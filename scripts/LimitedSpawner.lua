local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local LimitedSpawner =
{
    Properties = 
    {
        Debug = false,
        Event = "OnSpawn",
    },
}

function LimitedSpawner:OnActivate()
    Utilities:InitLogging(self, "LimitedSpawner")
    self.gameplayListener = GameplayNotificationBus.Connect(self, GameplayNotificationId(self.entityId, self.Properties.Event, "float"))
end

function LimitedSpawner:OnEventBegin(value)
    SpawnerComponentRequestBus.Event.DestroyAllSpawnedSlices(self.entityId)
    SpawnerComponentRequestBus.Event.Spawn(self.entityId)
end

function LimitedSpawner:OnDeactivate()
    if self.gameplayListener ~= nil then
        self.gameplayListener:Disconnect()
        self.gameplayListener = nil
    end
end

return LimitedSpawner