import-module ./src/NsxtRest.psm1 -Force

Connect-NsxtRestServer -IgnoreCertRequirements -Server nsxt.greenscript.net -Credential $Credential

$BaseUri = "/policy/api/v1/infra/domains/default/groups"

$newGroupName = "testGrp970"

## Call 1 Get

$Body = @{
    "description" = $newGroupName
    "display_name" = $newGroupName
    "_revision" = 0
} 

Invoke-NsxtRestMethod -Method "Patch" -URI  "$BaseUri/$newGroupName" -Body ($Body | ConvertTo-Json -Depth 99 -Compress) 


## Call 2 Get

$Results = Invoke-NsxtRestMethod -Method "Get" -URI  $BaseUri
$Results.results | Format-Table


## Call 3 Patch 

$Body = $Results.results | ? { $_.id -eq $newGroupName } | Select-Object description,display_name,"_revision"
$Body.display_name = "Updated description"  

Invoke-NsxtRestMethod -Method "Patch" -URI  "$BaseUri/$newGroupName" -Body ($Body | ConvertTo-Json -Depth 99 -Compress) 


## Call 4 Get

$Results = Invoke-NsxtRestMethod -Method "Get" -URI  $BaseUri
$Results.results | Format-Table


## Call 5 display name updates

$Results = Invoke-NsxtRestMethod -Method "Get" -URI  $BaseUri

foreach ($group in $Results.results){
    $Body = $group | Select-Object description,display_name,"_revision"
    $Body.display_name = "Mary Poppins"
    Invoke-NsxtRestMethod -Method "Patch" -URI  "$BaseUri/$newGroupName" -Body ($Body | ConvertTo-Json -Depth 99 -Compress) 
}

$Results = Invoke-NsxtRestMethod -Method "Get" -URI  $BaseUri
$Results.results | Format-Table

## Call 6 revert display name updates

$Results = Invoke-NsxtRestMethod -Method "Get" -URI  $BaseUri
$Results.results | Format-Table

foreach ($group in $Results.results){
    $Body = $group | Select-Object description,display_name,"_revision"
    $Body.display_name = $group.id
    Invoke-NsxtRestMethod -Method "Patch" -URI  "$BaseUri/$newGroupName" -Body ($Body | ConvertTo-Json -Depth 99 -Compress) 
}

$Results = Invoke-NsxtRestMethod -Method "Get" -URI  $BaseUri
$Results.results | Format-Table