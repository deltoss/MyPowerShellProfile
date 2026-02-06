$scriptDir = $PSScriptRoot

Import-Module "$scriptDir/Modules/WhichMenu"
Import-Module "$scriptDir/Modules/RandomCliTip"

Get-ChildItem -Path "$scriptDir/Tools/*.ps1" | ForEach-Object { . $_.FullName }

Get-ChildItem -Path "$scriptDir/Menus/*.ps1" | ForEach-Object { . $_.FullName }