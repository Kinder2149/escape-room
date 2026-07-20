# PLAN.md — Découpage d'exécution

> La carte de construction du socle (voir `BASE.md`).
> **Règle d'or : un prompt par étape. On teste entre chaque. On n'enchaîne jamais deux étapes sans avoir validé la précédente.**
> Les prompts sont produits **une étape à la fois**, au moment de l'exécuter — jamais d'avance (sinon on est tenté de tout lancer d'un coup, et plus rien n'est testable).

---

# Jets 1 à 5 — construits

**Jet 1 — le socle.** Marcher dans une pièce → la maison complète → sortie et victoire → reconnaître les pièces (Blender).

**Jet 2 — la clé en deux morceaux.** Ouvrir un coffre → le butin → deux coffres, une porte.

**Jet 3 — le rôdeur.** La maison dans la pénombre → le rôdeur qui patrouille → il repère et poursuit.

**Jet 4 — les cachettes.** Entrer et sortir d'un meuble → caché, il ne me voit plus → les quatre cachettes.

**Jet 5 — chaque partie est différente.** Six emplacements par type → le tirage au sort (sortie, coffres, réveil, rôdeur) → la porte d'entrée et son verrouillage supprimés, la maison devient close.

Le jeu se gagne, se perd, et laisse le choix entre courir et attendre.

> *Corrigé le 20/07/2026 : cette ligne disait « se relance ». C'était vrai de la défaite seule — **la victoire ne relançait rien**. Le jet 12 s'en occupe.*

---

## Leçons à garder en tête

**Sur le ressenti, seul le test manuel tranche.** Les tests automatiques ont validé les règles à chaque étape ; ce sont les tests à la main de Kinder qui ont trouvé tous les vrais défauts — le rôdeur qui lâchait au chrono, le faisceau qui tremblait dans les angles, la zone morte à bout portant, un script joueur qui ne compilait pas, une armoire montée à l'envers, une chaise qui bouchait la vue. Aucun n'était visible en vérifiant que les règles s'appliquent.

**Les arbitrages de ressenti reviennent à Kinder.** Deux fois, ses choix ont battu la recommandation : la poursuite à deux vitesses (marche lente / sprint jamais plus rapide que le joueur), et les cachettes qu'on peut utiliser sous les yeux du rôdeur quitte à s'y faire déloger.

**Un garde-fou qui parle de « pièce » ne protège pas d'une ligne de vue.** Le défaut cuisine ↔ salle de bain (voir `BASE.md`, « À corriger ») respecte la règle à la lettre et la trahit en pratique. Quand une règle protège d'une situation, la vérifier sur la situation, pas sur son étiquette.

**Une donnée recopiée finit toujours par mentir.** Les points de patrouille recopiés, les commentaires qui décrivent une mécanique supprimée, les docs en retard sur le code : même maladie. Une information ne doit vivre qu'à un seul endroit ; les autres l'interrogent.

**Une carte ne se croit pas, elle se vérifie.** Le calcul de la carte de navigation perdait parfois la course contre la construction des murs ; à la relance, la carte de la partie morte faisait illusion une image. Personne ne l'avait vu : ça marchait, par chance de timing. Le jeu vérifie désormais que le sol répond — et que c'est le sien.

---

## Structure Godot — actuelle
**Dix scènes de jeu**, sur un plafond de vingt, plus un outil *(compte vérifié le 20/07/2026 : le document en annonçait neuf, il en listait bien dix)* :
- **Joueur** — corps, caméra, contrôles, visée, torche, état « caché ».
- **Maison** — murs, couloirs, mobilier, pénombre, sols colorés par pièce, carte de navigation calculée et **vérifiée** au démarrage, audit des emplacements.
- **Pièce** — le nom d'une pièce et ses trois repères (coffre, porte rouge, réveil) ; posée **treize fois** dans la Maison, seule source des emplacements.
- **Coffre** — posée deux fois, placée au lancement.
- **CoffreFort** — même script, modèle acier plus gros, le badge dedans.
- **Cachette** — posée **neuf fois**, réglable meuble par meuble.
- **Sortie** — la porte rouge, placée au lancement, toujours de plain-pied.
- **RôdeurIncarné** — le pantin animé : squelette, trois démarches, lanterne portée devant. **Posée deux fois**, une par niveau.
- **Jeu** — le tirage au sort et la distribution, la chaîne d'objectifs, « Gagné », « Attrapé », remise à zéro, bandeau d'audit.
- **Vérification** *(outil, hors jeu)* — voir ci-dessous.

