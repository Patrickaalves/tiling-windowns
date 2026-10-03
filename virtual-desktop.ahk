; ================= GERENCIAMENTO DE DESKTOPS VIRTUAIS =================
; Módulo responsável pela navegação entre desktops e fixação de janelas

; Fixa todas as janelas abertas no monitor vertical
FixarJanelasMonitorVertical() {
    global vdExe
    if (!FileExist(vdExe))
        return

    monCount := MonitorGetCount()
    vertL := 0, vertT := 0, vertR := 0, vertB := 0
    temVertical := false

    loop monCount {
        MonitorGetWorkArea(A_Index, &mL, &mT, &mR, &mB)
        if ((mB - mT) > (mR - mL)) { ; Identifica o monitor vertical
            vertL := mL, vertT := mT, vertR := mR, vertB := mB
            temVertical := true
            break
        }
    }

    if (!temVertical)
        return

    ; Varre as janelas abertas e fixa qualquer uma presente no monitor vertical
    for hwnd in WinGetList() {
        if (WinGetMinMax("ahk_id " hwnd) == -1)
            continue

        title := WinGetTitle("ahk_id " hwnd)
        if (title == "" || title == "Program Manager" || title == "Settings")
            continue

        exStyle := WinGetExStyle("ahk_id " hwnd)
        if (exStyle & 0x00000080)
            continue

        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        if (w < 150 || h < 150)
            continue

        cx := x + (w / 2)
        cy := y + (h / 2)

        ; Se o centro da janela estiver dentro do monitor vertical, fixa-a
        if (cx >= vertL && cx <= vertR && cy >= vertT && cy <= vertB) {
            try Run(vdExe ' /pwh:' hwnd,, "Hide")
        }
    }
}

; Navega para o desktop virtual à esquerda preservando configuração do monitor vertical
NavigateDesktopLeft() {
    FixarJanelasMonitorVertical()
    RecriarBadgesGrupos()
    Send("^#{Left}")
}

; Navega para o desktop virtual à direita preservando configuração do monitor vertical
NavigateDesktopRight() {
    FixarJanelasMonitorVertical()
    RecriarBadgesGrupos()
    Send("^#{Right}")
}

; Recria e repina todos os badges de grupos para garantir visibilidade após troca de desktop
RecriarBadgesGrupos() {
    global gruposJanelas, grupoOverlays, vdExe
    if (!FileExist(vdExe))
        return
    for gId, grupo in gruposJanelas {
        for hwnd in grupo {
            if (grupoOverlays.Has(hwnd))
                try Run(vdExe ' /pwh:' grupoOverlays[hwnd].gui.Hwnd,, "Hide")
        }
    }
}

; Fixa manualmente a janela ativa em todos os desktops virtuais
PinCurrentWindow() {
    global vdExe
    if (FileExist(vdExe))
        Run(vdExe " /paw",, "Hide")
}
