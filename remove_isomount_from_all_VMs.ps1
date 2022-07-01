param (
    [parameter(Mandatory=$true)]
    [string] $esxihost="",
    [string] $username="",
    [string] $password=""
)
$havePowerCLI = Get-Module -ListAvailable | Where-Object Name -eq "VMware.PowerCLI"
if ($havePowerCLI -ne $null) {
    if ($username -eq "" -And $password -eq "") {
        Write-Host "You will be prompted for your username and password for your ESXi/vCenter Server"
        try {
            Connect-VIServer -Server $esxihost -ErrorAction Stop
        }
        catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{
            Write-Host "Invalid Login Information" -ForegroundColor Red
            Exit
        }
        catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException] {
            Write-Host "Invalid ESXi/vCenter Server hostname or IP address" -ForegroundColor Red
            Exit
        }
        catch {
            Write-Host "Unknown error occured when connecting to $esxihost" -ForegroundColor Red
            Exit
        }
        Write-Host "Connected!" -ForegroundColor Green
    } elseif ($username -eq "" -or $password -eq "") {
        Write-Warning "You must specify a username AND a password."
        Exit
    } else {
        Write-Host "Connecting to $esxihost using supplied credentials"
        try {
            Connect-VIServer -Server $esxihost -User $username -Password $password -ErrorAction Stop
        }
        catch [VMware.VimAutomation.ViCore.Types.V1.ErrorHandling.InvalidLogin]{
            Write-Host "Invalid Login Information" -ForegroundColor Red
            Exit
        }
        catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.ViServerConnectionException] {
            Write-Host "Invalid ESXi/vCenter Server" -ForegroundColor Red
            Exit
        }
        catch {
            Write-Host "Unknown error occured when connecting to $esxihost" -ForegroundColor Red
            Exit
        }
        Write-Host "Connected!" -ForegroundColor Green
    }

    Write-Host "Getting list of VMs...."
    $vmList = Get-VM
    Start-Sleep -Seconds 1
    Write-Host "List acquired..."

    foreach ($vm in $vmList) {
        $name = $vm.Name
        Write-Host "***********************************************************"
        Write-Host "Working on VM named: $name"
        Write-Host "***********************************************************"
        $cdStatus = Get-CDDrive -VM $vm 
        if ($cdStatus.IsoPath -ne $null) {
            Write-Host "Found an ISO Mounted in the CD Drive! Ejecting it!"
            try {
                Set-CDDrive -NoMedia -Confirm:$false -CD $cdStatus -ErrorAction Stop | Out-Null
                Write-Host "ISO Ejected!!!" -ForegroundColor Green
                Write-Host "Continuing to work through the list...."
                Write-Host ""
            }
            catch {
                Write-Warning "Unable to Eject the ISO file from $name!!!"
                Write-Host "Continuing to work through the list...."
                Write-Host ""
                Start-Sleep -Seconds 2
                Break
            }
        }
        else {
            Write-Host "No ISO Mounted to $name" -ForegroundColor Green
            Write-Host "Continuing to work through the list...."
            Write-Host ""
        }
    }

    Write-Host "***********************************************************"
    Write-Host "***********************************************************"
    Write-Host "***********************************************************"
    Write-Host "Iterated through all VMs, If everything is Green you are good to go!"

    Disconnect-VIServer -Confirm:$false
}
else {
    Write-Warning "You do not have PowerCLI installed!"
    Exit
}
