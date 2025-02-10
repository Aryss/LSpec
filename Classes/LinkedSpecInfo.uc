// ============================================================================
// LinkedSpecInfo for DuelSpecOverlay
// Copyright 2024 by _Lynx <aryss.skahara at gmail.com>
//
// Tracks player specific info
// ============================================================================
class LinkedSpecInfo extends LinkedReplicationInfo;

var Pawn PlayerPawn;
var PlayerReplicationInfo PRI; // easy reference to the owner PRI
var MutSpecPlus SpecMutator;
var bool bAllow;
var int CheckDelay;

var float LastDamageTime;
var class<DamageType> LastDamageType;
var int AggregatedDamage;
var int LastDmgSlot;


// generic
var byte PawnShield;
var byte PawnHP;
var byte Kills;
var int UDamageTime;
var int DamageDone;
var int DamageRecieved;
var int SelfDamage;

// pickups
var int UDTimeTotal;
var int ShieldTotal;
var int HPTotal;
var int VialsCount;
var byte HPCount;
var byte KegCount;
var byte ShieldCount;
var byte BeltCount;
var byte UDcount;

// incoming damage tracking
struct DamageInfo
{
    var int Damage;
    var string Desc;
    var bool bSelf;
};

var DamageInfo DamageLog[5];

//weapons
var byte CurWeap;
var int hasBio,
         hasASMD,
         hasLink,
         hasMini,
         hasFlak,
         hasRocket,
         hasLG,
         hasSniper;

replication
{
	// Things the server should send to the client.
	reliable if ( bNetDirty && (Role == Role_Authority) )
        bAllow,
		PawnShield, PawnHP, Kills,
        UDamageTime, UDTimeTotal, ShieldTotal,HPTotal,
        VialsCount, KegCount, HPCount, ShieldCount, BeltCount, UDCount,
        curWeap, hasBio,hasASMD,hasLink,hasMini,hasFlak,hasRocket,hasLG,hasSniper,
        DamageLog, DamageDone, DamageRecieved, SelfDamage;
}


// ============================================================================
// PostNetBeginPlay
//
// Getting Local PC, start timer.
// ============================================================================
simulated event PostNetBeginPlay()
{
    SetTimer(0.1,true);
    LastDmgSlot = 0;
}


