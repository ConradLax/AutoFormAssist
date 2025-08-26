#Requires AutoHotkey v2.0

appState_path := "C:\Temp"
appState_file_path := appState_path "\app-state.txt"

saveState(currIndex) {
    try {
        ; create Temp directory if it does not exist yet
        if not DirExist(appState_path) {
            DirCreate appState_path
        }

        ; create app-state file if it does not exist yet
        ; clear app-state (done with FileOpen with 'w' Flag. See https://www.autohotkey.com/docs/v2/lib/FileOpen.htm#Flags)
        appState_file := FileOpen(appState_file_path, 'w')

        ; write current index to app-state
        currIndex_str := String(currIndex)
        appState_file.Write(currIndex_str)

        ; close file
        appState_file.Close()

        return true
    } catch Error as e {
        ; return Boolean indicating whether write is successful or not
        return false
    }
}

continueState(size) {
    ; check if app-state exists
    if not FileExist(appState_file_path) {
        return false
    }

    try {
        ; read app-state
        currIndex := FileRead(appState_file_path)

        ; get index (check if integer)
        if (IsInteger(currIndex)) {
            ; ask if use current index or start over
            if (currIndex == size) {
                result := MsgBox(Format("AFA unexpectedly stopped previously at index {}. `nTry running it again?`n`nCancel to startover.", currIndex),, "RetryCancel Icon? Default3")
            }
            ; ask if use current index, or go the next index, or start over
            else {
                result := MsgBox(Format("AFA unexpectedly stopped previously at index {}. `nTry running it again? Or Continue with the next index?`n`nCancel to startover.", currIndex),, "CancelTryAgainContinue Icon? Default3")
            }
            ; return index
            if (result = "Cancel") {
                return 0
            }
            else if (result = "Retry") {
                return Integer(currIndex)
            }
            else if (result = "TryAgain") {
                return Integer(currIndex)
            }
            else if (result = "Continue") {
                return Integer(currIndex) + 1
            }
            return 1
        }

        return false
        
    } catch Error as e {
        return false
    }
}

; clear app-state AFTER complete automation
clearState(file_path := appState_file_path) {
    ; clear content of app-state
    appState_file := FileOpen(file_path, 'w')
    appState_file.Close()
}