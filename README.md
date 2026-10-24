# Prompteur Epytome

Téléprompteur web pensé pour l'iPad de tournage. Une fois ajouté à l'écran d'accueil, il s'ouvre en plein écran et fonctionne hors ligne.

Adresse : https://epytome-prod.github.io/prompteur/

Les scripts restent dans l'appareil qui les importe. Ce dépôt ne contient que le code de la page, aucun texte ni donnée.

## Mettre à jour

La source unique est `source/prompteur.html`. C'est aussi le contenu de la version publiée sur claude.ai, qui ajoute la synchronisation entre appareils et la télécommande.

1. Modifier `source/prompteur.html`.
2. Lancer `bash source/build.sh ..` : la page, le manifeste, le cache hors ligne et les icônes sont régénérés à la racine.
3. Publier sur `main`. GitHub Pages met le site à jour en une minute, et l'iPad récupère la nouvelle version à la prochaine ouverture avec du réseau.
