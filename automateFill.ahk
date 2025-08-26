#Include lib\AHKv2Lib\ImagePut.ahk
#Include lib\AHKv2Lib\_JXON.ahk
#Include lib\AHKv2Lib\Array.ahk
#include lib\AHKv2Lib\ShinsImageScanClass.ahk
#Include lib\Helpers\ArrayHelper.ahk
#Include lib\Helpers\Logger.ahk
#Include lib\Helpers\AppState.ahk
#Include lib\AHKv2Lib\WaitKey.ahk
#Include lib\AHKv2Lib\ClickImageEventHandler.ahk
#Include lib\AHKv2Lib\RunApp.ahk
#Include lib\Comms\PushNotifier.ahk
#SingleInstance Force

; FOR INPUT file:
; 1. Change all [text] with any appropriate String
; (maybe save the original input in Keylogger to give user an idea what to input)
; 2. Change all [arrow] with the arrow actions needed to get desired input in dropdown boxes/radio buttons 
;   FORMAT: [button_press_count]:[arrow_button_to_press],[button_press_count]:[arrow_button_to_press],...
;   arrow_button_to_press formats: {Up}, {Down}, {Left}, {Right}
;   example: 2:{Down} or 2:{Down},1:{Up}


; CONFIG VALUES
logging_path := IniRead("config\config.ini", "DEFAULT", "logging_path", "logs\")
screenshot_path := IniRead("config\config.ini", "DEFAULT", "screenshot_path", "screenshots\")
filename_structure := IniRead("config\config.ini", "DEFAULT", "filename_structure", "1")
filename_image_type := IniRead("config\config.ini", "DEFAULT", "filename_image_type", "png")
enable_notifier := IniRead("config\config.ini", "PushNotifier", "enable", "N")
enable_curr_image_display := IniRead("config\config.ini", "DisplayCurrentImage", "enable", "N")


; VARIABLES
actual_inputdir_index := 1
current_inputdir_index := 0
current_inputkey := ""
current_inputkey_status := false


; LOG-RELATED INITIALIZATIONS
logging_path_with_date := getLog(logging_path)

; Logging function
log(level, message) {
    global logging_path_with_date
    ; Check if the log file exists, create it if it doesn't
    log_message := Format("{1} [{2}] : {3}`n", FormatTime(, "yyyy-MM-dd HH:mm:ss"), level, message)
    FileAppend log_message, logging_path_with_date
}

; Log startup
log("INFO", "Script started.")

; READ config.ini
log("INFO", "Extracting values from config.ini")



; SCREENSHOT-RELATED INITIALIZATIONS
; Ensure the screenshot_path ends with a backslash
if !RegExMatch(screenshot_path, "\\$") {
    screenshot_path .= "\"
}
; put outputs in date dir
time := FormatTime(, "yyyy-MM-dd")
screenshot_path := screenshot_path . time . "\"
DirCreate screenshot_path

if (!FileExist(screenshot_path) or !InStr(FileExist(screenshot_path), "D")) {
    log("ERROR", "Invalid screenshot_path: " . screenshot_path)
    MsgBox "Invalid screenshot_path: " . screenshot_path
    ExitApp(3)
}

log("INFO", "Config values read: Screenshot path: " . screenshot_path . ", Filename indices: " . filename_structure . ", Image ext: " . filename_image_type)

;variable to hold the Printscreen count
keypress_count := 0



; COMMANDLINE ARGS
; command line argument error handling 
if A_Args.Length < 1 {
    MsgBox "This script requires an input filename argument."
    log("ERROR", "Input filename argument missing.")
    ExitApp(3)
}

if A_Args.Length > 3 {
    MsgBox "This script has only 2 arguments: input filename (REQUIRED) and delay duration (OPTIONAL)."
    log("ERROR", "Too many arguments provided.")
    ExitApp(3)
}

if (A_Args.Length == 2 || A_Args.Length == 3) {

    if(IsNumber(A_Args.Get(2))) {
        delay_duration := A_Args.Get(2)
        log("INFO", "Delay duration set to " . delay_duration)
    }
    else {
        MsgBox "Delay duration (2nd argument) is not a number."
        log("ERROR", "Non-numeric delay duration provided.")
        ExitApp(3)
    }
}

; File read + error handling
; converts Input file parameter into the corresponding keylog file

; checks if A_Args.Get(1) is a full input path or relative path (esp. in inputs folder)
new_address := StrReplace(A_Args.Get(1), "/", "\")
if(FileExist(A_Args.Get(1))){
    SplitPath new_address, &name, &dir

    logdir := "traversals"
    inputdir := dir
    inputFileName_arg := name
    filename := StrReplace(inputFileName_arg, "Input-", "")
}
else {
    logdir := "traversals"
    inputdir := "inputs"
    inputFileName_arg := new_address
    filename := StrReplace(inputFileName_arg, "Input-", "")
}


logdir_with_date := Format("{1}\Logs-{2}", logdir, filename)
logdir_with_date := StrReplace(logdir_with_date, ".csv", ".txt")
inputdir_with_date := Format("{1}\Input-{2}", inputdir, filename)

if(!FileExist(logdir_with_date)) {
    MsgBox Format("Keylogger output file {1} does not exist in {2} directory. (Hint) Have you recorded input keys with Keylogger?", logdir_with_date, logdir)
    log("ERROR", "Keylogger output file does not exist: " . logdir_with_date)
    ExitApp(3)
}

if(!FileExist(inputdir_with_date)) {
    MsgBox Format("Input file {1} does not exist in {2} directory. (Hint) Have you recorded and input keys with Keylogger and replaced input values in \inputs?", inputdir_with_date, inputdir)
    log("ERROR", "Input file does not exist: " . inputdir_with_date)
    ExitApp(3)
}

inputs_Raw := FileRead(inputdir_with_date, "UTF-8")
inputs_all := StrSplit(RTrim(inputs_Raw, "`r`n"), "`n")
log("INFO", "Input file read successfully.")

inputKeys_Raw := FileRead(logdir_with_date, "UTF-8")
inputKeys := StrSplit(inputKeys_Raw, "`n")
log("INFO", "Keylogger file read successfully.")




; hotkey for starting automation
#s:: {
    global inputs_all
    global inputKeys
    global delay_duration
    inputs_idx := 1
    global keypress_count
    global actual_inputdir_index
    global current_inputdir_index
    global current_inputkey
    global current_inputkey_status
    global filename
    
    result_Idx_From_continueState := 0

    if(StrUpper(enable_curr_image_display) = "Y") {
        MyGui := Gui()
        MyGui := GUI("+AlwaysOnTop +ToolWindow -Caption") 
        currentPicture := MyGui.Add("Picture", "w48.184 h-1", getImagePath(filename, 0))
        MyGui.Show("x0 y0")
    }


    imageCounter := 0
    name := StrReplace(filename, "csv", "")

    log("INFO", "Automation started.")

    ; start at remaining inputs
    if(A_Args.Length == 3) {
        actual_inputdir_index := A_Args.Get(3)
    }
    else {
        result_Idx_From_continueState := continueState(inputs_all.Length)
    }
    if(IsInteger(result_Idx_From_continueState) AND Integer(result_Idx_From_continueState) != false) {
        actual_inputdir_index := result_Idx_From_continueState
        remaining_inputs := slice(inputs_all, actual_inputdir_index, inputs_all.Length)
        inputs_all := remaining_inputs
    }
    

    ; loops all input text by line in .csv file
    for index_csv, inputs_row in inputs_all {

        ; reset imageCounter, the index for clickable image's filename
        imageCounter := 0

        ; save current index to current_inputdir_index
        current_inputdir_index := index_csv

        ; Log the processing progress
        log("INFO", Format("Processing entry {1} of {2}...", index_csv, inputs_all.Length))
        
        keypress_count := 0


        ; parses a line in input CSV
        inputs := Array()
        loop parse inputs_row, 'CSV' {
            inputs.Push A_LoopField
        }

        ; screenshot filename for current line in input CSV
        screenshot_filename := ""
        screenshot_filename_idx := StrSplit(filename_structure, "|")
        for idx in screenshot_filename_idx {
            screenshot_filename := screenshot_filename . inputs.Get(idx)
        }
        multi_screenshot_idx := 1

        ; loops all keystrokes in a line
        for index_nav, inputKey in inputKeys {
            inputKey := Trim(inputKey, "`r`n")
            if(StrCompare(inputKey, "[text]") == 0) {
                SendInput inputs.Get(inputs_idx++)
            }
            ; add delay for Enter and Space(used as a Select button in some UIs), which are most of the time used in executing actions with loading time
            else if(StrCompare(inputKey, "{Enter}") == 0) {
                SetKeyDelay 400
                SendEvent inputKey
                Sleep(500)
            }
            else if(StrCompare(inputKey, A_Space) == 0) {
                SetKeyDelay 400
                SendEvent inputKey
                Sleep(500)
            }
            else if(StrCompare(inputKey, "!{PrintScreen}") == 0) {
                ; update screenshot index for multiple saving screenshots
                screenshot_filename_full := screenshot_filename . "_" . multi_screenshot_idx++ . "." . filename_image_type

                coords := [0, 0, A_ScreenWidth, A_ScreenHeight]
                
                ImagePutFile(ImagePutScreenshot(coords), screenshot_path . screenshot_filename_full)

                log("INFO", Format("Screenshot saved: {1}", screenshot_path . screenshot_filename))
            }
            else if(StrCompare(inputKey, "{PrintScreen}") == 0) {
                ; update screenshot index for multiple saving screenshots
                screenshot_filename_full := screenshot_filename . "_" . multi_screenshot_idx++ . "." . filename_image_type

                ImagePutFile("A", screenshot_path . screenshot_filename_full)

                log("INFO", Format("Screenshot saved: {1}", screenshot_path . screenshot_filename))
            }
            else if(StrCompare(inputKey, "{F11}") == 0) {
                Sleep(delay_duration)
            }

            else if(RegExMatch(inputKey, '({KeyWait ").("})')) {
                waitFor(inputKey)
            }

            else if(RegExMatch(inputKey, '({Run ").+("})')) {
                open_app_res := runApp(inputKey)
                if (open_app_res = false) {
                    waitFor('`"```"')
                }
            }

            else if(InStr(inputKey, "{Click}")) {
                imagePath := getImagePath(filename, imageCounter)
                if(StrUpper(enable_curr_image_display) = "Y" and FileExist(imagePath))
                    currentPicture.Value := imagePath
                res := clickImage(filename, &imageCounter, delay_duration)
                if (res = false) {
                    ; MsgBox "Press ' `` ' to continue. Press Ctrl+Esc to exit."
                    waitFor('`"```"')
                    ; saveState(actual_inputdir_index)
                    ; ExitApp(1)
                }
            }

            else if (StrCompare(inputKey, "{Click OTP}") == 0) {
                res := clickImage(filename, &imageCounter, delay_duration, true)
                if (res = false) {
                    ; MsgBox "Press ' `` ' to continue. Press Ctrl+Esc to exit."
                    waitFor('`"```"')
                    ; saveState(actual_inputdir_index)
                    ; ExitApp(1)
                }
            }

            else {
                ; delay accounting for general hardware\UI latency
                SetKeyDelay 10
                SendEvent inputKey
                SetKeyDelay 0
            }
        }
        log("INFO", Format("Processed entry {1} of {2}.", index_csv, inputs_all.Length))
        ; reset inputs_idx for new line in .csv (i.e., next set of form input)
        inputs_idx := 1

        ; increment actual index for entire input
        ; moved at last line of loop to ensure that it increments only when the current action is completed
        actual_inputdir_index++
    }
    log("INFO", "Automation finished.")

    if(StrCompare(IniRead("config\config.ini", "DEFAULT", "enable_complete_prompt", "Y"), "Y") == 0) {
        MsgBox "Done. Processed " . inputs_all.length . " rows."
    }

    if (StrUpper(enable_curr_image_display) = "Y")
        MyGui.Destroy()
    clearState()
    ExitApp(0)
}

^Esc:: {
    global actual_inputdir_index
    global current_inputdir_index
    saveState(actual_inputdir_index)

    log("INFO", Format("Stopped at line {1}: {2}", actual_inputdir_index, inputs_all[current_inputdir_index]))
    log("INFO", "Script terminated.")

    ExitApp(4)
}

^Q:: {
    notif_message := "Someone clicked Ctrl + Q"
    notify(notif_message)
}

notify(notif_message) {
    if StrUpper(enable_notifier) != "Y" {
        return
    }
    send_notif_res := sendNotification(notif_message)
    if(send_notif_res["status"] = 1 OR send_notif_res["status"] = "1") 
        log("INFO", "Notification sent successfully. {message: " . notif_message . ", request_id: " . send_notif_res["response"] . " }")
    else
        log("WARNING", "Failed in sending notification. {message: " . notif_message . ", error: " . send_notif_res["error"] . ", request_id: " . send_notif_res["response"] . " }")
}