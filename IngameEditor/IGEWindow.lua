-- Released under GPL v3
--------------------------------------------------------------
include("IGEAPIAll");
print("IGE_Window");

IGE = nil;
local initialized = false;
local currentPlot = nil;
local oldCurrentPlot = nil;
local mouseHandlers = {};
local mouseMode = 0;
--local busy = false;


--===============================================================================================
-- INIT-SHOW-HIDE
--===============================================================================================
local function IGEOnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
	IGEOnUpdatedOptions(_IGE);
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(IGEOnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function IGEOnInitialize()
	IGEResize(Controls.MainGrid);
	local sizeX, sizeY = UIManager:GetScreenSizeVal();
	local offset = (sizeX - 320) - Controls.MainGrid:GetSizeX();
	Controls.MainGrid:SetOffsetX(offset > 0 and offset * 0.5 or -10);

	if sizeY < 1000 then
		Controls.PanelsContainer:SetOffsetY(47);
		IGELowerSizeY(Controls.MainGrid, 21);
	end

	if not UI.CompareFileTime then 
		print("Pirate version, autosave disabled.");
		Controls.ReloadButton:SetHide(true);
		Controls.SaveButton:SetHide(true);
		Controls.AutoSave:SetHide(true);
	end
end
LuaEvents.IGE_Initialize.Add(IGEOnInitialize);

-------------------------------------------------------------------------------------------------
local function IsVisible()
	return not Controls.Container:IsHidden();
end

-------------------------------------------------------------------------------------------------
local function SetBusy(flag, loading)
	busy = flag;
	UI.SetBusy(flag);--[[
	Controls.MainButton:SetDisabled(busy);
	UIManager:SetUICursor(busy and 1 or 0);]]
end

-------------------------------------------------------------------------------------------------
local function ClosePopups()
	LookUpControl("InGame/WorldView/InfoCorner/TechPanel"):SetHide(true);
	LookUpControl("InGame/TechAwardPopup"):SetHide(true);
	LookUpControl("InGame/ProductionPopup"):SetHide(true);
	Controls.ChooseReligionPopup:SetHide(true);
	Controls.ChoosePantheonPopup:SetHide(true);
	Controls.ProductionPopup:SetHide(true);
	Controls.OptionsPanel:SetHide(true);
	Controls.WonderPopup:SetHide(true);
end

-------------------------------------------------------------------------------------------------
local function OpenCore()
	if not initialized then
		LuaEvents.IGE_Initialize();
		initialized = true;
		print("Initialization completed");
	end

	IGE.revealMap = false;
	IGEOnUpdateUI()
	LuaEvents.IGE_Showing();
	IGEUpdateMouse();

	ClosePopups();
	UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_SELECTION);
	print("OpenCore - step1");
    Events.SystemUpdateUI.CallImmediate(SystemUpdateUIType.BulkHideUI);
	Events.SerialEventMouseOverHex.Add(IGEOnMouseMoveOverHex);
	print("OpenCore - step2");
	Events.CameraViewChanged.Add(IGEUpdateMouse);
	Controls.Container:SetHide(false);
	print("OpenCore - done");
end

-------------------------------------------------------------------------------------------------
local reportedError = false;
local function OnInitializationError(err)
	if reportedError then return end
	reportedError = true;

	print("Failed to open IGE:");
	err = IGEFormatError(err, 1);

	-- Show popup to user
	local str = IGEL("TXT_KEY_IGE_LOADING_ERROR").."[NEWLINE][ICON_PIRATE] "..err;
	Events.SerialEventGameMessagePopup( { Type = ButtonPopupTypes.BUTTONPOPUP_TEXT, Data1 = 800, Option1 = true, Text = str } );

	-- Restore things up
	Events.SystemUpdateUI.CallImmediate(SystemUpdateUIType.BulkShowUI);
	Events.ClearHexHighlights();
	LuaEvents.IGE_Show_Fail();
	return false
end

