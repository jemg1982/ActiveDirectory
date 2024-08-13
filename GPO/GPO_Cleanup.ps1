<#
.SYNOPSIS
This script performs checks on Group Policy Objects (GPOs) in Active Directory and provides information about disabled, unlinked, and empty GPOs.

.DESCRIPTION
The script connects to Active Directory and retrieves all GPOs. It then checks each GPO for different criteria:
- Disabled GPOs: GPOs that have all settings disabled.
- Unlinked GPOs: GPOs that are not linked to any Active Directory container.
- Empty GPOs: GPOs that have no extension data or no extension data for both User and Computer settings.

The script outputs the count and details of GPOs falling into each category.

.PARAMETER None
This script does not accept any parameters.

.INPUTS
This script does not accept any inputs.

.OUTPUTS
The script provides the following outputs:
- Count and details of GPOs with 'All Settings Disabled'.
- Count and details of unlinked GPOs.
- Count and details of empty GPOs.

.NOTES
- This script requires the Active Directory PowerShell module to be installed.
- The user executing the script should have appropriate permissions to access and retrieve GPO information from Active Directory.
- This script does not make any modifications to GPOs; it only retrieves information and performs checks.
- The script should be run from a machine with access to the Active Directory domain.
#>

# Connect to Active Directory
Import-Module ActiveDirectory

# Define Arrays to store different types of GPOs
$DisabledGPOs = @()
$UnlinkedGPOs = @()
$EmptyGPOs = @()

# Retrieve all GPOs and process them one by one
Get-GPO -All | ForEach-Object {

    # Try to generate the GPO report and handle any errors
    try {
        [xml]$Report = $_ | Get-GPOReport -ReportType Xml
    }
    catch {
        Write-Error "Failed to generate GPO report for $($_.DisplayName): $_"
        return
    }

    # Check if GPO is Disabled
    if ($_.GpoStatus -eq "AllSettingsDisabled") {
        $DisabledGPOs += $_
    }

    # Check if GPO is Unlinked
    if ($Report.GPO.LinksTo -eq $NULL) {
        $UnlinkedGPOs += $_
    }

    # Check if GPO is Empty
    if ($_.User.DSVersion -eq 0 -and $_.Computer.DSVersion -eq 0 -or
        ($Report.GPO.Computer.ExtensionData -eq $NULL -and $Report.GPO.User.ExtensionData -eq $NULL)) {
        $EmptyGPOs += $_
    }
}

# Output the count and details of GPOs with 'All Settings Disabled'
Write-Host "Total GPOs with 'All Settings Disabled': $($DisabledGPOs.Count)" -f Yellow
$DisabledGPOs

# Output the count and details of unlinked GPOs
Write-Host "Total of unlinked GPOs: $($UnlinkedGPOs.Count)" -f Yellow
$UnlinkedGPOs

# Output the count and details of empty GPOs
Write-Host "Total of empty GPOs: $($EmptyGPOs.Count)" -f Yellow
$EmptyGPOs

# Export the results to CSV files
$DisabledGPOs | Export-Csv -Path "DisabledGPOs.csv" -NoTypeInformation
$UnlinkedGPOs | Export-Csv -Path "UnlinkedGPOs.csv" -NoTypeInformation
$EmptyGPOs | Export-Csv -Path "EmptyGPOs.csv" -NoTypeInformation

Write-Host "Results exported to CSV files: DisabledGPOs.csv, UnlinkedGPOs.csv, EmptyGPOs.csv" -f Green

<#
Hashtags: #PowerShell #ActiveDirectory #CyberSecurity #ITAutomation #GroupPolicy #SysAdmin #ITManagement
#>
