# PROJET_CONTEXTE.md

> À lire en premier à chaque session, avant toute action.
> Nom de travail : **Manoir** (changé le 16/07/2026 — la maison est appelée à grandir).

## STATUT — fait foi pour les statuts (lu par Pilotage)

```
STATUT DU PROJET : En développement
MISSION : Manoir, du pavillon au manoir (jets 7 à 12) — Close
MISSION : Les trois pistes (jets 13 à 17) — Close
  Étape : Le geste qui expose (jet 13) — Close — critère : ouvrir un coffre ou prendre un objet cloue le joueur 2-3 s à découvert, jamais en se cachant
  Étape : L'étau (jet 14) — Close — critère : un rôdeur qui voit le joueur prévient l'autre, qui rejoint s'il peut arriver utilement
  Étape : Le fil rouge (jets 15 à 17) — Close — critère : noms de pièces visibles en entrant, pièce d'introduction à deux portes, carte au bouton M
MISSION : Quartier cubique — En implémentation
  Étape : (aucune écrite) — contenu de jeu du cube non tranché
IDÉES PARQUÉES :
  - Le son
  - Les textures
  - Les meubles bas franchissables
  - La cave
  - Une course à deux joueurs
  - Générer le manoir au hasard
  - Portage Android
```
*(Bloc ajouté le 2026-10-30, validé par Kinder.)*

## Intention
Un jeu d'évasion en vue première personne. Le joueur se réveille dans un manoir clos qu'il ne connaît pas, sans savoir où il est. Pour sortir, il doit remonter une chaîne : **deux morceaux de clé → le coffre-fort → le badge → la porte rouge** — le tout en évitant **deux rôdeurs** qui traquent dans la pénombre, un par niveau. Des cachettes permettent de les laisser passer.

**Chaque partie est différente** : la sortie, les trois objets à chercher, le point de réveil et le départ de chaque rôdeur sont tirés au sort à chaque lancement.

Tout est construit et validé (voir `BASE.md`) : le jeu se gagne, se perd et se relance.

## Le cap — du pavillon au manoir *(atteint le 16/07/2026)*
La destination était **un manoir sur plusieurs niveaux avec des épreuves qui s'enchaînent**. Les trois grandes étapes sont construites et validées :

- ✅ **A — le rez-de-chaussée grandit** *(jet 7)* : 6 → 9 pièces, une aile est et une galerie en boucle.
- ✅ **B — l'étage et les rôdeurs par niveau** *(jet 8)* : 4 pièces de plus, deux escaliers en boucle verticale, **deux rôdeurs** — chacun chez lui, qui suit le joueur d'un étage à l'autre s'il le voit, et rentre s'il le perd.
- ✅ **C — la chaîne d'objectifs** *(jet 9)* : deux morceaux → coffre-fort → badge → porte rouge.

**Reste du cap d'origine, non construit : la cave.** Elle est prête à recevoir — les niveaux se déduisent de l'altitude des repères, il suffira d'ajouter un rôdeur dans la scène. **Parquée le 20/07/2026 :** pas avant que le fil rouge ait un propos (voir la question ouverte).

**Jet 12 clos le 20/07/2026 — le jeu dit ses règles.** Le panneau d'accueil énonce le but, la chaîne, les commandes et les abris, et devient le point de passage de chaque partie ; une ligne rappelle le but au réveil. **N'importe qui peut désormais y jouer** — jusque-là le jeu n'indiquait nulle part quelles touches appuyer. La victoire, qui ne relançait rien depuis toujours, relance enfin. Aucune scène nouvelle, aucune règle touchée. Voir `BASE.md` et `PLAN.md`.

## LA QUESTION OUVERTE — tranchée le 27/07/2026
*(constat de Kinder, 16/07/2026, après la remise en ordre)*

**Le fil rouge est pauvre.** Aujourd'hui : deux morceaux de clé → un badge → la porte rouge. C'était déjà court sur treize pièces ; **sur trois niveaux ce serait creux**. Le manoir aurait de la surface sans avoir de propos.

Deux directions possibles, **une seule à la fois** :
- **La cave** — un troisième niveau, un rôdeur de plus. Ajoute de la surface.
- **Le fil rouge** — enrichir la progression : plus d'étapes, des objets qui se répondent, une raison d'explorer chaque niveau.

