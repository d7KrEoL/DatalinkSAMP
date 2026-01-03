#include <a_samp>
#include <a_players>

#include "sscanf2.inc"
#include "requests.inc"

#define TRANSMIT_MESSAGES_DELAY 100 //  Deley between each player's data transmit
#define SPEED_VECTOR_MULTIPLIER 50  //  Multiply speed vector to get real player's speed value
#define ENEMY_TEAM_DELIM 2  //  Players that is in team with number below this value will be sent as enemies, others - as allies

//  Send single enemy player data
forward sendEnemy(room[], name[], type, Float:posX, Float:posY, Float:posZ, Float:vecX, Float:vecY, Float:vecZ);
//  Send single ally player data
forward sendAlly(room[], name[], type, Float:posX, Float:posY, Float:posZ, Float:vecX, Float:vecY, Float:vecZ);
//  Send single player data with delay
forward autoSendPlayer(playerid);
//  Send all selected by rule players (rule depends of script working mode)
forward OnDatalinkUpdate();
//  Send all players that is online and spawned
forward OnDatalinkUpdateAll();
//  Send all players that is selected, online and spawned
forward OnDatalinkUpdateSelected();

new dlinkHost[64];  //  Remote datalink host url
new dlinkPort[5];   //  Remote datalink host port
new dlinkRoom[64];  //  Room to send data
new dlinkMode;  //  Working mode (0-N)
new dlinkSelected[MAX_PLAYERS]; //	Array of selected players for working mode 1
new dlinkActive = true; //  Enable/disable data transmission

public OnFilterScriptInit()
{
	print("----------------------------\n|-[datalink script by d7.KrEoL loaded]");
	print("|		07.12.24\n|->Web Page:https://sampmap.ru/satactics");
	print("|->Discord:https://discord.gg/QSKkNhZrTh");
	print("|->VK:https://vk.com/rusampmap\n----------------------------");
	
	
	format(dlinkHost, sizeof(dlinkHost), "datalink.sampmap.ru");	//	Default host url
	format(dlinkPort, sizeof(dlinkPort), "443");	//	Default host port
	format(dlinkRoom, sizeof(dlinkRoom), "MainServer"); //  Default room name
	TestConnection();
	
	new funcName[17];
	format(funcName, sizeof(funcName), "OnDatalinkUpdate");
	SetTimer(funcName, 3000, true);
	return 1;
}

public OnFilterScriptExit()
{
	print("\n--dlink Test Unloaded.\n------------------");
	return 1;
}

public OnDatalinkUpdate()
{
	if (!dlinkActive) return;
	switch(dlinkMode)
	{
	    case 0:
	        OnDatalinkUpdateAll();
	    case 1:
	        OnDatalinkUpdateSelected();
	}
}


public OnDatalinkUpdateAll()
{
    new delay = 0;
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
	    if (!IsPlayerConnected(i)) continue;
	    if (!IsPlayerSpawned(i)) continue;
	    delay += TRANSMIT_MESSAGES_DELAY;
	    new funcName[15];
	    format(funcName, sizeof(funcName), "autoSendPlayer");
	    SetTimerEx(funcName, delay, false, "d", i);
	}
}

public OnDatalinkUpdateSelected()
{
	new delay = 0;
	for (new i = 0; i < MAX_PLAYERS; i++)
	{
	    if (dlinkSelected[i] == 0) continue;
	    if (!IsPlayerConnected(i))
	    {
	        dlinkSelected[i] = false;
	        continue;
	    }
	    if (!IsPlayerSpawned(i)) continue;
	    delay += TRANSMIT_MESSAGES_DELAY;
	    new funcName[15];
	    format(funcName, sizeof(funcName), "autoSendPlayer");
	    SetTimerEx(funcName, delay, false, "d", i);
	}
}

