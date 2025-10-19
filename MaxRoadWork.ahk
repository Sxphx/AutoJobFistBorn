#NoEnv
#Persistent
#SingleInstance Force
#Include, Gdip_All.ahk
SetBatchLines -1
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Client

turnDegrees := 90
pixelsPerDegree := 20
stepSize := 500
stepDelay := 5
Rounds := 0

pixelsFor90deg := 1800

if !pToken := Gdip_Startup()
{
    MsgBox, GDI+ failed to start.
    ExitApp
}

Gui, 2:Color, 0x1E1E1E
Gui, 2:Font, s10 cWhite Bold, Segoe UI
Gui, 2:+AlwaysOnTop -Caption +Border +ToolWindow
Gui, 2:Add, Text, x10 y8 w280 h25 BackgroundTrans Center, Kuyrai
Gui, 2:Font, s9 c0xDDDDDD Normal, Consolas
Gui, 2:Add, Text, x10 y35 w280 h18 BackgroundTrans Center vRoundsText, Rounds: 0
Gui, 2:Add, Text, x10 y55 w280 h18 BackgroundTrans Center vTimerText, Time: 00:00.0
Gui, 2:Add, Edit, x10 y78 w280 h80 -VScroll vStatus ReadOnly BackgroundBlack c0xDDDDDD
Gui, 2:Show, w300 h170, Macro Status Window

WinWait, Macro Status Window
WinGetPos, RX, RY, RW, RH, ahk_exe RobloxPlayerBeta.exe
WinGetPos,,, GuiW, GuiH, Macro Status Window
WinMove, Macro Status Window,, % RX + RW - GuiW - 10, % RY + 10

global Status := ""
global RoadworkStart := 0
global RoadworkActive := False
global LastRoadworkMs := 0

Notify(NewMessage) {
    global Status
    Status .= NewMessage "`n"
    If (GetLine(Status, "`n") > 5)
        Status := SubStr(Status, InStr(Status,"`n") + 1)
    GuiControl, 2:, Status, %Status%
    Gui, 2:Submit, NoHide
}

UpdateRounds(Rounds){
    GuiControl, 2:, RoundsText, Rounds: %Rounds%
}

GetLine(Text, var) {
    StringReplace, Text, Text, % var, % var, UseErrorLevel
    Return ( ( (var = "`n" || var = "`r") && (Text) ) ? ErrorLevel + 1 : ErrorLevel )
}

pad2(n) {
    n := Floor(n)
    return (n < 10 ? "0" n : "" n)
}

FormatDuration(ms) {
    if (ms < 0)
        ms := 0
    sec := Floor(ms / 1000)
    min := Floor(sec / 60)
    sec := Mod(sec, 60)
    tenth := Floor(Mod(ms, 1000) / 100)
    return pad2(min) ":" pad2(sec) "." tenth
}

Notify("Initializing...")
if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
    Notify("Roblox not found. Start Roblox then reload script.")
    MsgBox, 48, Roblox not found, Please start Roblox (RobloxPlayerBeta.exe) and reload this script.
    ExitApp
}
WinMove, ahk_exe RobloxPlayerBeta.exe, , 0, 0, 860, 800
Notify("Window configured")

dimensions() {
    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 100
    WinGetPos, X, Y, Width, Height, ahk_exe RobloxPlayerBeta.exe
    return Width . "x" . Height
}

dimensions()
Notify("Ready: " dimensions())

MoveMouseX(dx) {
    global stepSize, stepDelay
    sign := (dx >= 0) ? 1 : -1
    remain := Abs(dx)
    while (remain > 0) {
        move := (remain >= stepSize) ? stepSize * sign : remain * sign
        DllCall("mouse_event", "UInt", 0x0001, "Int", move, "Int", 0, "UInt", 0, "UPtr", 0)
        remain -= Abs(move)
        if (stepDelay > 0)
            Sleep, %stepDelay%
    }
}

turn(dir := 1) {
    global pixelsFor90deg
    pixels := dir * pixelsFor90deg

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 50

    DllCall("SetCursorPos", "int", 430, "int", 400)
    Sleep, 20

    SendInput, {RButton down}
    Sleep, 30
    DllCall("mouse_event", "UInt", 0x0001, "Int", 1, "Int", 0, "UInt", 0, "UPtr", 0)
    DllCall("mouse_event", "UInt", 0x0001, "Int", -1, "Int", 0, "UInt", 0, "UPtr", 0)

    MoveMouseX(pixels)
    Sleep, 20
    SendInput, {RButton up}
    Sleep, 100
}

