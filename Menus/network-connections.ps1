function Get-SSHConnections {
  Get-Content "$env:USERPROFILE\.ssh\config" |
  Where-Object { $_ -match '^Host\s+(.+)' } |
  ForEach-Object {
    ($matches[1] -split '\s+') | Where-Object { $_ -notmatch '[*?]' }
  } | Sort-Object -Unique
}
function Connect-SSH {
  $selectedConn = Get-SSHConnections | fzf --tac --header="Connect - SSH"
  ssh $selectedConn
}
Set-Alias -Name cs -Value Connect-SSH

function Open-NetworkDriveWithYazi {
  $networkDrives = net use | Where-Object { $_ -match "sshfs" } | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim("`t `r`n") }
  $selected = $networkDrives | fzf --tac --header="Connect - Open Network Drive"
  if ($selected -match '([A-Z]:)') {
    $selectedDrive = $matches[1]
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("y $selectedDrive")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }
}
Set-Alias -Name cn -Value Open-NetworkDriveWithYazi

function Get-SSHFSCommandsFromConfig {
  $sshConfig = Get-Content ~/.ssh/config
  $hosts = @()
  $currentHost = @{}

  foreach ($line in $sshConfig) {
    $line = $line.Trim()

    if ($line -match '^Host\s+(.+)') {
      if ($currentHost.Count -gt 0) {
        $hosts += $currentHost
      }
      $currentHost = @{
        Host = $matches[1]
        HostName = $null
        User = $null
      }
    }
    elseif ($line -match '^HostName\s+(.+)') {
      $currentHost.HostName = $matches[1]
    }
    elseif ($line -match '^User\s+(.+)') {
      $currentHost.User = $matches[1]
    }
  }

  if ($currentHost.Count -gt 0) {
    $hosts += $currentHost
  }

  $commands = @()
  foreach ($h in $hosts) {
    if ($h.HostName -and $h.User) {
      $commands += "net use \\sshfs.r\$($h.User)@$($h.HostName)"
    }
  }

  return $commands
}
function Mount-NetworkDrives {
  $selected = Get-SSHFSCommandsFromConfig | fzf --tac --header="Connect - Mount Network Drives"
  if ($selected) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selected)
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }
}
Set-Alias -Name cm -Value Mount-NetworkDrives

function Unmount-NetworkDrives {
  $networkDrives = net use | Where-Object { $_ -match "sshfs" } | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim("`t `r`n") }
  $selected = $networkDrives | fzf --tac --header="Connect - Unmount Network Drives"
  if ($selected -match '([A-Z]:)') {
    $selectedDrive = $matches[1]
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("net use $selectedDrive /DELETE")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
  }
}
Set-Alias -Name cu -Value Unmount-NetworkDrives

$global:WhichWBindings = @(
  @{
    Key = 's'
    Desc = '[S]SH'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Connect-SSH')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'y'
    Desc = '[Y]azi - Open a Network Drive'
    Action = { Open-NetworkDriveWithYazi }
  }
  @{
    Key = 'm'
    Desc = '[M]ount Network Drives'
    Action = { Mount-NetworkDrives }
  },
  @{
    Key = 'u'
    Desc = '[U]nmount Network Drives'
    Action = { Unmount-NetworkDrives }
  }
)

Set-PSReadLineKeyHandler -Key Ctrl+w -ScriptBlock {
  Show-WhichMenu -Bindings $global:WhichWBindings -Title 'Net[w]ork Connections'
}
