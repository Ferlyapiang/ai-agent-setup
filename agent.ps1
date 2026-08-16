param(
    [string]$Path = ".",
    [string]$Task = "",
    [ValidateSet("deepseek", "openrouter", "ollama")]
    [string]$Provider = "deepseek",
    [string]$Model = "",
    [switch]$NoBootstrap,
    [switch]$Interactive,
    [switch]$InstallLocalSkills
)

$ErrorActionPreference = "Stop"

$SetupRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetPath = Resolve-Path -LiteralPath $Path
$TargetRoot = $TargetPath.Path

function Write-Info {
    param([string]$Message)
    Write-Host $Message
}

function Test-Command {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-EnvFileValue {
    param(
        [string]$FilePath,
        [string]$Key
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        return ""
    }

    $line = Get-Content -LiteralPath $FilePath |
        Where-Object { $_ -match "^\s*$([regex]::Escape($Key))=" } |
        Select-Object -Last 1

    if (-not $line) {
        return ""
    }

    $value = $line -replace "^\s*$([regex]::Escape($Key))=", ""
    return $value.Trim().Trim("'").Trim('"')
}

function Ensure-Directory {
    param([string]$DirectoryPath)

    if (-not (Test-Path -LiteralPath $DirectoryPath)) {
        New-Item -ItemType Directory -Path $DirectoryPath | Out-Null
    }
}

function Ensure-GitIgnoreBlock {
    param(
        [string]$RepoRoot,
        [bool]$IgnoreDeepseek = $false
    )

    $gitIgnorePath = Join-Path $RepoRoot ".gitignore"
    $rules = @(
        "# AI agent local files",
        ".env",
        ".env.*",
        "!.env.example",
        "docs-input/*",
        "!docs-input/.gitkeep",
        ".codewhale/state/"
    )

    if ($IgnoreDeepseek) {
        $rules += ".deepseek/"
    }

    if (-not (Test-Path -LiteralPath $gitIgnorePath)) {
        Set-Content -LiteralPath $gitIgnorePath -Value ($rules -join [Environment]::NewLine)
        return
    }

    $currentLines = Get-Content -LiteralPath $gitIgnorePath
    $missingRules = @()
    foreach ($rule in $rules) {
        if ($currentLines -notcontains $rule) {
            $missingRules += $rule
        }
    }

    if ($missingRules.Count -gt 0) {
        Add-Content -LiteralPath $gitIgnorePath -Value ""
        Add-Content -LiteralPath $gitIgnorePath -Value $missingRules
    }
}

function Copy-DirectoryIfMissing {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Destination)) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Recurse
        Write-Info "Copied: $Destination"
    } else {
        Write-Info "Already exists, skipped: $Destination"
    }
}

function Copy-FileIfMissing {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Destination)) {
        Copy-Item -LiteralPath $Source -Destination $Destination
        Write-Info "Copied: $Destination"
    } else {
        Write-Info "Already exists, skipped: $Destination"
    }
}

if (-not (Test-Command "codewhale")) {
    Write-Info "CodeWhale command was not found."
    Write-Info "Run setup first:"
    Write-Info "  $SetupRoot\setup.ps1"
    exit 1
}

$setupEnvPath = Join-Path $SetupRoot ".env"
$deepseekApiKey = Get-EnvFileValue -FilePath $setupEnvPath -Key "DEEPSEEK_API_KEY"
if ($deepseekApiKey) {
    $env:DEEPSEEK_API_KEY = $deepseekApiKey
}
$openRouterApiKey = Get-EnvFileValue -FilePath $setupEnvPath -Key "OPENROUTER_API_KEY"
if ($openRouterApiKey) {
    $env:OPENROUTER_API_KEY = $openRouterApiKey
}

if ($Provider -eq "deepseek" -and (-not $env:DEEPSEEK_API_KEY)) {
    Write-Info "DEEPSEEK_API_KEY is empty. Fill it in .env or choose another provider."
    exit 1
}

if ($Provider -eq "openrouter" -and (-not $env:OPENROUTER_API_KEY)) {
    Write-Info "OPENROUTER_API_KEY is empty. Fill it in .env or choose another provider."
    Write-Info "For temporary testing, you can use OpenRouter free models after creating an API key."
    exit 1
}

$env:CODEWHALE_PROVIDER = $Provider

if ((-not $Model) -and $Provider -eq "openrouter") {
    $Model = "openrouter/free"
}

