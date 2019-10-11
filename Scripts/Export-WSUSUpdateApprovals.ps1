# Internal function to get updates approval information for exporting.
Function Get-UpdatesApprovals ($Updates, $ComputerTargetGroups, $UpdateInfo) {
    $ExportApprovals = @()

    foreach ($Update in $Updates) {
        Write-Progress -activity "Getting $UpdateInfo updates approval information" -PercentComplete ($pCounter++ * 100 /$Updates.Count) 
        $Approvals = $Update.GetUpdateApprovals()

        if ($Update.IsDeclined -eq $true) {
            $Title = $Update.Title
            $Id = $Update.Id
            $Action = "Decline"
            $Deadline = $null
            $ComputerTargetGroup = $null
            $ExportApprovals += New-Object PSObject -Property @{Title=$Title; ComputerTargetGroup=$ComputerTargetGroup; Id=$Id; Action=$Action; Deadline=$Deadline}    
        } elseif ($Approvals.Count -ne 0) {
            foreach ($Approval in $Approvals) {
                $Title = $Update.Title
                $Id = $Approval.UpdateId
                $Action = $Approval.Action
                $Deadline = $Approval.Deadline
                $ComputerTargetGroup = ($ComputerTargetGroups | Where-Object {$_.Id -eq $Approval.ComputerTargetGroupId}).Name
                $ExportApprovals += New-Object PSObject -Property @{Title=$Title; ComputerTargetGroup=$ComputerTargetGroup; Id=$Id; Action=$Action; Deadline=$Deadline}
            }
        }
    }
    return $ExportApprovals
}

Function Export-WSUSUpdateApprovals {
    <#  
    .SYNOPSIS  
        Export WSUS update approval infomation to a XML file.

    .DESCRIPTION
        Export WSUS update approval infomation to a XML file.

    .NOTES  
        Name: Export-WSUSUpdateApprovals
        Author: Rei Ikei 

    .EXAMPLE
        Export-WSUSUpdateApprovals -XmlPath C:\WSUSUpdateApprovals.xml -All
        Export-WSUSUpdateApprovals -XmlPath C:\WSUSUpdateApprovals.xml -TargetComputerGroup "All Computers"
    #>

    Param (
        [parameter(mandatory=$true)][string]$XmlPath,
        [switch]$All,
        [string]$TargetComputerGroupName
    )

    Process {
        if (($All -eq $false) -And ($TargetComputerGroupName -eq "")) {
            Write-Error "You must use -TargetComputerGroupName or -All option."
            return
        } elseif (($All -eq $true) -And ($TargetComputerGroupName -ne "")) {
            Write-Error "You cannot use -TargetComputerGroupName and -All options at same time."
            return
        }

        Write-Host "Try to connect WSUS."
        
        Try {
            $WSUS = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
            $ComputerTargetGroups = $WSUS.GetComputerTargetGroups()
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "Connected WSUS successfully."

        $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope

        if ($TargetComputerGroupName -ne "") {
            $ComputerTargetGroup = $ComputerTargetGroups | Where-Object {$_.Name -eq $TargetComputerGroupName}
            if ($null -ne $ComputerTargetGroup) {
                $UpdateScope.ApprovedComputerTargetGroups.AddRange($ComputerTargetGroup)
            } else {
                Write-Error "$TargetComputerGroupName is not existed on this WSUS server."
                return
            }
        }

        $ExportApprovals = @()
        
        Write-Host "Try to get Approved updates from WSUS."

        Try {
            $UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::HasStaleUpdateApprovals, [Microsoft.UpdateServices.Administration.ApprovedStates]::LatestRevisionApproved;
            $Updates = $WSUS.GetUpdates($UpdateScope)
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "Got Approved updates from WSUS successfully."

        $ExportApprovals += Get-UpdatesApprovals $Updates $ComputerTargetGroups "Approved"
        
        Write-Host "Try to get Not Approved updates from WSUS."

        Try {
            $UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::NotApproved
            $Updates = $WSUS.GetUpdates($UpdateScope)
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "Got Not Approved updates from WSUS successfully."

        $ExportApprovals += Get-UpdatesApprovals $Updates $ComputerTargetGroups "Not Approved"

        if ($All -eq $true) {
            Write-Host "Try to get Declined updates from WSUS."

            Try {
                $UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::Declined
                $Updates = $WSUS.GetUpdates($UpdateScope)
            } Catch {
                Write-Error "$error[0]"
                Return
            }

            Write-Host "Got Declined updates from WSUS successfully."

            $ExportApprovals += Get-UpdatesApprovals $Updates $ComputerTargetGroups "Declined"
        }
            
        Write-Host "Try to export WSUS update approval infromation to $XmlPath."

        Try {
            $ExportApprovals | Export-Clixml -Path $XmlPath -Encoding unicode
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "Exported successfully WSUS update approval infromation to $XmlPath."
    }
}