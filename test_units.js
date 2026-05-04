const assert = require('assert');

let heightM = 0.7; // Bulbasaur
let weightKg = 6.9; // Bulbasaur

let isImperial = true;

let hText, wText;

if (isImperial) {
    let totalInches = heightM * 39.3701;
    let ft = Math.floor(totalInches / 12);
    let inc = Math.round(totalInches % 12);
    hText = `${ft}'${inc}"`;

    let lbs = (weightKg * 2.20462).toFixed(1);
    wText = `${lbs} lbs`;
}

console.log(`Height: ${hText}, Weight: ${wText}`);
assert.equal(hText, `2'4"`);
assert.equal(wText, `15.2 lbs`);
console.log("Unit conversion is correct.");
