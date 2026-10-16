param(
    [Parameter(Mandatory=$true)]
    [string]$Org,

    [string]$Roster = "$PSScriptRoot\..\roster\students.csv"
)

$ErrorActionPreference = "Stop"

function Require-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Comando '$name' non trovato. Installarlo prima di continuare."
    }
}

Require-Command "gh"

Write-Host "== AETHER / Invito studenti ==" -ForegroundColor Cyan
gh auth status
if ($LASTEXITCODE -ne 0) {
    throw "Eseguire prima: gh auth login"
}

Write-Host "Verifico accesso all'Organization $Org..."
gh api "orgs/$Org" --silent
if ($LASTEXITCODE -ne 0) {
    throw "Organization '$Org' non accessibile. Deve essere già stata creata e l'utente corrente deve essere Owner."
}

$students = Import-Csv $Roster
$valid = $students | Where-Object { $_.github_username -and $_.github_username.Trim() -ne "" }

if ($valid.Count -eq 0) {
    throw "Nessuno username presente in $Roster. Compilare prima il CSV."
}

foreach ($s in $valid) {
    $u = $s.github_username.Trim()
    Write-Host "Invito $u ..."
    try {
        gh api --method PUT "orgs/$Org/memberships/$u" -f role=member --silent
        Write-Host "  OK" -ForegroundColor Green
    }
    catch {
        Write-Warning "  Invito non completato per $u : $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Inviti inviati." -ForegroundColor Green
Write-Host "Ora gli studenti devono ACCETTARE l'invito."
Write-Host "Quando hanno accettato, promuovere manualmente altri due studenti a Organization Owner."
Write-Host "Poi eseguire 02_bootstrap_aether.ps1."
