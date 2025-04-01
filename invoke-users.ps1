Import-Module ActiveDirectory

# Spécifiez le chemin du fichier CSV contenant les utilisateurs
$csvFile = "C:\chemin\vers\votre\fichier.csv"

# Spécifiez le chemin complet de l'unité d'organisation (OU) dans laquelle vous voulez créer les utilisateurs
$ouPath = "OU=entreprise,DC=inwaves,DC=lan"

# Spécifiez le nom de domaine du contrôleur de domaine (DC) sur lequel vous souhaitez créer les utilisateurs
$domainController = "inwaves.lan"

# Importez les données du fichier CSV en spécifiant le délimiteur de point-virgule
$users = Import-Csv $csvFile -Delimiter ";"

# Parcourez chaque utilisateur dans la liste et créez-les dans Active Directory
foreach ($user in $users) {
    # Définissez les attributs de l'utilisateur à partir des données du fichier CSV
    $nom = $user.Nom
    $prenom = $user.Prenom
    $username = $user.UserName
    $password = $user.Password

    # Créez le compte utilisateur dans Active Directory en spécifiant le chemin et le contrôleur de domaine
    New-ADUser -Name "$prenom $nom" -SamAccountName $username -GivenName $prenom -Surname $nom `
    -UserPrincipalName $username -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
    -Enabled $true -Path $ouPath -Server $domainController
}
