-- Released under GPL v3
--------------------------------------------------------------
include("IGEAPIAll");
print("IGE_TabsBar");
IGE = nil;

local editTabItemManager = IGECreateInstanceManager("TabInstance", "Root", Controls.EditTabsStack);
local paintTabItemManager = IGECreateInstanceManager("TabInstance", "Root", Controls.PaintTabsStack);
local changeTabItemManager = IGECreateInstanceManager("TabInstance", "Root", Controls.ChangeTabsStack);

local smallLayout = false;
local currentTabID = nil;
local currentPanelID = nil;
local reportedMultipleVersions = false;
local groups = { edit = {}, paint = {}, change = {} };
local tabs = {};
local data = {};

-------------------------------------------------------------------------------------------------
function IGESetTab(ID)
	currentPanelID = ID;
	if ID ~= "PLAYER_SELECTION" then currentTabID = ID end
	LuaEvents.IGE_SelectedPanel(ID);
	LuaEvents.IGE_Update();
end
LuaEvents.IGE_SetTab.Add(IGESetTab);

-------------------------------------------------------------------------------------------------
local function IGEOnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(IGEOnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function IGEOnInitialize()
	print("IGE_TabsBar.OnInitialize");
	IGESetPlayersData(data, {});

	IGEResize(Controls.Container);
	IGEResize(Controls.TabsGrid);

	local sizeX, sizeY = UIManager:GetScreenSizeVal();
	if sizeX < 1280 then
		Controls.Label_Edit:SetOffsetX(0);
		Controls.Label_Paint:SetOffsetX(0);
		Controls.Label_Change:SetOffsetX(0);
		Controls.EditTabsStack:SetOffsetX(0);
		Controls.PaintTabsStack:SetOffsetX(0);
		Controls.ChangeTabsStack:SetOffsetX(0);
	end

	if sizeY < 1000 then
		smallLayout = true;
		IGELowerSizeY(Controls.Container, 16);
		IGELowerSizeY(Controls.TabsGrid, 16);
		IGELowerSizeY(Controls.TabsStack, 16);
		IGELowerSizeY(Controls.PlayerButton, 16);
		IGELowerSizeY(Controls.PlayerBackground, 16);
		IGELowerSizeY(Controls.PlayerHover, 16);
		IGELowerSizeY(Controls.PlayerContainer, 16);

		Controls.PlayerImage:SetSizeX(45);
		Controls.PlayerImage:SetSizeY(45);

		Controls.TabsStack:ReprocessAnchoring();
		Controls.PlayerContainer:ReprocessAnchoring();

		editTabItemManager = IGECreateInstanceManager("SmallTabInstance", "Root", Controls.EditTabsStack);
		paintTabItemManager = IGECreateInstanceManager("SmallTabInstance", "Root", Controls.PaintTabsStack);
		changeTabItemManager = IGECreateInstanceManager("SmallTabInstance", "Root", Controls.ChangeTabsStack);
	end
	print("IGE_TabsBar.OnInitialize - Done");
end
LuaEvents.IGE_Initialize.Add(IGEOnInitialize);

-------------------------------------------------------------------------------------------------
function IGEOnRegisterTab(_id, _name, _icon, _group, _toolTip, _topData)
	local header = "[COLOR_POSITIVE_TEXT]".._name.."[ENDCOLOR]";
	_toolTip = _toolTip and header.."[NEWLINE]".._toolTip or header;
	local iconSize = smallLayout and 45 or 64;

	local tab = 
	{ 
		ID = _id, 
		name = _name, 
		icon = _icon, 
		group = _group,
		toolTip = _toolTip,
		topData = _topData,
		texture = (smallLayout and "Art/IgeMenuIcons45.dds" or "Art/IgeMenuIcons64.dds"),
		textureOffset = Vector2(iconSize * _icon, iconSize),
		visible = true,
	};

	if tabs[_id] then
		
	end
	tabs[_id] = tab;
	table.insert(groups[_group], tab);

	if currentPanelID == nil then
		currentPanelID = _id;
		currentTabID = _id;
		LuaEvents.IGE_SelectedPanel(_id);
	end
end
LuaEvents.IGE_RegisterTab.Add(IGEOnRegisterTab);

-------------------------------------------------------------------------------------------------
function IGEOnSetTabData(ID, data)
	tabs[ID].topData = data;
	IGEOnUpdate();
end
LuaEvents.IGE_SetTabData.Add(IGEOnSetTabData);

-------------------------------------------------------------------------------------------------
function IGEOnUpdate()
	for k, v in pairs(tabs) do
		v.selected = (currentPanelID == k);
	end

	IGEUpdateGeneric(groups.edit, editTabItemManager, function(v) IGESetTab(v.ID) end);
	IGEUpdateGeneric(groups.paint, paintTabItemManager, function(v) IGESetTab(v.ID) end);
	IGEUpdateGeneric(groups.change, changeTabItemManager, function(v) IGESetTab(v.ID) end);

	Controls.EditTabsStack:CalculateSize();
	Controls.PaintTabsStack:CalculateSize();
	Controls.ChangeTabsStack:CalculateSize();
	Controls.TabsStack:CalculateSize();

	-- German fix (names were too long)
	while Controls.TabsStack:GetSizeX() > Controls.TabsGrid:GetSizeX() do
		Controls.Label_Edit:SetOffsetX(Controls.Label_Edit:GetOffsetVal() - 10);
		Controls.Label_Paint:SetOffsetX(Controls.Label_Paint:GetOffsetVal() - 10);
		Controls.Label_Change:SetOffsetX(Controls.Label_Change:GetOffsetVal() - 10);
		Controls.TabsStack:ReprocessAnchoring();
	end

	local playerData = data.playersByID[IGE.currentPlayerID];
	if smallLayout then
		Controls.PlayerImage:SetTexture(playerData.texture);
		Controls.PlayerImage:SetTextureOffset(playerData.textureOffset);
	else
		Controls.PlayerImage:SetTexture(playerData.texture);
		Controls.PlayerImage:SetTextureOffset(playerData.textureOffset);
	end
	Controls.PlayerLabel:SetText(playerData.label or playerData.name);
end
LuaEvents.IGE_Update.Add(IGEOnUpdate);

-------------------------------------------------------------------------------------------------
local function IGEOnClosePlayerSelection()
	IGESetTab(currentTabID);
end
LuaEvents.IGE_ClosePlayerSelection.Add(IGEOnClosePlayerSelection);

-------------------------------------------------------------------------------------------------
local function OnOpenPlayerSelectionClick()
	if currentPanelID == "PLAYER_SELECTION" then
		IGESetTab(currentTabID);
	else
		IGESetTab("PLAYER_SELECTION");
	end
end
Controls.PlayerButton:RegisterCallback(Mouse.eLClick, OnOpenPlayerSelectionClick);

