//-----------------------------------------------------------
// Controller with a set of Spectating QoL features for broadcasting
//
//-----------------------------------------------------------
class LSController extends xPlayer config(LSpec);

var bool bVerbose;

var bool bIsAttractMode;
var bool bStaticCamera;
var bool bChaseCamera;

var int TotalPlayers;
var Pawn LSattracttarget;
var Pawn LStargetenemy;
var Controller LConList;
var vector CameraFocus;
var vector CameraLocation;
var rotator DebugRotation;

replication
{

    // Things the server should send to the client.
    reliable if( Role == ROLE_Authority )
        DebugRotation, LOSto, UpdateFOV, ClientFindFreeCam;

    reliable if( Role == ROLE_Authority && bNetDirty )
        LConList, CameraFocus, TotalPlayers, LSattracttarget, bIsAttractMode, LStargetenemy, bStaticCamera, bChaseCamera;

	// client to server
	reliable if ( Role < ROLE_Authority )
		ServerAttract, ServerEndAttract, ServerPickNextPlayer;

   	reliable if ( Role < ROLE_Authority && bNetDirty)
        CameraLocation;
}

exec function GoTV(){
  ServerAttract();
}

function ServerAttract(){
  if (!IsSpectating())
    return;

  bIsAttractMode = True;
  GotoState('TVMode');
}

exec function EndTV(){
  ServerEndAttract();
}

function ServerEndAttract(){
  bIsAttractMode = false;
  GotoState('Spectating');
  bBehindView = true;
  ServerSpectate();
  ServerViewNextPlayer();
}

