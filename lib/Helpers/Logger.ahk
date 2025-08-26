#Requires AutoHotkey v2.0

currentDate := FormatTime(, "yyyy-MM-dd")

; provides timestamp naming convention for logs
getLog(logging_path) {
    newlog := Format("{1}\autoform_logs-{2}.log", logging_path, currentDate)
    if (!FileExist(newlog)) {
        FileAppend("", newlog)  ; Create an empty file
    }
    return newlog
}