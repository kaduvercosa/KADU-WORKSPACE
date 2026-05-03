const qobuz = require('./qobuz');
const notion = require('./notion');

async function syncAlbum(albumId) {
    console.log(`Starting sync for Qobuz Album ID: ${albumId}`);

    // 1. Fetch Album Data
    const albumData = await qobuz.getAlbum(albumId);
    console.log(`Fetched Album: ${albumData.title} by ${albumData.artist.name}`);

    // 2. Fetch Artist Data
    const artistData = await qobuz.getArtist(albumData.artist.id);

    // 3. Process Artist
    let artistNotionId;
    const existingArtist = await notion.findArtist(artistData.name);
    if (existingArtist) {
        console.log(`Artist "${artistData.name}" already exists in Notion.`);
        artistNotionId = existingArtist.id;
    } else {
        console.log(`Creating Artist "${artistData.name}" in Notion...`);
        const artistImage = artistData.image && artistData.image.large ? artistData.image.large : (artistData.picture ? artistData.picture : null);

        // Extract biography safely
        let biography = '';
        if (artistData.biography && artistData.biography.content) {
            // Strip simple HTML tags if present, or just use as is
            biography = artistData.biography.content.replace(/<[^>]*>?/gm, '');
        }

        const newArtist = await notion.createArtist({
            name: artistData.name,
            image: artistImage,
            biography: biography,
            albums_count: artistData.albums_count
        });
        artistNotionId = newArtist.id;
        console.log(`Artist created successfully.`);
    }

    // 4. Process Album
    let albumNotionId;
    const existingAlbum = await notion.findAlbum(albumData.title);
    if (existingAlbum) {
        // Double check if the relation matches? For now, assume title is unique enough or skip
        console.log(`Album "${albumData.title}" already exists in Notion.`);
        albumNotionId = existingAlbum.id;
    } else {
        console.log(`Creating Album "${albumData.title}" in Notion...`);

        // Determine audio quality string
        let audioQuality = [];
        if (albumData.maximum_bit_depth) audioQuality.push(`${albumData.maximum_bit_depth}-bit`);
        if (albumData.maximum_sampling_rate) audioQuality.push(`${albumData.maximum_sampling_rate}kHz`);

        const newAlbum = await notion.createAlbum({
            title: albumData.title,
            release_date: albumData.release_date_original ? albumData.release_date_original : albumData.release_date_stream,
            cover: albumData.image && albumData.image.large ? albumData.image.large : null,
            label: albumData.label ? albumData.label.name : null,
            genre: albumData.genre ? albumData.genre.name : null,
            tracks_count: albumData.tracks_count,
            duration: albumData.duration,
            upc: albumData.upc,
            audio_quality: audioQuality.join(' ') || null
        }, artistNotionId);
        albumNotionId = newAlbum.id;
        console.log(`Album created successfully.`);
    }

    // 5. Process Tracks
    if (albumData.tracks && albumData.tracks.items) {
        console.log(`Processing ${albumData.tracks.items.length} tracks...`);
        let count = 0;
        for (const track of albumData.tracks.items) {
            const existingTrack = await notion.findTrack(track.title, albumNotionId);
            if (existingTrack) {
                console.log(`Track "${track.title}" already exists.`);
            } else {
                let trackAudioQuality = [];
                if (track.maximum_bit_depth) trackAudioQuality.push(`${track.maximum_bit_depth}-bit`);
                if (track.maximum_sampling_rate) trackAudioQuality.push(`${track.maximum_sampling_rate}kHz`);

                await notion.createTrack({
                    title: track.title,
                    track_number: track.track_number,
                    duration: track.duration,
                    isrc: track.isrc,
                    audio_quality: trackAudioQuality.join(' ') || null,
                    explicit: track.parental_warning
                }, albumNotionId, artistNotionId);
                console.log(`Track "${track.title}" synced.`);
                count++;
            }
        }
        console.log(`Finished syncing ${count} new tracks.`);
    }

    console.log(`Sync complete for ${albumData.title}!`);
}

module.exports = {
    syncAlbum
};
