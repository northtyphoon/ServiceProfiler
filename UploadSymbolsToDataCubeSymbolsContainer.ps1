#Requires -Version 3.0

<#
.DESCRIPTION
    Upload symbol pdb files to data cube sp-symbols container

.NOTE
    The script replies on Azure Powershll cmdlets which you can download from https://www.microsoft.com/web/handlers/webpi.ashx/getinstaller/WindowsAzurePowershellGet.3f.3f.3fnew.appids

.EXAMPLE
    .\UploadSybmolsToDataCubeSymbolsContainer.ps1 $symstoreExePath "C:\Program Files (x86)\Windows Kits\10\Debuggers\x86\symstore.exe" `
                                                  $pdbRootFolder "C:\build\release" `
                                                  $workingFolder "C:\working" `
                                                  $product "myproduct" `
                                                  $dataCubeStorageAccountName "mystorageaccountname" `
                                                  $dataCubeStorageAccountKey "mystroageaccountkey"
#>


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$symstoreExePath,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$pdbRootFolder,

    [Parameter(Mandatory=$true, Position=2)]
    [string]$workingFolder,

    [Parameter(Mandatory=$true, Position=3)]
    [string]$product,

    [Parameter(Mandatory=$true, Position=4)]
    [string]$dataCubeStorageAccountName,

    [Parameter(Mandatory=$true, Position=5)]
    [string]$dataCubeStorageAccountKey
)

if(!(Test-Path $symstoreExePath))
{
    Write-Error "$symstoreExePath doesn't exist."
    exit -1
}

# Create a sub working folder each time
$workingFolder = Join-Path $workingFolder $(Get-Date -Format o).Replace(":", "_")

# It's the default data cube symbol container name. Please don't change it.
$symbolContainerName = "sp-symbols"

# Run symstore to index the original pdb files into the working folder
Write-Host "$(Get-Date): Start SymStore"

$pdbFiles = Get-ChildItem -Path $pdbRootFolder -Filter "*.pdb" -Recurse
# You can also filter the pdbs. The following is an simple example of filtering out the pdbs for "Test" assemblies.
# $pdbFiles = Get-ChildItem -Path $pdbRootFolder -Filter "*.pdb" -Recurse | ? {!$_.FullName.Contains("Test")}

foreach ($pdbfile in $pdbFiles)
{
    $pdfFilePath = $pdbfile.FullName
    Write-Host "Start to index $pdfFilePath"
    & $symstoreExePath add /f "$pdfFilePath" /compress /s "$workingFolder" /t "$product" /o
    if ($lastexitcode -ne 0)
    {
        throw "symstore failed as error code: $lastexitcode"
    }
}

Write-Host "$(Get-Date): Finish SymStore"


# Upload the pdb files to data cube storage sp-symbols container
Write-Host "$(Get-Date): Start Upload"

$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

if(!(Get-AzureStorageContainer -Name $symbolContainerName -Context $storageContext -ErrorAction Ignore))
{
    New-AzureStorageContainer -Name $symbolContainerName -Context $storageContext -ErrorAction Stop
}

$pdbFiles = Get-ChildItem -Path $workingFolder -Filter "*.pd_" -Recurse

foreach ($pdbfile in $pdbFiles)
{
    $pdbfilePath = $pdbfile.FullName
    $blobName = $pdbfilePath.Substring($workingFolder.Length+1).Replace("\", "/")

    Write-Host "Start to upload $pdbfilePath"
    Set-AzureStorageBlobContent -Blob $blobName -Container $symbolContainerName -File $pdbfilePath -Context $storageContext -Force -Verbose -ErrorAction Stop
}

Write-Host "$(Get-Date): Finish Upload"