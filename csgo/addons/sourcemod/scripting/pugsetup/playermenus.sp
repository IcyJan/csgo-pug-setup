public GiveSideMenu(client) {
    new Handle:menu = CreateMenu(SideMenuHandler);
    SetMenuTitle(menu, "Which side do you want first");
    SetMenuExitButton(menu, false);
    AddMenuItem(menu, "CT", "CT");
    AddMenuItem(menu, "T", "T");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public SideMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
    if (action == MenuAction_Select) {
        new hisTeam = CS_TEAM_CT;
        if (param2 == 1)  // T was option index 1 in the menu
            hisTeam = CS_TEAM_T;

        if (hisTeam == CS_TEAM_T)
            PrintToChatAll(" \x01\x0B\x07%N \x01has picked \x02T \x01first.", g_capt2);
        else
            PrintToChatAll(" \x01\x0B\x07%N \x01has picked \x03CT \x01first.", g_capt2);

        new otherTeam = CS_TEAM_T;
        if (hisTeam == CS_TEAM_T)
            otherTeam = CS_TEAM_CT;

        g_Teams[g_capt2] = hisTeam;
        SwitchPlayerTeam(g_capt2, hisTeam);
        g_Teams[g_capt1] = otherTeam;
        SwitchPlayerTeam(g_capt1, otherTeam);
        ServerCommand("mp_restartgame 1");
        CreateTimer(2.0, Timer_GivePlayerSelectionMenu, GetClientSerial(g_capt1));
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public PlayerMenuHandler(Handle:menu, MenuAction:action, param1, param2) {
    if (action == MenuAction_Select) {
        new client = param1;
        new String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        new UserID = StringToInt(info);
        new selected = GetClientOfUserId(UserID);

        if (selected > 0) {
            g_Teams[selected] = g_Teams[client];
            SwitchPlayerTeam(selected, g_Teams[client]);
            if (client == g_capt1)
                PrintToChatAll(" \x01\x0B\x06%N \x01has picked \x05%N", client, selected);
            else
                PrintToChatAll(" \x01\x0B\x07%N \x01has picked \x02%N", client, selected);

            if (!IsPickingFinished()) {
                new nextCapt = -1;
                if (client == g_capt1)
                    nextCapt = g_capt2;
                else
                    nextCapt = g_capt1;
                CreateTimer(0.5, MoreMenuPicks, GetClientSerial(nextCapt));
            } else {
                CreateTimer(1.0, FinishPicking);
            }
        } else {
            CreateTimer(0.5, MoreMenuPicks, GetClientSerial(client));
        }

    } else if (action == MenuAction_Cancel) {
        new client = param1;
        CreateTimer(0.5, MoreMenuPicks, GetClientSerial(client));
    } else if (action == MenuAction_End) {
        CloseHandle(menu);
    }
}

public bool:IsPickingFinished() {
    new numSelected = 0;
    for (new i = 1; i <= MaxClients; i++)
        if (IsPlayerPicked(i))
            numSelected++;

    return numSelected >= GetConVarInt(g_hLivePlayers);
}

public Action:MoreMenuPicks(Handle:timer, any:serial) {
    new client = GetClientFromSerial(serial);
    if (IsPickingFinished() || !IsValidClient(client) || !IsClientInGame(client)) {
        CreateTimer(5.0, FinishPicking);
        return Plugin_Handled;
    }
    GivePlayerSelectionMenu(client);
    return Plugin_Handled;
}

public Action:Timer_GivePlayerSelectionMenu(Handle:timer, any:serial) {
    GivePlayerSelectionMenu(GetClientFromSerial(serial));
}

public GivePlayerSelectionMenu(client) {
    new Handle:menu = CreateMenu(PlayerMenuHandler);
    SetMenuTitle(menu, "Pick your players");
    SetMenuExitButton(menu, false);
    AddPlayersToMenu(menu);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public AddPlayersToMenu(Handle:menu) {
    new String:user_id[12];
    new String:name[MAX_NAME_LENGTH];
    new String:display[MAX_NAME_LENGTH+15];
    new count = 0;
    for (new client = 1; client <= MaxClients; client++) {
        if (IsValidClient(client) && !IsPlayerPicked(client) && !IsFakeClient(client)) {
            IntToString(GetClientUserId(client), user_id, sizeof(user_id));
            GetClientName(client, name, sizeof(name));
            Format(display, sizeof(display), "%s", name);
            AddMenuItem(menu, user_id, display);
            count++;
        }
    }
}

static IsPlayerPicked(client) {
    new team = g_Teams[client];
    return team == CS_TEAM_T || team == CS_TEAM_CT;
}
