# Sources 3D du projet

## `../mobilier.blend`
Le meuble, les coffres, le morceau de clé, l'ancienne silhouette du rôdeur.
Tout y est rangé **par pièce** (collections `Entree`, `Cuisine`, `EtageDressing`…).

> **Piège :** exporter une collection ne prend pas ses sous-collections. Il faut
> descendre l'arbre, sinon l'export réussit en silence et produit un fichier
> **vide**. Vérifier le nombre d'objets exportés avant de continuer.

## `Meshy_AI_pixellabs_voodoo_doll_biped.zip`
Le pantin qui incarne les rôdeurs, généré sur Meshy. Le zip contient quatre
fichiers qui embarquent chacun une copie du maillage : le personnage seul et
trois animations (*Walking*, *Running*, *Alert*).

`../rodeur_perso.glb` en est la fusion : **un seul** maillage portant les trois
animations renommées **Marche / Course / Guet**, avec trois teintes sombres
réparties par zones du corps (corps / tête et avant-bras / mains et orteils).

**Ce zip est la seule source du personnage** — il n'existe pas dans le fichier
Blender. Sans lui, impossible de retoucher ses animations.

### Ce qu'il a fallu corriger à l'import
- Il regarde vers **+Z** alors que le manoir attend des personnages vers **-Z**.
- Ses animations n'arrivent **pas en boucle**.
- Il mesure **1,70 m** ; il est ramené à **0,9** dans le jeu (1,53 m).
- Ses bras s'écartent à **0,66 m** de son axe : c'est ce qui fixe la largeur
  des portes et la marge de navigation.
