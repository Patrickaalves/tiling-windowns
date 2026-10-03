#Requires AutoHotkey v2.0
#SingleInstance Force

; ================= EXECUÇÃO ELEVADA (ADMINISTRADOR) =================
if (!A_IsAdmin) {
    try {
        Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
        ExitApp()
    }
}

; Caminho do utilitário de persistência
global vdExe := A_ScriptDir "\VirtualDesktop11.exe"

; ================= GERENCIAMENTO DE JANELAS EM GRADE (WIN + T) =================
#t:: {
    hwndAlvo := WinExist("A")
    if (!hwndAlvo)
        return

    monCount := MonitorGetCount()
    currentMon := 1
    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwndAlvo)
    wMidX := wx + (ww / 2)
    wMidY := wy + (wh / 2)

    loop monCount {
        MonitorGet(A_Index, &mL, &mT, &mR, &mB)
        if (wMidX >= mL && wMidX <= mR && wMidY >= mT && wMidY <= mB) {
            currentMon := A_Index
            break
        }
    }

    MonitorGetWorkArea(currentMon, &WL, &WT, &WR, &WB)
    workW := WR - WL
    workH := WB - WT

    marginOuter := 10
    marginInner := 12
    isVertical := (workH > workW)

    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow")
    overlay.BackColor := "111827"
    overlay.SetFont("s22 bold cE5E7EB", "Segoe UI")
    caixas := Map()

    if (isVertical) {
        nCols := 2
        nRows := 2
        hudW := Round(Min(workW * 0.85, 340))
        hudH := hudW

        zonasPermitidas := Map(
            "q", {row: 1, col: 1}, "w", {row: 1, col: 2},
            "a", {row: 2, col: 1}, "s", {row: 2, col: 2}
        )
    } else {
        nCols := 3
        nRows := 2
        hudW := 600
        hudH := 340

        zonasPermitidas := Map(
            "q", {row: 1, col: 1}, "w", {row: 1, col: 2}, "e", {row: 1, col: 3},
            "a", {row: 2, col: 1}, "s", {row: 2, col: 2}, "d", {row: 2, col: 3}
        )
    }

    hudPad := 16
    gap := 10

    hudX := WL + (workW - hudW) / 2
    hudY := WT + (workH - hudH) / 2

    cardW := (hudW - (2 * hudPad) - ((nCols - 1) * gap)) / nCols
    cardH := (hudH - (2 * hudPad) - ((nRows - 1) * gap)) / nRows

    for tecla, coord in zonasPermitidas {
        bx := hudPad + ((coord.col - 1) * (cardW + gap))
        by := hudPad + ((coord.row - 1) * (cardH + gap))
        caixas[tecla] := overlay.AddText(
            "x" Round(bx) " y" Round(by)
            " w" Round(cardW) " h" Round(cardH)
            " Center 0x200 Background1F2937",
            StrUpper(tecla)
        )
    }

    overlay.Show("x" Round(hudX) " y" Round(hudY) " w" hudW " h" hudH " NoActivate")
    WinSetTransparent(235, overlay.Hwnd)

    ih1 := InputHook("L1 T2")
    ih1.Start()
    ih1.Wait()
    t1 := StrLower(ih1.Input)

    if (!zonasPermitidas.Has(t1)) {
        overlay.Destroy()
        return
    }

    try caixas[t1].Opt("Background2563EB")

    ih2 := InputHook("L1 T0.8")
    ih2.Start()
    ih2.Wait()
    t2 := StrLower(ih2.Input)

    if (!zonasPermitidas.Has(t2))
        t2 := t1

    overlay.Destroy()

    colW := (workW - (2 * marginOuter) - ((nCols - 1) * marginInner)) / nCols
    rowH := (workH - (2 * marginOuter) - ((nRows - 1) * marginInner)) / nRows

    z1 := zonasPermitidas[t1]
    z2 := zonasPermitidas[t2]

    minCol := Min(z1.col, z2.col)
    maxCol := Max(z1.col, z2.col)
    minRow := Min(z1.row, z2.row)
    maxRow := Max(z1.row, z2.row)

    spanCols := (maxCol - minCol) + 1
    spanRows := (maxRow - minRow) + 1

    finalX := WL + marginOuter + ((minCol - 1) * (colW + marginInner))
    finalY := WT + marginOuter + ((minRow - 1) * (rowH + marginInner))
    finalW := (spanCols * colW) + ((spanCols - 1) * marginInner)
    finalH := (spanRows * rowH) + ((spanRows - 1) * marginInner)

    WinRestore("ahk_id " hwndAlvo)
    WinMove(Round(finalX), Round(finalY), Round(finalW), Round(finalH), "ahk_id " hwndAlvo)

    ; Se a janela foi posicionada no monitor vertical, fixa-a em todas as telas
    if (isVertical && FileExist(vdExe)) {
        try Run(vdExe ' /pwh:' hwndAlvo,, "Hide")
    }
}

