$scriptDir = $PSScriptRoot

. "$scriptDir/environments.ps1"
. "$scriptDir/Tools/PSReadline.ps1"
. "$scriptDir/Tools/yazi.ps1"
. "$scriptDir/Tools/fzf.ps1"
. "$scriptDir/Tools/ripgrep.ps1"
. "$scriptDir/Tools/bat.ps1"
. "$scriptDir/Tools/eza.ps1"
. "$scriptDir/Tools/starship.ps1"
. "$scriptDir/Tools/zoxide.ps1"
. "$scriptDir/Tools/chezmoi.ps1"
. "$scriptDir/Tools/neovim.ps1"
. "$scriptDir/Tools/aichat-shell-integration.ps1"
. "$scriptDir/Tools/aichat-shell-autocompletion.ps1"
. "$scriptDir/Tools/atac.ps1"
. "$scriptDir/Tools/navi.ps1"

. "$scriptDir/Menus/search.ps1"
. "$scriptDir/Menus/find.ps1"
. "$scriptDir/Menus/git.ps1"
. "$scriptDir/Menus/git-worktrees.ps1"
. "$scriptDir/Menus/git-pull-request.ps1"
. "$scriptDir/Menus/kill-tasks.ps1"
. "$scriptDir/Menus/network-connections.ps1"
. "$scriptDir/Menus/llm.ps1"
. "$scriptDir/Menus/help-pages.ps1"

Import-Module "$scriptDir/Modules/WhichMenu"
Import-Module "$scriptDir/Modules/RandomCliTip"

Get-RandomFavoriteCli
