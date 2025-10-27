$env:INTELLI_HOME = "$env:USERPROFIlE/intelli-shell/data"
$env:INTELLI_CONFIG = "$env:XDG_CONFIG_HOME/intelli-shell/config.toml"
$env:INTELLI_SEARCH_HOTKEY = "Ctrl+e"

intelli-shell.exe init pwsh | Out-String | Invoke-Expression
