## Default values
# 2022 - Fernando Della Torre @ BS4IT
$Folder = "backups" #Folder created inside base path
$UsePerVMFile = $true
$EnableXFSFastClone = $true
$EnableBackupImmutability = $true
$AlignDataBlocks = $true
$ImmutabilityPeriod = 7
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
    Write-Host -ForegroundColor Green "Add Linux Server"
    Write-Output ""
    Write-Host -ForegroundColor Red "$errmsg"
    # Ask source IP
    $IP = Read-Host -Prompt "Server IP or FQDN"
    $IP -as [ipaddress] -as [Bool]
    if (-Not ($IP -as [ipaddress] -as [Bool] -eq $true)){$errmsg = "Please enter a valid IPV4 address!"}
} while (($IP.Length -eq 0) -or -Not ($IP -as [ipaddress] -as [Bool] -eq $true))
Write-Output "Connecting to $IP"

$lnxServer = Invoke-RestMethod -TimeoutSec 2 -Uri "http://$($IP)/server.json"
Write-Host -NoNewline -ForegroundColor White "Adding server "
Write-Host -NoNewline -ForegroundColor Yellow $lnxServer.Name.ToLower()
Write-Host -NoNewline -ForegroundColor White "... "
$Server = Add-VBRLinux -Name $lnxServer.Name.ToLower() -SSHPort $lnxServer.SSHPort -SSHUser $lnxServer.SSHUser -SSHPassword $lnxServer.SSHPassword -Description $lnxServer.Description -SSHTempCredentials:$true -SSHElevateToRoot:$true

if ( $Server.Name -eq $lnxServer.Name.ToLower() ){
    Write-Host -ForegroundColor Green "OK"
    $postParams = @{status='OK'}
    Set-UseUnsafeHeaderParsing -Enable
    $postResult = Invoke-WebRequest -Uri "http://$($IP)/cgi-bin/status.py" -Method POST -Body $postParams
} Else {
    Write-Host -ForegroundColor Red "Error"
    Exit
}
$RepoName = ($lnxServer.Name.Split(".")[0]).ToUpper()

Write-Host -NoNewline -ForegroundColor White "Creating Linux repository "
Write-Host -NoNewline -ForegroundColor Yellow $RepoName
Write-Host -NoNewline -ForegroundColor White "... "
$Repo = Add-VBRBackupRepository -Name $RepoName -Description $lnxServer.Description -Server $Server -Folder "$($lnxServer.Path)/$Folder" -Type LinuxLocal -UsePerVMFile:$UsePerVMFile -EnableXFSFastClone:$EnableXFSFastClone -EnableBackupImmutability:$EnableBackupImmutability -AlignDataBlocks:$AlignDataBlocks -ImmutabilityPeriod $ImmutabilityPeriod
if ( $Repo.Name -eq $RepoName ){
    Write-Host -ForegroundColor Green "OK"
} Else {
    Write-Host -ForegroundColor Red "Error"
    Exit
}
Write-Host ""
Write-Host -ForegroundColor White "Done!"

