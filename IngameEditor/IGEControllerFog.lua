-- Released under GPL v3
-- Yes, this file is a mess. So is the fog in Civ5, full of naughty tricks. Good luck!
------------------------------------------------------------------------------------------
local IGE = nil;
local revealMap = false;
local opened = false;

-------------------------------------------------------------------------------------------------
local function RestoreFog()
	if not revealMap then return end
	print("RestoreFog")

	FOW_SetAll(1);

	-- Restore
	for i = 0, Map.GetNumPlots()-1, 1 do
		local plot = Map.GetPlotByIndex(i);
		plot:UpdateFog();
	end

	Game.UpdateFOW(true);
	UI.RequestMinimapBroadcast();
	revealMap = false
end

-------------------------------------------------------------------------------------------------
local function HideFog()
	if revealMap then return end
	print("HideFog")

	FOW_SetAll(0);
	Game.UpdateFOW(true);
	UI.RequestMinimapBroadcast();
	revealMap = true
end

-------------------------------------------------------------------------------------------------
local function Update()
	if not opened then return end
	if IGE.revealMap == revealMap then return end
	print("UpdateFog")

	if IGE.revealMap then
		HideFog()
	else
		RestoreFog()
	end
end
LuaEvents.IGE_ToggleRevealMap.Add(Update);

-------------------------------------------------------------------------------------------------
local function IGEOnSelectingPlayer(playerID, takeSeat)
	if takeSeat then
		RestoreFog()
	end
end
LuaEvents.IGE_SelectingPlayer.Add(IGEOnSelectingPlayer);

-------------------------------------------------------------------------------------------------
local function IGEOnSelectedPlayer(playerID, takeSeat)
	if takeSeat then
		Update()
	end

	local pPlayer = Players[playerID];
	local plot = pPlayer:GetStartingPlot()
	if plot then UI.LookAt(plot, 0) end
end
LuaEvents.IGE_SelectedPlayer.Add(IGEOnSelectedPlayer);

-------------------------------------------------------------------------------------------------
local function IGEOnClosing(takingSeat)
	RestoreFog()
	opened = false
end
LuaEvents.IGE_Show_Fail.Add(IGEOnClosing);
LuaEvents.IGE_Closing.Add(IGEOnClosing);

-------------------------------------------------------------------------------------------------
local function IGEOnShowing()
	opened = true
	Update();
end
LuaEvents.IGE_Showing.Add(IGEOnShowing);

-------------------------------------------------------------------------------------------------
local function IGEOnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(IGEOnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
local function ShouldBeRevealed(plot, recursivity)
	local playerID = IGE.currentPlayerID;
	if plot:GetOwner() == playerID then return true end

	local numUnits = plot:GetNumUnits();
	for i = 0, numUnits do
		local unit = plot:GetUnit(i);
		if unit and unit:GetOwner() == playerID then
			return true
		end
	end

	if recursivity > 0 then
		for neighbor in IGENeighbors(plot) do
			if ShouldBeRevealed(neighbor, recursivity - 1) then return true end
		end
	end

	return false;
end

-------------------------------------------------------------------------------------------------
local function IGEOnForceRevealMap(revealing, disableFoW)
	local currentTeamID = IGE.currentTeamID

	for i = 0, Map.GetNumPlots()-1, 1 do
		local plot = Map.GetPlotByIndex(i);
		local oldVisibility = plot:GetVisibilityCount(currentTeamID)
		local visible = ShouldBeRevealed(plot, 1)

		if oldVisibility > 0 then
			plot:ChangeVisibilityCount(currentTeamID, -oldVisibility, -1, true, true);
		end
		if visible or disableFoW then
			plot:ChangeVisibilityCount(currentTeamID, 1, -1, true, true);
		end
			
		plot:SetRevealed(currentTeamID, visible or revealing);
		plot:UpdateFog();
	end
	Game.UpdateFOW(true);
	UI.RequestMinimapBroadcast();
end
LuaEvents.IGE_ForceRevealMap.Add(IGEOnForceRevealMap);
