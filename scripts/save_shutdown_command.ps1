$packerWindowsDir = 'C:\Windows\packer'
New-Item -Path $packerWindowsDir -ItemType Directory -Force

# build up the clean-up and shutdown command to reset WinRM and shutdown the VM
$shutdownCmd = @"
call netsh advfirewall firewall delete rule name="WinRM-HTTP"

call winrm set winrm/config/service @{AllowUnencrypted="false"}
call winrm set winrm/config/service/auth @{Basic="false"}

call winrm delete winrm/config/Listener?Address=*+Transport=HTTP

call shutdown /s /t 120 /f /d p:4:1 /c "Packer Shutdown"
"@

Set-Content -Path "$($packerWindowsDir)\PackerShutdown.bat" -Value $shutdownCmd

$setupComplete = @"
set LOCALAPPDATA=%USERPROFILE%\AppData\Local
set PSExecutionPolicyPreference=Unrestricted
powershell -File "%systemdrive%\Windows\packer\winrm_ansible.ps1" -EnableCredSSP >"%systemdrive%\Windows\packer\winrm_ansible_log.txt" 2>&1
"@

New-Item -Path 'C:\Windows\Setup\Scripts' -ItemType Directory -Force
Set-Content -path "C:\Windows\Setup\Scripts\SetupComplete.cmd" -Value $setupComplete