-------------------------------------------------------------------------------------------------
local function Open()
	if not IsVisible() and not busy then
		SetBusy(true);

		-- More than one version installed?
		local pingData = { count = 0 };
		LuaEvents.IGE_PingAllVersions(pingData);
		if (pingData.count > 1) then
			local str = IGEL("TXT_KEY_IGE_MORE_THAN_ONE_VERSION_ERROR");
			Events.SerialEventGameMessagePopup( { Type = ButtonPopupTypes.BUTTONPOPUP_TEXT, Data1 = 800, Option1 = true, Text = str } );
			SetBusy(false);
			return;
		end

		-- Try to init data
		reportedError = false;
		local status, err = xpcall(OpenCore, OnInitializationError);
		if not status then 
			SetBusy(false);
			return;
		end

		-- Autosave
		print("SaveFile - begin");
		if IGE.autoSave then
			IGESaveFile(IGE.cleanUpFiles);
		end
		print("SaveFile - done");

		-- Restore current plot
		if oldCurrentPlot then
			IGESetCurrentPlot(oldCurrentPlot);
		end

		SetBusy(false);
		print("SetBusy - done");
		LuaEvents.IGE_Update();
	end
end

-------------------------------------------------------------------------------------------------
local function Close(keepBulkUIHidden, takingSeat)
	if IsVisible() and not busy then
		SetBusy(true);
		if not takingSeat then 
			if Game.GetActivePlayer() ~= IGE.initialPlayerID then
				Game.SetActivePlayer(IGE.initialPlayerID);
			end
		end

		leftButtonDown = false;
		rightButtonDown = false;
		oldCurrentPlot = currentPlot;
		IGESetCurrentPlot(nil);
		LuaEvents.IGE_Closing(takingSeat);

		if not keepBulkUIHidden then
			Events.SystemUpdateUI.CallImmediate(SystemUpdateUIType.BulkShowUI);
		end
		ClosePopups();

		Events.SerialEventMouseOverHex.Remove(IGEOnMouseMoveOverHex);
		Events.CameraViewChanged.Remove(IGEUpdateMouse);

		Controls.Container:SetHide(true);
		UI.SetInterfaceMode(InterfaceModeTypes.INTERFACEMODE_SELECTION);
		IGESetMouseMode(IGE_MODE_NONE);
		Map.RecalculateAreas();

		SetBusy(false);
	end
end
Controls.CloseButton:RegisterCallback(Mouse.eLClick, function() Close(false, false) end);

-------------------------------------------------------------------------------------------------
local function IGEOnForceQuit(takingSeat)
	Close(false, takingSeat);
end
LuaEvents.IGE_ForceQuit.Add(IGEOnForceQuit);

-------------------------------------------------------------------------------------------------
local function CloseAndKeepUIHidden()
	Close(true, false);
end
Events.SearchForPediaEntry.Add(CloseAndKeepUIHidden);
Events.GoToPediaHomePage.Add(CloseAndKeepUIHidden);


--===============================================================================================
-- MOUSE HOVER
--===============================================================================================
local selectedNewPlot = false;
local highlightedPlots = {};
function IGESetCurrentPlot(plot)
	selectedNewPlot = (plot ~= currentPlot);
	currentPlot = plot;

	LuaEvents.IGE_SelectedPlot(plot);
	LuaEvents.IGE_Update();
end

-------------------------------------------------------------------------------------------------
local function HighlightPlot(plot, color)
	if plot then
		Events.SerialEventHexHighlight(ToHexFromGrid(Vector2(plot:GetX(), plot:GetY())), true, color);
	end
end

