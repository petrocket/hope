local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local CameraController = {
	Properties = {
		Debug = true,
		Player = EntityId(),
		Bounds = EntityId(),
		SmoothAmount = 0.1,
		UpdateRate = { default=0.016, suffix = "s"}
	}
}

function CameraController:OnActivate()
	Utilities:InitLogging(self, "CameraController")
	self.entityListener = EntityBus.Connect(self, self.Properties.Player)
	self.nextUpdateTime = 0
end

function CameraController:GetTickOrder()
	return TickOrder.UI
end

function CameraController:OnEntityActivated(entityId)
    if entityId == self.Properties.Player then
        self.playerPosition = TransformBus.Event.GetWorldTranslation(self.Properties.Player)
        self.position = TransformBus.Event.GetWorldTranslation(self.entityId)
		self.offset = Vector3(self.position.x - self.playerPosition.x, self.position.y - self.playerPosition.y, 0)
		if self.entityListener ~= nil then
			self.entityListener:Disconnect()
		end
        self.tickHandler = TickBus.Connect(self,0)
    end
end

function CameraController:OnTick(deltaTime, scriptTime)
	if scriptTime:GetSeconds() > self.nextUpdateTime then 
		self.nextUpdateTime = scriptTime:GetSeconds() + self.Properties.UpdateRate
		local position = TransformBus.Event.GetWorldTranslation(self.entityId)
		local playerPosition = TransformBus.Event.GetWorldTranslation(self.Properties.Player)
		
		local destination = self:GetDestinationCameraPosition(position, playerPosition)
		local distanceSq = destination:GetDistanceSq(position)
		if distanceSq > 0.1 then
			local moveAmount = (destination - position) * self.Properties.SmoothAmount 
			-- TODO limit to max distance
			TransformBus.Event.SetWorldTranslation(self.entityId, position + moveAmount)
		end
	end
end

function CameraController:OnTransformChanged(localTM, worldTM)
	self.playerPosition = worldTM:GetTranslation()
	local newCameraPosition = self:GetDestinationCameraPosition(self.position, self.PlayerPosition)
	if newCameraPosition:GetDistanceSq(self.position) > 1.0 then
		self.destination = newCameraPosition
	end
end

function CameraController:GetDestinationCameraPosition(currentPosition, playerPosition)
	local inside = ShapeComponentRequestsBus.Event.IsPointInside(self.Properties.Bounds, playerPosition)
	if inside then
		return currentPosition
	else
		local distance =  ShapeComponentRequestsBus.Event.DistanceFromPoint(self.Properties.Bounds, playerPosition)
		local boundsCenter = TransformBus.Event.GetWorldTranslation(self.Properties.Bounds)
		local direction = playerPosition - boundsCenter
		direction.z = 0
		direction = direction:GetNormalized()
		--self:Log("Direction " .. tostring(direction))
		return currentPosition + (direction * distance)
	end
	return currentPosition
end

function CameraController:OnDeactivate()
	if self.tickHandler ~= nil then
		self.tickHandler:Disconnect()
		self.tickHandler = nil
    end
    if self.entityListener ~= nil then
        self.entityListener:Disconnect()
        self.entityListener = nil
    end
end

return CameraController