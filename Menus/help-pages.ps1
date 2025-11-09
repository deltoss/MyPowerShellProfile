function Search-Tldr {
  $selected = tldr --list | fzf --prompt="🔧 Select a CLI tool > " --height=20 --border --preview-window=wrap --preview="echo {}" --header="Use ↑↓ to navigate, Enter to select, Esc to cancel"

  & tldr $selected
}

$global:WhichPBindings = @(
  @{
    Key = 'r'
    Desc = 'Get [R]andom Favorite CLI Tip'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Get-RandomFavoriteCli')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 't'
    Desc = 'Search Favorite CLI [T]ools'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Search-FavoriteCliTools')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'T'
    Desc = 'Search [T]ldr'
    Action = {
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Search-Tldr')
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  }
)

Set-PSReadLineKeyHandler -Key Ctrl+p -ScriptBlock {
  Show-WhichMenu -Bindings $global:WhichPBindings -Title 'Help [P]ages'
}