Sources 3D, dans `sources/` et à la racine :
- `mobilier.blend` — le mobilier rangé **par pièce**, les coffres, le morceau de clé, le badge. *Piège : exporter une collection ne prend pas ses sous-collections ; l'export réussit en silence et produit un fichier vide.*
- `sources/Meshy_AI_pixellabs_voodoo_doll_biped.zip` — **la seule source du pantin**, il n'est pas dans le fichier Blender. Voir `sources/LISEZMOI.md`.

## Le filet de sécurité — `verifier.bat`
Un fichier à double-cliquer, à la racine. Il rejoue **vingt et une séries de contrôles** (quatre bancs — `banc`, `partie`, `controles`, `defaite` — plus dix-sept sondes dans `verification/`) et rend un verdict unique. Le détail part dans `verification.log`. *(Corrigé le 20/07/2026 : le document annonçait dix-huit séries, le fichier en lance vingt et une.)*

Il couvre : la vision et les neuf cachettes, l'audit des emplacements, quarante tirages et leurs garde-fous, les règles de l'étage, la chaîne d'objectifs, le coffre-fort, la géométrie de l'étage et de l'aile, les escaliers, les planques contre les murs, les deux rôdeurs et leurs niveaux, la poursuite dans les escaliers, la battue, l'extrapolation de fuite, les allures, les démarches et le glissement au réveil.

Et surtout, les trois séries qui jouent le jeu plutôt que ses règles :
- **`partie`** — une partie **gagnée de bout en bout**, sans rien forcer : elle approche chaque objet, le vise avec le rayon du joueur, appuie sur la touche d'action. Elle **tourne autour** d'un objet jusqu'à trouver un angle qui accroche, comme un joueur le ferait ; si aucune approche ne marche, l'objet est vraiment inabordable.
- **`controles`** — le joueur lui-même : avancer, être arrêté par un mur, rester au sol, se cacher, y avoir le regard bridé, ressortir.
- **`defaite`** — attrapé : figé, annoncé, les deux rôdeurs arrêtés, une seconde capture sans effet.

**Deux choses restent hors de portée du filet**, et c'est écrit dans les sondes plutôt que caché :
- **La remise à zéro après « Attrapé »** — une sonde instancie le jeu à la main, elle n'est pas la scène principale ; « recharger la scène » n'y veut rien dire.
  > **Ce que cet angle mort cachait** *(trouvé le 20/07/2026)* : **la victoire ne relançait rien du tout.** On gagnait, tout se figeait, il fallait fermer la fenêtre. Le défaut vivait exactement là où le filet ne peut pas voir — et la limite était écrite ici depuis le début sans que personne aille regarder derrière. **Une limite connue d'un outil de contrôle est un endroit où il faut aller voir à la main, pas une case à cocher.** Réparé par le jet 12.
- **La fluidité** — le banc tourne sans affichage, il n'y a rien à rendre. Seul un test à la main peut le dire.

> **À lancer avant et après tout changement.** Fermer l'éditeur Godot pendant qu'il tourne, et **ne jamais en lancer deux en même temps** : les deux séries se disputent la machine, ralentissent tout et faussent le résultat.

### Trois règles pour qu'une sonde reste digne de foi
1. **Un budget se compte en temps réel, jamais en images.** Le débit d'images dépend de la machine et de sa charge : deux sondes rataient au hasard en rafale et passaient seules.
2. **On vérifie une règle, pas un trajet.** Attendre qu'un rôdeur remonte physiquement 46 m d'escalier prenait une minute et cassait sous charge — alors que la règle (« il repart chez lui ») se lit instantanément dans sa destination.
3. **Quand une sonde accuse, se demander d'abord si c'est elle qui ment.** Sur ce projet c'est arrivé plus souvent que l'inverse : un joueur téléporté là où aucun joueur ne peut marcher, un scan qui ignorait qu'une collision est une surface et non un volume, une porte abordée par l'arrière.

---

# Jet 6 — Aplatir : une base propre avant de grossir

