const fs = require('fs');

const content = fs.readFileSync('Pokedex/index.html', 'utf8');
const scriptMatch = content.match(/<script>(.*?)<\/script>/s);

if (scriptMatch) {
    try {
        new Function(scriptMatch[1]);
        console.log("Syntax is OK!");
    } catch (e) {
        console.error("Syntax Error in inline script:");
        console.error(e);
    }
}
