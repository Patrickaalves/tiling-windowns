; ================= FUNÇÕES UTILITÁRIAS COMUNS =================
; Módulo compartilhado com funções reutilizáveis em todo o projeto

; Verifica se uma janela é válida e visível
IsValidWindow(hwnd) {
    if (!hwnd)
        return false

    title := WinGetTitle("ahk_id " hwnd)
    if (title == "" || title == "Program Manager" || title == "Settings")
        return false

    if (WinGetMinMax("ahk_id " hwnd) == -1) ; Minimizada
        return false

    exStyle := WinGetExStyle("ahk_id " hwnd)
    if (exStyle & 0x00000080) ; WS_EX_TOOLWINDOW (painéis flutuantes/background)
        return false

    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    if (w < 150 || h < 150) ; Ignora elementos invisíveis ou minúsculos
        return false

    return true
}

; Obtém o monitor atual de uma janela baseado em sua posição
GetWindowMonitor(hwnd) {
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    cx := x + (w / 2)
    cy := y + (h / 2)

    monCount := MonitorGetCount()
    loop monCount {
        MonitorGet(A_Index, &mL, &mT, &mR, &mB)
        if (cx >= mL && cx <= mR && cy >= mT && cy <= mB) {
            return A_Index
        }
    }
    return 1 ; Padrão: monitor 1
}

; Restaura uma janela se estiver maximizada
RestoreIfMaximized(hwnd) {
    if (WinGetMinMax("ahk_id " hwnd) == 1)
        WinRestore("ahk_id " hwnd)
}

; Detecta layout do monitor (vertical ou horizontal)
IsMonitorVertical(monIndex) {
    MonitorGetWorkArea(monIndex, &mL, &mT, &mR, &mB)
    return ((mB - mT) > (mR - mL))
}

; Encontra o monitor vertical se existir
FindVerticalMonitor() {
    monCount := MonitorGetCount()
    loop monCount {
        if (IsMonitorVertical(A_Index))
            return A_Index
    }
    return 0
}