; ================= FUNÇÃO PARA FIXAR TUDO NO MONITOR VERTICAL =================
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

; ================= NAVEGAÇÃO DE DESKTOP (PRESERVA MONITOR VERTICAL) =================
; Ao navegar com Win + Ctrl + Setas, fixa tudo no vertical antes de trocar a tela
^#Left:: {
    FixarJanelasMonitorVertical()
    Send("^#{Left}")
}

^#Right:: {
    FixarJanelasMonitorVertical()
    Send("^#{Right}")
}

; ================= ATALHOS GERAIS =================
; Win + P: Fixa manualmente a janela ativa (útil se você a arrastou com o mouse)
#p:: {
    global vdExe
    if (FileExist(vdExe))
        Run(vdExe " /paw",, "Hide")
}

; Win + W: Fecha a janela em foco
#w:: {
    hwnd := WinExist("A")
    if (!hwnd)
        return
    class := WinGetClass("ahk_id " hwnd)
    if (class == "Progman" || class == "WorkerW" || class == "Shell_TrayWnd")
        return
    Send("!{F4}")
}

; Win + Espaço: PowerToys Run
#Space::Send("#!{Space}")

; Win + Enter / Win + Alt + Enter: Terminal
#Enter::Run("wt")
#!Enter::Run("*RunAs wt")

; Win + Alt + R: Recarregar script
#!r::Reload()

; ================= TROCA DE POSIÇÃO DE JANELAS (WIN + ALT + SETAS) =================
#!Left::SwapWindows()
#!Right::SwapWindows()

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

; ================= DESATIVAR MENU INICIAR NA TECLA WIN AVULSA =================
; Impede a abertura do Menu Iniciar ao teclar Win sozinho,
; mas mantém 100% funcionais todos os atalhos (Win + T, Win + Espaço, etc.):
~LWin::Send("{Blind}{vkE8}")
~RWin::Send("{Blind}{vkE8}")

; Ao pressionar e soltar a tecla Win sozinha, abre o PowerToys Run:
~LWin up:: {
    if (A_PriorKey == "LWin")
        Send("#!{Space}")
}

; ================= REDIMENSIONAR JANELAS ADJACENTES (WIN + / WIN -) =================
; Passo de 140px por clique (ajuste este valor se quiser saltos maiores ou menores)
#=::AdjustWindowSplit(140)          ; Win + =
#+=::AdjustWindowSplit(140)         ; Win + Shift + = (Win + + físico)
#NumpadAdd::AdjustWindowSplit(140)  ; Win + Numpad +

#-::AdjustWindowSplit(-140)         ; Win + -
#NumpadSub::AdjustWindowSplit(-140) ; Win + Numpad -

