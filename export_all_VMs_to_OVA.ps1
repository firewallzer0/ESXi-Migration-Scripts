param (
    [parameter(Mandatory=$true)]
    [string] $esxihost="",
    [string] $username="",
    [string] $password="",
    [parameter(Mandatory=$true)]
    [string] $exportFolder
)
$havePowerCLI = Get-Module -ListAvailable | Where-Object Name -eq "VMware.PowerCLI"
if ($null -ne $havePowerCLI) {
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
    foreach ($vm in $vmList) {
        $name = $vm.Name
        Write-Host "***********************************************************"
        Write-Host "Working on $name"
        Write-Host "***********************************************************"
        Write-Host "Making sure the VM is shutdown"
        $status = get-vm -Name $name | Select-Object PowerState
        if ( $status.PowerState -eq "PoweredOff"){
            Write-Host "VM is already shutdown!" -ForegroundColor Green
            Write-Host "Moving to next step..."
        }
        else {
            try {
                Shutdown-VMGuest -VM $vm -Confirm:$false -ErrorAction Stop
                Write-Host "Command completed successfully, waiting for VM to turn off..."
                while( $true ) {
                    Start-Sleep -Seconds 5
                    $powStatus = get-vm -Name $name | Select-Object PowerState
                    if ($powStatus.PowerState -eq "PoweredOff"){
                        break
                    }
                    Write-Host "Still waiting for $name to shut off..."
                }
            }
            catch {
                Write-Warning "Unable to power off the VM named $name..."
                Write-Host "Moving to next VM..."
                break
            }
            Write-Host "VM is finally Powered Off..."
            Write-Host "Attempting to Export it..."
            Start-Sleep -Seconds 5
        }
        try {
            Export-VApp -VM $vm -Destination $exportFolder -Format OVA -ErrorAction Stop
            Write-Host "Successfully Exported $Name to $exportFolder" -ForegroundColor Green
        }
        catch {
            Write-Warning "Unknown issue occurred during export, the reason why is beyond the scope of this script to reattempt manually connect PowerCLI to your host and run the following command: Get-VM -Name $name | Export-VApp -Destination $exportFolder -Format OVA"
            break
        }

        
    }
    Write-Host "***********************************************************"
    Write-Host "***********************************************************"
    Write-Host "***********************************************************"
    Write-Host "Iterated through all VMs, If nothing is yellow or red you are good to go!"
    Write-Host "ALWAYS VERIFY YOUR BACKUPS!!!" -BackgroundColor White -ForegroundColor Black
    Disconnect-VIServer -Confirm:$false
}
else {
    Write-Warning "You do not have PowerCLI installed!"
    Exit
}