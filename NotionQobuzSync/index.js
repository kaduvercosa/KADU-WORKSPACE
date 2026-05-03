#!/usr/bin/env node
const { Command } = require('commander');
const { searchAlbums } = require('./qobuz');
const { syncAlbum } = require('./sync');

const program = new Command();

program
  .name('notion-qobuz-sync')
  .description('Sync Qobuz music metadata to Notion databases')
  .version('1.0.0');

program
  .option('-a, --album <id>', 'Sync a specific Qobuz Album ID')
  .option('-s, --search <query>', 'Search for an album by title/artist and sync the first result')
  .action(async (options) => {
      try {
          if (options.album) {
              await syncAlbum(options.album);
          } else if (options.search) {
              console.log(`Searching for "${options.search}"...`);
              const results = await searchAlbums(options.search, 1);
              if (results.length > 0) {
                  const albumId = results[0].id;
                  console.log(`Found Album: ${results[0].title} (ID: ${albumId})`);
                  await syncAlbum(albumId);
              } else {
                  console.log(`No albums found for query: "${options.search}"`);
              }
          } else {
              console.log('Please provide either an --album ID or a --search query. Use --help for more info.');
          }
      } catch (error) {
          console.error("An error occurred during sync:");
          console.error(error.message);
      }
  });

program.parse(process.argv);
