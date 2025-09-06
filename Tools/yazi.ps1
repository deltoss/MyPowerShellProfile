# Configure Yazi to open files correctly on Windows.
# See:
#   https://yazi-rs.github.io/docs/installation#windows
$env:YAZI_FILE_ONE = "C:\Program Files\Git\usr\bin\file.exe"
$env:YAZI_CONFIG_HOME="$env:XDG_CONFIG_HOME/yazi"

# Yazi File Manager
# See:
#   https://yazi-rs.github.io/docs/quick-start#shell-wrapper
function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}
