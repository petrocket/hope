local Events = require "scripts/ToolKit/events"
local Utilities = require "scripts/ToolKit/utilities"
local GameData = require "scripts/ToolKit/gamedata"

local GameLogic =
{
    Properties = 
    {
        Debug = true,
        ResetGameData = { default = {""} },
        ActivateGameData = { default = {""} },
    }
}

function GameLogic:OnActivate()
    Utilities:InitLogging(self, "GameLogic")

    for i=1,#self.Properties.ResetGameData do
        GameData:Set(self.Properties.ResetGameData[i], 0)
    end
    for i=1,#self.Properties.ActivateGameData do
        GameData:Set(self.Properties.ActivateGameData[i], 1)
    end
end


function GameLogic:OnDeactivate()
end

return GameLogic