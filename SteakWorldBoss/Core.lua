local updater = CreateFrame("Frame")

local SBFrame = CreateFrame("Button", "SoulbreakerCountdown", UIParent)

SBFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
SBFrame:EnableMouse(true)
SBFrame:SetMovable(true)
SBFrame:RegisterForDrag("LeftButton")
SBFrame:SetScript("OnDragStart", SBFrame.StartMoving)
SBFrame:SetScript("OnDragStop", SBFrame.StopMovingOrSizing)

SBFrame.bg = SBFrame:CreateTexture(nil, "BACKGROUND")
SBFrame.bg:SetAllPoints()
SBFrame.bg:SetTexture(0, 0, 0, 0.6)

SBFrame.text = SBFrame:CreateFontString(nil, "OVERLAY")
SBFrame.text:SetFont("Interface\\AddOns\\SoulbreakerAlert\\Audiowide-Regular.ttf", 10, "OUTLINED")
SBFrame.text:SetPoint("CENTER")
SBFrame.text:SetText("Soulbreaker Countdown: 0h 0m")
SBFrame.text:SetJustifyH("CENTER")

SBFrame:SetSize(SBFrame.text:GetWidth() + 10, SBFrame.text:GetHeight() + 10)

local Toast = CreateFrame("Frame", "SoulbreakerToast", UIParent)

Toast:SetSize(280, 60)
Toast:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
Toast:Hide()

Toast.bg = Toast:CreateTexture(nil, "BACKGROUND")
Toast.bg:SetAllPoints()
Toast.bg:SetTexture(0, 0, 0, 0.75)

Toast.text = Toast:CreateFontString(nil, "OVERLAY")
Toast.text:SetFont("Interface\\AddOns\\SoulbreakerAlert\\Audiowide-Regular.ttf", 12, "OUTLINED")
Toast.text:SetPoint("CENTER")
Toast.text:SetWidth(Toast:GetWidth() - 30)
Toast.text:SetJustifyH("CENTER")

Toast.state = "idle"
Toast.timer = 0
Toast.fadeIn = 0.3
Toast.hold = 5
Toast.fadeOut = 0.5

local spawnTimes = { {2, 0}, {10, 0}, {18, 0} }
local alertTimes = {60, 30, 10, 0}
local fired = {}

local function MinutesUntilNextSpawn()
	local hour, min = GetGameTime()
	local now = hour * 60 + min

	local today = {}
	for _, t in ipairs(spawnTimes) do
		table.insert(today, t[1] * 60 + t[2])
	end

	table.sort(today)

	for _, spawn in ipairs(today) do
		if now < spawn then
			return spawn - now, spawn
		end
	end

	return (24 * 60 - now) + today[1], today[1]
end

local function FormatTime(min)
	min = min * 60
	local h = math.floor(min / 3600)
	local m = math.floor((min % 3600) / 60)
	return string.format("%dh %dm", h, m)
end

updater:SetScript("OnUpdate", function(self, elapsed)
	self.timer = (self.timer or 0) + elapsed
	if self.timer < 1 then return end
	self.timer = 0

	local mins = MinutesUntilNextSpawn()
	local color = "|cffffffff"

	if mins < 10 then
		color = "|cffff0000"
	elseif mins >= 10 and mins < 30 then
		color = "|cffff8000"
	elseif mins <= 60 then
		color = "|cffffff00"
	end

	SBFrame:SetSize(math.max(SBFrame.text:GetWidth()+10, SBFrame:GetWidth()), math.max(SBFrame.text:GetHeight()+10, SBFrame:GetHeight())

	SBFrame.text:SetText("Soulbreaker Countdown: "..color..FormatTime(mins))
end)

SBFrame:SetScript("OnClick", function(self, button)
	local mins = MinutesUntilNextSpawn()

	if GetNumRaidMembers() > 0 then
		SendChatMessage("Soulbreaker in "..FormatTime(mins), "RAID")
	elseif GetNumPartyMembers() > 0 then
		SendChatMessage("Soulbreaker in "..FormatTime(mins), "PARTY")
	elseif GetGuildRosterInfo(1) ~= nil then
		SendChatMessage("Soulbreaker in "..FormatTime(mins), "GUILD")
	else
		SendChatMessage("Soulbreaker in "..FormatTime(mins), "YELL")
	end
end)

Toast:SetScript("OnUpdate", function(self, elapsed)
	if self.state == "idle" then
		self:Hide()
		return
	end

	self.timer = self.timer + elapsed

	if self.state == "fadein" then
		local a = self.timer / self.fadeIn
		if a >= 1 then
			a = 1
			self.state = "hold"
			self.timer = 0
		end
		self:SetAlpha(a)
		return
	end

	if self.state == "hold" then
		if self.timer >= self.hold then
			self.state = "fadeout"
			self.timer = 0
		end
		return
	end

	if self.state == "fadeout" then
		local a = 1 - (self.timer / self.fadeOut)
		if a <= 0 then
			a = 0
			self.state = "idle"
			self.timer = 0
		end
		self:SetAlpha(a)
		return
	end
end)

function Toast:ShowMessage(msg)
	self.text:SetText(msg)
	self:SetSize(self.text:GetWidth()+30, self.text:GetHeight()+30)
	self.timer = 0
	self.state = "fadein"
	self:SetAlpha(0)
	self:Show()
end

local f = CreateFrame("Frame", nil, UIParent)

local function OnUpdate(self, elapsed)
	self.timer = (self.timer or 0) + elapsed

	if self.timer >= 1 then
		local remaining = MinutesUntilNextSpawn()

		for _, mins in ipairs(alertTimes) do
			if remaining == mins then
				if not fired[mins] then
					if remaining == 0 then
						Toast:ShowMessage("Souldbreaker has spawned!")
					else
						Toast:ShowMessage("Soulbreaker spawns in "..remaining.." minute(s).")
					end
					fired[mins] = true
				end
			else
				fired[mins] = false
			end
		end

		self.timer = 0
	end
end

f:SetScript("OnUpdate", OnUpdate)
