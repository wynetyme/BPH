# Replacement installer for BPH: bypasses npm/npx entirely for installing skills.
# Requires Git and an internet connection; Node.js is only needed for Ponytail hooks.
# Review all third-party skill files and Ponytail hooks before trusting their execution.
# From repository root: powershell -ExecutionPolicy Bypass -File .\setup-cursor-skills.ps1
param(
    [switch]$SkipPonytail,
    [switch]$SkipUIUX,
    [switch]$SkipRoClicks,
    [switch]$SkipScenario,
    [switch]$SkipTokenSkills
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not installed or is missing from PATH.'
}
$skillsRoot = Join-Path $projectRoot '.cursor\skills'
New-Item -ItemType Directory -Path $skillsRoot -Force | Out-Null
$script:installedCount = 0
$script:missingCount = 0

function Install-SkillsFromGit {
    param([string]$Repository,[string[]]$Names)
    Write-Host "`nDownloading $Repository via Git..." -ForegroundColor Cyan
    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ('bph-skills-' + [guid]::NewGuid().ToString('N'))
    try {
        & git clone --quiet --depth 1 "https://github.com/$Repository.git" $tempPath
        if ($LASTEXITCODE -ne 0) { throw "Git clone failed: $Repository" }
        $candidates = @(Get-ChildItem -LiteralPath $tempPath -Filter 'SKILL.md' -File -Recurse -Force -ErrorAction Stop)
        foreach ($name in $Names) {
            $match = $candidates | Where-Object { $_.Directory.Name -eq $name } | Select-Object -First 1
            if ($null -eq $match) {
                Write-Warning "Not found upstream (skipping): $Repository / $name"
                $script:missingCount++
                continue
            }
            $destination = Join-Path $skillsRoot $name
            if (Test-Path (Join-Path $destination 'SKILL.md')) {
                Write-Host "  Already installed: $name" -ForegroundColor DarkGray
                continue
            }
            if (Test-Path -LiteralPath $destination) {
                Write-Warning "Destination exists but no SKILL.md (skipping): $destination"
                continue
            }
            Copy-Item -LiteralPath $match.Directory.FullName -Destination $destination -Recurse -Force
            if (-not (Test-Path (Join-Path $destination 'SKILL.md'))) { throw "Copy failed: $name" }
            $script:installedCount++
            Write-Host "  Installed: $name" -ForegroundColor Green
        }
    }
    finally {
        if (Test-Path -LiteralPath $tempPath) {
            Remove-Item -LiteralPath $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host 'Installing Cursor Agent Skills with Git (no npx required)' -ForegroundColor Cyan
Install-SkillsFromGit 'TabooHarmony/roblox-brain' @(
    'roblox-luau-types','roblox-luau-patterns','roblox-architecture',
    'roblox-networking','roblox-security','roblox-data','roblox-performance',
    'roblox-gui','roblox-npc-ai','roblox-animation-vfx',
    'roblox-game-design','roblox-monetization','roblox-input'
)
Install-SkillsFromGit 'EL4CTEO/roblox-skills' @(
    'roblox-luau','roblox-testing','roblox-code-review','roblox-data-stores','roblox-studio-mcp'
)
Install-SkillsFromGit 'gamedev-skills/awesome-gamedev-agent-skills' @(
    'tower-defense','card-game','roblox-simulator-economy','game-feel','game-ui-ux'
)
if (-not $SkipScenario) {
    Install-SkillsFromGit 'scenario-labs/skills' @('scenario-roblox-expert','scenario-roblox-performance','scenario-roblox-tooling')
}
if (-not $SkipTokenSkills) {
    Install-SkillsFromGit 'muratcankoylan/Agent-Skills-for-Context-Engineering' @(
        'context-optimization','context-compression','filesystem-context'
    )
    Install-SkillsFromGit 'bm629/agent-skills' @('token-optimization')
}
if (-not $SkipRoClicks) {
    Install-SkillsFromGit 'zriptic/roclicks-skills' @('roblox-ui-maker','roblox-vfx')
}
if (-not $SkipUIUX) {
    Install-SkillsFromGit 'nextlevelbuilder/ui-ux-pro-max-skill' @('ui-ux-pro-max')
    Write-Warning 'UI/UX Pro Max data/CLI may require its upstream full installer; skill-folder copy alone is not always sufficient.'
}
if (-not $SkipPonytail) {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Warning 'Ponytail skipped: Node.js is required for the Cursor hooks.'
    }
    else {
        $ponytail = Join-Path $projectRoot '.third_party\ponytail'
        $hookFile = Join-Path $ponytail 'scripts\cursor-hooks.js'
        if (-not (Test-Path -LiteralPath $hookFile)) {
            New-Item -ItemType Directory -Path (Split-Path $ponytail) -Force | Out-Null
            & git clone --quiet --depth 1 https://github.com/DietrichGebert/ponytail.git $ponytail
            if ($LASTEXITCODE -ne 0) { throw 'Could not clone Ponytail.' }
        }
        if (-not (Test-Path -LiteralPath $hookFile)) {
            Write-Warning 'Ponytail hook installer is missing upstream. Skipping Ponytail.'
        }
        else {
            $hooksConfig = Join-Path $projectRoot '.cursor\hooks.json'
            if (Test-Path -LiteralPath $hooksConfig) {
                $backupPath = "$hooksConfig.bak-before-ponytail"
                if (-not (Test-Path -LiteralPath $backupPath)) {
                    Copy-Item -LiteralPath $hooksConfig -Destination $backupPath
                }
            }
            Write-Host "`nInstalling Ponytail Cursor hooks..." -ForegroundColor Cyan
            & node $hookFile install --project
            if ($LASTEXITCODE -ne 0) { throw 'Ponytail hooks failed to install.' }
        }
    }
}
Write-Host "`nCompleted. New skills: $script:installedCount; missing upstream names: $script:missingCount" -ForegroundColor Green
Write-Host 'Verify folders with: Get-ChildItem .\.cursor\skills -Directory' -ForegroundColor Green
Write-Host 'Restart Cursor, check Studio MCP, then use prompts/00-verify-environment.txt.' -ForegroundColor Green
