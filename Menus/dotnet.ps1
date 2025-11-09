$global:WhichNBindings = @(
  @{
    Key = 'n'
    Desc = '.[N]ET Command'
    Action = {
      $selection = Get-DotNetCommand
      if ($selection) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection.cmd)
      }
    }
  },
  @{
    Key = 'c'
    Desc = '.NET [C]ommand'
    Action = {
      $selection = Get-DotNetCommand
      if ($selection) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection.cmd)
      }
    }
  },
  @{
    Key = 'i'
    Desc = 'New [I]tem'
    Action = { New-DotNetItem }
  },
  @{
    Key = 'p'
    Desc = 'New [P]roject'
    Action = {
      $selection = Get-NewDotNetProjectCommand
      if ($selection) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($selection)
      }
    }
  }
)

Set-PSReadLineKeyHandler -Key Ctrl+n -ScriptBlock {
  Show-WhichMenu -Bindings $global:WhichNBindings -Title '.[N]et'
}
