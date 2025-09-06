$env:BAT_PAGER = "less" # On Windows, see: https://github.com/jftuga/less-Windows
$env:BAT_THEME = "gruvbox-light"

function Invoke-Bat {
    & bat --color=always --style=numbers @args
}
Set-Alias -Name cat -Value Invoke-Bat

