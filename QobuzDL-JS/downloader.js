const fs = require('fs');
const path = require('path');
const axios = require('axios');
const NodeID3 = require('node-id3');

class Downloader {
    constructor(apiClient, baseDir = 'Downloads') {
        this.api = apiClient;
        this.baseDir = path.resolve(baseDir);
        if (!fs.existsSync(this.baseDir)) {
            fs.mkdirSync(this.baseDir, { recursive: true });
        }
    }

    async downloadFile(url, filepath) {
        const writer = fs.createWriteStream(filepath);

        const response = await axios({
            url,
            method: 'GET',
            responseType: 'stream'
        });

        response.data.pipe(writer);

        return new Promise((resolve, reject) => {
            writer.on('finish', resolve);
            writer.on('error', reject);
        });
    }

    async downloadCover(url, filepath) {
        if (!url) return;
        try {
            await this.downloadFile(url, filepath);
            return filepath;
        } catch (error) {
            console.error('Failed to download cover art:', error.message);
        }
    }

    sanitizeFilename(name) {
        return name.replace(/[\/\\?%*:|"<>]/g, '-').trim();
    }

    async downloadAlbum(albumId, formatId = 5) {
        console.log(`Fetching metadata for album ${albumId}...`);
        const album = await this.api.getAlbum(albumId);

        const artistName = this.sanitizeFilename(album.artist.name);
        const albumTitle = this.sanitizeFilename(album.title);
        const albumDirName = `${artistName} - ${albumTitle}`;
        const albumDir = path.join(this.baseDir, albumDirName);

        if (!fs.existsSync(albumDir)) {
            fs.mkdirSync(albumDir, { recursive: true });
        }

        console.log(`Downloading album to: ${albumDir}`);

        // Download cover
        const coverPath = path.join(albumDir, 'cover.jpg');
        let hasCover = false;
        if (album.image && album.image.large) {
             hasCover = !!(await this.downloadCover(album.image.large, coverPath));
        }

        const extension = formatId === 5 ? '.mp3' : '.flac';

        for (const track of album.tracks.items) {
            const trackNumber = String(track.track_number).padStart(2, '0');
            const trackTitle = this.sanitizeFilename(track.title);
            const filename = `${trackNumber} - ${trackTitle}${extension}`;
            const filepath = path.join(albumDir, filename);

            if (fs.existsSync(filepath)) {
                console.log(`Skipping ${filename} (already exists)`);
                continue;
            }

            console.log(`Downloading track ${track.track_number}: ${track.title}...`);
            try {
                const urlData = await this.api.getTrackFileUrl(track.id, formatId);
                if (!urlData || !urlData.url) {
                     console.error(`Could not get URL for track ${track.id}`);
                     continue;
                }

                await this.downloadFile(urlData.url, filepath);
                console.log(`Downloaded ${filename}`);

                // Tagging (MP3 only for now, FLAC requires additional libraries to be fully equivalent)
                if (formatId === 5) {
                    const tags = {
                        title: track.title,
                        artist: track.performer?.name || album.artist.name,
                        album: album.title,
                        trackNumber: `${track.track_number}/${album.tracks_count}`,
                        year: album.release_date_original ? String(new Date(album.release_date_original).getFullYear()) : ''
                    };

                    if (hasCover) {
                        tags.image = coverPath;
                    }

                    NodeID3.write(tags, filepath);
                }

            } catch (error) {
                console.error(`Failed to download track ${track.id}:`, error.message);
            }
        }
        console.log(`Album download complete!`);
    }
}

module.exports = Downloader;
