# Use Neovim to edit the Shell console
Set-PSReadLineKeyHandler -Key Ctrl+o -ScriptBlock {
  $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1" # The temp file extension is for Neovim's syntax highlighting

  try {
    # Get current command from console to feed to Neovim via a temp file
    $line = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$null)

    $line | Out-File $tempFile -Encoding utf8

    Start-Process -FilePath "nvim" -ArgumentList $tempFile -NoNewWindow -Wait
    $newCommand = (Get-Content $tempFile -Raw).TrimEnd() -replace "`r`n", "`n"

    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($newCommand)
  }
  catch {
    Write-Host "Error: $($_.Exception.Message)"
  }
  finally {
    Remove-Item $tempFile
  }
}
