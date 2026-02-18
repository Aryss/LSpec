// ============================================================================
// DuelSpecOverlay
// Copyright 2024 by _Lynx <aryss.skahra at gmail.com>
//
// Overlay handling drawing of additional spec information
// ============================================================================
class DuelSpecOverlay extends Interaction config(User);

#EXEC OBJ LOAD FILE=UT2003Fonts.utx
#exec OBJ LOAD FILE=HudContent.utx
#exec texture import file=Textures\hp_shield_bars.tga alpha=on lodset=LODSET_Interface
#exec texture import file=Textures\check.tga alpha=on lodset=LODSET_Interface
#exec texture import file=Textures\shield.tga alpha=on lodset=LODSET_Interface
#exec texture import file=Textures\shield25.tga alpha=on lodset=LODSET_Interface
#exec texture import file=Textures\shield50.tga alpha=on lodset=LODSET_Interface
#exec texture import file=Textures\udamage.tga alpha=on lodset=LODSET_Interface
#exec texture import file=Textures\HP.tga alpha=on lodset=LODSET_Interface
#exec texture import file=Textures\keg.tga alpha=on lodset=LODSET_Interface
#exec new truetypefontfactory package=LSpec_v115 name="FontTimer60" fontname="Jost" style=600 height=60 USize=512 VSize=128 Antialias=1 Chars=" 0123456789OT:.-+% " Compression=8 DropShadowX=2 DropShadowY=2
#exec new truetypefontfactory package=LSpec_v115 name="FontTimer52" fontname="Jost" style=600 height=50 USize=512 VSize=128 Antialias=1 Chars=" 0123456789OT:.-+% " Compression=8 DropShadowX=2 DropShadowY=2
#exec new truetypefontfactory package=LSpec_v115 name="FontJost21" fontname="Jost" style=500 height=23 USize=512 VSize=256 YPad=2 Antialias=1 Path=. Wildcard=*.rut Chars=" 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-=[]\\{}|;:',./?><\"¡«°»¿ÀÁÄÈÉÊËÌÍÑÒÓÖÙÚÜßàáâäçèéêëìíîïñòóôöùúûüæøå" Compression=8  DropShadowX=2 DropShadowY=2
#exec new truetypefontfactory package=LSpec_v115 name="FontTimer36" fontname="Jost" style=400 height=36 USize=512 VSize=128 Antialias=1 Chars=" 0123456789OT:.-+ %" Compression=8 DropShadowX=2 DropShadowY=2 Kerning=2
#exec new truetypefontfactory package=LSpec_v115 name="FontJost12" fontname="Jost" style=500 height=13 USize=512 VSize=128 Antialias=1 Path=. Wildcard=*.rut Chars=" 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-=[]\\{}|;:',./?><\"¡«°»¿ÀÁÄÈÉÊËÌÍÑÒÓÖÙÚÜßàáâäçèéêëìíîïñòóôöùúûüæøå" Compression=8 DropShadowX=2 DropShadowY=2

// ' -- this to fix code highlighting, since it breaks due to unpaired symbol in the  line above


var PlayerController PC;
var HUD playerHUD;
var GameReplicationInfo GRI;
var LSpecReplicationDuel SpecRI;
var PlayerReplicationInfo LeftPlayer, RightPlayer;

//var globalconfig array<SpecOverlayPlugin>  ExtraStatsPlugins;


var globalconfig Font MidFont,
                      BigFont,
                      ClockFont,
                      SmallFont,
                      DMGFont,
                      ScoreFont,
                      PlayerFont;

var float screenMidX;
var float screenMaxY;
var float LastInfoSwitch;
var float ToNextKeg,
          ToNextUD,
          ToNextShieldA,
          ToNextShieldB,
          ToNextShieldC,
          ToNextBelt;

var globalconfig float X1, X2, Y1, Y2; // debug to adjust item positions live without recompiling

var bool bInitialLog;
var bool bDisplayOverlay;
var bool bOvertime;
var bool bHideArmor;
var bool bXray;
var bool bDisabled;
var int OvertimeStart;
var int InfoMode;  // 0 - hidden, 1 - weapons, 2 - accuracy, 3 - pickups
var int ShowName;  // 0 - don't show, 1 - show at the side alternating, 2 - show in the middle

var globalconfig byte BestOf;
var globalconfig byte ScoreLeft;
var globalconfig byte ScoreRight;
var globalconfig bool bExtraScoreData;

// ============================================================================
// Events to initialize values at the start and safely remove the overlay at
// the end of the match
// ============================================================================

event Initialized()
{
    PC = ViewportOwner.Actor;
    playerHUD = ViewportOwner.Actor.myHUD;
    GRI = PC.GameReplicationInfo;
    bDisplayOverlay = True;
//    LoadPlugins();
}

event NotifyLevelChange()
{
  SaveConfig();
  Master.RemoveInteraction(self);
}

// ============================================================================
// SwapSides
//
// Swaps the players Left <=> Right
// ============================================================================
function SwapSides(){
  local PlayerReplicationInfo tempPRI;
  tempPRI = LeftPlayer;
  LeftPlayer = RightPlayer;
  RightPlayer = tempPRI;
}


// ============================================================================
// EXEC FUNCTIONS
// ============================================================================


// ============================================================================
// KEY PRESS EVENTS
// ============================================================================

function bool KeyEvent(out EInputKey InputKey, out EInputAction InputAction, float Delta)
{
  if (InputKey == IK_Y && InputAction == IST_Press){
     SwapSides();
  }
  
  if (InputKey == IK_U && InputAction == IST_Press){
     if ( ShowName == 2 )
        ShowName = 0;
     else
        ShowName += 1;
  }  

  if (InputKey == IK_X && InputAction == IST_Press){
     bXRay = !bXray;
     Log("[LSpec] toggling X-Ray");
  }

  if (InputKey == IK_I && InputAction == IST_Press){
     bExtraScoreData = !bExtraScoreData;
  }

  if (InputKey == IK_O && InputAction == IST_Press){
     LastInfoSwitch = PC.Level.GRI.ElapsedTime;
     if ( InfoMode == 3 )
        InfoMode = 1;
     else
        InfoMode += 1;
  }

  if (InputKey == IK_P && InputAction == IST_Press){
        InfoMode = 0;
  }

  if (InputKey == IK_Comma && InputAction == IST_Press){
     if ( BestOf == 3 ){
        if (scoreLeft == 0)
           scoreLeft = 1;
        else if (scoreLeft == 1)
           scoreLeft = 2;
        else if (scoreLeft == 2)
           scoreLeft = 0;
     }
     if ( BestOf == 5 ){
        if (scoreLeft == 0)
           scoreLeft = 1;
        else if (scoreLeft == 1)
           scoreLeft = 2;
        else if (scoreLeft == 2)
           scoreLeft = 3;
        else if (scoreLeft == 3)
           scoreLeft = 0;
     }
     if ( BestOf == 7 ){
        if (scoreLeft == 0)
           scoreLeft = 1;
        else if (scoreLeft == 1)
           scoreLeft = 2;
        else if (scoreLeft == 2)
           scoreLeft = 3;
        else if (scoreLeft == 3)
           scoreLeft = 4;
        else if (scoreLeft == 4)
           scoreLeft = 0;
     }
     SaveConfig();
  }

  if (InputKey == IK_Period && InputAction == IST_Press){
     if ( BestOf == 3 ){
        if (ScoreRight == 0)
           ScoreRight = 1;
        else if (ScoreRight == 1)
           ScoreRight = 2;
        else if (ScoreRight == 2)
           ScoreRight = 0;
     }
     if ( BestOf == 5 ){
        if (ScoreRight == 0)
           ScoreRight = 1;
        else if (ScoreRight == 1)
           ScoreRight = 2;
        else if (ScoreRight == 2)
           ScoreRight = 3;
        else if (ScoreRight == 3)
           ScoreRight = 0;
     }
     if ( BestOf == 7 ){
        if (ScoreRight == 0)
           ScoreRight = 1;
        else if (ScoreRight == 1)
           ScoreRight = 2;
        else if (ScoreRight == 2)
           ScoreRight = 3;
        else if (ScoreRight == 3)
           ScoreRight = 4;
        else if (ScoreRight == 4)
           ScoreRight = 0;
     }
     SaveConfig();
  }

  if (InputKey == IK_Slash && InputAction == IST_Press){
     if ( BestOf == 1 )
        BestOf = 3;
     else if ( BestOf == 3 )
        BestOf = 5;
     else if ( BestOf == 5 )
        BestOf = 7;
     else if ( BestOf == 7 )
        BestOf = 1;
     SaveConfig();
  }

  return Super.KeyEvent(InputKey, InputAction, Delta);
}

