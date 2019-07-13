local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"
local GameData = require "scripts/ToolKit/gamedata"

local SetGameDataOnEvent =
{
    Properties = 
    {
        Debug = false,
        GameData = "",
        Event = "",
        Value = "", 
        UseEventValue = false,
    }
}

function SetGameDataOnEvent:OnActivate()
    Utilities:InitLogging(self, "SetGameDataOnEvent")

    local id = GameplayNotificationId(self.entityId, self.Properties.Event, "float")
    self.gameplayListener = GameplayNotificationBus.Connect(self,id) 
end

function SetGameDataOnEvent:OnEventBegin(value)
    self:Log("OnEventBegin " .. tostring(value))
    if self.Properties.UseEventValue then
        GameData:Set(self.Properties.GameData, value)
    else
        GameData:Set(self.Properties.GameData, self.Properties.Value)
    end
end

function SetGameDataOnEvent:OnDeactivate()
   	if self.gameplayListener ~= nil then
		self.gameplayListener:Disconnect()
		self.gameplayListener = nil
	end
end

return SetGameDataOnEvent