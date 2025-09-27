Import-Module "$PSScriptRoot/LeaderKey"

function ConvertFrom-VimKeyBinding {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$VimKeyBinding
  )

  $vimKeyBinding = $vimKeyBinding.Replace('<leader>', (Get-LeaderKey))

  # Translate special key mappings. See:
  # - https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/using-keyhandlers?view=powershell-7.5#finding-key-names-and-chord-bindings
  # - https://learn.microsoft.com/en-us/dotnet/api/system.consolekey
  $specialKeys = @{
    'Enter' = 'Enter'
    'Return' = 'Enter'
    'CR' = 'Enter'
    'Esc' = 'Escape'
    'Space' = 'Spacebar'
    'Tab' = 'Tab'
    'BS' = 'Backspace'
    'Backspace' = 'Backspace'
    'Del' = 'Delete'
    'Delete' = 'Delete'
    'Up' = 'UpArrow'
    'Down' = 'DownArrow'
    'Left' = 'LeftArrow'
    'Right' = 'RightArrow'
    'Home' = 'Home'
    'End' = 'End'
    'PageUp' = 'PageUp'
    'PageDown' = 'PageDown'
    'Insert' = 'Insert'
    'kInsert' = 'Insert'
  }

  $result = @()
  $remaining = $VimKeyBinding

  # Parse the string character by character, handling angle bracket sequences
  while ($remaining.Length -gt 0) {
    # Check for angle bracket notation
    if ($remaining -match '^<([^>]+)>(.*)') {
      $keyContent = $Matches[1]
      $remaining = $Matches[2]

      $modifiers = @()
      $baseKey = $keyContent

      # Parse modifiers - split on dash and check each part
      $parts = $keyContent -split '-'
      if ($parts.Length -gt 1) {
        $baseKey = $parts[-1] # Last part is the key
        $modifierParts = $parts[0..($parts.Length-2)] # Everything else

        foreach ($mod in $modifierParts) {
          switch ($mod) {
            'C' { $modifiers += 'Ctrl' }
            'A' { $modifiers += 'Alt' }
            'S' { $modifiers += 'Shift' }
          }
        }
      }

      if ($specialKeys.ContainsKey($baseKey)) {
          $baseKey = $specialKeys[$baseKey]
      } elseif ($baseKey -cmatch '[A-Z]') {
          $modifiers += 'Shift'
          $baseKey = $baseKey.ToLower()
      }

      if ($modifiers.Count -gt 0) {
          $result += ($modifiers + $baseKey) -join '+'
      } else {
          $result += $baseKey
      }
    }
    # Handle regular characters
    else {
      $char = $remaining.Substring(0, 1)
      $remaining = $remaining.Substring(1)

      if ($char -cmatch '[A-Z]') {
        $result += "Shift+$($char.ToLower())"
      } else {
        $result += $char
      }
    }
  }

  return $result | Join-String -Separator ','
}

Export-ModuleMember -Function ConvertFrom-VimKeyBinding