// ============================================================================
// Timer
//
// Gets the relevant pawn to monitor HP and Shield
// ============================================================================
simulated function Timer()
{
  local Pawn testPawn;
  local Weapon W;
  local Inventory Inv;
  local int Count;
  local byte tmpCurWeap;
  local float AmmoMax, AmmoCur;

  if (Level.NetMode == NM_Client || PRI == None )
     return;

  if ((Level.TimeSeconds - LastDamageTime) > 1.0 && AggregatedDamage > 0){
     AggregatedDamage = 0;
     Log("Aggregated Damage reset for "@PRI.PlayerName);
     LastDamageType = none;
  }

  if ( PRI.PlayerName == "WebAdmin" || PRI.PlayerName == "DemoRecSpectator" )
     return;


  if (PlayerPawn == None){
    foreach AllObjects(class'Pawn', testPawn){
      if (testPawn.PlayerReplicationInfo != None && testPawn.PlayerReplicationInfo == PRI){
         PlayerPawn = testPawn;
      }
    }
  }

  CheckDelay++;

  if ( CheckDelay == 50 && SpecMutator != None && PRI != None && PRI.bOnlySpectator){
    bAllow = SpecMutator.IsAllowed(PRI.PlayerName);
  }

  tmpCurWeap = 255;

  if (PlayerPawn != None){
     PawnHP = Clamp(PlayerPawn.Health,0,199);
     PawnShield = Clamp(PlayerPawn.ShieldStrength,0,150);
     if (Level.NetMode != NM_Client){
        for( Inv=PlayerPawn.Inventory; Inv!=None; Inv=Inv.Inventory )
        {
            W = Weapon( Inv );
    		Count++;
    		if ( Count > 100 )
    			break;

            if( (W == None) || (W.IconMaterial == None) )
                continue;

            if (BioRifle(W) != None){
               W.GetAmmoCount(AmmoMax,AmmoCur);
               hasBio = AmmoCur;
               if(W == PlayerPawn.Weapon)
                 tmpcurWeap = 1;
            }
            if (ShockRifle(W) != None){
               W.GetAmmoCount(AmmoMax,AmmoCur);
               hasASMD = AmmoCur;
               if(W == PlayerPawn.Weapon)
                 tmpcurWeap = 2;
            }
            if (LinkGun(W) != None){
               W.GetAmmoCount(AmmoMax,AmmoCur);
               hasLink = AmmoCur;
               if(W == PlayerPawn.Weapon)
                 tmpcurWeap = 3;
            }
            if (Minigun(W) != None){
               W.GetAmmoCount(AmmoMax,AmmoCur);
               hasMini = AmmoCur;
               if(W == PlayerPawn.Weapon)
                 tmpcurWeap = 4;
            }
            if (FlakCannon(W) != None){
               W.GetAmmoCount(AmmoMax,AmmoCur);
               hasFlak = AmmoCur;
               if(W == PlayerPawn.Weapon)
                 tmpcurWeap = 5;
            }
            if (RocketLauncher(W) != None){
               W.GetAmmoCount(AmmoMax,AmmoCur);
               hasRocket = AmmoCur;
               if(W == PlayerPawn.Weapon)
                 tmpcurWeap = 6;
            }
            if (SniperRifle(W) != None){
               W.GetAmmoCount(AmmoMax,AmmoCur);
               hasLG = AmmoCur;
               if(W == PlayerPawn.Weapon)
                 tmpcurWeap = 7;
            }
            if (ClassicSniperRifle(W) != None){
               W.GetAmmoCount(AmmoMax,AmmoCur);
               hasSniper = AmmoCur;
               if(W == PlayerPawn.Weapon)
                 tmpcurWeap = 8;
            }
            curWeap = tmpcurWeap;
        }

        if (xPawn(PlayerPawn) != None)
           UDamageTime = xPawn(PlayerPawn).UDamageTime - Level.TimeSeconds;
     }

  }



  if (Level.NetMode != NM_Client && PRI != None){
     Kills = PRI.Kills;
  }

}

function MatchStarting(){
   Reset();
}

function ProcessDamage(int Damage, class<DamageType> DamageType,bool bSelfDamage){

  if ( (Level.TimeSeconds - LastDamageTime) < 1.0 && IsContinuous(DamageType) && DamageType == LastDamageType && DamageType != None){
     AggregatedDamage += Damage;
     DamageLog[LastDmgSlot].Damage = AggregatedDamage;
     DamageLog[LastDmgSlot].Desc = GetReadableNameFor(DamageType);
     DamageLog[LastDmgSlot].bSelf = bSelfDamage;
  }
  else {
     if (LastDmgSlot == 0){
       DamageLog[LastDmgSlot].Damage = Damage;
       DamageLog[LastDmgSlot].Desc = GetReadableNameFor(DamageType);
       DamageLog[LastDmgSlot].bSelf = bSelfDamage;
       LastDmgSlot++;
     }
     else if (LastDmgSlot < 4){
       DamageLog[LastDmgSlot].Damage = Damage;
       DamageLog[LastDmgSlot].Desc = GetReadableNameFor(DamageType);
       DamageLog[LastDmgSlot].bSelf = bSelfDamage;
       LastDmgSlot++;
     }
     else {
       DamageLog[0] = DamageLog[1];
       DamageLog[1] = DamageLog[2];
       DamageLog[2] = DamageLog[3];
       DamageLog[3] = DamageLog[4];
       DamageLog[LastDmgSlot].Damage = Damage;
       DamageLog[LastDmgSlot].Desc = GetReadableNameFor(DamageType);
       DamageLog[LastDmgSlot].bSelf = bSelfDamage;
     }

  }

  LastDamageTime = Level.TimeSeconds;
  LastDamageType = DamageType;
}

