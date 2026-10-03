; ================= AGRUPAMENTO DE JANELAS (ESTILO HYPRLAND) =================
; Módulo responsável por agrupar janelas no mesmo espaço retangular
; IMPORTANTE: Bloqueia Win + G do Game Bar para usar apenas com agrupamento

; Bloqueia completamente o Game Bar do Windows
; Win + G agora ativa apenas o agrupamento de janelas
#g::AgruparComVizinha()

; Win + Alt + G: Remove a janela ativa do grupo
#!g::DesagruparJanela()

; Win + Shift + Left / Right: Alterna entre janelas do mesmo grupo
#+Left::CiclarGrupo(-1)  ; Janela anterior do grupo
#+Right::CiclarGrupo(1)  ; Próxima janela do grupo

global gruposJanelas := Map()      ; Map de grupos: ID_Grupo -> Array de HWNDs
global janelaParaGrupo := Map()    ; HWND -> ID_Grupo
global proximoGrupoId := 1
global hwndPendente := 0           ; Janela aguardando par para agrupar

; ---- Fluxo de dois passos ----
; 1º Win+G: Marca a janela ativa como pendente (aguardando par)
; 2º Win+G: Forma o grupo entre a janela pendente e a janela atual
AgruparComVizinha() {
    global gruposJanelas, janelaParaGrupo, proximoGrupoId, hwndPendente
    SetWinDelay(-1)

    hwndA := WinExist("A")
    if (!hwndA)
        return

    ; Ainda não há janela pendente — marca esta como pendente e aguarda
    if (hwndPendente == 0) {
        hwndPendente := hwndA
        ; Feedback visual: torna a borda da janela levemente transparente
        WinSetTransparent(220, "ahk_id " hwndA)
        return
    }

    ; Mesma janela pressionou Win+G duas vezes — cancela
    if (hwndPendente == hwndA) {
        WinSetTransparent("Off", "ahk_id " hwndA)
        hwndPendente := 0
        return
    }

    hwndB := hwndPendente
    hwndPendente := 0

    ; Restaura transparência
    WinSetTransparent("Off", "ahk_id " hwndB)

    ; Verifica se as janelas ainda existem
    if (!WinExist("ahk_id " hwndB))
        return

    ; Obtém posição da janela B (referência)
    WinGetPos(&bx, &by, &bw, &bh, "ahk_id " hwndB)

    ; Define o ID do grupo
    gId := 0
    if (janelaParaGrupo.Has(hwndB)) {
        gId := janelaParaGrupo[hwndB]
    } else if (janelaParaGrupo.Has(hwndA)) {
        gId := janelaParaGrupo[hwndA]
    } else {
        gId := proximoGrupoId++
        gruposJanelas[gId] := [hwndB]
        janelaParaGrupo[hwndB] := gId
    }

    ; Adiciona janela A ao grupo se ainda não estiver
    if (!janelaParaGrupo.Has(hwndA)) {
        gruposJanelas[gId].Push(hwndA)
        janelaParaGrupo[hwndA] := gId
    }

    ; Alinha a janela ativa sobre a janela de referência
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

; Remove a janela ativa do grupo
DesagruparJanela() {
    global gruposJanelas, janelaParaGrupo, hwndPendente
    hwndA := WinExist("A")
    if (!hwndA)
        return

    ; Cancela agrupamento pendente se houver
    if (hwndPendente != 0) {
        WinSetTransparent("Off", "ahk_id " hwndPendente)
        hwndPendente := 0
        return
    }

    if (!janelaParaGrupo.Has(hwndA))
        return

    gId := janelaParaGrupo[hwndA]
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
