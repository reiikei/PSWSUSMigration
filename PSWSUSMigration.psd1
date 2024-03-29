@{

RootModule = 'PSWSUSMigration.psm1'

ModuleVersion = '0.9.0'

GUID = '93d123fb-ada0-432b-9310-e6a67cee6cef'

Author = 'Rei Ikei'

CompanyName = 'Unknown'

Copyright = '(c) 2019 Rei Ikei. All rights reserved.'

Description = 'Powershell module to help WSUS (Windows Server Update Services) server migration. Support site: https://github.com/reiikei/PSWSUSMigration'

PowerShellVersion = '3.0'

FunctionsToExport = @('Export-WSUSOptions','Import-WSUSOptions','Export-WSUSComputerGroups','Import-WSUSComputerGroups','Export-WSUSUpdateApprovals','Import-WSUSUpdateApprovals')

CmdletsToExport = @()

VariablesToExport = '*'

AliasesToExport = @()

FileList = @('PSWSUSMigration.psm1','PSWSUSMigration.psd1')

PrivateData = @{

    PSData = @{
        LicenseUri = 'https://github.com/reiikei/PSWSUSMigration/blob/master/LICENSE'
        ProjectUri = 'https://github.com/reiikei/PSWSUSMigration/'
    }
}

}

