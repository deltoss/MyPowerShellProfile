function Invoke-Eza {
  $expandedArgs = $args | ForEach-Object {
    if ($_ -match '^~') {
      $_ -replace '^~', $HOME
    } else {
      $_
    }
  }
  & eza --oneline -A $expandedArgs
}

Set-Alias -Name ls -Value Invoke-Eza