// ============================================================================
// PostRender
//
// Lets start rendering all the things! Most of the functionality is plit into
// subfunctions for ease of reading
// ============================================================================
function PostRender( canvas Canvas )
{
  if (!PC.PlayerReplicationInfo.bOnlySpectator){
       PC.myHUD.bHideHUD = false;
       PC.myHUD.bCrosshairShow = true;
       Master.RemoveInteraction(self);
       bDisabled = true;
       bDisplayOverlay = false;
  }

  screenMidX = Canvas.SizeX/2;
  screenMaxY = Canvas.SizeY;
  if (!bInitialLog){
     Log("[LSpec] Screen res: "$Canvas.SizeX$"x"$Canvas.SizeY$"; screenMidX = "$screenMidX);
     Log("[LSpec] Overlay spawned, overlay SRI reference set to "$SpecRI);
     bInitialLog = True;
  }

  Canvas.SetDrawColor(255,255,255);
  Canvas.Font = SmallFont;
  Canvas.SetPos(60, canvas.SizeY/2);
//  Canvas.DrawTile(Texture'HudContent.Generic.HUD', -64, 64, 2, 247, 68, 68);
//  if (SpecRI != none)
//     Canvas.DrawText("LastBeltTime:"@SpecRI.LastBeltTime$"; Time to next:"@((SpecRI.LastBeltTime + 55) - PC.Level.GRI.ElapsedTime));

  // draw HUD when we open scoreboard and hide it when we close it
  if (bDisplayOverlay)
  {
     PC.myHUD.bHideHUD = !PC.myHUD.bShowScoreBoard;
  }
  else {
     PC.myHUD.bHideHUD = false;
  }

  PC.myHUD.bCrosshairShow = !PC.bBehindView;

  if(!PC.myHUD.bShowScoreBoard && bDisplayOverlay){

      HudBase(PC.myHUD).DisplayLocalMessages(Canvas);
      PC.myHUD.DisplayMessages(Canvas);

      DrawBackground(Canvas);
      DrawTimer(Canvas);
      DrawSeriesScore(Canvas);
      TryDrawCenteredName(Canvas);

      if (LeftPlayer != None){
         DrawLeftPlayerHP(Canvas);
         DrawLeftPlayerShield(Canvas);
         DrawLeftPlayerScore(Canvas);
         DrawLeftPlayerName(Canvas);
         DrawNumericalHPShieldUD(LeftPlayer, Canvas);
         if (bExtraScoreData)
            DrawLeftPlayerExtraData(Canvas);
         if (InfoMode == 1)
            DrawLeftWeapons(Canvas);
         if (InfoMode == 2)
            DrawLeftPickups(Canvas);
//            DrawNumericalHPShieldUD(LeftPlayer, Canvas);
//         if (InfoMode == 3)
//            DrawLeftAccuracy(Canvas);


         DrawLeftPlayerDmgLog(Canvas);
      }
      else {
         DrawWaitingFor(0,Canvas);
      }
      if (RightPlayer != None){
         DrawRightPlayerHP(Canvas);
         DrawRightPlayerShield(Canvas);
         DrawRightPlayerScore(Canvas);
         DrawRightPlayerName(Canvas);
       DrawNumericalHPShieldUD(RightPlayer, Canvas);
         if (bExtraScoreData)
            DrawRightPlayerExtraData(Canvas);
         if (InfoMode == 1)
            DrawRightWeapons(Canvas);
         if (InfoMode == 2)
            DrawRightPickups(Canvas);
//            DrawNumericalHPShieldUD(RightPlayer, Canvas);
//         if (InfoMode == 3)


         DrawRightPlayerDmgLog(Canvas);
      }
      else {
         DrawWaitingFor(1,Canvas);
      }

      if (SpecRI != None){
         DrawPickupTimers(Canvas);
      }

      if (bXRay){
         DrawPawn(Canvas, LeftPlayer);
         DrawPawn(Canvas, RightPlayer);
      }
  }

}

// ============================================================================
// DrawBackground
//
// Draws the dark semitransparent background for clock, HP/shields and
// playernames
// midX - 687
// width - 1374
// height - 124
// ============================================================================
function DrawBackground(Canvas C){

  C.SetDrawColor(0,0,0);
  C.SetPos(screenMidX - 1374/2,0);
  C.DrawTile(Texture'HudContent.Generic.HUD', 1374, 124, 173, 211, 162, 47);
}

// ============================================================================
// DrawTimer
//
// Draws the match timer and the Overtime text underneath
// ============================================================================
function DrawTimer(Canvas C){
  local int TimeLeft, Minutes, Seconds;
  local string MinuteValue, SecondsValue;
  local float XL, YL;

  // calculate time
  TimeLeft = PC.GameReplicationInfo.RemainingTime;

  if (PC.GameReplicationInfo.RemainingTime == 1)
     OvertimeStart = PC.Level.TimeSeconds+1;

  if (bOvertime){
     TimeLeft = PC.Level.TimeSeconds - OvertimeStart;
  }


  Minutes = TimeLeft / 60;
  Seconds = TimeLeft - Minutes * 60;
  SecondsValue = string(Seconds);
  MinuteValue = string(Minutes);

  // add leading zeroes to seconds and minutes
  if (Minutes < 10)
     MinuteValue = "0"$Minutes;
  if (Seconds < 10)
     SecondsValue = "0"$Seconds;

  C.Font = ClockFont;
  C.StrLen("15:55", XL, YL);
  C.SetPos(screenMidX - XL/2, 30);
  C.SetDrawColor(255,255,255);
  C.DrawText(MinuteValue$":"$SecondsValue);

  // draw OT msg
  if (SpecRI != None){
     bOvertime = SpecRI.bOvertime;
     if (SpecRI.bOvertime){
       C.Font = PlayerFont;
       C.StrLen("OVERTIME", XL, YL);
       C.SetPos(screenMidX - XL/2, 125);
       C.DrawText("OVERTIME");
     }
  }
}

