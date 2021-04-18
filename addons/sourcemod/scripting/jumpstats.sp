/* Special thanks to DocG, Delusional and wen for testing */
/* Credits to hleV for sharing the Unreal Tournament sounds: https://forums.alliedmods.net/showthread.php?t=87869 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <mapchooser>
#define REQUIRE_PLUGIN
#include <jumpstats>
#include <colorlib>

#pragma semicolon 1
#pragma newdecls required

// Change DISABLE_SOUNDS to true in order to disable the announcer sounds and prevent them from downloading to players
bool DISABLE_SOUNDS = false;

// ConVar Defines
#define PLUGIN_VERSION              "0.4.0"
#define STATS_ENABLED               "1"
#define DISPLAY_ENABLED             "3"
#define DISPLAY_DELAY_ROUNDSTART    "0"
#define BUNNY_HOP_CANCELS_ANNOUNCER "1"
#define MINIMUM_ANNOUNCE_TIER       "Impressive"
#define ANNOUNCE_TO_TEAMS           "4"
#define RECORD_FOR_TEAMS            "3"
#define ANNOUNCER_SOUNDS            "1"

// Don't play with this
#define BHOP_TIME                   0.1

// Variables Temporality
#define CURRENT                     0
#define LAST                        1

// Position Tendencies
#define DESCENDING                  -1
#define STABLE                      0
#define ASCENDING                   1

// Jump Types
#define JUMP_INVALID                -3
#define JUMP_VERTICAL               -2
#define JUMP_TOO_SHORT              -1
#define JUMP_NONE                   0

#define VALID_JUMP_TYPES            7
#define JUMP_LJ                     1
#define JUMP_BHJ                    2
#define JUMP_MBHJ                   3
#define JUMP_LADJ                   4
#define JUMP_WHJ                    5
#define JUMP_LDHJ                   6
#define JUMP_LBHJ                   7

// Jump Contexts
#define NONE                        0
#define JUMPED                      1
#define DROPPED                     2
#define LADDER_UNKNOWN              3
#define LADDER_DROPPED              4
#define LADDER_JUMPED               5

// Client Flag
#define JUST_LANDED                 2
#define ON_LAND                     1
#define IN_AIR                      0
#define JUST_AIRED                  -1

// Jump Tiers
#define IMPRESSIVE                  0
#define EXCELLENT                   1
#define OUTSTANDING                 2
#define UNREAL                      3
#define GODLIKE                     4

// Jump Tier Distances by Type
#define MINIMUM_LJ_DISTANCE         200.0
#define LJ_IMPRESSIVE               "228.0"
#define LJ_EXCELLENT                "234.0"
#define LJ_OUTSTANDING              "240.0"
#define LJ_UNREAL                   "246.0"
#define LJ_GODLIKE                  "252.0"

#define MINIMUM_BHJ_DISTANCE        200.0
#define BHJ_IMPRESSIVE              "248.0"
#define BHJ_EXCELLENT               "256.0"
#define BHJ_OUTSTANDING             "262.0"
#define BHJ_UNREAL                  "270.0"
#define BHJ_GODLIKE                 "278.0"

#define MINIMUM_MBHJ_DISTANCE       200.0
#define MBHJ_IMPRESSIVE             "248.0"
#define MBHJ_EXCELLENT              "256.0"
#define MBHJ_OUTSTANDING            "262.0"
#define MBHJ_UNREAL                 "270.0"
#define MBHJ_GODLIKE                "278.0"

#define MINIMUM_LADJ_DISTANCE       125.0
#define LADJ_IMPRESSIVE             "150.0"
#define LADJ_EXCELLENT              "158.0"
#define LADJ_OUTSTANDING            "166.0"
#define LADJ_UNREAL                 "174.0"
#define LADJ_GODLIKE                "182.0"

#define MINIMUM_WHJ_DISTANCE        200.0
#define WHJ_IMPRESSIVE              "240.0"
#define WHJ_EXCELLENT               "248.0"
#define WHJ_OUTSTANDING             "254.0"
#define WHJ_UNREAL                  "262.0"
#define WHJ_GODLIKE                 "270.0"

#define MINIMUM_LDHJ_DISTANCE        200.0
#define LDHJ_IMPRESSIVE              "240.0"
#define LDHJ_EXCELLENT               "248.0"
#define LDHJ_OUTSTANDING             "254.0"
#define LDHJ_UNREAL                  "262.0"
#define LDHJ_GODLIKE                 "270.0"

#define MINIMUM_LBHJ_DISTANCE        200.0
#define LBHJ_IMPRESSIVE              "236.0"
#define LBHJ_EXCELLENT               "244.0"
#define LBHJ_OUTSTANDING             "250.0"
#define LBHJ_UNREAL                  "258.0"
#define LBHJ_GODLIKE                 "266.0"

// Jump Tier Sound Paths
char g_saJumpSoundPaths[][] =
{
    "jumpstats/impressive.mp3",
    "jumpstats/excellent.mp3",
    "jumpstats/outstanding.mp3",
    "jumpstats/unreal.mp3",
    "jumpstats/godlike.mp3"
};

// Jump Tier Color
#define IMPRESSIVE_COLOR             "{bluegrey}"
#define EXCELLENT_COLOR              "{blue}"
#define OUTSTANDING_COLOR            "{darkblue}"
#define UNREAL_COLOR                 "{purple}"
#define GODLIKE_COLOR                "{red}"

//Spec Defines
#define REFRESH_RATE                0.1
#define SPECMODE_NONE               0
#define SPECMODE_FIRSTPERSON        4
#define SPECMODE_3RDPERSON          5
#define SPECMODE_FREELOOK           6
#define MOUSE_LEFT                  (1 << 0)
#define MOUSE_RIGHT                 (1 << 1)
#if defined FL_INWATER
    #undef FL_INWATER
#endif
#define FL_INWATER                  (1 << 10)

// In-game Team Defines
#define JOINTEAM_RND       0
#define JOINTEAM_SPEC      1
#define JOINTEAM_T         2
#define JOINTEAM_CT        3

public Plugin myinfo =
{
    name        = "Jump Stats",
    author      = "ceLoFaN, c0rp3n",
    description = "Jump Stats for CS:GO",
    version     = PLUGIN_VERSION,
    url         = "steamcommunity.com/id/celofan"
};

/*\----ConVars----------------------------------------\*/
ConVar g_hEnabled;
ConVar g_hDisplayEnabled;
ConVar g_hDisplayDelayRoundstart;
ConVar g_hBunnyHopCancelsAnnouncer;
ConVar g_hMinimumAnnounceTier;
ConVar g_hAnnounceToTeams;
ConVar g_hRecordForTeams;
ConVar g_hAnnouncerSounds;

ConVar g_hLJImpressive;
ConVar g_hLJExcellent;
ConVar g_hLJOutstanding;
ConVar g_hLJUnreal;
ConVar g_hLJGodlike;

ConVar g_hBHJImpressive;
ConVar g_hBHJExcellent;
ConVar g_hBHJOutstanding;
ConVar g_hBHJUnreal;
ConVar g_hBHJGodlike;

ConVar g_hMBHJImpressive;
ConVar g_hMBHJExcellent;
ConVar g_hMBHJOutstanding;
ConVar g_hMBHJUnreal;
ConVar g_hMBHJGodlike;

ConVar g_hLadJImpressive;
ConVar g_hLadJExcellent;
ConVar g_hLadJOutstanding;
ConVar g_hLadJUnreal;
ConVar g_hLadJGodlike;

ConVar g_hWHJImpressive;
ConVar g_hWHJExcellent;
ConVar g_hWHJOutstanding;
ConVar g_hWHJUnreal;
ConVar g_hWHJGodlike;

ConVar g_hLDHJImpressive;
ConVar g_hLDHJExcellent;
ConVar g_hLDHJOutstanding;
ConVar g_hLDHJUnreal;
ConVar g_hLDHJGodlike;

ConVar g_hLBHJImpressive;
ConVar g_hLBHJExcellent;
ConVar g_hLBHJOutstanding;
ConVar g_hLBHJUnreal;
ConVar g_hLBHJGodlike;

ConVar g_hImpressiveColor;
ConVar g_hExcellentColor;
ConVar g_hOutstandingColor;
ConVar g_hUnrealColor;
ConVar g_hGodlikeColor;

