# PROJET_CONTEXTE.md

> À lire en premier à chaque session, avant toute action.
> Nom de travail : **Manoir** (changé le 16/07/2026 — la maison est appelée à grandir).

## Intention
Un jeu d'évasion en vue première personne. Le joueur se réveille dans un manoir clos qu'il ne connaît pas, sans savoir où il est. Pour sortir, il doit remonter une chaîne : **deux morceaux de clé → le coffre-fort → le badge → la porte rouge** — le tout en évitant **deux rôdeurs** qui traquent dans la pénombre, un par niveau. Des cachettes permettent de les laisser passer.

**Chaque partie est différente** : la sortie, les trois objets à chercher, le point de réveil et le départ de chaque rôdeur sont tirés au sort à chaque lancement.

Tout est construit et validé (voir `BASE.md`) : le jeu se gagne, se perd et se relance.

## Le cap — du pavillon au manoir *(atteint le 16/07/2026)*
La destination était **un manoir sur plusieurs niveaux avec des épreuves qui s'enchaînent**. Les trois grandes étapes sont construites et validées :

- ✅ **A — le rez-de-chaussée grandit** *(jet 7)* : 6 → 9 pièces, une aile est et une galerie en boucle.
- ✅ **B — l'étage et les rôdeurs par niveau** *(jet 8)* : 4 pièces de plus, deux escaliers en boucle verticale, **deux rôdeurs** — chacun chez lui, qui suit le joueur d'un étage à l'autre s'il le voit, et rentre s'il le perd.
- ✅ **C — la chaîne d'objectifs** *(jet 9)* : deux morceaux → coffre-fort → badge → porte rouge.

**Reste du cap d'origine, non construit : la cave.** Elle est prête à recevoir — les niveaux se déduisent de l'altitude des repères, il suffira d'ajouter un rôdeur dans la scène.

## LA QUESTION OUVERTE — à trancher avant de construire quoi que ce soit
*(constat de Kinder, 16/07/2026, après la remise en ordre)*

**Le fil rouge est pauvre.** Aujourd'hui : deux morceaux de clé → un badge → la porte rouge. C'était déjà court sur treize pièces ; **sur trois niveaux ce serait creux**. Le manoir aurait de la surface sans avoir de propos.

Deux directions possibles, **une seule à la fois** :
- **La cave** — un troisième niveau, un rôdeur de plus. Ajoute de la surface.
- **Le fil rouge** — enrichir la progression : plus d'étapes, des objets qui se répondent, une raison d'explorer chaque niveau.

**Avis posé pour la prochaine session, à confirmer par un audit frais :** le fil rouge **avant** la cave. C'est le même raisonnement qui a fait passer la croissance avant l'habillage au jet 10 — *on n'ajoute pas de la surface avant ce qui lui donnera un sens*. Une cave posée sur le fil rouge actuel serait un troisième étage qu'on traverse sans raison.

**Angle mort à retenir :** l'audit de remise en ordre a couvert la machinerie (fichiers, tests, documents, historique) mais **pas la profondeur du jeu**. Un projet peut être techniquement irréprochable et pauvre à jouer.

## La chaîne d'outils
- **Blender** — fabrique les décors et les objets 3D. En vue première personne on ne voit pas le personnage, donc l'effort porte sur la maison, pas sur un héros. **Blender est entré dans le jeu** : tout le mobilier, les coffres, le morceau de clé et le badge en viennent. Les rôdeurs, eux, sont un pantin généré sur Meshy — sa source est dans `sources/`, pas dans le fichier Blender.
- **Godot** — le moteur : assemble la scène et fait vivre l'interaction (déplacement, collisions, tirage au sort, victoire). Piloté par Cascade via MCP.
- **Kinder** — lance le jeu sur PC et le teste à la main. Personne ne peut tester à ta place.

## Méthode
Quatre phases, dans l'ordre, jamais sautées :
**Vision → Figer → Plan → Exécution.**
Cascade n'est engagé qu'après le figé. Une décision n'existe que si elle est écrite dans un `.md` validé.

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
