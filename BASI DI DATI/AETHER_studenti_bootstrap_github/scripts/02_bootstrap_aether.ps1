param(
    [Parameter(Mandatory=$true)]
    [string]$Org,

    [string]$Repo = "aether-platform",

    [ValidateSet("public","private")]
    [string]$Visibility = "public",

    [Parameter(Mandatory=$true)]
    [datetime]$Sprint1Start,

    [string]$Roster = "$PSScriptRoot\..\roster\students.csv",

    [string]$Backlog = "$PSScriptRoot\..\backlog\aether_backlog.json"
)

$ErrorActionPreference = "Stop"
$ProjectTitle = "AETHER Delivery Board"

function Require-Command($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Comando '$name' non trovato."
    }
}

function Gh-Ok {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
    & gh @Args
    return ($LASTEXITCODE -eq 0)
}

function Ensure-Label($name, $color, $description) {
    & gh label create $name -R "$Org/$Repo" --color $color --description $description --force | Out-Null
}

function Ensure-Team($name) {
    $slug = $name.ToLower()
    & gh api "orgs/$Org/teams/$slug" --silent 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creo team $name ..."
        & gh api --method POST "orgs/$Org/teams" -f "name=$name" -f "privacy=closed" --silent
        if ($LASTEXITCODE -ne 0) { throw "Impossibile creare team $name" }
    }
    return $slug
}

