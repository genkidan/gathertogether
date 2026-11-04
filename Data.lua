GatherTogetherZones = {}

-- Seuils Classic: competence minimale pour une touche, puis seuil sans poisson echappe.
local function add(minimum, sure, entries)
    for _, entry in ipairs(entries) do
        GatherTogetherZones[#GatherTogetherZones + 1] = {
            en = entry[1], fr = entry[2], minimum = minimum, sure = sure,
        }
    end
end

add(1, 25, {
    {"Dun Morogh", "Dun Morogh"}, {"Durotar", "Durotar"},
    {"Elwynn Forest", "Forêt d’Elwynn"}, {"Mulgore", "Mulgore"},
    {"Teldrassil", "Teldrassil"}, {"Tirisfal Glade", "Clairières de Tirisfal"},
})
add(1, 75, {
    {"Blackfathom Deeps", "Profondeurs de Brassenoire"}, {"Darkshore", "Sombrivage"},
    {"Darnassus", "Darnassus"}, {"Ironforge", "Forgefer"},
    {"Loch Modan", "Loch Modan"}, {"Orgrimmar", "Orgrimmar"},
    {"Silverpine Forest", "Forêt des Pins argentés"}, {"Stormwind City", "Hurlevent"},
    {"The Barrens", "Les Tarides"}, {"The Deadmines", "Les Mortemines"},
    {"Thunder Bluff", "Les Pitons-du-Tonnerre"}, {"Undercity", "Fossoyeuse"},
    {"Wailing Caverns", "Cavernes des lamentations"}, {"Westfall", "Marche de l’Ouest"},
})
add(51, 150, {
    {"Ashenvale", "Orneval"}, {"Duskwood", "Bois de la Pénombre"},
    {"Hillsbrad Foothills", "Contreforts de Hautebrande"},
    {"Redridge Mountains", "Les Carmines"}, {"Stonetalon Mountains", "Les Serres-Rocheuses"},
    {"Wetlands", "Les Paluns"},
})
add(126, 225, {
    {"Alterac Mountains", "Montagnes d’Alterac"}, {"Arathi Highlands", "Hautes-terres Arathies"},
    {"Desolace", "Désolace"}, {"Dustwallow Marsh", "Marécage d’Âprefange"},
    {"Scarlet Monastery", "Monastère écarlate"},
    {"Stranglethorn Vale", "Vallée de Strangleronce"},
    {"Swamp of Sorrows", "Marais des Chagrins"}, {"Thousand Needles", "Mille pointes"},
})
add(201, 300, {
    {"Azshara", "Azshara"}, {"Felwood", "Gangrebois"}, {"Feralas", "Féralas"},
    {"Jaguero Isle", "Île aux jagueros"}, {"Maraudon", "Maraudon"},
    {"Moonglade", "Reflet-de-Lune"}, {"Sunken Temple", "Temple englouti"},
    {"Tanaris", "Tanaris"}, {"The Hinterlands", "Les Hinterlands"},
    {"Un'goro Crater", "Cratère d’Un’Goro"},
    {"Western Plaguelands", "Maleterres de l’Ouest"},
})
add(326, 425, {
    {"Bay of Storms", "Baie des tempêtes"}, {"Burning Steppes", "Steppes Ardentes"},
    {"Deadwind Pass", "Défilé de Deuillevent"},
    {"Eastern Plaguelands", "Maleterres de l’Est"},
    {"Hetaera's Clutch", "Frai d’Hetaera"}, {"Jademir Lake", "Lac Jademir"},
    {"Scalebeard's Cave", "Caverne de Barbe-d’écailles"},
    {"Scholomance", "Scholomance"}, {"Silithus", "Silithus"},
    {"Stratholme", "Stratholme"}, {"Winterspring", "Berceau-de-l’Hiver"},
    {"Zul'Gurub", "Zul’Gurub"},
})

-- Pour les sous-zones absentes du catalogue, montrer seulement les prises de la
-- zone parente, clairement signalees comme indicatives.
local parentFish = {
    ["Wailing Caverns"] = "The Barrens",
    ["Jaguero Isle"] = "Stranglethorn Vale",
    ["Sunken Temple"] = "Swamp of Sorrows",
    ["Bay of Storms"] = "Azshara",
    ["Hetaera's Clutch"] = "Azshara",
    ["Jademir Lake"] = "Feralas",
    ["Scalebeard's Cave"] = "Azshara",
}
for _, zone in ipairs(GatherTogetherZones) do zone.fishFrom = parentFish[zone.en] end

