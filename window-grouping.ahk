; ================= AGRUPAMENTO DE JANELAS (ESTILO OMARCHY/HYPRLAND) =================
; Visual: borda colorida ao redor do grupo + barra de abas no topo com títulos

#g::AgruparComVizinha()
#!g::DesagruparJanela()
#+Left::CiclarGrupo(-1)
#+Right::CiclarGrupo(1)

; ================= ESTADO =================

global gruposJanelas    := Map()  ; gId -> Array de HWNDs
global janelaParaGrupo  := Map()  ; hwnd -> gId
global proximoGrupoId   := 1
global hwndPendente     := 0
global grupoVisuais     := Map()  ; gId -> { tabGui, borders[] }
global ultimaPosGrupo   := Map()  ; hwnd -> {x,y,w,h} para detectar movimento manual
global ultimaAtivaGrupo := 0      ; rastreia mudança de janela ativa para atualizar aba

; Paleta de cores por grupo
global grupoCores := ["C53030", "276749", "2B6CB0", "C05621", "6B46C1", "086F83"]

SetTimer(AtualizarVisuaisGrupos, 150)
SetTimer(DetectarMovimentoGrupo, 250)

; ================= AGRUPAMENTO EM DOIS PASSOS =================

AgruparComVizinha() {
    global gruposJanelas, janelaParaGrupo, proximoGrupoId, hwndPendente
    SetWinDelay(-1)

    hwndA := WinExist("A")
    if (!hwndA)
        return

    ; Passo 1: marca janela como pendente com feedback visual
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

    ; Empilha janela ativa sobre a de referência
    WinRestore("ahk_id " hwndA)
    WinMove(bx, by, bw, bh, "ahk_id " hwndA)
    WinActivate("ahk_id " hwndA)

    ; Cria visual do grupo
    CriarVisualGrupo(gId)
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

    if (novoArray.Length > 1) {
        gruposJanelas[gId] := novoArray
        CriarVisualGrupo(gId)  ; recria sem a janela removida
    } else if (novoArray.Length == 1) {
        gruposJanelas[gId] := novoArray
        janelaParaGrupo.Delete(novoArray[1])
        RemoverVisualGrupo(gId)
        gruposJanelas.Delete(gId)
    } else {
        RemoverVisualGrupo(gId)
        gruposJanelas.Delete(gId)
    }
}

; ================= VISUAL: BORDA + BARRA DE ABAS =================

; Helper para capturar hwnd por valor no closure de clique de aba
MakeTabHandler(targetHwnd) {
    return (*) => WinActivate("ahk_id " targetHwnd)
}

