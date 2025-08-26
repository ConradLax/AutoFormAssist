#Include ..\AHKv2Lib\_JXON.ahk

maxRetries := IniRead("config\config.ini", "DEFAULT", "maxRetries", 5)

url := IniRead("config\config.ini", "PushNotifier", "url", "")
user_key := IniRead("config\config.ini", "PushNotifier", "user_key", "")
app_token := IniRead("config\config.ini", "PushNotifier", "app_token", "")

sendNotification(message) {
    data := '{"message": "' . message . '"}'
    
    try {
        whr := ComObject("WinHttp.WinHttpRequest.5.1")
        ; open request in async mode (true)
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(data)
        ; wait for the server response
        whr.WaitForResponse()

        httpStatus := whr.Status
        responseText := whr.ResponseText


        if (httpStatus != 200 or httpStatus != 202) {
            ; MsgBox("HTTP Error: " httpStatus "`nResponse: " responseText)
            return Map("status", -1, "error", "HTTP Error " . httpStatus, "response", responseText)
        }
        ; return successful status
        else {
            return Map("status", 1, "response", responseText)
        }
    } catch {
        ; MsgBox("An error occurred: " A_LastError)
        return Map("status", -4, "error", "WinHttpRequest Failed", "response", A_LastError)
    }
}

; FOR PUSHOVER
; sendNotification(message) {
;     url := "https://api.pushover.net/1/messages.json"
;     data := "token=" . app_token . "&user=" . user_key . "&message=" . message
    
;     try {
;         whr := ComObject("WinHttp.WinHttpRequest.5.1")
;         ; open request in async mode (true)
;         whr.Open("POST", url, true)
;         whr.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
;         whr.Send(data)
;         ; wait for the server response
;         whr.WaitForResponse()

;         httpStatus := whr.Status
;         responseText := whr.ResponseText
        

;         if (httpStatus != 200) {
;             ; MsgBox("HTTP Error: " httpStatus "`nResponse: " responseText)
;             return Map("status", -1, "error", "HTTP Error " . httpStatus, "response", responseText)
;         }

;         ; attempt to parse JSON response
;         try {
;             responseObj := Jxon_Load(&responseText)
;             ; assumption: status attribute is always a Number
;             if responseObj.Has("status") && (responseObj["status"] = 1 OR responseObj["status"] = "1") {
;                 return Map("status", responseObj["status"], "error", "", "response", responseText)
;                 ; MsgBox("Success! Request ID: " responseObj["request"])
;         } else {
;             return Map("status", -2, "error", "API Error: No status JSON key.", "response", responseText)
;             ; MsgBox("API Error: " responseText)
;         }
;         return responseObj
;         } catch {
;             ; MsgBox("Failed to parse JSON response.`nRaw Response: " responseText)
;             return Map("status", -3, "error", "Invalid JSON", "response", responseText)
;         }
;     } catch {
;         ; MsgBox("An error occurred: " A_LastError)
;         return Map("status", -4, "error", "WinHttpRequest Failed", "response", A_LastError)
;     }
; }
