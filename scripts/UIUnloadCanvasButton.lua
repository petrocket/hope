local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"
local GameData = require "scripts/ToolKit/gamedata"

local UIUnloadCanvasButton = {
	Properties = {
		Event = "",
		Value = "",	
		Debug = false
	}
}

function UIUnloadCanvasButton:OnActivate()
	Utilities:InitLogging(self, "UIUnloadCanvasButton")
	self.buttonHandler = UiButtonNotificationBus.Connect(self, self.entityId)
end

function UIUnloadCanvasButton:OnDeactivate()
	self.buttonHandler:Disconnect()
end

function UIUnloadCanvasButton:OnButtonClick()
	local canvasEntityId = UiElementBus.Event.GetCanvas(self.entityId)
	self:Log("UIUnloadCanvasButton OnButtonClick " .. tostring(canvasEntityId))
	if canvasEntityId:IsValid() then
		UiCanvasManagerBus.Broadcast.UnloadCanvas(canvasEntityId)
	end

	if self.Properties.Event ~= "" then
		local id = GameplayNotificationId(EntityId(0), self.Properties.Event, "float")
		GameplayNotificationBus.Event.OnEventBegin(id, tostring(self.Properties.Value))
	end	
end

return UIUnloadCanvasButton