// ============================================================================
// DrawSeriesScore
//
// Draws the graphics showing best of type and series score
// Offsets:
// X: screenMidX
// Y: 10
// ============================================================================
function DrawSeriesScore(Canvas C){
  local float XL, YL;
  local float PosX, PosY; // transient vars to add elements with relative positioning within the same widget

  // Draw the series info text
  C.SetDrawColor(255,255,255);
  C.Font = SmallFont;
  C.StrLen("BO"$BestOf@"G"$(ScoreLeft+ScoreRight+1),XL,YL);
  PosY = 10 + YL/2 - 12;
  C.SetPos(screenMidX - XL/2,10);
  C.DrawText("BO"$BestOf@"G"$(ScoreLeft+ScoreRight+1));

  // draw left score, from inside to outside
  PosX = screenMidX - 87;
  if (bestOf == 3 || bestOf == 5 || bestOf == 7){
     // first circle
     C.SetPos(PosX - 24,PosY);
     if (ScoreLeft == 0)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 0, 64, 64);
     if (ScoreLeft > 0)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 64, 64, 64);
     // 2nd circle
     C.SetPos(PosX-56,PosY);
     if (ScoreLeft <= 1)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 0, 64, 64);
     if (ScoreLeft > 1)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 64, 64, 64);
  }
  if (bestOf == 5 || bestOf == 7){
     // third circle
     C.SetPos(PosX-88,PosY);
     if (ScoreLeft <= 2)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 0, 64, 64);
     if (ScoreLeft > 2)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 64, 64, 64);
  }
  if (bestOf == 7){
     // fourth circle
     C.SetPos(PosX-120,PosY);
     if (ScoreLeft <= 3)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 0, 64, 64);
     if (ScoreLeft > 3)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 64, 64, 64);
  }

  // draw right score, from inside to outside
  PosX = screenMidX + 87;
  if (bestOf == 3 || bestOf == 5 || bestOf == 7){
     // first circle
     C.SetPos(PosX,PosY);
     if (ScoreRight == 0)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 0, 64, 64);
     if (ScoreRight > 0)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 64, 64, 64);
     // 2nd circle
     C.SetPos(PosX+32,PosY);
     if (ScoreRight <= 1)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 0, 64, 64);
     if (ScoreRight > 1)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 64, 64, 64);
  }
  if (bestOf == 5 || bestOf == 7){
     // third circle
     C.SetPos(PosX+64,PosY);
     if (ScoreRight <= 2)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 0, 64, 64);
     if (ScoreRight > 2)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 64, 64, 64);
  }
  if (bestOf == 7){
     // fourth circle
     C.SetPos(PosX+96,PosY);
     if (ScoreRight <= 3)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 0, 64, 64);
     if (ScoreRight > 3)
        C.DrawTile(Texture'LSpec_v115.check', 24, 24, 0, 64, 64, 64);
  }


}

// ============================================================================
// DrawLeftPlayerScore
//
// Draws left player score, optionally their Kills/Suisices
// Offsets:
// X: screenMidX - 800
// Y: 20
// ============================================================================
function DrawLeftPlayerScore(Canvas C){

  local float XL, YL;

  C.SetDrawColor(255,255,255);
  C.Font = ScoreFont;
  C.StrLen(int(LeftPlayer.Score), XL, YL);
  C.SetPos(screenMidX - (820 - XL/2), 20);

  C.DrawText(int(LeftPlayer.Score));
}

// ============================================================================
// DrawRightPlayerScore
//
// Draws left player score, optionally their Kills/Suisides
// Offsets:
// X: Mid + 810px - XL
// Y: 54px from top to TopLeft
// ============================================================================
function DrawRightPlayerScore(Canvas C){

  local float XL, YL;

  C.SetDrawColor(255,255,255);
  C.Font = ScoreFont;
  C.StrLen(int(RightPlayer.Score), XL, YL);
  C.SetPos(screenMidX + (790 - XL/2), 20);

  C.DrawText(int(RightPlayer.Score));
}


// ============================================================================
// DrawPawn
//
// Draws left player score, optionally their Kills/Suisides
// Offsets:
// X: Mid + 810px - XL
// Y: 54px from top to TopLeft
// ============================================================================
function DrawPawn(Canvas C, PlayerReplicationInfo PRI){

  local pawn Pawn;

  Pawn = SpecRI.GetPawnFor(PRI);

/*  if (Pawn != None &&
      PC.ViewTarget != None &&
      Pawn(PC.ViewTarget) != None &&
      Pawn(PC.ViewTarget) != Pawn ){*/
  if (Pawn != None){
      C.DrawActor(Pawn, false, true);
  }



}



// ============================================================================
// DrawLeftPlayerExtraData
//
// Draws left player additional data, toggleable by I key.
// Lots of !=None checks because rendring absolutely hates empty references that
// were GC'ed before and crashes when trying to access one.
//
// Offsets:
// X: Mid - 950 (to keep 10px margin of left side on 1920x1080)
// Y: 10
// ============================================================================
function DrawLeftPlayerExtraData (Canvas C){

  local float XL, YL;
  local float PosX, PosY; // transient vars to add elements with relative positioning within the same widget
  local LinkedSpecInfo LeftSpecPRI;

  // set up color and coords
  C.SetDrawColor(255,255,255);
  C.Font = SmallFont;
  PosX = screenMidX - 950;
  PosY = 33;
  C.StrLen("XXX", XL, YL); // get YL once
  LeftSpecPRI = class'LSpecUtil'.static.GetSpecPRI(LeftPLayer);

  if (LeftSpecPRI != None){
     // kills
     C.SetPos(PosX, PosY);
     C.DrawText("KL:"@LeftSpecPRI.Kills);
  }

  if (LeftPlayer != None && LeftSpecPRI != None){
     // suicides
     C.SetPos(PosX, PosY + YL);
     C.DrawText("SC:"@(LeftSpecPRI.Kills - int(LeftPlayer.Score)));
  }

  if (LeftPlayer != None){
     // ping
     C.SetPos(PosX, PosY + YL*2);
     C.DrawText("PN:"@(LeftPlayer.Ping * 4));
     // PL
     C.SetPos(PosX, PosY + YL*3);
     C.DrawText("PL:"@LeftPlayer.PacketLoss);
  }
}

// ============================================================================
// DrawRightPlayerExtraData
//
// Draws right player additional data, toggleable by I key.
// Lots of !=None checks because rendring absolutely hates empty references that
// were GC'ed before and crashes when trying to access one.
//
// Offsets:
// X: Mid + 935 (shoudl keep ~10px margin on the right side on 1920x1080)
// Y: 10
// ============================================================================

function DrawRightPlayerExtraData (Canvas C){

  local float XL, YL;
  local float PosX, PosY; // transient vars to add elements with relative positioning within the same widget
  local LinkedSpecInfo RightSpecPRI;

  C.SetDrawColor(255,255,255);
  C.Font = SmallFont;
  PosX = screenMidX + 885;
  PosY = 33;
  C.StrLen("XXX", XL, YL); // get YL once

  RightSpecPRI = class'LSpecUtil'.static.GetSpecPRI(RightPLayer);

  if (RightSpecPRI != None){
     C.SetPos(PosX, PosY);
     C.DrawText("KL:"@RightSpecPRI.Kills);
  }

  if (RightPlayer != None && RightSpecPRI != None){
     // suicides
     C.SetPos(PosX, PosY + YL);
     C.DrawText("SC:"@(RightSpecPRI.Kills - int(RightPlayer.Score)));
  }

  if (RightPlayer != None){
     // ping
     C.SetPos(PosX, PosY + YL*2);
     C.DrawText("PN:"@(RightPlayer.Ping * 4));
     // PL
     C.SetPos(PosX, PosY + YL*3);
     C.DrawText("PL:"@RightPlayer.PacketLoss);
  }
}

// ============================================================================
// DrawLeftPlayerName
//
// Draws the dark semitransparent background for clock, HP/shields and
// playernames
// midX - 400 - XL/2
// ============================================================================
function DrawLeftPlayerName (Canvas C){

  local float XL, YL, tempXL;

  C.SetDrawColor(255,255,255);
  C.Font = PlayerFont;
  C.StrLen(LeftPlayer.PlayerName, XL, YL);
  C.SetPos(screenMidX - (400 + XL/2), 10);
  C.DrawText(LeftPlayer.PlayerName);

  if (PC.ViewTarget != None &&
      Pawn(PC.ViewTarget) != None &&
      Pawn(PC.ViewTarget).PlayerReplicationInfo != None &&
      Pawn(PC.ViewTarget).PlayerReplicationInfo == LeftPlayer && 
      ShowName == 0
      )
      {
      tempXL = XL/2;
      C.StrLen("[POV]", XL, YL);
      C.SetDrawColor(245,196,0);
      C.SetPos(screenMidX - (430 + tempXL + XL), 10);
      C.DrawText("[POV]");
  }

}

