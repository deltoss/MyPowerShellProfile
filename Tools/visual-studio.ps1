# Sample usage:
#   devenv MySolution.sln
#   devenv MySolution.sln /build "Debug|Any CPU"
#   devenv MySolution.sln /rebuild "Release|x64"
#   devenv MySolution.sln /clean
function devenv
{
  $vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -prerelease -property installationPath
  if ($vsPath)
  {
    Write-Debug "Visual Studio version found: $(Split-Path (Split-Path $vsPath) -Leaf)"
    $devenvPath = Join-Path $vsPath "Common7\IDE\devenv.exe"
    Write-Debug "Visual Studio devenv.exe found: $devenvPath"
    & $devenvPath @args
  } else
  {
    Write-Error "No Visual Studio installation found"
  }
}