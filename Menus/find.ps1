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
  }
)

Set-PSReadLineKeyHandler -Key Ctrl+f -ScriptBlock {
  Show-WhichMenu -Bindings $global:WhichFBindings -Title '[F]ind locally'
}
