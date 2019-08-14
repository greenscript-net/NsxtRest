function Connect-NsxtRestServer {
<#
    .SYNOPSIS
    Connect to a NSXT Rest Server

    .DESCRIPTION
    Connect to a NSXT Rest Server and generate a connection object with Servername, Token etc

    .PARAMETER Server
    NSXT Rest Server to connect to

    .PARAMETER Port
    Optionally specify the server port. Default is 443

    .PARAMETER Username
    Username to connect with

    .PARAMETER Password
    Password to connect with

    .PARAMETER Credential
    Credential object to connect with

    .PARAMETER IgnoreCertRequirements
    Ignore requirements to use fully signed certificates

    .PARAMETER SslProtocol

    Alternative Ssl protocol to use from the default
    Windows PowerShell: Ssl3, Tls, Tls11, Tls12
    PowerShell Core: Tls, Tls11, Tls12

    .INPUTS
    System.String
    System.SecureString
    Management.Automation.PSCredential
    Switch

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Connect-NsxtRestServer -Server nsxt.domain.local -Credential (Get-Credential)

    .EXAMPLE
    $SecurePassword = ConvertTo-SecureString “P@ssword” -AsPlainText -Force
    Connect-NsxtRestServer -Server nsxt.domain.local -Username admin -Password $SecurePassword -IgnoreCertRequirements

    .EXAMPLE
    Connect-NsxtRestServer -Server nsxt.domain.local -Port 443 -Credential (Get-Credential)

#>
[CmdletBinding(DefaultParametersetName="Username")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Server,

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Int]$Port = 443,

    [Parameter(Mandatory=$true,ParameterSetName="Username")]
    [ValidateNotNullOrEmpty()]
    [String]$Username,

    [Parameter(Mandatory=$true,ParameterSetName="Username")]
    [ValidateNotNullOrEmpty()]
    [SecureString]$Password,

    [Parameter(Mandatory=$true,ParameterSetName="Credential")]
	[ValidateNotNullOrEmpty()]
	[Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory=$false)]
    [Switch]$IgnoreCertRequirements,

    [parameter(Mandatory=$false)]
    [ValidateSet('Ssl3', 'Tls', 'Tls11', 'Tls12')]
    [String]$SslProtocol

    )

    # --- Test Connectivity to NSXT Rest Server on the given port
    try {

        # --- Test Connection to the NSXT Rest Server
        Write-Verbose -Message "Testing connectivity to $($Server):$($Port)"

        $TCPClient = New-Object Net.Sockets.TcpClient
        $TCPClient.Connect($Server, $Port)

        $TCPClient.Close()

    }
    catch [Exception] {

        throw "Could not connect to server $($Server) on port $($Port)"

    }

    # --- Handle untrusted certificates if necessary
    $SignedCertificates = $true

    if ($PSBoundParameters.ContainsKey("IgnoreCertRequirements")){

        if (!$IsCoreCLR) {

            if ( -not ("TrustAllCertsPolicy" -as [type])) {

            Add-Type @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class TrustAllCertsPolicy : ICertificatePolicy {
                public bool CheckValidationResult(
                    ServicePoint srvPoint, X509Certificate certificate,
                    WebRequest request, int certificateProblem) {
                    return true;
                }
            }
"@
            }
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }

        $SignedCertificates = $false
    }

    # --- Security Protocol
    $SslProtocolResult = 'Default'

    if ($PSBoundParameters.ContainsKey("SslProtocol") ){

        if (!$IsCoreCLR) {

            $CurrentProtocols = ([System.Net.ServicePointManager]::SecurityProtocol).toString() -split ', '

            if (!($SslProtocol -in $CurrentProtocols)){

                [System.Net.ServicePointManager]::SecurityProtocol += [System.Net.SecurityProtocolType]::$($SslProtocol)
            }
        }

        $SslProtocolResult = $SslProtocol
    }
    elseif (!$IsCoreCLR) {

        # --- Set the default Security Protocol for Windows PS to be TLS 1.2

        $CurrentProtocols = ([System.Net.ServicePointManager]::SecurityProtocol).toString() -split ', '

        if (!($SslProtocol -in $CurrentProtocols)){

            [System.Net.ServicePointManager]::SecurityProtocol += [System.Net.SecurityProtocolType]::Tls12
        }

        $SslProtocolResult = 'Tls12'
    }

    # --- Convert Secure Credentials
    if ($PSBoundParameters.ContainsKey("Credential")){

        $Username = $Credential.UserName
        $ConnectionPassword = $Credential.GetNetworkCredential().Password

    }
    if ($PSBoundParameters.ContainsKey("Password")){

        $ConnectionPassword = (New-Object System.Management.Automation.PSCredential("username", $Password)).GetNetworkCredential().Password
    }

    try {

        # --- Set Encoded Password
        $Auth = $Username + ':' + $ConnectionPassword
        $Encoded = [System.Text.Encoding]::UTF8.GetBytes($Auth)
        $EncodedPassword = [System.Convert]::ToBase64String($Encoded)

        # --- Create Output Object
        $Global:NsxtRestConnection = [pscustomobject]@{

            Server = "https://$($Server):$($Port)"
            Username = $Username
            EncodedPassword = $EncodedPassword
            Version = $Null
            APIVersion = $Null
            SignedCertificates = $SignedCertificates
            SslProtocol = $SslProtocolResult
        }

        # --- Update NsxtRestConnection with version information
        $VersionInfo = "2.4"
        $Global:NsxtRestConnection.Version = $VersionInfo.Version
        $Global:NsxtRestConnection.APIVersion = $VersionInfo.APIVersion

        # --- Test the credentials provided
        Write-Verbose -Message "Testing credentials"
        $URI = "/api/v1/licenses"
        Invoke-NsxtRestMethod -Method Get -URI $URI -ErrorAction Stop | Out-Null

        Write-Output $Global:NsxtRestConnection
    }
    catch [Exception]{

        Remove-Variable -Name NsxtRestConnection -Scope Global -Force -ErrorAction SilentlyContinue
        $PSCmdlet.ThrowTerminatingError($PSitem)
    }
}