bool g_bEnabled;
int g_iDisplayEnabled;
float g_fDisplayDelayRoundstart;
bool g_bBunnyHopCancelsAnnouncer;
int g_iMinimumAnnounceTier;
int g_iAnnounceToTeams;
int g_iRecordForTeams;
int g_iAnnouncerSounds;

float g_faQualityDistances[VALID_JUMP_TYPES + 1][5];
char g_saQualityColor[5][32];
/*-----------------------------------------------------*/

//cookies
Handle g_hToggleStatsCookie;
Handle g_hToggleAnnouncerSoundsCookie;

//stats
Handle g_hDisplayTimer;
Handle g_hInitialDisplayTimer;
bool g_baStats[MAXPLAYERS + 1] = {true, ...};
bool g_baAnnouncerSounds[MAXPLAYERS + 1] = {true, ...};
int g_iaJumped[MAXPLAYERS + 1] = {JUMP_NONE, ...};
int g_iaJumpContext[MAXPLAYERS + 1] = {0, ...};
bool g_baCanJump[MAXPLAYERS + 1] = {true, ...};
bool g_baJustHopped[MAXPLAYERS + 1] = {false, ...};
bool g_baCanBhop[MAXPLAYERS + 1] = {false, ...};
bool g_baCanDuck[MAXPLAYERS + 1] = {true, ...};
bool g_baAntiJump[MAXPLAYERS + 1] = {true, ...};
bool g_baOnLadder[MAXPLAYERS + 1] = {false, ...};
bool g_baAnnounceLastJump[MAXPLAYERS + 1] = {false, ...};
float g_faJumpCoord[MAXPLAYERS + 1][3];
float g_faLandCoord[MAXPLAYERS + 1][3];
float g_faDistance[MAXPLAYERS + 1] = {0.0, ...};
float g_faLastDistance[MAXPLAYERS + 1] = {0.0, ...};
int g_iaBhops[MAXPLAYERS + 1] = {0, ...};
int g_iaStatus[MAXPLAYERS + 1] = {0, ...};
int g_iaFrame[MAXPLAYERS + 1] = {0, ...};
int g_iaJumpType[MAXPLAYERS + 1] = {0, ...};
int g_iaLastJumpType[MAXPLAYERS + 1] = {0, ...};
int g_iaButtons[MAXPLAYERS+1] = {0, ...};
int g_iaMouseDisplay[MAXPLAYERS + 1] = {0, ...};
bool g_bVote = false;
Handle g_hVoteTimer;
float g_faPre[MAXPLAYERS + 1] = {0.0, ...};
float g_faPosition[MAXPLAYERS + 1][2][3];
int g_iaTendency[MAXPLAYERS + 1][2];
int g_iaTendencyFluctuations[MAXPLAYERS + 1] = {0, ...};
bool g_baTracked[MAXPLAYERS + 1] = {true, ...};

//Jump consts
char g_saJumpQualities[][] =
{
    "Impressive",
    "Excellent",
    "Outstanding",
    "Unreal",
    "Godlike"
};

GlobalForward g_fwJumpForward;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_fwJumpForward = new GlobalForward("JumpStats_OnJump", ET_Ignore, Param_Cell, Param_Any, Param_Float);

    CreateNative("JumpStats_InterruptJump", Native_InterruptJump);
    CreateNative("JumpStats_ClientUntrack", Native_ClientUntrack);
    CreateNative("JumpStats_ClientTrack", Native_ClientTrack);
    CreateNative("JumpStats_ClientIsTracked", Native_ClientIsTracked);

    RegPluginLibrary("jumpstats");

    return APLRes_Success;
}