state TVMode extends Spectating
{
	ignores SwitchWeapon, RestartLevel, ClientRestart, Suicide,
	 ThrowWeapon, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange;

	function bool IsSpectating()
	{
		return true;
	}

    function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
    {
        Acceleration = NewAccel;
        MoveSmooth(SpectateSpeed * Normal(Acceleration) * DeltaTime);
    }

    function PlayerMove(float DeltaTime)
    {
        local vector X,Y,Z;
	    local float deltayaw, destyaw;
        local Rotator newrot;

        if ( LSattracttarget == None )
			return;

        // updates camera yaw to smoothly rotate to the pawn facing
        if ( bChaseCamera )
        {
			if ( bBehindView ){
/*               (LSattracttarget.Controller == None)
//               || (LSattracttarget.Controller.Enemy == None)
               )
				return;
            NewRot = Rotator(LStargetenemy.location - LSattracttarget.location);
			destyaw = NewRot.Yaw;
            deltayaw = (destyaw & 65535) - (rotation.yaw & 65535);
            if (deltayaw < -32768) deltayaw += 65536;
            else if (deltayaw > 32768) deltayaw -= 65536;

            newrot = rotation;
            newrot.yaw += deltayaw * DeltaTime;
            DebugRotation = newrot;
            ClientSetRotation(newrot);  */
                NewRot = LSattracttarget.rotation;
                NewRot.Pitch = NewRot.Pitch-4000;
                destyaw = NewRot.Yaw;
                deltayaw = (destyaw & 65535) - (rotation.yaw & 65535);
                if (deltayaw < -32768) deltayaw += 65536;
                else if (deltayaw > 32768) deltayaw -= 65536;

                newrot = rotation;
                newrot.yaw += deltayaw * DeltaTime;
                ClientSetRotation(newrot);
            }
            else {
                 if ( (Pawn(ViewTarget) != None) && (Level.NetMode == NM_Client) )
                 {
                    if ( Pawn(ViewTarget).bSimulateGravity )
                       TargetViewRotation.Roll = 0;
                    BlendedTargetViewRotation.Pitch = BlendRot(DeltaTime, BlendedTargetViewRotation.Pitch, TargetViewRotation.Pitch & 65535);
                    BlendedTargetViewRotation.Yaw = BlendRot(DeltaTime, BlendedTargetViewRotation.Yaw, TargetViewRotation.Yaw & 65535);
                    BlendedTargetViewRotation.Roll = BlendRot(DeltaTime, BlendedTargetViewRotation.Roll, TargetViewRotation.Roll & 65535);
                 }
                 GetAxes(Rotation,X,Y,Z);
                 Acceleration = 0.02 * (aForward*X + aStrafe*Y + aUp*vect(0,0,1));
                 UpdateRotation(DeltaTime, 1);
            }
        }

        if ( bStaticCamera )
        {
            newrot = CameraFollow(LSattracttarget, DeltaTime);
            DebugRotation = newrot;
            ClientSetRotation(newrot);
        }

        if ( Role < ROLE_Authority ) // then save this move and replicate it
            ReplicateMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
        else
            ProcessMove(DeltaTime, Acceleration, DCLICK_None, rot(0,0,0));
	}

	exec function NextWeapon()
	{
	}

	exec function PrevWeapon()
	{
	}

	exec function Fire( optional float F )
	{
        // start playing
	}

	exec function AltFire( optional float F )
	{
        Fire(F);
	}

	function BeginState()
	{
		if ( Pawn != None )
		{
			ClientSetLocation(Pawn.Location, Pawn.Rotation);
		}
		bCollideWorld = true;
        if ( curcam == -1 )
        {
            camtime = 0;
            targettime = 0;
            autozoom = true;
            curcam = -1;
        }
        LogD("Starting attract mode");
        Timer();
        SetTimer(0.5, true);
	}

	function EndState()
	{
		PlayerReplicationInfo.bIsSpectator = false;
		bCollideWorld = false;
        curcam = -1;
	}

    function Timer()
    {
        local bool switchedbots;
        local Vector newloc;

        camtime += 0.5;
        targettime += 0.5;
        bFrozen = false;

        if (Role == ROLE_Authority){
            TotalPlayers = Level.Game.NumPlayers + Level.Game.NumBots;
            LConList = Level.ControllerList;
        }


        // keep watching a target for a few seconds after it dies
        if (gibwatchtime > 0)
        {
            gibwatchtime -= 0.5;
            if (gibwatchtime <= 0)
                LSattracttarget = None;
            else
                return;
        }
        else if ( LSattracttarget != None && LSattracttarget.Health <= 0 )
        {
            gibwatchtime = 1;
            //Log("attract: watching gib");
        }

        // switch targets //
        if (LSattracttarget == None
            || targettime > 20 )
        {
            ServerPickNextPlayer(LSattracttarget);
            switchedbots = true;
            targettime = 0;
         }

        if (LSattracttarget == None)
			return;

        if (Role == ROLE_Authority && LSattracttarget.Controller != None)
            LStargetenemy = LSattracttarget.Controller.Enemy;

        // switch views //
        if (
            switchedbots ||
            camtime > 10 ||
            bStaticCamera && (rotation.pitch < -10000 || !LOSto(LSattracttarget))
        )
        {
            camtime = 0;
            FovAngle = default.FovAngle;
            SetViewTarget(self);
	    	bBehindView = false;
	    	bStaticCamera = false;
	    	bChaseCamera = false;

	    	if (Role < ROLE_Authority){

               // use a floating camera
               if (FRand() < 0.9)
               {
                  ClientFindFreeCam(LSattracttarget);
                  CameraFocus = LSattracttarget.Location;
                  curcam = -1;
                  ClientSetLocation(CameraLocation, LSattracttarget.Rotation);
                  ClientSetRotation(CameraFollow(LSattracttarget, 0));
                  LogD("[LSpec] attract: free camera");
                  bStaticCamera = true;
               }
               // chase mode
               else
               {
                   curcam = -1;
                   ClientSetViewTarget(LSattracttarget);
                   if (FRand() < 0.5){
                      bBehindView = true;
                   }
                   else{
                      bBehindView = false;
                   }
                   ClientSetBehindView(bBehindView);
                   ClientSetRotation(LSattracttarget.rotation);
//                   CameraDeltaRotation.Pitch = -4000;
                   CameraDist = 7;
                   LogD("[LSpec] attract: chase camera");
                   bChaseCamera = true;
               }
            }
            else if (Role == ROLE_Authority){
                if (bStaticCamera){
                   ClientSetLocation(CameraLocation, LSattracttarget.Rotation);
                   ClientSetRotation(CameraFollow(LSattracttarget, 0));
                   LogD("[LSpec] Cam Location:"@CameraLocation);
                }
            }
        }
    }
}

