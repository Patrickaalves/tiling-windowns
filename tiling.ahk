#Requires AutoHotkey v2.0
#SingleInstance Force

; Atalho: Win + T
#t:: {
    hwndAlvo := WinExist("A")
    if (!hwndAlvo)
        return

    ; Identifica o monitor da janela ativa
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

    ; Espaçamentos
    marginOuter := 16
    marginInner := 12

    ; Detecta orientação do monitor
    isVertical := (workH > workW)

    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow")
    overlay.BackColor := "111827"
    overlay.SetFont("s22 bold cE5E7EB", "Segoe UI")
    caixas := Map()

    ; ================= MONTAGEM DO HUD POR MONITOR =================
    if (isVertical) {
        ; Layout Vertical: apenas 2 blocos (Cima e Baixo)
        hudW := Round(Min(workW * 0.85, 320))
        hudH := 360
        hudPad := 16
        gap := 12

        hudX := WL + (workW - hudW) / 2
        hudY := WT + (workH - hudH) / 2

        cardW := hudW - (2 * hudPad)
        cardH := (hudH - (2 * hudPad) - gap) / 2

        ; Desenha Q (Cima) e S (Baixo)
        caixas["q"] := overlay.AddText("x" hudPad " y" hudPad " w" cardW " h" Round(cardH) " Center 0x200 Background1F2937", "Q")
        caixas["s"] := overlay.AddText("x" hudPad " y" Round(hudPad + cardH + gap) " w" cardW " h" Round(cardH) " Center 0x200 Background1F2937", "S")

        ; Mapeamento de teclas válidas no monitor vertical (com W e A como sinônimos)
        zonasPermitidas := Map(
            "q", {row: 1, uiKey: "q"},
            "w", {row: 1, uiKey: "q"},
            "s", {row: 2, uiKey: "s"},
            "a", {row: 2, uiKey: "s"}
        )
    } else {
        ; Layout Horizontal / Ultrawide: grade 3x2 completa
        hudW := 600
        hudH := 340
        hudPad := 16
        gap := 10

        hudX := WL + (workW - hudW) / 2
        hudY := WT + (workH - hudH) / 2

        cardW := (hudW - (2 * hudPad) - (2 * gap)) / 3
        cardH := (hudH - (2 * hudPad) - (1 * gap)) / 2

        zonasPermitidas := Map(
            "q", {row: 1, col: 1, uiKey: "q"}, "w", {row: 1, col: 2, uiKey: "w"}, "e", {row: 1, col: 3, uiKey: "e"},
            "a", {row: 2, col: 1, uiKey: "a"}, "s", {row: 2, col: 2, uiKey: "s"}, "d", {row: 2, col: 3, uiKey: "d"}
        )

        for tecla, coord in zonasPermitidas {
            bx := hudPad + ((coord.col - 1) * (cardW + gap))
            by := hudPad + ((coord.row - 1) * (cardH + gap))
            caixas[tecla] := overlay.AddText("x" Round(bx) " y" Round(by) " w" Round(cardW) " h" Round(cardH) " Center 0x200 Background1F2937", StrUpper(tecla))
        }
    }

    overlay.Show("x" Round(hudX) " y" Round(hudY) " w" hudW " h" hudH " NoActivate")
    WinSetTransparent(235, overlay.Hwnd)

    ; Captura 1ª tecla
    ih1 := InputHook("L1 T2")
    ih1.Start()
    ih1.Wait()
    t1 := StrLower(ih1.Input)

    if (!zonasPermitidas.Has(t1)) {
        overlay.Destroy()
        return
    }

    ; Destaca a caixa correspondente no HUD
    try caixas[zonasPermitidas[t1].uiKey].Opt("Background2563EB")

    ; Captura 2ª tecla opcional
    ih2 := InputHook("L1 T0.8")
    ih2.Start()
    ih2.Wait()
    t2 := StrLower(ih2.Input)

    if (!zonasPermitidas.Has(t2))
        t2 := t1

    overlay.Destroy()

    ; ================= POSICIONAMENTO DA JANELA =================
    if (isVertical) {
        ; --- REGRAS DO MONITOR VERTICAL (2 ZONAS) ---
        halfH := (workH - (2 * marginOuter) - marginInner) / 2
        fullW := workW - (2 * marginOuter)

        r1 := zonasPermitidas[t1].row
        r2 := zonasPermitidas[t2].row

        ; Se digitou uma de cima e uma de baixo (ex: Q + S), TELA CHEIA
        if (r1 != r2) {
            finalX := WL + marginOuter
            finalY := WT + marginOuter
            finalW := fullW
            finalH := workH - (2 * marginOuter)
        } else if (r1 == 1) {
            ; Metade de Cima (Q)
            finalX := WL + marginOuter
            finalY := WT + marginOuter
            finalW := fullW
            finalH := Round(halfH)
        } else {
            ; Metade de Baixo (S)
            finalX := WL + marginOuter
            finalY := WT + marginOuter + Round(halfH) + marginInner
            finalW := fullW
            finalH := Round(halfH)
        }
    } else {
        ; --- REGRAS DO MONITOR ULTRAWIDE / HORIZONTAL (3x2) ---
        colW := (workW - (2 * marginOuter) - (2 * marginInner)) / 3
        rowH := (workH - (2 * marginOuter) - (1 * marginInner)) / 2

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
    }

    WinRestore("ahk_id " hwndAlvo)
    WinMove(Round(finalX), Round(finalY), Round(finalW), Round(finalH), "ahk_id " hwndAlvo)
}

