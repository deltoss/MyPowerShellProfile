function Prompt-RoleOption {
  $role = aichat --list-roles | fzf --header "Roles"
  if ($role) {
    return @("--role", $role)
  } else {
    return @()
  }
}

function Prompt-ModelOption {
  $model = aichat --list-models | fzf --header "Models"
  if ($model) {
    return @("--model", $model)
  } else {
    return @()
  }
}

function Invoke-Aichat {
  if ($args.Count -eq 0 -or ($args.Count -eq 1 -and $args[0] -is [string] -and -not $args[0].StartsWith('-'))) {
    $promptArgs = @()
    $promptArgs += Prompt-ModelOption
    $promptArgs += Prompt-RoleOption
    if ($args.Count -eq 0) {
      & aichat --session @promptArgs
    } else {
      & aichat @promptArgs @args
    }
  } else {
    & aichat @args
  }
}
Set-Alias -Name ai -Value Invoke-Aichat

function Invoke-Aichat-Execute {
  $promptArgs = Prompt-ModelOption
  & aichat @promptArgs --execute @args
}
Set-Alias -Name aie -Value Invoke-Aichat-Execute

function Invoke-Aichat-Code {
  $promptArgs = Prompt-ModelOption
  & aichat @promptArgs --code @args
}
Set-Alias -Name aic -Value Invoke-Aichat-Code

function Invoke-Aichat-Sessions {
  & aichat --session (aichat --list-sessions | fzf --header "Sessions") @args
}
Set-Alias -Name ais -Value Invoke-Aichat-Sessions

function Invoke-Aichat-Rags {
  & aichat --rag (aichat --list-rags | fzf --header "RAGs") @args
}
Set-Alias -Name air -Value Invoke-Aichat-Rags

function Invoke-Aichat-Macros {
  & aichat --macro (aichat --list-macros | fzf --header "Macros") @args
}
Set-Alias -Name aim -Value Invoke-Aichat-Macros

function Review-Structure-Aichat {
  & eza --recurse --tree --git-ignore | aichat --model (aichat --list-models | fzf --header "Models") "Analyze this project structure and suggest improvements in the context of software development."
}

function Review-Changes-Aichat {
  param(
    [string]$SessionName = "code-review-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
  )

  Write-Host "Session name: $SessionName"

  $initialPrompt += "I will give you code files, and the git diffs. I want you to review the code change in the context of the full file. Consider:
        1. Does the change make sense given the overall file structure?
        2. Are there any potential issues or improvements?
        3. Does it follow the existing code patterns and style?"

  aichat -s $SessionName $initialPrompt
  git diff --name-only | fzf -m --header "Select multiple with [TAB] and [SHIFT-TAB]" | ForEach-Object {
    $file = $_
    $diff = git diff $file

    $prompt = "Here's the git diff for this file:" + [Environment]::NewLine
    $prompt += $diff

    & aichat --session $SessionName --file $file $prompt
  }
}

function Explain-Code-Aichat {
  param(
    [string]$SessionName = "code-explain-$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
  )

  echo "Session name: $SessionName"

  $RG_PREFIX = "rg --column --line-number --no-heading --color=always --smart-case"

  $result = fzf --ansi --disabled --query "" `
  --bind "start:reload-sync:$RG_PREFIX {q}" `
  --bind "change:reload-sync:$RG_PREFIX {q}" `
  --delimiter ":" `
  --preview "bat --color=always {1} --highlight-line {2}" `
  --preview-window "up,60%,border-bottom,+{2}+3/3,~3" `
  --header "Open in Neovim"

  if ($result) {
    $parts = $result -split ':'
    $file = $parts[0]
    $line = $parts[1]

    if ($file -and $line) {
      & aichat --session $SessionName --file $file "Explain the code in line $line of the file I just gave you"
    }
  }
}

$global:WhichABindings = @(
  @{
    Key = 'l'
    Desc = 'AI/[L]LM'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('ai')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'a'
    Desc = '[A]I/LLM'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('ai')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'e'
    Desc = '[E]xecute or copy command from natural language'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('aie')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'c'
    Desc = 'Display [C]ode output from natural language'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('aic')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'r'
    Desc = 'Start [R]AG'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('air')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'm'
    Desc = 'Start [M]acro'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('aim')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 's'
    Desc = 'Continue From Existing [S]ession'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('ais')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'S'
    Desc = 'Review Code [S]tructure'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Review-Structure-Aichat')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'C'
    Desc = 'Review Code [C]hanges'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Review-Changes-Aichat')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'E'
    Desc = '[E]xplain Code'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Explain-Code-Aichat')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  }
)

Set-PSReadLineKeyHandler -Key Ctrl+a -ScriptBlock {
  Show-WhichMenu -Bindings $global:WhichABindings -Title 'LLM [A]I'
}
