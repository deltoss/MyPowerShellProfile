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

# Adds devenv to the path, so you can use:
#   devenv MySolution.sln
#   devenv MySolution.sln /build "Debug|Any CPU"
#   devenv MySolution.sln /rebuild "Release|x64"
#   devenv MySolution.sln /clean
$vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -property installationPath
if ($vsPath) {
    $devenvPath = Join-Path $vsPath "Common7\IDE"

    $env:PATH += ";$devenvPath"

    Write-Host "Added to PATH: $devenvPath" -ForegroundColor Green
    Write-Host "Visual Studio version found: $(Split-Path (Split-Path $vsPath) -Leaf)" -ForegroundColor Green
} else {
    Write-Host "No Visual Studio installation found" -ForegroundColor Yellow
}
