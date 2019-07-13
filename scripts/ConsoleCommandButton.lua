local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"

local ConsoleCommandButton =
{
    Properties = 
    {
        Debug = true,
        Command = "" 
    }
}


function ConsoleCommandButton:OnActivate()
    Utilities:InitLogging(self, ConsoleCommandButton)
	self.buttonHandler = UiButtonNotificationBus.Connect(self, self.entityId)
end

function ConsoleCommandButton:OnButtonClick()
    --self:Log("Enabling element " .. tostring(self.Properties.Command))
    ConsoleRequestBus.Broadcast.ExecuteConsoleCommand(self.Properties.Command)
end

function ConsoleCommandButton:OnDeactivate()
	self.buttonHandler:Disconnect()
end

return ConsoleCommandButton