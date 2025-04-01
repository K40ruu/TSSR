Param(
    [Parameter(Mandatory = $true)]
    [string]$CsvUrl,

    [Parameter(Mandatory = $true)]
    [string]$TargetOU,

    [switch]$DryRun
)

# Charger le module AD
Import-Module ActiveDirectory

# Télécharger le fichier CSV depuis GitHub (ou autre URL)
$TempCsvPath = "$env:TEMP\import-users.csv"
Write-Host "[INFO] Téléchargement du fichier CSV depuis : $CsvUrl"
Invoke-WebRequest -Uri $CsvUrl -OutFile $TempCsvPath -UseBasicParsing

# Importer les données depuis le CSV
$users = Import-Csv -Path $TempCsvPath -Delimiter ";"

# Vérifier la validité des colonnes requises
$requiredColumns = @("first_name", "last_name", "password")
foreach ($col in $requiredColumns) {
    if (-not ($users | Get-Member -Name $col)) {
        Write-Error "[ERREUR] La colonne '$col' est manquante dans le fichier CSV. Vérifie ton fichier."
        exit 1
    }
}

# Initialiser les compteurs
$successCount = 0
$failCount = 0

# Parcourir chaque ligne du CSV
foreach ($user in $users) {
    $prenom = $user.first_name
    $nom = $user.last_name
    $password = $user.password

    # Générer automatiquement le nom d'utilisateur
    $username = ($prenom.Substring(0,1) + $nom).ToLower()

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

        Write-Host "[OK] $prenom $nom ($username) créé avec succès." -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "[ERREUR] Impossible de créer $prenom $nom → $_" -ForegroundColor Red
        $failCount++
    }
}

# Résumé
Write-Host "`n=========== RÉSUMÉ ===========" -ForegroundColor Cyan
Write-Host "✔️ Utilisateurs créés : $successCount" -ForegroundColor Green
Write-Host "❌ Échecs de création : $failCount" -ForegroundColor Red