public void OnPluginStart()
{
    //ConVars here
    CreateConVar("jumpstats_version", PLUGIN_VERSION, "Version of JumpStats", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_hEnabled = CreateConVar("js_enabled", STATS_ENABLED, "Turns the jumpstats On/Off (0=OFF, 1=ON)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hDisplayEnabled = CreateConVar("js_display_enabled", DISPLAY_ENABLED, "Turns the display On/Off by the player's state (0=OFF, 1=ALIVE, 2=DEAD, 3=ANY)", _, true, 0.0, true, 3.0);
    g_hDisplayDelayRoundstart = CreateConVar("js_display_delay_roundstart", DISPLAY_DELAY_ROUNDSTART, "Sets the roundstart delay before the display is shown.", _, true, 0.0);
    g_hBunnyHopCancelsAnnouncer = CreateConVar("js_bunnyhop_cancels_announcer", BUNNY_HOP_CANCELS_ANNOUNCER, "Decides if bunny hopping after a jump cancels the announcer.", _, true, 0.0, true, 1.0);
    g_hMinimumAnnounceTier = CreateConVar("js_minimum_announce_tier", MINIMUM_ANNOUNCE_TIER, "The minimum jump tier required for announcing.");
    g_hAnnounceToTeams = CreateConVar("js_announce_to_teams", ANNOUNCE_TO_TEAMS, "The teams that can see jump announcements (0=NONE, 1=T, 2=CT, 3=T&CT, 4=ALL).", _, true, 0.0);
    g_hRecordForTeams = CreateConVar("js_record_for_teams", RECORD_FOR_TEAMS, "The teams to record jumps for (0=NONE, 1=T, 2=CT, 3=T&CT)", _, true, 0.0);
    if(!DISABLE_SOUNDS)
        g_hAnnouncerSounds = CreateConVar("js_announcer_sounds", ANNOUNCER_SOUNDS, "Turns the announcer sounds On/Off (0=OFF, 1=ON)", _, true, 0.0, true, 1.0);

    g_hLJImpressive = CreateConVar("js_lj_impressive", LJ_IMPRESSIVE, "The distance required for an Impressive Long Jump", _, true, 0.0);
    g_hLJExcellent = CreateConVar("js_lj_excellent", LJ_EXCELLENT, "The distance required for an Excellent Long Jump", _, true, 0.0);
    g_hLJOutstanding = CreateConVar("js_lj_outstanding", LJ_OUTSTANDING, "The distance required for an Outstanding Long Jump", _, true, 0.0);
    g_hLJUnreal = CreateConVar("js_lj_unreal", LJ_UNREAL, "The distance required for an Unreal Long Jump", _, true, 0.0);
    g_hLJGodlike = CreateConVar("js_lj_godlike", LJ_GODLIKE, "The distance required for a Godlike Long Jump", _, true, 0.0);

    g_hBHJImpressive = CreateConVar("js_bhj_impressive", BHJ_IMPRESSIVE, "The distance required for an Impressive BunnyHop Jump", _, true, 0.0);
    g_hBHJExcellent = CreateConVar("js_bhj_excellent", BHJ_EXCELLENT, "The distance required for an Excellent BunnyHop Jump", _, true, 0.0);
    g_hBHJOutstanding = CreateConVar("js_bhj_outstanding", BHJ_OUTSTANDING, "The distance required for an Outstanding BunnyHop Jump", _, true, 0.0);
    g_hBHJUnreal = CreateConVar("js_bhj_unreal", BHJ_UNREAL, "The distance required for an Unreal BunnyHop Jump", _, true, 0.0);
    g_hBHJGodlike = CreateConVar("js_bhj_godlike", BHJ_GODLIKE, "The distance required for a Godlike BunnyHop Jump", _, true, 0.0);

    g_hMBHJImpressive = CreateConVar("js_mbhj_impressive", MBHJ_IMPRESSIVE, "The distance required for an Impressive Multi BunnyHop Jump", _, true, 0.0);
    g_hMBHJExcellent = CreateConVar("js_mbhj_excellent", MBHJ_EXCELLENT, "The distance required for an Excellent Multi BunnyHop Jump", _, true, 0.0);
    g_hMBHJOutstanding = CreateConVar("js_mbhj_outstanding", MBHJ_OUTSTANDING, "The distance required for an Outstanding Multi BunnyHop Jump", _, true, 0.0);
    g_hMBHJUnreal = CreateConVar("js_mbhj_unreal", MBHJ_UNREAL, "The distance required for an Unreal Multi BunnyHop Jump", _, true, 0.0);
    g_hMBHJGodlike = CreateConVar("js_mbhj_godlike", MBHJ_GODLIKE, "The distance required for a Godlike Multi BunnyHop Jump", _, true, 0.0);

    g_hLadJImpressive = CreateConVar("js_ladj_impressive", LADJ_IMPRESSIVE, "The distance required for an Impressive Ladder Jump", _, true, 0.0);
    g_hLadJExcellent = CreateConVar("js_ladj_excellent", LADJ_EXCELLENT, "The distance required for an Excellent Ladder Jump", _, true, 0.0);
    g_hLadJOutstanding = CreateConVar("js_ladj_outstanding", LADJ_OUTSTANDING, "The distance required for an Outstanding Ladder Jump", _, true, 0.0);
    g_hLadJUnreal = CreateConVar("js_ladj_unreal", LADJ_UNREAL, "The distance required for an Unreal Ladder Jump", _, true, 0.0);
    g_hLadJGodlike = CreateConVar("js_ladj_godlike", LADJ_GODLIKE, "The distance required for a Godlike Ladder Jump", _, true, 0.0);

    g_hWHJImpressive = CreateConVar("js_whj_impressive", WHJ_IMPRESSIVE, "The distance required for an Impressive WeirdHop Jump", _, true, 0.0);
    g_hWHJExcellent = CreateConVar("js_whj_excellent", WHJ_EXCELLENT, "The distance required for an Excellent WeirdHop Jump", _, true, 0.0);
    g_hWHJOutstanding = CreateConVar("js_whj_outstanding", WHJ_OUTSTANDING, "The distance required for an Outstanding WeirdHop Jump", _, true, 0.0);
    g_hWHJUnreal = CreateConVar("js_whj_unreal", WHJ_UNREAL, "The distance required for an Unreal WeirdHop Jump", _, true, 0.0);
    g_hWHJGodlike = CreateConVar("js_whj_godlike", WHJ_GODLIKE, "The distance required for a Godlike WeirdHop Jump", _, true, 0.0);

    g_hLDHJImpressive = CreateConVar("js_ldhj_impressive", LDHJ_IMPRESSIVE, "The distance required for an Impressive Ladder DropHop Jump", _, true, 0.0);
    g_hLDHJExcellent = CreateConVar("js_ldhj_excellent", LDHJ_EXCELLENT, "The distance required for an Excellent Ladder DropHop Jump", _, true, 0.0);
    g_hLDHJOutstanding = CreateConVar("js_ldhj_outstanding", LDHJ_OUTSTANDING, "The distance required for an Outstanding Ladder DropHop Jump", _, true, 0.0);
    g_hLDHJUnreal = CreateConVar("js_ldhj_unreal", LDHJ_UNREAL, "The distance required for an Unreal Ladder DropHop Jump", _, true, 0.0);
    g_hLDHJGodlike = CreateConVar("js_ldhj_godlike", LDHJ_GODLIKE, "The distance required for a Godlike Ladder DropHop Jump", _, true, 0.0);

    g_hLBHJImpressive = CreateConVar("js_lbhj_impressive", LBHJ_IMPRESSIVE, "The distance required for an Impressive Ladder BunnyHop Jump", _, true, 0.0);
    g_hLBHJExcellent = CreateConVar("js_lbhj_excellent", LBHJ_EXCELLENT, "The distance required for an Excellent Ladder BunnyHop Jump", _, true, 0.0);
    g_hLBHJOutstanding = CreateConVar("js_lbhj_outstanding", LBHJ_OUTSTANDING, "The distance required for an Outstanding Ladder BunnyHop Jump", _, true, 0.0);
    g_hLBHJUnreal = CreateConVar("js_lbhj_unreal", LBHJ_UNREAL, "The distance required for an Unreal Ladder BunnyHop Jump", _, true, 0.0);
    g_hLBHJGodlike = CreateConVar("js_lbhj_godlike", LBHJ_GODLIKE, "The distance required for a Godlike Ladder BunnyHop Jump", _, true, 0.0);

    g_hImpressiveColor = CreateConVar("js_impressive_color", IMPRESSIVE_COLOR, "Impressive tire msg color");
    g_hExcellentColor = CreateConVar("js_excellent_color", EXCELLENT_COLOR, "Excellent tire msg color");
    g_hOutstandingColor = CreateConVar("js_outstanding_color", OUTSTANDING_COLOR, "Outstanding tire msg color");
    g_hUnrealColor = CreateConVar("js_unreal_color", UNREAL_COLOR, "Unreal tire msg color");
    g_hGodlikeColor = CreateConVar("js_godlike_color", GODLIKE_COLOR, "Godlike tire msg color");
    // Remember to add HOOKS to OnCvarChange | and also update OnConfigsExecuted
    //                                       V
    HookConVarChange(g_hEnabled, OnCvarChange);
    HookConVarChange(g_hDisplayEnabled, OnCvarChange);
    HookConVarChange(g_hDisplayDelayRoundstart, OnCvarChange);
    HookConVarChange(g_hBunnyHopCancelsAnnouncer, OnCvarChange);
    HookConVarChange(g_hMinimumAnnounceTier, OnCvarChange);
    HookConVarChange(g_hAnnounceToTeams, OnCvarChange);
    HookConVarChange(g_hRecordForTeams, OnCvarChange);
    if(!DISABLE_SOUNDS)
        HookConVarChange(g_hAnnouncerSounds, OnCvarChange);

    HookConVarChange(g_hLJImpressive, OnCvarChange);
    HookConVarChange(g_hLJExcellent, OnCvarChange);
    HookConVarChange(g_hLJOutstanding, OnCvarChange);
    HookConVarChange(g_hLJUnreal, OnCvarChange);
    HookConVarChange(g_hLJGodlike, OnCvarChange);

    HookConVarChange(g_hBHJImpressive, OnCvarChange);
    HookConVarChange(g_hBHJExcellent, OnCvarChange);
    HookConVarChange(g_hBHJOutstanding, OnCvarChange);
    HookConVarChange(g_hBHJUnreal, OnCvarChange);
    HookConVarChange(g_hBHJGodlike, OnCvarChange);

    HookConVarChange(g_hMBHJImpressive, OnCvarChange);
    HookConVarChange(g_hMBHJExcellent, OnCvarChange);
    HookConVarChange(g_hMBHJOutstanding, OnCvarChange);
    HookConVarChange(g_hMBHJUnreal, OnCvarChange);
    HookConVarChange(g_hMBHJGodlike, OnCvarChange);

    HookConVarChange(g_hLadJImpressive, OnCvarChange);
    HookConVarChange(g_hLadJExcellent, OnCvarChange);
    HookConVarChange(g_hLadJOutstanding, OnCvarChange);
    HookConVarChange(g_hLadJUnreal, OnCvarChange);
    HookConVarChange(g_hLadJGodlike, OnCvarChange);

    HookConVarChange(g_hWHJImpressive, OnCvarChange);
    HookConVarChange(g_hWHJExcellent, OnCvarChange);
    HookConVarChange(g_hWHJOutstanding, OnCvarChange);
    HookConVarChange(g_hWHJUnreal, OnCvarChange);
    HookConVarChange(g_hWHJGodlike, OnCvarChange);

    HookConVarChange(g_hLDHJImpressive, OnCvarChange);
    HookConVarChange(g_hLDHJExcellent, OnCvarChange);
    HookConVarChange(g_hLDHJOutstanding, OnCvarChange);
    HookConVarChange(g_hLDHJUnreal, OnCvarChange);
    HookConVarChange(g_hLDHJGodlike, OnCvarChange);

    HookConVarChange(g_hLBHJImpressive, OnCvarChange);
    HookConVarChange(g_hLBHJExcellent, OnCvarChange);
    HookConVarChange(g_hLBHJOutstanding, OnCvarChange);
    HookConVarChange(g_hLBHJUnreal, OnCvarChange);
    HookConVarChange(g_hLBHJGodlike, OnCvarChange);

    HookConVarChange(g_hImpressiveColor, OnCvarChange);
    HookConVarChange(g_hExcellentColor, OnCvarChange);
    HookConVarChange(g_hOutstandingColor, OnCvarChange);
    HookConVarChange(g_hUnrealColor, OnCvarChange);
    HookConVarChange(g_hGodlikeColor, OnCvarChange);

    //Hooked'em
    HookEvent("player_spawn", OnPlayerSpawn);
    HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", OnRoundEnd);
    HookEvent("player_death", OnPlayerDeath);

    g_bEnabled = true;

    RegConsoleCmd("togglestats", Command_ToggleStats);
    RegConsoleCmd("toggleannouncersounds", Command_ToggleSoundAnnouncer);
    AutoExecConfig(true, "jumpstats");

    g_hToggleStatsCookie = RegClientCookie("ToggleStatsCookie", "Me want cookie!", CookieAccess_Private);
    g_hToggleAnnouncerSoundsCookie = RegClientCookie("ToogleAnnouncerSoundsCookie", "Me can't afford it.", CookieAccess_Private);

    for(int iClient = 1; iClient <= MaxClients; iClient++) {
        if(IsClientInGame(iClient) && !IsFakeClient(iClient) && AreClientCookiesCached(iClient)) {
            OnClientCookiesCached(iClient);
        }
    }
}

public void OnConfigsExecuted()
{
    g_bEnabled = g_hEnabled.BoolValue;
    g_iDisplayEnabled = g_hDisplayEnabled.IntValue;
    g_fDisplayDelayRoundstart = g_hDisplayDelayRoundstart.FloatValue;
    g_bBunnyHopCancelsAnnouncer = g_hBunnyHopCancelsAnnouncer.BoolValue;
    char sTier[32];
    g_hMinimumAnnounceTier.GetString(sTier, sizeof(sTier));
    g_iMinimumAnnounceTier = GetQualityIndex(sTier);
    g_iAnnounceToTeams = g_hAnnounceToTeams.IntValue;
    g_iRecordForTeams = g_hRecordForTeams.IntValue;
    if(!DISABLE_SOUNDS) {
        g_iAnnouncerSounds = g_hAnnouncerSounds.IntValue;
    }
    else
        g_iAnnouncerSounds = 0;

    g_faQualityDistances[JUMP_LJ][IMPRESSIVE] = g_hLJImpressive.FloatValue;
    g_faQualityDistances[JUMP_LJ][EXCELLENT] = g_hLJExcellent.FloatValue;
    g_faQualityDistances[JUMP_LJ][OUTSTANDING] = g_hLJOutstanding.FloatValue;
    g_faQualityDistances[JUMP_LJ][UNREAL] = g_hLJUnreal.FloatValue;
    g_faQualityDistances[JUMP_LJ][GODLIKE] = g_hLJGodlike.FloatValue;

    g_faQualityDistances[JUMP_BHJ][IMPRESSIVE] = g_hBHJImpressive.FloatValue;
    g_faQualityDistances[JUMP_BHJ][EXCELLENT] = g_hBHJExcellent.FloatValue;
    g_faQualityDistances[JUMP_BHJ][OUTSTANDING] = g_hBHJOutstanding.FloatValue;
    g_faQualityDistances[JUMP_BHJ][UNREAL] = g_hBHJUnreal.FloatValue;
    g_faQualityDistances[JUMP_BHJ][GODLIKE] = g_hBHJGodlike.FloatValue;

    g_faQualityDistances[JUMP_MBHJ][IMPRESSIVE] = g_hMBHJImpressive.FloatValue;
    g_faQualityDistances[JUMP_MBHJ][EXCELLENT] = g_hMBHJExcellent.FloatValue;
    g_faQualityDistances[JUMP_MBHJ][OUTSTANDING] = g_hMBHJOutstanding.FloatValue;
    g_faQualityDistances[JUMP_MBHJ][UNREAL] = g_hMBHJUnreal.FloatValue;
    g_faQualityDistances[JUMP_MBHJ][GODLIKE] = g_hMBHJGodlike.FloatValue;

    g_faQualityDistances[JUMP_LADJ][IMPRESSIVE] = g_hLadJImpressive.FloatValue;
    g_faQualityDistances[JUMP_LADJ][EXCELLENT] = g_hLadJExcellent.FloatValue;
    g_faQualityDistances[JUMP_LADJ][OUTSTANDING] = g_hLadJOutstanding.FloatValue;
    g_faQualityDistances[JUMP_LADJ][UNREAL] = g_hLadJUnreal.FloatValue;
    g_faQualityDistances[JUMP_LADJ][GODLIKE] = g_hLadJGodlike.FloatValue;

    g_faQualityDistances[JUMP_WHJ][IMPRESSIVE] = g_hWHJImpressive.FloatValue;
    g_faQualityDistances[JUMP_WHJ][EXCELLENT] = g_hWHJExcellent.FloatValue;
    g_faQualityDistances[JUMP_WHJ][OUTSTANDING] = g_hWHJOutstanding.FloatValue;
    g_faQualityDistances[JUMP_WHJ][UNREAL] = g_hWHJUnreal.FloatValue;
    g_faQualityDistances[JUMP_WHJ][GODLIKE] = g_hWHJGodlike.FloatValue;

    g_faQualityDistances[JUMP_LDHJ][IMPRESSIVE] = g_hLDHJImpressive.FloatValue;
    g_faQualityDistances[JUMP_LDHJ][EXCELLENT] = g_hLDHJExcellent.FloatValue;
    g_faQualityDistances[JUMP_LDHJ][OUTSTANDING] = g_hLDHJOutstanding.FloatValue;
    g_faQualityDistances[JUMP_LDHJ][UNREAL] = g_hLDHJUnreal.FloatValue;
    g_faQualityDistances[JUMP_LDHJ][GODLIKE] = g_hLDHJGodlike.FloatValue;

    g_faQualityDistances[JUMP_LBHJ][IMPRESSIVE] = g_hLBHJImpressive.FloatValue;
    g_faQualityDistances[JUMP_LBHJ][EXCELLENT] = g_hLBHJExcellent.FloatValue;
    g_faQualityDistances[JUMP_LBHJ][OUTSTANDING] = g_hLBHJOutstanding.FloatValue;
    g_faQualityDistances[JUMP_LBHJ][UNREAL] = g_hLBHJUnreal.FloatValue;
    g_faQualityDistances[JUMP_LBHJ][GODLIKE] = g_hLBHJGodlike.FloatValue;

    g_hImpressiveColor.GetString(g_saQualityColor[IMPRESSIVE], 32);
    g_hExcellentColor.GetString(g_saQualityColor[EXCELLENT], 32);
    g_hOutstandingColor.GetString(g_saQualityColor[OUTSTANDING], 32);
    g_hUnrealColor.GetString(g_saQualityColor[UNREAL], 32);
    g_hGodlikeColor.GetString(g_saQualityColor[GODLIKE], 32);
}

public void OnCvarChange(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
    char sConVarName[64];
    GetConVarName(hConVar, sConVarName, sizeof(sConVarName));

    if(StrEqual("js_enabled", sConVarName))
        g_bEnabled = hConVar.BoolValue; else
    if(StrEqual("js_display_enabled", sConVarName))
        g_iDisplayEnabled = hConVar.IntValue; else
    if(StrEqual("js_display_delay_roundstart", sConVarName))
        g_fDisplayDelayRoundstart = hConVar.FloatValue; else
    if(StrEqual("js_bunnyhop_cancels_announcer", sConVarName))
        g_bBunnyHopCancelsAnnouncer = hConVar.BoolValue; else
    if(StrEqual("js_minimum_announce_tier", sConVarName)) {
        char sTier[32];
        hConVar.GetString(sTier, sizeof(sTier));
        g_iMinimumAnnounceTier = GetQualityIndex(sTier);
    } else
    if(StrEqual("js_announce_to_teams", sConVarName))
        g_iAnnounceToTeams = hConVar.IntValue; else
    if(StrEqual("js_record_for_teams", sConVarName))
        g_iRecordForTeams = hConVar.IntValue; else
    if(StrEqual("js_announcer_sounds", sConVarName)) {
        if(!DISABLE_SOUNDS) {
            g_iAnnouncerSounds = hConVar.IntValue;
        }
        else
            g_iAnnouncerSounds = 0;
    } else

    if(StrEqual("js_lj_impressive", sConVarName))
        g_faQualityDistances[JUMP_LJ][IMPRESSIVE] = hConVar.FloatValue; else
    if(StrEqual("js_lj_excellent", sConVarName))
        g_faQualityDistances[JUMP_LJ][EXCELLENT] = hConVar.FloatValue; else
    if(StrEqual("js_lj_outstanding", sConVarName))
        g_faQualityDistances[JUMP_LJ][OUTSTANDING] = hConVar.FloatValue; else
    if(StrEqual("js_lj_unreal", sConVarName))
        g_faQualityDistances[JUMP_LJ][UNREAL] = hConVar.FloatValue; else
    if(StrEqual("js_lj_godlike", sConVarName))
        g_faQualityDistances[JUMP_LJ][GODLIKE] = hConVar.FloatValue; else

    if(StrEqual("js_impressive_color", sConVarName))
        hConVar.GetString(g_saQualityColor[IMPRESSIVE], 32); else
    if(StrEqual("js_excellent_color", sConVarName))
        hConVar.GetString(g_saQualityColor[EXCELLENT], 32); else
    if(StrEqual("js_outstanding_color", sConVarName))
        hConVar.GetString(g_saQualityColor[OUTSTANDING], 32); else
    if(StrEqual("js_unreal_color", sConVarName))
        hConVar.GetString(g_saQualityColor[UNREAL], 32); else
    if(StrEqual("js_godlike_color", sConVarName))
        hConVar.GetString(g_saQualityColor[GODLIKE], 32);
}

public void OnClientCookiesCached(int iClient)
{
    char sCookieValue[8];

    GetClientCookie(iClient, g_hToggleStatsCookie, sCookieValue, sizeof(sCookieValue));
    g_baStats[iClient] = !StrEqual(sCookieValue, "off");

    GetClientCookie(iClient, g_hToggleAnnouncerSoundsCookie, sCookieValue, sizeof(sCookieValue));
    g_baAnnouncerSounds[iClient] = !StrEqual(sCookieValue, "off");
}

bool InterruptJump(int iClient, const char[] sMessage)
{
    if(iClient < 1 || iClient >= MaxClients)
        return false;

    if(g_iaTendencyFluctuations[iClient])
        PrintToConsole(iClient, "!INTERRUPT! - Your height fluctuated too much during the jump.", g_iaTendencyFluctuations[iClient]);
    g_iaJumped[iClient] = JUMP_NONE;
    g_baCanBhop[iClient] = false;
    g_iaJumpType[iClient] = JUMP_INVALID;
    g_iaJumpContext[iClient] = NONE;
    g_iaTendencyFluctuations[iClient] = 0;

    if(!sMessage[0])
        PrintToConsole(iClient, "[JS] Your jump recording was interrupted.");
    else
        PrintToConsole(iClient, sMessage);
    return true;
}

public int Native_InterruptJump(Handle hPlugin, int iNumParams)
{
    if(iNumParams != 1)
        return false;

    int iClient = GetNativeCell(1);
    char sPluginName[64];
    GetPluginFilename(hPlugin, sPluginName, sizeof(sPluginName));
    char sInterruptMessage[100];
    Format(sInterruptMessage, sizeof(sInterruptMessage), "[JS] Your jump was interrupted by a plugin called %s.", sPluginName);
    return InterruptJump(iClient, sInterruptMessage);
}

public int Native_ClientUntrack(Handle plugin, int numParams)
{
    int iClient = GetNativeCell(1);

    g_baTracked[iClient] = false;

    InterruptJump(iClient, "[JS] Your jump was interrupted because you are no longer tracked.");
}

public int Native_ClientTrack(Handle plugin, int numParams)
{
    int iClient = GetNativeCell(1);

    g_baTracked[iClient] = true;
}

public int Native_ClientIsTracked(Handle plugin, int numParams)
{
    int iClient = GetNativeCell(1);

    return g_baTracked[iClient];
}

public void OnMapStart() {
    // Precache sounds
    if(!DISABLE_SOUNDS) {
        for(int iTier = IMPRESSIVE; iTier <= GODLIKE; iTier++) {
            char sTemp[64];
            Format(sTemp, sizeof(sTemp), "sound/%s", g_saJumpSoundPaths[iTier][1]);
            AddFileToDownloadsTable(sTemp);
            AddToStringTable(FindStringTable("soundprecache"), g_saJumpSoundPaths[iTier]);
        }
    }
    g_bVote = false;
}

public void OnMapEnd() {
    if(g_hDisplayTimer != null) {
        KillTimer(g_hDisplayTimer);
        g_hDisplayTimer = null;
    }

    if(g_hInitialDisplayTimer != null) {
        KillTimer(g_hInitialDisplayTimer);
        g_hInitialDisplayTimer = null;
    }

    if(!g_bEnabled)
        return;
}

public Action OnRoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    if(!g_bEnabled)
        return Plugin_Continue;

    if(g_hDisplayTimer != null) {
        KillTimer(g_hDisplayTimer);
        g_hDisplayTimer = null;
    }
    if(g_hInitialDisplayTimer != null)
        KillTimer(g_hInitialDisplayTimer);
    g_hInitialDisplayTimer = CreateTimer(g_fDisplayDelayRoundstart, ShowDisplay);

    return Plugin_Continue;
}

public Action OnPlayerSpawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    if(!g_bEnabled)
        return Plugin_Continue;
    int iId = GetEventInt(hEvent, "userid");
    int iClient = GetClientOfUserId(iId);
    g_iaJumped[iClient] = JUMP_NONE;
    g_baOnLadder[iClient] = false;
    GetClientAbsOrigin(iClient, g_faPosition[iClient][LAST]);

    return Plugin_Continue;
}

