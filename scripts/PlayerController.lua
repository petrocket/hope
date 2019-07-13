local Utilities = require "scripts/ToolKit/utilities"
local Events = require "scripts/ToolKit/events"
local PlayerController = {
	Properties = {
		Debug = false,
		MoveSpeed = { default = 10.0, suffix = "m/s" },
		AirMoveSpeed = {default = 1.0, suffix = "m/s"},
		MoveSpeedModifier = { default = 10.0 },
		MaxMoveSpeed = { default = 300, suffix = "m/s"},
		JumpDelay = {default = 0.5, suffix = "s"},
		JumpAmount = {default = 100.0},
		DistanceToGround = {default = 1.0, suffix = "m", description = "distance from center of object to ground"},
		DoubleJump = {default = false},
		RotationSpeed = { default = 0.2, suffix = "m/s" },
		Epsilon = { default = 0.0001 },
		SmoothFactor = { default = 0.5 },
        Enabled = true,
		Camera = { default = EntityId()},
		Audio = 
		{
			Jump = "Play_jump",
			Land = "Play_ground_hit02"
		},
		Collider = EntityId()
	},
	InputEvents = {
		OnMoveForwardBack = {},
		OnMoveLeftRight = {},
		OnLookUpDown = {},
		OnLookLeftRight = {},
		OnSpeedModifier = {},
		OnJump = {},
	},
	Events = {
		[Events.OnSetEnabled] = {},
	},
}

function PlayerController:OnActivate()
	Utilities:InitLogging(self, "PlayerController")
	Utilities:BindEvents(self, self.Events)

	self.moveDirection = Vector2(0,0)
	self.lookDirection = Vector2(0,0)
	self.moveModifier = 1
	self.jumpAmount = 0
	self.nextJumpTime = 0
	self.maxVelocitySq = self.Properties.MaxMoveSpeed * self.Properties.MaxMoveSpeed
	self.onGround = 0
	self.rayCastConfig = RayCastConfiguration()
	self.rayCastConfig.ignoreEntityIds = vector_EntityId()
	self.rayCastConfig.ignoreEntityIds:PushBack(self.entityId)
	self.rayCastConfig.ignoreEntityIds:PushBack(self.Properties.Collider)
	self.rayCastConfig.direction = Vector3(0,0,-1) 
	self.rayCastConfig.maxDistance = self.Properties.DistanceToGround
	self.rayCastConfig.maxHits = 1
	
	self:BindInputEvents(self.InputEvents)
	
	self:SetEnabled(self.Properties.Enabled)
end

function PlayerController:GetTickOrder()
	return TickOrder.Default - 1
end

function PlayerController:UpdateOnGround(playerTM)
	self.rayCastConfig.origin = playerTM:GetPosition()

	local wasOnGround = self.onGround
	self.onGround = 0
	local result = PhysicsSystemRequestBus.Broadcast.RayCast(self.rayCastConfig)
	if result ~= nil then
		if result:GetHitCount() > 0 then
			self.onGround = 1
		end
	end

	if self.onGround == 1 and wasOnGround == 0 then
		--Debug:Log("Playing Landed sound")
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.Properties.Audio.Land)
	else
		--Debug:Log("OnGround " .. tostring(self.onGround) ..  " wasOnGround " .. tostring(wasOnGround))
	end
end

