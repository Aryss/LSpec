// ============================================================================
// SpecPlus mutator for DuelSpecOverlay
// Copyright 2024 by _Lynx <aryss.skahara at gmail.com>
//
// Sets up special controller (currently not used much)
// Also fills the overlay Left and Right player for the local player
// ============================================================================
class MutSpecPlus extends Mutator config;

var globalconfig string Pass;
var string origcontroller;
var class<PlayerController> origcclass;
var LSpecReplicationDuel SpecReplication;
var array<string> AllowedSpecs;

function PostBeginPlay()
{
	local GameRules G;

	Super.PostBeginPlay();
	SpecReplication = class'LSpecReplicationDuel'.static.InitRI(Self);
	G = spawn(class'SpecDataRules');
	SpecDataRules(G).SpecReplication = SpecReplication;
	if ( Level.Game.GameRulesModifiers == None )
		Level.Game.GameRulesModifiers = G;
	else
		Level.Game.GameRulesModifiers.AddGameRules(G);
}

function ModifyLogin(out string Portal, out string Options)
{
	local bool bSeeAll;
	local bool bSpectator;
	local bool bAllow;
	local string PlayerName;

	super.ModifyLogin (Portal, Options);

/*	if (origcontroller != "") {
		Level.Game.PlayerControllerClassName = origcontroller;
		Level.Game.PlayerControllerClass = origcclass;
		origcontroller = "";
	}*/

	bSpectator = ( Level.Game.ParseOption( Options, "SpectatorOnly" ) ~= "1" );
	PlayerName = Level.Game.ParseOption( Options, "Name" );
	bAllow = ( Level.Game.ParseOption( Options, "Key" ) ~= Pass );

	Log("[LSpec] Processing player login for "$PlayerName);


	if (bSpectator && bAllow) {
/*		origcontroller = Level.Game.PlayerControllerClassName;
		origcclass = Level.Game.PlayerControllerClass;
		Level.Game.PlayerControllerClassName = "LSpec.LSController";
		Level.Game.PlayerControllerClass = none;
		Log("[LSpec] Changed controller for "$PlayerName$" to "$Level.Game.PlayerControllerClassName);
*/
     AllowedSpecs.Length = AllowedSpecs.Length + 1;
     AllowedSpecs[AllowedSpecs.Length - 1] = PlayerName;
     log("[LSpec] Adding"@PlayerName@"to the allowlist");
	}
}

function NotifyLogout(Controller Exiting)
{
    local int i;

    for (i = 0; i < AllowedSpecs.Length; i++){
        if (Exiting.PlayerReplicationInfo.PlayerName == AllowedSpecs[i])
           AllowedSpecs.Remove(i,1);
    }

	if (NextMutator != None)
		NextMutator.NotifyLogout(Exiting);
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
    local LinkedReplicationInfo lPRI;

    if (PlayerReplicationInfo(Other)!=None)
    {
        if(PlayerReplicationInfo(Other).CustomReplicationInfo!=None)
        {
            lPRI=PlayerReplicationInfo(Other).CustomReplicationInfo;
            while(lPRI.NextReplicationInfo!=None)
            {
                 lPRI=lPRI.NextReplicationInfo;
            }
            lPRI.NextReplicationInfo=Spawn(class'LinkedSpecInfo', Other.Owner);
            LinkedSpecInfo(lPRI.NextReplicationInfo).PRI = PlayerReplicationInfo(Other);
            LinkedSpecInfo(lPRI.NextReplicationInfo).SpecMutator = self;
            Log("[LSpec] Spawned LinkedSpecInfo for"@PlayerReplicationInfo(Other).PlayerName$", LinkedSpecInfo.PRI set to"@LinkedSpecInfo(lPRI.NextReplicationInfo).PRI);
        }
        else
        {
            PlayerReplicationInfo(Other).CustomReplicationInfo=Spawn(class'LinkedSpecInfo', Other.Owner);
            LinkedSpecInfo(PlayerReplicationInfo(Other).CustomReplicationInfo).PRI = PlayerReplicationInfo(Other);
            LinkedSpecInfo(PlayerReplicationInfo(Other).CustomReplicationInfo).SpecMutator = self;
            Log("[LSpec] Spawned LinkedSpecInfo for"@PlayerReplicationInfo(Other).PlayerName$", LinkedSpecInfo.PRI set to"@LinkedSpecInfo(PlayerReplicationInfo(Other).CustomReplicationInfo).PRI);
        }

    }

  	return Super.CheckReplacement(Other,bSuperRelevant);
}

function bool IsAllowed(string PlayerName){
    local int i;

    for (i = 0; i < AllowedSpecs.Length; i++){
        if (PlayerName == AllowedSpecs[i]){
           log("[LSpec]"@PlayerName@"is cleared to use spec overlay");
           return true;
        }
    }
    log("[LSpec]"@PlayerName@"is not cleared to use spec overlay");
    return false;
}

function bool InStrNonCaseSensitive(String S, string S2)
{
    local int i;
    for(i=0; i<=(Len(S)-Len(S2)); i++)
    {
        if(Mid(S, i, Len(s2))~=S2)
            return true;
    }
    return false;
}

DefaultProperties
{
 FriendlyName="SpecPlus"
 Pass=""
}
