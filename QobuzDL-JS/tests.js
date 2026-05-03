const test = require('node:test');
const assert = require('node:assert');
const QobuzClient = require('./api');
const Downloader = require('./downloader');
const fs = require('fs');
const path = require('path');

test('QobuzClient properly initializes', (t) => {
    const client = new QobuzClient('test-id', 'test-secret', 'test-token');
    assert.strictEqual(client.appId, 'test-id');
    assert.strictEqual(client.appSecret, 'test-secret');
});

test('Downloader sanitizes filenames properly', (t) => {
    const downloader = new Downloader({}, './Downloads');
    const sanitized = downloader.sanitizeFilename('AC/DC - Back in Black?');
    assert.strictEqual(sanitized, 'AC-DC - Back in Black-');
});

test('CLI regex correctly extracts album ID', (t) => {
    const albumRegex = /\/album\/([a-zA-Z0-9]+)/;
    const url1 = 'https://play.qobuz.com/album/qxjbxh1dc3xyb';
    const match1 = url1.match(albumRegex);
    assert.strictEqual(match1[1], 'qxjbxh1dc3xyb');

    const url2 = 'invalid-url';
    const match2 = url2.match(albumRegex);
    assert.strictEqual(match2, null);
});