**Le principe du jet :** on ne rend générique que ce qu'un défaut de la liste « À corriger » (`BASE.md`) paye déjà. Pas une ligne de plus. Ni générateur de maison, ni système de meubles, ni fichier de configuration : la scalabilité visée, c'est **une pièce qu'on duplique et un filet qui rattrape les erreurs** — sur le modèle de la Cachette, déjà générique et réglée instance par instance.

**La racine commune :** la notion de « pièce » vit aujourd'hui à trois endroits (les volumes de la maison, le tableau d'emplacements du gestionnaire, la liste de patrouille du rôdeur) sans propriétaire. Le jet fait de la pièce **une chose** — et tout le reste en découle.

**À la fin du jet, ajouter une pièce =** creuser le volume et sa porte dans la maison + poser une Pièce et glisser ses trois repères à la souris + dupliquer un groupe de meubles dans Blender. **Zéro ligne de code.** Et une erreur s'affiche en bandeau rouge au premier lancement.

---

## Étape 1 — La pièce devient une chose *(faite — validée le 16/07/2026)*
**Pourquoi en premier :** c'est la fondation ; les étapes 2 et 3 lisent les pièces.

**Ce qu'on construit :** une scène **Pièce** (nom + trois repères : coffre, porte rouge, réveil), posée six fois dans la maison **aux coordonnées actuelles, à l'identique**. Le tableau de 18 emplacements du gestionnaire et la liste de patrouille du rôdeur disparaissent : les deux interrogent la maison. Les orientations deviennent visibles dans l'éditeur.

**Ce qui ne change pas :** rien à l'écran. Aucune règle de jeu. C'est un déménagement, pas une construction.

**Outils :** Godot seul.

**Test manuel :** relancer dix fois — le jeu est identique en tout point : tirages variés, parties gagnables, rôdeur normal.

---

## Étape 2 — Le garde-fou vérifie la vue *(faite — validée le 16/07/2026)*
**Ce qui était prévu :** le rôdeur expose « la vue est-elle dégagée entre ici et là ? » — ses règles de vision, écrites une seule fois, servent aussi au tirage, qui écarte tout départ compromis.

**Ce que le test manuel a ajouté :** un départ hors de vue mais *voisin* restait injuste (le rôdeur sur le joueur en trois secondes). Le garde-fou a gagné une **distance minimale de marche réelle** (9 m, constante de ressenti dans jeu.gd) et la **première ronde évite la pièce du réveil**.

**Ce que la vérification a déterré :** la carte de navigation pouvait naître infirme (course contre la construction des murs, carte fantôme à la relance). La maison la **vérifie** désormais au lieu d'y croire. Le correctif n°5 (rangement du rôdeur sur le réveil du Salon) a été plié dedans.

---

## Étape 3 — La maison se contrôle elle-même *(faite — validée le 16/07/2026)*
**Ce qui était prévu :** au démarrage, la maison vérifie chaque emplacement — sol praticable, joignable en marchant, porte rouge abordable et plaquée contre un mur extérieur — et affiche un **bandeau rouge à l'écran** en français si l'un est mauvais.

