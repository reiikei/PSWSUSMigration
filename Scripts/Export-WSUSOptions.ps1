Function Export-WSUSOptions {
    <#  
    .SYNOPSIS  
        Export WSUS options that can be set from WSUS administration console to a XML file.

    .DESCRIPTION
        Export WSUS options that can be set from WSUS administration console to a XML file.

    .NOTES  
        Name: Export-WSUSOptions
        Author: Rei Ikei 

    .EXAMPLE
        Export-WSUSOptions -XmlPath C:\WSUSOptions.xml
    #>

    Param (
        [parameter(mandatory=$true)][string]$XmlPath
    )

    Process {
        Write-Host "Try to connect WSUS and get options."
        
        Try {
            $WSUS = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
            $WSUSConf = $WSUS.GetConfiguration()
            $WSUSSubs = $WSUS.GetSubscription()
            $WSUSEmailConf = $WSUS.GetEmailNotificationConfiguration()
            $InstallApprovalRules = $WSUS.GetInstallApprovalRules()
        } Catch {
            Write-Error "$error[0]"
            Return
        } 

        Write-Host "Connected WSUS and get options successfully."

        # Get Install Approval Rules.
        $IARs = @()

        foreach ($IAR in $InstallApprovalRules) {
            $IARtmp = New-Object PSCustomObject
            $IARtmp | Add-Member -NotePropertyMembers @{
                Name = $IAR.Name
                Enabled = $IAR.Enabled
                Classifications = $IAR.GetUpdateClassifications() | Select Id, Title
                Categories = $IAR.GetCategories() | Select Id, Title
                ComputerTargetGroups = $IAR.GetComputerTargetGroups() | Select Name
                Deadline = $IAR.Deadline
            }
            $IARs += $IARtmp 
        }

        # Get WSUS options.
        $OptionsArray = (
            # 1. Update Source and Proxy Server 
            [PSCustomObject]@{    
                # 1-1. Update Source tab
                "SyncFromMicrosoftUpdate" = $WSUSConf.SyncFromMicrosoftUpdate
                "UpstreamWsusServerName" = $WSUSConf.UpstreamWsusServerName
                "UpstreamWsusServerPortNumber" = $WSUSConf.UpstreamWsusServerPortNumber
                "UpstreamWsusServerUseSsl" = $WSUSConf.UpstreamWsusServerUseSsl
                "IsReplicaServer" = $WSUSConf.IsReplicaServer
                # 1-2. Proxy Server tab
                "UseProxy" = $WSUSConf.UseProxy
                "ProxyName" = $WSUSConf.ProxyName
                "ProxyServerPort" = $WSUSConf.ProxyServerPort
                "AnonymousProxyAccess" = $WSUSConf.AnonymousProxyAccess
                "ProxyUserName" = $WSUSConf.ProxyUserName
                "ProxyUserDomain" = $WSUSConf.ProxyUserDomain 
                "HasProxyPassword" = $WSUSConf.HasProxyPassword
                "AllowProxyCredentialsOverNonSsl" = $WSUSConf.AllowProxyCredentialsOverNonSsl
            },
            # 2. Products and Classifications  
            [PSCustomObject]@{
                # 2-1. Products tab
                "Products" = $WSUSSubs.GetUpdateCategories() | Select Id, Title
                # 2-2. Classifications tab
                "Classifications" = $WSUSSubs.GetUpdateClassifications() | Select Id, Title
            },
            # 3 Update Files and Languages
            [PSCustomObject]@{
                # 3-1. Updates Files tab
                "HostBinariesOnMicrosoftUpdate" = $WSUSConf.HostBinariesOnMicrosoftUpdate
                "DownloadUpdateBinariesAsNeeded" = $WSUSConf.DownloadUpdateBinariesAsNeeded
                "DownloadExpressPackages" = $WSUSConf.DownloadExpressPackages
                "GetContentFromMU" = $WSUSConf.GetContentFromMU
                # 3-2. Languages tab
                "AllUpdateLanguagesEnabled" = $WSUSConf.AllUpdateLanguagesEnabled
                "EnabledUpdateLanguages" = $WSUSConf.GetEnabledUpdateLanguages()
            },
            # 4. Synchronization Schedule
            [PSCustomObject]@{
                "SynchronizeAutomatically" = $WSUSSubs.SynchronizeAutomatically
                "SynchronizeAutomaticallyTimeOfDay" = $WSUSSubs.SynchronizeAutomaticallyTimeOfDay
                "NumberOfSynchronizationsPerDay" = $WSUSSubs.NumberOfSynchronizationsPerDay
            },
            # 5. Automatic Approvals
            [PSCustomObject]@{
                # 5-1 Update Rules tab
                "UpdateRules" = $IARs
                # 5-2 Advanced tab
                "AutoApproveWsusInfrastructureUpdates" = $WSUSConf.AutoApproveWsusInfrastructureUpdates
                "AutoRefreshUpdateApprovals" = $WSUSConf.AutoRefreshUpdateApprovals
                "AutoRefreshUpdateApprovalsDeclineExpired" = $WSUSConf.AutoRefreshUpdateApprovalsDeclineExpired
            },
            # 6. Computer
            [PSCustomObject]@{
                "TargetingMode" = $WSUSConf.TargetingMode
            },
            # 7. Reporting Rollup
            [PSCustomObject]@{
                "DoDetailedRollup" = $WSUSConf.DoDetailedRollup
            },
            # 8. E-mail Notifications
            [PSCustomObject]@{
                # 8-1 General tab
                "SendSyncNotification" = $WSUSEmailConf.SendSyncNotification
                "SyncNotificationRecipients" = $WSUSEmailConf.SyncNotificationRecipients
                "SendStatusNotification" = $WSUSEmailConf.SendStatusNotification
                "StatusNotificationFrequency" = $WSUSEmailConf.StatusNotificationFrequency
                "StatusNotificationTimeOfDay" = $WSUSEmailConf.StatusNotificationTimeOfDay
                "StatusNotificationRecipients" = $WSUSEmailConf.StatusNotificationRecipients
                "EmailLanguage" = $WSUSEmailConf.EmailLanguage
                # 8-2 E-Mail Server tab
                "SmtpHostName" = $WSUSEmailConf.SmtpHostName
                "SmtpPort" = $WSUSEmailConf.SmtpPort
                "SenderDisplayName" = $WSUSEmailConf.SenderDisplayName
                "SenderEmailAddress" = $WSUSEmailConf.SenderEmailAddress
                "SmtpServerRequiresAuthentication" = $WSUSEmailConf.SmtpServerRequiresAuthentication
                "SmtpUserName" = $WSUSEmailConf.SmtpUserName
                "HasSmtpUserPassword" = $WSUSEmailConf.HasSmtpUserPassword
            },
            # 9. Microsoft Update Improvement Program
            [PSCustomObject]@{
                "MURollupOptin" = $WSUSConf.MURollupOptin
            }
        )

        Write-Host "Try to export WSUS options to $XmlPath."

        Try {
            $OptionsArray | Export-Clixml -Path $XmlPath -Encoding unicode
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "Exported successfully WSUS options to $XmlPath."
    }
}