public Action ShowDisplay(Handle hTimer)
{
    g_hInitialDisplayTimer = null;
    if(g_hDisplayTimer != null)
        KillTimer(g_hDisplayTimer);
    for(int iClient = 1; iClient <= MaxClients; iClient++) {
        g_iaButtons[iClient] = 0;
        g_iaMouseDisplay[iClient] = 0;
    }
    g_hDisplayTimer = CreateTimer(REFRESH_RATE, StatsDisplay, _, TIMER_REPEAT);
}

public Action StatsDisplay(Handle hTimer)
{
    if(g_bEnabled && g_iDisplayEnabled) {
        for(int iClient = 1; iClient <= MaxClients; iClient++) {
            if(IsClientInGame(iClient) && g_baStats[iClient] && !g_bVote) {
                if(IsPlayerAlive(iClient)) {
                    if(g_iDisplayEnabled == 3 || g_iDisplayEnabled == 1) {
                        static char sOutput[128];

                        Format(sOutput, sizeof(sOutput), "  Speed: %.1f ups (%.1f)\n", GetPlayerSpeed(iClient), g_faPre[iClient]);

                        int iTeam = GetClientTeam(iClient);
                        if(g_iRecordForTeams == 3 || (g_iRecordForTeams + 1) == iTeam) {
                            if(g_iaJumpType[iClient] != JUMP_VERTICAL) {
                                if(g_iaJumpType[iClient] > JUMP_TOO_SHORT) {
                                    g_faLastDistance[iClient] = g_faDistance[iClient];
                                    g_iaLastJumpType[iClient] = g_iaJumpType[iClient];
                                }

                                Format(sOutput, sizeof(sOutput),
                                "%s  Last Jump: %.1f units [%s]\n", sOutput, g_faLastDistance[iClient], g_saJumpTypes[g_iaLastJumpType[iClient]]);
                            }
                            else {
                                Format(sOutput, sizeof(sOutput), "%s  Last Jump: Vertical\n", sOutput);
                            }
                        }

                        Format(sOutput, sizeof(sOutput), "%s  BunnyHops: %i | %i", sOutput, g_iaBhops[iClient], g_iaTendencyFluctuations[iClient]);
                        // feature to add: for 0 bunnyhops: show LJ Strafes (x% sync)
                        //                 for 1 bunnyhop:  show BJ Strafes (x% sync)
                        //                 for 2 bunnyhops: show Number of bunnyhops and average speed / sync / distance covered

                        PrintHintText(iClient, sOutput);
                    }
                }
                else {
                    if(IsClientObserver(iClient) && (g_iDisplayEnabled >= 2)) {
                        int iSpecMode = GetEntProp(iClient, Prop_Send, "m_iObserverMode");
                        if(iSpecMode == SPECMODE_FIRSTPERSON || iSpecMode == SPECMODE_3RDPERSON) {
                            int iSpectatedClient = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
                            if(iSpectatedClient > 1 && iSpectatedClient <= MaxClients) {
                                static char sOutput[256];
                                if(g_iaButtons[iSpectatedClient] & IN_FORWARD)
                                    Format(sOutput, sizeof(sOutput), "               [ W ]");
                                else
                                    Format(sOutput, sizeof(sOutput), "               [      ]");
                                if(g_iaButtons[iSpectatedClient] & IN_ATTACK)
                                    Format(sOutput, sizeof(sOutput), "%s                    [ATK1]", sOutput);
                                else
                                    Format(sOutput, sizeof(sOutput), "%s                    [         ]", sOutput);
                                if(g_iaButtons[iSpectatedClient] & IN_ATTACK2)
                                    Format(sOutput, sizeof(sOutput), "%s  [ATK2]\n", sOutput);
                                else
                                    Format(sOutput, sizeof(sOutput), "%s  [          ]\n", sOutput);
                                ////////
                                if(g_iaButtons[iSpectatedClient] & IN_MOVELEFT)
                                    Format(sOutput, sizeof(sOutput), "%s  [ A ]", sOutput);
                                else
                                    Format(sOutput, sizeof(sOutput), "%s  [     ]", sOutput);
                                if(g_iaButtons[iSpectatedClient] & IN_BACK)
                                    Format(sOutput, sizeof(sOutput), "%s      [ S ]", sOutput);
                                else
                                    Format(sOutput, sizeof(sOutput), "%s      [     ]", sOutput);
                                if(g_iaButtons[iSpectatedClient] & IN_MOVERIGHT)
                                    Format(sOutput, sizeof(sOutput), "%s      [ D ]", sOutput);
                                else
                                    Format(sOutput, sizeof(sOutput), "%s      [     ]", sOutput);
                                if(g_iaMouseDisplay[iSpectatedClient] & MOUSE_LEFT)
                                    Format(sOutput, sizeof(sOutput), "%s       [\xc2\xab--]", sOutput);
                                else
                                    Format(sOutput, sizeof(sOutput), "%s       [      ]", sOutput);
                                if(g_iaMouseDisplay[iSpectatedClient] & MOUSE_RIGHT)
                                    Format(sOutput, sizeof(sOutput), "%s         [--\xc2\xbb]\n", sOutput);
                                else
                                    Format(sOutput, sizeof(sOutput), "%s         [      ]\n", sOutput);
                                ////////
                                if(g_iaButtons[iSpectatedClient] & IN_DUCK)
                                    Format(sOutput, sizeof(sOutput), "%s  [DUCK]", sOutput);
                                else
                                    Format(sOutput, sizeof(sOutput), "%s  [          ]", sOutput);
                                if(g_iaButtons[iSpectatedClient] & IN_JUMP)
                                    Format(sOutput, sizeof(sOutput), "%s        [JUMP]", sOutput);
                                else
                                    Format(sOutput, sizeof(sOutput), "%s        [           ]", sOutput);
                                Format(sOutput, sizeof(sOutput), "%s    |   Speed: %.1f", sOutput, GetPlayerSpeed(iSpectatedClient));
                                PrintHintText(iClient, sOutput);
                            }
                        }
                    }
                }
            }
        }
    }
    for(int iClient = 1; iClient <= MaxClients; iClient++) {
        g_iaButtons[iClient] = 0;
        g_iaMouseDisplay[iClient] = 0;
    }
    return Plugin_Continue;
}

