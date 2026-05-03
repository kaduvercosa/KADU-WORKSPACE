const assert = require('node:assert');
const test = require('node:test');
const { shadeColor } = require('./utils');

test('shadeColor lightens a color', () => {
  // #808080 is (128, 128, 128)
  // +20% -> 128 * 1.2 = 153.6 -> 153 (#99)
  const result = shadeColor('#808080', 20);
  assert.strictEqual(result, '#999999');
});

test('shadeColor darkens a color', () => {
  // #808080 is (128, 128, 128)
  // -20% -> 128 * 0.8 = 102.4 -> 102 (#66)
  const result = shadeColor('#808080', -20);
  assert.strictEqual(result, '#666666');
});

test('shadeColor caps at 255 (white)', () => {
  const result = shadeColor('#ffffff', 10);
  assert.strictEqual(result, '#ffffff');
});

test('shadeColor handles low values (black)', () => {
  // #000000 -> 0 * any = 0
  const result = shadeColor('#000000', -10);
  assert.strictEqual(result, '#000000');
});

test('shadeColor pads hex values with zero', () => {
  // #010101 is (1, 1, 1)
  // +100% -> 2 (#02)
  const result = shadeColor('#010101', 100);
  assert.strictEqual(result, '#020202');
});

test('shadeColor handles complex colors', () => {
  // #3A8DE9 is (58, 141, 233)
  // -40% -> 58 * 0.6 = 34.8 -> 34 (#22)
  //         141 * 0.6 = 84.6 -> 84 (#54)
  //         233 * 0.6 = 139.8 -> 139 (#8b)
  const result = shadeColor('#3a8de9', -40);
  assert.strictEqual(result.toLowerCase(), '#22548b');
});
