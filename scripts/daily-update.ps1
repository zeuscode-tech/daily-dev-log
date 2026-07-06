param(
    [Parameter(Mandatory = $true)]
    [string]$RepoPath
)

$ErrorActionPreference = 'Stop'
$RepoPath = (Resolve-Path -LiteralPath $RepoPath).Path
$lockPath = Join-Path $RepoPath '.daily-update.lock'
$statePath = Join-Path $RepoPath '.daily-state.json'
$almatyZone = [TimeZoneInfo]::FindSystemTimeZoneById('Central Asia Standard Time')
$now = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $almatyZone)
$day = $now.ToString('yyyy-MM-dd')

$lock = $null
try {
    $lock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
    Set-Location -LiteralPath $RepoPath

    git config user.name 'zeuscode-tech'
    git config user.email '180309429+zeuscode-tech@users.noreply.github.com'
    git pull --rebase origin main

    $state = if (Test-Path -LiteralPath $statePath) {
        Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    } else {
        [pscustomobject]@{ date = ''; phase = 0 }
    }

    if ($state.date -ne $day) {
        $state = [pscustomobject]@{ date = $day; phase = 0 }
    }

    if ($state.phase -lt 1) {
        $logDir = Join-Path $RepoPath 'logs'
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        $logPath = Join-Path $logDir ($now.ToString('yyyy-MM') + '.md')
        if (-not (Test-Path -LiteralPath $logPath)) {
            "# Daily pulses — $($now.ToString('yyyy-MM'))`n" | Set-Content -LiteralPath $logPath -Encoding utf8
        }
        "- $day — daily repository sync completed at $($now.ToString('HH:mm')) Asia/Almaty." | Add-Content -LiteralPath $logPath -Encoding utf8
        $state.phase = 1
        $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
        git add -- $logPath $statePath
        git commit -m "log: record daily pulse for $day"
    }

    if ($state.phase -lt 2) {
        $commitCount = [int](git rev-list --count HEAD)
        $status = [ordered]@{
            lastSuccessfulRun = $now.ToString('yyyy-MM-ddTHH:mm:sszzz')
            timezone = 'Asia/Almaty'
            repositoryCommitCountBeforeSnapshot = $commitCount
            automation = 'healthy'
        }
        $status | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $RepoPath 'status.json') -Encoding utf8
        $state.phase = 2
        $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
        git add -- status.json $statePath
        git commit -m "chore: refresh repository health for $day"
    }

    git push origin main
}
finally {
    if ($lock) { $lock.Dispose() }
    Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
}

