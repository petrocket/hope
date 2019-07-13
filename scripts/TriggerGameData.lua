local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"
local GameData = require "scripts/ToolKit/gamedata"

local TriggerGameData = {
	Properties = {
		Debug = true,
		GameData = "",
		Value = "",
		TargetTag = "",
		DestroyOnTrigger = false,
		Enabled = true,
		AudioEvent = "",
		GameDataEnabler = { default ="", description="If not empty, this game data must be 1 to enable this trigger"},
		GameDataParent = { default = "", description = "If the parent is on then this will always be on too"},
		TriggerOnce = {default=false, description = "true if once entered this remains on and can't be triggered again"},
		OnEmpty =
		{
			Delay = 0.0,
			Value = "",
			AudioEvent = ""
		}
	},
	Events =
	{
		[Events.OnSetEnabled] = {}
	}
}

function TriggerGameData:OnActivate()
	Utilities:InitLogging(self, "TriggerGameData")	
	Utilities:BindEvents(self, self.Events)

	self.enabled = true 
	self.numEntitiesInTrigger = 0

	if self.Properties.GameDataEnabler ~= "" then
		self:Log("gamedataenabler " .. self.Properties.GameDataEnabler .. " "  .. GameData:Get(self.Properties.GameDataEnabler))
		local enabled = GameData:Get(self.Properties.GameDataEnabler)
		if enabled == nil then
			enabled = false 
		end
		self:SetEnabled(enabled)
		local id = GameplayNotificationId(EntityId(0), "OnGameDataUpdated" .. self.Properties.GameDataEnabler, "float")
		self.gamedataListener = GameplayNotificationBus.Connect(self, id)
	else
		self:SetEnabled(self.Properties.Enabled)
	end

	if self:GameDataParentActive() then
		GameData:Set(self.Properties.GameData, self.Properties.Value)
	end
end

function TriggerGameData:OnEventBegin(value)
	local enabled = value 
	if enabled == nil then
		enabled = false 
	end
	self:Log("OnGameDataUpdated" .. tostring(self.Properties.GameDataEnabler) .. " " .. tostring(value))
	self:SetEnabled(enabled)
end

function TriggerGameData:SetEnabled(enabled)
	self:Log("Pre SetEnabled " .. tostring(enabled) .. " type " ..tostring(type(enabled)))
	-- tonumber converts booleans to nil
	if type(enabled) == "boolean" then
		self.enabled = enabled
	else
		self.enabled = tonumber(enabled) 
		if self.enabled == nil or self.enabled < 1 then
			self.enabled = false
		else
			self.enabled = true
		end
	end
	self:Log("Post converion SetEnabled " .. tostring(self.enabled) .. " type " ..tostring(type(self.enabled)))

	if self.enabled then 
		self:Log("enabling " .. tostring(self.enabled))
		if self.listener == nil then
			self.listener = TriggerAreaNotificationBus.Connect(self, self.entityId)
		end
	elseif self.listener ~= nil then
		self:Log("disabling")
		self.listener:Disconnect()
		self.listener = nil
	end
end

function TriggerGameData.Events.OnSetEnabled:OnEventBegin(enabled)
	self.Component:SetEnabled(enabled)
end

function TriggerGameData:OnTriggerAreaEntered(entityId)
	self.numEntitiesInTrigger = self.numEntitiesInTrigger + 1
	if entityId ~= nil and entityId:IsValid() then
		self:Log("OnTriggerAreaEntered setting data " .. tostring(self.Properties.GameData) .. " " .. tostring(self.Properties.Value))
		GameData:Set(self.Properties.GameData, self.Properties.Value)

		if self.Properties.AudioEvent ~= "" then
			AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.Properties.AudioEvent)
		end
		
		if self.Properties.DestroyOnTrigger then
			GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entityId)
		end
	end
end

function TriggerGameData:GameDataParentActive()
	if self.Properties.GameDataParent ~= nil and self.Properties.GameDataParent ~= "" then
		-- turn on!
		local value = tonumber(GameData:Get(self.Properties.GameDataParent))
		return value ~= nil and value > 0
	end
	return false
end

function TriggerGameData:OnTick(deltaTime, scriptTime)
	if scriptTime:GetSeconds() > self.delayEndTime then
		if self:GameDataParentActive() then
			self:Log("Not deactivating because parent is active")
		else
			self:Log("delay setting data " .. tostring(self.Properties.GameData) .. " " .. tostring(self.Properties.OnEmpty.Value))
			GameData:Set(self.Properties.GameData, self.Properties.OnEmpty.Value)
			if self.Properties.OnEmpty.AudioEvent ~= "" then
				AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.Properties.OnEmpty.AudioEvent)
			end
		end

		if self.tickListener ~= nil then
			self.tickListener:Disconnect()
			self.tickListener = nil
		end
	end
end

function TriggerGameData:OnTriggerAreaExited(entityId)
	self.numEntitiesInTrigger = Math.Max(0, self.numEntitiesInTrigger - 1)
	if self.numEntitiesInTrigger == 0 and self.Properties.OnEmpty.Value ~= "" then
		if self:GameDataParentActive() then
			self:Log("Not deactivating because parent is active")
		else
			if self.Properties.OnEmpty.Delay > 0 then
				local time = TickRequestBus.Broadcast.GetTimeAtCurrentTick()
				self.delayEndTime = time:GetSeconds() + self.Properties.OnEmpty.Delay
				if self.tickListener == nil then
					self.tickListener = TickBus.Connect(self,0)
				end
			else
				if self.Properties.OnEmpty.AudioEvent ~= "" then
					AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.Properties.AudioEvent)
				end
				self:Log("OnTriggerAreaExited setting data " .. tostring(self.Properties.GameData) .. " " .. tostring(self.Properties.OnEmpty.Value))
				GameData:Set(self.Properties.GameData, self.Properties.OnEmpty.Value)
			end
		end
	end
end

function TriggerGameData:OnDeactivate()
	if self.listener ~= nil then
		self.listener:Disconnect()
		self.listener = nil
	end
	if self.tickListener ~= nil then
		self.tickListener:Disconnect()
		self.tickListener = nil
	end
end

return TriggerGameData