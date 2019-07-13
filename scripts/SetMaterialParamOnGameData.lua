local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"
local GameData = require "scripts/ToolKit/gamedata"

local SetMaterialParamOnGameData = 
{
    Properties = 
    {
        Debug = false,
        GameData = { default = "", description = "name of global that controls this material param"},
        Target = EntityId(),
        TargetTag = "",
        CloneMaterial = true,
        MaterialParam =
        {
            Name = "",
        },
    }
}

function SetMaterialParamOnGameData:OnActivate()
    Utilities:InitLogging(self, "SetMaterialParamOnGameData")
    local id = GameplayNotificationId(EntityId(0), "OnGameDataUpdated" .. self.Properties.GameData, "float")
    self.gameplayListener = GameplayNotificationBus.Connect(self,id) 

    -- this may fail if this is by tag and they haven't activated yet TODO FIXME
    local targetEntityid = self:GetTarget()
    self.materialOwnerListener = MaterialOwnerNotificationBus.Connect(self, targetEntityid)
end

function SetMaterialParamOnGameData:OnMaterialOwnerReady()
    local targetEntityid = self:GetTarget()
    local material = MaterialOwnerRequestBus.Event.GetMaterial(targetEntityid)
    if material ~= nil then
        if self.Properties.CloneMaterial then
            self:Log("Cloning material ")
            material = material:Clone()
        end 

        local value = GameData:Get(self.Properties.GameData)
        if value == nil then
            value = 0
        end
        self:Log("Setting Param " .. tostring(self.Properties.MaterialParam.Name) .. " " .. tostring(value))
        material:SetParamNumber(self.Properties.MaterialParam.Name, tonumber(value))
        MaterialOwnerRequestBus.Event.SetMaterial(targetEntityid, material)
    else
        self:Log("Failed to get material to clone")
    end

    if self.materialOwnerListener ~= nil then
        self.materialOwnerListener:Disconnect()
        self.materialOwnerListener = nil
    end
end

function SetMaterialParamOnGameData:GetTarget()
    local targetEntityid = self.entityId 
    if self.Properties.Target ~= nil and self.Properties.Target:IsValid() then
        targetEntityid = self.Properties.Target
    elseif self.Properties.TargetTag ~= "" then
        targetEntityid = Utilities:GetEntityWithTag(Crc32(self.Properties.TargetTag))
    end

    return targetEntityid
end
function SetMaterialParamOnGameData:OnEventBegin(value)
    self:Log("OnEventBegin " .. tostring(value))
    local targetEntityid = self:GetTarget()
    local paramValue = tonumber(value)
    if paramValue == nil then
        paramValue = 0
    end
    local material = MaterialOwnerRequestBus.Event.GetMaterial(targetEntityid)
    if material ~= nil then
        self:Log("Setting Param " .. tostring(self.Properties.MaterialParam.Name) .. " " .. tostring(value))
        material:SetParamNumber(self.Properties.MaterialParam.Name, paramValue)
        MaterialOwnerRequestBus.Event.SetMaterial(targetEntityid, material)
    end
end

function SetMaterialParamOnGameData:OnDeactivate()
   	if self.gameplayListener ~= nil then
		self.gameplayListener:Disconnect()
		self.gameplayListener = nil
	end
    if self.materialOwnerListener ~= nil then
        self.materialOwnerListener:Disconnect()
        self.materialOwnerListener = nil
    end
end

return SetMaterialParamOnGameData