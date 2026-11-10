-- Fishing skill needed in each zone so that no fish get away: the zone's fishing level + 95.
-- Lure and pole bonuses count towards it. Zone skill is set by the server, not the game data,
-- and no source has published Forever's own numbers yet (10 November 2026), so these are
-- Classic's, from CMaNGOS's Classic 1.12 world database (skill_fishing_base_level), which
-- AzerothCore's matches for every Classic zone. Badlands, Blasted Lands and Searing Gorge have
-- no level there: they have no water to fish. The stats window also counts real getaways per
-- zone, with the skill they happened at: they judge zones missing from this table, overrule
-- ZONE_FISHING_NOTE, and overrule this table too when a fish gets away at or above your
-- current skill.
-- Keyed by English zone name; ZoneNames.lua swaps them for the client's own at load.

local _, ns = ...

local LEVELS = {
	[25] = {
		"Dun Morogh", "Durotar", "Elwynn Forest", "Mulgore", "Teldrassil", "Tirisfal Glades",
	},
	[75] = {
		"The Barrens", "Darkshore", "Loch Modan", "Silverpine Forest", "Westfall",
		"Stormwind City", "Orgrimmar", "Ironforge", "Thunder Bluff", "Undercity", "Darnassus",
		"The Deadmines", "Wailing Caverns", "Blackfathom Deeps",
	},
	[150] = {
		"Ashenvale", "Duskwood", "Hillsbrad Foothills", "Redridge Mountains",
		"Stonetalon Mountains", "Wetlands",
	},
	[225] = {
		"Alterac Mountains", "Arathi Highlands", "Desolace", "Dustwallow Marsh",
		"Stranglethorn Vale", "Swamp of Sorrows", "Thousand Needles", "Scarlet Monastery",
	},
	[300] = {
		"Azshara", "Felwood", "Feralas", "Moonglade", "Tanaris", "The Hinterlands",
		"Un'Goro Crater", "Western Plaguelands", "Sunken Temple", "Maraudon",
	},
	[425] = {
		"Burning Steppes", "Deadwind Pass", "Eastern Plaguelands", "Silithus", "Winterspring",
		"Zul'Gurub", "Stratholme", "Scholomance",
	},
}

-- Waters inside a zone with a level of their own, keyed by the sub-zone's name (what
-- GetSubZoneText says while you stand there). Same source as above.
ns.SPOT_FISHING_SKILL = {
	["Jaguero Isle"] = 300,      -- Stranglethorn Vale
	["Jademir Lake"] = 425,      -- Feralas
	["Bay of Storms"] = 425,     -- Azshara
	["Hetaera's Clutch"] = 425,  -- Azshara
	["Scalebeard's Cave"] = 425, -- Azshara
}

ns.ZONE_FISHING_SKILL = {}
for skill, zones in pairs(LEVELS) do
	for _, zone in ipairs(zones) do
		ns.ZONE_FISHING_SKILL[zone] = skill
	end
end

-- Zones new in Forever (Riverglades, Shen'dralas, Mount Hyjal, Gilneas, Zephras Isle) have no
-- Classic level and no published Forever one, so they're left out above: the stats window
-- judges them from your own catches and getaways. The book's Zones view lists them all the same.
ns.ZONE_FISHING_UNKNOWN = { "Riverglades", "Shen'dralas", "Mount Hyjal", "Gilneas", "Zephras Isle" }

-- Notes shown instead of a level, until a getaway in that zone proves them wrong.
ns.ZONE_FISHING_NOTE = {
	-- Forever bug report (ClassicWoWCommunity/forever-bugs#189, Sept 2026, still open at
	-- launch): skill 1 catches every time here, though its fish are 225+ tier. Blizzard
	-- may add a minimum at any time.
	["Riverglades"] = "no minimum skill reported (open bug, may be fixed)",
}