function PlayerController:OnTick(deltaTime, scriptTime)
	-- raycast ground check
	local tm = TransformBus.Event.GetWorldTM(self.entityId)
	self:UpdateOnGround(tm)

	local moveSq = self.moveDirection:GetLengthSq()
	if moveSq > self.Properties.Epsilon then
		if self.Properties.Camera ~= nil and self.Properties.Camera:IsValid() then
			local move = Vector3(self.moveDirection.x ,self.moveDirection.y ,0)
			local moveSpeed = self.Properties.MoveSpeed
			if self.onGround == 0 then
				moveSpeed = self.Properties.AirMoveSpeed
			end
			move = move:GetNormalized() * moveSpeed * deltaTime
			local cameraTM = TransformBus.Event.GetWorldTM(self.Properties.Camera)
			local forward = cameraTM.basisY
			forward.z = 0
			local side = cameraTM.basisX
			side.z = 0
			local impulse = side:GetNormalized() * move.x
			impulse = impulse + forward:GetNormalized() * move.y

			RigidBodyRequestBus.Event.ApplyLinearImpulse(self.entityId, impulse)
		end
		
		-- framerate dependent smoothing (TODO make independent of fps)
		self.moveDirection.x = self.moveDirection.x * self.Properties.SmoothFactor
		self.moveDirection.y = self.moveDirection.y * self.Properties.SmoothFactor
	end	

	if self.jumpAmount > 0 then
		if self.onGround > 0 then
			self:Log("Jump")
			AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.entityId, self.Properties.Audio.Jump)
			RigidBodyRequestBus.Event.ApplyLinearImpulse(self.entityId, Vector3(0,0,self.Properties.JumpAmount))
		end
		self.jumpAmount = 0
	end

	-- cap the max velocity if we go over
	local velocity = RigidBodyRequestBus.Event.GetLinearVelocity(self.entityId)
	if velocity:GetLengthSq() > self.maxVelocitySq then
		local newVelocity = velocity:GetNormalized() * self.Properties.MaxMoveSpeed
		self:Log("Limiting velocity")
		RigidBodyRequestBus.Event.SetLinearVelocity(self.entityId, newVelocity)
	end
end

function PlayerController:OnDeactivate()
	self:UnBindInputEvents(self.InputEvents)
	Utilities:UnBindEvents(self.Events)

	if self.tickHandler ~= nil then
		self.tickHandler:Disconnect()
		self.tickHandler = nil
	end
end

function PlayerController.Events.OnSetEnabled:OnEventBegin(enabled)
	self.Component:Log("OnSetEnabled "..tostring(enabled))
	self.Component:SetEnabled(enabled)
end

function PlayerController:SetEnabled(enabled)
	self.Properties.Enabled = enabled
	
	-- connecting/disconnecting from the tickbus effectively enables/disables the camera
	if enabled then
		if self.tickHandler == nil then
			self.tickHandler = TickBus.Connect(self,0)
		end 
	else
		if self.tickHandler ~= nil then
			self.tickHandler:Disconnect()
			self.tickHandler = nil			
		end
	end
end

-- input events
function PlayerController:BindInputEvents(events)
	for event, handler in pairs(events) do
		handler.Component = self
		handler.Listener = InputEventNotificationBus.Connect(handler, InputEventNotificationId(event))
	end
end

function PlayerController:UnBindInputEvents(events)
	for event, handler in pairs(events) do
		handler.Listener:Disconnect()
		handler.Listener = nil
	end
end

function PlayerController.InputEvents.OnMoveForwardBack:OnHeld(value)
    self.Component.moveDirection.y = value
end

function PlayerController.InputEvents.OnMoveForwardBack:OnReleased(value)
	-- disabled this in favor of slowing down exponentially (slightly smoother)
	--self.Component.moveDirection.y = 0
end

function PlayerController.InputEvents.OnMoveLeftRight:OnHeld(value)
	self.Component.moveDirection.x = value
end

function PlayerController.InputEvents.OnMoveLeftRight:OnReleased(value)
	-- disabled this in favor of slowing down exponentially (slightly smoother)
	--self.Component.moveDirection.x = 0
end

function PlayerController.InputEvents.OnLookUpDown:OnHeld(value)
	self.Component.lookDirection.y = value
end

function PlayerController.InputEvents.OnLookUpDown:OnReleased(value)
	-- disabled this in favor of slowing down exponentially (slightly smoother)
	--self.Component.lookDirection.y = 0
end

function PlayerController.InputEvents.OnLookLeftRight:OnHeld(value)
	self.Component.lookDirection.x = value
end

function PlayerController.InputEvents.OnLookLeftRight:OnReleased(value)
	-- disabled this in favor of slowing down exponentially (slightly smoother)
	--self.Component.lookDirection.x = 0
end

function PlayerController.InputEvents.OnSpeedModifier:OnHeld(value)
	self.Component.moveModifier = self.Component.Properties.MoveSpeedModifier
end

function PlayerController.InputEvents.OnSpeedModifier:OnReleased(value)
	self.Component.moveModifier = 1.0
end

function PlayerController.InputEvents.OnJump:OnPressed(value)
	local time = TickRequestBus.Broadcast.GetTimeAtCurrentTick()
	if time:GetSeconds() > self.Component.nextJumpTime then
		self.Component.nextJumpTime = time:GetSeconds() + self.Component.Properties.JumpDelay
		self.Component.jumpAmount = 1.0
	end
end

return PlayerController