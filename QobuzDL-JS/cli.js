#!/usr/bin/env node

const { Command } = require('commander');
const QobuzClient = require('./api');
const Downloader = require('./downloader');

const program = new Command();

program
  .name('qobuzdl-js')
  .description('A JavaScript port of qobuz-dl core functionality.')
  .version('1.0.0');

program
  .command('dl <url>')
  .description('Download an album from Qobuz')
  .option('-q, --quality <quality>', 'Quality ID (5=MP3, 6=FLAC 16, 7=FLAC 24, 27=FLAC 24 >96)', '5')
  .option('-d, --dir <directory>', 'Download directory', 'QobuzDownloads')
  .action(async (url, options) => {
    // Basic regex to extract album ID from Qobuz web player URL
    // e.g. https://play.qobuz.com/album/qxjbxh1dc3xyb
    const albumRegex = /\/album\/([a-zA-Z0-9]+)/;
    const match = url.match(albumRegex);

    if (!match) {
        console.error('Invalid Qobuz album URL. Must be in the format: https://play.qobuz.com/album/<id>');
        process.exit(1);
    }

    const albumId = match[1];
    const qualityId = parseInt(options.quality, 10);

    try {
        const client = new QobuzClient();
        const downloader = new Downloader(client, options.dir);

        await downloader.downloadAlbum(albumId, qualityId);
    } catch (error) {
        console.error('Download failed.');
        process.exit(1);
    }
  });

program.parse(process.argv);
