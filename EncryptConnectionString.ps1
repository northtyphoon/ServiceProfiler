#Requires -Version 3.0

<#
.DESCRIPTION
    Encrypt storage connection string using the specified certficate in LocalMachine\My store

.EXAMPLE
    .\EncryptConnectionString.ps1 -certThumbprint "B4539A3A61308639B98C72467023F12B913A7839" `                                                  
                                  -connectionString "DefaultEndpointsProtocol=https;AccountName=sample;AccountKey=WSzqQQrzxeVtUFL+1Y2DaO7M4dmMojgjMgwu60Vg0BFdTyX/EWTXwp08ss7M27XUVF/J+2mOLuvQgd6XwWgLbw="
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$certThumbprint,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$connectionString
)


$cert = Get-Item "Cert:\LocalMachine\My\$certThumbprint" -ErrorAction Stop
$data = [system.Text.Encoding]::UTF8.GetBytes($connectionString)
$contentInfo = New-Object System.Security.Cryptography.Pkcs.ContentInfo @(,$data)
$envelope = New-Object Security.Cryptography.Pkcs.EnvelopedCms $contentInfo
$recipient = New-Object Security.Cryptography.Pkcs.CmsRecipient $cert
$envelope.Encrypt($recipient)
$encryptedData = $envelope.Encode()
$encryptedConnectionString = [System.Convert]::ToBase64String($encryptedData)

Write-Host $encryptedConnectionString