function Disconnect-NsxtRestServer {
<#
    .SYNOPSIS
    Disconnect from a NSXT Rest server

    .DESCRIPTION
    Disconnect from a NSXT Rest server by removing the global NsxtRestConnection variable from PowerShell

    .EXAMPLE
    Disconnect-NsxtRestServer

    .EXAMPLE
    Disconnect-NsxtRestServer -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param ()

    # --- Test for existing connection to NsxtRestConnection
    if (-not $Global:NsxtRestConnection){

        throw "NSXT Rest Connection variable does not exist. Please run Connect-NsxtRestServer first to create it"
    }

    if ($PSCmdlet.ShouldProcess($Global:NsxtRestConnection.Server)){

        try {

            # --- Remove custom Security Protocol if it has been specified
            if ($Global:NsxtRestConnection.SslProtocol -ne 'Default'){

                if (!$IsCoreCLR) {

                    [System.Net.ServicePointManager]::SecurityProtocol -= [System.Net.SecurityProtocolType]::$($Global:NsxtRestConnection.SslProtocol)
                }
            }
        }
        catch [Exception]{

            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
        finally {

            # --- Remove the global PowerShell variable
            Write-Verbose -Message "Removing NsxtRestConnection Global Variable"
            Remove-Variable -Name NsxtRestConnection -Scope Global -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-NsxtRestMethod {
<#
    .SYNOPSIS
    Wrapper for Invoke-RestMethod with NSXT Rest specifics

    .DESCRIPTION
    Wrapper for Invoke-RestMethod with NSXT Rest specifics

    .PARAMETER Method
    REST Method: GET, POST, PUT or DELETE

    .PARAMETER URI
    API URI, e.g. /api/v1/licenses

    .PARAMETER Body
    REST Body in JSON format

    .PARAMETER Webrequest
    Use Invoke-WebRequest instead of Invoke-RestMethod

    .PARAMETER Headers
    Optionally supply custom headers

    .PARAMETER OutFile
    Saves the response body in the specified output file

    .INPUTS
    System.String
    System.Collections.IDictionary
    Switch

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Invoke-NsxtRestMethod -Method GET -URI '/api/v1/licenses'

    .EXAMPLE
    $URI = "/api/v1/licenses/"
    $JSON =  @"
{"parameters":
	[
        {
            "value": {"string":{ "value": "Apple"}},
            "type": "string",
            "name": "a",
            "scope": "local"
        },
        {
            "value": {"number":{ "value": 20}},
            "type": "number",
            "name": "b",
            "scope": "local"
        }
	]
}
"@
    $InvokeRequest = Invoke-NsxtRestMethod -Method POST -URI $URI -Body $Body -WebRequest
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateSet("GET","POST","PUT","DELETE")]
    [String]$Method,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$URI,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    $Body,

    [parameter(Mandatory=$false)]
    [Switch]$WebRequest,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [System.Collections.IDictionary]$Headers,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$OutFile
    )

# --- Test for existing connection to NSXT Rest
if (-not $Global:NsxtRestConnection){

    throw "NSXT Rest Connection variable does not exist. Please run Connect-NsxtRestServer first to create it"
}

    # --- Create Invoke-RestMethod Parameters
    $FullURI = "$($Global:NsxtRestConnection.Server)$($URI)"

    # --- Add default headers if not passed
    if (!$PSBoundParameters.ContainsKey("Headers")){

        $Headers = @{

            "Accept"="application/json";
            "Content-Type" = "application/json";
            "Authorization" = "Basic $($Global:NsxtRestConnection.EncodedPassword)";
        }
    }

    # --- Set up default parmaeters
    $Params = @{

        Method = $Method
        Headers = $Headers
        Uri = $FullURI
    }

    if ($PSBoundParameters.ContainsKey("Body")) {

        $Params.Add("Body", $Body)

        # --- Log the payload being sent to the server
        Write-Debug -Message $Body

    }
    elseif ($PSBoundParameters.ContainsKey("OutFile")) {

        $Params.Add("OutFile", $OutFile)
    }

    # --- Support for PowerShell Core certificate checking
    if (!($Global:NsxtRestConnection.SignedCertificates) -and ($IsCoreCLR)) {

        $Params.Add("SkipCertificateCheck", $true)
    }

    try {

        # --- Use either Invoke-WebRequest or Invoke-RestMethod

        if ($PSBoundParameters.ContainsKey("WebRequest")) {

            Invoke-WebRequest @Params
        }

        else {

            Invoke-RestMethod @Params
        }
    }
    catch [Exception] {

        $PSCmdlet.ThrowTerminatingError($PSitem)
    }
    finally {

        if (!$IsCoreCLR) {

            # Workaround for bug in Invoke-RestMethod. Thanks to the PowerNSX guys for pointing this one out
            # https://bitbucket.org/nbradford/powernsx/src

            $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($FullURI)
            $ServicePoint.CloseConnectionGroup("") | Out-Null
        }
    }
}