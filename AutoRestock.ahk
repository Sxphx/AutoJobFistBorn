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
JobCount := 0
Banked := 0

if !pToken := Gdip_Startup()
{
    MsgBox, GDI+ failed to start.
    ExitApp
}

Gui, 2:Color, 0x0D0D0D
Gui, 2:+AlwaysOnTop -Caption +Border +ToolWindow
Gui, 2:Margin, 0, 0

Gui, 2:Add, Progress, x0 y0 w350 h50 Background1a1a1a c4A90E2 vHeaderBar, 0
Gui, 2:Font, s14 cWhite Bold, Segoe UI
Gui, 2:Add, Text, x0 y12 w350 h26 BackgroundTrans Center, KUYRAI MACRO

Gui, 2:Font, s9 c0xCCCCCC Normal, Segoe UI

Gui, 2:Add, Progress, x10 y60 w105 h70 Background1E1E1E c2ECC71, 0
Gui, 2:Font, s8 c0x999999
Gui, 2:Add, Text, x10 y65 w105 h15 BackgroundTrans Center, JOBS COMPLETED
Gui, 2:Font, s16 cWhite Bold
Gui, 2:Add, Text, x10 y82 w105 h25 BackgroundTrans Center vRoundsText, 0
Gui, 2:Font, s8 c0x2ECC71 Normal
Gui, 2:Add, Text, x10 y107 w105 h15 BackgroundTrans Center, >> Active

Gui, 2:Add, Progress, x122 y60 w105 h70 Background1E1E1E c3498DB, 0
Gui, 2:Font, s8 c0x999999
Gui, 2:Add, Text, x122 y65 w105 h15 BackgroundTrans Center, MONEY BANKED
Gui, 2:Font, s16 cWhite Bold
Gui, 2:Add, Text, x122 y82 w105 h25 BackgroundTrans Center vBankedText, 0
Gui, 2:Font, s8 c0x3498DB Normal
Gui, 2:Add, Text, x122 y107 w105 h15 BackgroundTrans Center, >> Times

Gui, 2:Add, Progress, x234 y60 w105 h70 Background1E1E1E cE74C3C, 0
Gui, 2:Font, s8 c0x999999
Gui, 2:Add, Text, x234 y65 w105 h15 BackgroundTrans Center, CURRENT JOB
Gui, 2:Font, s12 cWhite Bold
Gui, 2:Add, Text, x234 y82 w105 h25 BackgroundTrans Center vTimerText, 00:00.0
Gui, 2:Font, s8 c0xE74C3C Normal
Gui, 2:Add, Text, x234 y107 w105 h15 BackgroundTrans Center, >> Running

Gui, 2:Font, s8 c0x999999 Normal, Segoe UI
Gui, 2:Add, Text, x10 y140 w330 h15 BackgroundTrans, STATUS LOG
Gui, 2:Font, s9 c0xDDDDDD Normal, Consolas
Gui, 2:Add, Edit, x10 y158 w330 h110 -VScroll vStatus ReadOnly Background0D0D0D c0xCCCCCC -E0x200

Gui, 2:Font, s8 c0x666666 Normal, Segoe UI
Gui, 2:Add, Text, x10 y275 w330 h18 BackgroundTrans Center, F1: Start | J: Exit

Gui, 2:Show, w350 h300, Macro Control Panel

WinWait, Macro Control Panel
WinGetPos, RX, RY, RW, RH, ahk_exe RobloxPlayerBeta.exe
WinGetPos,,, GuiW, GuiH, Macro Control Panel
WinMove, Macro Control Panel,, % RX + RW - GuiW - 10, % RY + 10

global Status := ""
global JobStart := 0
global JobActive := False
global LastJobMs := 0
global Pause := false

Notify(NewMessage) {
    global Status
    TimeStamp := A_Hour ":" pad2(A_Min) ":" pad2(A_Sec)
    Status .= "[" TimeStamp "] " NewMessage "`n"
    If (GetLine(Status, "`n") > 6)
        Status := SubStr(Status, InStr(Status,"`n") + 1)
    GuiControl, 2:, Status, %Status%
    Gui, 2:Submit, NoHide
}

JobDone(){
    global JobCount
    JobCount++
    GuiControl, 2:, RoundsText, %JobCount%
}

