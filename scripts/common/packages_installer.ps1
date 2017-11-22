[CmdletBinding()]

$global:AutOSDir = "C:\Windows\packer"

$PackagesFile = "$($AutOSDir)\packages.json"
$Logfile = "C:\Windows\packer\choco-app-install.log"
$ScriptPath = $MyInvocation.MyCommand.Path
$RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$RegistryEntry = "ChocoPackagesInstall"
$StateFile = "$($AutOSDir)\state.json"

function LogWrite {
   Param ([string]$logstring)
   $now = Get-Date -format s
   Add-Content $Logfile -value "$now $logstring"
   Write-Host $logstring
}

function Install-Packages {
    Write-host $pwd
    $Packages = Get-Packages

    if ((Get-State).started -eq 0) {
        LogWrite "Package installation not started, rebooting so Packer gets a clean exit code"
        Set-Service -Name "WinRM" -StartupType Disabled
        Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File $($script:ScriptPath)"
        Set-Started 1
        Restart-Computer -Force
        break
    }

    if ((Get-State).started -eq 1 -and (Get-State).currentPackage -le $Packages.length -1) {
        for ($i = (Get-State).currentPackage; $i -lt $Packages.Length; $i++) {
            Write-Host "Beginning installation of package:" $Packages[$i].name "(version: "$Packages[$i].version")"
            Set-CurrentPackage $i
            $exec = "choco install " + $Packages[$i].name + " --version " + $Packages[$i].version + " -y"

            Invoke-Expression $exec

            switch ($LastExitCode) {
                0 {
                    LogWrite "Package installed successfully, continuing with the next package"
                }
                1 {
                    LogWrite "Package installation exited with an error - breaking."
                    break
                }
                3010 {
                    LogWrite "Package requested a reboot - initialising reboot"
                    Set-BackFromReboot 1
                    Restart-Computer -Force
                }
                default {
                    LogWrite "Exit code could not be verified"
                    break
                }
            }
        }
    }

    if ((Get-State).currentPackage -eq $Packages.length -1) {
        Write-Host "Nore more packages to install, re-enabling WinRM and rebooting"
        Set-Service -Name "WinRM" -StartupType Automatic
        Remove-ItemProperty -Path $RegistryKey -Name $RegistryEntry -ErrorAction SilentlyContinue
        Restart-Computer -Force
    }
}

function Get-Packages {
    if ((Test-Path -Path $PackagesFile)) {
        return Get-Content $PackagesFile | ConvertFrom-Json
        if ($Packages.Length -eq 0) {
            LogWrite "No packages found in provided json file - aborting"
            break
        }
    } else {
        LogWrite "Packages file does not exist, please verify the path and try again"
        break
    }
}

function Get-State {
    if (Test-Path -Path $StateFile) {
        return Get-Content -Path $StateFile | ConvertFrom-Json
    } else {
        New-Item -Path $StateFile -ItemType "file" > $null
        $stateProps = @{
                    'started'=0;
                    'currentPackage'=0;
                    'morePackages'=0;
                    'backFromReboot'=0}
        $stateObject = New-Object –TypeName PSObject –Prop $stateProps
        ConvertTo-Json -InputObject $stateObject | Set-Content -Path $StateFile
        return $stateObject
    }
}

function Set-CurrentPackage($Value) {
$state = Get-State
$state.currentPackage = $Value
ConvertTo-Json -InputObject $state | Set-Content -Path $StateFile
}

function Set-Started($Value) {
$state = Get-State
$state.started = $Value
ConvertTo-Json -InputObject $state | Set-Content -Path $StateFile
}

function Set-MorePackages($Value) {
$state = Get-State
$state.morePackages = $Value
ConvertTo-Json -InputObject $state | Set-Content -Path $StateFile
}

function Set-BackFromReboot($Value) {
$state = Get-State
$state.backFromReboot = $Value
ConvertTo-Json -InputObject $state | Set-Content -Path $StateFile
}

Install-Packages
