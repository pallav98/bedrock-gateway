$ErrorActionPreference = "Stop"

# Setup
$folder = "C:\Temp\BigFix"
$logPath = "C:\Temp\BigFix\install_log.txt"
$url = "https://artifactory.helix.gsa.gov/artifactory/Workspaces-Ubuntu/BigFix/"

# Cleanup & prepare folder
if (Test-Path $folder) {
    Remove-Item -LiteralPath $folder -Force -Recurse
}
New-Item -Path $folder -ItemType Directory -Force | Out-Null

# Enable TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

# Log helper
function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp : $msg"
    Write-Output "$timestamp : $msg"
}

Log "Starting BigFix download..."

# Download files from Artifactory
try {
    $webResponse = Invoke-WebRequest -Uri $url -UseBasicParsing
    $links = $webResponse.Links | Where-Object { $_.href -ne "../" }

    foreach ($link in $links) {
        $fileName = $link.href
        $fileUrl = "$url$fileName"
        $destinationPath = Join-Path -Path $folder -ChildPath $fileName
        Log "Downloading $fileName"
        Invoke-WebRequest -Uri $fileUrl -OutFile $destinationPath -UseBasicParsing
    }
} catch {
    Log "Failed to download files: $_"
    exit 1
}

Log "Download complete."

# Optional: install BigFix here (if required)
# Example: Start-Process -FilePath "$folder\BigFixInstaller.exe" -ArgumentList "/S" -Wait

# Verify BigFix is installed
Log "Checking if BigFix is installed..."
$installed = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*BigFix*" }

if (-not $installed) {
    Log "BigFix is NOT installed!"
    exit 2
} else {
    Log "BigFix is installed: $($installed.Name)"
}

# Check if BigFix service is running
Log "Checking BigFix service status..."
$svc = Get-Service -Name "BESClient" -ErrorAction SilentlyContinue

if ($svc -and $svc.Status -eq "Running") {
    Log "BigFix service is running."
} else {
    Log "BigFix service is NOT running!"
    if ($svc) {
        Log "Current service status: $($svc.Status)"
    } else {
        Log "Service 'BESClient' not found."
    }
    exit 3
}

Log "BigFix installation and service check completed successfully."
