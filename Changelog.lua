-- OneCast's changelog, shown in the What's new window (WhatsNew.lua), newest first.
-- Each release: { version, date, sections = { { heading, { { lead, text }, ... } }, ... } }.
-- Add a new entry at the top for every release, with the same version as the TOC.

local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.3.0",
		date = "5 November 2026",
		sections = {
			{ "New", {
				{ "Skill-ups.", "The Session tab shows the Fishing skill you've gained and about how many catches until the next point. Below a zone's level, the skill bar says roughly how many catches it'll take to get there." },
				{ "Session summary.", "Take a 2-minute break and chat sums up the session: catches, fish per hour, vendor value, skill gained and new fish for your collection." },
				{ "Best spots.", "The Zone tab now tracks every spot you fish in a zone, a lake, a coast or a river. Click Spots to compare them, best fish per hour first, and hover one to see what bites there." },
				{ "Time of day.", "Every catch notes the realm hour, so each fish's page says whether you caught it by day or at night. Nightfin Snapper and Sunscale Salmon say when they bite in Classic." },
				{ "Find any fish.", "The collection book has a zone filter and a search box. Pick your zone, then Showing: missing, to see what's left to catch here." },
				{ "Fishing Extravaganza.", "A countdown to Stranglethorn's Sunday contest (Classic's schedule), a Tastyfish counter while it runs, chat reminders, and an alert the moment you hold 40." },
				{ "Auto loot.", "If auto loot is off, OneCast offers once to turn it on, so catches go straight to your bags." },
			} },
			{ "Changed", {
				{ "Auction house.", "The Scan fish prices button on the auction house window is gone. Scan from the stats window's button or /onecast scan instead." },
				{ "Lifetime tab.", "Shows how much of the collection you've caught." },
			} },
		},
	},
	{
		version = "0.2.1",
		date = "5 November 2026",
		sections = {
			{ "Updated for launch", {
				{ "88 catches in the collection.", "Checked against WoW Forever's launch build: 12 more trophy fish, 6 more bloated fish, the new Whimsyfin, the Fishing Extravaganza's Tastyfish and rare fish, and the Artisan quest fish." },
				{ "Honest about where fish come from.", "Zones not yet seen in Forever are marked as Classic data or player reports. Fish with no known waters fill in from your own catches." },
				{ "Maps fully revealed.", "The zone map on each fish's page now shows the whole zone, explored or not, instead of blank parchment." },
				{ "Riverglades.", "Its \"no minimum skill\" bug is still open. If a fish gets away there, OneCast now trusts that over the bug report." },
			} },
			{ "Fixed", {
				{ "Putting weapons back.", "No longer gets stuck after you level up, or when a saved weapon has left your bags. The pole is never put into a herb or other special bag." },
				{ "Zone while loading.", "Casts made during a loading screen no longer count under a blank zone." },
				{ "What's new.", "The version list scrolls once there are more versions than fit." },
			} },
		},
	},
	{
		version = "0.2.0",
		date = "23 October 2026",
		sections = {
			{ "New", {
				{ "The fishing collection.", "A book of every fish in WoW Forever: 61 catches across fish, special catches, trophy fish and bloated fish. Caught ones show in colour with your count; the rest wait greyed out." },
				{ "A page for every fish.", "Click any fish for its own page: the game's own description, a summary, your catches on every character, and when and where you first caught it." },
				{ "Where to catch it.", "Every zone it's caught in, the skill each needs, how many you've caught there, and a map of the zone. Open the full map in one click." },
				{ "What it's used in.", "The cooking, alchemy and fishing recipes each fish goes into, including WoW Forever's new ones." },
				{ "Shared across characters.", "The collection counts every character on your account, including everything you caught before this update." },
				{ "New fish announced.", "Catch a fish none of your characters has caught before and chat tells you it's new for your collection." },
			} },
			{ "How to open it", {
				{ "Anywhere you like.", "The book button in the stats window, Shift-click on the minimap button, the Open collection button in options, a key binding, or /onecast book." },
			} },
		},
	},
	{
		version = "0.1.0",
		date = "22 October 2026",
		sections = {
			{ "New", {
				{ "One-button fishing.", "Bind one key (or double right-click with a pole on): the first press casts, the next reels in your bobber. Every cast and every reel is still your own press." },
				{ "Your pole, equipped for you.", "With no pole on, the key equips the best one in your bags. Your weapons go back after a break, when combat starts, or with the sword button." },
				{ "Session stats.", "Casts, catches, catch rate, fish per hour and everything you caught, in a window that opens as you cast. Tabs for the session, the zone you're in, lifetime, and a log of recent catches." },
				{ "Is this zone right for you?", "A skill bar shows your Fishing skill, lure bonus included, against the zone's fishing level, so you know whether fish will get away. Zones without data are judged from your own catches." },
				{ "What your catch is worth.", "Vendor and auction value on every tab. Open the auction house and scan your catch with Auctionator in one click." },
				{ "Rare catch alerts.", "A raid-warning flash and sound for anything green or better, or any fish you mark as wanted with a right-click." },
				{ "Wowhead links.", "Click any caught item for its WoW Forever page on Wowhead, ready to copy. Shift-click links it in chat." },
				{ "Hear the splash.", "Sound effects turn up while your line is out; music and ambience are left alone." },
				{ "Make it yours.", "Options in the AddOns settings, a minimap button, and a stats window you can drag, scale and close." },
			} },
		},
	},
}
