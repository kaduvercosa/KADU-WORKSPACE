const crypto = require('crypto');
const axios = require('axios');
require('dotenv').config();

class QobuzClient {
    constructor(appId, appSecret, userAuthToken) {
        this.appId = appId || process.env.QOBUZ_APP_ID;
        this.appSecret = appSecret || process.env.QOBUZ_APP_SECRET;
        this.userAuthToken = userAuthToken || process.env.QOBUZ_USER_TOKEN;

        if (!this.appId || !this.appSecret) {
            throw new Error("QOBUZ_APP_ID and QOBUZ_APP_SECRET must be provided.");
        }

        this.baseURL = 'https://www.qobuz.com/api.json/0.2';
        this.client = axios.create({
            baseURL: this.baseURL,
            headers: {
                'X-App-Id': this.appId,
                'X-User-Auth-Token': this.userAuthToken || ''
            }
        });
    }

    async getAlbum(albumId) {
        try {
            const response = await this.client.get('/album/get', {
                params: {
                    album_id: albumId
                }
            });
            return response.data;
        } catch (error) {
            console.error(`Error fetching album ${albumId}:`, error.response?.data || error.message);
            throw error;
        }
    }

    async getTrackFileUrl(trackId, formatId = 5) {
        // formatId: 5 = MP3 320, 6 = FLAC 16-Bit, 7 = FLAC 24-Bit <= 96kHz, 27 = FLAC 24-Bit > 96kHz
        const unix = Math.floor(Date.now() / 1000);

        // request_sig = md5("trackgetFileUrlformat_id{formatId}intentstreamtrack_id{trackId}{unix}{appSecret}")
        const sigString = `trackgetFileUrlformat_id${formatId}intentstreamtrack_id${trackId}${unix}${this.appSecret}`;
        const requestSig = crypto.createHash('md5').update(sigString).digest('hex');

        try {
            const response = await this.client.get('/track/getFileUrl', {
                params: {
                    track_id: trackId,
                    format_id: formatId,
                    intent: 'stream',
                    request_ts: unix,
                    request_sig: requestSig
                }
            });
            return response.data;
        } catch (error) {
            console.error(`Error fetching track URL for ${trackId}:`, error.response?.data || error.message);
            throw error;
        }
    }
}

module.exports = QobuzClient;
