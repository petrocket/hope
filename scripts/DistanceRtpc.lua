local DistanceRTPC = 
{
    Properties = 
    {
        Target = EntityId(),
        MaxDistance = 100,
        RTPC = ""
    }
}

function DistanceRTPC:OnActivate()
    self.listener = TransformNotificationBus.Connect(self, self.Properties.Target)
end

function DistanceRTPC:OnTransformChanged(localTM, worldTM)
    -- update RTPC
    local position = TransformBus.Event.GetWorldTranslation(self.entityId)
    local distance = math.min(self.Properties.MaxDistance, position:GetDistance(worldTM:GetPosition()))

    --Debug.Log(tostring(distance))
    AudioRtpcComponentRequestBus.Event.SetRtpcValue(self.entityId, self.Properties.RTPC, distance / self.Properties.MaxDistance)
end

function DistanceRTPC:OnDeactivate()
    if self.listener ~= nil then
        self.listener:Disconnect()
        self.listener = nil
    end 
end


return DistanceRTPC