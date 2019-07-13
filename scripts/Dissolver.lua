local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local Dissolver = 
{
    Properties = 
    {
        DissolveAmount = 0.5,
        Debug = false
    },
    Events =
    {
        [Events.OnDissolve] = {}
    }
}

function Dissolver:OnActivate()
    Utilities:InitLogging(self, "Dissolver")
    Utilities:BindEvents(self, self.Events)

    self.listener = MaterialOwnerNotificationBus.Connect(self, self.entityId)
end

function Dissolver:OnMaterialOwnerReady()
    local material = MaterialOwnerRequestBus.Event.GetMaterial(self.entityId)
    if material ~= nil then
        self:Log("Dissolving ")
        material:SetParamNumber("DissolvePercentage", self.Properties.DissolveAmount)
    end
end

function Dissolver.Events.OnDissolve:OnEventBegin(value)
    self.Component:Log("OnDissolve " .. tostring(value))
    local material = MaterialOwnerRequestBus.Event.GetMaterial(self.entityId)
    if material ~= nil then
        material:SetParamNumber("DissolvePercentage", value)
    end
end

function Dissolver:OnDeactivate()
    Utilities:UnBindEvents(self.Events)
    if self.listener ~= nil then
        self.listener:Disconnect()
        self.listener = nil
    end
end

return Dissolver