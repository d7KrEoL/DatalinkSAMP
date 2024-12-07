#include <a_samp>
#include "sscanf2.inc"

/*
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  This is example filterscript that shows how 
  you can interact with dlink.amx script from
  any other filterscript or gamemode
  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

public OnFilterScriptInit()
{
	print("----------------------------");
	print("|-<datalink control script example by d7.KrEoL>");
	print("|		07.12.24\n|->Web Page:https://sampmap.ru/satactics");
	print("|->Discord:https://discord.gg/QSKkNhZrTh");
	print("|->VK:https://vk.com/rusampmap");
	print("|-   -   -   -   -   -   -   -");
	print("|->/dlinkselect [playerid]");
	print("|->/dlinkmode [value]");
	print("|----------------------------");
	return 1;
}

//  In this example dlink script can be configured by any unauthorized player
public OnPlayerCommandText(playerid, cmdtext[])
{
	new cmd[16];
	if (sscanf(cmdtext, "s[16]{d}", cmd))
		return 0;
	if (!strcmp(cmd, "/dlinkselect", true))
	{
	    new value;
	    if (sscanf(cmdtext, "{s[16]}d", value))
		    value = playerid;
		    
		//  Selecting/unselecting player in dlink.amx script by sending RCON command
	    new rconCommand[17];
	    format(rconCommand, sizeof(rconCommand), "dlinkSelect %d", value);
  		SendRconCommand(rconCommand);
  		
  		new strText[27];
  		format(strText, sizeof(strText), "dlink player selected %d", value);
  		SendClientMessage(playerid, 0xFFFF00FF, strText);
  		return 1;
	}
	
	if (!strcmp(cmd, "/dlinkmode", true))
	{
	    new value;
	    if (sscanf(cmdtext, "{s[16]}d", value))
		{
		    print("dlinkController error: /dlinkMode [value]<-value not set");
		    printf("dlinkController error: wrong dlinkMode from player: %d", playerid);
		    return 0;
		}
		
		//  Configuring dlink.amx script by sending RCON command
	    new strText[17];
	    format(strText, sizeof(strText), "dlinkMode %d", value);
  		SendRconCommand(strText);
  		
  		format(strText, sizeof(strText), "dlink mode set %d", value);
  		SendClientMessage(playerid, 0xFFFF00FF, strText);
  		return 1;
	}
	return 0;
}

//  In this example player will be selected for sending when he spawns, if his name is "IAmMapPlayer"
public OnPlayerSpawn(playerid)
{
	new playerName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, playerName, sizeof(playerName));
	if (!strcmp(playerName, "IAmMapPlayer"))
	{
	    //  Selecting player in dlink.amx script by sending RCON command
		new rconCommand[22];
		format(rconCommand, sizeof(rconCommand), "dlinkForceSelect %d", playerid);
	    SendRconCommand(rconCommand);
	}
}

//  This example code will unselect dead player if his name is "IAmMapPlayer"
public OnPlayerDeath(playerid, killerid, reason)
{
    new playerName[MAX_PLAYER_NAME];
	GetPlayerName(playerid, playerName, sizeof(playerName));
	if (!strcmp(playerName, "IAmMapPlayer"))
	{
	    //  Unselecting player in dlink.amx script by sending RCON command
		new rconCommand[24];
		format(rconCommand, sizeof(rconCommand), "dlinkForceUnselect %d", playerid);
	    SendRconCommand(rconCommand);
	}
}
