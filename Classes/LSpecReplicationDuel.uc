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
var int LastArmorTimeA,
        LastArmorTimeB,
        LastArmorTimeC;
var int ToNextKeg;
var int ToNextBelt;
var int ToNextUDamage;
var int ToNextArmorA,
        ToNextArmorB,
        ToNextArmorC;
var float MatchStartTime;
var bool bOvertime;
var bool bHasArmorA,
         bHasArmorB,
         bHasArmorC,
         bHasBelt,
         bHasKeg,
         bHasUD;
var PlayerController LocalPlayer;
var DuelSpecOverlay SpecOverlay;
var ShieldPack  ShieldPackA,
                ShieldPackB,
                ShieldPackC;

replication
{
    reliable if ( bNetDirty && ( Role == ROLE_Authority ) )
        ToNextKeg, ToNextBelt, ToNextUDamage, ToNextArmorA, ToNextArmorB, ToNextArmorC,
        bHasArmorA, bHasArmorB, bHasArmorC, bHasBelt, bHasKeg, bHasUD,
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
  local bool bUDDisabled;
  local bool bUTCompEnabled;
  local array<string> tmp1, tmp2;
  local Mutator Mut;

  foreach DynamicActors(class'Mutator',Mut)
  {
    if (Left(Mut.FriendlyName, 6) ~= "UTComp")
       bUTCompEnabled = True;
  }

  if (Level.NetMode != NM_Client);
     MatchStartTime = Level.GRI.ElapsedTime;

  Reset();

  bUDDisabled = bUTCompEnabled && !bool(ConsoleCommand("get MutUTComp bEnableDoubleDamage"));

  Split(Level,".",tmp1);

  foreach AllActors( class'xPickupBase', pickup )
  {
    // really ugly hack for the game not cleaning up pickups from the previous map
    Split(pickup, ".",tmp2);
    if (tmp2[0] == tmp1[0]){
    
//         Log("[LSpec] Found pickup:"@pickup);
         if ( UDamageCharger(pickup) !=  None && !bUDDisabled ){
            bHasUD = True;
         }
         if ( ShieldCharger(pickup) !=  None ){
            if ( ShieldPack(ShieldCharger(pickup).myPickup).ShieldAmount == 50){
                if (bHasArmorA){
                    bHasArmorB = True;
                    ShieldPackB = ShieldPack(ShieldCharger(pickup).myPickup);
//                    Log("[LSpec] ShieldPackB set to Shield Pack"@pickup@"with ShieldAmount of"@ShieldPack(ShieldCharger(pickup).myPickup).ShieldAmount);
                }
                else {
                    bHasArmorA = True;
                    ShieldPackA = ShieldPack(ShieldCharger(pickup).myPickup);
//                    Log("[LSpec] ShieldPackA set to Shield Pack"@pickup@"with ShieldAmount of"@ShieldPack(ShieldCharger(pickup).myPickup).ShieldAmount);
                }
            }                
         }
         // hate the hack, but there's no other way to catch the 25A pickups
         if ((Left(tmp2[1], 19) == "MediumShieldCharger" || Left(tmp2[1], 21) == "GameTypePickupCharger") && ShieldPack(pickup.myPickup) != None){
                bHasArmorC = True;
                ShieldPackC = ShieldPack(pickup.myPickup);
//                Log("[LSpec] ShieldPackC set to Shield Pack"@pickup@" with ShieldAmount of "@ShieldPack(pickup.myPickup).ShieldAmount );
         }
         if ( SuperShieldCharger(pickup) !=  None ){
            bHasBelt = True;
         }
         if ( SuperHealthCharger(pickup) !=  None ){
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

  if (Level.NetMode == NM_Client || Level.NetMode == NM_Standalone){
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
    

   if (Level.NetMode != NM_Client && bHasKeg){
       if (LastKegTime == 9999){ // workaround for the first pickup of the match
          ToNextKeg = 27 - Level.GRI.ElapsedTime;
       }
       else
          ToNextKeg = (LastKegTime + 55) - Level.GRI.ElapsedTime;
   }

   if (Level.NetMode != NM_Client && bHasUD){
       if (LastUDamageTime == 9999){
          ToNextUDamage = 27 - Level.GRI.ElapsedTime;
       }
       else
          ToNextUDamage = (LastUDamageTime + 82) - Level.GRI.ElapsedTime;
   }

   if (Level.NetMode != NM_Client && bHasBelt){
       if (LastBeltTime == 9999){
          ToNextBelt = 27 - Level.GRI.ElapsedTime;
       }
       else
          ToNextBelt = (LastBeltTime + 55) - Level.GRI.ElapsedTime;
   }

   if (Level.NetMode != NM_Client && bHasArmorA)
      ToNextArmorA = (LastArmorTimeA + 27.5) - Level.GRI.ElapsedTime;

   if (Level.NetMode != NM_Client && bHasArmorB)
      ToNextArmorB = (LastArmorTimeB + 27.5) - Level.GRI.ElapsedTime;
      
   if (Level.NetMode != NM_Client && bHasArmorC)
      ToNextArmorC = (LastArmorTimeC + 27.5) - Level.GRI.ElapsedTime;
      

}

function Reset(){
   local LinkedSpecInfo LRI;

   bOvertime = false;
   LastKegTime = 9999;
   LastBeltTime = 9999;
   LastUDamageTime = 9999;
   LastArmorTimeA = 0;
   LastArmorTimeB = 0;
   LastArmorTimeC = 0;
   ShieldPackA = None;
   ShieldPackB = None;
   ShieldPackC = None;
   bHasArmorA = false;
   bHasArmorB = false;
   bHasArmorC = false;

//   Log("LSpecReplication was reset");

   foreach DynamicActors( class'LinkedSpecInfo', LRI )
   {
     LRI.Reset();
   }
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
      SpecOverlay = DuelSpecOverlay(LocalPlayer.Player.InteractionMaster.AddInteraction("LSpec_v115.DuelSpecOverlay", LocalPlayer.Player));
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
  bhasArmorA = False;
  bhasArmorB = False;
  bhasArmorC = False;
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

function Pawn GetPawnFor(PlayerReplicationInfo PRI){
    local Pawn Pawn;

    foreach DynamicActors(class'Pawn', Pawn){
       Pawn.LastRenderTime = Level.TimeSeconds;
       if (Pawn.PlayerReplicationInfo != None && Pawn.PlayerReplicationInfo == PRI)
          return Pawn;
    }
}

defaultproperties {
LastKegTime = 9999;
LastBeltTime = 9999;
LastUDamageTime = 9999;
LastArmorTimeA = 0;
LastArmorTimeB = 0;
LastArmorTimeC = 0;
ToNextKeg = 9999;
ToNextBelt = 9999;
ToNextUDamage = 9999;
ToNextArmorA = 9999;
ToNextArmorB = 9999;
ToNextArmorC = 9999;
}