// ============================================================================
// DrawrRightPlayerName
//
// midX - 400 - XL/2
// ============================================================================
function DrawRightPlayerName (Canvas C){

  local float XL, YL, tempXL;

  C.SetDrawColor(255,255,255);
  C.Font = PlayerFont;
  C.StrLen(RightPlayer.PlayerName, XL, YL);
  C.SetPos(screenMidX + (400 - XL/2), 10);
  C.DrawText(RightPlayer.PlayerName);

  if (PC.ViewTarget != None &&
      Pawn(PC.ViewTarget) != None &&
      Pawn(PC.ViewTarget).PlayerReplicationInfo != None &&
      Pawn(PC.ViewTarget).PlayerReplicationInfo == RightPlayer && 
      ShowName == 0 )
      {
      tempXL = XL/2;
      C.StrLen("[POV]", XL, YL);
      C.SetDrawColor(245,196,0);
      C.SetPos(screenMidX + (430 + tempXL), 10);
      C.DrawText("[POV]");
  }

}


// ============================================================================
// DrawLeftPlayerHP
//
// Draws left player HP bar. Needs a rewrite to display base HP and anything
// over as separate bars
// X: midX - (133 + XL)
// Y: 52
// ============================================================================
function DrawLeftPlayerHP(Canvas C){

  local float XL;
  local byte HP;
  local LinkedSpecInfo LeftSpecPRI;


  LeftSpecPRI = class'LSpecUtil'.static.GetSpecPRI(LeftPLayer);

  if (LeftSpecPRI != None)
     HP = LeftSpecPRI.PawnHP;


  if (LeftSpecPRI != None){
      XL = FClamp((287/100)*Min(HP,100),0,287);

      C.SetDrawColor(255,255,255);
      C.SetPos(screenMidX - 133,48);
      C.DrawTile(Texture'LSpec_v115.hp_shield_bars', -XL, 32, 0, 0, XL, 32);

      // drawing extra bar
      if (HP >= 101){
          XL = FClamp((287/99)*Min(HP-100,99),0,287);
          C.SetPos(screenMidX - 396,48);
          C.DrawTile(Texture'LSpec_v115.hp_shield_bars', -XL, 32, 0, 64, XL, 32);
      }
  }
}

// ============================================================================
// DrawRightPlayerHP
//
// Draws right player HP barNeeds a rewrite to display base HP and anything
// over as separate bars
// X: midX - (133 + XL)
// Y: 52
// new X
// ============================================================================
function DrawRightPlayerHP(Canvas C){

  local float XL;
  local byte HP;
  local LinkedSpecInfo RightSpecPRI;

  RightSpecPRI = class'LSpecUtil'.static.GetSpecPRI(RightPLayer);
  if (RightSpecPRI != None)
     HP = RightSpecPRI.PawnHP;

  if (RightSpecPRI != None){
      XL = FClamp((287/100)*Min(HP,100),0,287);

      C.SetDrawColor(255,255,255);
      C.SetPos(screenMidX + 133,48);
      C.DrawTile(Texture'LSpec_v115.hp_shield_bars', XL, 32, 0, 0, XL, 32);

      // drawing extra bar
      if ( HP >= 101 ){
          XL = FClamp( ( 287/99 ) * Min( HP-100 ,99 ), 0, 287 );
          C.SetPos(screenMidX + 396,48);
          C.DrawTile(Texture'LSpec_v115.hp_shield_bars', XL, 32, 0, 64, XL, 32);
      }
  }
}

// ============================================================================
// DrawLeftPlayerShield
//
// Draws the shield bar for the left player
// X: midX - (133 + XL)
// Y: 52
// new X
// ============================================================================
function DrawLeftPlayerShield(Canvas C){

  local float XL, XLs;
  local byte Shield;
  local LinkedSpecInfo LeftSpecPRI;

  LeftSpecPRI = class'LSpecUtil'.static.GetSpecPRI(LeftPLayer);
  if (LeftSpecPRI != None)
     Shield = LeftSpecPRI.PawnShield;

  if (LeftSpecPRI != None){
      XL = FClamp((512/150)*Shield,0,512);
      XLs = XL*0.75;

      C.SetDrawColor(220,220,220);
      C.SetPos(screenMidX - 100,89);
      C.DrawTile(Texture'LSpec_v115.hp_shield_bars', -XLs, 24, 0, 32, XL, 32);
   }
}


// ============================================================================
// DrawRightPlayerShield
//
// Draws the shield bar for the right player
// X: midX - (97 + XL)
// Y: 93
// new X
// ============================================================================
function DrawRightPlayerShield(Canvas C){

  local float XL;
  local byte Shield;
  local LinkedSpecInfo RightSpecPRI;

  RightSpecPRI = class'LSpecUtil'.static.GetSpecPRI(RightPLayer);
  if (RightSpecPRI != None)
     Shield = RightSpecPRI.PawnShield;

  if (RightSpecPRI != None){
      XL = FClamp((512/150)*Shield,0,512);

      C.SetDrawColor(220,220,220);
      C.SetPos(screenMidX + 100,89);
      C.DrawTile(Texture'LSpec_v115.hp_shield_bars', XL*0.75, 24, 0, 32, XL, 32);
  }
}

// ============================================================================
// DrawWaitingFor
//
// Draws "Waiting for Player" text if there are less than 2 PRIs.
// For 0 draws the message on the left side, for 1 on the right
// ============================================================================
function DrawWaitingFor(int Who, Canvas C){
  local float XL, YL;

  C.SetDrawColor(255,255,255);
  C.Font = MidFont;
  C.StrLen("Waiting for player", XL, YL);
  if (Who == 0)
       C.SetPos(screenMidX - (400 + XL/2), 40);
  if (Who == 1)
       C.SetPos(screenMidX + (400 - XL/2), 40);
  C.DrawText("Waiting for player");
}

// ============================================================================
// DrawNumericalHP/Shield
//
// Draws "Now Viewing" under the correct side of the top panel
// ============================================================================

function DrawNumericalHPShieldUD(PlayerReplicationInfo Who, Canvas C){
  local float XL, YL, offsetX;
  local LinkedSpecInfo WhoRI;
  local byte HP, Shield;
  local int UDTime;

  WhoRI = class'LSpecUtil'.static.GetSpecPRI(Who);
  if (WhoRI != None){
     SHield = WhoRI.PawnShield;
     HP = WhoRI.PawnHP;
     UDTime = WhoRI.UDamageTime;
  }

  C.SetDrawColor(255,255,255);
  offsetX = 236;
  C.Font = PlayerFont;
  C.StrLen("199", XL, YL);
  // right player
  if (Who == RightPlayer && WhoRI != None){
       C.Font = PlayerFont;
       C.StrLen("199", XL, YL);
       // HP
       C.SetPos(screenMidX + (offsetX - XL - 45), 125);
       C.DrawIcon( material'LSpec_v115.HP', 0.5 );
       C.SetPos(screenMidX + (offsetX - XL - 10), 125 + 18 - YL/2);
       C.DrawText(HP);
       // shield
       C.SetPos(screenMidX + (offsetX), 125);
       C.DrawIcon( material'LSpec_v115.shield', 0.5 );
       C.SetPos(screenMidX + (offsetX + 37), 125 + 18 - YL/2);
       C.DrawText(Shield);
       //udamage
       if (UDTime > 0){
          C.SetPos(screenMidX + (offsetX + XL + 45), 125);
          C.DrawIcon( material'LSpec_v115.udamage', 0.5 );
          C.SetPos(screenMidX + (offsetX + XL + 85), 125 + 18 - YL/2);
          C.DrawText(UDTime);
       }
  }
  OffsetX = 231;
  // left player
  if (Who == LeftPlayer && WhoRI != None){
       //udamage
       if (WhoRI.UDamageTime > 0){
          C.SetPos(screenMidX - (offsetX + XL*2 + 69), 125);
          C.DrawIcon( material'LSpec_v115.udamage', 0.5 );
          C.SetPos(screenMidX - (offsetX + XL*2 + 25), 125 + 18 - YL/2);
          C.DrawText(UDTime);
       }
       // shield
       C.SetPos(screenMidX - (offsetX + XL + 42), 125);
       C.DrawIcon( material'LSpec_v115.shield', 0.5 );
       C.SetPos(screenMidX - (offsetX + XL), 125 + 18 - YL/2);
       C.DrawText(Shield);
       // hp
       C.SetPos(screenMidX - (offsetX - 5), 125);
       C.DrawIcon( material'LSpec_v115.HP', 0.5 );
       C.SetPos(screenMidX - (offsetX - 40), 125 + 18 - YL/2);
       C.DrawText(HP);
  }
  /*){
       C.SetPos(screenMidX - (300 + XL/2), 125);
       C.DrawText("NOW VIEWING");
       if(*/

}

