Invoke-Expression (&starship init powershell)

# Hook into Starship so that when spawning Wezterm panes, it'd automatically
# navigate to the current working directory that Powershell was in.
# See:
#   https://wezterm.org/shell-integration.html#osc-7-on-windows-with-powershell-with-starship
$prompt = ""
function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"

        # See:
        #   https://www.reddit.com/r/wezterm/comments/1fztaj8/comment/lr97ry9/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
        $title = GetCurrentDir($current_location)
        $title = "📂 " + $title
        wezterm cli set-tab-title $title;
    }
    $host.ui.Write($prompt)
}

function GetCurrentDir {
    param (
      [string]$path = ""
    )
    if ($path -eq "") {
      $path = Get-Location
    }

    if ($path -eq "$env:USERPROFILE") {
      return "~"
    }

    return Split-Path ($path) -Leaf 
}
