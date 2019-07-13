local UIShowCursor = 
{
    Properties = 
    {
        Debug = false,
        File = "textures/cursor.tif" 
    }
}

function UIShowCursor:OnActivate()
    UiCursorBus.Broadcast.IncrementVisibleCounter()
    UiCursorBus.Broadcast.SetUiCursor(self.Properties.File)
end

function UIShowCursor:OnDeactivate()
    UiCursorBus.Broadcast.DecrementVisibleCounter()			
end


return UIShowCursor