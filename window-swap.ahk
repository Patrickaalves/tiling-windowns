; ================= TROCA DE POSIÇÃO DE JANELAS (WIN + ALT + SETAS) =================
; Módulo responsável por trocar posição entre duas janelas

SwapWindows() {
    hwndA := WinExist("A")
    if (!hwndA)
        return

    WinGetPos(&ax, &ay, &aw, &ah, "ahk_id " hwndA)
    acx := ax + (aw / 2)
    acy := ay + (ah / 2)

    monCount := MonitorGetCount()
    currentMon := 1
    loop monCount {
        MonitorGet(A_Index, &mL, &mT, &mR, &mB)
        if (acx >= mL && acx <= mR && acy >= mT && acy <= mB) {
            currentMon := A_Index
            break
        }
    }
    MonitorGetWorkArea(currentMon, &WL, &WT, &WR, &WB)

    hwndB := 0
    bx := 0, by := 0, bw := 0, bh := 0

    for hwnd in WinGetList() {
        if (hwnd == hwndA)
            continue

        title := WinGetTitle("ahk_id " hwnd)
        if (title == "" || title == "Program Manager" || title == "Settings")
            continue

        if (WinGetMinMax("ahk_id " hwnd) == -1)
            continue

        exStyle := WinGetExStyle("ahk_id " hwnd)
        if (exStyle & 0x00000080)
            continue

        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        if (w < 200 || h < 200)
            continue

        cx := x + (w / 2)
        cy := y + (h / 2)

        if (cx >= WL && cx <= WR && cy >= WT && cy <= WB) {
            hwndB := hwnd
            bx := x, by := y, bw := w, bh := h
            break
        }
    }

    if (hwndB) {
        WinRestore("ahk_id " hwndA)
        WinRestore("ahk_id " hwndB)

        WinMove(bx, by, bw, bh, "ahk_id " hwndA)
        WinMove(ax, ay, aw, ah, "ahk_id " hwndB)

        WinActivate("ahk_id " hwndA)
    }
}
