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
        Write-Warning "You must specify a username and a password."
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
    Start-Sleep -Seconds 1
    Write-Host "It may take a long time to remove some snapshots and progress may appear stalled"
    Start-Sleep -Seconds 10
    foreach ($vm in $vmList) {
        $name = $vm.Name
        Write-Host "***********************************************************"
        Write-Host "Getting Snapshots for $name"
        Write-Host "***********************************************************"
        $snapshots = Get-Snapshot -VM $vm   
        foreach ($snap in $snapshots){
            Write-Host "Found $snap for $name"
            Write-Host "Trying to remove it..."
            try {
                Remove-Snapshot -Snapshot $snap -Confirm:$false -ErrorAction Stop
                Write-Host "Removed $snap from $name!!!" -ForegroundColor Green
                Write-Host "Moving along to the next one."
            }
            catch {
                Write-Warning "Failed to remove $snap from $name"
                Write-Host "Moving along to the next one."
                Start-Sleep -Seconds 3
                break
            }
        } 
    }
    Write-Host "***********************************************************"
    Write-Host "***********************************************************"
    Write-Host "***********************************************************"
    Write-Host "Iterated through all VMs, If nothing is red or yellow you are good to go!"
    Disconnect-VIServer -Confirm:$false
}
else {
    Write-Warning "You do not have PowerCLI installed!"
    Exit
}
Write-Host "end of script"
