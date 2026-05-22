# push_to_github.ps1
# Automates setting origin, committing, and pushing to your GitHub repo.
# Usage: Open PowerShell in the project folder and run:
#   powershell -ExecutionPolicy Bypass -File .\push_to_github.ps1

$repoUrl = 'https://github.com/phyopyaesone-p/TravelWebsite.git'
Write-Host "Setting origin to $repoUrl"
git remote set-url origin $repoUrl
git remote -v

# Ensure branch
$branch = git branch --show-current 2>$null
if ([string]::IsNullOrWhiteSpace($branch)) {
    Write-Host "No current branch detected — creating 'main'"
    git branch -M main
    $branch = 'main'
} else {
    $branch = $branch.Trim()
    git branch -M $branch
}

# Configure identity
git config user.name "Phyo"
git config user.email "phyopyaesone187@gmail.com"

# Stage and commit
git add -A
git commit -m "Initial commit" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "No new changes to commit or commit failed (continuing)."
}

# Attempt to push
Write-Host "Pushing to origin/$branch..."
$pushOutput = git push -u origin $branch 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Push succeeded."; exit 0
}

Write-Host "Push failed. Output:"
Write-Host $pushOutput

$tryPat = Read-Host "Push failed — try pushing with a Personal Access Token? (Y/N)"
if ($tryPat -ne 'Y' -and $tryPat -ne 'y') { Write-Host "Aborting."; exit 1 }

$ghUser = Read-Host "GitHub username (e.g. phyopyaesone-p)"
$securePAT = Read-Host "Enter GitHub Personal Access Token (input hidden)" -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePAT)
$pat = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

$tempUrl = "https://$ghUser:$pat@github.com/phyopyaesone-p/TravelWebsite.git"
Write-Host "Setting temporary origin with token and pushing..."
git remote set-url origin $tempUrl
$pushOutput2 = git push -u origin $branch 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Push succeeded using PAT. Restoring origin URL."
    git remote set-url origin $repoUrl
    $pat = $null
    exit 0
}

Write-Host "Push still failed. Output:"
Write-Host $pushOutput2
Write-Host "Restoring original origin URL."
git remote set-url origin $repoUrl
$pat = $null
exit 1