AdjustWindowSplit(delta) {
    ; Remove qualquer atraso artificial do AutoHotkey ao mover janelas (0 ms de delay)
    SetWinDelay(-1)

    hwndA := WinExist("A")
    if (!hwndA)
        return

    ; Posição e centro da janela ativa
    WinGetPos(&ax, &ay, &aw, &ah, "ahk_id " hwndA)
    acx := ax + (aw / 2)
    acy := ay + (ah / 2)

    ; Identifica o monitor atual
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

    bestHwnd := 0
    minDist := 99999999
    bx := 0, by := 0, bw := 0, bh := 0

    ; Procura a janela vizinha mais próxima no mesmo monitor
    for hwnd in WinGetList() {
        if (hwnd == hwndA)
            continue

        title := WinGetTitle("ahk_id " hwnd)
        if (title == "" || title == "Program Manager" || title == "Settings")
            continue

        if (WinGetMinMax("ahk_id " hwnd) == -1) ; Ignora minimizadas
            continue

        exStyle := WinGetExStyle("ahk_id " hwnd)
        if (exStyle & 0x00000080) ; Ignora ToolWindows/overlays
            continue

        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        if (w < 150 || h < 150)
            continue

        cx := x + (w / 2)
        cy := y + (h / 2)

        ; Deve estar no mesmo monitor
        if (cx >= WL && cx <= WR && cy >= WT && cy <= WB) {
            dist := Sqrt((cx - acx)**2 + (cy - acy)**2)
            if (dist < minDist) {
                minDist := dist
                bestHwnd := hwnd
                bx := x, by := y, bw := w, bh := h
            }
        }
    }

    if (!bestHwnd)
        return

    dx := (bx + bw / 2) - acx
    dy := (by + bh / 2) - acy

    ; Limite mínimo de tamanho para evitar colapso da janela
    minW := 280
    minH := 200

    ; Restaura apenas se alguma estiver de fato maximizada
    if (WinGetMinMax("ahk_id " hwndA) == 1)
        WinRestore("ahk_id " hwndA)
    if (WinGetMinMax("ahk_id " bestHwnd) == 1)
        WinRestore("ahk_id " bestHwnd)

    ; --- CASO 1: LADO A LADO NA HORIZONTAL (ULTRAWIDE) ---
    if (Abs(dx) >= Abs(dy)) {
        if (dx > 0) {
            ; Vizinha está à DIREITA
            newAw := aw + delta
            newBx := bx + delta
            newBw := bw - delta

            if (newAw < minW || newBw < minW)
                return

            WinMove(ax, ay, newAw, ah, "ahk_id " hwndA)
            WinMove(newBx, by, newBw, bh, "ahk_id " bestHwnd)
        } else {
            ; Vizinha está à ESQUERDA
            newAx := ax - delta
            newAw := aw + delta
            newBw := bw - delta

            if (newAw < minW || newBw < minW)
                return

            WinMove(newAx, ay, newAw, ah, "ahk_id " hwndA)
            WinMove(bx, by, newBw, bh, "ahk_id " bestHwnd)
        }
    }
    ; --- CASO 2: EMPILHADAS NA VERTICAL (MONITOR VERTICAL) ---
    else {
        if (dy > 0) {
            ; Vizinha está ABAIXO
            newAh := ah + delta
            newBy := by + delta
            newBh := bh - delta

            if (newAh < minH || newBh < minH)
                return

            WinMove(ax, ay, aw, newAh, "ahk_id " hwndA)
            WinMove(bx, newBy, bw, newBh, "ahk_id " bestHwnd)
        } else {
            ; Vizinha está ACIMA
            newAy := ay - delta
            newAh := ah + delta
            newBh := bh - delta

            if (newAh < minH || newBh < minH)
                return

            WinMove(ax, newAy, aw, newAh, "ahk_id " hwndA)
            WinMove(bx, by, bw, newBh, "ahk_id " bestHwnd)
        }
    }
}

; Inclui navegação espacial
#Include "focus.ahk"

; ================= DESATIVAR GAME BAR (WIN + G) =================
#g::return