**TRANCHÉ le 20/07/2026, après l'audit de profondeur : le fil rouge, et la cave reste parquée.** Une cave posée aujourd'hui ajouterait quatre pièces interchangeables de plus à balayer, et un troisième rôdeur qui ignorerait les deux autres : 30 % de surface pour 0 % de propos.

**TRANCHÉ SUR SON CONTENU le 27/07/2026 : trois pistes** (voir « La réponse » plus bas). Le contenu du chantier, laissé ouvert le 20/07 (*« on l'approfondira après »*), est désormais arrêté. Un second audit a relu le code avant de décider : les six constats ci-dessous tiennent tous, et la cave amplifierait exactement les défauts qu'ils nomment — l'avis « le fil rouge d'abord » est reconfirmé. Le jet 12 avait appris ses règles au joueur sans donner de profondeur au jeu ; ces trois pistes donnent au jeu un **second verbe**.

### Ce que l'audit de profondeur a trouvé *(20/07/2026 — à relire avant d'ouvrir ce chantier)*

Six constats, du plus lourd au plus léger. Le code confirme chacun.

1. **On ne peut pas mourir en courant.** Joueur 4,5 ; rôdeur en poursuite 4,0, jamais plus. En ligne droite il ne rattrape **jamais**. C'est assumé dans `BASE.md` — mais la conséquence ne l'est pas : la mort n'arrive plus que par accident. **La difficulté n'est pas une pression, c'est une malchance.**
2. **Les neuf cachettes sont facultatives.** Suite du point 1 : se cacher coûte du temps, le temps ne coûte rien. Qui a compris qu'il est le plus rapide n'entre jamais dans un meuble. Deux jets de travail que le jeu n'oblige jamais à utiliser.
3. **Le fil rouge n'est pas court — il est aveugle.** Quatre maillons, ce n'est pas si peu. Mais **rien ne dit où quoi que ce soit se trouve** : on balaie treize pièces à la torche. Les messages du jeu disent *quoi*, jamais *où*. **Donc rallonger la chaîne ne ferait qu'allonger le balayage** — c'est le piège dans lequel « plus d'étapes » tomberait.
4. **Les treize pièces sont interchangeables.** Chacune a sa couleur et ses meubles, mais mécaniquement : un emplacement de coffre, un réveil, un emplacement de porte, parfois une cachette. Aucune n'a d'usage propre. Seul le bureau a une identité de jeu — et c'est d'être un cul-de-sac, une identité subie.
5. **Le tirage donne de la variété, pas de la rejouabilité.** Ce qui change : *où* sont les objets. Ce qui ne change jamais : *ce qu'on fait*.
6. **Les deux rôdeurs s'ignorent totalement.** Aucun ne sait ce que l'autre a vu. C'est un rôdeur en double, jamais un étau.

**En une phrase :** le jeu est techniquement solide et n'a **qu'un seul verbe — chercher**. Il ne demande jamais au joueur de décider quoi que ce soit. Un choix, c'est une option qui coûte quelque chose ; aujourd'hui rien ne coûte rien.

**Angle mort à retenir :** l'audit de remise en ordre du 16/07 a couvert la machinerie (fichiers, tests, documents, historique) mais **pas la profondeur du jeu**. Un projet peut être techniquement irréprochable et pauvre à jouer.

**Second angle mort, même famille :** le filet de vérification déclare lui-même deux zones qu'il ne couvre pas. Personne n'était allé voir derrière — la victoire ne relançait rien depuis toujours. **Une limite connue d'un outil de contrôle est un endroit où aller regarder à la main, pas une case à cocher.**

### La réponse — trois pistes *(cadré le 27/07/2026)*

Enrichir le fil rouge ne veut **pas** dire l'allonger : rallonger la chaîne ne ferait qu'allonger le balayage aveugle (constat 3). La maladie, c'est que **rien ne coûte rien** — le jeu n'a qu'un seul verbe, chercher. Trois pistes y répondent, deux de tension et une de lisibilité. Seule la direction est arrêtée ici : **chaque piste se figera une à une dans `BASE.md`** au moment de la construire, et se découpera dans `PLAN.md` à ce moment-là — jamais d'avance.

**1. Le geste qui expose** *(tension)*. Ouvrir un coffre ou prendre un objet **cloue le joueur sur place, à découvert**, deux à trois secondes (durée à sentir au test). **Jamais en se cachant** : entrer et sortir d'un meuble reste instantané et sûr — les deux gestes doivent rester contraires. Un rôdeur à 4 m/s rattrape un joueur arrêté : la vitesse figée suffit enfin, les neuf cachettes se réveillent, chercher devient *chercher au bon moment*. Aucun chiffre gelé touché, aucune scène nouvelle.

**2. L'étau** *(tension)*. Un rôdeur qui voit le joueur **prévient l'autre**. L'allié rejoint à l'allure de traque (3 m/s), mais **seulement s'il peut arriver utilement** — 18 m de marche au plus (10 s de budget moins 4 s de fouille, chiffre déjà validé). Il vise la position **vivante** tant qu'on voit le joueur, **figée** sur le dernier point connu sinon. Un rôdeur **peut** quitter son étage pour l'étau (donc l'étau croise les niveaux quand on est près d'un escalier), mais **rentre chez lui si le budget s'épuise** ; le poursuivant, lui, garde sa battue de 30 s inchangée. Le résultat est une **vague** : deux chasseurs dix secondes, le poursuivant seul ensuite, puis le calme. *À guetter au test : se faire voir exprès pour vider un étage ne doit pas devenir rentable — sinon on baisse le budget.*

**3. Le fil rouge** *(lisibilité)*. On ne rallonge pas la chaîne, on rend le manoir **lisible**.
- **Noms de pièces** : pas allumés, lus à la torche, mais visibles en entrant sans les chercher. La pénombre reste intacte — un manoir qu'on apprend à lire, pas un manoir annoté.
- **La pièce d'introduction** : le joueur se réveille **toujours** dans une pièce d'intro **dédiée et fixe** *(révisé le 27/07/2026 : plus « tirée au sort » — un lieu à part du manoir, cf. jet 16)*, **fermée par une porte verrouillée**. Une table y porte **la carte complète** à prendre, un coffre une **clé d'intro dédiée** qui ouvre la porte. Puis la **chaîne classique reprend** : deux morceaux → coffre-fort → badge → sortie. Cette pièce est **exclue du tirage** des objectifs et des rôdeurs.
- **La carte (bouton M)** : complète dès l'intro, **deux morceaux aujourd'hui** (un par étage, lus à l'altitude) ; le troisième naîtra tout seul le jour de la cave, **jamais dessiné d'avance**. Elle montre les murs et les noms, **pas où sont les objets** — sinon la recherche disparaît.
- **Les étapes du fil rouge** : à penser plus tard *(Kinder, 27/07/2026)*.

**Un point figé rouvert en pleine conscience :** le jet 5 avait supprimé toute porte verrouillée au départ (*« ça n'a plus de sens quand on ne sait pas où l'on commence »*). La pièce d'introduction la réintroduit — **légitimement**, puisque désormais on *sait* où l'on commence. À **réécrire noir sur blanc dans `BASE.md`** quand la piste 3 se figera, pas à laisser se contredire en silence.

**Ordre d'exécution recommandé :** le geste qui expose d'abord (le plus petit, aucun figé touché, effet immédiat), puis l'étau, puis le fil rouge (le plus gros, et il rouvre du figé). **Une piste à la fois, testée à la main avant la suivante.** *(**LES TROIS PISTES SONT CLOSES.** Piste 1 — le geste qui expose (jet 13) et piste 2 — l'étau (jet 14), closes le 27/07/2026. Piste 3 — le fil rouge : noms de pièces (jet 15), pièce d'introduction à deux portes (jet 16), carte bouton M (jet 17), closes le 28/07/2026. La question ouverte est répondue : le jeu a son second verbe.)*

**La cave reste parquée** : la carte est bâtie pour l'accueillir sans qu'on la construise. Une décision qui coûte quelque chose d'abord ; la surface, jamais avant le propos.

## La chaîne d'outils
- **Blender** — fabrique les décors et les objets 3D. En vue première personne on ne voit pas le personnage, donc l'effort porte sur la maison, pas sur un héros. **Blender est entré dans le jeu** : tout le mobilier, les coffres, le morceau de clé et le badge en viennent. Les rôdeurs, eux, sont un pantin généré sur Meshy — sa source est dans `sources/`, pas dans le fichier Blender.
- **Godot** — le moteur : assemble la scène et fait vivre l'interaction (déplacement, collisions, tirage au sort, victoire). Piloté par Claude Code via MCP *(corrigé le 09/08/2026 : Cascade a été abandonné, voir `V:\DEV\CLAUDE.md`)*.
- **Kinder** — lance le jeu sur PC et le teste à la main. Personne ne peut tester à ta place.

## Méthode
Quatre phases, dans l'ordre, jamais sautées :
**Vision → Figer → Plan → Exécution.**
L'exécution n'est engagée qu'après le figé. Une décision n'existe que si elle est écrite dans un `.md` validé.

## Règles du projet (adaptées au jeu)
- **Docs : 3 maximum** — `PROJET_CONTEXTE.md`, `BASE.md`, `PLAN.md`. Pas de quatrième.
- **Structure du code** — la règle « 3 couches UI/Logique/Données » ne s'applique pas à un moteur de jeu. Elle est remplacée par l'organisation en scènes de Godot, **décidée et en place** : voir la structure dans `PLAN.md`.
- **Garde-fou : 20 modules max** — anti-dispersion. On en utilise sept.
- **Test manuel obligatoire** — si ce n'est pas testable par Kinder, la mission est incomplète.
- **Zéro structure construite pour le futur.**

## Idées parquées (NE PAS coder maintenant)
> Ce qui est construit (clé, rôdeur, cachettes) est spécifié dans `BASE.md` ; ce qui est décidé pour plus tard (étages, épreuves en chaîne) vit dans « Le cap » ci-dessus. Ici, ce qui n'est ni l'un ni l'autre :

> Trois manques constatés par Kinder en jouant le 16/07/2026, assumés et parqués : la couleur pour distinguer les cachettes, la couleur des éléments de décor, et le son.

- **Le son** — pas une seule note à ce jour. *Recommandation : à prendre en premier.* Dans un manoir noir où deux rôdeurs traquent, entendre des pas se rapprocher changera plus le jeu que n'importe quelle couleur.
- **Les textures** — la *palette* est faite (jet 10) ; les vraies textures restent parquées : le mobilier n'a aucune coordonnée de texture, il faudrait tout déplier dans Blender. À ne prendre que si la couleur ne suffit plus.
- **Les meubles bas franchissables** — la carte de navigation passe par-dessus certains meubles bas : un rôdeur peut marcher sur une table basse. Antérieur au jet 10, jamais constaté en jeu. À traiter si ça se voit.
- **La cave** — le troisième niveau du cap d'origine. Le jeu est prêt à la recevoir.
- Une course à deux joueurs (sortir le plus vite)
- Générer le manoir au hasard (aujourd'hui seul le contenu est tiré, pas les murs)
- Portage Android (joysticks tactiles à repenser)

## Audit de reprise (2026-08-06)
**Constat :** le dépôt a **70 fichiers modifiés/non commités** (`git status`), dont `BASE.md`, `PLAN.md`, `PROJET_CONTEXTE.md` eux-mêmes, et un lot de fichiers non trackés qui n'ont **aucune trace dans ce document** : `carte.gd`/`carte_objet.gd` (cohérents avec la piste 3 « fil rouge » décrite ci-dessus), `porte_intro.gd` (idem, pièce d'intro à deux portes), mais aussi `joueur_cube.gd`, `quartier.gd`, `portail.gd`, `bouton_dev.gd` — **sans lien documenté avec le plan ci-dessus**. Le dernier commit git date du jet 12 (`ba801ef`), alors que ce fichier décrit des jets jusqu'à 17 (clos le 28/07) : **le dépôt git est très en retard sur la documentation**, et lui-même en retard sur l'état réel des fichiers.

**Backlog (reprise) :**
1. ~~Clarifier la nature de `joueur_cube.gd` / `quartier.gd` / `portail.gd` / `bouton_dev.gd`~~ *(clos le 09/08/2026)* : confirmé par Kinder — c'est le chantier en cours du « quartier de jeux » (portage du prototype `3D/cube3D`), le bouton développeur est l'accès volontaire pendant sa construction. Assumé, on n'y touche pas.
2. Décider d'un commit (ou d'un nettoyage) du gros lot de fichiers non commités avant toute nouvelle mission — reprendre à l'aveugle sur un working tree à 70 fichiers modifiés est risqué. **Toujours ouvert.**
3. ~~Pas de `CHANGELOG.md`~~ *(tranché le 09/08/2026)* : décision explicite de ne pas en créer — la règle du projet plafonne à 3 documents (`PROJET_CONTEXTE.md`, `BASE.md`, `PLAN.md`), un 4e la violerait. Le suivi continue de se faire par les messages de commit et ce fichier.
4. ~~Pas de `graphify-out/`~~ *(vérifié le 09/08/2026)* : tenté, mais graphify ne détecte **aucun fichier `.gd`/`.tscn`** sur ce projet (0 fichier « code » trouvé, seuls les .md/README/sons sont vus) — confirme le constat déjà consigné en mémoire (« graphify est aveugle sur ce projet »). L'initialiser n'apporterait rien tant que cette limite tient ; à refaire si graphify gagne un jour le support Godot.
5. Vérifier si `verification.log` (daté du 28/07) est à jour par rapport au code actuel avant de s'y fier — le filet de vérification lui-même a des zones connues non couvertes (voir « second angle mort » ci-dessus). **Toujours ouvert** (log daté du 28/07, code du quartier de jeux ajouté depuis).
6. ~~Le texte mentionne encore Cascade comme pilote de Godot~~ *(corrigé le 09/08/2026)* : remplacé par Claude Code partout dans ce document et dans `BASE.md`.

## Le chantier du quartier cubique *(cadré le 11/08/2026)*

**Ce que c'est :** une suite du manoir, pas un jeu à part. Un espace cubique creux où l'on marche à l'intérieur sur les 6 faces, la gravité bascule d'une face à l'autre (réf. *Manifold Garden*) — une fondation différente du manoir (toute l'IA des rôdeurs et la navigation du manoir supposent un sol plat), donc construite dans ses propres fichiers (`quartier.gd`, `joueur_cube.gd`, `portail.gd`).

