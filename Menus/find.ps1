# [F]ind locally
function Find-Files {
  fd | fzf --tac --header="Find - In Current Directory" --preview $env:FZF_CUSTOM_PREVIEW
}
Set-Alias -Name ff -Value Find-Files

function Find-GitRepositoryFiles {
  $repoRoot = "$((git rev-parse --show-toplevel) -replace '/', '\')"
  $repoFiles = fd "" $repoRoot
  $coloredFiles = $repoFiles | ForEach-Object {
    $fullPath = $_
    $relativePath = $fullPath.Substring($repoRoot.Length).TrimStart('\')
    $coloredRelative = "`e[36m$relativePath`e[0m"
    $displayLine = $fullPath -replace [regex]::Escape($relativePath), $coloredRelative
    return $displayLine
  }
  return $coloredFiles | fzf --tac --header="Find - In Current Repository" --ansi --preview $env:FZF_CUSTOM_PREVIEW
}
Set-Alias -Name fg -Value Find-GitRepoFiles
Set-Alias -Name fr -Value Find-GitRepoFiles

function Search-CodeLine {
  $RG_PREFIX = "rg --column --line-number --no-heading --color=always --smart-case"

  return fzf --ansi --disabled --query "" `
  --bind "start:reload-sync:$RG_PREFIX {q}" `
  --bind "change:reload-sync:$RG_PREFIX {q}" `
  --delimiter ":" `
  --preview "bat --color=always {1} --highlight-line {2}" `
  --preview-window "up,60%,border-bottom,+{2}+3/3,~3" `
  --header "Open in Neovim"
}

$neovimCodeLineOpener = @{
  Key = 'n'
  Desc = '[N]eovim'
  Command = {
  param($Selection)
    Write-Host "Selection $Selection"
    if ($Selection) {
      $parts = $Selection -split ':'
      $file = '"' + $parts[0] + '"'
      $line = $parts[1]

      if ($file -and $line) {
        Write-Host "File and Line: $file $line"
        Start-Process -FilePath "nvim" -ArgumentList "+$line", $file -NoNewWindow -Wait
      }
    }
  }
}

$global:WhichFBindings = @(
  @{
    Key = 'f'
    Desc = '[F]iles'
    Action = { Find-Files }
    Openers = $global:Openers.All
  },
  @{
    Key = 'g'
    Desc = 'Files in [G]it Repository'
    Action = { Find-GitRepositoryFiles }
    Openers = $global:Openers.All
  },
  @{
    Key = 'c'
    Desc = 'File [C]ontent'
    Action = { Search-CodeLine }
    Openers = @($neovimCodeLineOpener)
  }
)

Set-PSReadLineKeyHandler -Key Ctrl+f -ScriptBlock {
  Show-WhichMenu -Bindings $global:WhichFBindings -Title '[F]ind locally'
}
