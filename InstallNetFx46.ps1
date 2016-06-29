#Requires -Version 3.0

<#
.DESCRIPTION
    Install .Net Framework 4.6.1
#>


[CmdletBinding()]
Param(
    [switch]$norestart
)

Set-StrictMode -Version Latest

$logFile = Join-Path $env:TEMP -ChildPath "InstallNetFx46ScriptLog.txt"

# Check if the latest NetFx46 version exists
$netFxKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full\\" -ErrorAction Ignore

if($netFxKey -and $netFxKey.Release -ge 394271) {
    "$(Get-Date): The machine already has NetFx 4.6.1 or later version installed." | Tee-Object -FilePath $logFile -Append
    exit 0
}

# Download the latest NetFx46
$setupFileSourceUri = "https://download.microsoft.com/download/3/5/9/35980F81-60F4-4DE3-88FC-8F962B97253B/NDP461-KB3102438-Web.exe"
$setupFileLocalPath = Join-Path $env:TEMP -ChildPath "NDP461-KB3102438-Web.exe"

"$(Get-Date): Start to download NetFx 4.6.1 to $setupFileLocalPath." | Tee-Object -FilePath $logFile -Append

if(Test-Path $setupFileLocalPath)
{
    Remove-Item -Path $setupFileLocalPath -Force
}

$webClient = New-Object System.Net.WebClient

$retry = 0

do
{
    try {
        $webClient.DownloadFile($setupFileSourceUri, $setupFileLocalPath)
        break
    }
    catch [Net.WebException] {
        $retry++

        if($retry -gt 3) {
            "$(Get-Date): Download failed as the network connection issue. Exception detail: $_" | Tee-Object -FilePath $logFile -Append
            break
        }

        $waitInSecond = $retry * 30
        "$(Get-Date): It looks the Internet network is not available now. Simply wait for $waitInSecond seconds and try again." | Tee-Object -FilePath $logFile -Append
        Start-Sleep -Second $waitInSecond
    }
} while ($true)


if(!(Test-Path $setupFileLocalPath))
{
    "$(Get-Date): Failed to download NetFx 4.6.1 setup package." | Tee-Object -FilePath $logFile -Append
    exit -1
}

# Install NetFx46
$setupLogFilePath = Join-Path $env:TEMP -ChildPath "NetFx46SetupLog.txt"
if($norestart) {
    $arguments = "/q /norestart /serialdownload /log $setupLogFilePath"
}
else {
    $arguments = "/q /serialdownload /log $setupLogFilePath"
}
"$(Get-Date): Start to install NetFx 4.6.1" | Tee-Object -FilePath $logFile -Append
$process = Start-Process -FilePath $setupFileLocalPath -ArgumentList $arguments -Wait -PassThru

if(-not $process) {
    "$(Get-Date): Install NetFx failed." | Tee-Object -FilePath $logFile -Append
    exit -1
}
else {
    $exitCode = $process.ExitCode

    # 0, 1641 and 3010 indicate success. See https://msdn.microsoft.com/en-us/library/ee390831(v=vs.110).aspx for detail.
    if($exitCode -eq 0 -or $exitCode -eq 1641 -or $exitCode -eq 3010) {
        "$(Get-Date): Install NetFx succeeded with exit code : $exitCode." | Tee-Object -FilePath $logFile -Append
        exit 0
    }
    else {
        "$(Get-Date): Install NetFx failed with exit code : $exitCode." | Tee-Object -FilePath $logFile -Append
        exit -1
    }
}