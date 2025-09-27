@{
    RootModule = 'WhichMenu.psm1'
    ModuleVersion = '1.0.0'

    GUID = 'ee10a107-abdc-48c2-a893-4707dcffc459'
    Author = 'Deltoss'
    CompanyName = 'Deltoss'
    Copyright = '(c) 2025. All rights reserved.'

    Description = 'Interactive menu system for PowerShell command or script selection'
    PowerShellVersion = '7.0'

    RequiredModules = @('PSReadLine')

    FunctionsToExport = @('Show-WhichMenu', 'ConvertFrom-VimKeyBinding', 'Set-KeyBinding', 'Set-VimKeyBinding', 'Get-LeaderKey', 'Set-LeaderKey')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
