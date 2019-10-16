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
        if (($All -eq $false) -And ($TargetComputerGroupName -eq "")) {
            Write-Error "You must use -TargetComputerGroupName or -All option."
            return
        } elseif (($All -eq $true) -And ($TargetComputerGroupName -ne "")) {
            Write-Error "You cannot use -TargetComputerGroupName and -All options at same time."
            return
        }

        Try {        
            $ImportUpdateApprovals = Import-Clixml $XmlPath
        } Catch {
            Write-Error "$error[0]"
            Return
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

        $ComputerTargetGroup = $ComputerTargetGroups | Where-Object {$_.Name -eq $TargetComputerGroupName}
        if (($All -eq $false) -And ($null -eq $ComputerTargetGroup)) {
            Write-Error "$TargetComputerGroupName is not existed on this WSUS server."
            Return
        }

        Write-Host "Start to import update approval information."

        foreach ($ImportUpdateApproval in $ImportUpdateApprovals) {
            if (($All -eq $false) -And ($ImportUpdateApproval.Action -eq "Decline")) {
            }
            else {
                $UpdateRevisionId = New-Object Microsoft.UpdateServices.Administration.UpdateRevisionId
                $UpdateRevisionId.UpdateId = $ImportUpdateApproval.Id.UpdateId
                $UpdateRevisionId.RevisionNumber = $ImportUpdateApproval.Id.RevisionNumber
                $UpdateTitle = $ImportUpdateApproval.Title
        
                Try {
                    $Update = $WSUS.GetUpdate($UpdateRevisionId)
                } Catch {
                    Write-Warning "$UpdateTitle is not existed on this WSUS Server."
                }

                if ($null -ne $Update) { 
                    if ($ImportUpdateApproval.Action -eq "Decline") {
                        $Update.Decline()
                        Write-Host "$UpdateTitle is Declined."
                    } else {
                        if ($ImportUpdateApproval.Action.Value -eq "Install") {
                            $ApprovalAction = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Install
                        } elseif ($ImportUpdateApproval.Action.Value -eq "NotApproved") {
                            $ApprovalAction = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::NotApproved
                        } elseif  ($ImportUpdateApproval.Action.Value -eq "Uninstall") {
                            $ApprovalAction = [Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Uninstall
                        }

                        if ($All -eq $true) {
                            $ComputerTargetGroupName = $ImportUpdateApproval.ComputerTargetGroup
                            $ComputerTargetGroup = $ComputerTargetGroups | Where-Object {$_.Name -eq $ComputerTargetGroupName}
                            if ($null -eq $ComputerTargetGroup) {
                                Write-Error "$ComputerTargetGroupName is not existed on this WSUS server."
                            }
                        } else {
                            $ComputerTargetGroupName = $TargetComputerGroupName
                        }
                        
                        if ($null -eq $ComputerTargetGroup) {
                        } else {
                            # Deadline is not need to set if it is deafault values ([DateTime]3155378975999999999).
                            if ($ImportUpdateApproval.Deadline -eq ([DateTime]3155378975999999999)) {
                                $Update.Approve($ApprovalAction, $ComputerTargetGroup) | Out-Null
                                Write-Host "$UpdateTitle is $ApprovalAction to $ComputerTargetGroupName."
                            } else {
                                $Deadline = $ImportUpdateApproval.Deadline
                                $Update.Approve($ApprovalAction, $ComputerTargetGroup, $Deadline) | Out-Null
                                Write-Host "$UpdateTitle is $ApprovalAction to $ComputerTargetGroupName and set deadline as $Deadline."
                            }
                        }
                    }
                }
            }
        }

        Write-Host "Imported update approval information."
    }
}