-------------------------------------------------------------------------------------------------
function IGEUpdateMouse(mouseOver, gridX, gridY)
	if gridX == nil then
		gridX, gridY = UI.GetMouseOverHex();
	end
	if mouseOver == nil then
		mouseOver = Controls.Background:HasMouseOver();
	end

	local shift = UIManager:GetShift();
	local plot = mouseOver and Map.GetPlot(gridX, gridY) or nil;
	Events.ClearHexHighlights();

	if mouseMode == IGE_MODE_PAINT then
		if plot then
			local color = rightButtonDown and Vector4(1.0, 0.0, 0.0, 1) or Vector4(0, 1.0, 0, 1);
			HighlightPlot(plot, color);

			if shift then
				for neighbor in IGENeighbors(plot) do
					HighlightPlot(neighbor, color);
				end
			end

			if rightButtonDown then
				LuaEvents.IGE_PaintPlot(2, plot, shift);
			end
		end

	elseif mouseMode == IGE_MODE_PLOP then
		if plot then
			local color = rightButtonDown and Vector4(1, 0, 0, 1) or Vector4(0, 1, 0, 1);
			HighlightPlot(plot, color);
		end

	elseif mouseMode == IGE_MODE_EDIT_AND_PLOP then
		if currentPlot then
			local rightClickCurrentPlot = (rightButtonDown and plot == currentPlot);
			local color = rightClickCurrentPlot and Vector4(0, 1, 0, 1) or Vector4(1, 0, 0, 1);
			HighlightPlot(currentPlot, color);
		end

	elseif mouseMode == IGE_MODE_EDIT then
		if currentPlot then
			HighlightPlot(currentPlot, Vector4(1, 0, 0, 1));
		end
	end

	-- Plots that have been undone
	for i, v in ipairs(highlightedPlots) do
		HighlightPlot(v, Vector4(0, 0, 1, 1));
	end

	LuaEvents.IGE_BroadcastingMouseState(mouseOver, gridX, gridY, plot, shift);
end

-------------------------------------------------------------------------------------------------
function IGEOnMouseMoveOverHex(hexX, hexY)
	IGEUpdateMouse(nil, hexX, hexY);
end

-------------------------------------------------------------------------------------------------
function IGEOnBackgroundMouseEnter()
	if IsVisible() then
		leftButtonDown = false;
		rightButtonDown = false;
		IGEUpdateCursor(true);
		IGEUpdateMouse(true);
	end
end
Controls.Background:RegisterCallback(Mouse.eMouseEnter, IGEOnBackgroundMouseEnter);

-------------------------------------------------------------------------------------------------
function IGEOnBackgroundMouseExit()
	if IsVisible() then
		leftButtonDown = false;
		rightButtonDown = false;
		IGEUpdateCursor(false);
		IGEUpdateMouse(false);
	end
end
Controls.Background:RegisterCallback(Mouse.eMouseExit, IGEOnBackgroundMouseExit);

-------------------------------------------------------------------------------------------------
function IGEUpdateCursor(hasMouseOver)
	local cursor = 0;
	if hasMouseOver then
		if mouseMode > IGE_MODE_EDIT_AND_PLOP then
			cursor = 8;
		elseif mouseMode > 0 then
			cursor = 3;
		end
	end
	UIManager:SetUICursor(cursor);
end

-------------------------------------------------------------------------------------------------
function IGESetMouseMode(mode)
	if mode == mouseMode then return end
	leftButtonDown = false;
	rightButtonDown = false;
	mouseMode = mode;
	IGEUpdateCursor();
	IGEUpdateMouse();
end
LuaEvents.IGE_SetMouseMode.Add(IGESetMouseMode);

-------------------------------------------------------------------------------------------------
function IGEOnFlashPlot(plot)
	table.insert(highlightedPlots, plot);
	IGEUpdateMouse();

	LuaEvents.IGE_Schedule(nil, 1.0, function()
		table.remove(highlightedPlots, 1);
		IGEUpdateMouse();
	end);
end
LuaEvents.IGE_FlashPlot.Add(IGEOnFlashPlot);


--===============================================================================================
-- INPUTS
--===============================================================================================
mouseHandlers[IGE_MODE_NONE] = function(uiMsg)
end

-------------------------------------------------------------------------------------------------
mouseHandlers[IGE_MODE_EDIT] = function(uiMsg)
	if uiMsg == MouseEvents.RButtonDown then
		IGESetCurrentPlot(nil);
		IGEUpdateMouse();
	elseif uiMsg == MouseEvents.LButtonDown then
		IGESetCurrentPlot(Map.GetPlot(UI.GetMouseOverHex()));
		IGEUpdateMouse();
	end
