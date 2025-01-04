// ============================================================================
// LinkedSpecInfo for DuelSpecOverlay
// Copyright 2024 by _Lynx <aryss.skahara at gmail.com>
//
// Class to track and replicate the pickup times
// Also sets up the interaction on the spec client
// ============================================================================
class LSpecReplicationDuel extends ReplicationInfo;

var int LastKegTime;
var int LastBeltTime;
var int LastUDamageTime;
var int LastArmorTime;
var float MatchStartTime;
var bool bOvertime;
var bool bHasArmor,
         bHasBelt,
         bHasKeg,
         bHasUD;
var PlayerController LocalPlayer;
var DuelSpecOverlay SpecOverlay;

replication
{
    reliable if ( bNetDirty && ( Role == ROLE_Authority ) )
        LastKegTime, LastArmorTime, LastBeltTime, LastUDamageTime,
        bHasArmor, bHasBelt, bHasKeg, bHasUD,
        bOvertime, MatchStartTime;
}


// ============================================================================
// PostNetBeginPlay
//
// Getting Local PC, start timer.
// ============================================================================
simulated event PostNetBeginPlay()
{
    if ( LocalPlayer == None ){
       LocalPlayer = Level.GetLocalPlayerController();
       Log("[LSpec] PostNetBeginPlay: set Local PC");
    }

    SetTimer(1.0,true);
}

function MatchStarting(){
  local xPickupBase pickup;
  local array<string> tmp1, tmp2;

  if (Level.NetMode != NM_Client);
     MatchStartTime = Level.TimeSeconds;

  Split(Level,".",tmp1);
  Log(tmp1[0]);

  foreach AllObjects( class'xPickupBase', pickup )
  {
    // really ugly hack for the game not cleaning up pickups from the previous map
    Split(pickup, ".",tmp2);
    if (tmp2[0] == tmp1[0]){
         if ( UDamageCharger(pickup) !=  None ){
            Log("Found Pickup"@pickup$", enabling UDamage tracking");
            bHasUD = True;
         }
         if ( ShieldCharger(pickup) !=  None ){
            Log("Found Pickup"@pickup$", enabling SHield Pack tracking");
            bHasArmor = True;
         }
         if ( SuperShieldCharger(pickup) !=  None ){
            Log("Found Pickup"@pickup$", enabling SuperShield tracking");
            bHasBelt = True;
         }
         if ( SuperHealthCharger(pickup) !=  None ){
            Log("Found Pickup"@pickup$", enabling Keg O'Health tracking");
            bHasKeg = True;
         }
     }
   }
}

// ============================================================================
// Timer
//
// Checks if references to left and right players PRI are empty and if they are
// fills them with the first non-spec entry that's not the other player. Aren't
// we lucky duels have only two players?
// ============================================================================
simulated function Timer()
{
  local int i;

  if (Level.NetMode != NM_Client && bOvertime != Level.Game.bOverTime){
     Log("[LSpec] Overtime starting");
     bOvertime = Level.Game.bOverTime;
  }

  if (SpecOverlay != None){
     if (SpecOverlay.LeftPlayer == None)
     {
    	for (i = 0; i < LocalPlayer.GameReplicationInfo.PRIArray.Length; i++)
    	{
			if ( !LocalPlayer.GameReplicationInfo.PRIArray[i].bOnlySpectator &&
                 LocalPlayer.GameReplicationInfo.PRIArray[i] != SpecOverlay.RightPlayer
                 )
    		{
                 SpecOverlay.LeftPlayer = LocalPlayer.GameReplicationInfo.PRIArray[i];
                 break;
    		}
    	}
     }
     if (SpecOverlay.RightPlayer == None)
     {
    	for (i = 0; i < LocalPlayer.GameReplicationInfo.PRIArray.Length; i++)
    	{
			if ( !LocalPlayer.GameReplicationInfo.PRIArray[i].bOnlySpectator &&
                 LocalPlayer.GameReplicationInfo.PRIArray[i] != SpecOverlay.LeftPlayer
                 )
    		{
                 SpecOverlay.RightPlayer = LocalPlayer.GameReplicationInfo.PRIArray[i];
                 break;
    		}
    	}
     }
   }
}

function Reset(){
   bOvertime = false;
   LastKegTime = 9999;
   LastBeltTime = 9999;
   LastUDamageTime = 9999;
   LastArmorTime = 0;
}

// ============================================================================
// Tick
//
// Spawn overlay and add references
// ============================================================================
simulated event Tick(float DeltaTime)
{
    local LinkedSpecInfo SpecPRI;

    if (LocalPlayer == None && Level.NetMode != NM_DedicatedServer){
       LocalPlayer = Level.GetLocalPlayerController();
    }

    if (LocalPlayer != None)
       SpecPRI = class'LSpecUtil'.static.GetSpecPRI(LocalPlayer.PlayerReplicationInfo);

    if ( SpecPRI != None &&
         Level.NetMode != NM_DedicatedServer &&
         SpecOverlay == None &&
         LocalPlayer.PlayerReplicationInfo != None &&
         LocalPlayer.PlayerReplicationInfo.bOnlySpectator &&
         ( SpecPRI.bAllow || Level.NetMode == NM_Standalone)
         ) {
      Log("[LSpec] SRI: Overlay is none, trying to spawn");
      SpecOverlay = DuelSpecOverlay(LocalPlayer.Player.InteractionMaster.AddInteraction("LSpec.DuelSpecOverlay", LocalPlayer.Player));
      Log("[LSpec] Overlay is now:"$SpecOverlay);
      if ( SpecOverlay != None ) {
        SpecOverlay.SpecRI = Self;
      }
    }
}



// ============================================================================
// NotifyLevelChange
//
// Cleanup things and references at the end
// ============================================================================
simulated function NotifyLevelChange()
{
  Disable('Tick');
  SpecOverlay = None;
  bhasKeg = False;
  bhasBelt = False;
  bhasArmor = False;
  bhasUD = False;
}

// ============================================================================
// FindRI
//
// A function to find an existing LSpecReplicationDuel class
// Using Wormbo's UTPlus code as a base
// ============================================================================
static function LSpecReplicationDuel FindRI(Actor Referencer)
{
  local LSpecReplicationDuel LSRD;

  if ( Referencer == None )
    return None;

  foreach Referencer.DynamicActors(class'LSpecReplicationDuel', LSRD) {
    return LSRD;
  }
}

// ============================================================================
// InitRI
//
// Static function to find or spawn a new PRI
// Using Wormbo's UTPlus code as a base
// ============================================================================
static function LSpecReplicationDuel InitRI(Actor Referencer)
{
  local LSpecReplicationDuel LSRD;

  LSRD = FindRI(Referencer);

  if ( LSRD == None && Referencer.Level.NetMode != NM_Client ) {
    LSRD = Referencer.Spawn(default.Class);
  }

  return LSRD;
}

defaultproperties {
LastKegTime = 9999;
LastBeltTime = 9999;
LastUDamageTime = 9999;
LastArmorTime = 0;
}


