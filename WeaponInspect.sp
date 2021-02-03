#include <sourcemod>
#include <cstrike>
#include <eitems>
#include <sdkhooks>
//#include <clientprefs>

bool isInspect[MAXPLAYERS + 1] = false;
bool isSwitch[MAXPLAYERS + 1] = false;

public Plugin myinfo = 
{
	name = "another WeaponInspect",
	description = "change csgo WeaponInspect",
	author = "宇宙遨游",
	version = "0.1",
	url = "https://www.wssr.top/"
}; 

public void OnPluginStart()
{
	RegConsoleCmd("sm_inspect", CommandInspect);
	
	HookEvent("inspect_weapon", Event_OnWeaponInspect);
}

public Action CommandInspect(int client, int args)
{
	if (!IsValidClient(client))return Plugin_Continue;
	yzCreateMenu(client).Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

Menu yzCreateMenu(int client)
{
	Menu m = CreateMenu(InspectHandler);
	m.SetTitle("武器动作")
	m.ExitButton = true;
	char itemTitle[255];
	Format(itemTitle, sizeof(itemTitle), "稀有武器动作[%s]",isInspect[client]?"锁定":"解锁");
	m.AddItem("inspect", itemTitle);
	Format(itemTitle, sizeof(itemTitle), "稀有切换动作[%s]",isSwitch[client]?"锁定":"解锁");
	m.AddItem("switch", itemTitle);
	return m;
}

public int InspectHandler(Menu menu, MenuAction action, int client, int param)
{
	if (!IsValidClient(client))return;
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!param)isInspect[client] = !isInspect[client];
			else isSwitch[client] = !isSwitch[client];
			delete menu;
			yzCreateMenu(client).Display(client, MENU_TIME_FOREVER);
		}
		case MenuAction_End:delete menu;
	}
}

public void OnClientPostAdminCheck(int client)
{
	//if (!IsValidClient(client))return;
	//todo cookie
	isInspect[client] = false;
	isSwitch[client] = false;
	SDKHook(client, SDKHook_WeaponCanSwitchTo, setInvSequence);
}


public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponCanSwitchTo, setInvSequence);
}


public Action setInvSequence(int client,int weapon)
{
	if (IsValidClient(client) && isSwitch[client])
	{
		int iWeaponDefIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(eItems_HasRareDrawByDefIndex(iWeaponDefIndex))
		{
			int iPredictedViewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
			if (IsValidEntity(iPredictedViewModel))
			{
				DataPack data = new DataPack();
				data.WriteCell(iPredictedViewModel);
				data.WriteCell(iWeaponDefIndex);
				RequestFrame(Frame_Switch, data);
			}
		}
	}
}

void Frame_Switch(DataPack data)
{
	data.Reset();
	int iPredictedViewModel = data.ReadCell();
	int iWeaponDefIndex = data.ReadCell();
	SetEntProp(iPredictedViewModel, Prop_Send, "m_nSequence", eItems_GetRareDrawSequenceByDefIndex(iWeaponDefIndex));
	CloneHandle(data);
}

public Action Event_OnWeaponInspect(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && isInspect[client])
	{
		int iWeaponDefIndex = eItems_GetActiveWeaponDefIndex(client);
		
		if (eItems_HasRareInspectByDefIndex(iWeaponDefIndex))
		{
			int iPredictedViewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
			
			if (IsValidEntity(iPredictedViewModel))
			{
				DataPack data = new DataPack();
				data.WriteCell(iPredictedViewModel);
				data.WriteCell(iWeaponDefIndex);
				RequestFrame(Frame_Inspect, data);
			}
		}
	}
}

public void Frame_Inspect(DataPack data)
{
	data.Reset();
	int iPredictedViewModel = data.ReadCell();
	int iWeaponDefIndex = data.ReadCell();
	
	SetEntProp(iPredictedViewModel, Prop_Send, "m_nSequence", eItems_GetRareInspectSequenceByDefIndex(iWeaponDefIndex));
	CloseHandle(data);
}

bool IsValidClient(client)
{
	if (client < 1 || client > MaxClients)return false;
	if(IsFakeClient(client))return false;
	if(IsClientConnected(client) && IsClientInGame(client))return true;
	return false;
}