public Action Command_ToggleStats(int iClient, int iArgs)
{
    if(iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient)) {
        g_baStats[iClient] = !g_baStats[iClient];
        if(!g_baStats[iClient])
            SetClientCookie(iClient, g_hToggleStatsCookie, "off");
        else
            SetClientCookie(iClient, g_hToggleStatsCookie, "on");

        PrintToChat(iClient, "\x04[JS] You have turned %s the jump stats.", g_baStats[iClient] ? "on" : "off");
    }
    return Plugin_Handled;
}

public Action Command_ToggleSoundAnnouncer(int iClient, int iArgs)
{
    if(iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient)) {
        g_baAnnouncerSounds[iClient] = !g_baAnnouncerSounds[iClient];
        if(!g_baAnnouncerSounds[iClient])
            SetClientCookie(iClient, g_hToggleAnnouncerSoundsCookie, "off");
        else
            SetClientCookie(iClient, g_hToggleAnnouncerSoundsCookie, "on");

        PrintToChat(iClient, "\x04[JS] You have turned %s the announcer sounds.", g_baAnnouncerSounds[iClient] ? "on" : "off");
    }
    return Plugin_Handled;
}

public Action SDKHook_StartTouch_Callback(int iClient, int iTouched)
{
    if(g_bEnabled && iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient)) {
        if(IsPlayerAlive(iClient)) {
            if(g_iaJumped[iClient]) {  // if the player jumped before the touch occured
                if(iTouched > 0)  // the player touched an entity (not the world)
                    InterruptJump(iClient, "[JS] Your jump was interrupted because you touched something.");  // therefore we interrupt the jump
                else if(iTouched == 0)   // if the player touched the world
                    if(!(GetEntityFlags(iClient) & FL_ONGROUND))  // and it's currently not standing on the ground
                        InterruptJump(iClient, "[JS] Your jump was interrupted because you touched a wall.");  // interrupt the jump recording
            }
        }
    }
}

