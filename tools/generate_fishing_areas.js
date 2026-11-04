// Build broad fishing areas from GatherMate2_Data_Classic school coordinates.
// Download its FishData.lua as GatherTogether/PoolSourceClassic.tmp, then run from
// AddOns: node GatherTogether/tools/generate_fishing_areas.js
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'PoolSourceClassic.tmp'), 'utf8');
const nodeFish = {105:6359, 106:21153, 107:6358, 108:21071, 109:6522, 110:13422,
  137:6358, 138:6358, 139:6358, 140:6358, 141:6359, 142:6359, 143:6359, 144:6359};
const byMap = new Map();
let current = null;
for (const line of source.split(/\r?\n/)) {
  const zone = line.match(/^\s*\[(\d{1,4})\]\s*=\s*\{?\s*$/);
  if (zone) { current = Number(zone[1]); continue; }
  const point = line.match(/^\s*\[(\d{9,10})\]\s*=\s*(\d+),/);
  if (!point || !current) continue;
  const fish = nodeFish[Number(point[2])];
  if (!fish) continue;
  const coord = point[1].padStart(10, '0');
  const x = Number(coord.slice(0, 4)) / 100;
  const y = Number(coord.slice(4, 8)) / 100;
  if (x < 0 || x > 100 || y < 0 || y > 100) continue;
  if (!byMap.has(current)) byMap.set(current, []);
  byMap.get(current).push({x, y, fish});
}
const lines = [
  '-- Broad fishing school regions derived from public GatherMate2_Data_Classic coordinates.',
  '-- These are Classic estimates; individual pools spawn and despawn.',
  '-- Source: https://github.com/Thurdi/GatherMate2_Data_Classic/blob/master/GatherMate2_Data/FishData.lua',
  'GatherTogetherFishingAreas = {',
];
let zones = 0, areas = 0;
for (const [mapID, points] of [...byMap].sort((a, b) => a[0] - b[0])) {
  if (!points.length || mapID < 1400 || mapID > 1500) continue;
  const cells = new Map();
  for (const p of points) {
    const key = `${Math.floor(p.x / 15)}:${Math.floor(p.y / 15)}`;
    if (!cells.has(key)) cells.set(key, {points:[], fish:new Set()});
    cells.get(key).points.push(p);
    cells.get(key).fish.add(p.fish);
  }
  lines.push(`  [${mapID}] = {`);
  for (const cell of cells.values()) {
    const ps = cell.points;
    const minX = Math.min(...ps.map(p => p.x)), maxX = Math.max(...ps.map(p => p.x));
    const minY = Math.min(...ps.map(p => p.y)), maxY = Math.max(...ps.map(p => p.y));
    const x = (minX + maxX) / 200, y = (minY + maxY) / 200;
    const rx = Math.max(0.065, (maxX - minX) / 200 + 0.04);
    const ry = Math.max(0.080, (maxY - minY) / 200 + 0.05);
    const fish = [...cell.fish].sort((a, b) => a - b);
    lines.push(`    {x=${x.toFixed(3)}, y=${y.toFixed(3)}, rx=${rx.toFixed(3)}, ry=${ry.toFixed(3)}, fish={${fish.join(',')}}},`);
    areas++;
  }
  lines.push('  },');
  zones++;
}
lines.push('}');
fs.writeFileSync(path.join(root, 'FishingAreas.lua'), lines.join('\n') + '\n');
process.stdout.write(`${zones} maps, ${areas} broad areas\n`);
