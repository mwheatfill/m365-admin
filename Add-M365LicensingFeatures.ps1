#Get a group
$group = Get-MgGroup -GroupId "8b0ae377-0696-43c6-a8d0-a76f6c5a3a43"

# Get group members
$groupMembers = Get-MgGroupMember -GroupId $group.Id

# Get the M365 E3 SKU number
$e3Sku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'SPE_E3'

# Get the list of features (service plans) to enable for the user
$plansToEnable = $e3Sku.ServicePlans | Where ServicePlanName -in ("MICROSOFTBOOKINGS", "MICROSOFT_LOOP") | Select -ExpandProperty ServicePlanId

foreach ($groupMember in $licensedUsers) {
    $userLicense = Get-MgUserLicenseDetail -UserId $groupMember.Id
    $userDisabledPlans = $userLicense.ServicePlans | Where ProvisioningStatus -eq "Disabled" | Select -ExpandProperty ServicePlanId
    $disabledPlans = $userDisabledPlans | Where {$_ -notin $plansToEnable}
    
    #Add licensing features with updated features list
    $addLicenses = @(
        @{
            SkuId = $e3Sku.SkuId
            DisabledPlans = $disabledPlans
        }
    )
    Set-MgUserLicense -UserId $groupMember.Id -AddLicenses $addLicenses -RemoveLicenses @()
}