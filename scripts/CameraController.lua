local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local CameraController = {
	Properties = {
		Debug = true,
		Player = EntityId(),
		Bounds = EntityId(),
		SmoothAmount = 0.1,
		UpdateRate = { default=0.016, suffix = "sec"},
		DissolveCheckRate = { default = 0.1, suffix = "sec"},
		DissolveTracker = EntityId()
	}
}

function CameraController:OnActivate()
	Utilities:InitLogging(self, "CameraController")
	self.entityListener = EntityBus.Connect(self, self.Properties.Player)
	self.nextUpdateTime = 0
	self.nextDissolveCheckTime = 0

	self.rayCastConfig = RayCastConfiguration()
	self.rayCastConfig.ignoreEntityIds = vector_EntityId()
	self.rayCastConfig.ignoreEntityIds:PushBack(self.entityId)
	self.rayCastConfig.ignoreEntityIds:PushBack(self.Properties.Player)
	self.rayCastConfig.ignoreEntityIds:PushBack(self.Properties.Bounds)
	self.rayCastConfig.direction = Vector3(0,0,1) 
	self.rayCastConfig.maxDistance = 1.0
	self.rayCastConfig.maxHits = 1
	self.lastHitEntity = nil
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

	if scriptTime:GetSeconds() > self.nextDissolveCheckTime then
		self.nextDissolveCheckTime = scriptTime:GetSeconds() + self.Properties.DissolveCheckRate

		local position = TransformBus.Event.GetWorldTranslation(self.entityId)
		local playerPosition = TransformBus.Event.GetWorldTranslation(self.Properties.Player)

		self.rayCastConfig.origin = position 
		local direction = playerPosition - position;
		self.rayCastConfig.maxDistance = direction:GetLength() - 0.2
		self.rayCastConfig.direction =  direction:GetNormalized()
		local result = PhysicsSystemRequestBus.Broadcast.RayCast(self.rayCastConfig)
		if result ~= nil then
			local previousEntity =  self.lastHitEntity
			if result:GetHitCount() > 0 then
				local hit = result:GetHit(1)
				TransformBus.Event.SetWorldTranslation(self.Properties.DissolveTracker, hit.position)
				if hit ~= nil and hit.entityId ~= nil and hit.entityId:IsValid() then
					if hit.entityId ~= self.lastHitEntity then
						-- hit a different entity
						local material = MaterialOwnerRequestBus.Event.GetMaterial(hit.entityId)
						if material then
							material:SetParamNumber("DissolvePercentage", 0.5)
						end
						self:Log("dissolving entity " .. tostring(hit.entityId))
						self.lastHitEntity = hit.entityId
					else
						self:Log("hit same entity")
					end
				elseif hit ~= nil  then
					-- didn't hit an entity 
					self.lastHitEntity = nil
					self:Log("hit non-entity")
				else
					-- didn't hit an entity 
					self.lastHitEntity = nil
					self:Log("no hit")
				end
			else
				self.lastHitEntity = nil
				TransformBus.Event.SetWorldTranslation(self.Properties.DissolveTracker, Vector3(0,0,0))
			end 

			if previousEntity ~= nil and previousEntity ~= self.lastHitEntity then
				self:Log("restoring previous dissolved entity")
				local material = MaterialOwnerRequestBus.Event.GetMaterial(previousEntity)
				if material then
					material:SetParamNumber("DissolvePercentage", 0)
				end
			end
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
	if playerPosition ~= nil then
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