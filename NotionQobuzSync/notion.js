const { Client } = require('@notionhq/client');
const dotenv = require('dotenv');

dotenv.config({ path: __dirname + '/.env' });

const notion = new Client({ auth: process.env.NOTION_TOKEN });

const ARTISTS_DB = process.env.NOTION_ARTISTS_DB;
const ALBUMS_DB = process.env.NOTION_ALBUMS_DB;
const TRACKS_DB = process.env.NOTION_TRACKS_DB;

// Generic function to search by Name/Title
async function findEntity(databaseId, propertyName, propertyValue) {
    const response = await notion.databases.query({
        database_id: databaseId,
        filter: {
            property: propertyName,
            title: {
                equals: propertyValue
            }
        }
    });
    return response.results.length > 0 ? response.results[0] : null;
}

async function findArtist(name) {
    return findEntity(ARTISTS_DB, 'Name', name);
}

async function findAlbum(title) {
    return findEntity(ALBUMS_DB, 'Title', title);
}

async function findTrack(title, albumId) {
    const response = await notion.databases.query({
        database_id: TRACKS_DB,
        filter: {
            and: [
                {
                    property: 'Title',
                    title: {
                        equals: title
                    }
                },
                {
                    property: 'Album',
                    relation: {
                        contains: albumId
                    }
                }
            ]
        }
    });
    return response.results.length > 0 ? response.results[0] : null;
}

async function createArtist(artistData) {
    const properties = {
        'Name': {
            title: [{ text: { content: artistData.name } }]
        }
    };

    if (artistData.image) {
        properties['Image / Picture'] = {
            url: artistData.image
        };
    }

    if (artistData.biography) {
        properties['Biography'] = {
            rich_text: [{ text: { content: artistData.biography.substring(0, 2000) } }] // Notion limit
        };
    }

    if (artistData.albums_count !== undefined) {
        properties['Total Albums Count'] = {
            number: artistData.albums_count
        };
    }

    const response = await notion.pages.create({
        parent: { database_id: ARTISTS_DB },
        properties
    });
    return response;
}

async function createAlbum(albumData, artistNotionId) {
    const properties = {
        'Title': {
            title: [{ text: { content: albumData.title } }]
        },
        'Artist': {
            relation: [{ id: artistNotionId }]
        }
    };

    if (albumData.release_date) {
        properties['Release Date'] = {
            date: { start: albumData.release_date } // Format YYYY-MM-DD
        };
    }

    if (albumData.cover) {
        properties['Cover Art'] = {
            url: albumData.cover
        };
    }

    if (albumData.label) {
        properties['Label'] = {
            rich_text: [{ text: { content: albumData.label } }]
        };
    }

    if (albumData.genre) {
        const genres = albumData.genre.split ? albumData.genre.split(',').map(g => ({name: g.trim()})) : [{name: albumData.genre}];
        properties['Genre'] = {
            multi_select: genres
        };
    }

    if (albumData.tracks_count !== undefined) {
        properties['Track Count'] = {
            rich_text: [{ text: { content: String(albumData.tracks_count) } }]
        };
    }

    if (albumData.duration !== undefined) {
        properties['Duration'] = {
            number: albumData.duration
        };
    }

    if (albumData.upc) {
        properties['UPC/EAN'] = {
            rich_text: [{ text: { content: albumData.upc } }]
        };
    }

    if (albumData.audio_quality) {
        properties['Audio Quality/Hi-Res Info'] = {
            rich_text: [{ text: { content: albumData.audio_quality } }]
        };
    }

    const response = await notion.pages.create({
        parent: { database_id: ALBUMS_DB },
        properties
    });
    return response;
}

async function createTrack(trackData, albumNotionId, artistNotionId) {
    const properties = {
        'Title': {
            title: [{ text: { content: trackData.title } }]
        },
        'Album': {
            relation: [{ id: albumNotionId }]
        },
        'Artist': {
            relation: [{ id: artistNotionId }]
        }
    };

    if (trackData.track_number !== undefined) {
        properties['Track Number'] = {
            number: trackData.track_number
        };
    }

    if (trackData.duration !== undefined) {
        properties['Duration'] = {
            number: trackData.duration
        };
    }

    if (trackData.isrc) {
        properties['ISRC Code'] = {
            rich_text: [{ text: { content: trackData.isrc } }]
        };
    }

    if (trackData.audio_quality) {
        properties['Audio Quality/Hi-Res Info'] = {
            rich_text: [{ text: { content: trackData.audio_quality } }]
        };
    }

    if (trackData.explicit !== undefined) {
        properties['Explicit Content Flag'] = {
            checkbox: trackData.explicit
        };
    }

    const response = await notion.pages.create({
        parent: { database_id: TRACKS_DB },
        properties
    });
    return response;
}

module.exports = {
    findArtist,
    findAlbum,
    findTrack,
    createArtist,
    createAlbum,
    createTrack
};
