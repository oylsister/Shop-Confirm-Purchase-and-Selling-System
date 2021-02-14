#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <multicolors>
#include <shop>

#pragma newdecls required

int g_iClientMaxTime[MAXPLAYERS+64];
bool g_bClientAllowed[MAXPLAYERS+64];

int g_iConfirmTime;
bool g_bEnabledConfirm;

ConVar g_CvarEnableConfirm;
ConVar g_CvarTimeConfirm;

public Plugin myinfo =
{
	name = "[Shop] Confirm System",
	description = "Forcing client to type !accept before purchase or sell item on shop.",
	author = "Oylsister",
	version = "1.0",
	url = "https://github.com/oylsister/Shop-Confirm-Purchase-and-Selling-System"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_accept", Command_Confirm);
	RegAdminCmd("sm_enableaccept", Toggle_Confirm, ADMFLAG_ROOT);

	g_CvarEnableConfirm = CreateConVar("sm_shop_confirm_enable", "1.0", "Enable Confirm System before", _, true, 0.0, true, 1.0);
	g_CvarTimeConfirm = CreateConVar("sm_shop_confirm_time", "10.0", "How many second that player will be allowed to purchase or sell after type !accept command?", _, true, 1.0, false);

	HookConVarChange(g_CvarEnableConfirm, Cvar_Enable_Confirm);
	HookConVarChange(g_CvarTimeConfirm, Cvar_Time_Confirm);
}

public void Cvar_Enable_Confirm(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabledConfirm = GetConVarBool(convar);
}

public void Cvar_Time_Confirm(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iConfirmTime = GetConVarInt(convar);
}

public Action Toggle_Confirm(int client, int args)
{
	if(g_bEnabledConfirm == true)
	{
		g_bEnabledConfirm = false;
		CPrintToChatAll("{green}[Shop] {default}Purchase Confirm System is currently {red}Disabled.");
	}
	else
	{
		g_bEnabledConfirm = true;
		CPrintToChatAll("{green}[Shop] {default}Purchase Confirm System is currently {lightgreen}Enabled.");
	}
}

public Action Command_Confirm(int client, int args)
{
	int CurrentTime = GetTime();

	if(g_bEnabledConfirm == false)
		return Plugin_Continue;

	else
	{
		if(g_bClientAllowed[client] == true)
		{
			CReplyToCommand(client, "{green}[Shop]{default} You already activated confirm mode. Purchase or sell item before end in {lightgreen}%d", g_iClientMaxTime[client] - CurrentTime);
			return Plugin_Continue;
		}
		else
		{
			g_iClientMaxTime[client] = CurrentTime + g_iConfirmTime;
			if(g_iClientMaxTime[client] > CurrentTime)
			{
				g_bClientAllowed[client] = true;
				CreateTimer(1.0, Check_TimeLeft, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				g_bClientAllowed[client] = false;
				return Plugin_Handled;
			}
		}
		return Plugin_Continue;
	}
}

public Action Check_TimeLeft(Handle hTimer, any client)
{
	int CurrentTime = GetTime();

	if(g_iClientMaxTime[client] > CurrentTime)
	{
		g_bClientAllowed[client] = true;
		CPrintToChat(client, "{green}[Shop]{default} You have {lightgreen}%d {default}before you need to type {red}!accept {default}to confirm the purchase again.", g_iClientMaxTime[client] - CurrentTime);
		return Plugin_Continue;
	}
	else if(g_iClientMaxTime[client] < CurrentTime)
	{
		g_bClientAllowed[client] = false;
		CPrintToChat(client, "{green}[Shop]{default} Type {red}!accept {default}to confirm purchase again.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Shop_OnItemBuy(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int &price, int &sell_price, int &value, int &gold_price, int &gold_sell_price)
{
	if(g_bClientAllowed[client] == false)
	{
		CPrintToChat(client, "{green}[Shop]{default} Type {red}!accept {default}to confirm the purchase or selling item.");
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;
}

public Action Shop_OnItemSell(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ItemType type, int &sell_price, int &gold_sell_price)
{
	if(g_bClientAllowed[client] == false)
	{
		CPrintToChat(client, "{green}[Shop]{default} Type {red}!accept {default}to confirm the purchase or selling item.");
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;
}