// ============================================================================
// Shows the player name in the middle of the screen, on by default, turned off using U key
// 
// ============================================================================

function TryDrawCenteredName(Canvas C){
  local float PosX, PosY,
              XL, YL,
              TotalWidth, NameWidth, AmmoWidth;
  local string PlayerName;
  local int ammo;
  local int WT_Top, 
            WT_Left,
            WT_Width,
            WT_Height;
  local LinkedSpecInfo thisPRI;
              
  if (ShowName > 0 && PC.ViewTarget != None && Pawn(PC.ViewTarget) != None){
    PosY = screenMaxY * 0.75;
    ammo = -1;
  
    if (Pawn(PC.ViewTarget).PlayerReplicationInfo != None )
        PlayerName = Pawn(PC.ViewTarget).PlayerReplicationInfo.PlayerName;

    // find relevant specPRI to get current weapon and ammo
    thisPRI = class'LSpecUtil'.static.GetSpecPRI(Pawn(PC.ViewTarget).PlayerReplicationInfo);
    // it's either this or do it in the rendering below
    if (thisPRI.curWeap == 1){
        ammo = thisPRI.hasBio;
        WT_Top = 129;
        WT_Left = 169;
        WT_Width = 78;
        WT_Height = 41;        
    }
    if (thisPRI.curWeap == 2){
        ammo = thisPRI.hasASMD;
        WT_Top = 108;
        WT_Left = 249;
        WT_Width = 81;
        WT_Height = 38;        
    }
    if (thisPRI.curWeap == 3){
        ammo = thisPRI.hasLink;
        WT_Top = 86;
        WT_Left = 169;
        WT_Width = 78;
        WT_Height = 37;        
    }
    if (thisPRI.curWeap == 4){
        ammo = thisPRI.hasMini;
        WT_Top = 80;
        WT_Left = 251;
        WT_Width = 79;
        WT_Height = 28;        
    }
    if (thisPRI.curWeap == 5){
        ammo = thisPRI.hasFlak;
        WT_Top = 173;
        WT_Left = 169;
        WT_Width = 76;
        WT_Height = 34;
    }
    if (thisPRI.curWeap == 6){
        ammo = thisPRI.hasRocket;
        WT_Top = 147;
        WT_Left = 249;
        WT_Width = 80;
        WT_Height = 35;        
    }
    if (thisPRI.curWeap == 7){
        ammo = thisPRI.hasLG;
        WT_Top = 183;
        WT_Left = 249;
        WT_Width = 79;
        WT_Height = 28;        
    }
    if (thisPRI.curWeap == 8){
        ammo = thisPRI.hasSniper;
        WT_Top = 177;
        WT_Left = 427;
        WT_Width = 79;
        WT_Height = 32;        
    }
    if (thisPRI.curWeap == 9){
        ammo = thisPRI.hasAR;
        WT_Top = 40;
        WT_Left = 249;
        WT_Width = 80;
        WT_Height = 37;        
    }
    if (thisPRI.curWeap == 10){
        ammo = thisPRI.hasSG;
        WT_Top = 42;
        WT_Left = 168;
        WT_Width = 74;
        WT_Height = 36;        
    }
  
    // yellow
    C.SetDrawColor(245,196,0);
   
    
    // now viewing block
    C.Font = SmallFont;   
    C.StrLen("NOW VIEWING", XL, YL);
    
    if (ShowName == 1){
        if (Pawn(PC.ViewTarget).PlayerReplicationInfo == LeftPlayer){
            PosX = 300;
        }
        else{
            PosX = C.SizeX - (300 + XL);
        }
    }
    else {
        PosX = screenMidX - XL * 0.5;
    }
    C.SetPos(PosX, PosY - YL);
    C.DrawText("NOW VIEWING");
    
    
    // name block
    // calculate sizes
    C.Font = PlayerFont;
    C.StrLen("XXX", XL, YL);
    AmmoWidth = XL;
    C.StrLen(PlayerName, XL, YL);
    NameWidth = XL;
    TotalWidth = NameWidth + 100 + AmmoWidth;
    // get coordinates based on sizes
    PosY = PosY + YL/2 + 10;
    if (ShowName == 1){
        if (Pawn(PC.ViewTarget).PlayerReplicationInfo == LeftPlayer){
            PosX = 300;
        }
        else{
            PosX = C.SizeX - (300 + TotalWidth);
        }
    }
    else {
        PosX = screenMidX - TotalWidth * 0.5;
    }
    
    // draw
    
    if (ShowName == 1 && Pawn(PC.ViewTarget).PlayerReplicationInfo == RightPlayer){
        C.SetDrawColor(255,255,255);
        C.SetPos(PosX + 80, PosY - WT_Height * 0.5);
        if (thisPRI.curWeap > 0 && ammo >= 0)
            C.DrawTile(Texture'HudContent.Generic.HUD', WT_Width * -1, WT_Height, WT_Left, WT_Top, WT_Width, WT_Height);
        C.SetPos(PosX + 90, PosY - YL * 0.5);        
        if (ammo >= 0 )
            C.DrawText(string(ammo));
        C.SetDrawColor(245,196,0);
        C.SetPos(PosX + 100 + AmmoWidth, PosY - YL * 0.5);
        C.DrawText(PlayerName);
    }
    else {
        C.SetPos(PosX, PosY - YL * 0.5);
        C.DrawText(PlayerName);
        C.SetPos(PosX + NameWidth + 10, PosY - WT_Height * 0.5);
        C.SetDrawColor(255,255,255);
        if (thisPRI.curWeap > 0 && ammo >= 0)
            C.DrawTile(Texture'HudContent.Generic.HUD', WT_Width, WT_Height, WT_Left, WT_Top, WT_Width, WT_Height);
        C.SetPos(PosX + NameWidth + 100, PosY - YL * 0.5);
        if (ammo >= 0 )
            C.DrawText(string(ammo));
    }
  }
  
}

// ============================================================================
// DrawPickupTimers
//
// Draws pickup timers for Keg, Supershield Shield, SHield 50 A & B, 25 shield and Udamage in that order
// Calculates total item number existing on the map, calculates width based on that, tries to draw the list in the middle
// ============================================================================

