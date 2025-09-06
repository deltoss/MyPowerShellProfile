function Set-EnvVarIfNotSet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if (-not (Get-Item "env:$Name" -ErrorAction SilentlyContinue)) {
        Set-Item -Path "env:$Name" -Value $Value
        [System.Environment]::SetEnvironmentVariable($Name, $Value, 'User')
        Write-Host "Set $Name to: $Value" -ForegroundColor Green
    }
}

Set-EnvVarIfNotSet -Name 'XDG_CONFIG_HOME' -Value "$env:USERPROFILE/.config"
Set-EnvVarIfNotSet -Name 'EDITOR' -Value "nvim"

