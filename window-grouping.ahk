; ================= AGRUPAMENTO DE JANELAS (ESTILO HYPRLAND) =================
; Módulo responsável por agrupar janelas no mesmo espaço retangular

global gruposJanelas := Map()      ; Map de grupos: ID_Grupo -> Array de HWNDs
global janelaParaGrupo := Map()    ; HWND -> ID_Grupo
global proximoGrupoId := 1

; Cria ou adiciona a janela ativa a um grupo com a vizinha
AgruparComVizinha() {
    global gruposJanelas, janelaParaGrupo, proximoGrupoId
    SetWinDelay(-1)

    hwndA := WinExist("A")
    if (!hwndA)
        return

    ; Identifica a janela vizinha mais próxima no mesmo monitor
    WinGetPos(&ax, &ay, &aw, &ah, "ahk_id " hwndA)
    acx := ax + (aw / 2), acy := ay + (ah / 2)

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

    bestHwnd := 0, minDist := 99999999
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
        if (w < 150 || h < 150)
            continue

        cx := x + (w / 2), cy := y + (h / 2)
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

    ; Define o ID do grupo
    gId := 0
    if (janelaParaGrupo.Has(bestHwnd)) {
        gId := janelaParaGrupo[bestHwnd]
    } else if (janelaParaGrupo.Has(hwndA)) {
        gId := janelaParaGrupo[hwndA]
    } else {
        gId := proximoGrupoId++
        gruposJanelas[gId] := [bestHwnd]
        janelaParaGrupo[bestHwnd] := gId
    }

    ; Adiciona a janela atual ao grupo se ainda não estiver nele
    if (!janelaParaGrupo.Has(hwndA)) {
        gruposJanelas[gId].Push(hwndA)
        janelaParaGrupo[hwndA] := gId
    }

    ; Alinha a geometria: molda a janela ativa no retângulo exato da vizinha
    WinRestore("ahk_id " hwndA)
    WinMove(bx, by, bw, bh, "ahk_id " hwndA)
    WinActivate("ahk_id " hwndA)
}

; Alterna entre janelas do mesmo grupo (direção: 1 = próxima, -1 = anterior)
CiclarGrupo(direcao) {
    global gruposJanelas, janelaParaGrupo
    hwndA := WinExist("A")
    if (!hwndA || !janelaParaGrupo.Has(hwndA))
        return

    gId := janelaParaGrupo[hwndA]
    grupo := gruposJanelas[gId]
    tam := grupo.Length
    if (tam <= 1)
        return

    ; Localiza índice atual
    idxAtual := 1
    for i, h in grupo {
        if (h == hwndA) {
            idxAtual := i
            break
        }
    }

    novoIdx := idxAtual + direcao
    if (novoIdx > tam)
        novoIdx := 1
    if (novoIdx < 1)
        novoIdx := tam

    proximaHwnd := grupo[novoIdx]
    if (WinExist("ahk_id " proximaHwnd)) {
        WinActivate("ahk_id " proximaHwnd)
    }
}

; Remove a janela ativa do grupo
DesagruparJanela() {
    global gruposJanelas, janelaParaGrupo
    hwndA := WinExist("A")
    if (!hwndA || !janelaParaGrupo.Has(hwndA))
        return

    gId := janelaParaGrupo[hwndA]
    grupo := gruposJanelas[gId]

    ; Remove do array do grupo
    novoArray := []
    for h in grupo {
        if (h != hwndA)
            novoArray.Push(h)
    }

    if (novoArray.Length > 0)
        gruposJanelas[gId] := novoArray
    else
        gruposJanelas.Delete(gId)

    janelaParaGrupo.Delete(hwndA)
}
