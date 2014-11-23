-- Released under GPL v3
--------------------------------------------------------------
include("IGEAPIAll");
print("IGE_PlayersPanel");
IGE = {};

local majorPlayerItemManager = IGECreateInstanceManager("PlayerInstance", "Button", Controls.MajorPlayersList);
local minorPlayerItemManager = IGECreateInstanceManager("PlayerInstance", "Button", Controls.MinorPlayersList);

local data = {};
local actions = nil;
local isVisible = false;
local currentActionID = 1;


--===============================================================================================
-- EVENTS
--===============================================================================================
local function IGEOnSharingGlobalAndOptions(_IGE)
	IGE = _IGE;
end
LuaEvents.IGE_SharingGlobalAndOptions.Add(IGEOnSharingGlobalAndOptions);

-------------------------------------------------------------------------------------------------
function IGEOnInitialize()
	IGESetPlayersData(data, {});

	if not IGE_HasGodsAndKings then
		Controls.FoundPantheonButton:SetHide(true);
		Controls.FoundReligionButton:SetHide(true);
		Controls.FaithContainer:SetHide(true);
		Controls.FreeTechButton:SetOffsetVal(0, 20);
	end

	IGEResize(Controls.Container);
	IGEResize(Controls.ScrollPanel);

	actions =
	{
		{ text = IGEL("TXT_KEY_IGE_MEET"),						filter = IGECanMeet,			handler = IGEMeet,				none=IGEL("TXT_KEY_IGE_MEET_NONE") },
		{ text = IGEL("TXT_KEY_IGE_FORM_TEAM"),				filter = IGECanFormTeam,		handler = IGEFormTeam,			none=IGEL("TXT_KEY_IGE_FORM_TEAM_NONE") },
		{ text = IGEL("TXT_KEY_IGE_MAKE_PEACE"),				filter = IGECanMakePeace,		handler = IGEMakePeace,		none=IGEL("TXT_KEY_IGE_MAKE_PEACE_NONE") },
		{ text = IGEL("TXT_KEY_IGE_SIGN_DOF") ,				filter = IGECanMakeDoF,		handler = IGEMakeDoF,			none=IGEL("TXT_KEY_IGE_SIGN_DOF_NONE") },
		{ text = IGEL("TXT_KEY_IGE_MAX_MINOR_INFLUENCE"),		filter = IGECanAllyMinor,		handler = IGEAllyMinor,		none=IGEL("TXT_KEY_IGE_MAX_MINOR_INFLUENCE_NONE")},
		{ text = IGEL("TXT_KEY_IGE_FLAG_STATE_LIBERATED"),		filter = IGECanFlagLiberated,	handler = IGEFlagLiberated,	none=IGEL("TXT_KEY_IGE_FLAG_STATE_LIBERATED_NONE") },
		{ text = IGEL("TXT_KEY_IGE_SET_EMBARGO"),				filter = IGECanSetEmbargo,		handler = IGESetEmbargo,		none=IGEL("TXT_KEY_IGE_TWO_SIDES_NONE") },
		{ text = IGEL("TXT_KEY_IGE_DENOUNCE"),					filter = IGECanDenounce,		handler = IGEDenounce,			none=IGEL("TXT_KEY_IGE_DENOUNCE_NONE")},
		{ text = IGEL("TXT_KEY_IGE_DENOUNCED_BY"),				filter = IGECanBeDenounced,	handler = IGEMakeDenounced,	none=IGEL("TXT_KEY_IGE_DENOUNCED_BY_NONE") },
		{ text = IGEL("TXT_KEY_IGE_DECLARE_WAR"),				filter = IGECanDeclareWar,		handler = IGEDeclareWar,		none=IGEL("TXT_KEY_IGE_TWO_SIDES_NONE") },
		{ text = IGEL("TXT_KEY_IGE_DECLARE_WAR_BY"),			filter = IGECanBeDeclaredWar,	handler = IGEMakeDeclaredWar,	none=IGEL("TXT_KEY_IGE_TWO_SIDES_NONE") },
	};

    for i, v in ipairs(actions) do
        local instance = {};
        Controls.PullDown:BuildEntry("InstanceOne", instance);
        instance.Button:SetText(v.text);
        instance.Button:SetVoid1(i);
    end
    Controls.PullDown:CalculateInternals();

	LuaEvents.IGE_RegisterTab("PLAYERS",  IGEL("TXT_KEY_IGE_PLAYERS_PANEL"), 3, "change",  "")
