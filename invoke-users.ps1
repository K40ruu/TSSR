@'
Param(
    [Parameter(Mandatory = $true)]
    [string]$CsvUrl,

    [Parameter(Mandatory = $true)]
    [string]$TargetOU,

    [switch]$DryRun
)

Import-Module ActiveDirectory

$TempCsvPath = "$env:TEMP\import-users.csv"
Invoke-WebRequest -Uri $CsvUrl -OutFile $TempCsvPath -UseBasicParsing

$users = Import-Csv -Path $TempCsvPath -Delimiter ";"

$requiredColumns = @("first_name", "last_name", "username", "password")
foreach ($col in $requiredColumns) {
    if (-not ($users | Get-Member -Name $col)) {
        Write-Error "Colonne '$col' manquante dans le CSV."
        exit 1
    }
}

$successCount = 0
$failCount = 0

foreach ($user in $users) {
    $prenom = $user.first_name
    $nom = $user.last_name
    $username = $user.username
    $password = $user.password

    if ($DryRun) {
        Write-Host "[DRY-RUN] $prenom $nom → $username (compte non créé)" -ForegroundColor Yellow
        continue
    }

    try {
        New-ADUser `
            -Name "$prenom $nom" `
            -SamAccountName $username `
            -GivenName $prenom `
            -Surname $nom `
            -UserPrincipalName "$username@$(($env:USERDNSDOMAIN -replace '\.$',''))" `
            -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
            -Enabled $true `
            -Path $TargetOU

        Write-Host "[OK] $prenom $nom ($username) créé." -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "[ERREUR] $prenom $nom → $_" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "=========== RÉSUMÉ ===========" -ForegroundColor Cyan
Write-Host "Utilisateurs créés : $successCount" -ForegroundColor Green
Write-Host "Erreurs rencontrées : $failCount" -ForegroundColor Red
'@ | Set-Content -Path "$env:TEMP\invoke-users.ps1" -Encoding ASCII
