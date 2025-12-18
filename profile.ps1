$scriptDir = $PSScriptRoot

Import-Module "$scriptDir/Modules/WhichMenu"
Import-Module "$scriptDir/Modules/RandomCliTip"

. "$scriptDir/environments.ps1"

Get-ChildItem -Path "$scriptDir/Tools/*.ps1" | ForEach-Object { . $_.FullName }

Get-ChildItem -Path "$scriptDir/Menus/*.ps1" | ForEach-Object { . $_.FullName }