function DrawPickupTimers(Canvas C){
  local float PosX, PosY,
              XL, YL,
              ItemWidth, Step;
              
              
  local int ItemNum;
  
  Step = 74;
  C.Font = MidFont;
  C.SetDrawColor(255,255,255);

  if (SpecRI != None){
     ToNextKeg    = SpecRI.ToNextKeg;
     ToNextUD     = SpecRI.ToNextUDamage;
     ToNextBelt   = SpecRI.ToNextBelt;
     ToNextShieldA = SpecRI.ToNextArmorA;
     ToNextShieldB = SpecRI.ToNextArmorB;
     ToNextShieldC = SpecRI.ToNextArmorC;
     
     if (SpecRI.bHasKeg)
        ItemNum += 1;
     if (SpecRI.bHasUD)
        ItemNum += 1;
     if (SpecRI.bHasBelt)
        ItemNum += 1;
     if (SpecRI.bHasArmorA)
        ItemNum += 1;
     if (SpecRI.bHasArmorB)
        ItemNum += 1;
     if (SpecRI.bHasArmorC)
        ItemNum += 1;        
  }
  
  
  PosY = C.SizeY - Step;
  
  ItemWidth = ItemNum * Step - 12; //
  PosX = ScreenMidX - ( ItemWidth / 2 ); // for easy adjustment  
  /*  
  C.StrLen("PosX: "$PosX$"; ItemWidth: "$ItemWidth$"; ItemNum: "$ItemNum$"; C.SizeX: "$C.SizeX$"; ScreenMidX:"@ScreenMidX, XL, YL);
  C.SetPos ((C.SizeX / 2) - XL/2, C.SizeY - YL);
  C.DrawText("PosX: "$PosX$"; ItemWidth: "$ItemWidth$"; ItemNum: "$ItemNum$"; C.SizeX: "$C.SizeX$"; ScreenMidX:"@ScreenMidX);
  */
  ItemNum = -1;

  if (SpecRI.bHasKeg)
    ItemNum += 1;

  if (ToNextKeg <= 10 ){
     C.SetPos(PosX + Step * ItemNum, PosY);
     C.DrawTile(Texture'LSpec_v115.keg', 64, 64, 0, 0, 256, 256);
     if (ToNextKeg > 0){
         C.StrLen(int(ToNextKeg),XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText(int(ToNextKeg));
     }
     else {
         C.StrLen("UP",XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText("UP");
     }
  }
  
  if (SpecRI.bHasBelt)
    ItemNum += 1;  
  
  if (ToNextBelt <= 10){
     C.SetPos(PosX + Step * ItemNum, PosY);
     C.DrawTile(Texture'HudContent.Generic.HUD', 64, 64, 2, 247, 68, 68);
     if (ToNextBelt > 0){
         C.StrLen(int(ToNextBelt),XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText(int(ToNextBelt));
     }
     else {
         C.StrLen("UP",XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText("UP");
     }
  }
  
   if (SpecRI.bHasArmorA)
    ItemNum += 1;   
  
  if (ToNextShieldA <= 10){
     C.SetPos(PosX + Step * ItemNum, PosY);
     C.DrawTile(Texture'LSpec_v115.shield50', 64, 64, 0, 0, 64, 64);
     if (ToNextShieldA > 0){
         C.StrLen(int(ToNextShieldA),XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText(int(ToNextShieldA));
     }
     else {
         C.StrLen("UP",XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText("UP");
     }
  }

   if (SpecRI.bHasArmorB)
    ItemNum += 1;  

  if (ToNextShieldB <= 10){
     C.SetPos(PosX + Step * ItemNum, PosY); 
     C.DrawTile(Texture'LSpec_v115.shield50', 64, 64, 0, 0, 64, 64);
     if (ToNextShieldB > 0){
         C.StrLen(int(ToNextShieldB),XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText(int(ToNextShieldB));
     }
     else {
         C.StrLen("UP",XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText("UP");
     }
  }
  
  if (SpecRI.bHasArmorC)
    ItemNum += 1;

  if (ToNextShieldC <= 10){
     C.SetPos(PosX + Step * ItemNum, PosY);
     C.DrawTile(Texture'LSpec_v115.shield25', 64, 64, 0, 0, 64, 64);
     if (ToNextShieldC > 0){
         C.StrLen(int(ToNextShieldC),XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText(int(ToNextShieldC));
     }
     else {
         C.StrLen("UP",XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText("UP");
     }
  }

  if (SpecRI.bHasUD)
    ItemNum += 1;  

  if (ToNextUD <= 10){
     C.SetPos(PosX + 4 + Step * ItemNum, PosY); // also non rectangle, so adjusting, X+4
     C.DrawTile(Texture'HudContent.Generic.HUD', 56, 64, 0, 164, 74, 84);
     if (ToNextUD > 0){
         C.StrLen(int(ToNextUD),XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText(int(ToNextUD));
     }
     else {
         C.StrLen("UP",XL, YL);
         C.SetPos(PosX + Step * ItemNum + 32 - XL/2, PosY - YL);
         C.DrawText("UP");
     }
  }
}

// ============================================================================
// DrawLeftWeapons
//
// Draws the list of weapons and ammo for the left player.
//
//The weird trick with  making a local copy of all relevant replicated values
// is to reduce the reads of an outside reference to a minimum and at the
// beginning of the function. Rendering really hates when a reference it tries
// to access is not there and results in memory access crash
// ============================================================================
function DrawLeftWeapons(Canvas C){

  local LinkedSpecInfo LeftSpecPRI;
  local float PosX, PosY, XL, YL;

  // ugly local caching attempt to avoid crash if a player leaves midgame
  local int hasBio,
            hasASMD,
            hasLink,
            hasMini,
            hasFlak,
            hasRocket,
            hasLG,
            hasSniper;
  local byte CurWeap;


  // set up color and base coords
  C.SetDrawColor(255,255,255,128);
  C.Font = PlayerFont;
  C.StrLen("XXX", XL, YL); // get XL and YL once
  XL +=5;
  PosX = 20 + XL;
  PosY = 400;

  LeftSpecPRI = class'LSpecUtil'.static.GetSpecPRI(LeftPLayer);

  if (LeftSpecPRI != none){
     hasBio = LeftSpecPRI.hasBio;
     hasASMD = LeftSpecPRI.hasASMD;
     hasLink = LeftSpecPRI.hasLink;
     hasMini = LeftSpecPRI.hasMini;
     hasFlak = LeftSpecPRI.hasFlak;
     hasRocket = LeftSpecPRI.hasRocket;
     hasLG = LeftSpecPRI.hasLG;
     hasSniper = LeftSpecPRI.hasSniper;
     curWeap = LeftSpecPRI.CurWeap;
  }

  if (LeftSpecPRI != none){
     if (hasBio >= 0){
        if (CurWeap == 1)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX + 61, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', -61, 32, 169, 129, 78, 41);
        C.SetPos(PosX - XL, PosY + 16 - YL/2);
        C.DrawText(hasBio);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasASMD >= 0){
        if (CurWeap == 2)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX + 71, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', -71, 32, 249, 108, 81, 38);
        C.SetPos(PosX - XL, PosY + 16 - YL/2);
        C.DrawText(hasASMD);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasLink >= 0){
        if (CurWeap == 3)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX + 67, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', -67, 32, 169, 86, 78, 37);
        C.SetPos(PosX - XL, PosY + 16 - YL/2);
        C.DrawText(hasLink);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasMini >= 0){
        if (CurWeap == 4)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX + 68, PosY + 4); // adjust Y for mini being thin
        C.DrawTile(Texture'HudContent.Generic.HUD', -68, 24, 251, 80, 79, 28);
        C.SetPos(PosX - XL, PosY + 16 - YL/2);
        C.DrawText(hasMini);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasFlak >= 0){
        if (CurWeap == 5)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX + 72, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', -72, 32, 169, 173, 76, 34);
        C.SetPos(PosX - XL, PosY + 16 - YL/2);
        C.DrawText(hasFlak);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasRocket >= 0){
        if (CurWeap == 6)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX + 73, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', -73, 32, 249, 147, 80, 35);
        C.SetPos(PosX - XL, PosY + 16 - YL/2);
        C.DrawText(hasRocket);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasLG >= 0){
        if (CurWeap == 7)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX + 79, PosY + 2); // adjusting for LG thin sprite
        C.DrawTile(Texture'HudContent.Generic.HUD', -79, 28, 249, 183, 79, 28);
        C.SetPos(PosX - XL, PosY + 16 - YL/2);
        C.DrawText(hasLG);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasSniper >= 0){
        if (CurWeap == 8)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX + 79, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', -79, 32, 427, 177, 79, 32);
        C.SetPos(PosX - XL, PosY + 16 - YL/2);
        C.DrawText(hasSniper);
     }
  }
}

function DrawRightWeapons(Canvas C){

  local LinkedSpecInfo RightSpecPRI;
  local float PosX, PosY, XL, YL;

  // ugly local caching attempt to avoid crash if a player leaves midgame
  local int hasBio,
            hasASMD,
            hasLink,
            hasMini,
            hasFlak,
            hasRocket,
            hasLG,
            hasSniper;
  local byte CurWeap;

  // set up color and base coords
  C.SetDrawColor(255,255,255,128);
  C.Font = PlayerFont;
  C.StrLen("XXX", XL, YL); // get XL and YL once
  PosX = C.SizeX - 25 - XL;
  PosY = 400;

  RightSpecPRI = class'LSpecUtil'.static.GetSpecPRI(RightPLayer);

  if (RightSpecPRI != none){
     hasBio = RightSpecPRI.hasBio;
     hasASMD = RightSpecPRI.hasASMD;
     hasLink = RightSpecPRI.hasLink;
     hasMini = RightSpecPRI.hasMini;
     hasFlak = RightSpecPRI.hasFlak;
     hasRocket = RightSpecPRI.hasRocket;
     hasLG = RightSpecPRI.hasLG;
     hasSniper = RightSpecPRI.hasSniper;
     curWeap = RightSpecPRI.CurWeap;
  }

  if (RightSpecPRI != none){
     if (hasBio >= 0){
        if (CurWeap == 1)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX - 61, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', 61, 32, 169, 129, 78, 41);
        C.SetPos(PosX + 10, PosY + 16 - YL/2);
        C.DrawText(hasBio);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasASMD >= 0){
        if (CurWeap == 2)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX - 71, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', 71, 32, 249, 108, 81, 38);
        C.SetPos(PosX + 10, PosY + 16 - YL/2);
        C.DrawText(hasASMD);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasLink >= 0){
        if (CurWeap == 3)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX - 67, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', 67, 32, 169, 86, 78, 37);
        C.SetPos(PosX + 10, PosY + 16 - YL/2);
        C.DrawText(hasLink);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasMini >= 0){
        if (CurWeap == 4)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX - 68, PosY + 4); // adjust Y for mini being thin
        C.DrawTile(Texture'HudContent.Generic.HUD', 68, 24, 251, 80, 79, 28);
        C.SetPos(PosX + 10, PosY + 16 - YL/2);
        C.DrawText(hasMini);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasFlak >= 0){
        if (CurWeap == 5)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX - 72, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', 72, 32, 169, 173, 76, 34);
        C.SetPos(PosX + 10, PosY + 16 - YL/2);
        C.DrawText(hasFlak);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasRocket >= 0){
        if (CurWeap == 6)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX - 73, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', 73, 32, 249, 147, 80, 35);
        C.SetPos(PosX + 10, PosY + 16 - YL/2);
        C.DrawText(hasRocket);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasLG >= 0){
        if (CurWeap == 7)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX - 79, PosY + 2); // adjusting for LG thin sprite
        C.DrawTile(Texture'HudContent.Generic.HUD', 79, 28, 249, 183, 79, 28);
        C.SetPos(PosX + 10, PosY + 16 - YL/2);
        C.DrawText(hasLG);
        // set up next
        C.SetDrawColor(255,255,255,128);
        PosY += 36;
     }
     if (hasSniper >= 0){
        if (CurWeap == 8)
           C.SetDrawColor(255,255,255,255);
        C.SetPos(PosX - 79, PosY);
        C.DrawTile(Texture'HudContent.Generic.HUD', 79, 32, 427, 177, 79, 32);
        C.SetPos(PosX + 10, PosY + 16 - YL/2);
        C.DrawText(hasSniper);
     }
  }
}

// ============================================================================
// DrawLeftWeapons
//
// Draws the list of last damage recieved by the left player, from the bottom
// of the screen up
//
// Same as with Weapon list, making a local cache and working with it
// ============================================================================

function DrawLeftPlayerDmgLog(Canvas C){
  local int Damage[5];
  local string Desc[5];
  local int bSelf[5];
  local LinkedSpecInfo LeftSpecPRI;
  local float PosY, XL, YL;
  local int i;

  C.Font = DMGFont;
  C.SetDrawColor(255,255,255);
  C.StrLen("200", XL, YL);
  PosY = C.SizeY - 10 - YL;

  LeftSpecPRI = class'LSpecUtil'.static.GetSpecPRI(LeftPLayer);

  // caching hack to reduce the likeliness of crash
  if (LeftSpecPRI != none){
     for (i = 0; i < 5; i++){
       Damage[i] = LeftSpecPRI.DamageLog[i].Damage;
       Desc[i] = LeftSpecPRI.DamageLog[i].Desc;
       bSelf[i] = int(LeftSpecPRI.DamageLog[i].bSelf);
     }
  }

  if (LeftSpecPRI != none){
     for (i = 0; i < 5; i++){
         if (Desc[i] != ""){
              C.SetPos(10,PosY);
              C.DrawText(Damage[i]);
              C.SetPos(20 + XL,PosY); // line up desc separately
              if (bSelf[i] == 1)
                 C.SetDrawColor(255,96,96);
              C.DrawText(Desc[i]);
              C.SetDrawColor(255,255,255);
              PosY -= YL;
         }
     }
  }

}

// ============================================================================
// DrawRightWeapons
//
// Draws the list of last damage recieved by the Right player, from the bottom
// of the screen up
//
// Same as with Weapon list, making a local cache and working with it
// ============================================================================

function DrawRightPlayerDmgLog(Canvas C){
  local int Damage[5];
  local string Desc[5];
  local int bSelf[5];
  local LinkedSpecInfo RightSpecPRI;
  local float PosY, XL, YL, PosX, StepY;
  local int i;

  C.Font = DMGFont;
  C.SetDrawColor(255,255,255);
  C.StrLen("200", XL, YL);
  PosY = C.SizeY - 10 - YL;
  StepY = YL;

  RightSpecPRI = class'LSpecUtil'.static.GetSpecPRI(RightPLayer);

  // caching hack to reduce the likeliness of crash
  if (RightSpecPRI != none){
     for (i = 0; i < 5; i++){
       Damage[i] = RightSpecPRI.DamageLog[i].Damage;
       Desc[i] = RightSpecPRI.DamageLog[i].Desc;
       bSelf[i] = int(RightSpecPRI.DamageLog[i].bSelf);
     }
  }

  PosX = C.SizeX - 10 - XL;
  if (RightSpecPRI != none){
     for (i = 0; i < 5; i++){
         if (Desc[i] != ""){
              C.SetPos(PosX,PosY);
              C.DrawText(Damage[i]);
              C.StrLen(Desc[i],XL, YL);
              C.SetPos(PosX - 10 - XL,PosY); // line up desc separately
              if (bSelf[i] == 1)
                 C.SetDrawColor(255,96,96);
              C.DrawText(Desc[i]);
              C.SetDrawColor(255,255,255);
              PosY -= StepY;
         }
     }
  }

}

function DrawLeftAccuracy(Canvas C);

function DrawLeftPickups(Canvas C){
  local LinkedSpecInfo LeftSpecPRI;
  local float PosX, PosY, XL, YL;

  // ugly local caching attempt to avoid crash if a player leaves midgame
  local int DamageDone,
            DamageRecieved,
            SelfDamage,
            UDTimeTotal,
            ShieldTotal,
            HPTotal,
            VialsCount;

  local byte HPCount,
             KegCount,
             ShieldCount,
             BeltCount,
             UDcount;


  // set up color and base coords
  C.SetDrawColor(255,255,255);
  C.Font = DMGFont;
  C.StrLen("XXX", XL, YL); // get XL and YL once
  PosX = 20;
  PosY = 400;

  LeftSpecPRI = class'LSpecUtil'.static.GetSpecPRI(LeftPLayer);

  DamageDone = LeftSpecPRI.DamageDone;
  DamageRecieved = LeftSpecPRI.DamageRecieved;
  SelfDamage = LeftSpecPRI.SelfDamage;
  UDTimeTotal = LeftSpecPRI.UDTimeTotal;
  ShieldTotal = LeftSpecPRI.ShieldTotal;
  HPTotal = LeftSpecPRI.HPTotal;
  VialsCount = LeftSpecPRI.VialsCount;
  HPCount = LeftSpecPRI.HPCount;
  KegCount = LeftSpecPRI.KegCount;
  ShieldCount = LeftSpecPRI.ShieldCount;
  BeltCount = LeftSpecPRI.BeltCount;
  UDcount = LeftSpecPRI.UDcount;

  if (LeftSpecPRI != none){
     if (DamageDone > 0){
        C.StrLen("DAMAGE DEALT:"@DamageDone, XL, YL);
        C.SetPos(PosX, PosY);
        C.DrawText("DAMAGE DEALT:"@DamageDone);
        PosY += YL;
     }
     if (DamageRecieved > 0){
        C.StrLen("DAMAGE TAKEN:"@DamageRecieved, XL, YL);
        C.SetPos(PosX, PosY);
        C.DrawText("DAMAGE TAKEN:"@DamageRecieved);
        PosY += YL;
     }
     if (SelfDamage > 0){
        C.StrLen("SELF-DAMAGE:"@SelfDamage, XL, YL);
        C.SetPos(PosX, PosY);
        C.DrawText("SELF-DAMAGE:"@SelfDamage);
        PosY += YL;
     }
     if (HPTotal > 0){
        C.SetPos(PosX, PosY);
        C.DrawText("HEALTH TOTAL:"@HPTotal);
        PosY += YL;
     }
     if (ShieldTotal > 0){
        C.SetPos(PosX, PosY);
        C.DrawText("SHIELD TOTAL:"@ShieldTotal);
        PosY += YL;
     }
     if (KegCount > 0){
        C.SetPos(PosX, PosY);
        C.DrawText("100H: x"$KegCount);
        PosY += YL;
     }
     if (HPCount > 0){
        C.SetPos(PosX, PosY);
        C.DrawText("25H: x"$HPCount);
        PosY += YL;
     }
     if (VialsCount > 0){
        C.SetPos(PosX, PosY);
        C.DrawText("5H: x"$VialsCount);
        PosY += YL;
     }
     if (BeltCount > 0){
        C.SetPos(PosX, PosY);
        C.DrawText("100A: x"$BeltCount);
        PosY += YL;
     }
     if (ShieldCount > 0){
        C.SetPos(PosX, PosY);
        C.DrawText("50A: x"$ShieldCount);
        PosY += YL;
     }
     if (UDcount > 0){
        C.SetPos(PosX, PosY);
        C.DrawText("UD: x"$UDcount);
     }
  }

}

function DrawRightAccuracy(Canvas C);

function DrawRightPickups(Canvas C){

  local LinkedSpecInfo RightSpecPRI;
  local float PosX, PosY, XL, YL;

  // ugly local caching attempt to avoid crash if a player leaves midgame
  local int DamageDone,
            DamageRecieved,
            SelfDamage,
            UDTimeTotal,
            ShieldTotal,
            HPTotal,
            VialsCount;

  local byte HPCount,
             KegCount,
             ShieldCount,
             BeltCount,
             UDcount;


  // set up color and base coords
  C.SetDrawColor(255,255,255);
  C.Font = DMGFont;
  C.StrLen("XXX", XL, YL); // get XL and YL once
  PosX = C.SizeX - 20;
  PosY = 400;

  RightSpecPRI = class'LSpecUtil'.static.GetSpecPRI(RightPlayer);

  DamageDone = RightSpecPRI.DamageDone;
  DamageRecieved = RightSpecPRI.DamageRecieved;
  SelfDamage = RightSpecPRI.SelfDamage;
  UDTimeTotal = RightSpecPRI.UDTimeTotal;
  ShieldTotal = RightSpecPRI.ShieldTotal;
  HPTotal = RightSpecPRI.HPTotal;
  VialsCount = RightSpecPRI.VialsCount;
  HPCount = RightSpecPRI.HPCount;
  KegCount = RightSpecPRI.KegCount;
  ShieldCount = RightSpecPRI.ShieldCount;
  BeltCount = RightSpecPRI.BeltCount;
  UDcount = RightSpecPRI.UDcount;

  if (RightSpecPRI != none){
     if (DamageDone > 0){
        C.StrLen("DAMAGE DEALT:"@DamageDone, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("DAMAGE DEALT:"@DamageDone);
        PosY += YL;
     }
     if (DamageRecieved > 0){
        C.StrLen("DAMAGE TAKEN:"@DamageRecieved, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("DAMAGE TAKEN:"@DamageRecieved);
        PosY += YL;
     }
     if (SelfDamage > 0){
        C.StrLen("SELF-DAMAGE:"@SelfDamage, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("SELF-DAMAGE:"@SelfDamage);
        PosY += YL;
     }
     if (HPTotal > 0){
        C.StrLen("HEALTH TOTAL:"@HPTotal, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("HEALTH TOTAL:"@HPTotal);
        PosY += YL;
     }
     if (ShieldTotal > 0){
        C.StrLen("SHIELD TOTAL:"@ShieldTotal, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("SHIELD TOTAL:"@ShieldTotal);
        PosY += YL;
     }
     if (KegCount > 0){
        C.StrLen("100H: x"$KegCount, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("100H: x"$KegCount);
        PosY += YL;
     }
     if (HPCount > 0){
        C.StrLen("25H: x"$HPCount, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("25H: x"$HPCount);
        PosY += YL;
     }
     if (VialsCount > 0){
        C.StrLen("5H: x"$VialsCount, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("5H: x"$VialsCount);
        PosY += YL;
     }
     if (BeltCount > 0){
        C.StrLen("100A: x"$BeltCount, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("100A: x"$BeltCount);
        PosY += YL;
     }
     if (ShieldCount > 0){
        C.StrLen("50A: x"$ShieldCount, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("50A: x"$ShieldCount);
        PosY += YL;
     }
     if (UDcount > 0){
        C.StrLen("UD: x"$UDcount, XL, YL);
        C.SetPos(PosX - XL, PosY);
        C.DrawText("UD: x"$UDcount);
     }
  }

}

DefaultProperties
{
  MidFont="LSpec_v115.FontJost21";
  ClockFont="LSpec_v115.FontTimer52";
  SmallFont="UT2003Fonts.FontNeuzeit12";
  BigFont="LSpec_v115.FontTimer36";
  PlayerFont="UT2003Fonts.FontEurostile17";
  ScoreFont="LSpec_v115.FontTimer60";
  DMGFont="LSpec_v115.FontJost12";
  bVisible=True;
  bInitialLog=False;
  ShowName=1;
  InfoMode=1;
  BestOf=7;
  ToNextKeg=9999;
  ToNextUD=9999;
  ToNextShieldA=9999;
  ToNextShieldB=9999;
  ToNextShieldC=9999;
  ToNextBelt=9999;
}
