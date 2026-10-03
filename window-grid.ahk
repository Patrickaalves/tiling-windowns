; ================= GERENCIAMENTO DE JANELAS EM GRADE (WIN + T) =================
; Módulo responsável pela lógica de posicionamento em grade 3x2 ou 2x2

GridWindowTiling() {
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

    marginOuter := 6
    marginInner := 6
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
    gap := 12

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

    ; Sincroniza o grupo: todas as janelas agrupadas recebem as mesmas coordenadas
    SincronizarGrupo(hwndAlvo, Round(finalX), Round(finalY), Round(finalW), Round(finalH))

    ; Se a janela foi posicionada no monitor vertical, fixa-a em todas as telas
    global vdExe
    if (isVertical && FileExist(vdExe)) {
        try Run(vdExe ' /pwh:' hwndAlvo,, "Hide")
    }
}
