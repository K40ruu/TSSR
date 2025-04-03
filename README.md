# 🛠️ Script de Post-Installation Debian – TSSR

Ce script Bash est conçu pour automatiser la configuration initiale d’un système Debian fraîchement installé. Il est utilisé dans le cadre de ma formation TSSR (Technicien Supérieur Systèmes et Réseaux) pour accélérer et fiabiliser le déploiement d’un environnement de travail de base.

---

## 🎯 Objectifs

- Mettre à jour le système
- Installer une liste de paquets utiles
- Appliquer des configurations utilisateur (bashrc, nanorc)
- Ajouter un `motd` personnalisé
- Sécuriser le SSH (authentification par clé uniquement)
- Proposer d'ajouter une clé SSH publique automatiquement
- Générer un fichier de log détaillé

---

## 📁 Structure du projet

```bash
.
├── postinstall.sh              # Script principal
├── README.md                   # Ce fichier
├── config/                     # Fichiers de config à appliquer
│   ├── bashrc.append
│   ├── nanorc.append
│   └── motd.txt
└── lists/
    └── packages.txt            # Liste des paquets à installer
