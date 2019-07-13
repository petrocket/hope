local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"
local GameData = require "scripts/ToolKit/gamedata"

local GameDataAnd =
{
    Properties = 
    {
        Debug = false,
        GameDataEvents = { default = {""} },
        GameData = { default="", description = "GameData to set when all others active"},
        Value = { default="", description = "GameData value to set"}
    }
}

function GameDataAnd:OnActivate()
	Utilities:InitLogging(self, "GameDataAnd")	
    self.listeners = {}
    self.numEvents = #self.Properties.GameDataEvents
    for i=1,self.numEvents do
        self.listeners[i] = {
            order = i,
            enabled = tonumber(GameData:Get(self.Properties.GameDataEvents[i])),
            OnEventBegin = function(listenerSelf, inValue)
                local value = inValue
                if type(inValue) == "boolean" then
                    if inValue then
                        value = 1 
                    else
                        value = 0 
                    end
                else
                    value = tonumber(inValue)
                    if value == nil then
                        value = 0
                    end
                end

                listenerSelf.enabled = value
                self:Log("Setting listeners.enabled to " .. tostring(value))
                self:UpdateGameData()
            end
        }
        local event = "OnGameDataUpdated" .. self.Properties.GameDataEvents[i]
        local id = GameplayNotificationId(EntityId(0),event, "float")
        self:Log("Binding order activator event " .. event)
        self.listeners[i].listener = GameplayNotificationBus.Connect(self.listeners[i], id )
    end

    self:UpdateGameData()
end

function GameDataAnd:UpdateGameData()
    local enabled = 1
    for i=1,self.numEvents do
        self:Log("listener " .. tostring(i) .. " " .. tostring(self.listeners[i].enabled ))
        if self.listeners[i].enabled == nil or self.listeners[i].enabled < 1 then
            enabled = 0
        end
    end

    GameData:Set(self.Properties.GameData, enabled)
    self:Log("updating game data " .. tostring(enabled))
end

function GameDataAnd:OnDeactivate()
    for i=1,#self.listeners do
        self.listeners[i].listener:Disconnect()
    end
    self.listeners = nil
end

return GameDataAnd