# Daily Dev Log

An automated, transparent activity journal for maintaining a small daily development habit.

Each scheduled run creates exactly two commits:

1. a dated pulse entry in `logs/YYYY-MM.md`;
2. a refreshed repository health snapshot in `status.json`.

The automation is idempotent: rerunning it on the same Almaty calendar day does not create duplicate commits.

## Run manually

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\daily-update.ps1 -RepoPath $PWD
```

