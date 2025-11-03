# [S]earching globally
function Search-ZoxideDirectories {
  zoxide query --interactive
}
# Usage example:
#   nvim (zq)
#   explorer (sz)
#   cd (sz)
Set-Alias -Name sz -Value Search-ZoxideDirectories
Set-Alias -Name zq -Value Search-ZoxideDirectories

function Search-Query {
    # Pipe null to disable the initial unnecessary search upon entering fzf
    # Sleep command is there to debounce the query so we don't search on every single letter typed
    $null | fzf --bind "change:reload-sync(Start-Sleep -m 100; es -sort date-modified-descending count:100 {q:1} {q:2} {q:3} {q:4} {q:5} {q:6} {q:7} {q:8} {q:9})" --phony --query "" --header="Search - Query"
}
Set-Alias -Name ss -Value Search-Query
Set-Alias -Name sq -Value Search-Query

function Search-DotNetSolutions {
    es /a-d -r !"*Recycle.Bin*\*" !"*RECYCLE*\*" !"C:\Program*\*" *.sln | fzf --multi --header='Search - .NET Solutions (Tab to Select)' | Where-Object { Start-Process devenv -Argument """$_""" }
}
Set-Alias -Name sd -Value Search-DotNetSolutions
Set-Alias -Name sn -Value Search-DotNetSolutions

function Search-ObsidianNotes {
    fd . "$env:USERPROFILE\Documents\Note Taking" | fzf --header="Search - Obsidian Notes" --preview $env:FZF_CUSTOM_PREVIEW
}
Set-Alias -Name so -Value Search-ObsidianNotes

function Search-GitRepositories {
    es -r folder:^\.git$ !"*RECYCLE*\*" !"C:\Program*\*" | ForEach-Object { Split-Path $_ -Parent } | fzf --header="Search - Git Repositories" --preview $env:FZF_CUSTOM_PREVIEW
}
Set-Alias -Name sg -Value Search-GitRepositories

function Search-Recents {
    # Pipe null to disable the initial unnecessary search upon entering fzf
    # Sleep command is there to debounce the query so we don't search on every single letter typed
    $null | fzf --bind "change:reload-sync(Start-Sleep -m 100; es -sort date-modified-descending count:100 dm:thisweek {q:1} {q:2} {q:3} {q:4} {q:5} {q:6} {q:7} {q:8} {q:9})" --phony --query "" --header="Search - Recents"
}
# Usage example: nvim (sr)
Set-Alias -Name sr -Value Search-Recents

function Search-History {
    $history = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems() | 
        ForEach-Object {
            # Clean up all types of line breaks and replace with pipe
            $_.CommandLine -replace "`r`n|`n|`r", " | "
        } | Select-Object -Unique

    $buffer = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$null)

    $selected = $history | fzf --tac --query $buffer --header="Search - Command History"
    if ($selected) {
        $cleanCommand = $selected -replace " \| ", "`n"
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($cleanCommand)
    }
}
Set-Alias -Name sh -Value Search-History
$searchHistoryScript = { Search-History }
Set-PSReadLineKeyHandler -Key 'Ctrl+r' -ScriptBlock $searchHistoryScript

$global:WhichSBindings = @(
  @{
    Key = 'z'
    Desc = '[Z]oxide'
    Action = { Search-ZoxideDirectories }
    Openers = $global:Openers.All
  },
  @{
    Key = 's'
    Desc = '[S]earch'
    Action = { Search-Query }
    Openers = $global:Openers.All
  },
  @{
    Key = 'n'
    Desc = '.[N]et Solutions'
    Action = { Search-DotNetSolutions }
  },
  @{
    Key = 'o'
    Desc = '[O]bsidian Notes'
    Action = { Search-ObsidianNotes }
    Openers = $global:Openers.All
  },
  @{
    Key = 'g'
    Desc = '[G]it Repositories'
    Action = { Search-GitRepositories }
    Openers = $global:Openers.All
  },
  @{
    Key = 'r'
    Desc = '[R]ecents'
    Action = { Search-Recents }
    Openers = $global:Openers.All
  },
  @{
    Key = 'h'
    Desc = 'Command [H]istory'
    Action = $searchHistoryScript
  }
)

Set-PSReadLineKeyHandler -Key Ctrl+s -ScriptBlock {
  Show-WhichMenu -Bindings $global:WhichSBindings -Title '[S]earch globally'
}
