// Download GatherLite scripts/nodes.lua and plugins/database/data/forever.lua
// as GatherLiteNodes.tmp and GatherLiteForever.tmp in GatherTogether, then run from AddOns.
// This produces broad map areas from reported WoW Forever gathering locations.
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const nodes = fs.readFileSync(path.join(root, 'GatherLiteNodes.tmp'), 'utf8');
const source = fs.readFileSync(path.join(root, 'GatherLiteForever.tmp'), 'utf8');
const items = {
  copper_vein:2770,tin_vein:2771,silver_vein:2775,iron_deposit:2772,gold_vein:2776,
  mithril_deposit:3858,truesilver_deposit:7911,dark_iron_deposit:11370,
  small_thorium_vein:10620,rich_thorium_vein:10620,
  silverleaf:765,peacebloom:2447,earthroot:2449,mageroyal:785,briarthorn:2450,
  stranglekelp:3820,bruiseweed:2453,wild_steelbloom:3355,grave_moss:3369,
  kingsblood:3356,liferoot:3357,fadeleaf:3818,goldthorn:3821,khadgars_whisker:3358,
  wintersbite:3819,firebloom:4625,purple_lotus:8831,arthas_tears:8836,sungrass:8838,
  blindweed:8839,ghost_mushroom:8845,gromsblood:8846,golden_sansam:13464,
  dreamfoil:13463,mountain_silversage:13465,plaguebloom:13466,icecap:13467,
  black_lotus:13468,
};
const objectInfo = new Map(), catalog = new Map();
for (const match of nodes.matchAll(/InsertObject\("(ore|herb)",\s*\{([^}]*)\},\s*"([^"]+)",\s*"[^"]+",\s*\{([^}]*)\}/g)) {
  const [, kind, objects, name, levels] = match;
  const item = items[name];
  if (!item) continue;
  const skill = Number(levels.match(/\d+/)[0]);
  const ids = objects.match(/\d+/g).map(Number);
  const key = ids[0];
  for (const id of ids) objectInfo.set(id, {kind, key, item, skill, name});
  catalog.set(key, {kind,key,item,skill,name});
}
const byKind = {ore:new Map(),herb:new Map()};
let object = null, mapID = null;
for (const line of source.split(/\r?\n/)) {
  const objectLine = line.match(/^    \[(\d+)\] = \{$/);
  if (objectLine) { object = objectInfo.get(Number(objectLine[1])) || null; mapID = null; continue; }
  const mapLine = line.match(/^        \[(\d+)\] = \{$/);
  if (mapLine) { mapID = Number(mapLine[1]); continue; }
  if (!object || !mapID || !/^            /.test(line)) continue;
  const coordinates = [...line.matchAll(/\b0\.\d+\b|\b1(?:\.0+)?\b/g)].map(x => Number(x[0]));
  if (coordinates.length % 2 !== 0) throw new Error(`Odd coordinate count on map ${mapID}`);
  const map = byKind[object.kind];
  if (!map.has(mapID)) map.set(mapID, []);
  for (let i = 0; i < coordinates.length; i += 2) {
    const x = coordinates[i], y = coordinates[i+1];
    if (x > 0 && x < 1 && y > 0 && y < 1) map.get(mapID).push({x,y,item:object.key});
  }
}
const lines = [
  '-- Broad areas derived from GatherLite WoW Forever reported nodes (MIT).',
  '-- Source: https://github.com/Wuild/GatherLite/tree/master/plugins/database/data',
  '-- A reported location does not guarantee a currently active node.',
  'GatherTogetherGathering = {',
  '  resources = {',
];
for (const {kind,key,item,skill,name} of [...catalog.values()].sort((a,b)=>a.skill-b.skill || a.key-b.key))
  lines.push(`    [${key}] = {kind="${kind}", item=${item}, skill=${skill}, en="${name.replace(/_/g,' ')}"},`);
lines.push('  },', '  areas = {');
let areaCount=0;
for (const kind of ['ore','herb']) {
  lines.push(`    ${kind} = {`);
  for (const [mapID, points] of [...byKind[kind]].sort((a,b)=>a[0]-b[0])) {
    if (!points.length || mapID < 1400 || mapID > 1500) continue;
    const cells = new Map();
    for (const p of points) {
      const key = `${Math.floor(p.x/0.16)}:${Math.floor(p.y/0.16)}`;
      if (!cells.has(key)) cells.set(key,{points:[],items:new Set()});
      cells.get(key).points.push(p); cells.get(key).items.add(p.item);
    }
    lines.push(`      [${mapID}] = {`);
    for (const cell of cells.values()) {
      const ps=cell.points, minX=Math.min(...ps.map(p=>p.x)), maxX=Math.max(...ps.map(p=>p.x));
      const minY=Math.min(...ps.map(p=>p.y)), maxY=Math.max(...ps.map(p=>p.y));
      const x=(minX+maxX)/2,y=(minY+maxY)/2;
      const rx=Math.max(0.055,(maxX-minX)/2+0.025),ry=Math.max(0.070,(maxY-minY)/2+0.035);
      lines.push(`        {x=${x.toFixed(3)}, y=${y.toFixed(3)}, rx=${rx.toFixed(3)}, ry=${ry.toFixed(3)}, fish={${[...cell.items].sort((a,b)=>a-b).join(',')}}, reported=true},`);
      areaCount++;
    }
    lines.push('      },');
  }
  lines.push('    },');
}
lines.push('  },','}');
fs.writeFileSync(path.join(root,'GatheringData.lua'),lines.join('\n')+'\n');
process.stdout.write(`${catalog.size} resources, ${areaCount} map areas\n`);
