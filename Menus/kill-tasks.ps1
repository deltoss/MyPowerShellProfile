function Kill-Tasks {
  $selected = Get-Process | Where-Object {$_.ProcessName -ne "Idle"} |
        ForEach-Object { "{0,8} {1,-30} {2,10:F1}" -f $_.Id, $_.ProcessName, $_.CPU } |
        fzf --multi --header="PID     Process Name                   CPU (Tab to select multiple)" --preview="echo 'Kill selected processes?'"

  if ($selected) {
    $processIds = $selected | ForEach-Object { $_.Trim().Split()[0] }

    Write-Host "About to kill $($processIds.Count) process(es):" -ForegroundColor Yellow
    foreach ($processId in $processIds) {
      Write-Host "  - Process ID: $processId" -ForegroundColor Cyan
    }

    $confirm = Read-Host "Proceed? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
      foreach ($processId in $processIds) {
        try {
          Write-Host "Killing process $processId..." -ForegroundColor Red
          Stop-Process -Id $processId -Force -ErrorAction Stop
          Write-Host "✓ Process $processId killed" -ForegroundColor Green
        } catch {
          Write-Host "✗ Failed to kill process $processId`: $_" -ForegroundColor Red
        }
      }
    } else {
      Write-Host "Cancelled." -ForegroundColor Gray
    }
  }
}
Set-Alias -Name kt -Value Kill-Tasks

Set-PSReadLineKeyHandler -Key Ctrl+k -ScriptBlock {
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Kill-Tasks')
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}
