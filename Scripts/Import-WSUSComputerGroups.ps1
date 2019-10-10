Function New-WSUSComputerGroupsRecursive($ImportComputerGroup, $ParentComputerGroup, $ImportComputerGroups, $WSUS) {
    $NewComputerTargetGroup = $WSUS.CreateComputerTargetGroup($ImportComputerGroup.ComputerTargetGroupName, $ParentComputerGroup)
    $ChildComputerTargetGroups = $ImportComputerGroups | Where-Object {$_.ParentComputerTargetGroupName -eq $NewComputerTargetGroup.Name}

    if ($null -ne $ChildComputerTargetGroups)
    {
        foreach ($ChildComputerTargetGroup in $ChildComputerTargetGroups) {
            New-WSUSComputerGroupsRecursive $ChildComputerTargetGroup $NewComputerTargetGroup $ImportComputerGroups $WSUS
        }
    }
}

Function Import-WSUSComputerGroups {
    <#  
    .SYNOPSIS  
        Import WSUS computer group infromation to a XML file.

    .DESCRIPTION
        Import WSUS computer group infromation to a XML file.

    .NOTES  
        Name: Import-WSUSComputerGroups
        Author: Rei Ikei 

    .EXAMPLE
        Import-WSUSComputerGroups -XmlPath C:\WSUSOptions.xml
        Import-WSUSComputerGroups -XmlPath C:\WSUSOptions.xml -IncludeComputerMembership
    #>

    Param (
        [parameter(mandatory=$true)][string]$XmlPath,
        [switch]$IncludeComputerMembership
    )

    Process {
        Write-Host "Try to load WSUS computer group infromation to import from $XmlPath."

        Try {        
            $ImportComputerGroups = Import-Clixml $XmlPath
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "loaded successfully WSUS computer group infromationfrom $XmlPath."
        Write-Host "Try to connect WSUS and get computer group infromation."

        Try {
            $WSUS = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
            $WSUSConf = $WSUS.GetConfiguration()
            $ComputerTargetGroups = $WSUS.GetComputerTargetGroups()
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "Connected WSUS and get computer group infromation successfully."

        if ($WSUSConf.IsReplicaServer -eq $true) { 
            Write-Error "On replica servers, you cannot create computer groups. You need to create computer groups on upstream servers"
            Return
        }
        
        if (($IncludeComputerMembership -eq $true) -And ($WSUSConf.TargetingMode -eq "Client")) { 
            Write-Error "You cannot change a computer membership because Computer Target Mode option is set as Client on this WSUS server."
            Return
        }

        # Delete current computer groups.
        $SystemComputerTargetGroup =  New-Object -TypeName Microsoft.UpdateServices.Administration.ComputerTargetGroupCollection

        foreach ($ComputerTargetGroup in $ComputerTargetGroups) {
            Try {
                $ComputerTargetGroup.Delete()
            } Catch {
                # All Computers & Unassinged Computers will not be able to delete.
                $SystemComputerTargetGroup += $ComputerTargetGroup
            }
        }

        # $SystemComputerTargetGroup will be 2 groups (All Computers & Unassinged Computers).
        if ($SystemComputerTargetGroup -ne 2){
            Write-Error "Failed to delete some computer groups. $SystemComputerTargetGroup"
        }

        Try {
            $AllComputersGroup = $SystemComputerTargetGroup[0].GetParentTargetGroup()
            $UnassingedComputersGroup = $SystemComputerTargetGroup[0]
        } Catch {
            $AllComputersGroup =  $SystemComputerTargetGroup[0]
            $UnassingedComputersGroup = $SystemComputerTargetGroup[1]
        }

        $ImportedAllComputersGroup = $ImportComputerGroups | Where-Object {$null -eq $_.ParentComputerTargetGroupName}

        foreach ($ImportComputerGroup in $ImportComputerGroups) {
            if (($ImportComputerGroup.ParentComputerTargetGroupName -eq $ImportedAllComputersGroup.ComputerTargetGroupName) -And ($UnassingedComputersGroup.Name -ne $ImportComputerGroup.ComputerTargetGroupName)) {
                    New-WSUSComputerGroupsRecursive $ImportComputerGroup $AllComputersGroup $ImportComputerGroups $WSUS
            }
        }
    }
}