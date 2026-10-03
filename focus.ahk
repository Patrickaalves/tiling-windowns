#Requires AutoHotkey v2.0
#SingleInstance Force

; ================= NAVEGAÇÃO DE FOCO ESPACIAL (WIN + SETAS) =================
#Left::FocusDirection("left")
#Right::FocusDirection("right")
#Up::FocusDirection("up")
#Down::FocusDirection("down")

FocusDirection(dir) {
    activeHwnd := WinExist("A")
    if (!activeHwnd)
        return

    ; Centro da janela ativa
    WinGetPos(&ax, &ay, &aw, &ah, "ahk_id " activeHwnd)
    acx := ax + (aw / 2)
    acy := ay + (ah / 2)

    bestHwnd := 0
    minDist := 99999999

    ; Percorre todas as janelas abertas
    for hwnd in WinGetList() {
        if (hwnd == activeHwnd)
            continue

        ; Ignora janelas sem título, minimizadas ou de sistema
        title := WinGetTitle("ahk_id " hwnd)
        if (title == "" || title == "Program Manager" || title == "Settings")
            continue

        if (WinGetMinMax("ahk_id " hwnd) == -1) ; Minimizada
            continue

        exStyle := WinGetExStyle("ahk_id " hwnd)
        if (exStyle & 0x00000080) ; WS_EX_TOOLWINDOW (painéis flutuantes/background)
            continue

        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        if (w < 150 || h < 150) ; Ignora elementos invisíveis ou minúsculos
            continue

        ; Centro da janela candidata
        cx := x + (w / 2)
        cy := y + (h / 2)

        dx := cx - acx
        dy := cy - acy

        ; Valida se a janela está na direção solicitada
        valid := false
        switch dir {
            case "left":
                if (dx < -30)
                    valid := true
            case "right":
                if (dx > 30)
                    valid := true
            case "up":
                if (dy < -30)
                    valid := true
            case "down":
                if (dy > 30)
                    valid := true
        }

        if (valid) {
            ; Pondera a distância para privilegiar o eixo principal da seta
            if (dir == "left" || dir == "right")
                dist := Abs(dx) + (Abs(dy) * 2.2)
            else
                dist := (Abs(dx) * 2.2) + Abs(dy)

            if (dist < minDist) {
                minDist := dist
                bestHwnd := hwnd
            }
        }
    }

    ; Foca na janela mais próxima encontrada
    if (bestHwnd)
        WinActivate("ahk_id " bestHwnd)
}

; ================= FECHAR JANELA EM FOCO (WIN + W) =================
#w:: {
    hwnd := WinExist("A")
    if (!hwnd)
        return

    ; Proteção: não fechar a Área de Trabalho ou a Barra de Tarefas por engano
    class := WinGetClass("ahk_id " hwnd)
    if (class == "Progman" || class == "WorkerW" || class == "Shell_TrayWnd")
        return

    ; Fecha a janela ativa de forma limpa (equivalente ao Alt + F4)
    WinClose("ahk_id " hwnd)
}