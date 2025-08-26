#Requires AutoHotkey v2.0

; Array slice
slice(arr, start, end := "") {
    len := arr.Length
    if (end = "" || end > len)
        end := len
    if (start < 1 || start > len || start > end)
        return []
        
    ret := []
    loop (end - start) + 1 {
        ret.push(arr[A_Index + start - 1])  ; Adjust for 0-based indexing internally
    }
    return ret
}