local PlayerController = {
	Properties = {
		MoveSpeed = { default = 10.0, suffix = "m/s" },
		MoveSpeedModifier = { default = 10.0 },
		RotationSpeed = { default = 0.2, suffix = "m/s" },
		Epsilon = { default = 0.0001 },
		SmoothFactor = { default = 0.5 },
        Enabled = true,
        Camera = { default = EntityId()}
	},
	InputEvents = {
		OnMoveForwardBack = {},
		OnMoveLeftRight = {},
		OnLookUpDown = {},
		OnLookLeftRight = {},
		OnSpeedModifier = {},
	},
}

function PlayerController:OnActivate()
	self.moveDirection = Vector2(0,0)
	self.lookDirection = Vector2(0,0)
	self.moveModifier = 1
	
	self:BindInputEvents(self.InputEvents)
	
	self:SetEnabled(self.Properties.Enabled)
end

function PlayerController:GetTickOrder()
	return TickOrder.Default - 1
end

function PlayerController:OnTick(deltaTime, scriptTime)
	local moveSq = self.moveDirection:GetLengthSq()
	if moveSq > self.Properties.Epsilon then
		local tm = TransformBus.Event.GetWorldTM(self.entityId)
		local move = Vector3(self.moveDirection.x ,self.moveDirection.y ,0)
		move = move:GetNormalized() * self.Properties.MoveSpeed * self.moveModifier * deltaTime
        --TransformBus.Event.MoveEntity(self.entityId, (tm.basisX * move.x) + (tm.basisY * move.y))
        
        RigidBodyRequestBus.Event.ApplyAngularImpulse(self.entityId, Vector3(self.moveDirection.y * self.Properties.MoveSpeed * deltaTime,self.moveDirection.x * self.Properties.MoveSpeed * deltaTime,0))
		
		-- framerate dependent smoothing (TODO make independent of fps)
		self.moveDirection.x = self.moveDirection.x * self.Properties.SmoothFactor
		self.moveDirection.y = self.moveDirection.y * self.Properties.SmoothFactor
	end	
end

function PlayerController:OnDeactivate()
	self:UnBindInputEvents(self.InputEvents)

	if self.tickHandler ~= nil then
		self.tickHandler:Disconnect()
		self.tickHandler = nil
	end
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

return PlayerController