end
LuaEvents.IGE_Initialize.Add(IGEOnInitialize)

-------------------------------------------------------------------------------------------------
function IGEOnSelectedPanel(ID)
	isVisible = (ID == "PLAYERS");
end
LuaEvents.IGE_SelectedPanel.Add(IGEOnSelectedPanel);

-------------------------------------------------------------------------------------------------
function IGEOnPullDownSelectionChanged(ID)
	currentActionID = ID;
	IGEOnUpdate();
end
Controls.PullDown:RegisterSelectionCallback(IGEOnPullDownSelectionChanged);

-------------------------------------------------------------------------------------------------
UpdateGold = IGEHookNumericBox("Gold", 
	function() return Players[IGE.currentPlayerID]:GetGold() end, 
	function(amount) Players[IGE.currentPlayerID]:SetGold(amount) end, 
	0, nil, 100);

UpdateCulture = IGEHookNumericBox("Culture", 
	function() return Players[IGE.currentPlayerID]:GetJONSCulture() end, 
	function(amount) Players[IGE.currentPlayerID]:SetJONSCulture(amount) end, 
	0, nil, 100);

if IGE_HasGodsAndKings then
	UpdateFaith = IGEHookNumericBox("Faith", 
		function() return Players[IGE.currentPlayerID]:GetFaith() end, 
		function(amount) Players[IGE.currentPlayerID]:SetFaith(amount) end, 
		0, nil, 100);
end

--===============================================================================================
-- UPDATE
--===============================================================================================
function IGEUpdatePlayers()
	local sourceID = IGE.currentPlayerID;

	local anyMinor = false;
	local anyMajor = false;
	local action = actions[currentActionID];
	for i, v in ipairs(data.allPlayers) do
		if v.ID ~= sourceID then
			v.visible, v.enabled, v.help = action.filter(sourceID, v.ID);

			if v.isCityState then
				anyMinor = anyMinor or v.visible;
			else
				anyMajor = anyMajor or v.visible;
			end
		else
			v.visible = false;
		end
	end

	Controls.NoPlayerLabel:SetText("[COLOR_POSITIVE_TEXT]"..action.none.."[ENDCOLOR]");
	Controls.NoPlayerLabel:SetHide(anyMinor or anyMajor);
	Controls.MajorPlayersList:SetHide(not anyMajor);
	Controls.MinorPlayersList:SetHide(not anyMinor);

	table.sort(data.majorPlayers, IGEDefaultSort);
	table.sort(data.minorPlayers, IGEDefaultSort);

	local handler = action.handler
	IGEUpdateList(data.majorPlayers, majorPlayerItemManager, function(v) IGEPlayerClickHandler(handler, sourceID, v.ID) end);
	IGEUpdateList(data.minorPlayers, minorPlayerItemManager, function(v) IGEPlayerClickHandler(handler, sourceID, v.ID) end);
end

-------------------------------------------------------------------------------------------------
function IGEOnUpdate()
	Controls.Container:SetHide(not isVisible);
	if not isVisible then return end

	LuaEvents.IGE_SetMouseMode(IGE_MODE_NONE);

	-- Update controls
	local pPlayer = IGE.currentPlayer;
	UpdateGold(pPlayer:GetGold());
	UpdateCulture(pPlayer:GetJONSCulture());
	if IGE_HasGodsAndKings then
		UpdateFaith(pPlayer:GetFaith());

		-- Count beliefs to detect religion enhancement
		local beliefs = 0;
		local religionID = pPlayer:GetReligionCreatedByPlayer();
		if pPlayer:HasCreatedReligion() then
			for i,v in ipairs(Game.GetBeliefsInReligion(religionID)) do
				beliefs = beliefs + 1;
			end
		end
		local hasEnhancedReligion = (beliefs >= 5);

		local stage = 0;
		if (hasEnhancedReligion) then stage = 3;
		elseif (pPlayer:HasCreatedReligion()) then stage = 2;
		elseif (pPlayer:HasCreatedPantheon()) then stage = 1;
		end

		Controls.EnhanceReligionButton:SetDisabled(stage ~= 2);
		Controls.EnhanceReligionButton:SetHide(stage < 2);

		Controls.FoundReligionButton:SetDisabled((stage ~= 1) or (Game.GetNumReligionsStillToFound() == 0));
		Controls.FoundReligionButton:SetHide(stage ~= 1);

		Controls.FoundPantheonButton:SetDisabled(stage ~= 0);
		Controls.FoundPantheonButton:SetHide(stage ~= 0);
	end
	Controls.PullDown:GetButton():SetText(actions[currentActionID].text);
	IGEUpdatePlayers();

	-- IGEResize
	Controls.PlayersStack:CalculateSize();
	Controls.PlayersStack:ReprocessAnchoring();
	Controls.ActionsStack:CalculateSize();
	Controls.ActionsStack:ReprocessAnchoring();
	Controls.Stack:CalculateSize();
	Controls.Stack:ReprocessAnchoring();

    Controls.ScrollPanel:CalculateInternalSize();
	Controls.ScrollBar:SetSizeX(Controls.ScrollPanel:GetSizeX() - 36);
