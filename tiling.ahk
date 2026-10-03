#Requires AutoHotkey v2.0
#SingleInstance Force

; Mapeamento fixo 3x2 padrão:
; Linha 1: Q | W | E
; Linha 2: A | S | D
global Zonas := Map(
    "q", {row: 1, col: 1},
    "w", {row: 1, col: 2},
    "e", {row: 1, col: 3},
    "a", {row: 2, col: 1},
    "s", {row: 2, col: 2},
    "d", {row: 2, col: 3}
)

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

    ; Mantém 3 colunas x 2 linhas
    nCols := 3
    nRows := 2

    ; Proporção adaptável do HUD de acordo com a orientação do monitor
    isVertical := (workH > workW)
    if (isVertical) {
        hudW := Round(Min(workW * 0.90, 420))
        hudH := Round(hudW * 0.70)
    } else {
        hudW := 600
        hudH := 340
    }

    hudPad := 16
    gap := 10

    hudX := WL + (workW - hudW) / 2
    hudY := WT + (workH - hudH) / 2

    cardW := (hudW - (2 * hudPad) - ((nCols - 1) * gap)) / nCols
    cardH := (hudH - (2 * hudPad) - ((nRows - 1) * gap)) / nRows

    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow")
    overlay.BackColor := "111827"
    overlay.SetFont("s20 bold cE5E7EB", "Segoe UI")

    caixas := Map()

    for tecla, coord in Zonas {
        bx := hudPad + ((coord.col - 1) * (cardW + gap))
        by := hudPad + ((coord.row - 1) * (cardH + gap))

        card := overlay.AddText(
            "x" Round(bx) " y" Round(by) 
            " w" Round(cardW) " h" Round(cardH) 
            " Center 0x200 Background1F2937", 
            StrUpper(tecla)
        )
        caixas[tecla] := card
    }

    overlay.Show("x" Round(hudX) " y" Round(hudY) " w" hudW " h" hudH " NoActivate")
    WinSetTransparent(235, overlay.Hwnd)

    ; Captura 1ª tecla
    ih1 := InputHook("L1 T2")
    ih1.Start()
    ih1.Wait()
    t1 := StrLower(ih1.Input)

    if (!Zonas.Has(t1)) {
        overlay.Destroy()
        return
    }

    try caixas[t1].Opt("Background2563EB")

    ; Captura 2ª tecla
    ih2 := InputHook("L1 T0.8")
    ih2.Start()
    ih2.Wait()
    t2 := StrLower(ih2.Input)

    if (!Zonas.Has(t2))
        t2 := t1

    overlay.Destroy()

    ; ================= CÁLCULO DAS DIVISÕES =================
    marginOuter := 16
    marginInner := 12

    colW := (workW - (2 * marginOuter) - ((nCols - 1) * marginInner)) / nCols
    rowH := (workH - (2 * marginOuter) - ((nRows - 1) * marginInner)) / nRows

    par := t1 . t2
    parInvertido := t2 . t1

    ; Regra especial: QS ou SQ ocupa a tela inteira (todas as 3 colunas e 2 linhas)
    if (par == "qs" || parInvertido == "qs") {
        minCol := 1
        maxCol := 3
        minRow := 1
        maxRow := 2
    } else {
        z1 := Zonas[t1]
        z2 := Zonas[t2]
        minCol := Min(z1.col, z2.col)
        maxCol := Max(z1.col, z2.col)
        minRow := Min(z1.row, z2.row)
        maxRow := Max(z1.row, z2.row)
    }

    spanCols := (maxCol - minCol) + 1
    spanRows := (maxRow - minRow) + 1

    finalX := WL + marginOuter + ((minCol - 1) * (colW + marginInner))
    finalY := WT + marginOuter + ((minRow - 1) * (rowH + marginInner))
    finalW := (spanCols * colW) + ((spanCols - 1) * marginInner)
    finalH := (spanRows * rowH) + ((spanRows - 1) * marginInner)

    WinRestore("ahk_id " hwndAlvo)
    WinMove(Round(finalX), Round(finalY), Round(finalW), Round(finalH), "ahk_id " hwndAlvo)
}