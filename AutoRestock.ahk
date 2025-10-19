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
global JobStart := 0
global JobActive := False
global LastJobMs := 0

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
    global pixelsPerDegree, turnDegrees

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 50

    DllCall("SetCursorPos", "int", 430, "int", 400)
    Sleep, 50

    MoveMouseX(Round(dir * turnDegrees * pixelsPerDegree))
    Sleep, 200
}

; Hotkey to manually test turning
f::turn()

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

findJob(){
    Notify("Searching for job...")
    Sleep, 200
    Send {Ctrl}
    Sleep, 200
    Loop,
    {
        ImageSearch, OutputVarX, OutputVarY, 10, 400, 145, 420, *50 Cat.bmp
        If (ErrorLevel == 0){
            Cancel()
            Sleep, 100
            SendInput, {e down}
            Sleep, 50
            SendInput, {e up}
            Sleep, 100
            Continue
        }

        ImageSearch, OutputVarX, OutputVarY, 10, 400, 145, 420, *50 Dust.bmp
        If (ErrorLevel == 0){
            Cancel()
            Sleep, 100
            SendInput, {e down}
            Sleep, 50
            SendInput, {e up}
            Sleep, 100
            Continue
        }

        ImageSearch, OutputVarX, OutputVarY, 10, 400, 145, 420, *50 Restock.bmp
        If (ErrorLevel == 0){
            Sleep, 200
            Restock()
            Break
        }
        Cancel()
        Sleep, 100
        SendInput, {e down}
        Sleep, 50
        SendInput, {e up}
        Sleep, 100
    }
}

Cancel() {
    Sleep, 50
    Notify("Cancelling job...")
    MouseClick, left, 24, 457
    Sleep, 50
    Return
}

reposition() {
    Notify("Repositioning...")

    SendInput, {s down}
    Sleep, 200
    SendInput, {s up}
    Sleep, 200
    SendInput, {d down}
    Sleep, 2500
    SendInput, {d up}
    Sleep, 200

    findJob()
}

Restock() {

    Send {Ctrl}
    checkStam()
    Notify("Starting Restock")
    StartJobTimer()
    turn()
    turn()
    walk(2250)
    turn(-1)
    walk(850)
    turn()
    run(4700)
    turn()
    run(22500)
    turn()
    turn()
    run(22500)
    turn(-1)
    run(4700)
    turn(-1)
    walk(850)
    turn()
    walk(2150)
    Notify("Adjusting position")
    SendInput, {a down}
    Sleep, 2500
    SendInput, {w down}
    Sleep, 2500
    SendInput, {a up}{w up}
    Notify("Restock complete")
    Rounds++
    UpdateRounds(Rounds)
    StopJobTimer()
    reposition()
}

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

StartJobTimer() {
    global JobStart, JobActive
    JobStart := A_TickCount
    JobActive := True
    GuiControl, 2:, TimerText, Time: 00:00.0
    SetTimer, __UpdateJobTimer, 100
}

StopJobTimer() {
    global JobActive, LastJobMs, JobStart
    if (JobActive) {
        LastJobMs := A_TickCount - JobStart
        JobActive := False
        SetTimer, __UpdateJobTimer, Off
        GuiControl, 2:, TimerText, % "Time: " FormatDuration(LastJobMs)
    }
}

__UpdateJobTimer:
    global JobActive, JobStart
    if (!JobActive)
        return
    elapsed := A_TickCount - JobStart
    GuiControl, 2:, TimerText, % "Time: " FormatDuration(elapsed)
return

f1::
    reposition()
Return

~k::pause
~j::ExitApp

GuiClose:
ExitApp
Return
