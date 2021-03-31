//
// Copyright (C) 2021 Oliver "c0rp3n" Hitchcock.
//

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <jumpstats>

public void OnPluginStart()
{
    int client = 0;
    JumpStats_InterruptJump(client);
    JumpStats_ClientUntrack(client);
    JumpStats_ClientTrack(client);
    JumpStats_ClientIsTracked(client);
}

public void JumpStats_OnJump(int client, JumpType type, float distance)
{
}
