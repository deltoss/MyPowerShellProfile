function Set-KeyBinding {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string[]]$Chord,

    [Parameter(ValueFromRemainingArguments)]
    $RemainingArgs
  )

  # Start with the Chord parameter
  $PSReadLineParams = @{
    Chord = $Chord
  }

  if ($RemainingArgs) {
    for ($i = 0; $i -lt $RemainingArgs.Count; $i += 2) {
      if ($i + 1 -lt $RemainingArgs.Count) {
        $paramName = $RemainingArgs[$i] -replace '^-', ''
        $PSReadLineParams[$paramName] = $RemainingArgs[$i + 1]
      }
    }
  }

  try {
    Set-PSReadLineKeyHandler @PSReadLineParams
    Write-Host "✓ Bound $Chord" -ForegroundColor Green
  }
  catch {
    $chordDisplay = $Chord -join '+'
    Write-Error "Failed to bind $chordDisplay`: $_"
  }
}

Export-ModuleMember -Function Set-KeyBinding
