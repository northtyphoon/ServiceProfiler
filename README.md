# Service Profiler Examples

### UploadSymbolsToDataCubeSymbolsContainer.ps1

This is an example script showing how to upload required symbol files (*.pdb) from the build machine to the data cube **sp-symbols** container. You can integrate it with your CI/CD tools (eg, Visual Studio Team Service) to prepare the symbols for each deployment.

#### Rererequisites

  - Install the latest [Azure PowerShell cmdlets](https://www.microsoft.com/web/handlers/webpi.ashx/getinstaller/WindowsAzurePowershellGet.3f.3f.3fnew.appids)
  - Install [SymStore tool](https://go.microsoft.com/fwlink/p/?LinkId=536682). You can also find a copy (symstore.exe and symsrv.dll) in Tools folder. 
  - Install [GitLink](https://github.com/GitTools/GitLink). You can also find a copy (GitLink.exe) in Tools folder.

#### How does it work
The script follows the steps to prepare the symbol files.

  - Before you run the script, you must have successfully built the source code and generated the assembly and symbol files.
  - [Optional] If your source code is hosted in a Git server (eg, Visual Studio Team Services or GitHub), run GitLink to update symbol files with source index mapping to your Git server.
  - Run SymStore to compress and archive the symbol files into a local working folder.
  - Run Azure PowerShell cmdlet to upload the symbol files from the local working folder to the data cube sp-symbols container.

#### Script parameters

  - $symstoreExePath - The full path of symstore.exe.
  - $pdbRootFolder - The full path of the root folder containing the original symbol pdb files.
  - $workingFolder - The full path of the local working folder.
  - $product - A product name (required by SymStore).
  - $dataCubeStorageAccountName - The storage account name of the data cube.
  - $dataCubeStorageAccountKey - The storage account key of the data cube.
  - $gitLinkExePath - The full path of the GitLink.exe.
  - $gitLinkCommandParameters - The command parameters passed into GitLink.exe. Check out [GitLink](https://github.com/GitTools/GitLink) for more details.

#### Examples

  - Source code in GitHub

```PowerShell
.\UploadSybmolsToDataCubeSymbolsContainer.ps1 -symstoreExePath "C:\tools\symstore.exe" `                                                  
                                                -pdbRootFolder "C:\build\release" `
                                                -workingFolder "C:\working" `
                                                -product "myproduct" `
                                                -dataCubeStorageAccountName "mystorageaccountname" `
                                                -dataCubeStorageAccountKey "mystroageaccountkey" `
                                                -gitLinkExePath "C:\tools\GitLink.exe" `
                                                -gitLinkCommandParameters "C:\source\ -c release"
```

  - Source code in Visual Studio Team Service Git Repository. The following command instructs GitLink to generate VSTS specific source content url. Remember to replace My-VSTS-Account and My-GitRepo-Guid. To get the Git repository id, you can open the project page in VSTS website.
 1. Click the gear icon in the upper-right corner. This takes you to the configuration UI.
 2. Choose the "Version Control" tab. You'll get a list of repositories.
 3. Click the target repository. The URL in your address bar will update.
 4. Copy out the "repositoryId" query parameter in the URL.

```PowerShell
.\UploadSybmolsToDataCubeSymbolsContainer.ps1 -symstoreExePath "C:\tools\symstore.exe" `                                                  
                                                -pdbRootFolder "C:\build\release" `
                                                -workingFolder "C:\working" `
                                                -product "myproduct" `
                                                -dataCubeStorageAccountName "mystorageaccountname" `
                                                -dataCubeStorageAccountKey "mystroageaccountkey" `
                                                -gitLinkExePath "C:\tools\GitLink.exe" `
                                                -gitLinkCommandParameters "C:\source\ -c release -u https://My-VSTS-Account.visualstudio.com/DefaultCollection/_apis/git/repositories/My-GitRepo-Guid/items?api-version=1.0&scopePath=/{filename}&versionType=commit&version={revision}"
```