function Vector ClientFindFreeCam(Pawn target)
{
    local Vector v1, v2, d;
    local Rotator r;
    local Vector hitloc, hitnormal;
    local Actor hitactor;
    local int tries;

    while (tries++ < 10)
    {
        v1 = target.Location;
        r = target.Rotation;
        r.Pitch = FRand()*12000 - 2000;
        if (VSize(target.Velocity) < 100)
            r.Yaw += FRand()*24000;
        else
            r.Yaw += FRand()*12000;
        d = Vector(r);
        v2 = v1 + d*2000;
        v1 += d*50;

        hitactor = Trace(hitloc, hitnormal, v2, v1, false);

        if (hitactor != None && VSize(hitloc - v1) > 250)
        {
            return (hitloc - d*50);
        }
    }
    // no good spots found, return something reasonable
    if (hitactor != None)
        CameraLocation = (hitloc - d*50);
    else
        CameraLocation = v2;
}

function bool LOSto(Pawn target)
{
    local vector v1, v2;
    local Vector hitloc, hitnormal;

    v1 = self.location;
    v2 = target.location;
    v2.z += target.eyeheight;
    v2 += Normal(v1 - v2) * 100;
    return (Trace(hitloc, hitnormal, v1, v2, false) == None);
}

function ServerPickNextPlayer(Pawn current)
{
    local Controller con;
    local int b;

    LogD("[LSpec] Looking for new player");
    LogD("[LSpec] Players: "$TotalPlayers);


    if (current != None) con = current.Controller;
    for (b = 0; b < TotalPlayers; b++)
    {
        if (con != None)
           con = con.NextController;
        else {
           con = LConList;
        }

        if ((con.IsA('xPlayer') || con.IsA('Bot')) && con.Pawn != None && !con.Pawn.IsA('ASTurret') && !con.IsInState('PlayerWaiting'))
        {
            LogD("[LSpec] Player found:"$con.PlayerReplicationInfo.PlayerName);
            LSattracttarget = con.Pawn;
            return;
        }
        else {
            LogD("[LSpec] Controller doesn't match criteria");
//            LogD("[LSpec] Is Player:"@string(con.IsA('xPlayer')));
//            LogD("[LSpec] Is Bot:"@string(con.IsA('Bot')));
//            LogD("[LSpec] Has pawn:"@string(con.Pawn != None));
//            LogD("[LSpec] Not a turret:"@string(!con.Pawn.IsA('ASTurret')));
//            LogD("[LSpec] Not waiting:"@string(!con.IsInState('PlayerWaiting')));
        }
    }
}

function UpdateFOV(float newFOV)
{
    FOVAngle = newFOV;
}

function Rotator CameraFollow(Pawn target, float DeltaTime)
{
    local float dist;
    local Vector lead;
    local float minzoomdist, maxzoomdist, viewangle, viewwidth;

    // update focuspoint
    lead = target.location + Vect(0,0,2) * Target.CollisionHeight; // + target.Velocity*0.5;
    dist = VSize(lead - CameraFocus);
    if (dist > 20)
    {
        CameraFocus += Normal(lead - CameraFocus) * dist * DeltaTime * 2.0;
    }

    // adjust zoom within bounds (FovAngle 30-100)
    if (autozoom)
    {
        dist = VSize(Location - target.Location);

        minzoomdist = 600;
        maxzoomdist = 1200;
        viewangle = default.FovAngle;

        if (dist < minzoomdist)
        {
            FovAngle = viewangle;
        }
        else if (dist < maxzoomdist)
        {
            viewwidth = minzoomdist*Tan(viewangle*PI/180 / 2);
            FovAngle = Atan(viewwidth, dist) * 180/PI * 2;
        }

        DesiredFOV = FovAngle;
    }

    return Rotator(CameraFocus - location);
}


simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	Super.DisplayDebug(Canvas, YL, YPos);

    Canvas.SetDrawColor(255, 255, 255);
	Canvas.DrawText("Target:"@LSattracttarget$". Enemy: "$LStargetenemy);
	YPos += YL;
	Canvas.SetPos(4, YPos);
	Canvas.DrawText("Rotation: "$string(Rotator(LStargetenemy.location - LSattracttarget.location)));
	YPos += YL;
    Canvas.SetPos(4, YPos);
	Canvas.DrawText("Delta rotation: "$string(DebugRotation));
	YPos += YL;
    Canvas.SetPos(4, YPos);
	Canvas.DrawText("Current camera time:"@camtime$". Target time:"@self.targettime$". Gib time:"@gibwatchtime);
	YPos += YL;
    Canvas.SetPos(4, YPos);
}

function LogD(string msg){
  if (bVerbose){
     Log(msg);
  }
}


DefaultProperties
{
  bAllActorsRelevant=True
  bVerbose=False
}
