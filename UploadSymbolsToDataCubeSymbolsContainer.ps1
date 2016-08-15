#Requires -Version 3.0

<#
.DESCRIPTION
    Upload symbol pdb files to data cube sp-symbols container

.NOTE
    You can download symstore from https://go.microsoft.com/fwlink/p/?LinkId=536682
    The script relies on Azure PowerShell cmdlets to upload symbol files to Azure storage. You can download it from https://www.microsoft.com/web/handlers/webpi.ashx/getinstaller/WindowsAzurePowershellGet.3f.3f.3fnew.appids
    The script also allows utlizing GitLink to update symbol files with source index mapping to your Git host. You can check out https://github.com/GitTools/GitLink for more details.

.EXAMPLE
    .\UploadSybmolsToDataCubeSymbolsContainer.ps1 -symstoreExePath "C:\tools\symstore.exe" `                                                  
                                                  -pdbRootFolder "C:\build\release" `
                                                  -workingFolder "C:\working" `
                                                  -product "myproduct" `
                                                  -dataCubeStorageAccountName "mystorageaccountname" `
                                                  -dataCubeStorageAccountKey "mystroageaccountkey" `
                                                  -gitLinkExePath "C:\tools\GitLink.exe" `
                                                  -gitLinkCommandParameters "C:\source\ -c release"
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
    [string]$dataCubeStorageAccountKey,

    [Parameter(Mandatory=$false, Position=6)]
    [string]$gitLinkExePath,

    [Parameter(Mandatory=$false, Position=7)]
    [string]$gitLinkCommandParameters
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

if($gitLinkExePath -and $gitLinkCommandParameters)
{
    # Run Gitlink to index source
    Write-Host "$(Get-Date): Start GetLink to index source"
    $process = Start-Process -FilePath $gitLinkExePath -ArgumentList $gitLinkCommandParameters -Wait -PassThru
    if($process.ExitCode -ne 0)
    {
        Write-Error  "GetLink failed as error code: $($process.ExitCode)" 
        exit -1
    }
    Write-Host "$(Get-Date): Finish GetLink"
}

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
        Write-Error  "symstore failed as error code: $lastexitcode"
        exit -1
    }
}

Write-Host "$(Get-Date): Finish SymStore"


# Upload the pdb files to data cube storage sp-symbols container
Write-Host "$(Get-Date): Start Upload"

$storageContext = New-AzureStorageContext -StorageAccountName $dataCubeStorageAccountName -StorageAccountKey $dataCubeStorageAccountKey

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