end

-------------------------------------------------------------------------------------------------
mouseHandlers[IGE_MODE_EDIT_AND_PLOP] = function(uiMsg)
	if uiMsg == MouseEvents.RButtonDown then
		IGESetCurrentPlot(nil);
		IGEUpdateMouse();
	elseif uiMsg == MouseEvents.LButtonDown then
		IGESetCurrentPlot(Map.GetPlot(UI.GetMouseOverHex()));
		IGEUpdateMouse();

		if UIManager:GetShift() then
			LuaEvents.IGE_Plop(1, Map.GetPlot(UI.GetMouseOverHex()), true);
		end
	end
end

-------------------------------------------------------------------------------------------------
mouseHandlers[IGE_MODE_PAINT] = function(uiMsg)
	if uiMsg == MouseEvents.RButtonUp then
		IGEUpdateMouse();
	elseif uiMsg == MouseEvents.RButtonDown then
		LuaEvents.IGE_BeginPaint();
		IGEUpdateMouse();
	end
end

-------------------------------------------------------------------------------------------------
mouseHandlers[IGE_MODE_PLOP] = function(uiMsg)
	if uiMsg == MouseEvents.RButtonUp then
		IGEUpdateMouse();
	elseif uiMsg == MouseEvents.RButtonDown then
		IGEUpdateMouse();
		LuaEvents.IGE_Plop(2, Map.GetPlot(UI.GetMouseOverHex()), UIManager:GetShift());
	end
end

-------------------------------------------------------------------------------------------------
function IGEInputHandler(uiMsg, wParam, lParam)
	if IsVisible() then
		if uiMsg == MouseEvents.LButtonDown then
			selectedNewPlot = false;
			leftButtonDown = true;
		elseif uiMsg == MouseEvents.LButtonUp then
			leftButtonDown = false;
		elseif uiMsg == MouseEvents.RButtonDown then
			rightButtonDown = true;
		elseif uiMsg == MouseEvents.RButtonUp then
			rightButtonDown = false;
		end

		if Controls.Background:HasMouseOver() then
			local func = mouseHandlers[mouseMode];
			func(uiMsg);
		end
		
		if uiMsg == MouseEvents.LButtonDown then
			return false;
		elseif uiMsg == MouseEvents.LButtonUp then
			return selectedNewPlot;
		elseif uiMsg == MouseEvents.RButtonDown then
			return true;
		elseif uiMsg == MouseEvents.RButtonUp then
			return true;
		elseif uiMsg == KeyEvents.KeyUp then
			IGEUpdateMouse();
			if wParam == Keys.Z and UIManager:GetControl() then
				return true;
			end

		-- Shortcuts
		elseif uiMsg == KeyEvents.KeyDown then
			if IGEProcessShortcuts(wParam) then
				IGEUpdateMouse();
				return true;
			else
				IGEUpdateMouse();
			end
		end
	end

	-- Open IGE
	if uiMsg == KeyEvents.KeyDown and wParam == Keys.I and UIManager:GetControl() then
		IGEToggle();
		return true;
	end

	return false;
end
ContextPtr:SetInputHandler(IGEInputHandler);

