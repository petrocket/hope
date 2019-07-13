local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local Teleporter = {
	Properties = {
		Debug = true,
		PlayerTag = "Player",
		TargetTag = "",
		OnTeleportStartEvent = "OnTeleportStart",
		OnTeleportStartValue = "",
		TeleportStartDelay = 1.0,
		OnTeleportEndEvent = "OnTeleportEnd",
		OnTeleportEndValue = "",
		TeleportEndDelay = 1.0,
	},
}

function Teleporter:OnActivate()
	Utilities:InitLogging(self, "Teleporter")	
	self.triggerListener = TriggerAreaNotificationBus.Connect(self, self.entityId)
	self.teleportStartTime = 0
	self.teleportEndTime = 0
end

function Teleporter:OnTriggerAreaEntered(entityId)
	if entityId ~= nil and entityId:IsValid() then
		self.entityToTeleport = entityId
		local entities = ToolKitRequestBus.Broadcast.GetEntitiesWithTag(Crc32(self.Properties.PlayerTag))
		if entities ~= nil and #entities > 0 then
			self.entityToTeleport = entities[1] 
		end
		self:Log("OnTriggerAreaEntered teleporting " .. tostring(entityId))
		Events:GlobalEvent(self.Properties.OnTeleportStartEvent, self.Properties.OnTeleportStartValue)
		Events:Event(self.entityToTeleport,Events.OnSetEnabled,false)
		if self.triggerListener ~= nil then
			self.triggerListener:Disconnect()
		end

		local currentTime = TickRequestBus.Broadcast.GetTimeAtCurrentTick()
		self.teleportStartTime = currentTime:GetSeconds() + self.Properties.TeleportStartDelay
		self.tickListener = TickBus.Connect(self, 0)
	end
end

function Teleporter:OnTick(deltaTime, scriptTime)
	if self.teleportEndTime > 0 and scriptTime:GetSeconds() > self.teleportEndTime then
		self:Log("Enabling teleported entity")
		self.teleportEndTime = 0
		if self.tickListener ~= nil then
			self.tickListener:Disconnect()
		end

		--GameEntityContextRequestBus.Broadcast.ActivateGameEntity(self.entityToTeleport)
		--RigidBodyRequestBus.Event.SetSimulationEnabled(self.entityToTeleport,true)
		RigidBodyRequestBus.Event.EnablePhysics(self.entityToTeleport)
		Events:Event(self.entityToTeleport,Events.OnSetEnabled,true)
		Events:GlobalEvent(self.Properties.OnTeleportEndEvent, self.Properties.OnTeleportEndValue)

		-- reconnect to trigger bus
		self.triggerListener = TriggerAreaNotificationBus.Connect(self, self.entityId)
	elseif self.teleportStartTime > 0 and scriptTime:GetSeconds() > self.teleportStartTime then
		self.teleportStartTime = 0
		self.teleportEndTime = scriptTime:GetSeconds() + self.Properties.TeleportEndDelay
		local entities = ToolKitRequestBus.Broadcast.GetEntitiesWithTag(Crc32(self.Properties.TargetTag))
		if entities ~= nil and #entities > 0 then
			local targetPosition = TransformBus.Event.GetWorldTranslation(entities[1])
			if targetPosition ~= nil then
				local currentPosition = TransformBus.Event.GetWorldTranslation(self.entityToTeleport)
				self:Log("Teleporting entity from " .. tostring(currentPosition) .. " to " .. tostring(targetPosition))

				-- don't need any of these (which don't really work right) if we jsut deactivate/activate after moving
				--PhysicsComponentRequestBus.Event.DisablePhysics(self.entityToTeleport)
				--RigidBodyRequestBus.Event.SetSimulationEnabled(self.entityToTeleport,false)
				--RigidBodyRequestBus.Event.DisablePhysics(self.entityToTeleport)

				TransformBus.Event.SetWorldTranslation(self.entityToTeleport, targetPosition )

				-- deactivate/reactivate or rigid body will teleport us back!
				GameEntityContextRequestBus.Broadcast.DeactivateGameEntity(self.entityToTeleport)
				GameEntityContextRequestBus.Broadcast.ActivateGameEntity(self.entityToTeleport)
				local children = TransformBus.Event.GetChildren(self.entityToTeleport)
				if children ~= nil then
					self:Log("teleporting child")
					--local position = TransformBus.Event.GetWorldTranslation(self.entityId)
					for i=1,#children do
						self:Log("teleporting child")
						TransformBus.Event.SetWorldTranslation(children[i], targetPosition )
						--TransformBus.Event.SetWorldTranslation(children[i], position)
					end
				end
				Events:Event(self.entityToTeleport,Events.OnSetEnabled,false)
				RigidBodyRequestBus.Event.DisablePhysics(self.entityToTeleport)
				--RigidBodyRequestBus.Event.SetSimulationEnabled(self.entityToTeleport,true)
				--RigidBodyRequestBus.Event.EnablePhysics(self.entityToTeleport)
				--RigidBodyRequestBus.Event.EnablePhysics(self.entityToTeleport)
				--PhysicsComponentRequestBus.Event.EnablePhysics(self.entityToTeleport)
			else
				self:Log("Teleporter couldn't get target position " .. tostring(entities[1]))
			end
		else
			self:Log("Teleporter couldn't find target")
		end
	end
end

function Teleporter:OnTriggerAreaExited(entityId)

end

function Teleporter:OnDeactivate()
	if self.tickListener ~= nil then
		self.tickListener:Disconnect()
		self.tickListener = nil
	end
	if self.triggerListener ~= nil then
		self.triggerListener:Disconnect()
		self.triggerListener = nil
	end
end


return Teleporter