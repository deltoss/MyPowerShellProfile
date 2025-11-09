# Git branch picker
# E.g:
#   git checkout (gbr)
function Select-GitBranch {
  [CmdletBinding()]
  param (
    [Parameter(Position=0, Mandatory=$false, HelpMessage="Provide an array of additional selections")]
    [string[]]
    $AdditionalOptions = @()
  )

  $interaction = $additionalOptions + (git branch -a --color=always) | fzf --print-query --ansi --header="Git - Branches" | ForEach-Object {
    $_.Trim() -replace '^\*\s*', '' -replace '^remotes/', '' -replace '\x1b\[[0-9;]*m', '' -replace '\+\s+', '' -replace '\s*->.+', ''
  }

  if (-not $interaction) { return $null }

  if ($interaction -is [string]) { # Only a search query, but no selection
    return [PSCustomObject]@{
      Query = $interaction
      Branch = $null
    }
  }

  return [PSCustomObject]@{ # A query, and a selection
    Query = $interaction[0]
    Branch = $interaction[1]
  }
}
$gitBranchScript = {
  $interaction = Select-GitBranch
  if ($interaction -and $interaction.Branch) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($interaction.Branch) }
}
Set-Alias -Name gb -Value Select-GitBranch

# Git commit picker
# E.g:
#   git show (gco)
#   git cherry-pick (gco)
function Select-GitCommit {
  git log --all --color=always --pretty=format:"%C(yellow)%h%C(reset) %C(green)%ad%C(reset) %s %C(blue)(%an)%C(reset) %H" --date=format:"%Y-%m-%d %I:%M %p" | fzf --ansi --header="Git - Commits" | ForEach-Object {
    ($_ -replace '\x1b\[[0-9;]*m', '').Split(' ')[0]
  }
}
Remove-Alias -Force -Name gc
Set-Alias -Name gc -Value Select-GitCommit
$gitCommitScript = {
  $commit = Select-GitCommit
  if ($commit) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($commit) }
}

# Git file picker (modified files)
# E.g:
#   git add (gfi)
function Select-GitFile {
  git status --porcelain | fzf --header="Git - Changed Files" | ForEach-Object { $_.Substring(3) }
}
Set-Alias -Name gf -Value Select-GitFile

# Git log
function Show-GitLog {
  param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$AdditionalFlags
  )

  $baseArgs = @(
    'log',
    '--graph',
    '--pretty=format:%C(yellow)%h%Creset %C(green)%ad%Creset %C(bold blue)%an%Creset %C(red)%d%Creset %s %C(dim white)%b%Creset',
    '--date=short',
    '--color'
  )

  $allArgs = $baseArgs + $AdditionalFlags
  & git $allArgs
}
Remove-Alias -Force -Name gl
Set-Alias -Name gl -Value Show-GitLog
$gitLogScript = {
  $branch = "HEAD"
  $selection = Select-GitBranch -AdditionalOptions @("  HEAD", "  --all")
  if ($selection) {
    $branch = $selection.Branch
  }
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert("Show-GitLog $branch")
}

$gitEditGitHubGistsScript = {
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('gh gist edit')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

$gitResolveMergeConflictScript = {
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('git mergetool')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

$global:WhichGBindings = @(
  @{
    Key = 'g'
    Desc = 'Lazy[G]it'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('lazygit')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'f'
    Desc = 'Select git [F]ile'
    Action = { Select-GitFile }
    Openers = $global:Openers.All
  },
  @{
    Key = 'b'
    Desc = 'Select git [B]ranch'
    Action = $gitBranchScript
  },
  @{
    Key = 'c'
    Desc = 'Select git [C]ommit'
    Action = $gitCommitScript
  },
  @{
    Key = 'l'
    Desc = 'Show git [L]og'
    Action = $gitLogScript
  },
  @{
    Key = 'G'
    Desc = 'Edit GitHub [G]ists'
    Action = $gitEditGitHubGistsScript
  },
  @{
    Key = 'm'
    Desc = 'Resolve git [M]erge conflicts'
    Action = $gitResolveMergeConflictScript
  },
  @{
    Key = 'p'
    Desc = 'Open [P]ull request'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('pr')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'w'
    Desc = '[W]orktree'
    Action = { Show-WhichMenu -Bindings $global:WhichGWBindings -Title '[W]orktree' }
  }
)

Set-PSReadLineKeyHandler -Key Ctrl+g -ScriptBlock {
  Show-WhichMenu -Bindings $global:WhichGBindings -Title '[G]it'
}
