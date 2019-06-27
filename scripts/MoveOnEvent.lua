local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local MoveOnEvent = 
{
    Properties = 
    {
        Event = "OnMove",
        EventTarget = EntityId(),
        Debug = false,
        MoveAmount = Vector3(0,0,1),
        MoveTarget = EntityId(),
        Duration = {default = 1.0, suffix="sec"},
        OnComplete =
        {
            Event = "OnMoveComplete",
            Target = EntityId()
        }
    }
}

function MoveOnEvent:OnActivate()
    Utilities:InitLogging(self, "MoveOnEvent")
    local targetEntityId = self.Properties.EventTarget
    if targetEntityId == nil or not targetEntityId:IsValid() then
		targetEntityId = self.entityId 
	end
    self.gameplayListener = GameplayNotificationBus.Connect(self, GameplayNotificationId(targetEntityId, self.Properties.Event, "float"))
    self.isMoving = false
    self.tweener = require "scripts/ScriptedEntityTweener/ScriptedEntityTweener"
end

function MoveOnEvent:OnEventBegin(newState)
    if self.isMoving == false then
        if self.gameplayListener then
            self.gameplayListener:Disconnect()
            self.gameplayListener = nil
        end
        self.isMoving = true
        self:Log("Moving " .. tostring(self.isMoving) .. " " .. tostring(self.entityId))
        local position = TransformBus.Event.GetLocalTranslation(self.Properties.MoveTarget)
        self.tweener:OnActivate()
        self.tweener:StartAnimation(
            self.Properties.MoveTarget, 
            self.Properties.Duration,
            {
            easeMethod=ScriptedEntityTweenerEasingMethod_Cubic,
            easeType=ScriptedEntityTweenerEasingType_InOut,
            ["3dposition"] = position + self.Properties.MoveAmount,
            onComplete = (function()
                Events:Event(self.Properties.OnComplete.Target, self.Properties.OnComplete.Event, 1.0)
                self:Log("move complete")
            end)
            }
        )
    end
end

function MoveOnEvent:OnDeactivate()
    if self.tweener ~= nil then
        self.tweener:OnDeactivate()
        self.tweener = nil
    end

   	if self.gameplayListener ~= nil then
		self.gameplayListener:Disconnect()
		self.gameplayListener = nil
	end
end

return MoveOnEvent