; ================= AGRUPAMENTO DE JANELAS (ESTILO HYPRLAND) =================
; Módulo responsável por agrupar janelas no mesmo espaço retangular

#g::AgruparComVizinha()
#!g::DesagruparJanela()

; Win + Shift + Left / Right: Alterna entre janelas do mesmo grupo
#+Left::CiclarGrupo(-1)
#+Right::CiclarGrupo(1)

global gruposJanelas   := Map()  ; gId -> Array de HWNDs
global janelaParaGrupo := Map()  ; hwnd -> gId
global proximoGrupoId  := 1
global hwndPendente    := 0      ; Janela aguardando 2º Win+G

; ---- Fluxo de dois passos ----
; 1º Win+G: janela fica levemente transparente (aguardando par)
; 2º Win+G: forma o grupo com a janela atualmente focada

AgruparComVizinha() {
    global gruposJanelas, janelaParaGrupo, proximoGrupoId, hwndPendente
    SetWinDelay(-1)

    hwndA := WinExist("A")
    if (!hwndA)
        return

    if (hwndPendente == 0) {
        hwndPendente := hwndA
        WinSetTransparent(220, "ahk_id " hwndA)
        return
    }

    if (hwndPendente == hwndA) {
        WinSetTransparent("Off", "ahk_id " hwndA)
        hwndPendente := 0
        return
    }

    hwndB := hwndPendente
    hwndPendente := 0
    WinSetTransparent("Off", "ahk_id " hwndB)

    if (!WinExist("ahk_id " hwndB))
        return

    WinGetPos(&bx, &by, &bw, &bh, "ahk_id " hwndB)

    gId := 0
    if (janelaParaGrupo.Has(hwndB))
        gId := janelaParaGrupo[hwndB]
    else if (janelaParaGrupo.Has(hwndA))
        gId := janelaParaGrupo[hwndA]
    else {
        gId := proximoGrupoId++
        gruposJanelas[gId] := [hwndB]
        janelaParaGrupo[hwndB] := gId
    }

    if (!janelaParaGrupo.Has(hwndA)) {
        gruposJanelas[gId].Push(hwndA)
        janelaParaGrupo[hwndA] := gId
    }

    WinRestore("ahk_id " hwndA)
    WinMove(bx, by, bw, bh, "ahk_id " hwndA)
    WinActivate("ahk_id " hwndA)
}

CiclarGrupo(direcao) {
    global gruposJanelas, janelaParaGrupo

    hwndA := WinExist("A")
    if (!hwndA || !janelaParaGrupo.Has(hwndA))
        return

    gId   := janelaParaGrupo[hwndA]
    grupo := gruposJanelas[gId]
    tam   := grupo.Length
    if (tam <= 1)
        return

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
    if (WinExist("ahk_id " proximaHwnd))
        WinActivate("ahk_id " proximaHwnd)
}

DesagruparJanela() {
    global gruposJanelas, janelaParaGrupo, hwndPendente

    hwndA := WinExist("A")
    if (!hwndA)
        return

    if (hwndPendente != 0) {
        WinSetTransparent("Off", "ahk_id " hwndPendente)
        hwndPendente := 0
        return
    }

    if (!janelaParaGrupo.Has(hwndA))
        return

    gId   := janelaParaGrupo[hwndA]
    grupo := gruposJanelas[gId]

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