**Décision assumée :** on construit le cube d'abord, isolé, avant de décider comment il se branche au manoir. **Le bouton développeur (`bouton_dev.gd`) est l'accès volontaire pendant cette construction** — un raccourci de test, pas une porte de jeu. **Le lien définitif avec le manoir (une porte dans le manoir, un chapitre après la victoire, autre chose) est explicitement non tranché** et sera décidé une fois le cube construit, pas avant. Ce n'est pas un oubli : c'est le choix délibéré de de-risquer la construction avant de figer le branchement.

**État au 11/08/2026 :** le mécanisme central fonctionne et est testable — on marche sur une face, la gravité bascule en passant sur la face voisine. **Les 6 faces ont désormais chacune leurs pièces, leurs plaques de noms (principe du manoir jet 15) et leur mobilier**, validées une à une par Kinder au fil de la construction (bascule testée après chaque face). Noms de pièces posés provisoirement par Claude Code faute de préférence donnée (Kinder : « je choisis des noms neutres, tu ajusteras au test ») — à renommer si besoin en jouant :
- Face 0 (aile entrée) : Vestiaire, W.-C., Salon, Buanderie, Débarras, Escalier.
- Face 1 (4 pièces égales) : Atelier, Réserve, Bureau, Chambre froide.
- Face 2 (2 grandes pièces diagonales) : Salle des machines, Entrepôt.
- Face 3 (6 petites pièces) : Chaufferie, Local technique, Vestiaires, Casiers, Infirmerie, Loge.
- Face 4 (enfilade) : Antichambre, Salle commune, Réfectoire.
- Face 5 (grande + petite) : Grande salle, Remise.

**Le contenu de jeu (objectifs, tension, rôdeurs) n'existe toujours pas sur le cube** — c'est la suite naturelle maintenant que le décor des 6 faces est posé, mais rien n'est tranché sur sa forme (reprendre le fil rouge du manoir ? autre chose ?).

**Correctif du 11/08/2026 : le joueur du cube n'avait pas de torche.** Constat de Kinder après test (« ça fait vide, pas de nom de pièce en entrant, manque une touche esthétique ») — le diagnostic (capture d'écran via godot-ai, jeu lancé) a montré que ce n'était pas un défaut de décor mais l'absence totale de `SpotLight3D` sur `joueur_cube.tscn` (le joueur du manoir en a une, `joueur.tscn` → `Camera3D/Torche`). Sans elle, les pièces sont noires et les plaques de noms (mêmes `Label3D` ombrés que le manoir, jet 15) ne captent aucune lumière donc restent invisibles — le mécanisme marchait déjà, on ne le voyait juste pas. Torche ajoutée, identique à celle du manoir. **Second correctif :** `_etagere()` dans `quartier.gd` posait des tablettes vides ; elle pose maintenant un bric-à-brac (3 objets par tablette, tailles/teintes variées) sur les trois tablettes basses.
