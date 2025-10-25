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

doJobCat := true
doJobDust := true
doJobRestock := true

Gui, 1:Color, 0x1E1E1E
Gui, 1:Font, s12 cWhite Bold, Segoe UI
Gui, 1:Add, Text, x10 y10 w280 h30 BackgroundTrans Center, SELECT JOBS TO DO
Gui, 1:Font, s10 c0xDDDDDD Normal, Segoe UI
Gui, 1:Add, Checkbox, x30 y50 w240 h25 vCheckCat Checked, Cat Job
Gui, 1:Add, Checkbox, x30 y80 w240 h25 vCheckDust Checked, Dust Job
Gui, 1:Add, Checkbox, x30 y110 w240 h25 vCheckRestock Checked, Restock Job
Gui, 1:Font, s10 cWhite Bold
Gui, 1:Add, Button, x60 y150 w180 h35 gStartMacro, START MACRO
Gui, 1:Show, w300 h200, Job Selection
return

StartMacro:
    Gui, 1:Submit
    doJobCat := CheckCat
    doJobDust := CheckDust
    doJobRestock := CheckRestock
    Gui, 1:Destroy

    if (!doJobCat && !doJobDust && !doJobRestock) {
        MsgBox, 48, No Jobs Selected, Please select at least one job type!
        ExitApp
    }

    GoSub, InitMacro
return

