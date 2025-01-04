// ============================================================================
// Game Rules for DuelSpecOverlay
// Copyright 2024 by _Lynx <aryss.skahra at gmail.com>
//
// Intercepts certain game events to tracks them
// ============================================================================
class SpecDataRules extends GameRules;

var LSpecReplicationDuel SpecReplication;


// ============================================================================
// HandleRestartGame
//
// Clean up all the data in case match is restarted
// ============================================================================
function bool HandleRestartGame()
{
    if ( SpecReplication != None)
       SpecReplication.Reset();


	if ( (NextGameRules != None) && NextGameRules.HandleRestartGame() )
		return true;
	return false;
}

function PostBeginPlay()
{
         Log("[Lspec] SpecDataRules added, SpecReplication is"@SpecReplication);
}


// ============================================================================
// OverridePickupQuery
//
// Track pickups, item times, weapons
// ============================================================================
function bool OverridePickupQuery(Pawn Other, Pickup item, out byte bAllowPickup)
{
    local LinkedSpecInfo SpecPRI;
    local bool bWarmup;

    bWarmup = bool(ConsoleCommand("get UTComp_Warmup bInWarmup"));

    SpecPRI = class'LSpecUtil'.static.GetSpecPRI(Other.PlayerReplicationInfo);

	if (SpecPRI != None && Level.GRI.bMatchHasBegun && !bWarmup){
		if(item.IsA('MiniHealthPack') && Other.Health < 199) { // vial
			SpecPRI.VialsCount += 1;
			SpecPRI.HPTotal += 5;
		} else if(item.IsA('HealthPack') && Other.Health < 100) {
			SpecPRI.HPCount += 1;
			SpecPRI.HPTotal += 25;
		} else if(item.IsA('SuperHealthPack') && Other.Health < 199) {
			SpecPRI.KegCount += 1;
			SpecPRI.HPTotal += 100;
			SpecReplication.LastKegTime = Level.GRI.ElapsedTime;
		} else if(item.IsA('ShieldPack') && int(Other.ShieldStrength) < 150) {
			SpecPRI.ShieldCount += 1;
			SpecPRI.ShieldTotal += 50;
			SpecReplication.LastArmorTime = Level.GRI.ElapsedTime;
		} else if(item.IsA('SuperShieldPack') && int(Other.ShieldStrength) < 150) {
			SpecPRI.BeltCount += 1;
			SpecPRI.ShieldTotal += 150;
			SpecReplication.LastBeltTime = Level.GRI.ElapsedTime;
		} else if(item.IsA('UDamagePack')) {
			SpecPRI.UDcount += 1;
			SpecReplication.LastUDamageTime = Level.GRI.ElapsedTime;
		}
	}

    if ( (NextGameRules != None) &&  NextGameRules.OverridePickupQuery(Other, item, bAllowPickup) )
		return true;
	return false;


}

// ============================================================================
// PreventDeath
//
// Track kills, deaths?
// ============================================================================
function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
    local LinkedSpecInfo SpecPRI;
    SpecPRI = class'LSpecUtil'.static.GetSpecPRI(Killed.PlayerReplicationInfo);

    SpecPRI.Died();

    if ( (NextGameRules != None) && NextGameRules.PreventDeath(Killed,Killer, damageType,HitLocation) )
		return true;
	return false;
}

// ============================================================================
// NetDamage
//
// Track damage
// ============================================================================
function int NetDamage( int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{

    local LinkedSpecInfo SpecPRI;
    SpecPRI = class'LSpecUtil'.static.GetSpecPRI(injured.PlayerReplicationInfo);


    SpecPRI.ProcessDamage(Damage,DamageType,(injured == instigatedby));

	if ( NextGameRules != None )
		return NextGameRules.NetDamage( OriginalDamage,Damage,injured,instigatedBy,HitLocation,Momentum,DamageType );
	return Damage;
}

DefaultProperties
{

}