**Ce que le filet a attrapé dès sa première exécution :** deux repères écrits avec l'orientation inversée à l'étape 1 (l'écriteau « SORTIE » de l'Entrée naissait dans le mur, le réveil du Bureau regardait l'étagère). Invisible pour les joueurs et pour cent tirages de sonde — vu au premier audit. Corrigés.

---

## Étape 4 — Le ménage *(faite — validée le 16/07/2026)*
`piece_test.tscn` supprimé ; `verif_temp` devenu `verification` (banc officiel, 23 contrôles), branché sur le même audit que le bandeau ; les commentaires menteurs étaient déjà tous morts au fil des étapes 1 et 2.

---

## Étape 5 — Le mobilier se range par pièce *(faite — validée le 16/07/2026)*
Dans Blender : les 28 meubles rangés en six sous-collections, une par pièce, dans la collection Mobilier. Ré-export du `.glb` comparé à l'ancien meuble par meuble : identique (mêmes nœuds, mêmes positions, mêmes matériaux).

---

## Fin du jet 6 — LE SOCLE EST CLOS *(16/07/2026)*
Les six défauts de `BASE.md` sont soldés, la definition of done du socle passe entièrement, le jeu tourne sur une base propre : la pièce est une chose qu'on duplique, le tirage vérifie les situations réelles (vue, distance de marche), la maison vérifie sa carte et ses emplacements, le banc `verification.tscn` rejoue tout en une commande.

**Ajouter une pièce coûte désormais :** creuser le volume et sa porte dans la maison, poser une Pièce et ses trois repères à la souris, dupliquer une sous-collection de meubles dans Blender. Zéro ligne de code ; toute erreur s'affiche en rouge au premier lancement.

**La suite** est devenue un cap : le manoir (voir `PROJET_CONTEXTE.md`). Grande étape A ci-dessous ; B (l'étage, les rôdeurs par niveau) et C (la chaîne d'objectifs) seront cadrées à leur tour, jamais d'avance.

---

# Jet 7 — Le rez-de-chaussée grandit *(figé dans `BASE.md`)*

## Étape 1 — Les murs *(faite — validée le 16/07/2026)*
Aile Est creusée : salle à manger, buanderie, bibliothèque, couloir prolongé et **galerie**, portes et lampes. Buanderie et bibliothèque ont deux portes : ce sont elles qui referment les deux boucles.

## Étape 2 — Les Pièces *(faite — validée le 16/07/2026)*
Trois instances de Pièce et leurs neuf repères. **Zéro ligne de code** : le tirage, la patrouille et l'audit ont découvert l'aile tout seuls — la démonstration du jet 6.

## Étape 3 — Le mobilier *(faite — validée le 16/07/2026)*
Trois sous-collections Blender : table et chaises (réutilisées), étagères et fauteuil (réutilisés), meubles neufs de la buanderie (machine, panier, étendoir).

## Étape 4 — Les cachettes *(faite — validée le 16/07/2026)*
Sous la grande table et dans la malle de la bibliothèque. **Retour de Kinder appliqué en cours d'étape :** les cachettes sont des meubles où l'on entre — le canapé devient penderie, le fauteuil devient malle (voir la règle d'or dans `BASE.md`). Et le repère ◆ ne traverse plus les murs.

## Étape 5 — L'équilibrage *(faite — validée le 16/07/2026)*
Session de jeu de Kinder. La boucle fonctionne (« j'arrive à le semer »). Trois arbitrages de ressenti, tous appliqués et gravés dans `BASE.md` :
1. **Il restait planté sur le seuil** → il entre fouiller la pièce.
2. **Il reprenait sa ronde au lieu de me chercher** → la battue (trois pièces, voisinage déduit de la distance de marche).
3. **Il ne partait pas dans la direction de ma fuite / trop dur à semer** → extrapolation de la course, et il ne sprinte plus quand il ne voit pas.

Deux défauts trouvés au passage : un joueur caché pouvait être attrapé au corps à corps sans avoir été vu entrer, et le banc `verification` était instable (le rôdeur en ronde bloquait la visée du coffre une fois sur quatre).

---

## Fin du jet 7 *(16/07/2026)*
La definition of done passe. Le manoir compte **neuf pièces, deux boucles, six cachettes**, et un rôdeur qui traque au lieu de tourner en rond.

---

# Jet 8 — L'étage *(figé dans `BASE.md`)*

**Le risque du jet, nommé d'avance : la navigation sur deux niveaux.** Toute la logique du rôdeur repose sur la carte ; si elle ne monte pas l'escalier, rien ne marche. D'où l'ordre : on prouve la verticalité **avant** de poser une cloison.

## Étape 1 — Un escalier, prouvé *(construite, en attente du test manuel)*
Un seul escalier (le côté est, dans une cage attenante à la galerie) et un palier minimal à l'étage. Rien d'autre : ni pièce, ni meuble, ni second rôdeur.
**Test manuel :** monter, redescendre, ne pas rester coincé. Et la preuve qui compte : un rôdeur envoyé au palier doit y arriver **en marchant**.

**Le pari était le bon : la verticalité a résisté trois fois avant de céder.**
1. **Rotation écrite à l'envers** — la volée descendait au lieu de monter. La carte de navigation était trouée et rien d'autre ne le montrait. *(Le piège était déjà consigné en mémoire projet : dans un `.tscn`, une rotation s'écrit en lignes, pas en colonnes.)*
2. **Dessous de volée creux** — il produisait un plancher fantôme sous l'escalier, îlot que la navigation prenait pour du sol. La volée est désormais pleine.
3. **Porte au flanc de la volée** — on l'abordait par le côté et on butait contre 8 cm de bordure : infranchissables pour un corps qui marche, alors que la navigation, elle, passait. La cage a été reculée pour qu'on entre **face** à l'escalier, sur du plat.

**Leçon :** une carte de navigation qui relie deux niveaux ne prouve pas qu'un corps puisse les relier. Il faut faire marcher quelqu'un.

## Étape 2 — Les murs de l'étage *(faite — validée le 16/07/2026)*
Couloir traversant, quatre pièces au nord (le sud reste plein : c'est ce qui rend l'étage plus petit), une porte entre les deux chambres, dix lampes, et le second escalier adossé à l'entrée. Les deux boucles verticales sont vérifiées.

**Conséquence sur le rez-de-chaussée :** la cage ouest étant adossée à l'entrée, son mur ouest n'est plus extérieur — **l'emplacement de la porte rouge de l'entrée a été déplacé sur son mur nord**. Seule modification du RDC.

## Étape 3 — Les Pièces *(faite — validée le 16/07/2026)*
Quatre instances de Pièce et leurs repères. Les deux règles du jet sont en place et déduites de l'altitude, sans aucune liste à tenir : **porte rouge toujours de plain-pied**, **au moins un coffre toujours à l'étage** (1,27 coffre en haut par partie en moyenne).

**Le banc a payé pour lui-même :** il a immédiatement échoué parce qu'il posait le joueur à l'altitude du rez-de-chaussée devant un coffre désormais souvent à l'étage. Il lit maintenant l'altitude du coffre au lieu d'une constante.

## Étape 4 — Le mobilier *(faite — validée le 16/07/2026)*
Seize meubles en quatre sous-collections. Défaut réel trouvé au passage : la protection « sa première ronde évite ta pièce » sautait dès qu'une route était calculée, or l'agent se déclare « arrivé » par intermittence dans les premières images. Elle dure maintenant jusqu'à ce qu'il se soit **éloigné de 3 m** — un critère qui ne ment pas.

## Étape 5 — Les cachettes *(faite — validée le 16/07/2026)*
L'armoire (chambre d'amis), la penderie (dressing), sous le grand lit (chambre de maître). La salle d'eau reste à découvert. **Neuf cachettes** au total.

## Étape 6 — Le deuxième rôdeur *(faite — validée le 16/07/2026)*
Un rôdeur par niveau. Tout découle d'une seule idée : **chacun ne connaît que les pièces de son étage pour sa ronde**, et le manoir entier seulement pour ratisser. Il suit donc le joueur dans l'escalier tant qu'il le voit, ratisse le niveau où il l'a perdu, puis **rentre chez lui tout seul** — sans qu'aucune règle de retour n'ait été écrite.

Les niveaux se déduisent de l'altitude des repères : **ajouter la cave demandera d'ajouter un rôdeur dans la scène, rien d'autre.**

**Le banc a été renforcé au passage :** son contrôle « caché, il est invisible » passait pour de mauvaises raisons — le rôdeur était simplement loin. Il est maintenant amené face à la cachette.

## Étape 7 — L'équilibrage *(faite — validée le 16/07/2026)*
Session de jeu de Kinder. Un arbitrage majeur, qui cassait la promesse du jet : **« je descends d'un étage, il me lâche »**. Deux causes cumulées, toutes deux corrigées :
1. Le cône de vision se mesurait **en 3D** — dévaler un escalier faisait sortir du cône en une seconde. Il se mesure désormais **à plat**.
2. La battue était verrouillée sur l'étage **du rôdeur** — il perdait la trace en haut de l'escalier et fouillait en haut. Elle se déroule désormais à l'étage **de la fuite**.

---

## Fin du jet 8 — LE MANOIR A UN ÉTAGE *(16/07/2026)*
Treize pièces sur deux niveaux, deux escaliers en boucle verticale, neuf cachettes, **deux rôdeurs** qui se partagent les étages et se suivent d'un niveau à l'autre. Le fil rouge tient : on cherche en haut, on s'échappe en bas.

**Ce que le jet 6 a rendu possible :** l'étage n'a demandé aucune scène nouvelle et aucune liste à tenir. Les niveaux se déduisent de l'altitude des repères — **ajouter la cave demandera d'ajouter un rôdeur dans la scène, rien d'autre.**

**Leçon du jet, à retenir avant la cave :** une carte de navigation qui relie deux niveaux ne prouve pas qu'un corps puisse les relier — il faut faire marcher quelqu'un. Et un outil de mesure qui ignore la hauteur ment dès qu'il y a deux étages : quatre sondes ont dû être rendues conscientes des niveaux, aucune n'était fausse au rez-de-chaussée.

---

# Jet 9 — La chaîne d'objectifs *(figé dans `BASE.md`)*

## Étape 1 — Le coffre-fort verrouillé *(faite — validée le 16/07/2026)*
Un troisième coffre, verrouillé, dans une quatrième pièce. Il refuse tant que les deux morceaux ne sont pas réunis et **dit ce qui manque**, en suivant le compte. Aucune scène nouvelle : le Coffre existant avec deux réglages. Sur 20 tirages, le coffre-fort monte à l'étage 7 fois — ni privilégié, ni évité.

## Étape 2 — Le badge et la porte *(faite — validée le 16/07/2026)*
Le badge se ramasse dans le coffre-fort ; la porte rouge **l'exige et ne compte plus les morceaux** ; l'affichage passe à « Badge en poche ». La porte nomme le coffre-fort dans son refus : c'est par elle qu'un joueur qui n'en a pas encore croisé apprend qu'il existe.

**La sonde des règles d'étage était périmée** — elle vérifiait « au moins un des DEUX coffres en haut » alors que la règle porte désormais sur les trois objets. Mise à jour.

## Étape 3 — Les modèles 3D *(faite — validée le 16/07/2026)*
Le coffre-fort a son propre modèle : **1,4 fois plus gros et en métal**, contre le bois des coffres ordinaires. Le badge est une **carte blanche plate**, sans rapport visuel avec un morceau de clé. Sa propre scène (`coffre_fort.tscn`), même script — **dixième scène sur un plafond de vingt**.

Le script cherche désormais le couvercle **par son nom** plutôt que par un chemin figé : chaque modèle 3D nomme le sien à sa façon, et un coffre sans couvercle doit se voir tout de suite au lieu de planter.

## Étape 4 — L'équilibrage *(faite — validée le 16/07/2026)*
Session de jeu de Kinder. Verdict : **« la partie est un peu dure mais pas trop, c'est parfait »**. Les deux morceaux de clé sont donc confirmés, aucun chiffre à retoucher.

Trois manques signalés et **assumés comme parqués** : de la couleur pour distinguer les cachettes, de la couleur sur les éléments de décor, et le son.

---

## Fin du jet 9 — LA CHAÎNE EST COMPLÈTE *(16/07/2026)*
Le cap du manoir est atteint dans ses trois grandes étapes : **A** le rez-de-chaussée agrandi, **B** l'étage et les rôdeurs par niveau, **C** la chaîne d'objectifs.

Le jeu se joue en quatre temps — deux morceaux, le coffre-fort, le badge, la porte — sur **treize pièces à deux niveaux**, avec **deux rôdeurs** qui traquent, ratissent et se suivent d'un étage à l'autre, et **neuf cachettes**. Dix scènes sur un plafond de vingt, trois documents.

**La suite** : Kinder travaille le son de son côté ; on prend donc **la couleur** (jet 10 ci-dessous).

---

# Jet 11 — Le rôdeur incarné *(clos le 16/07/2026)*

Un pantin de chiffon animé (modèle Meshy, 24 os, 3 démarches) remplace la silhouette. Il a d'abord cohabité avec elle le temps de comparer ; **depuis la remise en ordre, les deux rôdeurs sont incarnés** et l'ancienne silhouette a quitté le projet.

**Ce que le jet a réglé, dans l'ordre où les défauts sont apparus :**
1. Le modèle regardait à l'envers, ses animations ne bouclaient pas, ses quatre fichiers pesaient 6,5 Mo → un seul de 1,7 Mo, trois démarches.
2. **Il traversait les chambranles.** Sa demi-largeur réelle est de 0,66 m (les os disaient 0,39 : la chair déborde toujours plus). Portes élargies à 1,60 m, pantin réduit à 1,53 m.
3. **La marge de navigation est un plafond, pas un réglage.** Montée à 0,55 pour le recentrer, elle a rendu le joueur **invincible** dans tout passage entre 0,80 m et 1,10 m : il y tient debout, le rôdeur n'y a plus de sol. Ramenée à **0,40**, la valeur exacte où la navigation passe partout où le joueur passe. Débordement final : 19 cm au lieu de 30.
4. **Il renonçait au premier battement de cils** — un chemin « terminé » n'est pas une arrivée quand la cible est hors carte. Et sa charge dépendait de son cône de vision : elle ne dépend plus que de la distance et d'une voie libre.
5. **Sa lanterne clignotait** : logée dans son torse, ses bras la coupaient à chaque pas. Portée devant lui à 1,44 m — la hauteur où son corps est le plus mince. Zéro passage dans un mur sur une ronde complète.
6. **Ses trois démarches** branchées sur ses trois allures.

**Leçon du jet :** trois fois, une sonde a accusé le jeu à tort — un joueur téléporté dans un interstice où il ne peut pas marcher, un scan qui ignorait qu'une collision est une surface et non un volume, une cible posée dans un mur. **Vérifier d'abord si c'est l'outil qui ment.**

---

# Jet 10 — La couleur *(figé dans `BASE.md`)*

## Étape 1 — Les objets qu'on manipule *(faite — validée le 16/07/2026)*
Coffres en bois franc, coffre-fort en acier métallique, morceau de clé et badge avec un léger éclat. Le mobilier passe d'un gris 0,8 à un brun sourd, et l'interactif ne partage plus **aucun** matériau avec le décor — c'était la cause du problème.

**Une erreur rattrapée par la vérification :** l'export a d'abord produit un `mobilier.glb` **vide** (la fonction ne prenait que les objets directs, or le mobilier vit dans des sous-collections). Les 69 meubles avaient disparu. Le contrôle des matériaux exportés l'a montré immédiatement.

## Étape 2 — Le sol de chaque pièce *(faite — validée le 16/07/2026)*
Treize teintes, chaudes en bas, froides en haut. De simples surfaces posées à 1 cm du sol, sans collision, hors du nœud de navigation. **Prouvé neutre par un A/B** : bake avec puis sans, 392 polygones et altitudes identiques au millième.

## Étape 3 — Le décor *(faite — validée le 16/07/2026)*
Murs et plafonds passent du gris de chantier à une pierre sombre légèrement chaude. Les **circulations** reçoivent une pierre neutre : ni colorée comme une pièce, ni sombre comme un mur. Le repère ◆ des cachettes passe en **cyan** — c'est lui qui porte le code des abris.

**Observation hors sujet, notée pour plus tard :** la carte de navigation passe par-dessus certains meubles bas (au salon elle est à 0,59 m, c'est-à-dire sur la table basse). Un rôdeur peut donc marcher sur un meuble bas. **Antérieur au jet 10**, jamais signalé en jeu — à traiter si ça se voit un jour.

## Étape 4 — L'équilibrage *(faite — validée le 16/07/2026)*
Session de jeu de Kinder. La pénombre est intacte, la difficulté n'a pas bougé, le code couleur se lit.

---

## Fin du jet 10 — LE MANOIR SE LIT *(16/07/2026)*
**Le code couleur du jeu, appris en une partie :** chaud/doré = à ramasser · acier = le coffre-fort · rouge = la sortie · **cyan = un abri** · brun sourd et pierre sombre = le décor, qui se tait.

Et le sol dit où l'on est : treize teintes de pièce, chaudes en bas, froides en haut, sur des circulations de pierre neutre. **Sans toucher à un seul réglage de lumière.**

**Ce que le jet a coûté :** aucune mécanique, aucune scène, aucun meuble déplacé. Uniquement des matériaux et treize surfaces sans collision.

**Reste parqué de l'habillage :** les vraies textures (le mobilier n'a toujours aucune coordonnée de texture — un dépliage complet dans Blender). À ne prendre que si la palette ne suffit plus.

---

# Jet 12 — Le jeu dit ses règles *(figé dans `BASE.md`, 20/07/2026)*

**Ce que ce jet n'est pas :** une réponse à la question ouverte. Le fil rouge reste pauvre après ce jet comme avant — le joueur comprendra ce qu'on attend de lui, le jeu n'aura toujours qu'un seul verbe. **On l'approfondira après** *(décision Kinder, 20/07/2026)*.

**Le risque du jet, nommé d'avance :** on touche à la boucle de partie — le seul endroit du projet que le filet de vérification ne peut pas atteindre. Chaque étape se teste donc **à la main, en jouant**, et pas autrement.

## Étape 1 — Le panneau au lancement *(faite — validée le 20/07/2026)*
Le jeu s'ouvre sur le panneau d'accueil ; une touche entre dans le manoir. **Rien d'autre ne bouge** : la relance automatique après « Attrapé » reste en place.

**La frontière qui protège le filet :** le panneau ne s'affiche que si le Jeu **est la scène principale**. Une sonde qui l'instancie à la main entre directement dans le manoir — sinon les 21 séries resteraient bloquées sur l'écran d'accueil pour l'éternité. C'est la même frontière que la relance, déjà déclarée hors de portée du filet. **Conséquence assumée : le panneau ne se teste qu'à la main.**

**Les rôdeurs ne rondent qu'après la touche.** Sinon le joueur perdrait son avance pendant qu'il lit, et le garde-fou « les premières secondes lui appartiennent » (jet 6) ne voudrait plus rien dire. Pendant la lecture, la maison calcule sa carte de navigation en coulisse — du temps gagné.

**Ce que le test manuel a corrigé, en deux passes :**
1. **Les trois blocs de texte se chevauchaient** — titre par-dessus les lignes, début et fin coupés hors écran. Cause : chaque bloc était posé à une position fixe, calibrée à l'aveugle sur une résolution supposée. Remplacés par une **colonne qui se centre et s'espace seule** ; hauteur et largeur **mesurées** à quatre résolutions de 1024×576 à 1920×1080 au lieu d'être estimées.
2. **« C'est lourd de tout lire »** — huit lignes de prose de même poids. La chaîne **se montre** désormais au lieu de se raconter (une ligne à flèches au lieu de trois phrases), et le panneau **emprunte le code couleur du jet 10** : doré = à ramasser, acier = coffre-fort, rouge = la sortie, cyan = un abri. Le panneau n'est plus seulement lisible, **il enseigne le code couleur avant qu'on entre** — ce que le jet 10 n'avait jamais fait.

**Un défaut réel trouvé par Kinder à l'œil :** le losange du panneau et celui du jeu n'étaient **pas du même cyan**. Le panneau s'aligne sur le jeu (`#73e6ff`) — la teinte validée au jet 10 fait foi. *Un code couleur qui varie d'un écran à l'autre n'est plus un code.*

**Reste à trancher un jour :** la ligne « appuie sur une touche pour entrer » est elle aussi en cyan, alors que le cyan est censé signifier « abri ». Signalé, non corrigé.

**Ménage fait au passage** (voir plus bas) : les deux commentaires menteurs de `jeu.gd` et `cachette.gd`.

## Étape 2 — Le panneau devient le point de passage *(à faire)*
« Gagné » et « Attrapé » y ramènent tous les deux. La relance automatique disparaît. C'est l'étape qui répare la victoire qui ne relançait rien.

**Test manuel :** je gagne → panneau → je relance. Je me fais attraper → panneau → je relance. **Cinq fois d'affilée sans fermer la fenêtre.**

## Étape 3 — La ligne du réveil *(à faire)*
« Sors de ce manoir » s'affiche quelques secondes au démarrage de la partie, puis s'efface d'elle-même. Le panneau se lit une fois ; cette ligne est ce qui reste quand la partie commence.

**Test manuel :** dix parties — elle apparaît, elle s'efface, elle ne gêne ni la visée ni le compteur.

## Ménage fait pendant l'étape 1 *(20/07/2026)*
Deux commentaires mentaient, relevés à l'audit. Le jet 6 avait déclaré ce défaut soldé ; il était revenu. **Corrigés :**
- L'en-tête de `jeu.gd` disait que la porte rouge s'ouvre « une fois les deux morceaux réunis » — c'est **le badge** depuis le jet 9.
- `cachette.gd` parlait des « quatre meubles » et des « quatre cachettes » — il y en a **neuf**.
