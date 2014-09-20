-----------------------------------------------------------------------------------------------
-- Wildstar Client Lua Script for DeathIT
-- Swags - Pergo - Exile - ralph@rgnix.com
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Tooltip"
require "XmlDoc"
require "GameLib"
require "MatchingGame"
require "ChatSystemLib"
 
-----------------------------------------------------------------------------------------------
-- DeathIT Module Definition
-----------------------------------------------------------------------------------------------
local DeathIT = {} 
 
-----------------------------------------------------------------------------------------------
-- Local Default Settings
-----------------------------------------------------------------------------------------------
local debug = false
local shoutMuted = false
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

 local knSaveVersion = 1

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
---------------------------------------------------------------------------------------+++++++++++++++++++++++++++--------
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
		self.SecondsOverlay = Apollo.LoadForm(self.xmlDoc, "SecondsOverlay", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(true, true)
		self.SecondsOverlay:Show(false, false)

		-- if the xmlDoc is no longer needed, you should set it to nil
		self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		Apollo.RegisterSlashCommand("deathit", "OnDeathITOn", self)
		Apollo.RegisterEventHandler("ChatMessage","OnChatMessage", self)
		
		-- Timers
		Apollo.RegisterTimerHandler("DeathTimer", "OnDeathTimer", self)
		Apollo.RegisterTimerHandler("ClearSecondsAlert", "SecondsAlert", self)
		
		-- Do additional Addon initialization here
		if self.locSavedWindowLoc then
			self.wndMain:MoveToLocation(self.locSavedWindowLoc)
		end
		
		if self.locSavedShout then
			self.wndMain:FindChild("Shout"):SetCheck(self.locSavedShout)
			shoutMuted = self.locSavedShout
		end
		
		self.fTimeBeforeRezable = 30000
		self.maskSpawn = 0		
		
		Apollo.CreateTimer("DeathTimer", 0.10, true)
		Apollo.StopTimer("DeathTimer")
		
		self:Debug("DeahtIT: ", "true")
			
	end
end

---------------------------------------------------------------------------------------------------
-- Save / Restore
---------------------------------------------------------------------------------------------------
function DeathIT:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	
	local tSaveData = 
	{
		
		tWindowLocation = self.wndMain and self.wndMain:GetLocation():ToTable() or self.locSavedWindowLoc:ToTable(),
		nSaveVersion = knSaveVersion,
		tSaveShout = shoutMuted,
	}
	return tSaveData
end

function DeathIT:OnRestore(eType, tSavedData)
	self.tSavedData = tSavedData
	if tSavedData and tSavedData.nSaveVersion == knSaveVersion then
		self.locSavedWindowLoc = WindowLocation.new(tSavedData.tWindowLocation)
		self.locSavedShout = tSavedData.tSaveShout
	end
		
end

-----------------------------------------------------------------------------------------------
-- DeathIT Functions
-----------------------------------------------------------------------------------------------
function DeathIT:SecondsAlert()
	self.SecondsOverlay:FindChild("TextWindow"):SetText("")
end

function DeathIT:OnDeathTimer()

if self.fTimeBeforeRezable > 0 then
	self.fTimeBeforeRezable = self.fTimeBeforeRezable - 100
	if self.fTimeBeforeRezable == 10000 then 
		self:ShoutWaveTime()
		self.SecondsOverlay:Show(true, true)
		self.SecondsOverlay:FindChild("TextWindow"):SetText("!10 Seconds Till Res Wave!")
		Apollo.CreateTimer("ClearSecondsAlert", 3, false)
	end
else
	self.fTimeBeforeRezable = 30000
end

 local strTimeBeforeRezableFormatted = self:HelperCalcTimeSecondsMS(self.fTimeBeforeRezable)
 self.wndMain:FindChild("Title"):SetText(strTimeBeforeRezableFormatted .. Apollo.GetString("CRB__seconds"))

end


function DeathIT:OnChatMessage(channelCurrent, tMessage)
	local message = tMessage.arMessageSegments[1].strText
	
	if channelCurrent:GetName() == "Instance" then	
		self:Debug("Instance: ", "true")
	end

	if 	channelCurrent:GetName() == "System" then	
		self:Debug("System: ", "true")
	end
	
	if message == "You have been kicked by the server." then
		self:Debug("MatchEnded: ", "true")
		
		-- Stop timer and reset things
		Apollo.StopTimer("DeathTimer")
		self.fTimeBeforeRezable = 30000
		self.wndMain:FindChild("Title"):SetText("0.0 seconds")
		self.maskSpawn = 0
				
	end
		
	if channelCurrent:GetName() == "Datachron" then		
		self:Debug("Datachron: ", "true")
		
		-- Moodie mask spawn. Fist spawn
		if message == "A Moodie Mask has been unearthed!" and self.maskSpawn == 0 then
			self.maskSpawn = self.maskSpawn + 1
			self:Debug("Start timer: ", "mask timer")
			self.fTimeBeforeRezable = 28000 
			-- start timer
			Apollo.StartTimer("DeathTimer")
		end
		
		self.Debug("TimerCount: ", self.maskSpawn) 
	end

end

function DeathIT:ShoutWaveTime()
	DeathIT:sendInstanceMessage("10 Seconds")
end

function DeathIT:sendInstanceMessage(message)
	if shoutMuted == false then
		for _,channel in pairs(ChatSystemLib.GetChannels()) do
			if channel:GetType() == ChatSystemLib.ChatChannel_Instance then
				channel:Send("[RES WAVE IN]: " .. message)
			end
		end
	end
end
-- on SlashCommand "/deathit"
function DeathIT:OnDeathITOn()
	self.wndMain:Invoke() -- show the window
end

-----------------------------------------------------------------------------------------------
-- Time Helper Functions 
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
-- DeathIT Form Functions
-----------------------------------------------------------------------------------------------
function DeathIT:OnMute()
	if shoutMuted == false then
		shoutMuted = true
	else
		shoutMuted = false
	end
end


function DeathIT:OnStartTimer()
	Apollo.StartTimer("DeathTimer")
end

function DeathIT:OnStopTimer()
	Apollo.StopTimer("DeathTimer")
	self.fTimeBeforeRezable = 30000
	self.maskSpawn = 0
	self.wndMain:FindChild("Title"):SetText("0.0 seconds")
end

-- when the Cancel button is clicked
function DeathIT:OnCancel()
	self.wndMain:Close() -- hide the window
	Print("type /deathit to reopen")
end

-----------------------------------------------------------------------------------------------
-- Debug
-----------------------------------------------------------------------------------------------
function DeathIT:Debug(message, error)
	if message == nil then 
		message = "nil - "
	elseif error == nil then 
		error = " nil "
	end
		
	if debug == true then
		Print(message .. error)
	end
end

-----------------------------------------------------------------------------------------------
-- DeathIT Instance
-----------------------------------------------------------------------------------------------
local DeathITInst = DeathIT:new()
DeathITInst:Init()
