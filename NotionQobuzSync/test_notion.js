const { Client } = require('@notionhq/client');
const notion = new Client({ auth: 'test' });
console.log(typeof notion.databases.query);
