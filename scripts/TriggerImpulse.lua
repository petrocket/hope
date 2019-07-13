local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local TriggerImpulse = {
	Properties = {
		Debug = true,
		Enabled = true,
		Impulse = Vector3(0,0,1),
		TargetTag = "",
		AudioEvent = "",
	},
	Events =
	{
		[Events.OnSetEnabled] = {}
	}
}

function TriggerImpulse:OnActivate()
	Utilities:InitLogging(self, "TriggerImpulse")	
	Utilities:BindEvents(self, self.Events)

	self.enabled = false
	self:SetEnabled(self.Properties.Enabled)
end

function TriggerImpulse:SetEnabled(enabled)
	if enabled ~= self.enabled then
		self.enabled = enabled 
		if enabled then 
			self.listener = TriggerAreaNotificationBus.Connect(self, self.entityId)
		elseif self.listener ~= nil then
			self.listener:Disconnect()
			self.listener = nil
		end
	end
end

function TriggerImpulse.Events.OnSetEnabled:OnEventBegin(enabled)
	self.Component:SetEnabled(enabled)
end

function TriggerImpulse:OnTriggerAreaEntered(entityId)
	if entityId ~= nil and entityId:IsValid() then
		local targetEntity = entityId
		if self.Properties.TargetTag ~= "" then
			targetEntity = Utilities:GetEntityWithTag(Crc32(self.Properties.TargetTag))
		end

		self:Log("OnTriggerAreaEntered firing " .. tostring(self.Properties.Impulse))
		RigidBodyRequestBus.Event.ApplyLinearImpulse(targetEntity, self.Properties.Impulse)

		if self.Properties.AudioEvent ~= "" then
			AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.Properties.AudioEvent)
		end
	end
end

function TriggerImpulse:OnTriggerAreaExited(entityId)
end

function TriggerImpulse:OnDeactivate()
	if self.listener ~= nil then
		self.listener:Disconnect()
		self.listener = nil
	end
end

return TriggerImpulse