public void OnClientDisconnect(int iClient)
{
    SDKUnhook(iClient, SDKHook_StartTouch, SDKHook_StartTouch_Callback);
    g_iaButtons[iClient] = 0;
    g_baStats[iClient] = true;
    g_iaJumped[iClient] = JUMP_NONE;
    g_iaFrame[iClient] = 0;
    g_iaBhops[iClient] = 0;
    g_baCanJump[iClient] = true;
    g_faLastDistance[iClient] = 0.0;
    g_faPre[iClient] = 0.0;
}

public void OnClientPutInServer(int iClient)
{
    SDKHook(iClient, SDKHook_StartTouch, SDKHook_StartTouch_Callback);
    OnClientCookiesCached(iClient);
}

public Action OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &iDamage, int &iDamageType)
{
    if(!g_bEnabled)
        return Plugin_Continue;

    if(iVictim == 0)
        return Plugin_Continue;

    //Insert Jump Interrupt here with ConVar

    return Plugin_Continue;
}

public Action OnPlayerDeath(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    if(!g_bEnabled)
        return Plugin_Continue;

    // Insert Jump Interrupt here

    return Plugin_Continue;
}

int GetQualityIndex(const char[] sQuality)
{
    int iIndex;
    for(iIndex = 0; strcmp(sQuality, g_saJumpQualities[iIndex], false); iIndex++) {}
    return iIndex;
}

void AnnounceLastJump(int iClient)
{
    if(!g_baStats[iClient])
        return;

    if(g_iaJumpType[iClient] > JUMP_NONE) {
        int iType = g_iaJumpType[iClient];

        JumpType type;
        switch(iType) {
            case JUMP_LJ: type = Jump_LJ;
            case JUMP_BHJ: type = Jump_BHJ;
            case JUMP_MBHJ: type = Jump_MBHJ;
            case JUMP_LADJ: type = Jump_LadJ;
            case JUMP_WHJ: type = Jump_WHJ;
            case JUMP_LDHJ: type = Jump_LDHJ;
            case JUMP_LBHJ: type = Jump_LBHJ;
            default: type = Jump_None;
        }
        Call_StartForward(g_fwJumpForward);
        Call_PushCell(iClient);
        Call_PushCell(type);
        Call_PushFloat(g_faDistance[iClient]);
        Call_Finish();

        int iQuality;
        for(iQuality = -1; iQuality < sizeof(g_saJumpQualities) - 1; iQuality++) {
            if(g_faDistance[iClient] < g_faQualityDistances[iType][iQuality + 1])
                break;
        }

        if(iQuality > -1 && iQuality >= g_iMinimumAnnounceTier) {
            static char sNickname[MAX_NAME_LENGTH];
            CGetClientName(iClient, sNickname, sizeof(sNickname));

            static char sArticle[3];
            if(FindCharInString("AEIOUaeiou", g_saJumpQualities[iQuality][0]) != -1)
                Format(sArticle, sizeof(sArticle), "an");
            else
                Format(sArticle, sizeof(sArticle), "a");

            if(g_iAnnounceToTeams)
                for(int iId = 1; iId < MaxClients; iId++) {
                    if(IsClientInGame(iId) && g_baStats[iId]) {
                        int iTeam = GetClientTeam(iId);
                        if(g_iAnnounceToTeams == 4 ||
                           (iTeam > JOINTEAM_SPEC && (iTeam - 1 == g_iAnnounceToTeams || g_iAnnounceToTeams == 3))) {
                            // Announce in chat
                            CPrintToChat(iId, "%s[JS] %s did %s %s %.3f units %s.",
                                g_saQualityColor[iQuality], sNickname, sArticle, g_saJumpQualities[iQuality], g_faDistance[iClient], g_saPrettyJumpTypes[iType]);
                            // Announce by sound
                            if(g_iAnnouncerSounds == 1 && g_baAnnouncerSounds[iId]) {
                                if(iClient == iId || iQuality == 4)
                                    EmitSoundToClient(iId, g_saJumpSoundPaths[iQuality]);
                            }
                        }

                    }
                }
        }
    }
}

