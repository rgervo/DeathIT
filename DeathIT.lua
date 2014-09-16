-----------------------------------------------------------------------------------------------
-- Client Lua Script for DeathIT
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Tooltip"
require "XmlDoc"
require "GameLib"
require "MatchingGame"
 
-----------------------------------------------------------------------------------------------
-- DeathIT Module Definition
-----------------------------------------------------------------------------------------------
local DeathIT = {} 
 
-----------------------------------------------------------------------------------------------
-- Local Default Settings
-----------------------------------------------------------------------------------------------
local defaultSettings = {
	  wndPosition = {
		[1] = {0, -0, 0, -0},
	  },
	-- other settings
	debug = false,
}
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function DeathIT:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function DeathIT:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = "DeathIT"
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- DeathIT OnLoad
-----------------------------------------------------------------------------------------------
function DeathIT:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("DeathIT.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- DeathIT OnDocLoaded
-----------------------------------------------------------------------------------------------
function DeathIT:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "DeathITForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(true, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("deathit", "OnDeathITOn", self)
		
		
		Apollo.RegisterTimerHandler("DeathTimer", "OnDeathTimer", self)
		
		-- Do additional Addon initialization here
		self.nTimerProgress = nil
		self.bDead = false
		self.fTimeBeforeRezable = 30000		
		Apollo.CreateTimer("DeathTimer", 0.10, true)
		Apollo.StopTimer("DeathTimer")
		
			
	end
end

-----------------------------------------------------------------------------------------------
-- DeathIT Functions
-----------------------------------------------------------------------------------------------
function DeathIT:OnDeathTimer()

if self.fTimeBeforeRezable > 0 then
	self.fTimeBeforeRezable = self.fTimeBeforeRezable - 100
else
	self.fTimeBeforeRezable = 30000
end

 local strTimeBeforeRezableFormatted = self:HelperCalcTimeSecondsMS(self.fTimeBeforeRezable)
 self.wndMain:FindChild("Title"):SetText(strTimeBeforeRezableFormatted .. Apollo.GetString("CRB__seconds"))

end

-- on SlashCommand "/deathit"
function DeathIT:OnDeathITOn()
	self.wndMain:Invoke() -- show the window
end

-----------------------------------------------------------------------------------------------
-- Helper Time Functions 
-----------------------------------------------------------------------------------------------
function DeathIT:HelperCalcTimeSecondsMS(fTimeMS)
	local fTime = math.floor(fTimeMS / 1000)
	local fMillis = fTimeMS % 1000
	return string.format("%d.%d", fTime, math.floor(fMillis / 100))
end

function DeathIT:HelperCalcTimeMS(fTimeMS)
	local fSeconds = fTimeMS / 1000
	local fMillis = fTimeMS % 1000
	local strOutputSeconds = "00"
	if math.floor(fSeconds % 60) >= 10 then
		strOutputSeconds = tostring(math.floor(fSeconds % 60))
	else
		strOutputSeconds = "0" .. math.floor(fSeconds % 60)
	end
	
	return String_GetWeaselString(Apollo.GetString("CRB_TimeMinsToMS"), math.floor(fSeconds / 60), strOutputSeconds, math.floor(fMillis / 100))
end

function DeathIT:HelperCalcTime(fSeconds)
	local strOutputSeconds = "00"
	if math.floor(fSeconds % 60) >= 10 then
		strOutputSeconds = tostring(math.floor(fSeconds % 60))
	else
		strOutputSeconds = "0" .. math.floor(fSeconds % 60)
	end
	
	return String_GetWeaselString(Apollo.GetString("CRB_TimeMinsToMS"), math.floor(fSeconds / 60), strOutputSeconds)
end


-----------------------------------------------------------------------------------------------
-- DeathITForm Functions
-----------------------------------------------------------------------------------------------
function DeathIT:OnStartTimer()
	Apollo.StartTimer("DeathTimer")
end

function DeathIT:OnStopTimer()
	Apollo.StopTimer("DeathTimer")
	self.fTimeBeforeRezable = 30000
	self.wndMain:FindChild("Title"):SetText("0.0 seconds")
end

-- when the Cancel button is clicked
function DeathIT:OnCancel()
	self.wndMain:Close() -- hide the window
end

-----------------------------------------------------------------------------------------------
-- Debug
-----------------------------------------------------------------------------------------------
function DeathIT:Debug(message, error)
	if defaultSettings.debug == true then
		Print(message .. error)
	end
end

-----------------------------------------------------------------------------------------------
-- DeathIT Instance
-----------------------------------------------------------------------------------------------
local DeathITInst = DeathIT:new()
DeathITInst:Init()
