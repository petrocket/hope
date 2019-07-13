local Utilities = require "scripts/ToolKit/utilities"
local GameData = require "scripts/ToolKit/gamedata"

local GameDataAudioEvent = 
{
	Properties = 
	{
		Debug = true,
		AudioEvent = "",
		GameData = "",
		GameDataValue = "",
	}
}

function GameDataAudioEvent:OnActivate()
	Utilities:InitLogging(self, "GameDataAudioEvent")	
	self.value = nil
	local event = "OnGameDataUpdated" .. self.Properties.GameData
	self:Log("OnActivate " .. event)
	local id = GameplayNotificationId(EntityId(0), event, "float")
	self.listener = GameplayNotificationBus.Connect(self, id)
end

function GameDataAudioEvent:OnEventBegin(value)
	self:Log("OnEventBegin")

	if self.value ~= value and value == self.Properties.GameDataValue then
		if self.Properties.AudioEvent ~= "" then
			AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.Properties.AudioEvent)
		end
	end
end

function GameDataAudioEvent:OnDeactivate()
	if self.listener ~= nil then
		self.listener:Disconnect()
		self.listener = nil
	end
end

return GameDataAudioEvent