public Action StopBhopRecord(Handle hTimer, any iClient)
{
    if(iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient)) {
        g_baCanBhop[iClient] = false;
        g_iaJumpContext[iClient] = NONE;
    }
}

public Action AnnounceLastJumpDelayed(Handle hTimer, any iClient)
{
    if(g_baAnnounceLastJump[iClient])
        AnnounceLastJump(iClient);
}

void RecordJump(int iClient)
{
    GetClientAbsOrigin(iClient, g_faLandCoord[iClient]);
    float fDelta;
    int iTeam = GetClientTeam(iClient);

    if((g_faLandCoord[iClient][2] >= 0.0 && g_faJumpCoord[iClient][2] >= 0.0) ||
    (g_faLandCoord[iClient][2] <= 0.0 && g_faJumpCoord[iClient][2] <= 0.0))
        fDelta = FloatAbs(g_faLandCoord[iClient][2] - g_faJumpCoord[iClient][2]);
    else
        fDelta = FloatAbs(g_faLandCoord[iClient][2]) + FloatAbs(g_faJumpCoord[iClient][2]);

    if(fDelta < 2.0) {  // allow a height difference of 2 units
        g_faJumpCoord[iClient][2] = 0.0;
        g_faLandCoord[iClient][2] = 0.0;
        g_faDistance[iClient] = GetVectorDistance(g_faJumpCoord[iClient], g_faLandCoord[iClient]) + 32.0;

        if(g_faDistance[iClient] >= MINIMUM_LJ_DISTANCE) {
            g_iaJumpType[iClient] = g_iaJumped[iClient];
        }
        else
            g_iaJumpType[iClient] = JUMP_TOO_SHORT;
    }
    else if(fDelta < 10.0) { // ladder jumps usually have a height difference of 1 to 10 units (bigger is possible, up to 25 actually)
        // needs better detection
        if(g_iaJumped[iClient] == JUMP_LADJ) {
            g_faJumpCoord[iClient][2] = 0.0;
            g_faLandCoord[iClient][2] = 0.0;
            g_faDistance[iClient] = GetVectorDistance(g_faJumpCoord[iClient], g_faLandCoord[iClient]) + 32.0;

            if(g_faDistance[iClient] >= MINIMUM_LADJ_DISTANCE) {
                g_iaJumpType[iClient] = JUMP_LADJ;
                g_faLastDistance[iClient] = g_faDistance[iClient];
            }
            else
                g_iaJumpType[iClient] = JUMP_TOO_SHORT;
        }
        else
            g_iaJumpType[iClient] = JUMP_VERTICAL;
    }
    else {
        g_iaJumpType[iClient] = JUMP_INVALID; // the player probably didn't intend a longjump so the display will show the last valid jump
    }

    // this needs better detection
    if(fDelta < 20.0 && g_iaJumped[iClient] == JUMP_LADJ && g_iaJumpContext[iClient] == LADDER_UNKNOWN)
        g_iaJumpContext[iClient] = LADDER_JUMPED;
    if(g_iaJumpContext[iClient] == LADDER_UNKNOWN)
        g_iaJumpContext[iClient] = LADDER_DROPPED;

    if(g_iRecordForTeams == 3 || (g_iRecordForTeams + 1) == iTeam) { // this can be moved to top after I get ladder detection right
        if(g_iaJumpType[iClient] > JUMP_NONE) {
            if(!g_bBunnyHopCancelsAnnouncer)
                AnnounceLastJump(iClient);
            else
                CreateTimer(BHOP_TIME + 0.05, AnnounceLastJumpDelayed, iClient, TIMER_FLAG_NO_MAPCHANGE);  // might require 2 * BHOP_TIME
        }
    }
}