public OnRconCommand(cmd[])
{
    if (!strcmp(cmd, "dlinkHelp", true) || !strcmp(cmd, "dlinkhelp", true) || !strcmp(cmd, "datalink", true) || !strcmp(cmd, "dlink", true))
	{
	    HelpMessage();
	    return 1;
	}
	if (!strcmp(cmd, "dlinkActive"))
	{
	    dlinkActive = !dlinkActive;
	    if (dlinkActive)
	    	TestConnection();
	    return 1;
	}
	new command[32];
	new extra[64];
	if (sscanf(cmd, "s[32]s[64]", command, extra)) return 0;
	if (!strcmp(command, "dlinkHost", true))
	{
	    format(dlinkHost, sizeof(dlinkHost), "%s", extra);
	    printf("Datalink host changed to: https://%s:%s/", dlinkHost, dlinkPort);
	    return 1;
	}
	if (!strcmp(command, "dlinkPort", true))
	{
	    format(dlinkPort, sizeof(dlinkPort), "%s", extra);
	    printf("Datalink host changed to: https://%s:%s/", dlinkHost, dlinkPort);
	    return 1;
	}
	if (!strcmp(command, "dlinkRoom", true))
	{
	    format(dlinkRoom, sizeof(dlinkRoom), "%s", extra);
	    printf("Datalink room changed to: %s", dlinkRoom);
	    return 1;
	}
	if (!strcmp(command, "dlinkMode", true))
	{
		new mode;
		if (sscanf(extra, "d", mode))
		{
	 		print("Usage: dlinkMode [(int)modeValue]");
	 	}
		dlinkMode = mode;
	 	printf("Datalink working mode is now set to: %d", dlinkMode);
	 	return 1;
	}
	if (!strcmp(command, "dlinkSelect", true))
	{
	    if (dlinkMode != 1)
	    {
	        printf("Datalink error: cannot select player. Wrong script working mode (%d)", dlinkMode);
	        return 1;
	    }
	    new playerid;
	    if (sscanf(extra, "d", playerid))
		{
			 print("Usage: dlinkSelect [(int)playerID]");
			 return 1;
	 	}
	    if(!IsPlayerConnected(playerid))
	    {
	        printf("Datalink error: player %d is not connected", playerid);
	        return 1;
	    }
	    dlinkSelected[playerid] = !dlinkSelected[playerid];
	    printf("Datalink player %d %s", playerid, dlinkSelected[playerid]? "selected" : "unselected");
	    return 1;
	}
	if (!strcmp(command, "dlinkForceSelect", true))
	{
	    if (dlinkMode != 1)
	    {
	        printf("Datalink error: cannot select player. Wrong script working mode (%d)", dlinkMode);
	        return 1;
	    }
	    new playerid;
	    if (sscanf(extra, "d", playerid))
		{
			 print("Usage: dlinkSelect [(int)playerID]");
			 return 1;
	 	}
	    if(!IsPlayerConnected(playerid))
	    {
	        printf("Datalink error: player %d is not connected", playerid);
	        return 1;
	    }
	    dlinkSelected[playerid] = true;
	    printf("Datalink player %d selected", playerid);
	    return 1;
	}
	if (!strcmp(command, "dlinkForceUnselect", true))
	{
	    if (dlinkMode != 1)
	    {
	        printf("Datalink error: cannot select player. Wrong script working mode (%d)", dlinkMode);
	        return 1;
	    }
	    new playerid;
	    if (sscanf(extra, "d", playerid))
		{
			 print("Usage: dlinkSelect [(int)playerID]");
			 return 1;
	 	}
	    if(!IsPlayerConnected(playerid))
	    {
	        printf("Datalink error: player %d is not connected", playerid);
	        return 1;
	    }
	    dlinkSelected[playerid] = false;
	    printf("Datalink player %d unselected", playerid);
	    return 1;
	}
	return 0;
}

public autoSendPlayer(playerid)
{
	new playerName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, playerName, sizeof(playerName));
	
	new Float:posX, Float:posY, Float:posZ;
	GetPlayerPos(playerid, posX, posY, posZ);
	
	new Float:vecX, Float:vecY, Float:vecZ;
	if (IsPlayerInAnyVehicle(playerid))
	{
		new vehicleid = GetPlayerVehicleID(playerid);
		new isDone = GetVehicleVelocity(vehicleid, vecX, vecY, vecZ);
		if (!isDone) return;
	}
	else
	{
	    GetPlayerVelocity(playerid, vecX, vecY, vecZ);
	}
	vecX = posX + (vecX * SPEED_VECTOR_MULTIPLIER);
	vecY = posY + (vecY * SPEED_VECTOR_MULTIPLIER);
	vecZ = posZ + (vecZ * SPEED_VECTOR_MULTIPLIER);
	
	for (new i = 0; i < sizeof(playerName); i++)
	{
		if(playerName[i] == '[')
		    playerName[i] = '(';
		else if (playerName[i] == ']')
		    playerName[i] = ')';
	}
	if (GetPlayerTeam(playerid) < ENEMY_TEAM_DELIM)
	    sendEnemy(dlinkRoom, playerName, 1, posX, posY, posZ, vecX, vecY, vecZ);
	else
	    sendAlly(dlinkRoom, playerName, 1, posX, posY, posZ, vecX, vecY, vecZ);
	return;
}

public sendEnemy(room[], name[], type, Float:posX, Float:posY, Float:posZ, Float:vecX, Float:vecY, Float:vecZ)
{
	new req[2048];
	format(
		req,
		sizeof(req),
		"https://%s:%s/tacxenemy?room=%s&name=%s&objectType=%d&posX=%.2f&posY=%.2f&posZ=%.2f&vecX=%.2f&vecY=%.2f&vecZ=%.2f",
		dlinkHost,
		dlinkPort,
		room,
		name,
		type,
		posX,
		posY,
		posZ,
		vecX,
		vecY,
		vecZ
	);
	new RequestsClient:https = RequestsClient(req);
	Request(
	    https,
	    "",
	    HTTP_METHOD_GET,
	    "@OnSendEnemyResult"
	);
}

