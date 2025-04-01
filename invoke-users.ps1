Param(
    [string]$CsvPath,
    [string]$TargetOU
)

Import-Module ActiveDirectory

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

        Write-Host "Créé : $prenom $nom ($username)"
    } catch {
        Write-Host "Erreur : $prenom $nom"
    }
}
