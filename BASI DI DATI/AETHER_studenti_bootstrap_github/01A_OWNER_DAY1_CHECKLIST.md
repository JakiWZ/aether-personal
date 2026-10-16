# OWNER — Day 1 Checklist

## Prima del bootstrap
- [ ] Organization creata da uno studente
- [ ] 3 Owner studenti
- [ ] roster/students.csv compilato
- [ ] Git installato
- [ ] GitHub CLI installata
- [ ] `gh auth login` completato
- [ ] `gh auth refresh -h github.com -s admin:org -s project` completato

## Comandi
```powershell
.\scripts\01_invite_students.ps1 -Org "<ORG>"

.\scripts\02_bootstrap_aether.ps1 `
  -Org "<ORG>" `
  -Repo "aether-platform" `
  -Visibility "public" `
  -Sprint1Start "<YYYY-MM-DD>"
```

## Dopo
- [ ] studenti hanno accettato inviti
- [ ] team popolati
- [ ] Project creato
- [ ] vista Board raggruppata per Stage
- [ ] Auto-add workflow abilitato
- [ ] prima PR di prova completata
