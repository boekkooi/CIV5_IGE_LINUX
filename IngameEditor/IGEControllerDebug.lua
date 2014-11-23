-- Released under GPL v3
--------------------------------------------------------------
local debug = true;

function IGEplot_to_str(plot)
	if plot then
		return "("..plot:GetX().." ; "..plot:GetY()..")";
	else
		return "nil";
	end
end

--===============================================================================================
-- INIT-SHOW-UPDATE
--===============================================================================================
function IGEOnUpdate()
	print("IGE_Update");
end
LuaEvents.IGE_Update.Add(IGEOnUpdate);

function IGEOnPingAllVersions(data)
	print("IGE_PingAllVersions, data="..getstr(data));
end
LuaEvents.IGE_PingAllVersions.Add(IGEOnPingAllVersions);

function IGEOnInitialize()
	print("IGE_Initialize");
	print("IGE:Gods and kings="..getstr(IGE_HasGodsAndKings));
	print("IGE:Brave new world="..getstr(IGE_HasBraveNewWorld));
end
LuaEvents.IGE_Initialize.Add(IGEOnInitialize);

function IGEOnShareGlobalAndOptions()
	print("IGE_ShareGlobalAndOptions");
end
LuaEvents.IGE_ShareGlobalAndOptions.Add(IGEOnShareGlobalAndOptions);

function IGEOnSharingGlobalAndOptions(IGE)
	print("IGE_SharingGlobalAndOptions"..", IGE="..getstr(IGE));
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(IGEOnSharingGlobalAndOptions);

function IGEOnShowing()
	print("IGE_Showing");
end
LuaEvents.IGE_Showing.Add(IGEOnShowing);

function IGEOnShowingFailure()
	print("IGE_Showing_Failure");
end
LuaEvents.IGE_Showing_Failure.Add(IGEOnShowingFailure);

function IGEOnClosing(takingSeat)
	print("IGE_Closing"..", takingSeat="..getstr(takingSeat));
end
LuaEvents.IGE_Closing.Add(IGEOnClosing);

function IGEOnClosingPreview(takingSeat)
	print("IGE_Closing_Preview"..", takingSeat="..getstr(takingSeat));
end
LuaEvents.IGE_Closing_Preview.Add(IGEOnClosingPreview);

function IGEOnForceQuit(takingSeat)
	print("IGE_ForceQuit"..", takingSeat="..getstr(takingSeat));
end
LuaEvents.IGE_ForceQuit.Add(IGEOnForceQuit);

--===============================================================================================
-- INPUTS
--===============================================================================================
function IGEOnBroadcastingMouseState(mouseOver, gridX, gridY, plot, shift)
	--print("IGE_BroadcastingMouseState"..", mouseOver="..getstr(mouseOver)..", x="..getstr(gridX)..", y="..getstr(gridY)..", shift="..getstr(shift));
end
LuaEvents.IGE_BroadcastingMouseState.Add(IGEOnBroadcastingMouseState);

function IGEOnSelectedPlot(plot)
	--print("IGE_SelectedPlot"..", plot="..IGEplot_to_str(plot));
end
LuaEvents.IGE_SelectedPlot.Add(IGEOnSelectedPlot);

function IGEIGE_BeginPaint()
	print("IGE_BeginPaint");
end
LuaEvents.IGE_BeginPaint.Add(OnBeginPaint);

function IGEOnPaintPlot(button, plot, shift)
	--print("IGE_PaintPlot"..", button="..getstr(button)..", plot="..IGEplot_to_str(plot)..", shift="..getstr(shift));
end
LuaEvents.IGE_PaintPlot.Add(IGEOnPaintPlot);

function IGEOnPlop(button, plot, shift)
	--print("IGE_Plop"..", button="..getstr(button)..", plot="..IGEplot_to_str(plot)..", shift="..getstr(shift));
end
LuaEvents.IGE_Plop.Add(IGEOnPlop);

function IGEOnSetMouseMode(mode)
	print("IGE_SetMouseMode"..", mode="..getstr(mode));
end
LuaEvents.IGE_SetMouseMode.Add(IGEOnSetMouseMode);

function IGEOnPushUndoStack(set)
	print("IGE_PushUndoStack"..", set="..getstr(set));
end
LuaEvents.IGE_PushUndoStack.Add(IGEOnPushUndoStack);

function IGEOnRedo()
	print("IGE_Redo");
end
LuaEvents.IGE_Redo.Add(IGEOnRedo);

function IGEOnUndo()
	print("IGE_Undo");
end
LuaEvents.IGE_Undo.Add(IGEOnUndo);

--===============================================================================================
-- PANELS & TABS MANAGEMENT
--===============================================================================================
function IGEOnSelectedPanel(ID)
	print("IGE_SelectedPanel"..", ID="..getstr(ID));
end
LuaEvents.IGE_SelectedPanel.Add(IGEOnSelectedPanel);

