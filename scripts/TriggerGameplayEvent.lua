local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local TriggerGameplayEvent = {
	Properties = {
		Debug = true,
		Event = "",
		AudioEvent = "",
		Value = "",
		Global = false,
		TargetTag = "",
		DestroyOnTrigger = false,
		Enabled = true,
		OnEmpty =
		{
			Event = "OnEmpty",
			Value = "",
			AudioEvent = ""
		}
	},
	Events =
	{
		[Events.OnSetEnabled] = {}
	}
}

function TriggerGameplayEvent:OnActivate()
	Utilities:InitLogging(self, "TriggerGameplayEvent")	
	Utilities:BindEvents(self, self.Events)

	self.tickListener = nil
	self.enabled = false
	self.numEntitiesInTrigger = 0
	self:SetEnabled(self.Properties.Enabled)
end

function TriggerGameplayEvent:SetEnabled(enabled)
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

function TriggerGameplayEvent.Events.OnSetEnabled:OnEventBegin(enabled)
	self.Component:SetEnabled(enabled)
end

function TriggerGameplayEvent:OnTick(deltaTime, scriptTime)
end

function TriggerGameplayEvent:OnCollision(collision)
    self:Log(tostring(collision.entity) .. " " .. tostring(collision.CollisionBegin))
    --if collision.entity and collision.CollisionBegin then
    --end
end

function TriggerGameplayEvent:NotifyEntitiesWithTag(tag, event, value)
	self:Log("Looking for entities with tag " .. tostring(tag))
	local entities = ToolKitRequestBus.Broadcast.GetEntitiesWithTag(Crc32(tag))
	if entities ~= nil and #entities then
		for i=1,#entities do
			local tagEntityId = entities[i]

			self:Log("Notifying entity " .. tostring(tagEntityId))
			Events:Event(tagEntityId, event, value)

			--self:Log("Checking entity " .. tostring(tagEntityId))
			--local position = TransformBus.Event.GetWorldTranslation(tagEntityId)
			--if ShapeComponentRequestsBus.Event.IsPointInside(self.entityId, position) then
			--	self:Log("Notifying entity " .. tostring(tagEntityId))
				--Events:Event(tagEntityId, self.Properties.Event, self.Properties.Value)
			--end
		end
	end
end

function TriggerGameplayEvent:OnTriggerAreaEntered(entityId)
	self.numEntitiesInTrigger = self.numEntitiesInTrigger + 1
	if entityId ~= nil and entityId:IsValid() then
		self:Log("OnTriggerAreaEntered firing " .. tostring(self.Properties.Event))
		
		if self.Properties.Global then
			Events:GlobalEvent(self.Properties.Event, self.Properties.Value)
		elseif self.Properties.TargetTag ~= "" then
			self:NotifyEntitiesWithTag(self.Properties.TargetTag, self.Properties.Event, self.Properties.Value )
		else
			Events:Event(entityId, self.Properties.Event, self.Properties.Value)
		end

		if self.Properties.AudioEvent ~= "" then
			AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.Properties.AudioEvent)
		end
		
		if self.Properties.DestroyOnTrigger then
			GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entityId)
		end
	end
end

function TriggerGameplayEvent:OnTriggerAreaExited(entityId)
	self.numEntitiesInTrigger = Math.Max(0, self.numEntitiesInTrigger - 1)
	if self.numEntitiesInTrigger == 0 then
		self:Log("OnTriggerAreaExited firing " .. tostring(self.Properties.OnEmpty.Event))
		if self.Properties.Global then
			Events:GlobalEvent(self.Properties.OnEmpty.Event, self.Properties.OnEmpty.Value)
		elseif self.Properties.TargetTag ~= "" then
			self:NotifyEntitiesWithTag(self.Properties.TargetTag, self.Properties.OnEmpty.Event, self.Properties.OnEmpty.Value )
		else
			Events:Event(entityId, self.Properties.OnEmpty.Event, self.Properties.OnEmpty.Value)
		end

		if self.Properties.OnEmpty.AudioEvent ~= "" then
			AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.Properties.OnEmpty.AudioEvent)
		end
	end
end

function TriggerGameplayEvent:OnDeactivate()
	if self.listener ~= nil then
		self.listener:Disconnect()
		self.listener = nil
	end
end

return TriggerGameplayEvent