void GetPreJumpType(int iClient)
{
    if(g_iaBhops[iClient] == 1) {
        if(g_iaJumpContext[iClient] == LADDER_DROPPED) {
            g_iaJumped[iClient] = JUMP_LDHJ;
        } else
        if(g_iaJumpContext[iClient] == LADDER_JUMPED) {
            g_iaJumped[iClient] = JUMP_LBHJ;
        } else
        if(g_iaJumped[iClient] == JUMP_LJ) {
            g_iaJumped[iClient] = JUMP_BHJ;
        } else
        if(g_iaJumped[iClient] == JUMP_NONE && g_iaJumpContext[iClient] == DROPPED) {
            g_iaJumped[iClient] = JUMP_WHJ;
        }
        else {
            g_iaJumped[iClient] = JUMP_BHJ;
        }
    }
    else
        g_iaJumped[iClient] = JUMP_MBHJ;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float faVelocity[3], float faAngles[3], int &iWeapon, int &iSubType, int &iCmdNum, int &iTickCount, int &iSeed, int iMouse[2]) //OnRunCmd
{
    if(!g_bEnabled || !g_baTracked[iClient])
        return Plugin_Continue;

    // STATS START HERE
    // Record buttons pressed for displaying
    g_iaButtons[iClient] |= iButtons;

    // Record X-axis mouse movement for displaying
    static float s_fLastXAngle[MAXPLAYERS + 1];

    // Record current player position
    GetClientAbsOrigin(iClient, g_faPosition[iClient][CURRENT]);

    // Recording angles every 9 frames for optimisation
    if(g_iaFrame[iClient] == 8) {
        // The following code is duplicated for optimisation purposes
        if((s_fLastXAngle[iClient] < 0.0 && faAngles[1] < 0.0) || (s_fLastXAngle[iClient] > 0.0 && faAngles[1] > 0.0)) {
            if(faAngles[1] > s_fLastXAngle[iClient])
                g_iaMouseDisplay[iClient] |= MOUSE_LEFT;
            else if(s_fLastXAngle[iClient] > faAngles[1])
                g_iaMouseDisplay[iClient] |= MOUSE_RIGHT;
        }
        else if(s_fLastXAngle[iClient] > 90.0 || faAngles[1] > 90.0) {
            if(faAngles[1] < 0.0)
                g_iaMouseDisplay[iClient] |= MOUSE_LEFT;
            else
                g_iaMouseDisplay[iClient] |= MOUSE_RIGHT;
        }
        else {
            if(faAngles[1] > s_fLastXAngle[iClient])
                g_iaMouseDisplay[iClient] |= MOUSE_LEFT;
            else if(s_fLastXAngle[iClient] > faAngles[1])
                g_iaMouseDisplay[iClient] |= MOUSE_RIGHT;
        }
        s_fLastXAngle[iClient] = faAngles[1];
    }

    // Avoid multiple detection of the same jump
    g_iaFrame[iClient]++;
    if(g_iaFrame[iClient] == 9) {
        // The player is able to record a new bunny hop only after 9 frames from the last hop
        g_baJustHopped[iClient] = false;
        g_iaFrame[iClient] = 0;
    }

    if(iButtons & IN_DUCK) {
        if(g_baCanDuck[iClient]){
            g_baCanDuck[iClient] = false;
            g_iaTendencyFluctuations[iClient]--;
        }
    }
    else {
        if(!g_baCanDuck[iClient]){
            g_baCanDuck[iClient] = true;
            g_iaTendencyFluctuations[iClient]--;
        }
    }

    if(g_iaJumped[iClient]) {
        // Interrupt the jump recording if the player movement type changes (ladder, swimming for example)
        if(GetEntityMoveType(iClient) != MOVETYPE_WALK)
            InterruptJump(iClient, "[JS] Your jump was interrupted because you are not in-air or walking.");
        if(InWater(iClient))
            InterruptJump(iClient, "[JS] Your jump was interrupted because you are in water.");
        if (HasNoneStandardSpeed(iClient))
            InterruptJump(iClient, "[JS] Your jump was interrupted because you have none standard movement speed.");
        if (HasExoJump(iClient))
            InterruptJump(iClient, "[JS] Your jump was interrupted because you are using Exo Jump.");
        // Interrupt the jump recording if the player is not constantly descending or ascending
        float fHeightDifference = g_faPosition[iClient][CURRENT][2] - g_faPosition[iClient][LAST][2];
        if(fHeightDifference < 0.0)
            g_iaTendency[iClient][CURRENT] = DESCENDING;
        else if(fHeightDifference > 0.0)
            g_iaTendency[iClient][CURRENT] = ASCENDING;
        else
            g_iaTendency[iClient][CURRENT] = STABLE;
        if(g_iaTendency[iClient][CURRENT] != g_iaTendency[iClient][LAST] && g_iaTendency[iClient][CURRENT] != STABLE)
            g_iaTendencyFluctuations[iClient]++;
        g_iaTendency[iClient][LAST] = g_iaTendency[iClient][CURRENT];
        if(g_iaTendencyFluctuations[iClient] > 3) // actually 2 is enough, except for the most common case when the player ducks after descending
            InterruptJump(iClient, "[JS] Your height fluctuated too much during the jump.");
    }
    // Detect if the player is attached to a ladder
    if(GetEntityMoveType(iClient) == MOVETYPE_LADDER) {
        if(!g_baOnLadder[iClient]) {
            g_baOnLadder[iClient] = true;
        }
    }

    // The player is on the ground
    if(GetEntityFlags(iClient) & FL_ONGROUND) {
        if(g_iaStatus[iClient] == IN_AIR || g_iaStatus[iClient] == JUST_AIRED) {
            g_iaStatus[iClient] = JUST_LANDED;
            g_baCanBhop[iClient] = true;

            // Update the context for the next jump (landing)
            if(g_iaJumped[iClient] > JUMP_NONE) {
                if(g_iaJumped[iClient] == JUMP_LADJ) {
                    g_iaJumpContext[iClient] = LADDER_UNKNOWN;
                }
                else
                    g_iaJumpContext[iClient] = JUMPED;
            }
            else
                g_iaJumpContext[iClient] = DROPPED;
            CreateTimer(BHOP_TIME, StopBhopRecord, iClient, TIMER_FLAG_NO_MAPCHANGE);
        }
        else if(g_iaStatus[iClient] != ON_LAND)
            g_iaStatus[iClient] = ON_LAND;

        if(g_iaStatus[iClient] == JUST_LANDED) {
            if(g_baOnLadder[iClient])
                g_baOnLadder[iClient] = false;
        }

        if(iButtons & IN_JUMP) {  // if the player is pressing the +jump button
            if(!g_baJustHopped[iClient]) {       // avoid fake jumps and multiple bhop recordings
                if(g_baAntiJump[iClient]) {
                    g_faPre[iClient] = GetPlayerSpeed(iClient);
                    if(g_iaJumped[iClient] > JUMP_NONE) {   // if the player jumped during the same frame he landed
                        g_iaTendencyFluctuations[iClient] = 0;
                        g_baAnnounceLastJump[iClient] = false;  // don't announce this jump in case bunnyhopping cancels the announcer
                        RecordJump(iClient);    // record the jump
                        GetClientAbsOrigin(iClient, g_faJumpCoord[iClient]);    // get the player's coordinates for the next (hop) jump
                        g_iaBhops[iClient]++;            // counts the number of normal bhops
                        g_iaFrame[iClient] = 0;            // used to avoid multiple recordings of a jump
                        g_baJustHopped[iClient] = true;    // the player bhopped, used to avoid multiple recordings
                        GetPreJumpType(iClient);
                        g_baCanJump[iClient] = false;    // this variable looks like the opposite of g_iaJumped but it is needed to avoid multiple recordings of both perf and norm bhops
                    }
                    else {
                        if(g_baCanJump[iClient]) {
                            g_iaTendencyFluctuations[iClient] = 0;
                            GetClientAbsOrigin(iClient, g_faJumpCoord[iClient]);
                            if(g_baCanBhop[iClient]) {       // if the bhop time hasn't expired yet
                                g_iaBhops[iClient]++;       // update the bunnyhop counter
                                g_baAnnounceLastJump[iClient] = false;  // don't announce this jump in case bunnyhopping cancels the announcer
                                GetPreJumpType(iClient);
                            }
                            else {
                                g_iaBhops[iClient] = 0;  // reset the bunnyhop counter
                                g_baAnnounceLastJump[iClient] = true;  // set the jump to be announced
                                g_iaJumped[iClient] = JUMP_LJ;
                            }
                            g_iaFrame[iClient] = 0;
                            g_baJustHopped[iClient] = true;
                            g_baCanJump[iClient] = false;
                        }
                    }
                }
                else {  // player is on ground and holding +jump (space)
                    if(g_iaStatus[iClient] == JUST_LANDED) {  // if the player just landed then record this jump
                        if(g_iaJumped[iClient] > JUMP_NONE) {
                            g_baAnnounceLastJump[iClient] = true;  // set the jump to be announced
                            RecordJump(iClient);
                            GetClientAbsOrigin(iClient, g_faJumpCoord[iClient]);
                        }
                        g_iaJumped[iClient] = JUMP_NONE;
                    }
                }
            }
        }
        else {    //the player didn't +jump this time (so we can assume a -jump was made before or even now)
            g_baCanJump[iClient] = true;
            if(g_iaJumped[iClient]) {
                if(!g_baJustHopped[iClient]) {        // player jumped before
                    g_baAnnounceLastJump[iClient] = true;
                    RecordJump(iClient);
                    g_iaJumped[iClient] = JUMP_NONE;
                }
            }
            else {
                if(g_iaStatus[iClient] == JUST_LANDED) {
                    g_iaJumped[iClient] = JUMP_NONE;
                    g_baAnnounceLastJump[iClient] = false;
                }
            }
        }
    }
    else {
        if(g_iaStatus[iClient] > IN_AIR)
            g_iaStatus[iClient] = JUST_AIRED;
        else if(g_iaStatus[iClient] == JUST_AIRED)
            g_iaStatus[iClient] = IN_AIR;
        if(!g_iaJumped[iClient] && g_iaStatus[iClient] == JUST_AIRED)
            g_iaBhops[iClient] = 0;

        if(GetEntityMoveType(iClient) == MOVETYPE_WALK)
            if(g_baOnLadder[iClient]) { // the player just detached from the ladder
                g_baOnLadder[iClient] = false;
                g_iaBhops[iClient] = 0;
                if(g_iaStatus[iClient] >= IN_AIR) { // if the player didn't detach from the ladder directly to the ground
                    // set the conditions for a ladder jump
                    GetClientAbsOrigin(iClient, g_faJumpCoord[iClient]);
                    g_iaJumped[iClient] = JUMP_LADJ;
                }
            }
    }

    if(!(iButtons & IN_JUMP))
        g_baAntiJump[iClient] = true;    // -jump has been recorded
    else
        g_baAntiJump[iClient] = false;   // +jump as been recorded

    CopyVector(g_faPosition[iClient][CURRENT], g_faPosition[iClient][LAST]);
    // STATS END HERE

    return Plugin_Continue;
}

public Action OnRoundEnd(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    // ? BUG ?
    if(!g_bEnabled)
        return Plugin_Continue;
    return Plugin_Continue;
}

float GetPlayerSpeed(int iClient)
{
    static float faVelocity[3];
    GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", faVelocity);

    float fSpeed;
    fSpeed = SquareRoot(faVelocity[0] * faVelocity[0] + faVelocity[1] * faVelocity[1]);
    fSpeed *= GetEntPropFloat(iClient, Prop_Data, "m_flLaggedMovementValue");

    return fSpeed;
}

void CopyVector(const float faOrigin[3], float faTarget[3])
{
    faTarget[0] = faOrigin[0];
    faTarget[1] = faOrigin[1];
    faTarget[2] = faOrigin[2];
}

public void OnMapVoteStarted()
{
    g_bVote = true;
    if(g_hVoteTimer != null) {
        KillTimer(g_hVoteTimer);
        g_hVoteTimer = null;
    }
    g_hVoteTimer = CreateTimer(0.1, CheckVoteEnd, _, TIMER_REPEAT);
}

public Action CheckVoteEnd(Handle hTimer)
{
    if(HasEndOfMapVoteFinished()) {
        g_bVote = false;
        if(g_hVoteTimer != null) {
            KillTimer(g_hVoteTimer);
            g_hVoteTimer = null;
        }
    }
}

bool InWater(int iEntity)
{
    return ( GetEntProp(iEntity, Prop_Send, "m_fFlags") & FL_INWATER ) != 0;
}

bool HasNoneStandardSpeed(int iEntity)
{
    return GetEntPropFloat(iEntity, Prop_Send, "m_flLaggedMovementValue") != 1.0;
}

bool HasExoJump(int iEntity)
{
    return GetEntProp(iEntity, Prop_Send, "m_passiveItems", 1, 1) != 0;
}