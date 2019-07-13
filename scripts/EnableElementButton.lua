local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local EnableElementButton =
{
    Properties = 
    {
        Debug = true,
        Element = EntityId()
    }
}


function EnableElementButton:OnActivate()
    Utilities:InitLogging(self, EnableElementButton)
	self.buttonHandler = UiButtonNotificationBus.Connect(self, self.entityId)
end

function EnableElementButton:OnButtonClick()
    --self:Log("Enabling element " .. tostring(self.Properties.Element))
    UiElementBus.Event.SetIsEnabled(self.Properties.Element, true)
end

function EnableElementButton:OnDeactivate()
	self.buttonHandler:Disconnect()
end

return EnableElementButton