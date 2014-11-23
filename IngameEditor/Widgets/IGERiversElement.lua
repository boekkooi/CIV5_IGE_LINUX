-- Released under GPL v3
--------------------------------------------------------------
include("IGEAPIAll");
include("IGEAPIRivers");
include("IGEAPITerrain");
print("IGE_RiversElement");
IGE = nil

local currentPlot = nil;
local riverButtonTexture = "Art\\IgeTile256Base.dds";
local riverButtonTextureCW = "Art\\IgeTile256CW.dds";
local riverButtonTextureCCW = "Art\\IgeTile256CCW.dds";

-------------------------------------------------------------------------------------------------
local function IGEOnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(IGEOnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function IGEUpdateRiverStatus(button, plot, side)
	if plot then 
		local rotation = IGEGetFlowRotation(plot, side);

		if rotation == CWRotation then
			button:SetTexture(riverButtonTextureCW);
		elseif rotation == CCWRotation then
			button:SetTexture(riverButtonTextureCCW);
		else
			button:SetTexture(riverButtonTexture);
		end
	else
		button:SetTexture(riverButtonTexture);
	end
end

-------------------------------------------------------------------------------------------------
function IGEUpdate()
	if currentPlot then
		IGEUpdateRiverStatus(Controls.River_NW_Img, currentPlot, "NW");
		IGEUpdateRiverStatus(Controls.River_NE_Img, currentPlot, "NE");
		IGEUpdateRiverStatus(Controls.River_W_Img, currentPlot, "W");
		IGEUpdateRiverStatus(Controls.River_E_Img, currentPlot, "E");
		IGEUpdateRiverStatus(Controls.River_SW_Img, currentPlot, "SW");
		IGEUpdateRiverStatus(Controls.River_SE_Img, currentPlot, "SE");

		Controls.RiverVertex_N:SetHide(not IGEIsRiverEntryPoint(currentPlot, "N"));
		Controls.RiverVertex_NW:SetHide(not IGEIsRiverEntryPoint(currentPlot, "NW"));
		Controls.RiverVertex_NE:SetHide(not IGEIsRiverEntryPoint(currentPlot, "NE"));
		Controls.RiverVertex_SW:SetHide(not IGEIsRiverEntryPoint(currentPlot, "SW"));
		Controls.RiverVertex_SE:SetHide(not IGEIsRiverEntryPoint(currentPlot, "SE"));
		Controls.RiverVertex_S:SetHide(not IGEIsRiverEntryPoint(currentPlot, "S"));
	end
end
LuaEvents.IGE_Update.Add(IGEUpdate);

-------------------------------------------------------------------------------------------------
function IGEToggleRiver(side)
	local backup = IGEBackupPlot(currentPlot);
	IGEToggleRiverFlow(currentPlot, side);
	LuaEvents.IGE_PushUndoStack({ backup });
	LuaEvents.IGE_ModifiedPlot(currentPlot);

	for neighbor in IGENeighbors(currentPlot) do
		LuaEvents.IGE_ModifiedPlot(neighbor);
	end
	IGEUpdate();
end

Controls.River_W:RegisterCallback(Mouse.eLClick,  function() IGEToggleRiver("W") end);
Controls.River_NW:RegisterCallback(Mouse.eLClick, function() IGEToggleRiver("NW") end);
Controls.River_NE:RegisterCallback(Mouse.eLClick, function() IGEToggleRiver("NE") end);
Controls.River_E:RegisterCallback(Mouse.eLClick,  function() IGEToggleRiver("E") end);
Controls.River_SE:RegisterCallback(Mouse.eLClick, function() IGEToggleRiver("SE") end);
Controls.River_SW:RegisterCallback(Mouse.eLClick, function() IGEToggleRiver("SW") end);
--Controls.RiverBox:SetToolTipCallback(function() IGEToolTipHandler(river) end);

-------------------------------------------------------------------------------------------------
function IGEOnSelectedPlot(plot)
	currentPlot = plot;
	IGEUpdate();
end
LuaEvents.IGE_SelectedPlot.Add(IGEOnSelectedPlot)
