#Requires AutoHotkey v2.0
#Include ..\AHKv2Lib\ShinsImageScanClass.ahk
#Include ..\Helpers\AppState.ahk
#Include ..\Comms\PushNotifier.ahk

; CONFIG VALUES
instance_id := IniRead("config\config.ini", "DEFAULT", "instance_id", "0")
maxRetries := IniRead("config\config.ini", "DEFAULT", "maxRetries", 5)
scan_main_monitor_only := IniRead("config\config.ini", "DEFAULT", "scan_main_monitor_only", "Y")
OTPRegex := IniRead("config\config.ini", "OTP", "OTPRegex", "\b\d{4,6}\b")
clickThrice := IniRead("config\config.ini", "OTP", "ClickThrice", "1")
; OTPRegex := "\b\d{4,6}\b"

; flag for stopping retry loop
stopRetry := false

`:: {
    global stopRetry
    stopRetry := true
}

global scanInstance := ShinsImageScanClass()

getImagePath(filename, imageCounter) {
    return "traversals/Logs-" . StrReplace(filename,".csv","") . "/clickable_element_" . imageCounter++ . ".png"
}

clickImage(filename, &imageCounter, delay_duration, isForOTP := false) {
    global stopRetry, scanInstance

    scan := scanInstance
    imagePath := "traversals/Logs-" . StrReplace(filename,".csv","") . "/clickable_element_" . imageCounter++ . ".png"
    
    if(!FileExist(imagePath)) {
        notif_message := imagePath . " does not exist. Check instance #" . instance_id
        notify(notif_message)
        MsgBox(imagePath . " does not exist.")
        return false
    }
    
    tryCount := 0

    ; Move the mouse away to bypass hover effects
    MouseGetPos(&tempImgx, &tempImgy)
    MouseMove(0, 0, 0)
    BlockInput("Mouse")

    if(StrCompare(scan_main_monitor_only,"Y",0) == 0) {
        while (tryCount < maxRetries) {
            ; check if stopRetry flag is set
            if (stopRetry) {
                MsgBox("Image-search stopped by user. " . "`nCurrently at " . imagePath . ". Click the said image to continue.")
                ; reset stopRetry flag
                stopRetry := false
                return false
            }
            if (scan.Image(imagePath,0,&imgx, &imgy,1,0)) {

                if (isForOTP) {
                    ; MouseClick("L",imgx-60,imgy, 2)

                    ; put all msg text to clipboard 
                    if (clickThrice = "1") {
                        MouseClick("L",imgx,imgy, 3)
                    }
                    else MouseClick("L",imgx,imgy, 2)

                    ; clear clipboard
                    A_Clipboard := ""
                    ; copy text that should be selected from the previous 3-click action
                    if (clickThrice != "1") {
                        Sleep(delay_duration)
                        Send "^a"
                    }
                    Sleep(delay_duration)
                    Send "^c"
                    
                    ; get OTP from clipboard
                    acquiredOTP := getOTPFromClipboard(OTPRegex, delay_duration)
                    if acquiredOTP = false {
                        notif_message := "Error in extracting OTP. Check instance #" . instance_id
                        notify(notif_message)
                        return false
                    }
                    ; set current clipboard's top stack to the acquired OTP
                    A_Clipboard := acquiredOTP
                }
                else {
                    MouseClick("L",imgx,imgy)
                }
                ; reset stopRetry flag
                stopRetry := false

                break
            } else {
                Sleep(delay_duration)
                tryCount++
                if(tryCount >= maxRetries) {
                    ; reset stopRetry flag
                    stopRetry := false
                    notif_message := "Max Retries Reached. " . "`n" . imagePath . " not found. Check instance #" . instance_id
                    notify(notif_message)
                    MsgBox("Max Retries Reached. " . "`n" . imagePath . " not found.")
                    return false
                }
                continue
            }
        }
    } else {
        ; ImageSearch version, scans all monitors
        CoordMode("Pixel", "Screen")
        widthX := 0
        heightY := 0
        scan.GetImageDimensions(imagePath, &widthX, &heightY)
        while (tryCount < maxRetries) {
            if (ImageSearch(&imgx, &imgy, 0, 0, SysGet(78), SysGet(79), imagePath)) {
                MouseClick("L",imgx+widthX//2,imgy+heightY//2)
                break
            } else {
                Sleep(delay_duration)
                tryCount++
                if(tryCount >= maxRetries) {
                    notif_message := "Max Retries Reached. " . "`n" . imagePath . " not found. Check instance #" . instance_id
                    notify(notif_message)
                    MsgBox("Max Retries Reached. " . "`n" . imagePath . " not found.")
                    return false
                }
                continue
            }
        }
    }
    MouseMove(tempImgx, tempImgy, 0)
    BlockInput("Off")
}

getOTPFromClipboard(OTPRegex, delay_duration) {
    if !ClipWait(delay_duration//1000) {
        notif_message := "The attempt to copy OTP to clipboard failed." . ". Check instance #" . instance_id
        notify(notif_message)
        MsgBox("The attempt to copy OTP to clipboard failed.")
        return false
    }

    ; copied successfully to clipboard
    ClipboardContent := A_Clipboard

    if(RegExMatch(ClipboardContent, OTPRegex, &OTP)) {
        return OTP[0]
    }
    else {
        notif_message := "OTP not found in clipboard." . ". Check instance #" . instance_id
        notify(notif_message)
        MsgBox("OTP not found in clipboard.")
        return false
    }
}

; test
; OTP := getOTPFromClipboard(OTPRegex, 2000)
; MsgBox "Extracted OTP: " . OTP

; A_Clipboard := OTP