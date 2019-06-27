local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local SplineRevealer = 
{
    Properties = 
    {
        Debug = false,
        UpdateRate = 1.0,
        PlayerTag = { default = "Player" },
        MaxDistance = 1.0,
        OnComplete = 
        {
            Event = {default = "", description="Gameplay event to fire"},
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

    Debug.Log("num render segments " .. tostring(self.splineRenderSegments))
    Debug.Log("spline length " .. tostring(self.spline:GetSplineLength()))
    --Debug.Log("num spline segments " .. tostring(self.spline:GetSegmentCount()))
    --Debug.Log("spline granularity " .. tostring(self.spline:GetSegmentGranularity()))

    -- turn off all rendered segments
    for i = 0,self.splineRenderSegments do
        RoadRequestBus.Event.SetSegmentVisible(self.entityId, i, false)
    end
    TransformBus.Event.MoveEntity(self.entityId, Vector3(0,0,0.0001))
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
        local renderSegmentIndex = self:GetRenderSegmentFromAddress(self.spline, result.splineAddress)
        if renderSegmentIndex == self.numLitSegments + 1 then
            RoadRequestBus.Event.SetSegmentVisible(self.entityId, renderSegmentIndex, true)
            self.numLitSegments =self.numLitSegments + 1 

            if self.numLitSegments == self.splineRenderSegments then
                self:Log("Spline completely lit")
                Events:Event(self.Properties.OnComplete.Target, self.Properties.OnComplete.Event, 1.0)
            end
        else
            --Debug.Log(tostring(renderSegmentIndex))
        end
        -- check the previous and next segments? not needed when segments are about 1m
        --Debug.Log(tostring(result.distanceSq) .. " " .. tostring(renderSegmentIndex))
        TransformBus.Event.MoveEntity(self.entityId, Vector3(0,0,0.0001))
    end
end

function SplineRevealer:OnTick(deltaTime, scriptTime)
    if scriptTime:GetSeconds() > self.nextPlayerCheckTime then
        self.nextPlayerCheckTime = scriptTime:GetSeconds() + self.Properties.UpdateRate
        self:UpdateSegmentNearPlayer()
    end
end

function SplineRevealer:OnDeactivate()
    if self.tickListener ~= nil then
        self.tickListener:Disconnect()
        self.tickListener = nil
    end
end

return SplineRevealer