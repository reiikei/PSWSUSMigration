# What is PSWSUSMigration?
Powershell module to help WSUS (Windows Server Update Services) servers migration. WSUS Servers can be migrate using [this steps](https://technet.microsoft.com/library/hh852339.aspx). But [this steps](https://technet.microsoft.com/library/hh852339.aspx) migrates all data in the SUSDB which may have unnecessary old updates, and these old updates data cause problems sometime. Using PSWSUSMigration, you can migrate only necessary data such as WSUS options, computer groups, update approval information.

# Getting started
## Requirements 
- PowerShell 3.0 (or later)
- WSUS (Windows Server Update Services) installed environment

## Installing from PowerShell Gallery
1. Install PSWSUSMigration module from: https://www.powershellgallery.com/packages/?
```PowerShell
Install-Module -Name PSWSUSMigration
```

## Installing from zip file
Download the [ZIP file](https://github.com/reiikei/PSWSUSMigration/archive/stable.zip?) of the latest release and unpack it to one of the following locations:

- Current user: `C:\Users\<your.account>\Documents\WindowsPowerShell\Modules\PSWSUSMigration`
- All users: `C:\Program Files\WindowsPowerShell\Modules\PSWSUSMigration`

# Use PSWSUSMigration
## Discovering available commands
Get the full list of available cmdlets:
```PowerShell
Get-Command -Module PSWSUSMigration
```

## Example usage : Export-WSUSOptions & Import-WSUSOptions
Export WSUS options that can be set from WSUS administration console to a XML file.
```PowerShell
Export-WSUSOptions -XmlPath <XML file path to export>
```

Import WSUS options from a XML file exported by using "Export-WSUSOptions".
```PowerShell
Import-WSUSOptions -XmlPath <XML file path exported using Export-WSUSOptions>
```

## Example usage : Export-WSUSComputerGroups & Import-WSUSComputerGroups
## Example usage : Export-WSUSUpdateApprovals & Import-WSUSUpdateApprovals
