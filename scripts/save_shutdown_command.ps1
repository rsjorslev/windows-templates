$packerWindowsDir = 'C:\Windows\packer'
New-Item -Path $packerWindowsDir -ItemType Directory -Force

# build up the clean-up and shutdown command to reset WinRM and shutdown the VM
$shutdownCmd = @"
netsh advfirewall firewall delete rule name="WinRM-HTTP"

winrm set winrm/config/service @{AllowUnencrypted="false"}
winrm set winrm/config/service/auth @{Basic="false"}

winrm delete winrm/config/Listener?Address=*+Transport=HTTP

shutdown /s /t 10 /f /d p:4:1 /c "Packer Shutdown"
"@

Set-Content -Path "$($packerWindowsDir)\PackerShutdown.bat" -Value $shutdownCmd
