; ================= AGRUPAMENTO DE JANELAS (ESTILO HYPRLAND) =================
; Módulo responsável por agrupar janelas no mesmo espaço retangular

#g::AgruparComVizinha()
#!g::DesagruparJanela()
#+Left::CiclarGrupo(-1)
#+Right::CiclarGrupo(1)

; ================= ESTADO =================

global gruposJanelas   := Map()  ; gId -> Array de HWNDs
global janelaParaGrupo := Map()  ; hwnd -> gId
global proximoGrupoId  := 1
global hwndPendente    := 0
global ultimaPosGrupo  := Map()  ; hwnd -> {x,y,w,h} para detectar movimento manual

SetTimer(DetectarMovimentoGrupo, 250)

; ================= AGRUPAMENTO EM DOIS PASSOS =================
; 1º Win+G: janela fica levemente transparente (aguardando par)
; 2º Win+G: forma o grupo

AgruparComVizinha() {
    global gruposJanelas, janelaParaGrupo, proximoGrupoId, hwndPendente
    SetWinDelay(-1)

    hwndA := WinExist("A")
    if (!hwndA)
        return

    ; Passo 1: marca como pendente
    if (hwndPendente == 0) {
        hwndPendente := hwndA
        WinSetTransparent(200, "ahk_id " hwndA)
        return
    }

    ; Cancela se Win+G na mesma janela
    if (hwndPendente == hwndA) {
        WinSetTransparent("Off", "ahk_id " hwndA)
        hwndPendente := 0
        return
    }

    ; Passo 2: forma o grupo
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

; ================= CICLO E DESAGRUPAMENTO =================

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
    if (novoIdx > tam)  novoIdx := 1
    if (novoIdx < 1)    novoIdx := tam

    proximaHwnd := grupo[novoIdx]
    if (WinExist("ahk_id " proximaHwnd))
        WinActivate("ahk_id " proximaHwnd)
}

DesagruparJanela() {
    global gruposJanelas, janelaParaGrupo, hwndPendente
    hwndA := WinExist("A")
    if (!hwndA)
        return

    ; Cancela agrupamento pendente
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

    janelaParaGrupo.Delete(hwndA)

    if (novoArray.Length > 0)
        gruposJanelas[gId] := novoArray
    else
        gruposJanelas.Delete(gId)
}

; ================= TIMER: DETECTAR MOVIMENTO MANUAL =================

DetectarMovimentoGrupo() {
    global gruposJanelas, janelaParaGrupo, ultimaPosGrupo

    for gId, grupo in gruposJanelas {
        if (grupo.Length <= 1)
            continue

        for hwnd in grupo {
            if (!WinExist("ahk_id " hwnd))
                continue
            if (WinGetMinMax("ahk_id " hwnd) == -1)
                continue

            WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)

            if (!ultimaPosGrupo.Has(hwnd)) {
                ultimaPosGrupo[hwnd] := {x: x, y: y, w: w, h: h}
                continue
            }

            pos := ultimaPosGrupo[hwnd]

            if (x != pos.x || y != pos.y || w != pos.w || h != pos.h) {
                ; Atualiza todos antes de mover para evitar ping-pong
                for membro in grupo
                    ultimaPosGrupo[membro] := {x: x, y: y, w: w, h: h}

                for membro in grupo {
                    if (membro != hwnd && WinExist("ahk_id " membro)) {
                        try {
                            WinRestore("ahk_id " membro)
                            WinMove(x, y, w, h, "ahk_id " membro)
                        }
                    }
                }
                break
            }
        }
    }
}