function bool IsContinuous(class<DamageType> DamageType){
  if (DamageType == class'DamTypeAssaultBullet' ||
      DamageType == class'DamTypeLinkPlasma' ||
      DamageType == class'DamTypeLinkShaft' ||
      DamageType == class'DamTypeMinigunAlt' ||
      DamageType == class'DamTypeMinigunBullet' ||
      DamageType == class'DamTypeFlakChunk')
      return true;

  return false;
}

function string GetReadableNameFor(class<DamageType> DamageType){
   if (DamageType == class'Crushed')
      return "CRUSHED";
   else if (DamageType == class'Burned')
      return "BURNED";
   else if (DamageType == class'Drowned')
      return "DROWNED";
   else if (DamageType == class'Corroded')
      return "CORRODED";
   else if (DamageType == class'fell')
      return "FALL";
   else if (DamageType == class'FellLava')
      return "LAVA";
   else if (DamageType == class'Gibbed')
      return "GIBBED";
   else if (DamageType == class'DamTypeAssaultBullet')
      return "ASSAULT";
   else if (DamageType == class'DamTypeAssaultGrenade')
      return "AR GRENADE";
   else if (DamageType == class'DamTypeBioGlob')
      return "BIO";
   else if (DamageType == class'DamTypeFlakChunk')
      return "FLAK";
   else if (DamageType == class'DamTypeFlakShell')
      return "FLAK SHELL";
   else if (DamageType == class'DamTypeLinkPlasma')
      return "LINK";
   else if (DamageType == class'DamTypeLinkShaft')
      return "LINK ALT";
   else if (DamageType == class'DamTypeMinigunAlt')
      return "MINI SEC";
   else if (DamageType == class'DamTypeMinigunBullet')
      return "MINI PRI";
   else if (DamageType == class'DamTypeRedeemer')
      return "DEEMER";
   else if (DamageType == class'DamTypeRocket')
      return "ROCKET";
   else if (DamageType == class'DamTypeRocketHoming')
      return "RL HOMING";
   else if (DamageType == class'DamTypeShieldImpact')
      return "SHIELD GUN";
   else if (DamageType == class'DamTypeShockBall')
      return "SHOCK ALT";
   else if (DamageType == class'DamTypeShockBeam')
      return "SHOCK";
   else if (DamageType == class'DamTypeShockCombo')
      return "COMBO";
   else if (DamageType == class'DamTypeSniperHeadShot')
      return "LG HEADSHOT";
   else if (DamageType == class'DamTypeSniperShot')
      return "LG";
   else if (DamageType == class'DamTypeTeleFrag')
      return "TELEFRAG";
   else if (DamageType == class'DamTypeClassicHeadshot')
      return "SNIPER HS";
   else if (DamageType == class'DamTypeClassicSniper')
      return "SNIPER";
   else
      return "UNKNOWN";
}

simulated function Reset(){
  local int i;

  PawnShield = 0;
  PawnHP = 0;
  Kills = 0;
  UDamageTime = 0;
  UDTimeTotal = 0;
  ShieldTotal = 0;
  HPTotal = 0;
  VialsCount = 0;
  HPCount = 0;
  KegCount = 0;
  ShieldCount = 0;
  BeltCount = 0;
  UDcount = 0;
  hasBio = -1;
  hasASMD = -1;
  hasLink = -1;
  hasMini = -1;
  hasFlak = -1;
  hasRocket = -1;
  hasLG = -1;
  hasSniper = -1;
  LastDamageTime = 0;
  DamageDone = 0;
  DamageRecieved = 0;
  SelfDamage = 0;

  for (i = 0; i < 5; i++){
     DamageLog[i].Damage = 0;
     DamageLog[i].Desc = "";
  }
  Log("LinkedSpecReplication for"@PRI.PlayerName@"was reset");
}

function Died(){
  hasBio = -1;
  hasASMD = -1;
  hasLink = -1;
  hasMini = -1;
  hasFlak = -1;
  hasRocket = -1;
  hasLG = -1;
  hasSniper = -1;
}

DefaultProperties
{
  hasBio = -1;
  hasASMD = -1;
  hasLink = -1;
  hasMini = -1;
  hasFlak = -1;
  hasRocket = -1;
  hasLG = -1;
  hasSniper = -1;
}
