$global:WhichDBindings = @(
  @{
    Key = 'i'
    Desc = 'New [I]tem'
    Action = { New-DotNetItem }
  },
  @{
    Key = 'p'
    Desc = 'New [P]roject'
    Action = {
      $command = Get-NewDotNetProjectCommand
      if ($command) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
      }
    }
  }
)

Set-PSReadLineKeyHandler -Key Ctrl+d -ScriptBlock {
  Show-WhichMenu -Bindings $global:WhichDBindings -Title '[D]otnet'
}
