-- OneCast report: this character's fishing data as plain text, to copy and share.
--
-- Nobody has published Forever's real zone fishing levels or which fish live where, and the
-- game doesn't tell addons either. OneCast already sees every catch and getaway, and the skill
-- each happened at, so players can pass that on: OneCast's numbers can then become Forever's
-- own. The text holds fishing numbers only: no character name, realm or guild.

local _, ns = ...

local Report = {}
ns.Report = Report

local MAX_FISH = 15 -- items listed per zone, most caught first

-- The area ID for a zone name as the game gives it, in any client language.
local function AreaID(zone)
	local id = ns.ZONE_AREA_IDS and ns.ZONE_AREA_IDS[zone]
	if id then
		return id
	end
	for _, areaID in pairs(ns.ZONE_AREA_IDS or {}) do
		if C_Map.GetAreaInfo(areaID) == zone then
			return areaID
		end
	end
end

local function ByCount(items)
	local list = {}
	for id, item in pairs(items) do
		local count = type(item) == "table" and item.count or item
		local name = type(item) == "table" and item.name or C_Item.GetItemNameByID(id)
		list[#list + 1] = { id = id, count = count, name = name or ("item " .. id) }
	end
	table.sort(list, function(a, b)
		if a.count ~= b.count then
			return a.count > b.count
		end
		return a.id < b.id
	end)
	return list
end

local function ItemLine(items)
	local parts = {}
	local list = ByCount(items)
	for i = 1, math.min(#list, MAX_FISH) do
		parts[i] = string.format("%s (%d) x%d", list[i].name, list[i].id, list[i].count)
	end
	if #list > MAX_FISH then
		parts[#parts + 1] = string.format("and %d more", #list - MAX_FISH)
	end
	return table.concat(parts, ", ")
end

-- "  skill 200-224: 40 caught, 3 got away" for each step with anything in it.
local function SkillLines(z, add)
	local steps, seen = {}, {}
	for _, key in ipairs({ "skillCatches", "skillGetaways" }) do
		for bucket in pairs(z[key] or {}) do
			if not seen[bucket] then
				seen[bucket] = true
				steps[#steps + 1] = bucket
			end
		end
	end
	table.sort(steps)
	local step = ns.Stats.SKILL_STEP
	for _, bucket in ipairs(steps) do
		local caught = z.skillCatches and z.skillCatches[bucket] or 0
		local away = z.skillGetaways and z.skillGetaways[bucket] or 0
		add(string.format("  skill %d-%d: %d caught%s", bucket, bucket + step - 1, caught,
			away > 0 and string.format(", %d got away", away) or ""))
	end
	return #steps > 0
end

-- Findings: what this character has seen that OneCast doesn't know ----------------------
-- Worth sharing, so worth saying: once in chat when each is first found, and as a count on
-- the minimap button until the report is copied.

local MIN_UNKNOWN_LEVEL = 10 -- catches in a zone with no known level
local MIN_BELOW_LEVEL = 20   -- catches without a getaway below a zone's listed level
local MIN_NEW_PLACE = 3      -- of one collection fish in a zone OneCast doesn't list for it
local MIN_CAMP = 5           -- catches under a camp buff

local function Listed(fish, zone)
	for _, z in ipairs(fish.zones or {}) do
		if z == zone then
			return true
		end
	end
	for _, extra in ipairs(fish.more or {}) do
		if extra[1] == zone then
			return true
		end
	end
	return false
end

local function ItemName(id, item)
	return (type(item) == "table" and item.name) or C_Item.GetItemNameByID(id) or ("item " .. id)
end

-- Every finding, as { key, text, zone }: the key stays the same while the finding does. The
-- minimap button, stats window, book and this window can all ask in one redraw, so the list is
-- worked out once a frame. Callers may sort it, so each gets its own copy.
local cached, cachedAt
local Findings

function Report.Findings()
	local now = GetTime()
	if not cached or cachedAt ~= now then
		cached, cachedAt = Findings(), now
	end
	local copy = {}
	for i, f in ipairs(cached) do
		copy[i] = f
	end
	return copy
end

-- Nothing cached survives a catch, a getaway or sharing.
function Report.Forget()
	cached = nil
end

Findings = function()
	local found = {}
	local function add(key, text, zone)
		found[#found + 1] = { key = key, text = text, zone = zone }
	end
	local step = ns.Stats.SKILL_STEP
	local zoneNames = {}
	for zone in pairs(OneCastCharDB and OneCastCharDB.zoneStats or {}) do
		zoneNames[#zoneNames + 1] = zone
	end
	table.sort(zoneNames)
	for _, zone in ipairs(zoneNames) do
		local z = OneCastCharDB.zoneStats[zone]
		local listed = ns.ZONE_FISHING_SKILL and ns.ZONE_FISHING_SKILL[zone]
		if not listed then
			if (z.catches or 0) >= MIN_UNKNOWN_LEVEL then
				add("level:" .. zone, string.format("%d catches in %s, which has no known fishing level", z.catches, zone), zone)
			end
		else
			-- A getaway at or above the listed level says the real one is higher.
			local highestAway
			for bucket, n in pairs(z.skillGetaways or {}) do
				if n > 0 and (not highestAway or bucket > highestAway) then
					highestAway = bucket
				end
			end
			if highestAway and highestAway >= listed then
				add("above:" .. zone, string.format("A fish got away in %s at skill %d-%d, though OneCast lists %d",
					zone, highestAway, highestAway + step - 1, listed), zone)
			end
			-- Plenty of catches below the listed level, none getting away there, says it's lower.
			local below, lowest = 0, nil
			for bucket, n in pairs(z.skillCatches or {}) do
				if bucket + step <= listed and not (highestAway and bucket <= highestAway) then
					below = below + n
					lowest = math.min(lowest or bucket, bucket)
				end
			end
			if below >= MIN_BELOW_LEVEL then
				add("below:" .. zone, string.format("%d catches in %s from skill %d with no getaways, though OneCast lists %d",
					below, zone, lowest, listed), zone)
			end
		end
		for id, item in pairs(z.items or {}) do
			local fish = ns.FISH_BY_ID and ns.FISH_BY_ID[id]
			if fish and (item.count or 0) >= MIN_NEW_PLACE and not Listed(fish, zone) then
				add("place:" .. id .. ":" .. zone, string.format("%s caught in %s, where OneCast doesn't list it",
					ItemName(id, item), zone), zone)
			end
		end
	end
	for _, entry in ipairs(ns.Collection and ns.Collection.Discovered() or {}) do
		add("fish:" .. entry.id, string.format("%s, which isn't in OneCast's collection", entry.name or ("item " .. entry.id)))
	end
	for _, craft in ipairs(ns.Camp and ns.Camp.CRAFTS or {}) do
		local r = craft.buff and ns.Camp.Record(craft.key)
		if r and r.catches >= MIN_CAMP then
			add("camp:" .. craft.key, string.format("%d catches with %s on", r.catches, craft.buffName))
		end
	end
	return found
end

local function Seen()
	local charDB = OneCastCharDB
	charDB.reportFindings = charDB.reportFindings or { said = {}, shared = {} }
	return charDB.reportFindings
end

-- Findings not yet shared (copied from the report).
function Report.Unshared()
	if not OneCastCharDB then
		return {}
	end
	local shared = Seen().shared
	local list = {}
	for _, f in ipairs(Report.Findings()) do
		if not shared[f.key] then
			list[#list + 1] = f
		end
	end
	return list
end

-- Unshared findings by zone: { [zone] = { finding, ... } }, for the book's Zones tab.
function Report.UnsharedByZone()
	local byZone = {}
	for _, f in ipairs(Report.Unshared()) do
		if f.zone then
			byZone[f.zone] = byZone[f.zone] or {}
			table.insert(byZone[f.zone], f)
		end
	end
	return byZone
end

-- What a window's tooltip says about sharing: a line, or nil with nothing new.
function Report.TooltipLine()
	local n = #Report.Unshared()
	if n == 0 then
		return nil
	end
	return string.format("You have %d thing%s OneCast doesn't know yet. Sharing your report helps fill in Forever's numbers.",
		n, n == 1 and "" or "s")
end

-- After a catch or getaway: say anything newly found, once each.
function Report.Check()
	Report.Forget()
	if not (OneCastCharDB and ns.db and ns.db.reportHint) then
		return
	end
	local said = Seen().said
	local fresh = {}
	for _, f in ipairs(Report.Unshared()) do
		if not said[f.key] then
			said[f.key] = true
			fresh[#fresh + 1] = f
		end
	end
	if #fresh == 1 then
		ns.Print("you've found something OneCast doesn't know yet: " .. fresh[1].text .. ". /onecast report to share it.")
	elseif #fresh > 1 then
		ns.Print(string.format("you've found %d things OneCast doesn't know yet, like: %s. /onecast report to share them.",
			#fresh, fresh[1].text))
	end
end

-- Copying the report shares what's in it.
function Report.MarkShared()
	Report.Forget()
	if not OneCastCharDB then
		return
	end
	local seen = Seen()
	for _, f in ipairs(Report.Findings()) do
		seen.shared[f.key] = true
		seen.said[f.key] = true
	end
end

function Report.Text()
	local out = {}
	local function add(line)
		out[#out + 1] = line
	end
	local charDB = OneCastCharDB or {}
	local version, build = GetBuildInfo()
	add(string.format("OneCast %s data report", ns.VERSION or "?"))
	add(string.format("Game %s (build %s), %s, %s", version or "?", build or "?", GetLocale(), date("%Y-%m-%d")))
	local rank, maxRank, modifier = ns.Stats.FishingSkill()
	add(rank and string.format("Fishing %d/%d%s", rank, maxRank,
		modifier > 0 and string.format(" (+%d from lure or pole right now)", modifier) or "") or "Fishing skill not found")
	local findings = Report.Findings()
	if #findings > 0 then
		add("")
		add("New to OneCast:")
		for _, f in ipairs(findings) do
			add("- " .. f.text)
		end
	end
	add("")
	add("Per zone: catches and getaways at each effective skill (lure and pole included).")

	local zones = {}
	for zone, z in pairs(charDB.zoneStats or {}) do
		if (z.casts or 0) > 0 then
			zones[#zones + 1] = { zone = zone, z = z }
		end
	end
	table.sort(zones, function(a, b)
		return (a.z.catches or 0) > (b.z.catches or 0)
	end)
	for _, entry in ipairs(zones) do
		local zone, z = entry.zone, entry.z
		local id = AreaID(zone)
		add("")
		add(string.format("%s%s: %d caught from %d casts, %d got away", zone, id and (" [" .. id .. "]") or "",
			z.catches or 0, z.casts or 0, z.escapes or 0))
		-- Casts that brought nothing back and weren't a getaway: reeled too early (counted from
		-- 0.7.0), or no bite reeled in before the line came back on its own or was moved.
		local empty = (z.casts or 0) - (z.catches or 0) - (z.escapes or 0)
		if empty > 0 then
			local early = math.min(z.early or 0, empty)
			add(string.format("  empty casts: %d%s", empty,
				early > 0 and string.format(" (%d reeled before a bite)", early) or ""))
		end
		local listed = ns.ZONE_FISHING_SKILL and ns.ZONE_FISHING_SKILL[zone]
		add("  OneCast lists: " .. (listed and (listed .. " for no getaways") or "no level"))
		if not SkillLines(z, add) and z.escapeSkill then
			add(string.format("  highest skill a fish got away at: %d (from before 0.7.0)", z.escapeSkill))
		end
		local spots = {}
		for name, t in pairs(z.spots or {}) do
			if name ~= zone and (t.catches or 0) > 0 then
				spots[#spots + 1] = string.format("%s %d", name, t.catches)
			end
		end
		if #spots > 0 then
			table.sort(spots)
			add("  spots: " .. table.concat(spots, ", "))
		end
		if next(z.items or {}) then
			add("  caught: " .. ItemLine(z.items))
		end
	end
	if #zones == 0 then
		add("")
		add("No fishing recorded on this character yet.")
	end

	-- Messages the game showed while a line was out that OneCast doesn't recognise: they show
	-- what to match if getaways or other fishing messages are ever missed.
	local messages = charDB.messagesWhileFishing
	if messages and #messages > 0 then
		add("")
		add("Messages seen while fishing:")
		for _, m in ipairs(messages) do
			add(string.format("- %q x%d (%s%s)", m.text, m.count, m.event, m.id and (", " .. m.id) or ""))
		end
	end

	local camp = {}
	for _, craft in ipairs(ns.Camp and ns.Camp.CRAFTS or {}) do
		local r = craft.buff and ns.Camp.Record(craft.key)
		if r and r.catches > 0 then
			camp[#camp + 1] = { craft = craft, r = r }
		end
	end
	if #camp > 0 then
		add("")
		add("Camp buffs: what was caught while each was on.")
		for _, entry in ipairs(camp) do
			local zonesHere = {}
			for zone, n in pairs(entry.r.zones) do
				zonesHere[#zonesHere + 1] = string.format("%s %d", zone, n)
			end
			table.sort(zonesHere)
			add(string.format("%s (%s): %d caught, in %s", entry.craft.buffName, entry.craft.name, entry.r.catches,
				table.concat(zonesHere, ", ")))
			add("  caught: " .. ItemLine(entry.r.items))
		end
	end
	return table.concat(out, "\n")
end

-- What the report holds, for the window's summary rows.
function Report.Summary()
	local s = { zones = 0, catches = 0, escapes = 0 }
	for _, z in pairs(OneCastCharDB and OneCastCharDB.zoneStats or {}) do
		if (z.casts or 0) > 0 then
			s.zones = s.zones + 1
			s.catches = s.catches + (z.catches or 0)
			s.escapes = s.escapes + (z.escapes or 0)
		end
	end
	return s
end

-- The window ------------------------------------------------------------------------------
-- Laid out like the tackle box: a status line by the portrait, gold summary rows under a
-- section header, then the text itself in its own panel, and the buttons along the bottom.

local WINDOW_WIDTH, WINDOW_HEIGHT = 560, 710
local BANNER_MIN_HEIGHT = 120
local STEPS_WIDTH = WINDOW_WIDTH - 100 -- the banner, less its icon and margins
local LINK_HEIGHT, LINK_GAP = 20, 6
-- Where reports go. The GitHub link opens the repo's Data report issue form.
Report.WHERE = {
	{ label = "CurseForge", url = "https://www.curseforge.com/wow/addons/onecast/comments" },
	{ label = "GitHub", url = "https://github.com/rynmon/OneCast/issues/new?template=data-report.yml" },
}
local HEADER_HEIGHT, SECTION_GAP = 26, 6
local HINT = "Ctrl+C copies it once it's selected."
local SELECTED = "|cffffd100Selected! Now press Ctrl+C to copy.|r"
local COPIED = "|cff1eff00Report copied!|r Now copy a link above, open it in your browser and paste."
local LINK_COPIED = "|cff1eff00Link copied!|r Paste it in your browser's address bar."

-- A box holding a web address, read-only, all selected when clicked: WoW can't open links,
-- so copying is the way out.
local function LinkBox(parent, url, onCopy)
	local box = ns.UI.TryCreate("EditBox", nil, parent, "InputBoxTemplate") or CreateFrame("EditBox", nil, parent)
	box:SetAutoFocus(false)
	box:SetFontObject(GameFontHighlightSmall)
	box:SetHeight(20)
	box:SetText(url)
	box:SetCursorPosition(0)
	box:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(url)
			self:HighlightText()
		end
	end)
	box:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
	end)
	box:SetScript("OnEditFocusLost", function(self)
		self:HighlightText(0, 0)
		self:SetCursorPosition(0)
	end)
	box:SetScript("OnEscapePressed", box.ClearFocus)
	box:SetScript("OnEnterPressed", box.ClearFocus)
	box:SetScript("OnKeyDown", function(_, key)
		if key == "C" and IsControlKeyDown() then
			onCopy()
		end
	end)
	return box
end

-- The banner at the top: how to share, step by step, and where to. On parchment, like the
-- book's pages, so it stands apart from the window's own panels.
local function Banner(f, inset)
	local banner = CreateFrame("Frame", nil, inset)
	banner:SetPoint("TOPLEFT", 8, -6)
	banner:SetPoint("TOPRIGHT", -8, -6)
	banner:SetHeight(BANNER_MIN_HEIGHT)
	local bg = banner:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	if ns.UI.HasAtlas("QuestBG-Parchment") then
		bg:SetAtlas("QuestBG-Parchment")
	else
		bg:SetTexture("Interface\\QuestFrame\\QuestBG")
		bg:SetTexCoord(0, 0.586, 0, 0.65)
	end
	ns.Theme.Register(bg, "parchment")
	local edge = banner:CreateTexture(nil, "BORDER")
	edge:SetColorTexture(0.55, 0.40, 0.15, 0.8)
	edge:SetPoint("TOPLEFT")
	edge:SetPoint("BOTTOMLEFT")
	edge:SetWidth(3)

	local icon = banner:CreateTexture(nil, "ARTWORK")
	icon:SetSize(36, 36)
	icon:SetPoint("TOPLEFT", 14, -12)
	icon:SetTexture("Interface\\Icons\\INV_Letter_15")
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	banner.title = banner:CreateFontString(nil, "OVERLAY")
	ns.UI.SizedFont(banner.title, QuestTitleFont, 17)
	banner.title:SetShadowOffset(0, 0)
	banner.title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
	banner.title:SetText("Share your report")

	-- A fixed width, so the steps wrap the same way every time and the banner can be sized to them.
	banner.steps = banner:CreateFontString(nil, "OVERLAY")
	ns.UI.SizedFont(banner.steps, QuestFont, 12)
	banner.steps:SetShadowOffset(0, 0)
	banner.steps:SetPoint("TOPLEFT", banner.title, "BOTTOMLEFT", 0, -4)
	banner.steps:SetWidth(STEPS_WIDTH)
	banner.steps:SetJustifyH("LEFT")
	banner.steps:SetSpacing(3)

	-- The links flow on under the steps, however many lines those took.
	banner.links = {}
	local previous
	for i, where in ipairs(Report.WHERE) do
		local label = banner:CreateFontString(nil, "OVERLAY")
		ns.UI.SizedFont(label, QuestFont, 13)
		label:SetShadowOffset(0, 0)
		label:SetSize(78, LINK_HEIGHT)
		label:SetJustifyH("LEFT")
		label:SetText(where.label)
		local box = LinkBox(banner, where.url, function()
			f.hint:SetText(LINK_COPIED)
		end)
		box:SetPoint("LEFT", label, "RIGHT", 6, 0)
		box:SetPoint("RIGHT", banner, "RIGHT", -16, 0)
		label:SetPoint("LEFT", banner, "LEFT", 20, 0)
		if previous then
			label:SetPoint("TOP", previous, "BOTTOM", 0, -LINK_GAP)
		else
			label:SetPoint("TOP", banner.steps, "BOTTOM", 0, -10)
		end
		previous = label
		banner.links[i] = { label = label, box = box }
	end

	-- What's in a report, and what isn't: said plainly, at the foot of the banner.
	banner.privacy = banner:CreateFontString(nil, "OVERLAY")
	ns.UI.SizedFont(banner.privacy, QuestFont, 12)
	banner.privacy:SetShadowOffset(0, 0)
	banner.privacy:SetPoint("LEFT", banner, "LEFT", 20, 0)
	banner.privacy:SetPoint("TOP", previous, "BOTTOM", 0, -8)
	banner.privacy:SetWidth(STEPS_WIDTH + 40)
	banner.privacy:SetJustifyH("LEFT")
	banner.privacy:SetText("Your report holds fishing numbers only. It has no character name, realm, guild, account "
		.. "or anything else that could identify you, and nothing is sent anywhere unless you paste it yourself.")
	return banner
end

-- The banner's ink follows the theme, as the book's does, highlights included. Addons can't
-- put text on the clipboard (the game keeps CopyToClipboard for its own UI), so copying is
-- always the player's Ctrl+C, and the first step says so.
local STEPS = "1.  Click %sSelect report|r below, then press %sCtrl+C|r to copy it.\n"
	.. "2.  Click a link below, press %sCtrl+C|r, and open it in your browser.\n"
	.. "3.  Paste your report into a new comment or issue, and post it. Thank you!"

local function InkBanner(banner)
	local theme = ns.Theme.Current()
	banner.title:SetTextColor(theme.ink[1], theme.ink[2], theme.ink[3])
	banner.steps:SetTextColor(theme.ink[1], theme.ink[2], theme.ink[3])
	banner.steps:SetText(string.format(STEPS, theme.lead, theme.lead, theme.lead))
	for _, link in ipairs(banner.links) do
		link.label:SetTextColor(theme.ink[1], theme.ink[2], theme.ink[3])
	end
	banner.privacy:SetTextColor(theme.inkSoft[1], theme.inkSoft[2], theme.inkSoft[3])
	-- Tall enough for the title, the steps as they wrapped, the links and the privacy note.
	local height = 12 + math.max(banner.title:GetStringHeight(), 18) + 4 + banner.steps:GetStringHeight()
		+ 10 + #banner.links * (LINK_HEIGHT + LINK_GAP) + 2 + banner.privacy:GetStringHeight() + 12
	banner:SetHeight(math.max(height, BANNER_MIN_HEIGHT))
end

local NEW_ROWS, NEW_ROW_HEIGHT = 6, 18

-- What a finding is about, for its row's icon: the fish's own, the craft's, or a map.
local MAP_ICON = "Interface\\Icons\\INV_Misc_Map_01"
local function FindingIcon(key)
	local kind, a = key:match("^(%a+):([^:]+)")
	if kind == "place" or kind == "fish" then
		return C_Item.GetItemIconByID(tonumber(a)) or MAP_ICON
	elseif kind == "camp" then
		for _, craft in ipairs(ns.Camp and ns.Camp.CRAFTS or {}) do
			if craft.key == a then
				return C_Item.GetItemIconByID(craft.item) or MAP_ICON
			end
		end
	end
	return MAP_ICON
end

local KIND_LABEL = {
	level = "No known level here",
	above = "Level may be higher",
	below = "Level may be lower",
	place = "A fish somewhere new",
	fish = "A fish OneCast doesn't have",
	camp = "What a camp buff gives",
}

local function FindingRow(parent, index, y)
	local row = CreateFrame("Frame", nil, parent)
	row:SetPoint("TOPLEFT", 10, y)
	row:SetPoint("TOPRIGHT", -10, y)
	row:SetHeight(NEW_ROW_HEIGHT)
	ns.UI.RowBackground(row, index)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(NEW_ROW_HEIGHT - 4, NEW_ROW_HEIGHT - 4)
	row.icon:SetPoint("LEFT", 4, 0)
	row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	row.tag = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.tag:SetPoint("RIGHT", -6, 0)
	row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
	row.text:SetPoint("RIGHT", row.tag, "LEFT", -6, 0)
	row.text:SetJustifyH("LEFT")
	row.text:SetWordWrap(false)
	row:EnableMouse(true)
	row:SetScript("OnEnter", function(self)
		if not self.finding then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local kind = self.finding.key:match("^(%a+)")
		GameTooltip:SetText(KIND_LABEL[kind] or "New to OneCast")
		GameTooltip:AddLine(self.finding.text, 1, 1, 1, true)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(self.shared and "Already in a report you copied." or "Not shared yet: copy your report to send it.",
			0.6, 0.8, 1, true)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", GameTooltip_Hide)
	return row
end

local function FillFindingRow(row, finding, shared)
	row.finding, row.shared = finding, shared
	row.icon:SetTexture(FindingIcon(finding.key))
	row.icon:Show()
	row.text:SetText(finding.text)
	row.tag:SetText(shared and "|cff9d9d9dshared|r" or "|cff1eff00new|r")
	row:Show()
end

local frame
local FillFindings -- below; copying the report redraws the list with it

local function CreateWindow()
	local UI = ns.UI
	local f, inset = UI.CreateShell("OneCastReportFrame", "OneCast data report", "Interface\\Icons\\INV_Misc_Note_01")
	f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	ns.UI.RememberPosition(f, "report")
	tinsert(UISpecialFrames, f:GetName())
	UI.KeepOpenThroughOptions(f:GetName())

	-- Where the tackle box has its status: right of the portrait, above the inset.
	f.status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.status:SetPoint("BOTTOMLEFT", inset, "TOPLEFT", 62, 6)
	f.status:SetPoint("RIGHT", inset, "RIGHT", -6, 0)
	f.status:SetJustifyH("LEFT")
	f.status:SetWordWrap(false)
	f.status:SetText("Help fill in Forever's real fishing numbers.")

	f.banner = Banner(f, inset)
	InkBanner(f.banner)
	-- Everything else hangs from the banner's foot, so it moves with the banner's height.
	local content = CreateFrame("Frame", nil, inset)
	content:SetPoint("TOPLEFT", f.banner, "BOTTOMLEFT", -8, -SECTION_GAP)
	content:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT")
	local y = 0
	f.newHeader = UI.SectionHeader(content, y)
	f.newHeader.text:SetText("New to OneCast")
	y = y - HEADER_HEIGHT
	-- What this character's fishing adds to what OneCast knows, one finding a row.
	f.rows = {}
	for i = 1, NEW_ROWS do
		f.rows[i] = FindingRow(content, i, y)
		y = y - NEW_ROW_HEIGHT
	end
	f.empty = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.empty:SetPoint("TOPLEFT", 16, -HEADER_HEIGHT - 6)
	f.empty:SetPoint("RIGHT", -16, 0)
	f.empty:SetJustifyH("LEFT")
	f.empty:SetWordWrap(true)
	f.empty:SetSpacing(2)
	f.empty:SetText("Nothing new yet: everything you've fished matches what OneCast already knows.\n"
		.. "|cff9d9d9dA zone with no known level, a fish getting away above a listed level, a fish somewhere new "
		.. "or catches with a camp buff will show here.|r")

	y = y - SECTION_GAP
	UI.SectionHeader(content, y).text:SetText("Report text")
	y = y - HEADER_HEIGHT - 2

	-- The text sits in its own sunken panel, like the What's new list.
	local panel = UI.TryCreate("Frame", nil, content, "InsetFrameTemplate") or CreateFrame("Frame", nil, content)
	panel:SetPoint("TOPLEFT", 8, y)
	panel:SetPoint("BOTTOMRIGHT", -8, 8)
	ns.Theme.Panel(panel)
	-- The game's slim modern scroll bar, or the classic one where that template is missing.
	local scroll = UI.TryCreate("ScrollFrame", "OneCastReportScroll", panel, "ScrollFrameTemplate")
		or UI.TryCreate("ScrollFrame", "OneCastReportScroll", panel, "UIPanelScrollFrameTemplate")
		or CreateFrame("ScrollFrame", "OneCastReportScroll", panel)
	scroll:SetPoint("TOPLEFT", 8, -6)
	scroll:SetPoint("BOTTOMRIGHT", -22, 6)
	local box = CreateFrame("EditBox", nil, scroll)
	box:SetMultiLine(true)
	box:SetAutoFocus(false)
	box:SetFontObject(GameFontHighlightSmall)
	box:SetWidth(WINDOW_WIDTH - 72)
	box:SetMaxLetters(0)
	box:SetScript("OnEscapePressed", box.ClearFocus)
	-- Read-only, and all of it selected whenever it's clicked, ready to copy.
	box:SetScript("OnTextChanged", function(self, userInput)
		if userInput then
			self:SetText(f.text or "")
			self:HighlightText()
		end
	end)
	box:SetScript("OnEditFocusGained", function(self)
		self:HighlightText()
	end)
	box:SetScript("OnKeyDown", function(_, key)
		if key == "C" and IsControlKeyDown() then
			f.hint:SetText(COPIED)
			Report.MarkShared()
			FillFindings(f)
			if ns.Stats and ns.Stats.RefreshIfShown then
				ns.Stats.RefreshIfShown()
			end
			if ns.Book and ns.Book.RefreshIfShown then
				ns.Book.RefreshIfShown()
			end
		end
	end)
	scroll:SetScrollChild(box)
	-- A click anywhere in the panel, not just on the text, focuses it.
	scroll:EnableMouse(true)
	scroll:SetScript("OnMouseDown", function()
		box:SetFocus()
	end)
	f.box = box

	local select = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	ns.Theme.Register(select, "button")
	select:SetSize(120, 22)
	select:SetPoint("BOTTOMLEFT", 10, 4)
	select:SetText("Select report")
	select:SetScript("OnClick", function()
		box:SetFocus()
		box:HighlightText()
		f.hint:SetText(SELECTED)
	end)
	select:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText("Select report")
		GameTooltip:AddLine("Selects all of it. Then press Ctrl+C to copy: the game doesn't let addons copy for you.",
			1, 1, 1, true)
		GameTooltip:Show()
	end)
	select:SetScript("OnLeave", GameTooltip_Hide)
	f.select = select
	local refresh = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	ns.Theme.Register(refresh, "button")
	refresh:SetSize(110, 22)
	refresh:SetPoint("LEFT", select, "RIGHT", 4, 0)
	refresh:SetText("Refresh")
	refresh:SetScript("OnClick", function()
		Report.Show()
	end)
	f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	f.hint:SetPoint("LEFT", refresh, "RIGHT", 10, 0)
	f.hint:SetPoint("RIGHT", f, "RIGHT", -12, 0)
	f.hint:SetJustifyH("LEFT")
	f.hint:SetWordWrap(true)
	f:Hide()
	return f
end

FillFindings = function(f)
	local s = Report.Summary()
	f.status:SetText(string.format("This character: %d zone%s fished  ·  %d catch%s  ·  %d got away",
		s.zones, s.zones == 1 and "" or "s", s.catches, s.catches == 1 and "" or "es", s.escapes))
	local findings = Report.Findings()
	local shared = OneCastCharDB and OneCastCharDB.reportFindings and OneCastCharDB.reportFindings.shared or {}
	-- Not yet shared first: that's what's worth sending.
	table.sort(findings, function(a, b)
		local sa, sb = shared[a.key] and 1 or 0, shared[b.key] and 1 or 0
		if sa ~= sb then
			return sa < sb
		end
		return a.key < b.key
	end)
	local fresh = 0
	for _, finding in ipairs(findings) do
		if not shared[finding.key] then
			fresh = fresh + 1
		end
	end
	f.newHeader.text:SetText(fresh > 0 and string.format("New to OneCast  |cff1eff00(%d to share)|r", fresh)
		or "New to OneCast")
	local shown = math.min(#findings, NEW_ROWS)
	if #findings > NEW_ROWS then
		shown = NEW_ROWS - 1
	end
	for i, row in ipairs(f.rows) do
		local finding = findings[i]
		if i <= shown and finding then
			FillFindingRow(row, finding, shared[finding.key])
		elseif i == shown + 1 and #findings > shown then
			row.icon:Hide()
			row.text:SetText(string.format("|cff9d9d9dand %d more, all in the report text below|r", #findings - shown))
			row.tag:SetText("")
			row.finding = nil
			row:Show()
		else
			row:Hide()
		end
	end
	f.empty:SetShown(#findings == 0)
end

local function Fill(f)
	FillFindings(f)
	f.text = Report.Text()
	f.box:SetText(f.text)
	f.box:SetCursorPosition(0)
	f.hint:SetText(HINT)
	InkBanner(f.banner)
end

ns.Theme.OnChange(function()
	if frame then
		InkBanner(frame.banner)
	end
end)

function Report.Show()
	frame = frame or CreateWindow()
	Fill(frame)
	frame:Show()
end

function Report.Toggle()
	if frame and frame:IsShown() then
		frame:Hide()
	else
		Report.Show()
	end
end
