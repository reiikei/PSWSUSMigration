Function Get-UpdatesApprovals ($Updates, $ComputerTargetGroups) {
    $ExportApprovals = @()
    foreach ($Update in $Updates) {
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
        Export-WSUSUpdateApprovals -XmlPath C:\WSUSUpdateApprovals.xml
    #>

    Param (
        [parameter(mandatory=$true)][string]$XmlPath
    )

    Process {
        Write-Host "Try to connect WSUS."
        
        Try {
            $WSUS = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
            $ComputerTargetGroups = $WSUS.GetComputerTargetGroups() | Select-Object Id, Name
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        $UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope

        $ExportApprovals = @()
        
        Try {
            $UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::HasStaleUpdateApprovals, [Microsoft.UpdateServices.Administration.ApprovedStates]::LatestRevisionApproved;
            $Updates = $WSUS.GetUpdates($UpdateScope)
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        $ExportApprovals += Get-UpdatesApprovals $Updates $ComputerTargetGroups
        
        Try {
            $UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::NotApproved
            $Updates = $WSUS.GetUpdates($UpdateScope)
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        $ExportApprovals += Get-UpdatesApprovals $Updates $ComputerTargetGroups

        Try {
            $UpdateScope.ApprovedStates = [Microsoft.UpdateServices.Administration.ApprovedStates]::Declined
            $Updates = $WSUS.GetUpdates($UpdateScope)
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        $ExportApprovals += Get-UpdatesApprovals $Updates $ComputerTargetGroups
        
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