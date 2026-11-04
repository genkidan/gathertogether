// Code-drawn cyan region halo for map previews (128 px, 32-bit TGA).
const fs = require('fs');
const path = require('path');
const size = 128;
const header = Buffer.alloc(18);
header[2] = 2;
header.writeUInt16LE(size, 12);
header.writeUInt16LE(size, 14);
header[16] = 32;
header[17] = 40;
const pixels = Buffer.alloc(size * size * 4);
for (let y = 0; y < size; y++) {
  for (let x = 0; x < size; x++) {
    const radius = Math.hypot((x + 0.5 - size / 2) / (size / 2), (y + 0.5 - size / 2) / (size / 2));
    const fill = radius < 0.84 ? 0.28 * (1 - radius * 0.5) : 0;
    const border = Math.max(0, 1 - Math.abs(radius - 0.82) / 0.08) * 0.76;
    const fade = Math.max(0, 1 - Math.max(0, radius - 0.88) / 0.12);
    const offset = (y * size + x) * 4;
    pixels[offset] = 245;
    pixels[offset + 1] = 170;
    pixels[offset + 2] = 28;
    pixels[offset + 3] = Math.round(255 * Math.max(fill, border) * fade);
  }
}
fs.writeFileSync(path.resolve(__dirname, '../Media/FishingArea.tga'), Buffer.concat([header, pixels]));