CriarVisualGrupo(gId) {
    global grupoVisuais, gruposJanelas, grupoCores, vdExe

    RemoverVisualGrupo(gId)

    grupo := gruposJanelas[gId]
    if (grupo.Length == 0)
        return

    ; Referência de posição: primeiro membro visível
    refHwnd := 0
    for hwnd in grupo {
        if (WinExist("ahk_id " hwnd) && WinGetMinMax("ahk_id " hwnd) != -1) {
            refHwnd := hwnd
            break
        }
    }
    if (!refHwnd)
        return

    WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " refHwnd)

    cor      := grupoCores[Mod(gId - 1, grupoCores.Length) + 1]
    tabH     := 20   ; altura da barra de abas
    bordW    := 2    ; espessura da borda
    activeHwnd := WinExist("A")

    ; ---- BARRA DE ABAS ----
    tabGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    tabGui.BackColor := "0D0D1A"
    tabGui.SetFont("s7 cCCCCCC", "Segoe UI")

    tabCount := grupo.Length
    eachW    := Floor(ww / tabCount)

    for i, memberHwnd in grupo {
        title := ""
        try title := WinGetTitle("ahk_id " memberHwnd)
        if (StrLen(title) > 25)
            title := SubStr(title, 1, 23) "…"

        isActive := (memberHwnd == activeHwnd)
        tx       := (i - 1) * eachW
        tw       := (i == tabCount) ? (ww - tx) : eachW
        bgColor  := isActive ? cor : "1A1A2E"

        ctrl := tabGui.AddText(
            "x" tx " y0 w" tw " h" tabH " Center 0x200 Background" bgColor,
            title
        )
        ctrl.OnEvent("Click", MakeTabHandler(memberHwnd))

        ; Separador entre abas
        if (i < tabCount)
            tabGui.AddText("x" (tx + tw - 1) " y2 w1 h" (tabH - 4) " Background303050", "")
    }

    tabGui.Show("x" wx " y" wy " w" ww " h" tabH " NoActivate")
    WinSetTransparent(220, tabGui.Hwnd)
    if (FileExist(vdExe))
        try Run(vdExe ' /pwh:' tabGui.Hwnd,, "Hide")

    ; ---- BORDAS (click-through) ----
    borders := []
    positions := [
        {bx: wx,              by: wy,               bw: ww,    bh: bordW},          ; topo
        {bx: wx,              by: wy + wh - bordW,  bw: ww,    bh: bordW},          ; baixo
        {bx: wx,              by: wy,               bw: bordW, bh: wh},             ; esquerda
        {bx: wx + ww - bordW, by: wy,               bw: bordW, bh: wh}              ; direita
    ]

    for pos in positions {
        b := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
        b.BackColor := cor
        b.Show("x" pos.bx " y" pos.by " w" pos.bw " h" pos.bh " NoActivate")
        WinSetTransparent(180, b.Hwnd)
        if (FileExist(vdExe))
            try Run(vdExe ' /pwh:' b.Hwnd,, "Hide")
        borders.Push(b)
    }

    grupoVisuais[gId] := { tabGui: tabGui, borders: borders }
}

RemoverVisualGrupo(gId) {
    global grupoVisuais
    if (!grupoVisuais.Has(gId))
        return
    v := grupoVisuais[gId]
    try v.tabGui.Destroy()
    for b in v.borders
        try b.Destroy()
    grupoVisuais.Delete(gId)
}

; ================= TIMER: REPOSICIONAR VISUAIS =================

AtualizarVisuaisGrupos() {
    global grupoVisuais, gruposJanelas, janelaParaGrupo, ultimaAtivaGrupo

    ; Recria visual se a janela ativa mudou dentro de um grupo (atualiza aba destacada)
    activeHwnd := WinExist("A")
    if (activeHwnd != ultimaAtivaGrupo) {
        ultimaAtivaGrupo := activeHwnd
        if (janelaParaGrupo.Has(activeHwnd))
            CriarVisualGrupo(janelaParaGrupo[activeHwnd])
    }

    tabH  := 20
    bordW := 2

    for gId, v in grupoVisuais.Clone() {
        if (!gruposJanelas.Has(gId)) {
            RemoverVisualGrupo(gId)
            continue
        }

        grupo := gruposJanelas[gId]

        ; Encontra membro visível para referência
        refHwnd := 0
        allMin  := true
        for hwnd in grupo {
            if (!WinExist("ahk_id " hwnd))
                continue
            if (WinGetMinMax("ahk_id " hwnd) != -1) {
                refHwnd := hwnd
                allMin  := false
                break
            }
        }

        if (allMin || !refHwnd) {
            try v.tabGui.Hide()
            for b in v.borders
                try b.Hide()
            continue
        }

        WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " refHwnd)

        ; Reposiciona aba
        try WinMove(wx, wy, ww, tabH, "ahk_id " v.tabGui.Hwnd)

        ; Reposiciona bordas
        positions := [
            {bx: wx,              by: wy,               bw: ww,    bh: bordW},
            {bx: wx,              by: wy + wh - bordW,  bw: ww,    bh: bordW},
            {bx: wx,              by: wy,               bw: bordW, bh: wh},
            {bx: wx + ww - bordW, by: wy,               bw: bordW, bh: wh}
        ]
        for i, pos in positions
            try WinMove(pos.bx, pos.by, pos.bw, pos.bh, "ahk_id " v.borders[i].Hwnd)
    }
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
                ; Atualiza todos antes de mover para evitar ping-pong com SincronizarGrupo
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