InitMacro:

    if !pToken := Gdip_Startup()
    {
        MsgBox, GDI+ failed to start.
        ExitApp
    }

    Gui, 2:Color, 0x0D0D0D
    Gui, 2:+AlwaysOnTop +Border +ToolWindow
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

    Gui, 2:Add, Progress, x122 y60 w105 h70 Background1E1E1E c3498DB, 0
    Gui, 2:Font, s8 c0x999999
    Gui, 2:Add, Text, x122 y65 w105 h15 BackgroundTrans Center, MONEY BANKED
    Gui, 2:Font, s16 cWhite Bold
    Gui, 2:Add, Text, x122 y82 w105 h25 BackgroundTrans Center vBankedText, 0

    Gui, 2:Add, Progress, x234 y60 w105 h70 Background1E1E1E cE74C3C, 0
    Gui, 2:Font, s8 c0x999999
    Gui, 2:Add, Text, x234 y65 w105 h15 BackgroundTrans Center, CURRENT JOB
    Gui, 2:Font, s12 cWhite Bold
    Gui, 2:Add, Text, x234 y82 w105 h25 BackgroundTrans Center vTimerText, 00:00.0

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
        SendInput, {w down}{w up}{w down}
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

    findJob() {
        global doJobCat, doJobDust, doJobRestock

        checkCombat()
        checkFood()
        checkMoney()
        Notify("Searching for job...")
        Sleep, 200
        Send {Ctrl}
        Sleep, 200

        JobSearchStart := A_TickCount

        files := ["Cat.bmp", "Dust.bmp", "Restock.bmp"]
        funcs := ["cat", "dust", "Restock"]
        flags := [doJobCat, doJobDust, doJobRestock]
        names := ["Cat job", "Dust job", "Restock job"]

        Loop
        {
            SearchElapsed := A_TickCount - JobSearchStart
            if (SearchElapsed >= 300000) {
                Notify("ERROR: No job found in 5 minutes!")
                beeps := [1000, 800, 1000, 800]
                for index, tone in beeps {
                    SoundBeep, % tone, 500
                    Sleep, 200
                }
                Break
            }

            if (SearchElapsed >= 60000) {
                Notify("ERROR: No job found in 1 minute!")
                walk(200)
                Break
            }

            Loop, 3
            {
                i := A_Index
                img := files[i]
                ImageSearch, OutputVarX, OutputVarY, 10, 400, 145, 420, *50 %img%
                if (ErrorLevel == 0) {
                    Sleep, 200
                    if (flags[i]) {
                        Func(funcs[i]).Call()
                        Return
                    } else {
                        Notify("Skipping " . names[i] . " as per settings")
                        Cancel()
                        Sleep, 200
                        JobSearchStart := A_TickCount
                        Break
                    }
                }
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
        run(22350)
        SendInput, {d down}{w down}
        Sleep, 5000
        SendInput, {d up}{w up}
        Sleep, 200
        turn(-1)
        run(10000)
        Sleep, 100
        SendInput, {d down}
        Sleep, 500
        SendInput, {d up}
        run(5000)
        Sleep, 200
        Notify("Restock complete")
        StopJobTimer()
        Notify("Adjusting position")
        SendInput, {s down}
        Sleep, 300
        SendInput, {s up}
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
                Sleep, 200
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
        ; ImageSearch, OutputVarX, OutputVarY, 390, 575, 470, 595, *100 Clean.bmp
        ImageSearch, OutputVarX, OutputVarY, 440, 575, 465, 595, *100 Clean.bmp
        If (ErrorLevel != 0) {
            ImageSearch, OutputVarX, OutputVarY, 440, 575, 465, 595, *100 CleanB.bmp
        }
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
                Send, {Ctrl}
                SendInput, {a down}
                Sleep, 10000
                SendInput, {a up}
                Sleep, 100
                SendInput, {w down}
                Sleep, 15000
                SendInput, {w up}{a down}{s down}
                Sleep, 300
                SendInput, {s up}
                Sleep, 15000
                SendInput, {a up}
                Sleep, 200
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
        run(4500)
        SendInput, {w down}
        SendInput, {d down}
        Sleep, 10000
        SendInput, {w up}
        SendInput, {d up}
        Sleep, 200
        back(300)
        turn()
        run(5300)
        turn(-1)
        walk(9000)
        turn(-1)
        walk(2500)
        turn(-1)
        walk(700)
        checkCat()
        turn()
        turn()
        walk(700)
        turn()
        walk(2500)
        turn(-1)
        walk(13000)
        turn(-1)
        walk(2000)
        checkCat()
        turn()
        turn()
        walk(15500)
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
        run(8850)
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

    checkCat()
    {
        Notify("Checking for cat...")
        Loop, 5
        {
            ImageSearch, OutputVarX, OutputVarY, 440, 575, 465, 595, *100 Pick.bmp
            If (ErrorLevel == 0){
                Notify("Cat found! Catching...")
                SendInput, {e down}
                Sleep, 100
                SendInput, {e up}
                Sleep, 200
                Notify("Cat caught!")
                Return
            }
            Notify("No cat found, searching...")
            SendInput, {e down}
            Sleep, 100
            SendInput, {e up}
            Sleep, 100
        }
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
            Sleep, 200
            Send, {Ctrl}
            Sleep, 2000
            Notify("Approaching bank")
            Loop, 3
            {
                Click, 352, 630
                Sleep, 1500
            }
            Click, 420 , 593
            Sleep, 1000
            Send, {Ctrl}
            Sleep, 200
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
            Sleep, 2000
            Send, {Ctrl}
            Sleep, 2000
            Notify("Going back to work")
            Loop, 3
            {
                Click, 487 ,627
                Sleep, 1500
            }
            Sleep, 3000
            Click, 420 , 593
            Sleep, 3000
            Send, {Ctrl}
            Sleep, 200
            turn45(-1)
            Sleep, 2000
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
        Send, {Ctrl}
        Notify("Checking food...")
        ImageSearch, OutputVarX, OutputVarY, 390, 580, 475, 615, *20 NoFood1.bmp
        If (ErrorLevel == 0){
            Notify("Check Hotdog...")
            ImageSearch, OutputVarX, OutputVarY, 370, 720, 520, 780, *20 Hotdog.bmp
            If (ErrorLevel == 0){
                ; Loop,
                ; {
                Notify("Eating Hotdog...")
                SendInput, 1
                Sleep, 100
                Loop, 3
                {
                    MouseClick, Left , 425, 390
                    Sleep, 1000
                }
                Send, {Ctrl}
                Sleep, 200
                SendInput, 1
                ; Sleep, 1000
                ; ImageSearch, OutputVarX, OutputVarY, 390, 580, 475, 615, *20 FullFood.bmp
                ; If (ErrorLevel == 0){
                ;     Notify("Food restored!")
                ;     Send, {Ctrl}
                ;     Return
                ; }
                ; }
            }Else
            {
                Notify("Buying Hotdog...")
                back(800)
                Send, {a down}
                Sleep, 800
                Send, {a up}
                Send, e
                Sleep, 200
                MouseClickDrag, Left, 273, 338, 573, 339
                Sleep, 200
                MouseClick, Left, 429, 391
                Sleep, 2000
                Send, {w down}{a down}
                Sleep, 5000
                Send, {w up}{a up}
                Send, {Ctrl}
                reposition()
            }
        }Else{
            Notify("Food OK")
            Send, {Ctrl}
        }
    }

    checkCombat(){
        Notify("Checking combat...")
        ImageSearch, OutputVarX, OutputVarY, 440, 125, 461, 146, *100 Combat.bmp
        If (ErrorLevel == 0){
            Notify("In combat! Exiting...")
            Send, F8
            Shutdown, 2
        } Else {
            Notify("All Good!")
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
f4::turn45(-1)
~j::ExitApp

1GuiClose:
ExitApp
Return

GuiClose:
ExitApp
Return