run(RunTime) {
    SendInput, {w down} {w up}
    SendInput, {w down}
    Sleep, RunTime
    SendInput, {w up}
}

walk(WalkTime) {
    SendInput, {w down}
    Sleep, WalkTime
    SendInput, {w up}
    Sleep, 200
}

DoRoadwork()
{
    global Rounds
    checkStam() 
    Notify("Starting roadwork...")
    StartRoadworkTimer()
    run(24000)
    turn()
    run(10250)
    turn()
    run(25250)
    turn()
    run(11000)
    turn()
    walk(4850)
    StopRoadworkTimer()
    Rounds += 1
    UpdateRounds(Rounds)
    Notify("Roadwork complete. Total rounds: " Rounds)
    turn()
    Send, {w down}
    Sleep, 15000
    Send, {a down}
    Sleep, 5000
    Send, {a up}{w up}
    reposition()
}

reposition()
{
    Notify("Repositioning character...")
    SendInput, {d down}
    Sleep, 2900
    SendInput, {d up}
    Sleep, 200
    turn()
    turn()
    walk(600)
    SendInput, {e}
    checkRoadWork()
    walk(2000)
    turn()
    walk(1000)
    turn(-1)
    walk(3000)
    turn(-1)
    walk(750)
    turn()
    walk(1500)
    turn()
    DoRoadwork()
    Notify("Repositioning complete.")
}

checkRoadWork()
{
    Notify("Checking for roadwork...")
    Loop,
    {
        ImageSearch, OutputVarX, OutputVarY, 200, 725, 660, 780, *20 RoadWork.bmp
        If (ErrorLevel == 0){
            Notify("Roadwork found!")
            SendInput, 1
            Sleep, 200
            Click
            Return
        }
        SendInput, e
    }
}

checkhowlongtorun()
{
    Notify("Checking how long to run...")
    StartRoadworkTimer()
    global running := true
    SetTimer, __CheckStopRunning, 50
    SendInput, {w down}{w up}
    SendInput, {w down}
    while running
        Sleep, 50
    SendInput, {w up}
    SetTimer, __CheckStopRunning, Off
    StopRoadworkTimer()
}

checkhowlongtowalk()
{
    Notify("Checking how long to walk...")
    StartRoadworkTimer()
    global walking := true
    SetTimer, __CheckStopWalking, 50
    SendInput, {w down}
    while walking
        Sleep, 50
    SendInput, {w up}
    SetTimer, __CheckStopWalking, Off
    StopRoadworkTimer()
}

__CheckStopRunning:
    if GetKeyState("s", "P")
        running := false
return
__CheckStopWalking:
    if GetKeyState("s", "P")
        walking := false
return

f2:: checkhowlongtorun()
f3:: checkhowlongtowalk()
f4:: checkRoadWork()
f:: turn()
+f:: turn(-1)
+g:: DoRoadwork()

checkStam()
{
    Notify("Checking stamina...")
    Loop,
    {
        ImageSearch, OutputVarX, OutputVarY, 570, 655, 615, 680, *20 Stam.bmp
        If (ErrorLevel == 0){
            Notify("Stamina restored!")
            Return
        }
        Notify("Waiting for stamina...")
        Sleep, 1000
    }
}

StartRoadworkTimer() {
    global RoadworkStart, RoadworkActive
    RoadworkStart := A_TickCount
    RoadworkActive := True
    GuiControl, 2:, TimerText, Time: 00:00.0
    SetTimer, __UpdateRoadworkTimer, 100
}

StopRoadworkTimer() {
    global RoadworkActive, LastRoadworkMs, RoadworkStart
    if (RoadworkActive) {
        LastRoadworkMs := A_TickCount - RoadworkStart
        RoadworkActive := False
        SetTimer, __UpdateRoadworkTimer, Off
        GuiControl, 2:, TimerText, % "Time: " FormatDuration(LastRoadworkMs)
    }
}

__UpdateRoadworkTimer:
    global RoadworkActive, RoadworkStart
    if (!RoadworkActive)
        return
    elapsed := A_TickCount - RoadworkStart
    GuiControl, 2:, TimerText, % "Time: " FormatDuration(elapsed)
return

f1:: reposition()
~k::pause
~j::ExitApp

GuiClose:
ExitApp
Return
