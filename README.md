# NsxtRest
Module for working with NSXT purely via Rest

Currently an extremely basic module that allows establishing a connection to NSX-T for Rest Operations

once connected a variable is in place for a wrapper for the Invoke-RestMethod cmdlet
which will take care of SSL headers and authorization

In time can add additonal functions maybe even make use of powershell classes for additional functionality

## Usage 

Connect-NsxtRestServer -Server $servername -cred $credential

Invoke-NsxtRestMethod -Method GET -URI /api/v1/licences

Disconnect-NsxtRestServer