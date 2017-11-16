Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

trap {
    Write-Host
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Host 'Sleeping for 60m to give you time to look around the virtual machine before self-destruction...'
    Start-Sleep -Seconds (60*60)
    Exit 1
}

if (![Environment]::Is64BitProcess) {
    throw 'this must run in a 64-bit PowerShell session'
}

if (!(New-Object System.Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'this must run with Administrator privileges (e.g. in a elevated shell session)'
}

# Don't bother if the operating system is older than Vista
if([environment]::OSVersion.version.Major -lt 6) { return }

# Cannot change the network location if you are joined to a domain, so abort
if(1,3,4,5 -contains (Get-WmiObject win32_computersystem).DomainRole) { return }

# Get network connections
$networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
$connections = $networkListManager.GetNetworkConnections()

$connections |foreach {
	Write-Host $_.GetNetwork().GetName()"category was previously set to"$_.GetNetwork().GetCategory()
	$_.GetNetwork().SetCategory(1)
	Write-Host $_.GetNetwork().GetName()"changed to category"$_.GetNetwork().GetCategory()
}

# Configure WinRM.
winrm quickconfig -q
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

## dump the WinRM configuration.
#winrm enumerate winrm/config/listener
#winrm get winrm/config
#winrm id