-- UIMapIDs verifies pour le client Forever via QuestieDB/support/Forever/Zones.
local mapIDs = {
    ["Dun Morogh"] = 1426, ["Durotar"] = 1411, ["Elwynn Forest"] = 1429,
    ["Mulgore"] = 1412, ["Teldrassil"] = 1438, ["Tirisfal Glade"] = 1420,
    ["Darkshore"] = 1439, ["Darnassus"] = 1457, ["Ironforge"] = 1455,
    ["Loch Modan"] = 1432, ["Orgrimmar"] = 1454, ["Silverpine Forest"] = 1421,
    ["Stormwind City"] = 1453, ["The Barrens"] = 1413, ["Thunder Bluff"] = 1456,
    ["Undercity"] = 1458, ["Westfall"] = 1436, ["Ashenvale"] = 1440,
    ["Duskwood"] = 1431, ["Hillsbrad Foothills"] = 1424,
    ["Redridge Mountains"] = 1433, ["Stonetalon Mountains"] = 1442,
    ["Wetlands"] = 1437, ["Alterac Mountains"] = 1416,
    ["Arathi Highlands"] = 1417, ["Desolace"] = 1443,
    ["Dustwallow Marsh"] = 1445, ["Stranglethorn Vale"] = 1434,
    ["Swamp of Sorrows"] = 1435, ["Thousand Needles"] = 1441,
    ["Azshara"] = 1447, ["Felwood"] = 1448, ["Feralas"] = 1444,
    ["Moonglade"] = 1450, ["Tanaris"] = 1446, ["The Hinterlands"] = 1425,
    ["Un'goro Crater"] = 1449, ["Western Plaguelands"] = 1422,
    ["Burning Steppes"] = 1428, ["Deadwind Pass"] = 1430,
    ["Eastern Plaguelands"] = 1423, ["Silithus"] = 1451,
    ["Winterspring"] = 1452,
}
local parentMap = {
    ["Blackfathom Deeps"] = "Ashenvale", ["The Deadmines"] = "Westfall",
    ["Wailing Caverns"] = "The Barrens", ["Scarlet Monastery"] = "Tirisfal Glade",
    ["Jaguero Isle"] = "Stranglethorn Vale", ["Maraudon"] = "Desolace",
    ["Sunken Temple"] = "Swamp of Sorrows", ["Bay of Storms"] = "Azshara",
    ["Hetaera's Clutch"] = "Azshara", ["Jademir Lake"] = "Feralas",
    ["Scalebeard's Cave"] = "Azshara", ["Scholomance"] = "Western Plaguelands",
    ["Stratholme"] = "Eastern Plaguelands", ["Zul'Gurub"] = "Stranglethorn Vale",
}
local areaIDs = {
    ["Blackfathom Deeps"] = 719, ["The Deadmines"] = 1581,
    ["Wailing Caverns"] = 718, ["Scarlet Monastery"] = 796,
    ["Jaguero Isle"] = 297, ["Maraudon"] = 2100,
    ["Sunken Temple"] = 1477, ["Bay of Storms"] = 1227,
    ["Hetaera's Clutch"] = 1222, ["Jademir Lake"] = 1112,
    ["Scalebeard's Cave"] = 3140, ["Scholomance"] = 2057,
    ["Stratholme"] = 2017, ["Zul'Gurub"] = 1977,
}
for _, zone in ipairs(GatherTogetherZones) do
    zone.mapFrom = parentMap[zone.en]
    zone.mapID = mapIDs[zone.en] or mapIDs[zone.mapFrom]
    zone.areaID = areaIDs[zone.en]
end

GatherTogetherAllZones = {}
for _, zone in ipairs(GatherTogetherZones) do GatherTogetherAllZones[#GatherTogetherAllZones + 1] = zone end
for _, entry in ipairs({
    {"Badlands", "Terres ingrates", 1418},
    {"Blasted Lands", "Terres foudroyées", 1419},
    {"Searing Gorge", "Gorge des Vents brûlants", 1427},
}) do
    GatherTogetherAllZones[#GatherTogetherAllZones + 1] = {
        en=entry[1], fr=entry[2], mapID=entry[3], minimum=0, sure=0, gatherOnly=true,
    }
end

GatherTogetherLures = {
    {id = 6529, name = "Verroterie brillante", enName = "Shiny Bauble", bonus = 25, required = 1},
    {id = 6530, name = "Asticots", enName = "Nightcrawlers", bonus = 50, required = 50},
    {id = 6532, name = "Verroterie", enName = "Bright Baubles", bonus = 75, required = 100},
    {id = 6533, name = "Attracteur de poissons aquadynamique", enName = "Aquadynamic Fish Attractor", bonus = 100, required = 100},
}
