const axios = require('axios');
const dotenv = require('dotenv');

dotenv.config({ path: __dirname + '/.env' });

const QOBUZ_APP_ID = process.env.QOBUZ_APP_ID;
const QOBUZ_USER_TOKEN = process.env.QOBUZ_USER_TOKEN;

const apiClient = axios.create({
    baseURL: 'https://www.qobuz.com/api.json/0.2',
    headers: {
        'X-App-Id': QOBUZ_APP_ID,
        'X-User-Auth-Token': QOBUZ_USER_TOKEN
    }
});

async function searchAlbums(query, limit = 1) {
    try {
        const response = await apiClient.get('/album/search', {
            params: {
                query,
                limit
            }
        });
        if (response.data && response.data.albums && response.data.albums.items) {
            return response.data.albums.items;
        }
        return [];
    } catch (error) {
        console.error('Error searching Qobuz albums:', error.response ? error.response.data : error.message);
        throw error;
    }
}

async function getAlbum(albumId) {
    try {
        const response = await apiClient.get('/album/get', {
            params: {
                album_id: albumId
            }
        });
        return response.data;
    } catch (error) {
        console.error(`Error fetching Qobuz album ${albumId}:`, error.response ? error.response.data : error.message);
        throw error;
    }
}

async function getArtist(artistId) {
    try {
        const response = await apiClient.get('/artist/get', {
            params: {
                artist_id: artistId
            }
        });
        return response.data;
    } catch (error) {
        console.error(`Error fetching Qobuz artist ${artistId}:`, error.response ? error.response.data : error.message);
        throw error;
    }
}

module.exports = {
    searchAlbums,
    getAlbum,
    getArtist
};