//  When get request result received
@OnSendEnemyResult(Request:id, E_HTTP_STATUS:status, data[], dataLen);
@OnSendEnemyResult(Request:id, E_HTTP_STATUS:status, data[], dataLen)
{
	if (strcmp(data, "true", true, dataLen))
	    printf("Cannot send enemy:\n%s\nLen:%d", data, dataLen);
}

//  When failed to send any request
forward OnRequestFailure(Request:id, errorCode, errorMessage[], len);
public OnRequestFailure(Request:id, errorCode, errorMessage[], len)
{
	new message[256];
	format(message, sizeof(message), "\n[!]Datalink send request error:\nError code: %d", errorCode);
	switch (errorCode)
	{
		case 1:
		{
		    format(message, sizeof(message), "%s (Cannot connect)", message);
		}
		default:
		{
		    format(message, sizeof(message), "%s (Unexpected exception)", message);
		}
	}
	format(message, sizeof(message), "%s\nError message (UTF-8): %s\n", message, errorMessage);
	print(message);
	print("\nScript will now be deactivated.\nTo make it active again use RCON command: dlinkActive\n");
}

public sendAlly(room[], name[], type, Float:posX, Float:posY, Float:posZ, Float:vecX, Float:vecY, Float:vecZ)
{
    new req[2048];
	format(
		req,
		sizeof(req),
		"https://%s:%s/tacxally?room=%s&name=%s&objectType=%d&posX=%.2f&posY=%.2f&posZ=%.2f&vecX=%.2f&vecY=%.2f&vecZ=%.2f",
		dlinkHost,
		dlinkPort,
		room,
		name,
		type,
		posX,
		posY,
		posZ,
		vecX,
		vecY,
		vecZ
	);
	new RequestsClient:https = RequestsClient(req);
	Request(
	    https,
	    "",
	    HTTP_METHOD_GET,
	    "@OnSendAllyResult"
	);
}

//  When get request result received
@OnSendAllyResult(Request:id, E_HTTP_STATUS:status, data[], dataLen);
@OnSendAllyResult(Request:id, E_HTTP_STATUS:status, data[], dataLen)
{
	if (strcmp(data, "true", true, dataLen))
	    printf("Cannot send ally:\n%s\nLen: %d", data, dataLen);
}

//  Checks connection to remote host
stock TestConnection()
{
	dlinkMode = 0;

	new name[24];
	format(name, sizeof(name), "SampServerConnected");
	sendEnemy(dlinkRoom, name, 1, 1024.23423, 2048.32423, 50, 1048.43432, 2091.4324454, 50);
	format(name, sizeof(name), "SampServerConnected");
	sendAlly(dlinkRoom, name, 1, 2048, 1024, 100, 2091, 1048, 100);
}

//  Prints help message to RCON console
stock HelpMessage()
{
    print("-------------------------------\nDatalink commands:\n\n");
    print("-------------------");
    print("/dlinkHost [IP/URL] - set current datalink host server IP/URL\nDefault:\"dlink.sampmap.ru\"");
    print("-------------------");
    print("/dlinkPort [PORT] - set current datalink host server PORT\nDefault:\"80\"");
    print("-------------------");
    print("/dlinkRoom [NAME] - set current datalink room\nDefault:\"MainServer\"");
    print("-------------------");
    print("/dlinkMode [VALUE] - set datalink working mode\nDefault:\"0\"\n-	-	-	-\nWorking modes:\n0 - Normal (transmit all players)\n1 - Selectable (only selected players will be transmited)");
    print("-------------------");
	print("/dlinkSelect [PLAYERID] - select/unselect player to be transmitted to datalink map (only in working mode \"1\")");
	print("-------------------");
	print("/dlinkForceSelect [PLAYERID] - select player to be transmitted to datalink map (only in working mode \"1\")");
	print("-------------------");
	print("/dlinkForceUnselect [PLAYERID] - unselect player to be transmitted to datalink map (only in working mode \"1\")");
	print("-------------------");
	print("/dlinkActive - activate/deactivate script");
    print("-------------------------------\n");
}

//  Checks if player game state is 'spawned'
stock IsPlayerSpawned(playerid)
{
	new pState = GetPlayerState(playerid);

	return 0 <= playerid <= MAX_PLAYERS && pState != PLAYER_STATE_NONE && pState != PLAYER_STATE_WASTED && pState != PLAYER_STATE_SPECTATING;
}
