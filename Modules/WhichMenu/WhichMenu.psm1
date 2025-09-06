function Show-WhichMenu {
  param(
    [Parameter(Mandatory = $true)]
    [array]$Bindings,

    [Parameter(Mandatory = $true)]
    [string]$Title
  )

  "`n=== $Title ===" | Out-Host
  foreach ($binding in $Bindings) {
    "$($binding.Key) → $($binding.Desc)" | Out-Host
  }

  $keyInfo = [Console]::ReadKey($true)
  $keyChar = $keyInfo.KeyChar.ToString()
  $keyName = $keyInfo.Key.ToString()

  if ($keyName -eq 'Escape') {
    $keyChar = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }

  $match = $Bindings | Where-Object { $_.Key -ceq $keyChar }
  if (-not $match -and $keyChar) {
    Write-Host "No command bound to '$keyChar'"
    Read-Host "Press Enter to continue"
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    return
  }

  if (!$match) { return }

  $selection = & $match.Action

  if (-not $selection) {
    return
  } elseif (-not $match.Openers) {
    # No Openers, then just insert selection to the CLI
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
  } elseif ($match.Openers.Count -gt 1) {
    Show-OpenerMenu $match $selection
  } elseif ($match.Openers.Count -eq 1) {
    $opener = $match.Openers[0]
    Invoke-OpenerCommand $opener.Key $Selection $opener
  }
}

function Show-OpenerMenu {
  param(
    [Parameter(Mandatory = $true)]
    $Binding,

    [Parameter(Mandatory = $true)]
    $Selection
  )

  "`n=== Open With ===" | Out-Host
  foreach ($opener in $Binding.Openers) {
    "$($opener.Key) → $($opener.Desc)" | Out-Host
  }

  $keyInfo = [Console]::ReadKey($true)
  $keyChar = $keyInfo.KeyChar.ToString()
  $keyName = $keyInfo.Key.ToString()

  if ($keyName -eq 'Escape') {
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    return
  } elseif ($keyName -eq "Enter") {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("`"$Selection`"")
    return
  }

  $selectedOpener = $Binding.Openers | Where-Object Key -ceq $keyChar | Select-Object -First 1
  if (!$selectedOpener) {
    Write-Host "No opener found matching the key '$keyChar'..." -ForegroundColor Yellow
    return
  }

  Invoke-OpenerCommand $keyChar $Selection $selectedOpener
}

function Invoke-OpenerCommand {
  param(
    [Parameter(Mandatory = $true)]
    $Key,

    [Parameter(Mandatory = $true)]
    $Selection,

    [Parameter(Mandatory = $true)]
    $Opener
  )

  if ($Opener.ParseAsDirectory) {
    $Selection = ConvertTo-DirectoryPath $Selection
  }

  if ($Opener.Command -is [string]) {
    $command = $Opener.Command -replace '\{\{Selection\}\}', $Selection
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
  } else {
    $result = & $Opener.Command $Selection
    if ($result) {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
    }
  }

  $causesInvoke = $Opener.CausesInvoke
  if ($causesInvoke) {
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }
}

function ConvertTo-DirectoryPath {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (Test-Path $Path -PathType Container) {
    return $Path
  } else {
    $parentDir = Split-Path $Path -Parent
    if ($parentDir) {
      return $parentDir
    }
  }
}

$global:Openers = @{
  Core = @(
    @{
      Key = 'q'
      Desc = "[Q]uery"
      Command = '"{{Selection}}"'
      CausesInvoke = $false
      ParseAsDirectory = $false
    }
  )

  Editors = @(
    @{
      Key = 'n'
      Desc = "[N]eovim"
      Command = 'nvim "{{Selection}}"'
      CausesInvoke = $true
    },
    @{
      Key = 'v'
      Desc = "[V]SCode"
      Command = 'code "{{Selection}}"'
      CausesInvoke = $true
    }
  )

  Folders = @(
    @{
      Key = 'c'
      Desc = "[C]hange Directory"
      Command = 'cd "{{Selection}}"'
      CausesInvoke = $true
      ParseAsDirectory = $true
    },
    @{
      Key = 'y'
      Desc = "[Y]azi"
      Command = 'y "{{Selection}}"'
      CausesInvoke = $true
      ParseAsDirectory = $true
    },
    @{
      Key = 'e'
      Desc = "[E]xplorer"
      Command = 'explorer "{{Selection}}"'
      CausesInvoke = $true
      ParseAsDirectory = $true
    }
  )
}

$global:Openers.All = $global:Openers.Core + $global:Openers.Editors + $global:Openers.Folders

Export-ModuleMember -Function Show-WhichMenu -Variable Openers
