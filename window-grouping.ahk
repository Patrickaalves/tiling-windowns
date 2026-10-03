; ================= AGRUPAMENTO DE JANELAS (ESTILO HYPRLAND) =================
; Módulo responsável por agrupar janelas no mesmo espaço retangular
; IMPORTANTE: Bloqueia Win + G do Game Bar para usar apenas com agrupamento

; Bloqueia completamente o Game Bar do Windows
#g::AgruparComVizinha()

; Win + Alt + G: Cancela pendência ou remove janela do grupo
#!g::DesagruparJanela()

; Win + Shift + Left / Right: Alterna entre janelas do mesmo grupo
#+Left::CiclarGrupo(-1)
#+Right::CiclarGrupo(1)

; ================= ESTADO =================

global gruposJanelas   := Map()   ; gId -> Array de HWNDs
global janelaParaGrupo := Map()   ; hwnd -> gId
global proximoGrupoId  := 1
global hwndPendente    := 0       ; Janela aguardando 2º Win+G
global grupoOverlays   := Map()   ; hwnd -> { gui: Gui, gId: int }

; Paleta de cores por grupo (azul, verde, vermelho, laranja, roxo, ciano)
global grupoCores := ["2563EB", "16A34A", "DC2626", "D97706", "7C3AED", "0891B2"]

; Timer que mantém os badges posicionados sobre as janelas
SetTimer(AtualizarOverlays, 150)

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

    ; Cancela se pressionou Win+G na mesma janela
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

    ; Define ou reutiliza ID do grupo
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

    ; Cria badges visuais para todas as janelas do grupo
    for h in gruposJanelas[gId]
        CriarOverlayGrupo(h, gId)

    ; Empilha janela ativa sobre a de referência
    WinRestore("ahk_id " hwndA)
    WinMove(bx, by, bw, bh, "ahk_id " hwndA)
    WinActivate("ahk_id " hwndA)
}

; ================= BADGE VISUAL =================

CriarOverlayGrupo(hwnd, gId) {
    global grupoOverlays, grupoCores

    ; Remove badge anterior se existir
    RemoverOverlayGrupo(hwnd)

    cor := grupoCores[Mod(gId - 1, grupoCores.Length) + 1]

    WinGetPos(&x, &y,, , "ahk_id " hwnd)

    ov := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")  ; E0x20 = click-through
    ov.BackColor := cor
    ov.SetFont("s8 bold cFFFFFF", "Segoe UI")
    ov.AddText("x0 y0 w28 h28 Center 0x200", "G" gId)
    ov.Show("x" (x + 8) " y" (y + 38) " w28 h28 NoActivate")
    WinSetTransparent(230, ov.Hwnd)

    grupoOverlays[hwnd] := { gui: ov, gId: gId, visible: true }
}

RemoverOverlayGrupo(hwnd) {
    global grupoOverlays
    if (grupoOverlays.Has(hwnd)) {
        try grupoOverlays[hwnd].gui.Destroy()
        grupoOverlays.Delete(hwnd)
    }
}

; Timer: reposiciona badges e remove os de janelas já fechadas
AtualizarOverlays() {
    global grupoOverlays

    for hwnd, info in grupoOverlays.Clone() {
        ; Janela foi fechada — remove badge
        if (!WinExist("ahk_id " hwnd)) {
            try info.gui.Destroy()
            grupoOverlays.Delete(hwnd)
            continue
        }

        ; Janela minimizada — esconde badge
        if (WinGetMinMax("ahk_id " hwnd) == -1) {
            info.gui.Hide()
            info.visible := false
            continue
        }

        WinGetPos(&x, &y,, , "ahk_id " hwnd)
        newX := x + 8
        newY := y + 38

        ; Badge foi destruído pelo sistema — recria
        if (!WinExist("ahk_id " info.gui.Hwnd)) {
            CriarOverlayGrupo(hwnd, info.gId)
            continue
        }

        ; Estava oculto (minimizado antes) — mostra novamente
        if (!info.visible) {
            info.gui.Show("x" newX " y" newY " NoActivate")
            info.visible := true
            continue
        }

        ; Apenas move sem chamar Show() — evita flicker e destruição pelo Windows
        WinMove(newX, newY,,,, "ahk_id " info.gui.Hwnd)
    }
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

    ; Remove badge da janela que está saindo
    RemoverOverlayGrupo(hwndA)

    novoArray := []
    for h in grupo {
        if (h != hwndA)
            novoArray.Push(h)
    }

    if (novoArray.Length > 0)
        gruposJanelas[gId] := novoArray
    else {
        ; Último membro saindo — remove grupo e badges restantes
        for h in grupo
            RemoverOverlayGrupo(h)
        gruposJanelas.Delete(gId)
    }

    janelaParaGrupo.Delete(hwndA)
}
