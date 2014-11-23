-- Released under GPL v3
--------------------------------------------------------------
include("IGEAPIAll");
include("IGEAPIRivers");
include("IGEAPITerrain");
print("IGE_TerrainPanel");
IGE = nil;

local groupManager = IGECreateInstanceManager("GroupInstance", "Stack", Controls.MainStack );
local routeItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.RouteList );
local improvementItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.ImprovementList );
local greatImprovementItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.GreatImprovementList );
local strategicResourceItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.StrategicResourceList );
local luxuryResourceItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.LuxuryResourceList );
local bonusResourceItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.BonusResourceList );
local naturalWonderItemManager= IGECreateInstanceManager("ListItemInstance", "Button", Controls.NaturalWonderList );
local waterItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.WaterList );
local terrainItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.TerrainList );
local featureItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.FeatureList );
local typeItemManager = IGECreateInstanceManager("TypeInstance", "Button", Controls.TypeList );
local artItemManager= IGECreateInstanceManager("ListItemInstance", "Button", Controls.ArtList );
local fogItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.FogList );
local ownershipItemManager = IGECreateInstanceManager("ListItemInstance", "Button", Controls.OwnershipList );

local redoStack = {};
local undoStack = {};
local groups = {};
local editData = {};
local paintData = {};
local currentPlot = nil;
local editSound = "AS2D_BUILD_UNIT";
local selectedStrategicResource = nil;
local clickHandler = nil;
local isEditing = true;
local isVisible = false;


--===============================================================================================
-- INITIALIZATION
--===============================================================================================
local function InitializeData(data)
	IGESetContinentArtsData(data,	{});
	IGESetTerrainsData(data,		{});
	IGESetPlotTypesData(data,		{});
	IGESetFeaturesData(data,		{ none=true });
	IGESetResourcesData(data,		{ none=true });
	IGESetImprovementsData(data,	{ none=true });
	IGESetRoutesData(data,			{ none=true });

	data.fogs = 
	{
		{ ID = 1, name = IGEL("TXT_KEY_IGE_EXPLORED_SETTING"), visible = true, enabled = true, action = IGESetFog, value = false, help=IGEL("TXT_KEY_IGE_EXPLORED_SETTING_HELP") },
		{ ID = 2, name = IGEL("TXT_KEY_IGE_UNEXPLORED_SETTING"), visible = true, enabled = true, action = IGESetFog, value = true, help=IGEL("TXT_KEY_IGE_UNEXPLORED_SETTING_HELP") },
	};
	data.ownerships = 
	{
		{ ID = 1, name = IGEL("TXT_KEY_IGE_FREE_LAND_SETTING"), visible = true, enabled = true, action = IGESetOwnership, value = false, help=IGEL("TXT_KEY_IGE_FREE_LAND_SETTING_HELP") },
		{ ID = 2, name = IGEL("TXT_KEY_IGE_YOUR_LAND_SETTING"), visible = true, enabled = true, action = IGESetOwnership, value = true, help=IGEL("TXT_KEY_IGE_YOUR_LAND_SETTING_HELP") },
	};
end

-------------------------------------------------------------------------------------------------
function IGECreateGroup(theControl, name)
	local theInstance = groupManager:GetInstance();
	if theInstance then
		theInstance.Header:SetText(name);
		theControl:ChangeParent(theInstance.List);
		groups[name] = { instance = theInstance, control = theControl, visible = true };
	end
end

