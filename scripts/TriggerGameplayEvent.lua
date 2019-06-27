local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local TriggerGameplayEvent = {
	Properties = {
		Debug = true,
		Event = "",
		Value = "",
		TriggerWhileInside = true,
		Global = false,
		TargetTag = "",
		DestroyOnTrigger = false,
	},
}

function TriggerGameplayEvent:OnActivate()
	Utilities:InitLogging(self, "TriggerGameplayEvent")	
	self.listener = TriggerAreaNotificationBus.Connect(self, self.entityId)
	--self.listener = PhysicsComponentNotificationBus.Connect(self, self.entityId)
	self.tickListener = nil
end


function TriggerGameplayEvent:OnTick(deltaTime, scriptTime)
end

function TriggerGameplayEvent:OnCollision(collision)
    self:Log(tostring(collision.entity) .. " " .. tostring(collision.CollisionBegin))
    --if collision.entity and collision.CollisionBegin then
    --end
end

function TriggerGameplayEvent:OnTriggerAreaEntered(entityId)
	if entityId ~= nil and entityId:IsValid() then
		self:Log("OnTriggerAreaEntered firing " .. tostring(self.Properties.Event))
		
		if self.Properties.Global then
			Events:GlobalEvent(self.Properties.Event, self.Properties.Value)
		elseif self.Properties.TargetTag ~= "" then
			self:Log("Looking for entities with tag " .. tostring(self.Properties.TargetTag))
			local entities = ToolKitRequestBus.Broadcast.GetEntitiesWithTag(Crc32(self.Properties.TargetTag))
			if entities ~= nil and #entities then
				for i=1,#entities do
					
                    local tagEntityId = entities[i]

					self:Log("Notifying entity " .. tostring(tagEntityId))
                    Events:Event(tagEntityId, self.Properties.Event, self.Properties.Value)

					--self:Log("Checking entity " .. tostring(tagEntityId))
					--local position = TransformBus.Event.GetWorldTranslation(tagEntityId)
					--if ShapeComponentRequestsBus.Event.IsPointInside(self.entityId, position) then
					--	self:Log("Notifying entity " .. tostring(tagEntityId))
						--Events:Event(tagEntityId, self.Properties.Event, self.Properties.Value)
					--end
				end
			end
		else
			Events:Event(entityId, self.Properties.Event, self.Properties.Value)
		end
		
		if self.Properties.DestroyOnTrigger then
			GameEntityContextRequestBus.Broadcast.DestroyDynamicSliceByEntity(self.entityId)
		end
	end
end

function TriggerGameplayEvent:OnTriggerAreaExited(entityId)

end

function TriggerGameplayEvent:OnDeactivate()
	if self.listener ~= nil then
		self.listener:Disconnect()
		self.listener = nil
	end
end


return TriggerGameplayEvent