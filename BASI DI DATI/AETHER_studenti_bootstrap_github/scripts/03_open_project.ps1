param(
    [Parameter(Mandatory=$true)]
    [string]$Org
)

$title = "AETHER Delivery Board"
$n = gh project list --owner $Org --format json --jq ".projects[] | select(.title==`"$title`") | .number"
if (-not $n) {
    throw "Project '$title' non trovato."
}
gh project view $n --owner $Org --web
