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

    $host.ui.Write($prompt)
  }
}
