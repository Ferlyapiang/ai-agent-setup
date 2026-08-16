$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RootDir

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
        [string]$Path,
        [string]$Key
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return ""
    }

    $line = Get-Content -LiteralPath $Path |
        Where-Object { $_ -match "^\s*$([regex]::Escape($Key))=" } |
        Select-Object -Last 1

    if (-not $line) {
        return ""
    }

    $value = $line -replace "^\s*$([regex]::Escape($Key))=", ""
    return $value.Trim().Trim("'").Trim('"')
}

Write-Info "Checking terminal AI coding agent..."
if (Test-Command "codewhale") {
    Write-Info "CodeWhale command found."
    $agentCommand = "codewhale"
} elseif ((Test-Command "deepseek") -or (Test-Command "deepseek-tui")) {
    Write-Info "DeepSeek-TUI command found."
    $agentCommand = "deepseek"
} else {
    if (-not (Test-Command "npm")) {
        Write-Info "npm is required to install the terminal AI coding agent, but npm was not found."
        Write-Info "Install Node.js/npm first, then rerun this script."
        exit 1
    }

    Write-Info "No supported agent was found. Installing CodeWhale with: npm install -g codewhale"
    Write-Info "DeepSeek-TUI is deprecated upstream; CodeWhale is its recommended replacement."
    npm install -g codewhale
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    $agentCommand = "codewhale"
}

Write-Info "Checking Python document-reading dependencies..."
$pythonCommand = ""
if (Test-Command "python") {
    $pythonCommand = "python"
} elseif (Test-Command "py") {
    $pythonCommand = "py"
}

if (-not $pythonCommand) {
    Write-Info "Python was not found. Install Python, then install document dependencies with:"
    Write-Info "  py -m pip install pandas openpyxl pdfplumber"
} else {
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $pythonCommand -c "import pandas, openpyxl, pdfplumber" *> $null
        $pythonDependencyExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($pythonDependencyExitCode -eq 0) {
        Write-Info "Document-reading Python dependencies are available."
    } else {
        Write-Info "Some document-reading Python dependencies are missing."
        Write-Info "Install them when needed with:"
        Write-Info "  $pythonCommand -m pip install pandas openpyxl pdfplumber"
    }
}

if (-not (Test-Path -LiteralPath "docs-input")) {
    New-Item -ItemType Directory -Path "docs-input" | Out-Null
}

if (-not (Test-Path -LiteralPath "docs-input/.gitkeep")) {
    New-Item -ItemType File -Path "docs-input/.gitkeep" | Out-Null
}

if (-not (Test-Path -LiteralPath ".env")) {
    Copy-Item -LiteralPath ".env.example" -Destination ".env"
    Write-Info ".env was created from .env.example."
    Write-Info "Please fill DEEPSEEK_API_KEY in .env, then rerun this script."
    exit 1
}

$deepseekApiKey = Get-EnvFileValue -Path ".env" -Key "DEEPSEEK_API_KEY"
if (-not $deepseekApiKey) {
    Write-Info ".env exists, but DEEPSEEK_API_KEY is empty."
    Write-Info "Please fill DEEPSEEK_API_KEY in .env, then rerun this script."
    exit 1
}

Write-Info "setup selesai, jalankan: $agentCommand"
