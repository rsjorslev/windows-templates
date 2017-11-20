net stop winrm

$script:ScriptPath = $MyInvocation.MyCommand.Path

$packerWindowsDir = 'C:\Windows\packer'
$RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$RegistryEntry = "InstallApplications"

Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File $($script:ScriptPath)"

if (!(Test-Path c:\windows\packer\done.txt)) {
  New-Item -Path "$($packerWindowsDir)\done.txt" -ItemType "file"
  Invoke-Expression "choco install firefox -fy"
  Restart-Computer -Force
} else {
  Remove-Item -Path "$($packerWindowsDir)\done.txt"
  Remove-ItemProperty -Path $RegistryKey -Name $RegistryEntry -ErrorAction SilentlyContinue
  net start winrm
}
