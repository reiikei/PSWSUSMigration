Function Import-WSUSUpdateApprovals {
    <#  
    .SYNOPSIS  
        Import WSUS update approval infomation from a XML file.

    .DESCRIPTION
        Import WSUS update approval infomation from a XML file.

    .NOTES  
        Name: Import-WSUSUpdateApprovals
        Author: Rei Ikei 

    .EXAMPLE
        Import-WSUSUpdateApprovals -XmlPath C:\WSUSUpdateApprovals.xml -All
        Import-WSUSUpdateApprovals -XmlPath C:\WSUSUpdateApprovals.xml -TargetComputerGroup "All Computers"
    #>
    
    Param (
        [parameter(mandatory=$true)][string]$XmlPath,
        [switch]$All,
        [string]$TargetComputerGroupName
    )

    Process {
        Try {        
            $ImportUpdateApprovals = Import-Clixml $XmlPath
        } Catch {
            Write-Error "$error[0]"
            Return
        }
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

    foreach ($ImportUpdateApproval in $ImportUpdateApprovals) {
        $UpdateRevisionId = New-Object Microsoft.UpdateServices.Administration.UpdateRevisionId
        $UpdateRevisionId.UpdateId = $ImportUpdateApproval.Id.UpdateId
        $UpdateRevisionId.RevisionNumber = $ImportUpdateApproval.Id.RevisionNumber
        $Update = $WSUS.GetUpdate($UpdateRevisionId)

        if ($ImportUpdateApproval.Action -eq "Decline") {
            $Update.Decline()
        } else {
            if ($ImportUpdateApproval.Action.Value -eq "Install") {
                $ApprovalAction = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Install
            } elseif ($ImportUpdateApproval.Action.Value -eq "NotApproved") {
                $ApprovalAction = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::NotApproved
            } elseif  ($ImportUpdateApproval.Action.Value -eq "Uninstall") {
                $ApprovalAction = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Uninstall
            }

            $ComputerTargetGroupName = $ImportUpdateApproval.ComputerTargetGroup
            $ComputerTargetGroup = $ComputerTargetGroups | Where-Object {$_.Name -eq $ComputerTargetGroupName}
            if ($null -eq $ComputerTargetGroup) {
                Write-Error "$ComputerTargetGroupName is not existed on this WSUS server."
            }

             (Get-Date "9999-12-31 23:59:59")

        }
    }
}