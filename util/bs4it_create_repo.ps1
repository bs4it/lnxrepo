## Default values
# 2022 - Fernando Della Torre @ BS4IT
$Folder = "backups" #Folder created inside base path
$EnableXFSFastClone = $true
$EnableBackupImmutability = $true
$AlignDataBlocks = $true
$ImmutabilityPeriodDefault = 7


# Determines Veeam Version
$corePath = Get-ItemProperty -Path "HKLM:\Software\Veeam\Veeam Backup and Replication\" -Name "CorePath"
$depDLLPath = Join-Path -Path $corePath.CorePath -ChildPath "Packages\VeeamDeploymentDll.dll" -Resolve
$file = Get-Item -Path $depDLLPath
$version = $file.VersionInfo.ProductVersion


function Set-UseUnsafeHeaderParsing
{
    param(
        [Parameter(Mandatory,ParameterSetName='Enable')]
        [switch]$Enable,

        [Parameter(Mandatory,ParameterSetName='Disable')]
        [switch]$Disable
    )

    $ShouldEnable = $PSCmdlet.ParameterSetName -eq 'Enable'

    $netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])

    if($netAssembly)
    {
        $bindingFlags = [Reflection.BindingFlags] 'Static,GetProperty,NonPublic'
        $settingsType = $netAssembly.GetType('System.Net.Configuration.SettingsSectionInternal')

        $instance = $settingsType.InvokeMember('Section', $bindingFlags, $null, $null, @())

        if($instance)
        {
            $bindingFlags = 'NonPublic','Instance'
            $useUnsafeHeaderParsingField = $settingsType.GetField('useUnsafeHeaderParsing', $bindingFlags)

            if($useUnsafeHeaderParsingField)
            {
              $useUnsafeHeaderParsingField.SetValue($instance, $ShouldEnable)
            }
        }
    }
}


$ErrorActionPreference = "Stop"
$errmsg = ""
do {
    # Clear Screen
    Clear-Host
    # Write welcome and first instructions
    Write-Host -ForegroundColor Blue "BS4IT Linux Hardened Repository"
    Write-Host -ForegroundColor White "Add Linux Server"
    Write-Output ""
    Write-Host -ForegroundColor Red "$errmsg"
    # Ask source IP
    $IP = Read-Host -Prompt "Linux Server IP or FQDN"
    #if (-Not ($IP -as [ipaddress] -as [Bool] -eq $true)){$errmsg = "Please enter a valid IPV4 address!"}
#} while (($IP.Length -eq 0) -or -Not ($IP -as [ipaddress] -as [Bool] -eq $true))
} while (($IP.Length -eq 0))
Write-Output "Connecting to $IP"
$lnxServer = Invoke-RestMethod -TimeoutSec 2 -Uri "http://$($IP)/server.json"
$Server = Get-VBRServer -Name $lnxServer.Name.ToLower()
if ( $Server -eq $null ){
    Write-Host -NoNewline -ForegroundColor White "Adding server "
    Write-Host -NoNewline -ForegroundColor Yellow $lnxServer.Name.ToLower()
    Write-Host -NoNewline -ForegroundColor White "... "
    $Server = Add-VBRLinux -Name $lnxServer.Name.ToLower() -SSHPort $lnxServer.SSHPort -SSHUser $lnxServer.SSHUser -SSHPassword $lnxServer.SSHPassword -Description $lnxServer.Description -SSHTempCredentials:$true -SSHElevateToRoot:$true
} Else {
    Write-Host -NoNewline -ForegroundColor White "Server "
    Write-Host -NoNewline -ForegroundColor Yellow $lnxServer.Name.ToLower()
    Write-Host -NoNewline -ForegroundColor White " already on VB&R, skiping. "
}

if ( $Server.Name -eq $lnxServer.Name.ToLower() ){
    Write-Host -ForegroundColor Green "OK"
    $postParams = @{status='OK'}
    Set-UseUnsafeHeaderParsing -Enable
    $postResult = Invoke-WebRequest -Uri "http://$($IP)/cgi-bin/status.py" -Method POST -Body $postParams
} Else {
    Write-Host -ForegroundColor Red "Error"
    Exit
}
$RepoNameDefault = ($lnxServer.Name.Split(".")[0]).ToUpper()
$RepoName = Read-Host -Prompt "Type repository name or ENTER to accept default ($RepoNameDefault) "
if ( [string]::IsNullOrWhiteSpace($RepoName) ) {
    $RepoName = $RepoNameDefault
}



do {
    $RepoPerVMFile = (Read-Host -Prompt "Enable per VM Backup File? (Defaults to Y) ").ToLower()
    if ( [string]::IsNullOrWhiteSpace($RepoPerVMFile) ) {
        $RepoPerVMFile = "y"
    }

    if (($RepoPerVMFile -ne "y") -and ($RepoPerVMFile -ne "n")) { Write-Host -ForegroundColor Red "Invalid input. Enter Y or N." }
    }
while (($RepoPerVMFile -ne "y") -and ($RepoPerVMFile -ne "n"))

do {
    $ImmutabilityPeriod = ""
    $ImmutabilityPeriod = (Read-Host -Prompt "Set immutability days. (Defaults to 7) ").ToLower()
     if ( [string]::IsNullOrWhiteSpace($ImmutabilityPeriod) ) {
         $ImmutabilityPeriod = $ImmutabilityPeriodDefault
     }

     if (([int]$ImmutabilityPeriod -lt 7 )) { $ImmutabilityPeriod = 7 }

     if (($ImmutabilityPeriod -NotMatch '^\d+$')) { Write-Host -ForegroundColor Red "Invalid input. Enter a numeric value." }
     }
While (($ImmutabilityPeriod -NotMatch '^\d+$'))

Write-Host ""
Write-Host -NoNewline -ForegroundColor White "Creating Linux repository "
Write-Host -NoNewline -ForegroundColor Yellow $RepoName
Write-Host -NoNewline -ForegroundColor White "... "
if ( $RepoPerVMFile -eq "y") {
    $Repo = Add-VBRBackupRepository -Name $RepoName -Description $lnxServer.Description -Server $Server -Folder "$($lnxServer.Path)/$Folder" -Type LinuxLocal -UsePerVMFile:$true -EnableXFSFastClone:$EnableXFSFastClone -EnableBackupImmutability:$EnableBackupImmutability -AlignDataBlocks:$AlignDataBlocks -ImmutabilityPeriod $ImmutabilityPeriod
}
else {
    $Repo = Add-VBRBackupRepository -Name $RepoName -Description $lnxServer.Description -Server $Server -Folder "$($lnxServer.Path)/$Folder" -Type LinuxLocal -EnableXFSFastClone:$EnableXFSFastClone -EnableBackupImmutability:$EnableBackupImmutability -AlignDataBlocks:$AlignDataBlocks -ImmutabilityPeriod $ImmutabilityPeriod
}

if ( $Repo.Name -eq $RepoName ){
    Write-Host -ForegroundColor Green "OK"
} Else {
    Write-Host -ForegroundColor Red "Error"
    Exit
}
Write-Host ""
Write-Host -ForegroundColor White "Done!"
Write-Host ""
