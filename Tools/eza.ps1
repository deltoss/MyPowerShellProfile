function Invoke-Eza {
    & eza --oneline -A @args
}
Set-Alias -Name ls -Value Invoke-Eza