Banked(){
    global Banked
    Banked++
    GuiControl, 2:, BankedText, %Banked%
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

Notify("System initialized")
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

turn45(dir := 1) {
    global pixelsPerDegree

    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 50

    DllCall("SetCursorPos", "int", 430, "int", 400)
    Sleep, 50

    MoveMouseX(Round(dir * 45 * pixelsPerDegree))
    Sleep, 200
}

MoveDown(dy) {
    global stepSize, stepDelay
    sign := (dy >= 0) ? 1 : -1
    remain := Abs(dy)
    while (remain > 0) {
        move := (remain >= stepSize) ? stepSize * sign : remain * sign
        DllCall("mouse_event", "UInt", 0x0001, "Int", 0, "Int", move, "UInt", 0, "UPtr", 0)
        remain -= Abs(move)
        if (stepDelay > 0)
            Sleep, %stepDelay%
    }
}

turnDown() {
    WinActivate, ahk_exe RobloxPlayerBeta.exe
    Sleep, 50

    DllCall("SetCursorPos", "int", 430, "int", 400)
    Sleep, 50

    MoveDown(10000)
    Sleep, 200
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

back(BackTime) {
    SendInput, {s down}
    Sleep, BackTime
    SendInput, {s up}
    Sleep, 200
}

findJob(){
    checkMoney()
    Notify("Searching for job...")
    Sleep, 200
    Send {Ctrl}
    Sleep, 200
    JobSearchStart := A_TickCount
    Loop,
    {
        SearchElapsed := A_TickCount - JobSearchStart
        If (SearchElapsed >= 300000) {
            Notify("ERROR: No job found in 5 minutes!")
            SoundBeep, 1000, 500
            Sleep, 200
            SoundBeep, 800, 500
            Sleep, 200
            SoundBeep, 1000, 500
            Sleep, 200
            SoundBeep, 800, 500
            Return
        }

        ImageSearch, OutputVarX, OutputVarY, 10, 400, 145, 420, *50 Cat.bmp
        If (ErrorLevel == 0){
            Sleep, 200
            cat()
            Break
        }

        ImageSearch, OutputVarX, OutputVarY, 10, 400, 145, 420, *50 Dust.bmp
        If (ErrorLevel == 0){
            Sleep, 200
            dust()
            Break
        }

        ImageSearch, OutputVarX, OutputVarY, 10, 400, 145, 420, *50 Restock.bmp
        If (ErrorLevel == 0){
            Sleep, 200
            Restock()
            Break
        }
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
    turnDown()
    Notify("Repositioning...")
    JobDone()
    SendInput, {w down}{a down}
    Sleep, 5000
    SendInput, {w up}{a up}
    Sleep, 200
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
    run(10000)
    Notify("Restock complete")
    StopJobTimer()
    Notify("Adjusting position")
    SendInput, {a down}
    Sleep, 10000
    SendInput, {w down}
    Sleep, 10000
    SendInput, {a up}{w up}
    reposition()
}

dust() {
    Notify("Starting Dust job...")
    StartJobTimer()

    DustStartTime := A_TickCount

    back(400)
    WalkCount := 0
    global DustCount
    if (!DustCount){
        DustCount := 0
    }
    If (DustCount >= 5){
        DustCount := 0
        Notify("Dust count reset")
    }
    WalkBack := True
    WalkFront := False
    SwitchLane := 0
    Loop,
    {
        ElapsedTime := A_TickCount - DustStartTime
        If (ElapsedTime >= 120000) {
            Notify("2 minutes passed")
            Notify("Dusting complete")
            Cancel()
            StopJobTimer()
            Notify("Adjusting position")
            SendInput, {w down}
            Sleep, 15000
            SendInput, {w up}{a down}
            Sleep, 15000
            SendInput, {a up}
            Send, {Ctrl}
            reposition()
            Return
        }

        checkDust()
        If (WalkBack && (WalkCount < 8)){
            back(200)
            WalkCount++
            Notify("Walking back " WalkCount "/8")
        } Else If (WalkCount >= 8){
            WalkFront := !WalkFront
            WalkBack := !WalkBack
            WalkCount := 0
            if (SwitchLane == 0){
                Loop, 10
                {
                    checkDust()
                    SendInput, {d down}
                    Sleep, 200
                    SendInput, {d up}
                    Sleep, 150
                }
                SwitchLane := 1
            } Else If (SwitchLane == 1){
                Loop, 10
                {
                    checkDust()
                    SendInput, {d down}
                    Sleep, 150
                    SendInput, {d up}
                    Sleep, 150
                }
                SwitchLane := 2
            } Else If (SwitchLane == 2){
                Loop, 10
                {
                    checkDust()
                    SendInput, {d down}
                    Sleep, 100
                    SendInput, {d up}
                    Sleep, 150
                }
                SwitchLane := 3
            } Else If (SwitchLane == 3){
                Loop, 20
                {
                    checkDust()
                    SendInput, {a down}
                    Sleep, 225
                    SendInput, {a up}
                    Sleep, 150
                }
                SwitchLane := 0
            }
        } Else If (WalkFront && (WalkCount < 8)){
            WalkCount++
            walk(200)
        }
    }
}

checkDust(){
    global DustCount
    ImageSearch, OutputVarX, OutputVarY, 390, 575, 470, 595, *100 Clean.bmp
    If (ErrorLevel == 0){
        Notify("Dust found, cleaning...")
        SendInput, {e down}
        Sleep, 100
        SendInput, {e up}
        Sleep, 3000
        DustCount++
        Notify("Dusted: " DustCount "/5")
        If (DustCount >= 5){
            Notify("Dusting complete")
            Cancel()
            StopJobTimer()
            Notify("Adjusting position")
            SendInput, {w down}
            Sleep, 15000
            SendInput, {w up}{a down}
            Sleep, 15000
            SendInput, {a up}
            Send, {Ctrl}
            reposition()
        }
    }
}

cat() {
    Send {Ctrl}
    Notify("Starting Cat job...")
    StartJobTimer()
    turn()
    turn()
    walk(2250)
    turn(-1)
    walk(850)
    turn()
    run(4700)
    SendInput, {w down}
    SendInput, {d down}
    Sleep, 10000
    SendInput, {w up}
    SendInput, {d up}
    Sleep, 200
    back(300)
    turn()
    run(5500)
    turn(-1)
    walk(9000)
    turn(-1)
    walk(2950)
    turn(-1)
    walk(700)
    checkCat()
    turn()
    turn()
    walk(700)
    turn()
    walk(2950)
    turn(-1)
    walk(13000)
    turn(-1)
    walk(2000)
    checkCat()
    turn()
    turn()
    walk(15000)
    checkCat()
    turn()
    walk(25000)
    SendInput, {d down}
    Sleep, 500
    SendInput, {d up}
    walk(2000)
    checkCat()
    walk(2000)
    turn()
    run(8900)
    turn(-1)
    run(10000)

    Notify("Cat job complete")
    StopJobTimer()
    SendInput, {a down}
    Sleep, 5000
    SendInput, {a up}
    SendInput, {w down}
    SendInput, {a down}
    Sleep, 10000
    SendInput, {w up}
    SendInput, {a up}
    reposition()
}

checkMoney()
{
    Notify("Checking money...")
    ImageSearch, OutputVarX, OutputVarY, 225, 630, 280, 645, *100 Money.bmp
    If (ErrorLevel == 0){
        Notify("Money maxed! Banking...")
        turn()
        turn()
        walk(2250)
        turn(-1)
        walk(1700)
        turn()
        walk(11000)
        Send, {e down}{e up}
        Sleep, 2000
        Loop, 6
        {
            Click, 487 ,627
            Sleep, 1000
        }
        Click, 420 , 593
        Sleep, 1000
        turnDown()
        turn45()
        turn()
        turn()
        SendInput, {a down}
        sleep, 10000
        SendInput, {a up}
        sleep, 300
        SendInput, {d down}
        sleep, 500
        SendInput, {d up}
        walk(18900)
        turn45(-1)
        walk(5200)
        turn45(-1)
        walk(6500)
        Sleep, 200
        Send, {Ctrl}
        Sleep, 300
        Click, 650 ,364
        Notify("Opening bank")
        Sleep, 300
        Send, e
        Sleep, 300
        Notify("Entering bank")
        Click, 462 ,428
        Notify("Withdraw 100")
        Sleep, 200
        Click, 423 ,354
        Sleep, 200
        Send, 1
        Sleep, 200
        Send, 0
        Sleep, 200
        Send, 0
        Sleep, 200
        Click, 378 ,401
        Sleep, 200
        Notify("Exit bank")
        Click, 425 ,481
        Sleep, 200
        Send, {Ctrl}
        turn()
        turn()
        walk(6500)
        turn45()
        walk(5200)
        turn45()
        walk(18900)
        turn(-1)
        walk(8000)
        Sleep, 200
        Send, {e down}{e up}
        Send, {Ctrl}
        Loop, 6
        {
            Click, 352, 630
            Sleep, 1000
        }
        Click, 420 , 593
        Send, {Ctrl}
        Sleep, 200
        SendInput, {a down}
        Sleep, 1000
        SendInput, {a up}
        Sleep, 200
        run(5000)
        SendInput, {a down}
        Sleep, 5000
        SendInput, {a up}
        turnDown()
        Banked()
        reposition()
    }
}

checkCat()
{
    Notify("Checking for cat...")
    Loop, 5
    {
        SendInput, {e down}
        Sleep, 100
        SendInput, {e up}
    }
    Return
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

checkFood()
{
    Notify("Checking food...")
    Loop,
    {
        ImageSearch, OutputVarX, OutputVarY, 225, 600, 280, 620, *100 Food.bmp
        If (ErrorLevel == 0){
            Notify("Food sufficient!")
            Return
        }
        Notify("Eating food...")
        SendInput, {1}
        Sleep, 3000
    }
}

StartJobTimer() {
    global JobStart, JobActive
    JobStart := A_TickCount
    JobActive := True
    GuiControl, 2:, TimerText, 00:00.0
    SetTimer, __UpdateJobTimer, 100
}

StopJobTimer() {
    global JobActive, LastJobMs, JobStart
    if (JobActive) {
        LastJobMs := A_TickCount - JobStart
        JobActive := False
        SetTimer, __UpdateJobTimer, Off
        GuiControl, 2:, TimerText, % FormatDuration(LastJobMs)
    }
}

__UpdateJobTimer:
    global JobActive, JobStart
    if (!JobActive)
        return
    elapsed := A_TickCount - JobStart
    GuiControl, 2:, TimerText, % FormatDuration(elapsed)
return

f1::
    reposition()
Return

f2::
    {
        MouseGetPos, MX, MY
        Notify("Mouse: X=" . MX . " Y=" . MY)
    }
Return

f3::turnDown()
f4::turn45()

~Space::
    Notify("SPACEBAR PRESSED!")
    SoundBeep, 750, 100
Return

~j::ExitApp

GuiClose:
ExitApp
Return