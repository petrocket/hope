local Follower =
{
    Properties =
    {
        Target = EntityId()
    }
}

function Follower:OnActivate()
    self.listener = EntityBus.Connect(self, self.Properties.Target)
end
function Follower:OnEntityActivated(entity)
    if self.listener ~= nil then
        self.listener:Disconnect()
        self.listener = nil
    end
    self.transformListener = TransformNotificationBus.Connect(self, self.Properties.Target)
    local position = TransformBus.Event.GetWorldTranslation(self.entityId)
    local targetPosition = TransformBus.Event.GetWorldTranslation(self.Properties.Target)
    self.offset = position - targetPosition
end

function Follower:OnTransformChanged(localTM, worldTM)
    TransformBus.Event.SetWorldTranslation(self.entityId, worldTM:GetPosition() + self.offset)
end

function Follower:OnDeactivate()
    if self.transformListener ~= nil then
        self.transformListener:Disconnect()
        self.transformListener = nil
    end
    if self.listener ~= nil then
        self.listener:Disconnect()
        self.listener = nil
    end
end

return Follower