function Ensure-ProjectField($projectNumber, $name, $options) {
    $existing = & gh project field-list $projectNumber --owner $Org --format json --jq ".fields[] | select(.name==`"$name`") | .name"
    if (-not $existing) {
        Write-Host "Creo campo Project: $name"
        & gh project field-create $projectNumber --owner $Org --name $name --data-type SINGLE_SELECT --single-select-options $options | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Impossibile creare campo $name" }
    }
}

function Set-ProjectValue($projectNumber, $url, $field, $value) {
    if (-not $value) { return }
    & gh project item-edit $projectNumber --owner $Org --url $url --field $field --value $value 2>$null | Out-Null
}

Require-Command "gh"
Require-Command "git"

Write-Host "== AETHER / Bootstrap completo ==" -ForegroundColor Cyan

& gh auth status
if ($LASTEXITCODE -ne 0) { throw "Eseguire prima gh auth login" }

Write-Host "Verifica scope consigliati: admin:org + project"
Write-Host "Se necessario: gh auth refresh -h github.com -s admin:org -s project"

& gh api "orgs/$Org" --silent
if ($LASTEXITCODE -ne 0) { throw "Organization non accessibile: $Org" }

# 1. Repository
& gh repo view "$Org/$Repo" --json name 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creo repository $Org/$Repo ($Visibility)..."
    if ($Visibility -eq "public") {
        & gh repo create "$Org/$Repo" --public --description "AETHER Mars Operations Platform - Full Stack Capstone" --add-readme
    } else {
        & gh repo create "$Org/$Repo" --private --description "AETHER Mars Operations Platform - Full Stack Capstone" --add-readme
    }
    if ($LASTEXITCODE -ne 0) { throw "Creazione repository fallita." }
} else {
    Write-Host "Repository già esistente."
}

# 2. Teams + memberships
$teamNames = @("ARES","PHOENIX","TITAN","ORION","HELIOS")
$teamSlugs = @{}
foreach ($t in $teamNames) {
    $slug = Ensure-Team $t
    $teamSlugs[$t] = $slug

    # team -> repository write permission
    & gh api --method PUT "orgs/$Org/teams/$slug/repos/$Org/$Repo" -f "permission=push" --silent 2>$null
}

$students = Import-Csv $Roster | Where-Object { $_.github_username -and $_.github_username.Trim() -ne "" }

foreach ($s in $students) {
    $u = $s.github_username.Trim()
    $squad = $s.squad.Trim().ToUpper()
    if (-not $teamSlugs.ContainsKey($squad)) {
        Write-Warning "$u ha squad non valida '$squad'. Saltato."
        continue
    }

    $state = & gh api "orgs/$Org/memberships/$u" --jq ".state" 2>$null
    if ($LASTEXITCODE -ne 0 -or $state -ne "active") {
        Write-Warning "$u non ha ancora accettato l'invito. Rilanciare lo script più tardi."
        continue
    }

    $slug = $teamSlugs[$squad]
    $role = if ($s.team_role -eq "maintainer") { "maintainer" } else { "member" }
    Write-Host "Team $squad <- $u ($role)"
    & gh api --method PUT "orgs/$Org/teams/$slug/memberships/$u" -f "role=$role" --silent
}

# 3. Copy repository template
$tmp = Join-Path $env:TEMP ("aether-bootstrap-" + [guid]::NewGuid().ToString())
Write-Host "Clono repository temporaneamente..."
& gh repo clone "$Org/$Repo" $tmp -- --quiet
if ($LASTEXITCODE -ne 0) { throw "Clone fallito." }

$template = Resolve-Path "$PSScriptRoot\..\repo-template"
Get-ChildItem $template -Force | ForEach-Object {
    Copy-Item $_.FullName -Destination $tmp -Recurse -Force
}

Push-Location $tmp
try {
    $login = & gh api user --jq ".login"
    & git config user.name $login
    & git config user.email "$login@users.noreply.github.com"
    & git add .
    $changes = & git status --porcelain
    if ($changes) {
        & git commit -m "chore: bootstrap AETHER class project"
        & git push origin main
        if ($LASTEXITCODE -ne 0) { throw "Push template fallito." }
    } else {
        Write-Host "Template repository già aggiornato."
    }
}
finally {
    Pop-Location
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# 4. Repository settings
& gh api --method PATCH "repos/$Org/$Repo" `
    -F has_issues=true `
    -F has_projects=true `
    -F delete_branch_on_merge=true `
    -F allow_squash_merge=true `
    -F allow_merge_commit=false `
    -F allow_rebase_merge=false `
    --silent

# 5. Labels
$labels = @(
    @("type:epic","6f42c1","Epic"),
    @("type:story","1d76db","User Story"),
    @("type:task","5319e7","Technical Task"),
    @("type:bug","d73a4a","Bug"),
    @("type:spike","bfdadc","Spike / research"),
    @("type:change-request","fbca04","Change Request"),
    @("priority:critical","b60205","Critical"),
    @("priority:high","d93f0b","High"),
    @("priority:medium","fbca04","Medium"),
    @("priority:low","0e8a16","Low"),
    @("squad:ares","0052cc","ARES"),
    @("squad:phoenix","c2e0c6","PHOENIX"),
    @("squad:titan","7057ff","TITAN"),
    @("squad:orion","006b75","ORION"),
    @("squad:helios","e99695","HELIOS"),
    @("squad:cross","ededed","Cross-squad"),
    @("area:db","0e8a16","Database"),
    @("area:backend","5319e7","Backend"),
    @("area:frontend","1d76db","Frontend"),
    @("area:integration","c5def5","Integration"),
    @("area:devops","006b75","DevOps"),
    @("area:documentation","d4c5f9","Documentation"),
    @("area:qa","bfdadc","QA"),
    @("area:analysis","f9d0c4","Analysis"),
    @("area:full-stack","c2e0c6","Full Stack"),
    @("area:big-data","7057ff","Big Data")
)
foreach ($l in $labels) { Ensure-Label $l[0] $l[1] $l[2] }

# 6. Milestones
$milestoneNumbers = @{}
for ($i=1; $i -le 3; $i++) {
    $title = "Sprint $i"
    $start = $Sprint1Start.AddDays(7 * ($i-1))
    $due = $start.AddDays(4)
    $all = & gh api "repos/$Org/$Repo/milestones?state=all&per_page=100" | ConvertFrom-Json
    $m = $all | Where-Object { $_.title -eq $title } | Select-Object -First 1
    if (-not $m) {
        Write-Host "Creo milestone $title ($($start.ToString('yyyy-MM-dd')) -> $($due.ToString('yyyy-MM-dd')))"
        $created = & gh api --method POST "repos/$Org/$Repo/milestones" `
            -f "title=$title" `
            -f "description=$title - AETHER" `
            -f "due_on=$($due.ToString('yyyy-MM-dd'))T23:59:59Z" | ConvertFrom-Json
        $milestoneNumbers[$title] = $created.number
    } else {
        $milestoneNumbers[$title] = $m.number
    }
}

# 7. Project
$projectNumber = & gh project list --owner $Org --format json --jq ".projects[] | select(.title==`"$ProjectTitle`") | .number" 2>$null
if (-not $projectNumber) {
    Write-Host "Creo GitHub Project '$ProjectTitle'..."
    $projectNumber = & gh project create --owner $Org --title $ProjectTitle --format json --jq ".number"
}
$projectNumber = [int]$projectNumber
Write-Host "Project number: $projectNumber"

& gh project edit $projectNumber --owner $Org `
    --description "Scrum board della classe per AETHER Mars Operations Platform" `
    --visibility $(if ($Visibility -eq "public") { "PUBLIC" } else { "PRIVATE" }) | Out-Null

& gh project link $projectNumber --owner $Org --repo $Repo 2>$null | Out-Null

Ensure-ProjectField $projectNumber "Stage" "Backlog,Ready,In Progress,Code Review,Testing,Done"
Ensure-ProjectField $projectNumber "Type" "Epic,Story,Task,Bug,Spike,Change Request"
Ensure-ProjectField $projectNumber "Priority" "Critical,High,Medium,Low"
Ensure-ProjectField $projectNumber "Sprint" "Sprint 1,Sprint 2,Sprint 3,Future"
Ensure-ProjectField $projectNumber "Story Points" "1,2,3,5,8"
Ensure-ProjectField $projectNumber "Squad" "ARES,PHOENIX,TITAN,ORION,HELIOS,CROSS"
Ensure-ProjectField $projectNumber "Area" "Analysis,DB,Backend,Frontend,Full Stack,Integration,DevOps,Documentation,QA,Big Data"

# 8. Seed backlog
$backlogItems = Get-Content $Backlog -Raw | ConvertFrom-Json
$existingIssues = & gh issue list -R "$Org/$Repo" --state all --limit 500 --json title,url | ConvertFrom-Json

foreach ($item in $backlogItems) {
    $existing = $existingIssues | Where-Object { $_.title -eq $item.title } | Select-Object -First 1

    if ($existing) {
        $url = $existing.url
        Write-Host "Esiste: $($item.key)"
    } else {
        $labelsForIssue = @(
            "type:$($item.type.ToLower())",
            "priority:$($item.priority.ToLower())",
            "squad:$($item.squad.ToLower())",
            "area:$($item.area.ToLower().Replace(' ','-'))"
        )

        $args = @("issue","create","-R","$Org/$Repo","--title",$item.title,"--body",$item.body)
        foreach ($lab in $labelsForIssue) { $args += @("--label",$lab) }

        if ($item.sprint -match "^Sprint [123]$") {
            $args += @("--milestone",$item.sprint)
        }

        $url = & gh @args
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Issue fallita: $($item.title)"
            continue
        }
    }

    & gh project item-add $projectNumber --owner $Org --url $url 2>$null | Out-Null
    Set-ProjectValue $projectNumber $url "Stage" "Backlog"
    Set-ProjectValue $projectNumber $url "Type" $item.type
    Set-ProjectValue $projectNumber $url "Priority" $item.priority
    Set-ProjectValue $projectNumber $url "Sprint" $item.sprint
    Set-ProjectValue $projectNumber $url "Story Points" $item.points
    Set-ProjectValue $projectNumber $url "Squad" $item.squad
    Set-ProjectValue $projectNumber $url "Area" $item.area
}

# 9. Protect main if public
if ($Visibility -eq "public") {
    Write-Host "Configuro protezione branch main..."
    $protection = @{
        required_status_checks = $null
        enforce_admins = $false
        required_pull_request_reviews = @{
            dismiss_stale_reviews = $true
            require_code_owner_reviews = $false
            required_approving_review_count = 1
        }
        restrictions = $null
        required_conversation_resolution = $true
        allow_force_pushes = $false
        allow_deletions = $false
    } | ConvertTo-Json -Depth 5

    $jsonFile = Join-Path $env:TEMP "aether-branch-protection.json"
    $protection | Out-File $jsonFile -Encoding utf8

    & gh api --method PUT `
        -H "Accept: application/vnd.github+json" `
        "repos/$Org/$Repo/branches/main/protection" `
        --input $jsonFile 2>$null | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Protezione main non applicata automaticamente. Configurarla dalla UI."
    }
    Remove-Item $jsonFile -ErrorAction SilentlyContinue
} else {
    Write-Warning "Repository private su piano Free: la protezione main potrebbe richiedere un piano superiore. Applicare almeno la regola organizzativa 'PR prima del merge' come convenzione didattica."
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "AETHER BOOTSTRAP COMPLETATO" -ForegroundColor Green
Write-Host "Repository: https://github.com/$Org/$Repo"
Write-Host "Project: eseguire:"
Write-Host "  gh project view $projectNumber --owner $Org --web"
Write-Host ""
Write-Host "ULTIMI 2 PASSI MANUALI:"
Write-Host "1) Nel Project creare una vista Board raggruppata per Stage."
Write-Host "2) Project -> Workflows -> Auto-add to project -> repo $Repo -> filtro is:issue,pr -> Enable."
Write-Host "========================================"