function IGEOnRegisterTab(ID, name, icon, group, toolTip, topData)
	print("IGE_RegisterTab"..", ID="..getstr(ID)..", name="..getstr(name)..", icon="..getstr(icon)..", group="..getstr(group));
end
LuaEvents.IGE_RegisterTab.Add(IGEOnRegisterTab);

function IGEOnSetTabData(data)
	print("IGE_SetTabData"..", data="..getstr(data));
end
LuaEvents.IGE_SetTabData.Add(IGEOnSetTabData);

function IGEOnClosePlayerSelection()
	print("IGE_ClosePlayerSelection");
end
LuaEvents.IGE_ClosePlayerSelection.Add(IGEOnClosePlayerSelection);

function IGEOnSetTab(tab)
	print("IGE_SetTab"..", tab="..getstr(tab));
end
LuaEvents.IGE_SetTab.Add(IGEOnSetTab);

--===============================================================================================
-- OPTIONS
--===============================================================================================
function IGEOnUpdateOptions(options)
	print("IGE_UpdateOptions"..", options="..getstr(options));
end
LuaEvents.IGE_UpdateOptions.Add(IGEOnUpdateOptions);

function IGEOnUpdatedOptions(IGE)
	print("IGE_UpdatedOptions"..", IGE="..getstr(IGE));
end
LuaEvents.IGE_UpdatedOptions.Add(IGEOnUpdatedOptions);


--===============================================================================================
-- OTHERS
--===============================================================================================
function IGEOnSelectPlayer(ID)
	print("IGE_SelectPlayer"..", ID="..getstr(ID));
end
LuaEvents.IGE_SelectPlayer.Add(IGEOnSelectPlayer);

function IGEOnSelectingPlayer(ID)
	print("IGE_SelectingPlayer"..", ID="..getstr(ID));
end
LuaEvents.IGE_SelectingPlayer.Add(IGEOnSelectingPlayer);

function IGEOnSelectedPlayer(ID)
	print("IGE_SelectedPlayer"..", ID="..getstr(ID));
end
LuaEvents.IGE_SelectedPlayer.Add(IGEOnSelectedPlayer);

function IGEOnToggleRevealMap(revealMap)
	print("IGE_ToggleRevealMap"..", revealMap="..getstr(revealMap));
end
LuaEvents.IGE_ToggleRevealMap.Add(IGEOnToggleRevealMap);

function IGEOnModifiedPlot(plot)
	print("IGE_ModifiedPlot"..", plot="..IGEplot_to_str(plot));
end
LuaEvents.IGE_ModifiedPlot.Add(IGEOnModifiedPlot);

function IGEOnFlashPlot(plot)
	print("IGE_FlashPlot"..", plot="..IGEplot_to_str(plot));
end
LuaEvents.IGE_FlashPlot.Add(IGEOnFlashPlot);

function IGEOnSchedule(frames, timeSpan, callback)
	print("IGE_Schedule"..", frames="..getstr(frames)..", timeSpan="..getstr(timeSpan)..", callback="..getstr(callback));
end
LuaEvents.IGE_Schedule.Add(IGEOnSchedule);

function IGEOnForceRevealMap(reveal, removeFoW)
	print("IGE_ForceRevealMap"..", reveal="..getstr(reveal)..", removeFoW="..getstr(removeFoW));
end
LuaEvents.IGE_ForceRevealMap.Add(IGEOnForceRevealMap);

function IGEOnConfirmPopup(text, yesCallback)
	print("IGE_ConfirmPopup"..", text="..getstr(text)..", yesCallback="..getstr(yesCallback));
end
LuaEvents.IGE_ConfirmPopup.Add(IGEOnConfirmPopup);

function IGEOnWonderPopup(buildingID)
	print("IGE_WonderPopup"..", buildingID="..getstr(buildingID));
end
LuaEvents.IGE_WonderPopup.Add(IGEOnWonderPopup);

function IGEOnChooseReligionPopup(player, city)
	print("IGE_ChooseReligionPopup"..", player="..getstr(player)..", city="..getstr(city));
end
LuaEvents.IGE_ChooseReligionPopup.Add(IGEOnChooseReligionPopup);

function IGEOnChoosePantheonPopup(player)
	print("IGE_ChoosePantheonPopup"..", player="..getstr(player));
end
LuaEvents.IGE_ChoosePantheonPopup.Add(IGEOnChoosePantheonPopup);

function IGEOnFloatingError(text)
	print("IGE_FloatingMessage"..", text="..getstr(text));
end
LuaEvents.IGE_FloatingMessage.Add(IGEOnFloatingError)

function IGEOnResizedReseedElement(w, h)
	print("IGE_ResizedReseedElement"..", w="..getstr(w)..", h="..getstr(h));
end
LuaEvents.IGE_ResizedReseedElement.Add(IGEOnResizedReseedElement);