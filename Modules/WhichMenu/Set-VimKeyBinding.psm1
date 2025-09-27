Export-ModuleMember -Function Set-VimKeyBinding, Set-VimLeaderKey
Import-Module "$PSScriptRoot/ConvertFrom-VimKeyBinding"
Import-Module "$PSScriptRoot/Set-KeyBinding"

function Set-VimKeyBinding {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$vimKeyBinding,

    [Parameter(ValueFromRemainingArguments)]
    $RemainingArgs
  )

  $keyBinding = ConvertFrom-VimKeyBinding $vimKeyBinding
  Write-Host "Converted Vim keybind '$vimKeyBinding' to '$keyBinding'"

  $processedArgs = Get-ProcessedArgs @RemainingArgs
  Set-KeyBinding -Chord $keyBinding @processedArgs
}

function Get-ProcessedArgs {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromRemainingArguments)]
    $RemainingArgs
  )

  $processedArgs = @()
  $i = 0

  while ($i -lt $RemainingArgs.Count) {
    $arg = $RemainingArgs[$i]

    if ($arg -eq '-ScriptBlock' -and ($i + 1) -lt $RemainingArgs.Count) {
      $processedArgs += $arg
      # Skip the parameter itself
      $i++

      $originalScriptBlock = $RemainingArgs[$i]
      $wrappedScriptBlock = {
        $buffer = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$null)
        $isBufferEmpty = [string]::IsNullOrWhiteSpace($buffer)

        if ($isBufferEmpty) {
          Write-Host "Buffer is empty" -ForegroundColor Cyan
        }
        & $originalScriptBlock
      }.GetNewClosure()

      $processedArgs += $wrappedScriptBlock
    }
    elseif ($arg -eq '-Function' -and ($i + 1) -lt $RemainingArgs.Count) {
      $i++

      $functionName = $RemainingArgs[$i]
      $processedArgs += '-ScriptBlock' # Convert the -Function to -ScriptBlock

      $wrappedScriptBlock = {
        $buffer = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$buffer, [ref]$null)
        $isBufferEmpty = [string]::IsNullOrWhiteSpace($buffer)

        if ($isBufferEmpty) {
          Write-Host "Buffer is empty (calling function: $($functionName))" -ForegroundColor Cyan
        }
        & $functionName
      }.GetNewClosure()

      $processedArgs += $wrappedScriptBlock
    }
    else {
      # Pass through other arguments unchanged
      $processedArgs += $arg
    }

    $i++
  }

  return $processedArgs
}

Export-ModuleMember -Function Set-VimKeyBinding
