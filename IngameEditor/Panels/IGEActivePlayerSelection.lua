-- Released under GPL v3
--------------------------------------------------------------
include("IGEAPIAll");
print("IGE_ActivePlayerSelection");
IGE = nil;

local majorPlayerItemManager = IGECreateInstanceManager("MajorPlayerInstance", "Button", Controls.MajorPlayerList);
local minorPlayerItemManager = IGECreateInstanceManager("MinorPlayerInstance", "Button", Controls.MinorPlayerList);

local panelID = "PLAYER_SELECTION";
local isVisible = false;
local data = {};

-------------------------------------------------------------------------------------------------
function IGEOnSelectedPanel(ID)
	isVisible = (ID == panelID);
end
LuaEvents.IGE_SelectedPanel.Add(IGEOnSelectedPanel)

-------------------------------------------------------------------------------------------------
local function IGEOnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(IGEOnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function IGEOnInitialize()
	IGEResize(Controls.Container);
	IGEResize(Controls.ScrollPanel);
	Controls.ScrollBar:SetSizeX(Controls.ScrollPanel:GetSizeX() - 6);
	IGESetPlayersData(data, { none=false });
end
LuaEvents.IGE_Initialize.Add(IGEOnInitialize);

-------------------------------------------------------------------------------------------------
function IGEOnUpdate()
	Controls.Container:SetHide(not isVisible);
	if not isVisible then return end

	for k, v in pairs(data.allPlayers) do
		v.selected = false;
		v.visible = (v.ID >= 0 and Players[v.ID]:IsAlive());
		if v.ID == IGE.initialPlayerID then
			v.priority = 10;
			v.label = IGEL("TXT_KEY_YOU").." - "..v.civilizationName;
		elseif v.isBarbarians then
			v.label = v.civilizationName;
			v.priority = 1;
		else
			v.label = v.civilizationName and v.name.." - "..v.civilizationName or v.name;
			v.priority = 2;
		end
	end

	table.sort(data.majorPlayers, IGEDefaultSort);
	table.sort(data.minorPlayers, IGEDefaultSort);
	--for k, v in ipairs(data.majorPlayers) do print(v.name) end

	IGEUpdateList(data.majorPlayers, majorPlayerItemManager, function(v) LuaEvents.IGE_SelectPlayer(v.ID) end);
	IGEUpdateList(data.minorPlayers, minorPlayerItemManager, function(v) LuaEvents.IGE_SelectPlayer(v.ID) end);

	Controls.Stack:CalculateSize();
	local offset = (Controls.ScrollPanel:GetSizeX() - Controls.Stack:GetSizeX()) / 2;
	Controls.Stack:SetOffsetVal(offset > 0 and offset or 0, 0);

	Controls.Stack:ReprocessAnchoring();
	Controls.ScrollPanel:CalculateInternalSize();
	Controls.ScrollDown:SetHide(offset > 0);
	Controls.ScrollBar:SetHide(offset > 0);
	Controls.ScrollUp:SetHide(offset > 0);
end
LuaEvents.IGE_Update.Add(IGEOnUpdate);
