Param(
    [string]$CsvUrl,
    [string]$TargetOU
)

Import-Module ActiveDirectory

# Télécharger le CSV
$CsvPath = "$env:TEMP\users.csv"
Invoke-WebRequest -Uri $CsvUrl -OutFile $CsvPath -UseBasicParsing

# Lire les données
$users = Import-Csv -Path $CsvPath -Delimiter ";"

foreach ($user in $users) {
    $prenom = $user.first_name
    $nom = $user.last_name
    $username = $user.username
    $password = $user.password

    try {
        New-ADUser `
            -Name "$prenom $nom" `
            -SamAccountName $username `
            -GivenName $prenom `
            -Surname $nom `
            -UserPrincipalName "$username@domaine.lan" `
            -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
            -Enabled $true `
            -Path $TargetOU

    }
}
