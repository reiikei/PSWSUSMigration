$ScriptPath = Split-Path $MyInvocation.MyCommand.Path

if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Update Services\Server\Setup")) {
    Write-Error "Need to use this module on WSUS servers"
    Return
}

# Try loading installed WSUS assemblies.
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")

# Validate WSUS library
if (-not ([appdomain]::CurrentDomain.GetAssemblies() | %{ $_.GetName() } | Where-Object {$_.Name -eq "Microsoft.UpdateServices.Administration"})){
	Write-Error "WSUS Libraries could not be loaded"
	Return
}

# Load Functions
Try {
    Get-ChildItem "$ScriptPath\Scripts" | Select-Object -ExpandProperty FullName | ForEach-Object {
        $Function = Split-Path $_ -Leaf
        . $_
    }
} Catch {
    Write-Error "$error[0]"
    Return
}
