# prepare

$BaseUri = "https://nsxt.greenscript.net/policy/api/v1/infra/domains/default/groups"


## Call 1 patch

$Method = "Patch"

$newGroupName = "testGrp960"

$Body = @{
    "description" = $newGroupName
    "display_name" = $newGroupName
    "_revision" = 0
}

$Params = @{
    Method = $Method
    Headers = $Headers
    Uri = "$BaseUri/$newGroupName"
    SkipCertificateCheck = $true
}

$Body = $Body | ConvertTo-Json -Depth 99 -Compress

$Params.Add("Body", $Body)

Invoke-RestMethod @Params 


## Call 2 Get

$Method = "Get"

$Params = @{
    Method = $Method
    Headers = $Headers
    Uri = "$BaseUri"
    SkipCertificateCheck = $true
}

$Results  =  Invoke-RestMethod @Params
$Results.results | Format-Table  
 
$NewBody = $Results.results | ? { $_.id -eq $newGroupName } | Select-Object description,display_name,"_revision"


## Call 3 Patch 

$Method = "Patch"

$Params = @{
    Method = $Method
    Headers = $Headers
    Uri = "$BaseUri/$newGroupName"
    SkipCertificateCheck = $true
}

$NewBody.display_name = "Updated description"  

$Body = $NewBody | ConvertTo-Json -Depth 99 -Compress

$Params.Add("Body", $Body)

Invoke-RestMethod @Params 


## Call 4 Get

$Method = "Get"

$Params = @{

    Method = $Method
    Headers = $Headers
    Uri = $BaseUri
    SkipCertificateCheck = $true
}

$Results  =  Invoke-RestMethod @Params
$Results.results | Format-Table


## Call 5 display name updates

$Method = "Get"

$Params = @{

    Method = $Method
    Headers = $Headers
    Uri = $BaseUri
    SkipCertificateCheck = $true
}

$Results  =  Invoke-RestMethod @Params
$Results.results | Format-Table

foreach ($group in $Results.results){

    $group | Format-Table

    $Method = "Patch"

    $Params = @{
        Method = $Method
        Headers = $Headers
        Uri = "$BaseUri/$($group.id)"
        SkipCertificateCheck = $true
    }

    $NewBody = $group | Select-Object description,display_name,"_revision"
    $NewBody.display_name = "Mary Poppins"

    $Body = $NewBody | ConvertTo-Json -Depth 99 -Compress

    $Params.Add("Body", $Body)

    Invoke-RestMethod @Params 

}

$Method = "Get"

$Params = @{

    Method = $Method
    Headers = $Headers
    Uri = $BaseUri
    SkipCertificateCheck = $true
}

$Results  =  Invoke-RestMethod @Params
$Results.results | Format-Table

## Call 6 revert display name updates

$Method = "Get"

$Params = @{

    Method = $Method
    Headers = $Headers
    Uri = $BaseUri
    SkipCertificateCheck = $true
}

$Results  =  Invoke-RestMethod @Params
$Results.results | Format-Table

foreach ($group in $Results.results){

    $Method = "Patch"

    $Params = @{
        Method = $Method
        Headers = $Headers
        Uri = "$BaseUri/$($group.id)"
        SkipCertificateCheck = $true
    }

    $NewBody = $group | Select-Object description,display_name,"_revision"
    $NewBody.display_name = $group.id

    $Body = $NewBody | ConvertTo-Json -Depth 99 -Compress

    $Params.Add("Body", $Body)

    Invoke-RestMethod @Params 

}

$Method = "Get"

$Params = @{

    Method = $Method
    Headers = $Headers
    Uri = $BaseUri
    SkipCertificateCheck = $true
}

$Results  =  Invoke-RestMethod @Params
$Results.results | Format-Table