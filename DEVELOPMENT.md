# Guia de Desenvolvimento - Tiling Windows

Este documento descreve como estender e melhorar o projeto Tiling Windows com novas funcionalidades.

---

## 📋 Índice

1. [Arquitetura do Projeto](#arquitetura-do-projeto)
2. [Estrutura de Módulos](#estrutura-de-módulos)
3. [Como Adicionar uma Nova Funcionalidade](#como-adicionar-uma-nova-funcionalidade)
4. [Padrões de Código](#padrões-de-código)
5. [Testando Suas Alterações](#testando-suas-alterações)
6. [Convenções de Nomenclatura](#convenções-de-nomenclatura)
7. [Debugging e Troubleshooting](#debugging-e-troubleshooting)

---

## 🏗️ Arquitetura do Projeto

O projeto segue uma arquitetura modular onde cada arquivo `.ahk` é responsável por um aspecto específico da funcionalidade:

```
tiling.ahk (entry point)
    ├── includes
    ├── utils.ahk (utilities)
    ├── focus.ahk (navigation)
    ├── window-grid.ahk (grid positioning)
    ├── virtual-desktop.ahk (desktop management)
    ├── window-swap.ahk (window swapping)
    ├── window-resize.ahk (window resizing)
    └── hotkeys.ahk (system hotkeys)
```

### Fluxo de Carregamento

1. `tiling.ahk` executa verificações de admin
2. Define variáveis globais (`vdExe`)
3. Inclui todos os módulos via `#Include`
4. Define atalhos principais

---

## 📦 Estrutura de Módulos

### Convenção de Responsabilidades

Cada módulo deve ser **coeso** e realizar uma única função bem definida:

| Módulo | Responsabilidade |
|--------|-----------------|
| **tiling.ahk** | Orquestração e ponto de entrada |
| **utils.ahk** | Funções reutilizáveis (validação, detecção) |
| **focus.ahk** | Navegação de foco entre janelas |
| **window-grid.ahk** | Posicionamento em grade com HUD |
| **virtual-desktop.ahk** | Gerenciamento de desktops virtuais |
| **window-swap.ahk** | Troca de posição entre janelas |
| **window-resize.ahk** | Redimensionamento dinâmico |
| **window-grouping.ahk** | Agrupamento de janelas (estilo Hyprland) |
| **hotkeys.ahk** | Atalhos gerais não categorizados |

### Globais Disponíveis

- `vdExe` — Caminho para `VirtualDesktop11.exe`
- `A_ScriptDir` — Diretório onde os scripts estão localizados
- `A_IsAdmin` — Verifica se está rodando como administrador

---

## 🆕 Como Adicionar uma Nova Funcionalidade

### Passo 1: Decidir Onde Colocar o Código

**Pergunta:** Esta funcionalidade se encaixa em um módulo existente?

- ✅ **SIM** → Adicione à função existente no módulo apropriado
- ❌ **NÃO** → Crie um novo módulo

### Passo 2: Criar um Novo Módulo (se necessário)

Crie um arquivo `nomefuncionalidade.ahk` seguindo este template:

```autohotkey
; ================= DESCRIÇÃO DA FUNCIONALIDADE =================
; Módulo responsável por [descrever o que faz]

; Função principal
MeunovaFuncao() {
    ; implementação
}

; Função auxiliar (se necessário)
MinhaFuncaoAuxiliar() {
    ; implementação
}
```

### Passo 3: Incluir o Módulo em `tiling.ahk`

Abra `tiling.ahk` e adicione a inclusão:

```autohotkey
; ================= INCLUSÃO DE MÓDULOS =================
#Include "utils.ahk"
#Include "focus.ahk"
#Include "window-grid.ahk"
#Include "virtual-desktop.ahk"
#Include "window-swap.ahk"
#Include "window-resize.ahk"
#Include "hotkeys.ahk"
#Include "nomefuncionalidade.ahk"  ; ← Adicione aqui
```

### Passo 4: Definir Atalho em `tiling.ahk`

Adicione a ligação do atalho na seção de atalhos principais:

```autohotkey
; ================= ATALHOS PRINCIPAIS =================
#t::GridWindowTiling()
#p::PinCurrentWindow()
; ... outros atalhos ...

; Seu novo atalho
#NovaCombo::MinhaNovaFuncao()  ; ← Adicione aqui
```

### Passo 5: Testar e Documentar

1. Recarregue o script (`Win + Alt + R`)
2. Teste a funcionalidade
3. Atualize o `README.md` com o novo atalho
4. Atualize este `DEVELOPMENT.md` se aplicável

---

## 🎨 Padrões de Código

### Checagem de Janela Válida

Sempre valide janelas antes de operar:

```autohotkey
; ✅ Correto
if (!IsValidWindow(hwnd))
    return

; ❌ Evite
if (!hwnd)
    return
```

A função `IsValidWindow()` está em `utils.ahk` e já filtra minimizadas, de sistema, etc.

### Obter Posição do Monitor

```autohotkey
; ✅ Use a função utilitária
monIndex := GetWindowMonitor(hwnd)

; ❌ Evite duplicar lógica
WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
; ... calcular centro ...
; ... comparar com todos os monitores ...
```

### Restaurar Janelas Maximizadas

```autohotkey
; ✅ Use função auxiliar
RestoreIfMaximized(hwndA)
RestoreIfMaximized(hwndB)

; ❌ Evite código duplicado
if (WinGetMinMax("ahk_id " hwndA) == 1)
    WinRestore("ahk_id " hwndA)
```

### Comentários e Separadores

Use comentários descritivos e separadores visuais:

```autohotkey
; ================= NOME DA SEÇÃO =================
; Descrição do que esta seção faz

; Comentário para lógica complexa
if (Abs(dx) >= Abs(dy)) {
    ; Lado a lado na horizontal
    ; ...
} else {
    ; Empilhadas na vertical
    ; ...
}
```

### Tratamento de Erros

Use blocos `try` para operações que podem falhar:

```autohotkey
global vdExe

if (FileExist(vdExe)) {
    try Run(vdExe ' /pwh:' hwnd,, "Hide")
}
```

---

## 🧪 Testando Suas Alterações

### Recarregar o Script

Pressione **`Win + Alt + R`** para recarregar sem reiniciar.

### Verificar Erros

Se algo falhar:

1. Procure por mensagens de erro do AutoHotkey
2. Verifique a sintaxe do arquivo modificado
3. Use `MsgBox` para debug:

```autohotkey
; Debug: verificar valor
MsgBox("hwnd é: " hwnd)

; Debug: verificar fluxo
MsgBox("Chegou aqui")
```

### Testar com Múltiplas Janelas

Para testar:

1. Abra várias janelas (Notepad, Explorer, etc)
2. Teste a funcionalidade em diferentes cenários
3. Teste em múltiplos monitores (se aplicável)

### Testar com Monitores Virtuais

Para testar com desktops virtuais:

1. Crie um novo desktop (`Win + Ctrl + D`)
2. Mova janelas entre desktops
3. Verifique se a funcionalidade funciona corretamente

---

## 📝 Convenções de Nomenclatura

### Funções

Use **PascalCase** e nomes descritivos:

```autohotkey
; ✅ Correto
GetWindowMonitor(hwnd)
IsValidWindow(hwnd)
RestoreIfMaximized(hwnd)
AdjustWindowSplit(delta)

; ❌ Evite
GetMon(hwnd)
IsValid(hwnd)
Restore(hwnd)
AdjustSplit(delta)
```

### Variáveis Locais

Use **camelCase** para variáveis locais:

```autohotkey
bestHwnd := 0
minDist := 99999999
hwndA := WinExist("A")
```

### Variáveis Globais

Use **camelCase** com prefixo ou contexto claro:

```autohotkey
global vdExe := A_ScriptDir "\VirtualDesktop11.exe"
global configMargin := 10
```

### Constantes

Use **UPPER_SNAKE_CASE**:

```autohotkey
MIN_WINDOW_WIDTH := 150
MIN_WINDOW_HEIGHT := 150
MARGIN_OUTER := 10
MARGIN_INNER := 12
```

---

## 🐛 Debugging e Troubleshooting

### Problema: Função não é reconhecida

**Causa:** Módulo não foi incluído em `tiling.ahk`

**Solução:** Verifique se `#Include "seu-modulo.ahk"` está em `tiling.ahk`

### Problema: Janelas não respondem

**Causa:** Pode ser uma janela protegida ou em modo fullscreen

**Solução:** Adicione validações usando `IsValidWindow()`

### Problema: Atalho não funciona

**Causa:** Conflito com outro programa ou sintaxe incorreta

**Solução:** 
1. Verifique a sintaxe do atalho
2. Mude para uma combinação diferente
3. Recarregue o script (`Win + Alt + R`)

### Problema: Monitor não é detectado

**Causa:** Possível problema com `MonitorGet()` ou disposição não esperada

**Solução:**
1. Teste com `MsgBox` para visualizar `MonitorGetCount()`
2. Verifique se o monitor está ativo
3. Tente `MonitorGetWorkArea()` em vez de `MonitorGet()`

### Usando MsgBox para Debug

```autohotkey
; Verificar se uma função foi chamada
MsgBox("MyFunction foi chamada")

; Verificar valor de variável
MsgBox("hwnd = " hwnd "`nmonitor = " currentMon)

; Verificar status de arquivo
if (FileExist(vdExe))
    MsgBox("VirtualDesktop11.exe foi encontrado")
else
    MsgBox("VirtualDesktop11.exe NÃO foi encontrado")
```

---

## 🚀 Checklist para Nova Funcionalidade

Antes de commitar, verifique:

- [ ] Código segue os padrões do projeto
- [ ] Funções têm nomes descritivos em PascalCase
- [ ] Módulo está incluído em `tiling.ahk`
- [ ] Atalho está definido em `tiling.ahk`
- [ ] README.md foi atualizado com novo atalho
- [ ] Testou em múltiplas janelas/monitores
- [ ] Sem erros de sintaxe
- [ ] Commit com mensagem clara e descritiva

---

## 📚 Recursos Úteis

- [Documentação AutoHotkey v2](https://www.autohotkey.com/docs/v2/)
- [Funções de Janela](https://www.autohotkey.com/docs/v2/lib/Win.htm)
- [Atalhos de Teclado](https://www.autohotkey.com/docs/v2/Hotkeys.htm)
- [Referência de Variáveis Especiais](https://www.autohotkey.com/docs/v2/Variables.htm)

---

## 💡 Exemplos de Extensões Possíveis

### 1. Adicionar Snapshot de Layouts

Criar atalho para salvar/restaurar layouts de janelas:

```autohotkey
; salvar layout
#!s::SaveWindowLayout()

; restaurar layout
#!l::RestoreWindowLayout()
```

**Arquivo:** `window-layout.ahk`

### 2. Adicionar Ciclo de Zoom

Implementar ciclo de zoom (pequeno → médio → grande → tela cheia):

```autohotkey
; próximo tamanho
#]::CycleWindowSize()

; tamanho anterior
#[::CycleWindowSize(-1)
```

**Arquivo:** `window-zoom.ahk`

### 3. Adicionar Gestos de Mouse

Implementar gestos com mouse para mover/redimensionar janelas:

```autohotkey
; arrastar com botão direito
RButton::BeginMouseGesture()
```

**Arquivo:** `mouse-gestures.ahk`

### 4. Adicionar Configuração via JSON

Carregar configurações de um arquivo `config.json`:

```autohotkey
; carregar configurações
LoadConfig()

; margin customizável
marginOuter := config.marginOuter
marginInner := config.marginInner
```

**Arquivo:** `config.ahk`

---

## 📞 Contribuindo

Se você criou uma nova funcionalidade interessante:

1. Crie um branch: `git checkout -b feature/sua-funcionalidade`
2. Commit com mensagem clara: `git commit -m "feat: adicionar sua funcionalidade"`
3. Faça push: `git push origin feature/sua-funcionalidade`
4. Crie um Pull Request com descrição detalhada

---

**Última atualização:** Outubro 2026

Para dúvidas ou sugestões, consulte o `README.md` ou abra uma issue no repositório.