if (-not $NoBootstrap) {
    Write-Info "Preparing AI agent files in: $TargetRoot"

    if ($InstallLocalSkills) {
        $sourceDeepseek = Join-Path $SetupRoot ".deepseek"
        $targetDeepseek = Join-Path $TargetRoot ".deepseek"
        if (Test-Path -LiteralPath $sourceDeepseek) {
            Ensure-Directory -DirectoryPath $targetDeepseek

            $sourceSkills = Join-Path $sourceDeepseek "skills"
            $targetSkills = Join-Path $targetDeepseek "skills"
            Ensure-Directory -DirectoryPath $targetSkills

            if (Test-Path -LiteralPath $sourceSkills) {
                Get-ChildItem -LiteralPath $sourceSkills -Directory | ForEach-Object {
                    $destinationSkill = Join-Path $targetSkills $_.Name
                    Copy-DirectoryIfMissing -Source $_.FullName -Destination $destinationSkill
                }
            }

            $sourceMcp = Join-Path $sourceDeepseek "mcp.json"
            $targetMcp = Join-Path $targetDeepseek "mcp.json"
            if (Test-Path -LiteralPath $sourceMcp) {
                Copy-FileIfMissing -Source $sourceMcp -Destination $targetMcp
            }
        }
    } else {
        Write-Info "Using skills from setup repo; not copying .deepseek into target."
    }

    $docsInput = Join-Path $TargetRoot "docs-input"
    Ensure-Directory -DirectoryPath $docsInput

    $gitKeep = Join-Path $docsInput ".gitkeep"
    if (-not (Test-Path -LiteralPath $gitKeep)) {
        New-Item -ItemType File -Path $gitKeep | Out-Null
    }

    $ignoreDeepseekInTarget = ($TargetRoot -ne (Resolve-Path -LiteralPath $SetupRoot).Path)
    Ensure-GitIgnoreBlock -RepoRoot $TargetRoot -IgnoreDeepseek:$ignoreDeepseekInTarget
}

Set-Location $TargetRoot

$setupSkillsPath = Join-Path $SetupRoot ".deepseek\skills"
$setupMcpPath = Join-Path $SetupRoot ".deepseek\mcp.json"
$localSkillsPath = Join-Path $TargetRoot ".deepseek\skills"
$localMcpPath = Join-Path $TargetRoot ".deepseek\mcp.json"

if ($InstallLocalSkills -and (Test-Path -LiteralPath $localSkillsPath)) {
    $env:CODEWHALE_SKILLS_DIR = $localSkillsPath
} elseif (Test-Path -LiteralPath $setupSkillsPath) {
    $env:CODEWHALE_SKILLS_DIR = $setupSkillsPath
}

if ($InstallLocalSkills -and (Test-Path -LiteralPath $localMcpPath)) {
    $env:CODEWHALE_MCP_CONFIG = $localMcpPath
} elseif (Test-Path -LiteralPath $setupMcpPath) {
    $env:CODEWHALE_MCP_CONFIG = $setupMcpPath
}

$defaultTask = @"
Jawab selalu dalam Bahasa Indonesia kecuali untuk nama file, command, error, dan istilah teknis.
Saya sudah masuk ke folder repo ini.
Baca repo ini terlebih dahulu. Mulai dari README.md dan file instruksi di .deepseek/skills jika ada.
Gunakan skill project-conventions sebagai aturan kerja default jika tersedia.
Scan struktur folder, deteksi bahasa/framework/tools, jelaskan cara menjalankan project,
cara test/build jika tersedia, risiko penting, dan rekomendasi langkah berikutnya.
Jangan mengedit file apa pun dulu sebelum saya minta.
"@

if (-not $Task) {
    $Task = $defaultTask
}

Write-Info "Running CodeWhale in: $TargetRoot"
Write-Info "Provider: $Provider"
if ($Model) {
    Write-Info "Model: $Model"
}
if ($env:CODEWHALE_SKILLS_DIR) {
    Write-Info "Using skills dir: $env:CODEWHALE_SKILLS_DIR"
}
Write-Info ""

if ($Interactive) {
    Write-Info "Interactive mode. Paste this prompt into CodeWhale:"
    Write-Info ""
    Write-Info $Task
    Write-Info ""
    if ($Model) {
        codewhale --provider $Provider --model $Model
    } else {
        codewhale --provider $Provider
    }
} else {
    if ($Model) {
        codewhale --provider $Provider --model $Model -p $Task
    } else {
        codewhale --provider $Provider -p $Task
    }
}
