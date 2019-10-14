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
Export all WSUS options ([Update Source and Proxy Server], [Products and Classifications] and so on) that can be set from WSUS administration console to a XML file.
```PowerShell
Export-WSUSOptions -XmlPath <XML file path to export>
```
if above command is successfully completed, a XML file which contains WSUS options is exported to XMLPath.

Import WSUS options to other WSUS servers from a XML file exported by using "Export-WSUSOptions".
```PowerShell
Import-WSUSOptions -XmlPath <XML file path exported by using Export-WSUSOptions>
```

## Example usage : Export-WSUSComputerGroups & Import-WSUSComputerGroups
Export WSUS computer group infromation to a XML file.
```PowerShell
Export-WSUSComputerGroups -XmlPath <XML file path to export>
```
If you use -IncludeComputerMembership option, you can include computer membership information to a XML file.
```PowerShell
Export-WSUSComputerGroups -XmlPath <XML file path to export> -IncludeComputerMembership
```
if above commands are successfully completed, a XML file which contains WSUS computer group infromation is exported to XMLPath.

Import WSUS computer group infromation to other WSUS servers from a XML file. **Import-WSUSComputerGroups will delete currently exists computer groups on a WSUS server.**
```PowerShell
Import-WSUSComputerGroups -XmlPath <XML file path to export>
```

If you used -IncludeComputerMembership option when exporting, you can also import computer membership infomation using -IncludeComputerMembership option.
```PowerShell
Import-WSUSComputerGroups -XmlPath <XML file path to export> -IncludeComputerMembership
```

## Example usage : Export-WSUSUpdateApprovals & Import-WSUSUpdateApprovals
Export WSUS all update approval infomation to a XML file.
```PowerShell
Export-WSUSUpdateApprovals -XmlPath <XML file path to export> -All
```
If you use -TargetComputerGroup option, you can export update approval infomation of specifified group.
```PowerShell
Export-WSUSUpdateApprovals -XmlPath <XML file path to export> -TargetComputerGroup <Computer group name>
```
if above commands are successfully completed, a XML file which contains WSUS update approval infomation is exported to XMLPath.

Import WSUS all update approval infomation from a XML file.
```PowerShell
Import-WSUSUpdateApprovals -XmlPath <XML file path to export> -All
```
If you used -TargetComputerGroup option when exporting, you can also import update approval infomation to specifified group -TargetComputerGroup using option.
```PowerShell
Export-WSUSUpdateApprovals -XmlPath <XML file path to export> -TargetComputerGroup <Computer group name>
```
