$ErrorActionPreference = "Stop"

# Config
$folder = "C:\Temp\BigFix"
$logPath = "$folder\install_log.txt"
$url = "https://artifactory.helix.gsa.gov/artifactory/Workspaces-Ubuntu/BigFix/"

# Ensure TLS
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

# Log helper
function Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp : $msg"
    Write-Output "$timestamp : $msg"
}

# Prep log folder
if (Test-Path $folder) {
    Remove-Item -LiteralPath $folder -Force -Recurse
}
New-Item -Path $folder -ItemType Directory -Force | Out-Null

Log "=== Starting BigFix Installation Script ==="

# Step 1: Check if BigFix is already installed
Log "Checking for existing BigFix installation..."
$existing = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*BigFix*" }

if ($existing) {
    Log "BigFix is already installed: $($existing.Name)"
    
    $svc = Get-Service -Name "BESClient" -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -ne "Running") {
            Log "BigFix service is not running. Attempting to start..."
            Start-Service -Name "BESClient"
            Log "BigFix service started."
        } else {
            Log "BigFix service is already running."
        }
    } else {
        Log "BigFix service not found!"
        exit 3
    }

    Log "Skipping reinstallation."
    exit 0
}

# Step 2: Download installer files from Artifactory
Log "BigFix not installed. Proceeding with download..."
try {
    $webResponse = Invoke-WebRequest -Uri $url -UseBasicParsing
    $links = $webResponse.Links | Where-Object { $_.href -ne "../" }

    foreach ($link in $links) {
        $fileName = $link.href
        $fileUrl = "$url$fileName"
        $destinationPath = Join-Path -Path $folder -ChildPath $fileName
        Log "Downloading $fileName..."
        Invoke-WebRequest -Uri $fileUrl -OutFile $destinationPath -UseBasicParsing
    }
    Log "Download completed."
} catch {
    Log "ERROR: Failed to download from Artifactory - $_"
    exit 1
}

# Step 3: Install BigFix (customize this section)
# Example placeholder command (update this with your actual installer & args)
$installer = Get-ChildItem "$folder\*.exe" | Select-Object -First 1
if ($installer) {
    Log "Starting BigFix installer: $($installer.Name)"
    try {
        Start-Process -FilePath $installer.FullName -ArgumentList "/S" -Wait -NoNewWindow
        Log "BigFix installer completed."
    } catch {
        Log "ERROR: Installation failed - $_"
        exit 2
    }
} else {
    Log "ERROR: No installer file found in $folder"
    exit 2
}

# Step 4: Final verification
Log "Verifying installation..."
$installed = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*BigFix*" }
if (-not $installed) {
    Log "ERROR: BigFix not detected after installation."
    exit 2
}

$svc = Get-Service -Name "BESClient" -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Log "✅ BigFix installed and service is running."
    exit 0
} elseif ($svc) {
    Log "BigFix installed but service is NOT running. Attempting to start..."
    Start-Service -Name "BESClient"
    Log "BigFix service started."
    exit 0
} else {
    Log "ERROR: BigFix installed but service not found."
    exit 3
}
