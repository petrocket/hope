local Events = require "scripts/toolkit/events"
local Utilities = require "scripts/toolkit/utilities"

local GameplayEventButton = {
	Properties = {
		Debug = false,
		Event = { default = "", description = "Event name" },
		Value = { default = "", description = "Event value" },
		InputEvent = { default = "", description = "Optional input event name, useful for controllers"},
		PressedAudio = { default = "", description = "Audio to play on pressed"},
		HoverAudio = { default = "", description = "Audio to play on hover"},
		AudioProxyTag = { default = "MenuAudio" }
	},
	AudioProxy = EntityId(0) -- entity Id for the audio proxy
}

function GameplayEventButton:OnActivate()
	Utilities:InitLogging(self, "GameplayEventButton")
	self.buttonHandler = UiButtonNotificationBus.Connect(self, self.entityId)
	
	if self.Properties.HoverAudio ~= nil then
		self.interactableHandler = UiInteractableNotificationBus.Connect(self , self.entityId)
	end
	
	if self.Properties.InputEvent ~= "" then
		local id = InputEventNotificationId(self.Properties.InputEvent)
		self.inputHandler = InputEventNotificationBus.Connect(self, id)
	end
	
	Utilities:ExecuteOnNextTick(self, function(self)
		self.AudioProxy = TagGlobalRequestBus.Event.RequestTaggedEntities(Crc32(self.Properties.AudioProxyTag))
	end)
end

function GameplayEventButton:OnPressed(value)
	self:Log("OnPressed " .. tostring(self.Properties.Event))
	Events:GlobalEvent(self.Properties.Event, self.Properties.Value)
	if self.Properties.PressedAudio ~= "" then
		self:PlayAudio(self.Properties.PressedAudio)
	end
end

function GameplayEventButton:OnHoverStart()
	self:PlayAudio(self.Properties.HoverAudio)	
end

function GameplayEventButton:PlayAudio(audio)
	if self.AudioProxy ~= nil and self.AudioProxy ~= EntityId(0) then
		self:Log("Playing audio " .. audio)
		AudioTriggerComponentRequestBus.Event.ExecuteTrigger(self.AudioProxy, audio)
	end
end

function GameplayEventButton:OnButtonClick()
	self:Log("OnButtonClick " .. tostring(self.Properties.Event))
	Events:GlobalEvent(self.Properties.Event, self.Properties.Value)
end

function GameplayEventButton:OnDeactivate()
	if self.buttonHandler ~= nil then
		self.buttonHandler:Disconnect()
	end
	
	if self.inputHandler ~= nil then
		self.inputHandler:Disconnect()
	end
	
	if self.interactableHandler ~= nil then
		self.interactableHandler:Disconnect()
	end
end


return GameplayEventButton