-------------------------------------------------------------------------------------------------
function IGEProcessShortcuts(key)
	-- Escape = quit
	if key == Keys.VK_ESCAPE then
		Close(false, false);
		return true;
	end

	-- Ctrl + Z = undo
	if key == Keys.Z and UIManager:GetControl() then
		rightButtonDown = false;
		leftButtonDown = false;
		LuaEvents.IGE_Undo();
		return true;
	end
	-- Ctrl + Y = redo
	if key == Keys.Y and UIManager:GetControl() then
		rightButtonDown = false;
		leftButtonDown = false;
		LuaEvents.IGE_Redo();
		return true;
	end

	-- F5 = quicksave
	-- Ctrl + F5 = save and reload
	if key == Keys.VK_F5 then
		if UIManager:GetControl() then
			IGEOnReloadButtonClick();
		else
			IGEOnSaveButtonClick();
		end
		return true;
	end

	-- F1-F4 and F6-F8 : panels
	if key == Keys.VK_F1 then
		LuaEvents.IGE_SetTab("TERRAIN_EDITION");
		return true;
	end
	if key == Keys.VK_F2 then
		LuaEvents.IGE_SetTab("CITIES_AND_UNITS");
		return true;
	end
	if key == Keys.VK_F3 then
		LuaEvents.IGE_SetTab("TERRAIN_PAINTING");
		return true;
	end
	if key == Keys.VK_F4 then
		LuaEvents.IGE_SetTab("UNITS");
		return true;
	end
	if key == Keys.VK_F6 then
		LuaEvents.IGE_SetTab("PLAYERS");
		return true;
	end
	if key == Keys.VK_F7 then
		LuaEvents.IGE_SetTab("TECHS");
		return true;
	end
	if key == Keys.VK_F8 then
		LuaEvents.IGE_SetTab("POLICIES");
		return true;
	end
end


--===============================================================================================
-- OPTIONS AND CONTROLS
--===============================================================================================
function IGEOnUpdatedOptions(IGE)
	Controls.AutoSave:SetCheck(IGE.autoSave);
	Controls.ShowResources:SetCheck(IGE.showResources);
	Controls.ShowUnknownResources:SetCheck(IGE.showUnknownResources);
	Controls.DisableStrategicView:SetCheck(IGE.disableStrategicView);
	Controls.CleanUpFiles:SetCheck(IGE.cleanUpFiles);
	Controls.ShowYields:SetCheck(IGE.showYields);
	Controls.SafeMode:SetCheck(IGE.safeMode);
end
LuaEvents.IGE_UpdatedOptions.Add(IGEOnUpdatedOptions);

-------------------------------------------------------------------------------------------------
function IGEOnOptionControlChanged()
	local options = {};
	options.autoSave = Controls.AutoSave:IsChecked();
	options.cleanUpFiles = Controls.CleanUpFiles:IsChecked();
	options.disableStrategicView = Controls.DisableStrategicView:IsChecked();
	options.showUnknownResources = Controls.ShowUnknownResources:IsChecked();
	options.showResources = Controls.ShowResources:IsChecked();
	options.showYields = Controls.ShowYields:IsChecked();
	options.safeMode = Controls.SafeMode:IsChecked();
	LuaEvents.IGE_UpdateOptions(options);
end
Controls.CleanUpFiles:RegisterCheckHandler(IGEOnOptionControlChanged);
Controls.DisableStrategicView:RegisterCheckHandler(IGEOnOptionControlChanged);
Controls.ShowUnknownResources:RegisterCheckHandler(IGEOnOptionControlChanged);
Controls.ShowResources:RegisterCheckHandler(IGEOnOptionControlChanged);
Controls.ShowYields:RegisterCheckHandler(IGEOnOptionControlChanged);
Controls.SafeMode:RegisterCheckHandler(IGEOnOptionControlChanged);
Controls.AutoSave:RegisterCheckHandler(IGEOnOptionControlChanged);

-------------------------------------------------------------------------------------------------
function IGEOnSaveButtonClick()
	IGESaveFile(IGE.cleanUpFiles);
end
Controls.SaveButton:RegisterCallback(Mouse.eLClick, IGEOnSaveButtonClick);

-------------------------------------------------------------------------------------------------
function IGEOnReloadButtonClick()
	LuaEvents.IGE_ConfirmPopup(IGEL("TXT_KEY_IGE_CONFIRM_SAVE_AND_RELOAD"), function()
		local fileName = "IGE - reload";
		if IGE.cleanUpFiles then
			IGEDeleteFiles(fileName);
		end
		UI.SaveGame(fileName, true);
		IGELoadFile(fileName);
	end);
end
Controls.ReloadButton:RegisterCallback(Mouse.eLClick, IGEOnReloadButtonClick);

-------------------------------------------------------------------------------------------------
local function OnRevealMapButtonClick()
	IGE.revealMap = true;
	LuaEvents.IGE_ToggleRevealMap(IGE.revealMap);
