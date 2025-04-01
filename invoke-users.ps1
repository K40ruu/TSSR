Param(
    [Parameter(Mandatory = $true)]
    [string]$CsvUrl,

    [Parameter(Mandatory = $true)]
    [string]$TargetOU,

    [switch]$DryRun
)

Import-Module ActiveDirectory

# Télécharger le CSV
$TempCsvPath = "$env:TEMP\import-users.csv"
Write-Host "[INFO] Téléchargement depuis : $CsvUrl"
Invoke-WebRequest -Uri $CsvUrl -OutFile $TempCsvPath -UseBasicParsing

# Importer les utilisateurs
$users = Import-Csv -Path $TempCsvPath -Delimiter ";"

# Vérifier que les colonnes existent
$requiredColumns = @("first_name", "last_name", "username", "password")
foreach ($col in $requiredColumns) {
    if (-not ($users | Get-Member -Name $col)) {
        Write-Error "[ERREUR] La colonne '$col' est manquante dans le fichier CSV."
        exit 1
    }
}

# Stats
$successCount = 0
$failCount = 0

# Boucle principale
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

# Résumé
Write-Host "`n=========== RÉSUMÉ ===========" -ForegroundColor Cyan
Write-Host "✔️ Utilisateurs créés : $successCount" -ForegroundColor Green
Write-Host "❌ Échecs : $failCount" -ForegroundColor Red
