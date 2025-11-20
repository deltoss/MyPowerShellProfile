# Configure Yazi to open files correctly on Windows.
# See:
#   https://yazi-rs.github.io/docs/installation#windows
$env:YAZI_FILE_ONE = "C:\Program Files\Git\usr\bin\file.exe"

Set-EnvVarIfNotSet -Name 'YAZI_CONFIG_HOME' -Value "$env:XDG_CONFIG_HOME/yazi"

# Yazi File Manager
# Based on:
#   https://yazi-rs.github.io/docs/quick-start#shell-wrapper
function y
{
  $tmp = (New-TemporaryFile).FullName
  yazi $args --cwd-file="$tmp"
  $cwd = Get-Content -Path $tmp -Encoding UTF8
  if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path)
  {
    Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
  }
  Remove-Item -Path $tmp
}

function Get-PathWithYazi
{
  $tmp = (New-TemporaryFile).FullName
  yazi $args --cwd-file="$tmp"
  $cwd = Get-Content -Path $tmp -Encoding UTF8
  Remove-Item -Path $tmp
  if (-not [String]::IsNullOrEmpty($cwd))
  {
    return (Resolve-Path -LiteralPath $cwd).Path
  }
  return $null
}