end
Controls.RevealMapButton:RegisterCallback(Mouse.eLClick, OnRevealMapButtonClick);

-------------------------------------------------------------------------------------------------
local function OnCoverMapButtonClick()
	IGE.revealMap = false;
	LuaEvents.IGE_ToggleRevealMap(IGE.revealMap);
end
Controls.CoverMapButton:RegisterCallback(Mouse.eLClick, OnCoverMapButtonClick);

-------------------------------------------------------------------------------------------------
function IGEOnUpdateUI()
	local notHuman = not Players[Game.GetActivePlayer()]:IsHuman()
	Controls.CoverMapButton:SetHide(notHuman or not IGE.revealMap);
	Controls.RevealMapButton:SetHide(notHuman or IGE.revealMap);
	Controls.IGECameraButton:SetHide(notHuman)
end
LuaEvents.IGE_Update.Add(IGEOnUpdateUI)
LuaEvents.IGE_ToggleRevealMap.Add(IGEOnUpdateUI);

-------------------------------------------------------------------------------------------------
local function OnIGECameraHome()
	local plot = IGE.currentPlayer:GetStartingPlot()
	if plot then 
		print("Go home")
		UI.LookAt(plot) 
	end
end
Controls.IGECameraButton:RegisterCallback(Mouse.eLClick, OnIGECameraHome);

-------------------------------------------------------------------------------------------------
local function IGEToggleOptions() 
	local hidden = Controls.OptionsPanel:IsHidden();
	Controls.OptionsPanel:SetHide(not hidden);
end 
Controls.MainButton:RegisterCallback(Mouse.eRClick, IGEToggleOptions);

-------------------------------------------------------------------------------------------------
function IGEToggle() 
	if IsVisible() then
		Close();
	else
		Open();
	end
end 
Controls.MainButton:RegisterCallback(Mouse.eLClick, IGEToggle);

-------------------------------------------------------------------------------------------------
local TOP    = 0;
local BOTTOM = 1;
local LEFT   = 2;
local RIGHT  = 3;

local function ScrollMouseEnter(which)
    if which == TOP then
		Events.SerialEventCameraStartMovingForward();
    elseif which == BOTTOM then
		Events.SerialEventCameraStartMovingBack();
    elseif which == LEFT then
		Events.SerialEventCameraStartMovingLeft();
    else
		Events.SerialEventCameraStartMovingRight();
    end
end

local function ScrollMouseExit(which)
    if which == TOP then
		Events.SerialEventCameraStopMovingForward();
    elseif which == BOTTOM then
		Events.SerialEventCameraStopMovingBack();
    elseif which == LEFT then
		Events.SerialEventCameraStopMovingLeft();
    else
		Events.SerialEventCameraStopMovingRight();
    end
end
Controls.ScrollTop:RegisterCallback( Mouse.eMouseEnter, ScrollMouseEnter);
Controls.ScrollTop:RegisterCallback( Mouse.eMouseExit, ScrollMouseExit);
Controls.ScrollTop:SetVoid1(TOP);

Controls.ScrollBottom:RegisterCallback( Mouse.eMouseEnter, ScrollMouseEnter);
Controls.ScrollBottom:RegisterCallback( Mouse.eMouseExit, ScrollMouseExit);
Controls.ScrollBottom:SetVoid1(BOTTOM);

Controls.ScrollLeft:RegisterCallback( Mouse.eMouseEnter, ScrollMouseEnter);
Controls.ScrollLeft:RegisterCallback( Mouse.eMouseExit, ScrollMouseExit);
Controls.ScrollLeft:SetVoid1(LEFT);

Controls.ScrollRight:RegisterCallback( Mouse.eMouseEnter, ScrollMouseEnter);
Controls.ScrollRight:RegisterCallback( Mouse.eMouseExit, ScrollMouseExit);
Controls.ScrollRight:SetVoid1(RIGHT);

LuaEvents.IGE_ShareGlobalAndOptions();
print("IGE loaded");