end
LuaEvents.IGE_Update.Add(IGEOnUpdate);



--===============================================================================================
-- DIPLOMATIC HANDLERS
--===============================================================================================
function IGEPlayerClickHandler(handler, sourceID, targetID)
	handler(sourceID, targetID);
	IGEOnUpdate();
end

function IGEAllClick()
	local handler = actions[currentActionID].handler;
	for i, v in ipairs(data.allPlayers) do
		if v.visible and v.enabled then
			handler(IGE.currentPlayerID, v.ID);
		end
	end
	IGEOnUpdate();
end
Controls.AllButton:RegisterCallback(Mouse.eLClick, IGEAllClick);

function IGENotifyDiplo(sourceID, targetID, type, summaryTexKey, detailsTxtKey)
	Players[sourceID]:AddNotification(type, 
		IGEL("TXT_KEY_NOTIFICATION_CITY_WLTKD", Players[targetID]:GetCivilizationDescription()),
		IGEL(summaryTexKey, Players[targetID]:GetCivilizationDescription()), nil, nil, targetID);
end

-------------------------------------------------------------------------------------------------
function IGECanMeet(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false ;
	else
		local visible = not IGEGetTeam(sourceID):IsHasMet(IGEGetTeamID(targetID));
		return visible, true;
	end
end

function IGECanFormTeam(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif IGEGetTeamID(sourceID) == IGEGetTeamID(targetID) then
		return true, false, IGEL("TXT_KEY_IGE_ALREADY_IN_TEAM_ERROR") ;
	else
		return true, true;
	end
end

function IGECanMakePeace(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif not IGEGetTeam(sourceID):IsAtWar(IGEGetTeamID(targetID)) then
		return false;
	else
		return true, true;
	end
end

function IGECanMakeDoF(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif Players[targetID]:IsMinorCiv() then 
		return false;
	elseif Players[sourceID]:IsDoF(targetID) then
		return true, false, IGEL("TXT_KEY_IGE_ALREADY_UNDER_DOF_ERROR");
	else
		return true, true;
	end
end

function IGECanAllyMinor(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif Players[sourceID]:IsMinorCiv() or not Players[targetID]:IsMinorCiv() then
		return false;
	elseif Players[targetID]:GetMinorCivFriendshipWithMajor(sourceID) >= GameDefines.FRIENDSHIP_THRESHOLD_MAX then
		return true, false, IGEL("TXT_KEY_IGE_MAX_MINOR_INFLUENCE_ERROR");
	else
		return true, true;
	end
end

function IGECanDeclareWar(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif IGEGetTeamID(sourceID) == IGEGetTeamID(targetID) then
		return true, false, IGEL("TXT_KEY_IGE_SAME_TEAM_ERROR");
	elseif IGEGetTeam(sourceID):IsAtWar(IGEGetTeamID(targetID)) then
		return true, false, IGEL("TXT_KEY_IGE_ALREADY_AT_WAR_ERROR");
	else
		return true, true;
	end
end

function IGECanBeDeclaredWar(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	else
		return IGECanDeclareWar(targetID, sourceID);
	end
end

function IGECanDenounce(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif Players[sourceID]:IsDenouncedPlayer(targetID) then
		return true, false, IGEL("TXT_KEY_IGE_ALREADY_DENOUNCED_ERROR");
	else
		return true, true;
	end
end

function IGECanBeDenounced(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif Players[targetID]:IsDenouncedPlayer(sourceID) then
		return true, false, IGEL("TXT_KEY_IGE_ALREADY_DENOUNCED_BY_ERROR");
	else
		return true, true;
	end
end

function IGECanFlagLiberated(sourceID, targetID)
	if not Players[targetID]:IsMinorCiv() then
		return false;
	else
		return true, true;
	end
end

function IGECanSetEmbargo(sourceID, targetID)
	if not Players[targetID]:IsAlive() then 
		return false;
	elseif IGEGetTeamID(sourceID) == IGEGetTeamID(targetID) then
		return true, false, IGEL("TXT_KEY_IGE_SAME_TEAM_ERROR");
	elseif IGEGetTeam(sourceID):IsAtWar(IGEGetTeamID(targetID)) then
		return true, false, IGEL("TXT_KEY_IGE_ALREADY_AT_WAR_ERROR");
	else
		return true, true;
	end
end

-------------------------------------------------------------------------------------------------
function IGEMeet(sourceID, targetID)
	IGEGetTeam(sourceID):Meet(IGEGetTeamID(targetID), false);
end

function IGEMakePeace(sourceID, targetID)
	IGEGetTeam(sourceID):MakePeace(IGEGetTeamID(targetID));
end

function IGEFormTeam(sourceID, targetID)
	IGEGetTeam(sourceID):AddTeam(IGEGetTeamID(targetID));
	IGENotifyDiplo(sourceID, targetID, NotificationTypes.NOTIFICATION_PEACE_ACTIVE_PLAYER, 
		IGEL("TXT_KEY_IGE_NOTIFY_ALLIANCE_SHORT"), IGEL("TXT_KEY_IGE_NOTIFY_ALLIANCE_LONG") );
end

function IGEMakeDoF(sourceID, targetID)
	Players[sourceID]:DoForceDoF(targetID);
	IGENotifyDiplo(sourceID, targetID, NotificationTypes.NOTIFICATION_PEACE_ACTIVE_PLAYER, 
		IGEL("TXT_KEY_IGE_NOTIFY_DOF_SHORT"), IGEL("TXT_KEY_IGE_NOTIFY_DOF_LONG"));
end

function IGEAllyMinor(sourceID, targetID)
	local offset = GameDefines.FRIENDSHIP_THRESHOLD_MAX - Players[targetID]:GetMinorCivFriendshipWithMajor(sourceID);
	if offset > 0 then
		Players[targetID]:ChangeMinorCivFriendshipWithMajor(sourceID, offset);
	end
end

function IGEDeclareWar(sourceID, targetID)
	IGEGetTeam(sourceID):DeclareWar(IGEGetTeamID(targetID));
end

function IGEMakeDeclaredWar(sourceID, targetID)
	IGEDeclareWar(targetID, sourceID);
end

function IGEDenounce(sourceID, targetID)
	Players[sourceID]:DoForceDenounce(targetID);
end

function IGEMakeDenounced(sourceID, targetID)
	IGEDenounce(targetID, sourceID);
end

function IGESetEmbargo(sourceID, targetID)
	Players[sourceID]:StopTradingWithTeam(IGEGetTeamID(targetID));
	IGENotifyDiplo(sourceID, targetID, NotificationTypes.NOTIFICATION_WAR_ACTIVE_PLAYER, IGEL("TXT_KEY_IGE_NOTIFY_EMBARGO_SHORT"), IGEL("TXT_KEY_IGE_NOTIFY_EMBARGO_LONG") );
end

function IGEFlagLiberated(sourceID, targetID)
	Players[targetID]:DoMinorLiberationByMajor(sourceID);
end


--===============================================================================================
-- REGULAR HANDLERS
--===============================================================================================
local function TriggerGoldenAge(turns)
	local pPlayer = IGE.currentPlayer;
	local currentTurns = pPlayer:GetGoldenAgeTurns();
	pPlayer:ChangeGoldenAgeTurns(turns - currentTurns);
end

-------------------------------------------------------------------------------------------------
function IGEOnGoldenAge10Click()
	TriggerGoldenAge(10);
end
Controls.GoldenAge10Button:RegisterCallback(Mouse.eLClick, IGEOnGoldenAge10Click);

-------------------------------------------------------------------------------------------------
function IGEOnGoldenAge250Click()
	TriggerGoldenAge(250);
end
Controls.GoldenAge250Button:RegisterCallback(Mouse.eLClick, IGEOnGoldenAge250Click);

-------------------------------------------------------------------------------------------------
function IGEOnTakeSeatClick()
	LuaEvents.IGE_ForceQuit(true);
end
Controls.TakeSeatButton:RegisterCallback(Mouse.eLClick, IGEOnTakeSeatClick);

-------------------------------------------------------------------------------------------------
function IGEOnUnexploreMapClick()
	LuaEvents.IGE_ForceRevealMap(false);
end
Controls.UnexploreMapButton:RegisterCallback(Mouse.eLClick, IGEOnUnexploreMapClick);

-------------------------------------------------------------------------------------------------
function IGEOnExploreMapClick()
	LuaEvents.IGE_ForceRevealMap(true, false);
end
Controls.ExploreMapButton:RegisterCallback(Mouse.eLClick, IGEOnExploreMapClick);

-------------------------------------------------------------------------------------------------
function IGEOnRevealMapClick()
	LuaEvents.IGE_ForceRevealMap(true, true);
end
Controls.RevealMapButton:RegisterCallback(Mouse.eLClick, IGEOnRevealMapClick);

-------------------------------------------------------------------------------------------------
function IGEOnKillUnitsClick()
	IGE.currentPlayer:KillUnits();
end
Controls.KillUnitsButton:RegisterCallback(Mouse.eLClick, IGEOnKillUnitsClick);

-------------------------------------------------------------------------------------------------
function IGEOnKillClick()
	local i = 0;
	while i == IGE.currentPlayerID or Players[i] == nil or not Players[i]:IsAlive() do
		i = i + 1;
	end

	local pPlayer = IGE.currentPlayer;
	LuaEvents.IGE_SelectPlayer(i);
	pPlayer:KillUnits();
	pPlayer:KillCities();
end
Controls.KillButton:RegisterCallback(Mouse.eLClick, IGEOnKillClick);

-------------------------------------------------------------------------------------------------
function IGEOnFreeTechClick()
	IGE.currentPlayer:SetNumFreeTechs(IGE.currentPlayer:GetNumFreeTechs() + 1);
	IGE.currentPlayer:AddNotification(NotificationTypes.NOTIFICATION_FREE_TECH, IGEL("TXT_KEY_IGE_FREE_TECH_BUTTON"), IGEL("TXT_KEY_IGE_FREE_TECH_BUTTON_HELP") );
	IGEOnUpdate();
end
Controls.FreeTechButton:RegisterCallback(Mouse.eLClick, IGEOnFreeTechClick);


-------------------------------------------------------------------------------------------------
function IGEOnFreePolicyClick()
	IGE.currentPlayer:SetNumFreePolicies(IGE.currentPlayer:GetNumFreePolicies() + 1);
	IGE.currentPlayer:AddNotification(NotificationTypes.NOTIFICATION_FREE_POLICY, IGEL("TXT_KEY_IGE_FREE_POLICY_BUTTON"), IGEL("TXT_KEY_IGE_FREE_POLICY_BUTTON_HELP"));
	IGEOnUpdate();
end
Controls.FreePolicyButton:RegisterCallback(Mouse.eLClick, IGEOnFreePolicyClick);

-------------------------------------------------------------------------------------------------
function IGEOnFoundPantheonClick()
	LuaEvents.IGE_ChoosePantheonPopup(IGE.currentPlayer);
end
Controls.FoundPantheonButton:RegisterCallback(Mouse.eLClick, IGEOnFoundPantheonClick);

-------------------------------------------------------------------------------------------------
function IGEOnFoundReligionClick()
	local capital = IGE.currentPlayer:GetCapitalCity();
	LuaEvents.IGE_ChooseReligionPopup(IGE.currentPlayer, capital, true);
end
Controls.FoundReligionButton:RegisterCallback(Mouse.eLClick, IGEOnFoundReligionClick);

-------------------------------------------------------------------------------------------------
function IGEOnEnhanceReligionClick()
	local capital = IGE.currentPlayer:GetCapitalCity();
	LuaEvents.IGE_ChooseReligionPopup(IGE.currentPlayer, capital, false);
end
Controls.EnhanceReligionButton:RegisterCallback(Mouse.eLClick, IGEOnEnhanceReligionClick);

-------------------------------------------------------------------------------------------------
function IGEOnNotificationAdded( Id, type, toolTip, strSummary, iGameValue, iExtraGameData )
	IGEOnUpdate();
end
Events.NotificationAdded.Add(IGEOnNotificationAdded);
