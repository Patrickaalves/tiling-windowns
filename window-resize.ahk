; ================= REDIMENSIONAR JANELAS ADJACENTES (WIN + / WIN -) =================
; Módulo responsável por redimensionar janelas adjacentes lado a lado ou empilhadas

; Sincroniza todas as janelas do grupo da janela informada para as coordenadas dadas
; Atualiza ultimaPosGrupo para prevenir re-trigger no timer de detecção manual
SincronizarGrupo(hwnd, x, y, w, h) {
    global gruposJanelas, janelaParaGrupo
    if (!janelaParaGrupo.Has(hwnd))
        return
    gId := janelaParaGrupo[hwnd]
    for membro in gruposJanelas[gId] {
        if (membro != hwnd && WinExist("ahk_id " membro)) {
            WinRestore("ahk_id " membro)
            WinMove(x, y, w, h, "ahk_id " membro)
        }
    }
}

AdjustWindowSplit(delta) {
    ; Remove qualquer atraso artificial do AutoHotkey ao mover janelas (0 ms de delay)
    SetWinDelay(-1)
    global janelaParaGrupo

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
    ; Ignora janelas que estão no mesmo grupo que hwndA (são a mesma "célula")
    for hwnd in WinGetList() {
        if (hwnd == hwndA)
            continue

        ; Ignora membros do mesmo grupo — eles ocupam o mesmo espaço
        if (janelaParaGrupo.Has(hwndA) && janelaParaGrupo.Has(hwnd)
            && janelaParaGrupo[hwndA] == janelaParaGrupo[hwnd])
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
            SincronizarGrupo(hwndA, ax, ay, newAw, ah)

            WinMove(newBx, by, newBw, bh, "ahk_id " bestHwnd)
            SincronizarGrupo(bestHwnd, newBx, by, newBw, bh)
        } else {
            ; Vizinha está à ESQUERDA
            newAx := ax - delta
            newAw := aw + delta
            newBw := bw - delta

            if (newAw < minW || newBw < minW)
                return

            WinMove(newAx, ay, newAw, ah, "ahk_id " hwndA)
            SincronizarGrupo(hwndA, newAx, ay, newAw, ah)

            WinMove(bx, by, newBw, bh, "ahk_id " bestHwnd)
            SincronizarGrupo(bestHwnd, bx, by, newBw, bh)
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
            SincronizarGrupo(hwndA, ax, ay, aw, newAh)

            WinMove(bx, newBy, bw, newBh, "ahk_id " bestHwnd)
            SincronizarGrupo(bestHwnd, bx, newBy, bw, newBh)
        } else {
            ; Vizinha está ACIMA
            newAy := ay - delta
            newAh := ah + delta
            newBh := bh - delta

            if (newAh < minH || newBh < minH)
                return

            WinMove(ax, newAy, aw, newAh, "ahk_id " hwndA)
            SincronizarGrupo(hwndA, ax, newAy, aw, newAh)

            WinMove(bx, by, bw, newBh, "ahk_id " bestHwnd)
            SincronizarGrupo(bestHwnd, bx, by, bw, newBh)
        }
    }
}
