Function Import-WSUSOptions {
    <#  
    .SYNOPSIS  
        Import WSUS options from a XML file exported by using "Export-WSUSOptions".

    .DESCRIPTION
        Import WSUS options from a XML file exported by using "Export-WSUSOptions".

    .NOTES  
        Name: Import-WSUSOptions
        Author: Rei Ikei 

    .EXAMPLE
        Import-WSUSOptions -XmlPath C:\WSUSOptions.xml
        Import-WSUSOptions -XmlPath C:\WSUSOptions.xml -ProxyPassword Passw0rd! -SmtpUserPassword Passw0rd!
    #>

    Param (
        [parameter(mandatory=$true)][string]$XmlPath,
        [string]$ProxyPassword,
        [string]$SmtpUserPassword
    )

    Process {
        Write-Host "Try to load WSUS options from $XmlPath."

        Try {        
            $ImportConf = Import-Clixml $XmlPath
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "loaded successfully WSUS options from $XmlPath."

        # Check whether Proxy password & Smtp user password are needed.
        if (($ImportConf[0].HasProxyPassword -eq $true) -And ($ProxyPassword -eq "")) {
            Write-Error "Need to input -ProxyPassword option."
            Return
        }

        if (($ImportConf[7].HasSmtpUserPassword -eq $true) -And ($SmtpUserPassword -eq "")) {
            Write-Error "Need to input -SmtpUserPassword option."
            Return
        }

        Write-Host "Try to connect WSUS and get options."
        
        Try {
            $WSUS = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer()
            $WSUSConf = $WSUS.GetConfiguration()
            $WSUSSubs = $WSUS.GetSubscription()
            $OldInstallApprovalRules = $WSUS.GetInstallApprovalRules()
            $ExistComputerTargetGroups = $WSUS.GetComputerTargetGroups()
            $WSUSEmailConf = $WSUS.GetEmailNotificationConfiguration()
        } Catch {
            Write-Error "$error[0]"
            Return
        } 

        Write-Host "Connected WSUS and get options successfully."
        Write-Host "Try to set WSUS configurations."

        $WSUSConf.SyncFromMicrosoftUpdate = $ImportConf[0].SyncFromMicrosoftUpdate
        $WSUSConf.UpstreamWsusServerName = $ImportConf[0].UpstreamWsusServerName
        $WSUSConf.UpstreamWsusServerPortNumber = $ImportConf[0].UpstreamWsusServerPortNumber
        $WSUSConf.UpstreamWsusServerUseSsl = $ImportConf[0].UpstreamWsusServerUseSsl
        $WSUSConf.IsReplicaServer = $ImportConf[0].IsReplicaServer
        $WSUSConf.UseProxy = $ImportConf[0].UseProxy
        $WSUSConf.ProxyName = $ImportConf[0].ProxyName
        $WSUSConf.ProxyServerPort = $ImportConf[0].ProxyServerPort
        $WSUSConf.AnonymousProxyAccess = $ImportConf[0].AnonymousProxyAccess
        $WSUSConf.ProxyUserName = $ImportConf[0].ProxyUserName
        $WSUSConf.ProxyUserDomain = $ImportConf[0].ProxyUserDomain
        $WSUSConf.AllowProxyCredentialsOverNonSsl = $ImportConf[0].AllowProxyCredentialsOverNonSsl

        $WSUSConf.HostBinariesOnMicrosoftUpdate = $ImportConf[2].HostBinariesOnMicrosoftUpdate
        $WSUSConf.DownloadUpdateBinariesAsNeeded = $ImportConf[2].DownloadUpdateBinariesAsNeeded
        $WSUSConf.DownloadExpressPackages = $ImportConf[2].DownloadExpressPackages
        $WSUSConf.GetContentFromMU = $ImportConf[2].GetContentFromMU
        $WSUSConf.AllUpdateLanguagesEnabled = $ImportConf[2].AllUpdateLanguagesEnabled

        $WSUSConf.AutoApproveWsusInfrastructureUpdates = $ImportConf[4].AutoApproveWsusInfrastructureUpdates
        $WSUSConf.AutoRefreshUpdateApprovals = $ImportConf[4].AutoRefreshUpdateApprovals
        $WSUSConf.AutoRefreshUpdateApprovalsDeclineExpired = $ImportConf[4].AutoRefreshUpdateApprovalsDeclineExpired

        $WSUSConf.TargetingMode = $ImportConf[5].TargetingMode

        $WSUSConf.DoDetailedRollup = $ImportConf[6].DoDetailedRollup

        $WSUSConf.MURollupOptin = $ImportConf[8].MURollupOptin

        # Save WSUS configurations.
        Try {
            if ($ImportConf[0].HasProxyPassword -eq $true) {
                $WSUSConf.SetProxyPassword($ProxyPassword)
            }

            if ($ImportConf[2].AllUpdateLanguagesEnabled -eq $false) {
                $WSUSConf.SetEnabledUpdateLanguages($ImportConf[2].EnabledUpdateLanguages)
            }

            $WSUSConf.Save()
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "Set WSUS Configurations successfully."
        Write-Host "Try to set WSUS subscriptions."

        # Get Categories & Classifications to sychronize.
        $SyncCategories = New-Object -TypeName Microsoft.UpdateServices.Administration.UpdateCategoryCollection

        foreach ($Product in $ImportConf[1].Products) {
            Try {
                $SyncCategories.AddRange($WSUS.GetUpdateCategory($Product.Id))
            } Catch {
                Write-Warning "$Product may not be existed on this WSUS server. If you have not done WSUS synchronization, it may be added by doing WSUS synchronization."
                Write-Verbose "$error[0]"
            }
        }

        $SyncClassifications = New-Object -TypeName Microsoft.UpdateServices.Administration.UpdateClassificationCollection

        foreach ($Classification in $ImportConf[1].Classifications) {
            Try {
                $SyncClassifications.AddRange($WSUS.GetUpdateClassification($Classification.Id))
            } Catch {
                Write-Warning "$Classification may not be existed on this WSUS server. If you have not done WSUS synchronization, it may be added by doing WSUS synchronization."
                Write-Verbose "$error[0]"
            }
        }

        # Set a WSUS Subscription.
        Try {
            $WSUSSubs.SetUpdateCategories($SyncCategories)
            $WSUSSubs.SetUpdateClassifications($SyncClassifications)
            $WSUSSubs.SynchronizeAutomatically = $ImportConf[3].SynchronizeAutomatically
            $WSUSSubs.SynchronizeAutomaticallyTimeOfDay = $ImportConf[3].SynchronizeAutomaticallyTimeOfDay
            $WSUSSubs.NumberOfSynchronizationsPerDay = $ImportConf[3].NumberOfSynchronizationsPerDay
            $WSUSSubs.Save()
        } Catch {
            Write-Error "$error[0]"
            Return
        }

        Write-Host "Set WSUS Subscriptions successfully."
        Write-Host "Try to create Update Rules."

        # Delete current Install Approval Rules 

        foreach ($OldInstallApprovalRule in $OldInstallApprovalRules) {
            $WSUS.DeleteInstallApprovalRule($OldInstallApprovalRule.Id)
        }

        # Create new Install Approval Rules from an imported XML
        foreach ($NewInstallApprovalRule in $ImportConf[4].UpdateRules) {
            $NewInstallApprovalRuleName = $NewInstallApprovalRule.Name
            Write-Host "Try to create $NewInstallApprovalRuleName."

            $IARCategories = New-Object -TypeName Microsoft.UpdateServices.Administration.UpdateCategoryCollection

            foreach ($Product in $NewInstallApprovalRule.Categories) {
                if ($Product.Id -ne $null) {
                    Try {
                        $IARCategories.AddRange($WSUS.GetUpdateCategory($Product.Id))
                    } Catch {
                        Write-Warning "$Product may not be existed on this WSUS server. If you have not done WSUS synchronization, it may be added by doing WSUS synchronization."
                        Write-Verbose "$error[0]"
                    }
                }
            }

            $IARClassifications = New-Object -TypeName Microsoft.UpdateServices.Administration.UpdateClassificationCollection

            foreach ($Classification in $NewInstallApprovalRule.Classifications) {
                if ($Classification.Id -ne $null) {
                    Try {
                        $IARClassifications.AddRange($WSUS.GetUpdateClassification($Classification.Id))
                    } Catch {
                        Write-Warning "$Classification may not be existed on this WSUS server. If you have not done WSUS synchronization, it may be added by doing WSUS synchronization."
                        Write-Verbose "$error[0]"
                    }
                }
            }

            $IARComputerTargetGroups = New-Object -TypeName Microsoft.UpdateServices.Administration.ComputerTargetGroupCollection

            foreach ($ComputerTargetGroup in $NewInstallApprovalRule.ComputerTargetGroups) {
                $TmpCTG = $ExistComputerTargetGroups | Where {$_.Name -eq $ComputerTargetGroup.Name}

                if ($TmpCTG -eq $null) { 
                    $ComputerTargetGroupName = $ComputerTargetGroup.Name
                    Write-Warning "$ComputerTargetGroupName may not be existed on this WSUS server. You need to create the computer group because $NewInstallApprovalRuleName uses."
                } else {
                    $IARComputerTargetGroups.AddRange($TmpCTG)
                }
            }
            Try {
                $NewIAR = $WSUS.CreateInstallApprovalRule($NewInstallApprovalRule.Name)
                $NewIAR.Enabled = $NewInstallApprovalRule.Enabled
                $NewIAR.SetCategories($IARCategories)
                $NewIAR.SetUpdateClassifications($IARClassifications)
                $NewIAR.SetComputerTargetGroups($IARComputerTargetGroups)
                $NewIAR.Deadline = $NewInstallApprovalRule.Deadline
                $NewIAR.Save()
            } Catch {
                Write-Error "$error[0]"
                Return
            }

            Write-Host "Createted $NewInstallApprovalRuleName successfully."
        }

        Write-Host "Createted all Update Rules successfully."
        Write-Host "Try to set WSUS Email Notification Configurations."

        $WSUSEmailConf.SendSyncNotification = $ImportConf[7].SendSyncNotification
        $WSUSEmailConf.SendStatusNotification = $ImportConf[7].SendStatusNotification
        $WSUSEmailConf.StatusNotificationFrequency = $ImportConf[7].StatusNotificationFrequency
        $WSUSEmailConf.StatusNotificationTimeOfDay = $ImportConf[7].StatusNotificationTimeOfDay
        $WSUSEmailConf.EmailLanguage = $ImportConf[7].EmailLanguage
        $WSUSEmailConf.SmtpHostName = $ImportConf[7].SmtpHostName
        $WSUSEmailConf.SmtpPort = $ImportConf[7].SmtpPort
        $WSUSEmailConf.SenderDisplayName = $ImportConf[7].SenderDisplayName
        $WSUSEmailConf.SenderEmailAddress = $ImportConf[7].SenderEmailAddress
        $WSUSEmailConf.SmtpServerRequiresAuthentication = $ImportConf[7].SmtpServerRequiresAuthentication
        $WSUSEmailConf.SmtpUserName = $ImportConf[7].SmtpUserName
        
        Try {
            if ($ImportConf[7].SyncNotificationRecipients -ne $null) {
                $WSUSEmailConf.SyncNotificationRecipients.Clear()
                $WSUSEmailConf.SyncNotificationRecipients.Add($ImportConf[7].SyncNotificationRecipients)
            }

            if ($ImportConf[7].StatusNotificationRecipients -ne $null) {
                $WSUSEmailConf.StatusNotificationRecipients.Clear()
                $WSUSEmailConf.StatusNotificationRecipients.Add($ImportConf[7].StatusNotificationRecipients)
            }

            if ($ImportConf[7].HasSmtpUserPassword -eq $true) {
                $WSUSEmailConf.SetSmtpUserPassword($SmtpUserPassword)
            }
            $WSUSEmailConf.Save()
        } Catch {
            Write-Error "$error[0]"
            Return
        }
        
        Write-Host "Set WSUS Email Notification Configurations successfully."
        Write-Host "All WSUS options are imported from $XmlPath"
    }
}
