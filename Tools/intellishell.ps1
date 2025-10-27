$env:INTELLI_CONFIG = "$env:XDG_CONFIG_HOME/intelli-shell/config.toml"

intelli-shell init powershell | Out-String | Invoke-Expression
