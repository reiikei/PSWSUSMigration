Function Export-WSUSComputerGroups {
    <#  
    .SYNOPSIS  
        Export WSUS computer group infromation to a XML file.

    .DESCRIPTION
        Export WSUS computer group infromation to a XML file.

    .NOTES  
        Name: Export-WSUSComputerGroups
        Author: Rei Ikei 

    .EXAMPLE
        Export-WSUSComputerGroups -XmlPath C:\WSUSOptions.xml
        Export-WSUSComputerGroups -XmlPath C:\WSUSOptions.xml -IncludeComputerMembership
    #>

    Param (
        [parameter(mandatory=$true)][string]$XmlPath,
        [switch]$IncludeComputerMembership
    )

    Process {
        Write-Host "Try to connect WSUS and get computer group infromation."

        Try {
            $WSUS = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
            $ComputerTargetGroups = $WSUS.GetComputerTargetGroups()
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "Connected WSUS and get computer group infromation successfully."

        $ExportComputerTargetGroups = @()

        foreach ($ComputerTargetGroup in $ComputerTargetGroups) {
            Try {
                $ParentComputerTargetGroupName = ($ComputerTargetGroup.GetParentTargetGroup()).Name
            } Catch {
                $ParentComputerTargetGroupName = $null
            }
            
            if ($IncludeComputerMembership -eq $true) {
                $ComputerTargetName = $ComputerTargetGroup.GetComputerTargets() | Select-Object FullDomainName
                $ExportComputerTargetGroups += New-Object PSObject -Property @{ComputerTargetGroupName=$ComputerTargetGroup.Name; ParentComputerTargetGroupName=$ParentComputerTargetGroupName; ComputerTargetName=$ComputerTargetName}
            } else {
                $ExportComputerTargetGroups += New-Object PSObject -Property @{ComputerTargetGroupName=$ComputerTargetGroup.Name; ParentComputerTargetGroupName=$ParentComputerTargetGroupName}
            }
        }
    
        Write-Host "Try to export WSUS computer group infromation to $XmlPath."

        Try {
            $ExportComputerTargetGroups | Export-Clixml -Path $XmlPath -Encoding unicode
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "Exported successfully WSUS computer group infromation to $XmlPath."
    }
}