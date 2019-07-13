local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local SplineRevealer = 
{
    Properties = 
    {
        Debug = false,
        UpdateRate = 1.0,
        RoadUpdateRate = 0.1,
        PlayerTag = { default = "Player" },
        MaxDistance = 1.0,
        OnComplete = 
        {
            Event = {default = "", description="Gameplay event to fire"},
            Value = {default=1},
            Target = {default = EntityId()}
        }
    }
}

function SplineRevealer:OnActivate()
    Utilities:InitLogging(self, "SplineRevealer")

    self.spline = SplineComponentRequestBus.Event.GetSpline(self.entityId)
    self.splineRenderSegments = RoadRequestBus.Event.GetNumSegments(self.entityId)
    self.splinePosition = TransformBus.Event.GetWorldTranslation(self.entityId)

    if self.splineRenderSegments > 0 then
        self.splineRenderSegmentLength = self.spline:GetSplineLength() / self.splineRenderSegments
    else
        self.splineRenderSegmentLength = 0.1
    end

    self.numLitSegments =-1 
    self.nextVisibleTime = 0
    self.nextPlayerCheckTime = 0
    self.tickListener = TickBus.Connect(self,0)
    self.maxDistanceSq = self.Properties.MaxDistance * self.Properties.MaxDistance
    self.player = nil
    self.nextRoadUpdateTime = 0
    self.clonedMaterial = false
    self.material = nil

    self.materialOwnerListener = MaterialOwnerNotificationBus.Connect(self, self.entityId)

    Debug.Log("num render segments " .. tostring(self.splineRenderSegments))
    Debug.Log("spline length " .. tostring(self.spline:GetSplineLength()))
    --Debug.Log("num spline segments " .. tostring(self.spline:GetSegmentCount()))
    --Debug.Log("spline granularity " .. tostring(self.spline:GetSegmentGranularity()))

    -- turn off all rendered segments
    --for i = 0,self.splineRenderSegments do
        --RoadRequestBus.Event.SetSegmentVisible(self.entityId, i, false)
    --end
    --TransformBus.Event.MoveEntity(self.entityId, Vector3(0,0,0.0001))
end

function SplineRevealer:OnMaterialOwnerReady()
    self:Log("OnMaterialOwnerReady")
    self.material = MaterialOwnerRequestBus.Event.GetMaterial(self.entityId)
    if self.material ~= nil then
        -- always clone
        local paramName = "Shininess"
        self.material = self.material:Clone()
        self.material:SetParamNumber(paramName, 0)
        MaterialOwnerRequestBus.Event.SetMaterial(self.entityId, self.material)
        --local shininess = self.material:GetParamNumber(paramName)
        --self:Log("Shininess " .. tostring(diffuse))
        --[[
        diffuse.r = 0.5 
        diffuse.g = 0
        diffuse.b = 0
        diffuse.a = 1
        self.material:SetParamColor(paramName, diffuse)
        ]]
    else
        self:Log("Failed to get material")
    end

    if self.materialOwnerListener ~= nil then
        self.materialOwnerListener:Disconnect()
        self.materialOwnerListener = nil
    end
end

function SplineRevealer:GetSplineFraction(spline, address)
    local length = 0
    for segment = 0,spline:GetSegmentCount() do
        local segmentLength = spline:GetSegmentLength(segment)
        if address.segmentIndex == segment then
            length = length + (segmentLength * address.segmentFraction)
            break
        else
            length = length + segmentLength
        end
    end 

    return length
end

function SplineRevealer:GetRenderSegmentFromAddress(spline, address)
    --local length = self:GetSplineFraction(spline, address)
    local ratio = spline:GetLength(address) / spline:GetSplineLength()
    --Debug.Log(tostring(length) .. " total: " .. spline:GetSplineLength() .. " ratio: " .. tostring(ratio))
    return Math.Round(ratio * self.splineRenderSegments)
end

function SplineRevealer:GetRatio(spline, address)
    return spline:GetLength(address) / spline:GetSplineLength()
end

function SplineRevealer:UpdateSegmentNearPlayer()
    if self.player == nil then
        local entities = ToolKitRequestBus.Broadcast.GetEntitiesWithTag(Crc32(self.Properties.PlayerTag))
        if entities ~= nil and #entities > 0 then
           self.player = entities[1] 
        end
    end
    if self.player == nil then
        return
    end
    local playerPosition = TransformBus.Event.GetWorldTranslation(self.player)
    -- TODO see if player is within bbox of spline first
    local result = self.spline:GetNearestAddressPosition(playerPosition - self.splinePosition)
    if result ~= nil and result.distanceSq < self.maxDistanceSq then
        -- get the segment near the player and turn it on
        local ratio = self:GetRatio(self.spline, result.splineAddress)
        if false and self.material ~= nil then
            local shininess = self.material:GetParamNumber("Shininess")
            if shininess ~= nil then
                --self:Log("Ratio is " .. tostring(ratio))
                self.material:SetParamNumber("Shininess",ratio)
            else
                self:Log("Diffuse color param is nil")
            end
        end
        local renderSegmentIndex = self:GetRenderSegmentFromAddress(self.spline, result.splineAddress)
        if renderSegmentIndex == self.numLitSegments + 1 then
            --RoadRequestBus.Event.SetSegmentVisible(self.entityId, renderSegmentIndex, true)
            self.numLitSegments =self.numLitSegments + 1 
            --TransformBus.Event.MoveEntity(self.entityId, Vector3(0,0,0.0001))

            self.material:SetParamNumber("Shininess",self.numLitSegments / self.splineRenderSegments)
            if self.numLitSegments == self.splineRenderSegments then
                self:Log("Spline completely lit")
                Events:Event(self.Properties.OnComplete.Target, self.Properties.OnComplete.Event, self.Properties.OnComplete.Value)
            end
            --local scriptTime = TickRequestBus.Broadcast.GetTimeAtCurrentTick()
            --if self.nextRoadUpdateTime < scriptTime:GetSeconds() then
                --self.nextRoadUpdateTime = scriptTime:GetSeconds() + self.Properties.RoadUpdateRate
            --end
        else
            --Debug.Log(tostring(renderSegmentIndex))
        end
        --]]
        -- check the previous and next segments? not needed when segments are about 1m
        --Debug.Log(tostring(result.distanceSq) .. " " .. tostring(renderSegmentIndex))
        -- don't update every frame because rebuild makes the road flicker
        --TransformBus.Event.MoveEntity(self.entityId, Vector3(0,0,0.0001))
    end
end

function SplineRevealer:OnTick(deltaTime, scriptTime)
    if scriptTime:GetSeconds() > self.nextPlayerCheckTime then
        self.nextPlayerCheckTime = scriptTime:GetSeconds() + self.Properties.UpdateRate
        self:UpdateSegmentNearPlayer()
    end
    if scriptTime:GetSeconds() > self.nextRoadUpdateTime then
        --TransformBus.Event.MoveEntity(self.entityId, Vector3(0,0,0.0001))
    end
end

function SplineRevealer:OnDeactivate()
    if self.tickListener ~= nil then
        self.tickListener:Disconnect()
        self.tickListener = nil
    end
end

return SplineRevealer