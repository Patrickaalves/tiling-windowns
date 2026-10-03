; ================= CONFIGURAÇÃO DO TILING WINDOWS =================
; Arquivo de configuração para personalizar comportamento do sistema

; ================= AGRUPAMENTO DE JANELAS (WINDOW GROUPING) =================

; Define o modo de filtro para agrupamento:
; "whitelist" = apenas aplicações na lista podem ser agrupadas (RECOMENDADO)
; "blacklist" = aplicações na lista NÃO podem ser agrupadas
; "permissivo" = qualquer janela pode ser agrupada
global groupingMode := "whitelist"

; Whitelist de aplicações que PODEM ser agrupadas
; Use o título da janela (ex: "Visual Studio Code", "PyCharm", etc)
; Se você quer agrupar VSCode com IntelliJ, PyCharm, etc, adicione-os aqui
; EXEMPLO: Você tem VSCode e PyCharm abertos lado a lado
;          Pressione Win + G no VSCode -> ele se alinha com PyCharm
;          porque ambos estão na whitelist
global groupingApps := [
    "Visual Studio Code",
    "PyCharm",
    "IntelliJ IDEA",
    "IntelliJ",
    "Sublime Text",
    "Cursor",
    "Terminal",
    "Windows Terminal",
    "PowerShell",
    "cmd.exe",
    "Vim",
    "Neovim"
]

; ================= MARGENS E ESPAÇAMENTO =================

; Distância das bordas da tela (pixels)
global marginOuter := 10

; Distância (gap) entre as janelas (pixels)
global marginInner := 12

; Passo de redimensionamento ao usar Win + =/-  (pixels)
global resizeStep := 200

; ================= CORES DO HUD =================

; Cor de fundo do HUD modal
global hudBackColor := "111827"

; Cor das zonas (células) no grid
global hudZoneColor := "1F2937"

; Cor do destaque ao selecionar uma zona
global hudHighlightColor := "2563EB"

; ================= FUNÇÃO DE VERIFICAÇÃO =================

; Verifica se uma aplicação pode ser agrupada baseado na configuração
VerificaAgrupavelApp(titulo, classe, modo, listaApps) {
    if (modo == "permissivo")
        return true

    if (modo == "whitelist") {
        ; Procura se o título ou classe estão na whitelist
        for app in listaApps {
            if (InStr(titulo, app) || InStr(classe, app))
                return true
        }
        return false
    }

    if (modo == "blacklist") {
        ; Procura se o título ou classe estão na blacklist
        for app in listaApps {
            if (InStr(titulo, app) || InStr(classe, app))
                return false
        }
        return true
    }

    return true
}
