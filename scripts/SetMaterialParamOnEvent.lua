local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local SetMaterialParamOnEvent = 
{
    Properties = 
    {
        Debug = false,
        Event = "OnSetMaterialParam",
        Target = EntityId(),
        TargetTag = "",
        CloneMaterial = true,
        MaterialParam =
        {
            Name = "",
            Value = "", 
            UseEventValue = false,
        },
        --Duration = {default = 1.0, suffix="sec"},
        --OnComplete =
        --{
        --    Event = "OnComplete",
        --    Target = EntityId()
        --}
    }
}

function SetMaterialParamOnEvent:OnActivate()
    Utilities:InitLogging(self, "SetMaterialParamOnEvent")
    local id = GameplayNotificationId(self.entityId, self.Properties.Event, "float")
    self.gameplayListener = GameplayNotificationBus.Connect(self,id) 
    self.clonedMaterial = false
end

function SetMaterialParamOnEvent:OnEventBegin(value)
    local targetEntityid = self.entityId 
    if self.Properties.Target ~= nil and self.Properties.Target:IsValid() then
        targetEntityid = self.Properties.Target
    elseif self.Properties.TargetTag ~= "" then
        targetEntityid = Utilities:GetEntityWithTag(Crc32(self.Properties.TargetTag))
    end

    local material = MaterialOwnerRequestBus.Event.GetMaterial(targetEntityid)
    if material ~= nil then
        if not self.clonedMaterial and self.Properties.CloneMaterial then
            self:Log("Cloning material ")
            material = material:Clone()
            self.clonedMaterial = true
            MaterialOwnerRequestBus.Event.SetMaterial(targetEntityid, material)
        end
        self:Log("Setting Param " .. tostring(self.Properties.MaterialParam.Name) .. " " .. tostring(self.Properties.MaterialParam.Value))
        local materialParamValue = self.Properties.MaterialParam.Value 
        if self.Properties.MaterialParam.UseEventValue then
            materialParamValue = value
        end

        material:SetParamNumber(self.Properties.MaterialParam.Name, tonumber(materialParamValue))
    end
end

function SetMaterialParamOnEvent:OnDeactivate()
   	if self.gameplayListener ~= nil then
		self.gameplayListener:Disconnect()
		self.gameplayListener = nil
	end
end

return SetMaterialParamOnEvent