-------------------------------------------------------------------------------------------------
local function IGEOnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(IGEOnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function IGEOnInitialize()
	print("IGE_TerrainPanel.OnInitialize");
	InitializeData(editData);
	InitializeData(paintData);

	currentPaintSelection = paintData.terrainsByTypes["TERRAIN_GRASS"];
	currentPaintSelection.selected = true;

	IGEResize(Controls.Container);
	IGEResize(Controls.PromptContainer);
	IGEResize(Controls.ScrollPanel);
	IGEResize(Controls.OuterContainer);
	Controls.ScrollBar:SetSizeX(Controls.ScrollPanel:GetSizeX() - 36);

	local othersName = IGEL("TXT_KEY_IGE_OTHERS");
	IGECreateGroup(Controls.CoreContainer, IGEL("TXT_KEY_IGE_TERRAIN"));
	IGECreateGroup(Controls.FeaturesStack, IGEL("TXT_KEY_IGE_FEATURES_AND_WONDERS"));
	IGECreateGroup(Controls.ResourcesStack, IGEL("TXT_KEY_IGE_RESOURCES"));
	IGECreateGroup(Controls.ImprovementsStack, IGEL("TXT_KEY_IGE_IMPROVEMENTS"));
	IGECreateGroup(Controls.OthersContainer, othersName);
	groups[othersName].instance.Separator:SetHide(true);

	local tt = IGEL("TXT_KEY_IGE_TERRAIN_EDIT_PANEL_HELP");
	LuaEvents.IGE_RegisterTab("TERRAIN_EDITION",  IGEL("TXT_KEY_IGE_TERRAIN_EDIT_PANEL"), 0, "edit",  tt)

	local tt = IGEL("TXT_KEY_IGE_TERRAIN_PAINT_PANEL_HELP");
	LuaEvents.IGE_RegisterTab("TERRAIN_PAINTING", IGEL("TXT_KEY_IGE_TERRAIN_PAINT_PANEL"), 0, "paint", tt, currentPaintSelection)
	print("IGE_TerrainPanel.OnInitialize - Done");
end
LuaEvents.IGE_Initialize.Add(IGEOnInitialize)


--===============================================================================================
-- CORE EVENTS
--===============================================================================================
function IGEOnSelectedPanel(ID)
	if ID == "TERRAIN_EDITION" then
		isEditing = true;
		isVisible = true;
	elseif ID == "TERRAIN_PAINTING" then
		isEditing = false;
		isVisible = true;
	else
		isVisible = false;
	end
end
LuaEvents.IGE_SelectedPanel.Add(IGEOnSelectedPanel);

-------------------------------------------------------------------------------------------------
function IGEClickHandler(item)
	if isEditing then
		if currentPlot then
			Events.AudioPlay2DSound(editSound);	
			IGEBeginUndoGroup();
			IGEDoAction(currentPlot, item.action, item);
			IGECommitTerrainChanges();
			IGECommitFogChanges();
			IGEOnUpdate();
		end
	else
		if currentPaintSelection then
			currentPaintSelection.selected = false;
		end
		currentPaintSelection = item;
		if currentPaintSelection then
			currentPaintSelection.selected = true;
		end
		LuaEvents.IGE_SetTabData("TERRAIN_PAINTING", item);
		IGEOnUpdate();
	end
end

-------------------------------------------------------------------------------------------------
function IGEOnPaintPlot(button, plot, shift)
	if isVisible and currentPaintSelection then
		Events.AudioPlay2DSound(editSound);	
		local item = currentPaintSelection;

		IGEDoAction(plot, item.action, item);
		if shift then
			for neighbor in IGENeighbors(plot) do
				if currentPaintSelection:action(neighbor) then
					IGEDoAction(neighbor, item.action, item);
				end
			end
		end

		IGECommitFogChanges();
		IGECommitTerrainChanges();
	end
end
LuaEvents.IGE_PaintPlot.Add(IGEOnPaintPlot);

-------------------------------------------------------------------------------------------------
function IGEOnBeginPaint()
	IGEBeginUndoGroup();
end
LuaEvents.IGE_BeginPaint.Add(IGEOnBeginPaint)

-------------------------------------------------------------------------------------------------
function IGEOnSelectedPlot(plot)
	currentPlot = plot;
end
LuaEvents.IGE_SelectedPlot.Add(IGEOnSelectedPlot)



--===============================================================================================
-- UNDO
--===============================================================================================
function IGEBeginUndoGroup()
	table.insert(undoStack, {});
end

-------------------------------------------------------------------------------------------------
function IGEUndo(stack, altStack)
	while true do
		if #stack == 0 then break end

		local set = stack[#stack];
		table.remove(stack, #stack);

		if #set > 0 then
			local altSet = {};
			table.insert(altStack, altSet);

			for i = #set, 1, -1 do
				local backup = set[i];
				local plot = Map.GetPlot(backup.x, backup.y);
				local altBackup = IGEBackupPlot(plot);
				table.insert(altSet, altBackup);
				IGERestorePlot(backup);
			end
			break;
		end
	end

	IGECommitTerrainChanges();
	IGECommitFogChanges();
	LuaEvents.IGE_Update();
end

-------------------------------------------------------------------------------------------------
function IGEDoAction(plot, func, arg, invalidate)
	if invalidate == nil then 
		invalidate = true;
	end

	local backup = IGEBackupPlot(plot);
	local changed, resourceChanged = func(arg, plot)
	if changed then
		if invalidate then
			IGEInvalidateTerrain(plot, resourceChanged);
		end
		table.insert(undoStack[#undoStack], backup);
	end
end

-------------------------------------------------------------------------------------------------
function IGEOnUndo()
	if not isVisible then return end
	IGEUndo(undoStack, redoStack);	
end
LuaEvents.IGE_Undo.Add(IGEOnUndo);

-------------------------------------------------------------------------------------------------
function IGEOnRedo()
	if not isVisible then return end
	IGEUndo(redoStack, undoStack);	
end
LuaEvents.IGE_Redo.Add(IGEOnRedo);

-------------------------------------------------------------------------------------------------
function IGEOnPushUndoStack(set)
	if not isVisible then return end
	table.insert(undoStack, set);
end
LuaEvents.IGE_PushUndoStack.Add(IGEOnPushUndoStack);


--===============================================================================================
-- UPDATE
--===============================================================================================
function IGEUpdateStatusForPlot(plot)
	local selected = nil;

	-- Terrains
	local terrainID = plot:GetTerrainType();
	for i, v in pairs(editData.terrains) do
		v.enabled = IGECanHaveTerrain(plot, v);
		v.selected = (terrainID == v.ID);
		if v.selected then selected = v end
	end

	-- Water terrains
	for i, v in pairs(editData.waterTerrains) do
		v.enabled = IGECanHaveTerrain(plot, v);
		v.note = v.enabled and BUG_NoGraphicalUpdate or BUG_SavegameCorruption;
		v.selected = (terrainID == v.ID);
		if v.selected then selected = v end
	end

	-- Types
	local plotType = plot:GetPlotType();
	for i, v in pairs(editData.types) do
		v.selected = (plotType == v.type);
	end

	-- Features
	local featureID = plot:GetFeatureType();
	for i, v in pairs(editData.features) do 
		v.enabled = IGECanHaveFeature(plot, v);
		v.selected = (featureID == v.ID);
	end

	-- Natural wonders
	for k, v in pairs(editData.naturalWonders) do 
		v.enabled = IGECanHaveNaturalWonder(plot, v);
		v.selected = (featureID == v.ID);
	end

	-- Resources
	local resourceID = plot:GetResourceType();
	local numResource = plot:GetNumResource();
	for k, v in pairs(editData.allResources) do 
		v.enabled = IGECanHaveResource(plot, v);
		v.selected = (resourceID == v.ID);

		if v.selected and v.usage == ResourceUsageTypes.RESOURCEUSAGE_STRATEGIC then
			v.qty = numResource;
		end
	end

	-- Improvements
	local improvementID = plot:GetImprovementType();
	for k, v in pairs(editData.improvements) do 
		v.enabled = IGECanHaveImprovement(plot, v);
		v.selected = (improvementID == v.ID);
	end

	-- Great improvements
	for k, v in pairs(editData.greatImprovements) do 
		v.enabled = IGECanHaveImprovement(plot, v);
		v.selected = (improvementID == v.ID);
	end

	-- Routes
	local routeID = plot:GetRouteType();
	for k, v in pairs(editData.routes) do 
		v.enabled = (plotType == PlotTypes.PLOT_LAND or plotType == PlotTypes.PLOT_HILLS);
		v.selected = (routeID == v.ID);
	end

	-- Continent Arts
	local artID = plot:GetContinentArtType();
	for k, v in pairs(editData.continentArts) do 
		v.selected = (artID == v.ID);
	end

	local isOwner = (plot:GetOwner() == IGE.currentPlayerID);
	editData.ownerships[1].selected = not isOwner;
	editData.ownerships[2].selected = isOwner;

	local team = Players[IGE.currentPlayerID]:GetTeam();
	local visible = plot:IsRevealed(team, false);
	editData.fogs[2].selected = not visible;
	editData.fogs[1].selected = visible;


	local variety = plot:GetFeatureVariety();
	IGE.pillaged = plot:IsImprovementPillaged();
end

-------------------------------------------------------------------------------------------------
local function UpdateCore(data)
	-- Strategic resources
	selectedStrategicResource = IGEGetSelection(data.strategicResources);
	Controls.ResourceAmountGrid:SetHide(selectedStrategicResource == nil);
	Controls.ResourceAmountLabel:SetText(selectedStrategicResource and selectedStrategicResource.iconString or "");
	UpdateResourceAmount(IGEGetResourceAmount());

	-- Pillaged improvement
	local selectedImprovement = IGEGetSelection(data.improvements) or IGEGetSelection(data.greatImprovements);
	if selectedImprovement and selectedImprovement.ID == -1 then selectedImprovement = nil end

	Controls.PillageCB:SetCheck(IGE.pillaged);
	Controls.PillageCB:SetHide(selectedImprovement == nil);

	-- Update lists
	IGEUpdateGeneric(data.types,				typeItemManager,				IGEClickHandler);
	IGEUpdateList(data.features,				featureItemManager,				IGEClickHandler);
	IGEUpdateList(data.terrains,				terrainItemManager,				IGEClickHandler);
	IGEUpdateList(data.waterTerrains,			waterItemManager,				IGEClickHandler);
	IGEUpdateList(data.naturalWonders,			naturalWonderItemManager,		IGEClickHandler);
	IGEUpdateList(data.bonusResources,			bonusResourceItemManager,		IGEClickHandler);
	IGEUpdateList(data.luxuryResources,			luxuryResourceItemManager,		IGEClickHandler);
	IGEUpdateList(data.strategicResources,		strategicResourceItemManager,	IGEClickHandler);
	IGEUpdateList(data.greatImprovements,		greatImprovementItemManager,	IGEClickHandler);
	IGEUpdateList(data.improvements,			improvementItemManager,			IGEClickHandler);
	IGEUpdateList(data.routes,					routeItemManager,				IGEClickHandler);
	IGEUpdateList(data.fogs,					fogItemManager,					IGEClickHandler);
	IGEUpdateList(data.ownerships,				ownershipItemManager,			IGEClickHandler);
	IGEUpdateList(data.continentArts,			artItemManager,					IGEClickHandler);

	-- IGEResize
	Controls.ImprovementsInnerStack:CalculateSize();
	Controls.ImprovementsInnerStack:ReprocessAnchoring();

	Controls.StrategicResourceStack:CalculateSize();
	Controls.StrategicResourceStack:ReprocessAnchoring();

	-- Update elements visibility
	local selectedLand = IGEGetSelection(data.terrains);
	local isWaterPlot = isEditing and (selectedLand == nil);
	Controls.RiversElement:SetHide(isWaterPlot or not isEditing);
	Controls.TypeList:SetHide(isWaterPlot);
	Controls.ArtList:SetHide(isWaterPlot);

	local selectionPrompt = isEditing and (currentPlot == nil);
	Controls.PromptContainer:SetHide(not selectionPrompt);
	Controls.ScrollPanel:SetHide(selectionPrompt);

	-- Update groups size
	local groupCount = 0;
	for k, v in pairs(groups) do
		v.instance.Stack:SetHide(not v.visible);
		if v.visible then
			if v.control.CalculateSize then
				v.control:CalculateSize();
			end
			local width = v.control:GetSizeX();
			v.instance.Stack:SetSizeX(width + 20);
			v.instance.HeaderBackground:SetSizeX(width + 20);
			v.instance.List:SetOffsetX(10);
			groupCount = groupCount + 1;
		end
	end

	-- Adjust padding to cover the whole length
	Controls.MainStack:CalculateSize();
	Controls.MainStack:ReprocessAnchoring();

	local diff = Controls.MainStack:GetSizeX() - Controls.Container:GetSizeX();
	local offset = (diff < 0) and 10 - diff / (2 * groupCount) or 10;
	for k, v in pairs(groups) do
		local width = v.control:GetSizeX();
		v.instance.Stack:SetSizeX(width + 2 * offset);
		v.instance.HeaderBackground:SetSizeX(width + 2 * offset);
		v.instance.List:SetOffsetX(offset);
	end

	-- Update scroll bar
	Controls.MainStack:CalculateSize();
	Controls.MainStack:ReprocessAnchoring();
    Controls.ScrollPanel:CalculateInternalSize();
end

-------------------------------------------------------------------------------------------------
function IGEOnUpdate()
	Controls.OuterContainer:SetHide(not isVisible);
	Controls.RiversElement:SetHide(true);
	IGEOnResizedReseedElement(0, 0)

	if isEditing then
		if not isVisible then return end
		LuaEvents.IGE_SetMouseMode(IGE_MODE_EDIT);

		Controls.PromptContainer:SetHide(currentPlot ~= nil);
		Controls.Container:SetHide(currentPlot == nil);
		if not currentPlot then return end

		IGEUpdateStatusForPlot(currentPlot);
		UpdateCore(editData);
	else
		if not isVisible then return end
		LuaEvents.IGE_SetMouseMode(currentPaintSelection and IGE_MODE_PAINT or IGE_MODE_NONE);

		Controls.PromptContainer:SetHide(true);
		Controls.Container:SetHide(false);
		UpdateCore(paintData);
	end
end
LuaEvents.IGE_Update.Add(IGEOnUpdate);

-------------------------------------------------------------------------------------------------
function IGEOnResizedReseedElement(w, h)
	Controls.PromptLabelContainer:SetSizeX(Controls.PromptContainer:GetSizeX() - (w + 40));
	Controls.PromptLabelContainer:SetSizeY(Controls.PromptContainer:GetSizeY());
	Controls.PromptLabelContainer:ReprocessAnchoring();
	Controls.PromptContainer:ReprocessAnchoring();
end
LuaEvents.IGE_ResizedReseedElement.Add(IGEOnResizedReseedElement)

--===============================================================================================
-- CONTROLS EVENTS
--===============================================================================================
function IGEGetResourceAmount()
	return selectedStrategicResource and selectedStrategicResource.qty or 1;
end

-------------------------------------------------------------------------------------------------
function IGESetResourceAmount(amount, userInteraction)
	if selectedStrategicResource then
		selectedStrategicResource.qty = amount;

		if isEditing then
			if currentPlot and userInteraction then
				IGEBeginUndoGroup();
				IGEDoAction(currentPlot, IGESetResourceQty, amount, false);
			end
		end
	end
end
UpdateResourceAmount = IGEHookNumericBox("ResourceAmount", IGEGetResourceAmount, IGESetResourceAmount, 1, nil, 1);

-------------------------------------------------------------------------------------------------
function IGEOnPillageCBChanged()
	if isEditing and currentPlot then
		IGE.pillaged = Controls.PillageCB:IsChecked();

		IGEBeginUndoGroup();
		IGEDoAction(currentPlot, IGESetImprovementPillaged, IGE.pillaged, false);
	end
end
Controls.PillageCB:RegisterCallback(Mouse.eLClick, IGEOnPillageCBChanged);