; No final do arquivo tiling.ahk:
#Include "focus.ahk"

; ================= LANÇADOR RÁPIDO (WIN + ESPAÇO) =================
; Intercepta Win + Espaço, suprime a troca de idioma do Windows 
; e aciona instantaneamente o atalho do lançador (Alt + Espaço)
#Space::Send("!{Space}")

; ================= ABRIR TERMINAL (WIN + ENTER) =================
#Enter::Run("wt")

; ================= ABRIR TERMINAL (WIN + ALT + ENTER) =================
#!Enter::Run("*RunAs wt")

; ================= TROCAR POSIÇÃO DE DUAS JANELAS (WIN + ALT + SETAS LATERAIS) =================
#!Left::SwapWindows()
#!Right::SwapWindows()

SwapWindows() {
    hwndA := WinExist("A")
    if (!hwndA)
        return

    ; Posição e dimensões da janela ativa
    WinGetPos(&ax, &ay, &aw, &ah, "ahk_id " hwndA)
    acx := ax + (aw / 2)
    acy := ay + (ah / 2)

    ; Identifica o monitor onde a janela ativa está localizada
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

    ; Procura a outra janela visível e aberta no mesmo monitor
    for hwnd in WinGetList() {
        if (hwnd == hwndA)
            continue

        title := WinGetTitle("ahk_id " hwnd)
        if (title == "" || title == "Program Manager" || title == "Settings")
            continue

        if (WinGetMinMax("ahk_id " hwnd) == -1) ; Ignora janelas minimizadas
            continue

        exStyle := WinGetExStyle("ahk_id " hwnd)
        if (exStyle & 0x00000080) ; Ignora ToolWindows/overlays
            continue

        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        if (w < 200 || h < 200) ; Ignora notificações e popups pequenos
            continue

        ; Centro da janela candidata
        cx := x + (w / 2)
        cy := y + (h / 2)

        ; Valida se está na área útil deste monitor
        if (cx >= WL && cx <= WR && cy >= WT && cy <= WB) {
            hwndB := hwnd
            bx := x, by := y, bw := w, bh := h
            break
        }
    }

    ; Inverte as coordenadas e dimensões entre as duas janelas
    if (hwndB) {
        WinRestore("ahk_id " hwndA)
        WinRestore("ahk_id " hwndB)

        WinMove(bx, by, bw, bh, "ahk_id " hwndA)
        WinMove(ax, ay, aw, ah, "ahk_id " hwndB)

        ; Mantém o foco no aplicativo ativo
        WinActivate("ahk_id " hwndA)
    }
}