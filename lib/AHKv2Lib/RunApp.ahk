#Requires AutoHotkey v2.0
#Include ..\Comms\PushNotifier.ahk

; CONFIG VALUES
instance_id := IniRead("config\config.ini", "DEFAULT", "instance_id", "0")

runApp(inputKey) {
    app := StrSplit(inputKey, '"')[2]

    ; read app-to-URI mapping from config
    winTitle := IniRead("config\config.ini", "AppMappings", app, "")

    if (winTitle = "") {
        notif_message := "Application: " . inputKey . " did not run. Check instance #" . instance_id
        notify(notif_message)
        MsgBox "No mapping found for " . app
        return false
    }
    try {
        Run app, , 'Max'
        Sleep(500)

        ; try to activate the window
        Loop 5 {
            if WinExist(winTitle) {
                WinActivate
                return true
            }
            Sleep(500)
        }
        notif_message := "App window: " . winTitle . " not found. Check instance #" . instance_id
        notify(notif_message)
        MsgBox "App window " . winTitle . " not found."
        return false
    }
    catch{
        notif_message := "Error launching: " . app . ". Check instance #" . instance_id
        notify(notif_message)
        MsgBox "Error launching " . app
        return false
    }
}