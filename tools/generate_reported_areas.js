// Download GatherLite/plugins/fishing/data.lua as GatherTogether/GatherLiteFish.tmp,
// then run from AddOns: node GatherTogether/tools/generate_reported_areas.js
// The source reports catches in WoW Forever; it does not guarantee a pool.
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'GatherLiteFish.tmp'), 'utf8');
const maps = new Map();
let fishID = null;
for (const line of source.split(/\r?\n/)) {
  const fish = line.match(/^\s*\{itemID=(\d+), type="fish"/);
  if (fish) fishID = Number(fish[1]);
  const area = line.match(/^\s*\[(\d+)\]=\{([^}]*)\}/);
  if (!area || !fishID) continue;
  const numbers = [...area[2].matchAll(/\b0\.\d+\b|\b1(?:\.0+)?\b/g)].map(v => Number(v[0]));
  if (numbers.length % 2 !== 0) throw new Error(`Invalid coordinates for fish ${fishID}`);
  if (!maps.has(Number(area[1]))) maps.set(Number(area[1]), []);
  for (let i = 0; i < numbers.length; i += 2) {
    const x = numbers[i], y = numbers[i + 1];
    if (x >= 0 && x <= 1 && y >= 0 && y <= 1) maps.get(Number(area[1])).push({x, y, fish: fishID});
  }
}
const lines = [
  '-- Approximate fishing areas derived from reported WoW Forever catches.',
  '-- Source: https://github.com/Wuild/GatherLite/blob/master/plugins/fishing/data.lua (MIT).',
  '-- A reported catch is not a guaranteed current spawn or fishing pool.',
  'GatherTogetherReportedAreas = {',
];
let zoneCount = 0, areaCount = 0;
for (const [mapID, points] of [...maps].sort((a, b) => a[0] - b[0])) {
  if (!points.length) continue;
  const cells = new Map();
  for (const p of points) {
    const key = `${Math.floor(p.x / 0.15)}:${Math.floor(p.y / 0.15)}`;
    if (!cells.has(key)) cells.set(key, {points: [], fish: new Set()});
    cells.get(key).points.push(p);
    cells.get(key).fish.add(p.fish);
  }
  lines.push(`  [${mapID}] = {`);
  for (const cell of cells.values()) {
    const ps = cell.points;
    const minX = Math.min(...ps.map(p => p.x)), maxX = Math.max(...ps.map(p => p.x));
    const minY = Math.min(...ps.map(p => p.y)), maxY = Math.max(...ps.map(p => p.y));
    const x = (minX + maxX) / 2, y = (minY + maxY) / 2;
    const rx = Math.max(0.055, (maxX - minX) / 2 + 0.03);
    const ry = Math.max(0.075, (maxY - minY) / 2 + 0.04);
    const fish = [...cell.fish].sort((a, b) => a - b);
    lines.push(`    {x=${x.toFixed(3)}, y=${y.toFixed(3)}, rx=${rx.toFixed(3)}, ry=${ry.toFixed(3)}, fish={${fish.join(',')}}, reported=true},`);
    areaCount++;
  }
  lines.push('  },');
  zoneCount++;
}
lines.push('}');
fs.writeFileSync(path.join(root, 'ReportedAreas.lua'), lines.join('\n') + '\n');
process.stdout.write(`${zoneCount} maps, ${areaCount} reported areas\n`);
