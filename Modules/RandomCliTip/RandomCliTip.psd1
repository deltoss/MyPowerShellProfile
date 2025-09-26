@{
    RootModule = 'RandomCliTip.psm1'
    ModuleVersion = '1.0.0'

    GUID = 'e8f697ba-6912-41e9-8f53-3e013f5d4b42'
    Author = 'Deltoss'
    CompanyName = 'Deltoss'
    Copyright = '(c) 2025. All rights reserved.'

    Description = 'Get Random CLI Tips'
    PowerShellVersion = '7.0'

    RequiredModules = @('PSReadLine')

    FunctionsToExport = @('Get-RandomFavoriteCli', 'Search-Tldr', 'Search-FavoriteCliTools', 'Search-FavoriteCliCommands')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
