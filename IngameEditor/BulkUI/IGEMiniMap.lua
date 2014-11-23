-- Released under GPL v3
--------------------------------------------------------------
print("loaded");

function IGEOnMinimapClick(_, _, _, x, y )
    Events.MinimapClickedEvent(x, y);
end
Controls.Minimap:RegisterCallback( Mouse.eLClick, IGEOnMinimapClick );

-------------------------------------------------------------------------------------------------
function IGEOnStrategicViewClick()
    ToggleStrategicView();
end
Controls.StrategicViewButton:RegisterCallback(Mouse.eLClick, IGEOnStrategicViewClick);

-------------------------------------------------------------------------------------------------
local function OnStrategicViewStateChanged(bStrategicView)
	if bStrategicView then
		Controls.StrategicViewButton:SetTexture( "assets/UI/Art/Icons/MainWorldButton.dds" );
		Controls.StrategicMO:SetTexture( "assets/UI/Art/Icons/MainWorldButton.dds" );
		Controls.StrategicHL:SetTexture( "assets/UI/Art/Icons/MainWorldButtonHL.dds" );
	else
		Controls.StrategicViewButton:SetTexture( "assets/UI/Art/Icons/MainStrategicButton.dds" );
		Controls.StrategicMO:SetTexture( "assets/UI/Art/Icons/MainStrategicButton.dds" );
		Controls.StrategicHL:SetTexture( "assets/UI/Art/Icons/MainStrategicButtonHL.dds" );
	end
end
Events.StrategicViewStateChanged.Add(OnStrategicViewStateChanged);

-------------------------------------------------------------------------------------------------
local function OnMinimapInfo( uiHandle, width, height, paddingX )
    Controls.Minimap:SetTextureHandle( uiHandle );
    Controls.Minimap:SetSizeVal( width, height );
end



--===============================================================================================
-- HOOKS
--===============================================================================================
local function IGEOnShowing()
	Events.MinimapTextureBroadcastEvent.Add(OnMinimapInfo);
	UI:RequestMinimapBroadcast();
end
LuaEvents.IGE_Showing.Add(IGEOnShowing);

-------------------------------------------------------------------------------------------------
local function IGEOnClosing()
	Events.MinimapTextureBroadcastEvent.Remove(OnMinimapInfo);
end
LuaEvents.IGE_Closing.Add(IGEOnClosing);


