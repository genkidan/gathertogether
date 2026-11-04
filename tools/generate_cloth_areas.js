// Generate approximate cloth loot areas from the installed QuestieDB Forever
// item drop table and NPC spawn metadata. Run from any directory with Node.
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const addonRoot = path.resolve(root, '..');
const dbRoot = path.join(addonRoot, 'QuestieDB');
const drops = fs.readFileSync(path.join(dbRoot, 'support/Forever/DropTables/classicItemDrops.lua'), 'utf8');
const toc = fs.readFileSync(path.join(dbRoot, 'QuestieDB_Forever.toc'), 'utf8');
const zones = fs.readFileSync(path.join(dbRoot, 'support/Forever/Zones/uiMapIdToAreaId.lua'), 'utf8');
const catalog = [{id:2589,min:20},{id:2592,min:20},{id:4306,min:20},
  {id:4338,min:20},{id:14047,min:20},{id:14256,min:3}];

// Only the CBOR shapes used by QuestieDB spawn lists are needed here.
function decode(bytes) {
  let offset = 0;
  function read() {
    const head = bytes[offset++], type = head >> 5, small = head & 31;
    let n = small;
    if (type !== 7) {
      if (small === 24) n = bytes[offset++];
      else if (small === 25) { n = bytes.readUInt16BE(offset); offset += 2; }
      else if (small === 26) { n = bytes.readUInt32BE(offset); offset += 4; }
      else if (small === 27) { n = Number(bytes.readBigUInt64BE(offset)); offset += 8; }
    }
    if (type === 0) return n;
    if (type === 1) return -1 - n;
    if (type === 2 || type === 3) {
      const data = bytes.subarray(offset, offset + n); offset += n;
      return type === 3 ? data.toString('utf8') : data;
    }
    if (type === 4) { const a = []; for (let i=0;i<n;i++) a.push(read()); return a; }
    if (type === 5) { const o = {}; for (let i=0;i<n;i++) o[read()] = read(); return o; }
    if (type === 6) return read();
    if (type === 7) {
      if (small === 20) return false;
      if (small === 21) return true;
      if (small === 22) return null;
      if (small === 25) {
        const bits = bytes.readUInt16BE(offset); offset += 2;
        const exponent = (bits >> 10) & 31, fraction = bits & 1023;
        const value = exponent === 0 ? 2 ** -14 * fraction / 1024 :
          exponent === 31 ? (fraction ? NaN : Infinity) : 2 ** (exponent - 15) * (1 + fraction / 1024);
        return bits & 0x8000 ? -value : value;
      }
      if (small === 26) { const value = bytes.readFloatBE(offset); offset += 4; return value; }
      if (small === 27) { const value = bytes.readDoubleBE(offset); offset += 8; return value; }
    }
    throw new Error(`Unsupported CBOR type ${type}/${small}`);
  }
  return read();
}

const metadata = new Map();
for (const line of toc.split(/\r?\n/)) {
  const match = line.match(/^## X-Npc-(\d+)-7(?:-(\d+))?: (.+)$/);
  if (match) metadata.set(`${match[1]}:${match[2] || 0}`, match[3]);
}
const areaToMap = new Map();
for (const match of zones.matchAll(/^    \[(\d+)\] = (\d+),/gm)) {
  const map = Number(match[1]), area = Number(match[2]);
  if (map >= 1400 && map <= 1500) areaToMap.set(area, map);
}
const supported = new Set();
const data = fs.readFileSync(path.join(root, 'Data.lua'), 'utf8');
for (const match of data.matchAll(/\["[^"]+"\] = (14\d\d)/g)) supported.add(Number(match[1]));

function spawns(npc) {
  const direct = metadata.get(`${npc}:0`);
  if (!direct) return null;
  let encoded = direct;
  if (/^~\d+~$/.test(direct)) {
    const count = Number(direct.slice(1,-1));
    encoded = '';
    for (let i=1;i<=count;i++) encoded += metadata.get(`${npc}:${i}`) || '';
  }
  return decode(Buffer.from(encoded, 'base64'));
}

const byMap = new Map();
for (const {id, min} of catalog) {
  const start = drops.indexOf(`    [${id}] = { -- `);
  if (start < 0) throw new Error(`Missing drop table for ${id}`);
  const end = drops.indexOf('\n    },', start);
  for (const match of drops.slice(start,end).matchAll(/^        \[(\d+)\] = ([\d.]+),/gm)) {
    const npc = Number(match[1]), chance = Number(match[2]);
    if (chance < min) continue;
    const locations = spawns(npc);
    if (!locations) continue;
    for (const [area, points] of Object.entries(locations)) {
      const map = areaToMap.get(Number(area));
      if (!map || !supported.has(map)) continue;
      if (!byMap.has(map)) byMap.set(map, []);
      for (const point of points) {
        const x = point[0] / 100, y = point[1] / 100;
        if (x > 0 && x < 1 && y > 0 && y < 1) byMap.get(map).push({x,y,id});
      }
    }
  }
}

const lines = [
  '-- Approximate loot areas derived from the QuestieDB Forever cloth drop table',
  '-- and NPC spawn metadata installed alongside this addon.',
  '-- Drop thresholds: at least 20% for base cloth and 3% for Felcloth.',
  '-- These are Classic-derived estimates, not confirmed Forever drop locations.',
  'GatherTogetherClothAreas = {',
];
let areas = 0;
for (const [map, points] of [...byMap].sort((a,b) => a[0]-b[0])) {
  const cells = new Map();
  for (const p of points) {
    const key = `${Math.floor(p.x / .14)}:${Math.floor(p.y / .14)}`;
    if (!cells.has(key)) cells.set(key, {points:[], items:new Set()});
    cells.get(key).points.push(p); cells.get(key).items.add(p.id);
  }
  if (!cells.size) continue;
  lines.push(`  [${map}] = {`);
  for (const cell of cells.values()) {
    const xs = cell.points.map(p=>p.x), ys = cell.points.map(p=>p.y);
    const loX=Math.min(...xs), hiX=Math.max(...xs), loY=Math.min(...ys), hiY=Math.max(...ys);
    const x=(loX+hiX)/2, y=(loY+hiY)/2;
    const rx=Math.max(.045,(hiX-loX)/2+.02), ry=Math.max(.055,(hiY-loY)/2+.025);
    lines.push(`    {x=${x.toFixed(3)}, y=${y.toFixed(3)}, rx=${rx.toFixed(3)}, ry=${ry.toFixed(3)}, fish={${[...cell.items].sort((a,b)=>a-b).join(',')}}, reported=true},`);
    areas++;
  }
  lines.push('  },');
}
lines.push('}');
fs.writeFileSync(path.join(root,'ClothAreas.lua'),lines.join('\n')+'\n');
process.stdout.write(`${byMap.size} maps, ${areas} approximate cloth areas\n`);
