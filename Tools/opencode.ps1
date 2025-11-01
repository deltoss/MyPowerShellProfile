Set-EnvVarIfNotSet -Name 'OPENCODE_PORT' -Value 4096

function Invoke-OpenCode {
    # Build filtered args array
    $filteredArgs = @()
    $portFound = $false

    # Loop through arguments
    for ($i = 0; $i -lt $args.Count; $i++) {
        $filteredArgs += $args[$i]

        # Check if this is the --port flag
        if ($args[$i] -eq '--port') {
            $portFound = $true
        }
    }

    # If no port was provided, add it
    if (-not $portFound) {
        $filteredArgs += '--port'
        $filteredArgs += $env:OPENCODE_PORT
    }

    & opencode.exe @filteredArgs
}

Set-Alias -Name opencode -Value Invoke-OpenCode
