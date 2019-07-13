local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"
local GameData = require "scripts/ToolKit/gamedata"

local OrderActivater =
{
    Properties = 
    {
        Debug = false,
        GameDataEvents = { default = {""} },
        GameData = { default="", description = "GameData to set when activated in correct order"},
        Value = { default="", description = "GameData value to set"}
    }
}

function OrderActivater:OnActivate()
	Utilities:InitLogging(self, "OrderActivater")	
    self.listeners = {}
    self.numEvents = #self.Properties.GameDataEvents
    for i=1,self.numEvents do
        self.listeners[i] = {
            order = i,
            enabled = false,
            OnEventBegin = function(listenerSelf, inValue)
                local value = tonumber(inValue)
                if value < 1 then
                    listenerSelf.enabled = false 
                    self:Log("Disabling all from " .. tostring(listenerSelf.order) .. " to " .. tostring(self.numEvents) )
                    -- disable all listeners after you
                    self:DisableListenersAfter(listenerSelf.order)
                elseif listenerSelf.order == 1 or self.listeners[i - 1].enabled then
                    listenerSelf.enabled = true
                    self:Log("Enabling " .. tostring(listenerSelf.order))
                    if listenerSelf.order == self.numEvents then
                        GameData:Set(self.Properties.GameData, self.Properties.Value)
                        self:Log("All events active, updating game data " .. tostring(self.Properties.GameData))
                    end
                else
                    self:Log("Ignoring event with order " .. tostring(listenerSelf.order))
                end
            end
        }
        local event = "OnGameDataUpdated" .. self.Properties.GameDataEvents[i]
        local id = GameplayNotificationId(EntityId(0),event, "float")
        self:Log("Binding order activator event " .. event)
        self.listeners[i].listener = GameplayNotificationBus.Connect(self.listeners[i], id )
    end
end

function OrderActivater:DisableListenersAfter(order)
    for i=order,self.numEvents do
        self.listeners[i].enabled = false
    end
end

function OrderActivater:OnDeactivate()
    for i=1,#self.listeners do
        self.listeners[i].listener:Disconnect()
    end
    self.listeners = nil
end

return OrderActivater