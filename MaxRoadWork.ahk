#NoEnv
#Persistent
#SingleInstance Force
#MaxThreadsPerHotkey 2
#Include, Gdip_All.ahk
SetBatchLines -1
SetWorkingDir %A_ScriptDir%
CoordMode, Pixel, Screen
CoordMode, Mouse, Screen
SetTitleMatchMode, 2

Rounds := 0
turnDegrees := 90
pixelsPerDegree := 20
stepSize := 500
stepDelay := 5
pixelsFor90deg := 1800

if !pToken := Gdip_Startup()
{
    MsgBox, GDI+ failed to start.
    ExitApp
}

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

F3:: ; press F3 to toggle auto-walk
    toggle := !toggle
    if toggle
    {
        SetTimer, FindMarker, 50
        ToolTip, 🟢 Auto-Walk: ON
    }
    else
    {
        SetTimer, FindMarker, Off
        Send, {w up}{a up}{d up}
        ToolTip, 🔴 Auto-Walk: OFF
        Sleep, 800
        ToolTip
    }
return

FindMarker:
    ImageSearch, foundX, foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *100 marker.bmp
        ToolTip, % "Searching for marker..."

    if (ErrorLevel = 0)  ; found marker
    {
        centerX := A_ScreenWidth // 2
        delta := foundX - centerX

        ; if marker is near center -> move forward
        if (Abs(delta) < 40) {
            Send, {a up}{d up}
            Send, {w down}
        }
        else if (delta > 0) {
            ; marker is on right -> turn right
            Send, {w up}
            Send, {a up}
            Send, {d down}
            Sleep, 30
            Send, {d up}
        }
        else {
            ; marker is on left -> turn left
            Send, {w up}
            Send, {d up}
            Send, {a down}
            Sleep, 30
            Send, {a up}
        }
    }
    else
    {
        ; marker not found -> stop
        Send, {w up}{a up}{d up}
    }
return

~j::ExitApp
