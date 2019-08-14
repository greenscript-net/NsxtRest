# var

$Username = "admin"
$Password = "Vmware1!VMware1!"

if (!$Credential){
    $Credential = Get-Credential -UserName $Username
}



$ConnectionPassword = $Credential.GetNetworkCredential().Password

$Auth = $Username + ':' + $ConnectionPassword
$Encoded = [System.Text.Encoding]::UTF8.GetBytes($Auth)
$EncodedPassword = [System.Convert]::ToBase64String($Encoded)

$Headers = @{

    "Accept"="application/json";
    "Content-Type" = "application/json";
    "Authorization" = "Basic $($EncodedPassword)";
}

Write-Host -ForegroundColor Green $Headers