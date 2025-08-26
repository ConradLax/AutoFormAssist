#Requires AutoHotkey v2.0

waitFor(inputKey) {
    OnKeyDown(ih, VK, SC) {
        global keyPressed
        keyPressed := true
        ; MsgBox("Key pressed: " . SC) ; Fallback debug
    }

    key := StrSplit(inputKey, '"')[2]
    MsgBox("Script paused. Press the key '" key "' to continue.")

    global keyPressed := false  ; Flag to track if the target key was pressed

    ; create InputHook and set up event listener
    ih := InputHook("V") ; "V" allows user keystrokes to be sent to the active window
    ih.KeyOpt(key, "N S")  ; "N" notifies OnKeyDown when `key` is pressed; "S" suppresses `key` after pressing it (keystroke is not displayed) 
    ih.OnKeyDown := OnKeyDown
    ih.Start()
    
    ; wait until the target key is pressed
    while !keyPressed {
        Sleep(10)  ; prevent excessive CPU usage
    }
    ih.KeyOpt(key, "-S") ; unsuppress `key` 
    ih.Stop() ; stop the InputHook
}