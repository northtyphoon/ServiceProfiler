#Requires -Version 3.0

Set-StrictMode -Version Latest

$logFile = Join-Path $env:TEMP -ChildPath "InstallNetFx46ScriptLog.txt"

# Check if NetFx46 or later version exists
$netFxKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full\\" -ErrorAction Ignore

if($netFxKey -and $netFxKey.Release -ge 393295) {
    "$(Get-Date): The machine already has NetFx 4.6 or later version installed." | Out-File -FilePath $logFile -Append
    return
}

# Download NetFx46
$setupFileSourceUri = "https://download.microsoft.com/download/1/4/A/14A6C422-0D3C-4811-A31F-5EF91A83C368/NDP46-KB3045560-Web.exe"
$setupFileLocalPath = Join-Path $env:TEMP -ChildPath "NDP46-KB3045560-Web.exe"

"$(Get-Date): Start to download NetFx 4.6 to $setupFileLocalPath." | Out-File -FilePath $logFile -Append

if(Test-Path $setupFileLocalPath)
{
    Remove-Item -Path $setupFileLocalPath -Force
}

$webClient = New-Object System.Net.WebClient

try {
    $webClient.DownloadFile($setupFileSourceUri, $setupFileLocalPath)
} 
catch {
    "$(Get-Date): It looks the internet network is not available now. Simply wait for 30 seconds and try again." | Out-File -FilePath $logFile -Append
    Start-Sleep -Second 30
    $webClient.DownloadFile($setupFileSourceUri, $setupFileLocalPath)
}

if(!(Test-Path $setupFileLocalPath))
{
    "$(Get-Date): Failed to download NetFx 4.6 setup package." | Out-File -FilePath $logFile -Append
    return
}

# Install NetFx46
$setupLogFilePath = Join-Path $env:TEMP -ChildPath "NetFx46SetupLog.txt"
$arguments = "/q /serialdownload /log $setupLogFilePath"

"$(Get-Date): Start to install NetFx 4.6." | Out-File -FilePath $logFile -Append
$process = Start-Process -FilePath $setupFileLocalPath -ArgumentList $arguments -Wait -PassThru

"$(Get-Date): Install NetFx finished with exit code : $($process.ExitCode)." | Out-File -FilePath $logFile -Append