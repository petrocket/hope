local Utilities = require "scripts/ToolKit/utilities"

local UIGameplayEventSequence = 
{
	Properties = {
		Debug = false,
		Event = "",
	}
}

function UIGameplayEventSequence:OnActivate()
	Utilities:InitLogging(self, "UIGameplayEventSequence")
    local id = GameplayNotificationId(EntityId(0), self.Properties.Event, "float")
    self.gameplayListener = GameplayNotificationBus.Connect(self,id) 
end

function UIGameplayEventSequence:OnEventBegin(value)
	self:Log("OnEventBegin " .. tostring(value))
	UiAnimationBus.Event.ResetSequence(self.entityId, value)
	UiAnimationBus.Event.StartSequence(self.entityId, value)
end

function UIGameplayEventSequence:OnDeactivate()
   	if self.gameplayListener ~= nil then
		self.gameplayListener:Disconnect()
		self.gameplayListener = nil
	end
end

return UIGameplayEventSequence
