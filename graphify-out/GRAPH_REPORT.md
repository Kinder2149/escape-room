# Graph Report - V:\DEV\PROJETS\3D\escape-room  (2026-09-07)

## Corpus Check
- Corpus is ~17,803 words - fits in a single context window. You may not need a graph.

## Summary
- 101 nodes · 102 edges · 24 communities detected
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.69)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_clos cachettes|clos cachettes]]
- [[_COMMUNITY_Constat 27072026|Constat 27/07/2026]]
- [[_COMMUNITY_badge coffre-fort|badge coffre-fort]]
- [[_COMMUNITY_Idée parquée|Idée parquée]]
- [[_COMMUNITY_Étape Chaque|Étape Chaque]]
- [[_COMMUNITY_Audit reprise|Audit reprise]]
- [[_COMMUNITY_pantin rôdeur|pantin rôdeur]]
- [[_COMMUNITY_clos 27072026|clos 27/07/2026]]
- [[_COMMUNITY_arbitrage Kinder,|arbitrage Kinder,]]
- [[_COMMUNITY_Godot addon|Godot addon]]
- [[_COMMUNITY_mobilier.blend meubles,|mobilier.blend meubles,]]
- [[_COMMUNITY_Meshy génération|Meshy génération]]
- [[_COMMUNITY_Kinder lance|Kinder lance]]
- [[_COMMUNITY_Scène Vérification|Scène Vérification]]
- [[_COMMUNITY_Méthode Vision|Méthode Vision]]
- [[_COMMUNITY_Règle documents|Règle documents]]
- [[_COMMUNITY_Garde-fou modules|Garde-fou modules]]
- [[_COMMUNITY_Scène Joueur|Scène Joueur]]
- [[_COMMUNITY_Scène Maison|Scène Maison]]
- [[_COMMUNITY_Scène Coffre|Scène Coffre]]
- [[_COMMUNITY_Scène CoffreFort|Scène CoffreFort]]
- [[_COMMUNITY_Scène Cachette|Scène Cachette]]
- [[_COMMUNITY_Scène Sortie|Scène Sortie]]
- [[_COMMUNITY_Scène tirage,|Scène tirage,]]

## God Nodes (most connected - your core abstractions)
1. `Socle figé (jets 1-5)` - 10 edges
2. `Audit de profondeur (20/07/2026, six constats)` - 7 edges
3. `Chantier du quartier cubique (gravité multi-face, réf Manifold Garden)` - 7 edges
4. `Chaîne d'objectifs (2 morceaux → coffre-fort → badge → porte rouge)` - 6 edges
5. `Le rôdeur — vision, vitesse, poursuite, battue` - 6 edges
6. `Projet Manoir (escape room)` - 5 edges
7. `Le cap — du pavillon au manoir` - 5 edges
8. `La réponse — trois pistes (cadré 27/07/2026)` - 5 edges
9. `Piste 3 : le fil rouge (lisibilité — noms, intro, carte)` - 5 edges
10. `La maison — 13 pièces sur deux niveaux` - 5 edges

## Surprising Connections (you probably didn't know these)
- `Corrections à l'import du pantin (orientation, boucle, taille, largeur bras)` --conceptually_related_to--> `Le rôdeur — vision, vitesse, poursuite, battue`  [INFERRED]
  sources/LISEZMOI.md → BASE.md
- `Chantier du quartier cubique (gravité multi-face, réf Manifold Garden)` --conceptually_related_to--> `Torche du joueur toujours allumée (n'influe pas sur détection)`  [EXTRACTED]
  PROJET_CONTEXTE.md → BASE.md
- `Projet Manoir (escape room)` --references--> `Socle figé (jets 1-5)`  [EXTRACTED]
  PROJET_CONTEXTE.md → BASE.md
- `Socle figé (jets 1-5)` --references--> `Chaîne d'objectifs (2 morceaux → coffre-fort → badge → porte rouge)`  [EXTRACTED]
  BASE.md → PROJET_CONTEXTE.md
- `Chaîne d'objectifs (2 morceaux → coffre-fort → badge → porte rouge)` --references--> `Deux coffres (morceaux de clé)`  [EXTRACTED]
  PROJET_CONTEXTE.md → BASE.md

## Communities

### Community 0 - "clos cachettes"
Cohesion: 0.13
Nodes (16): Le bureau — cul-de-sac, Règle d'or des cachettes : où l'on entre vraiment (arbitrage Kinder, jet 7), Le départ — réveil dans une pièce tirée au sort, sans porte d'entrée, La maison — 13 pièces sur deux niveaux, Neuf cachettes, Le panneau d'accueil (jet 12), Repère ◆ cyan des cachettes, Socle figé (jets 1-5) (+8 more)

### Community 1 - "Constat 27/07/2026"
Cohesion: 0.24
Nodes (13): Audit de profondeur (20/07/2026, six constats), Constat 1 : on ne peut pas mourir en courant (joueur 4,5 > rôdeur 4,0), Constat 2 : les neuf cachettes sont facultatives, Constat 3 : le fil rouge est aveugle (pas de 'où'), Constat 4 : les treize pièces sont interchangeables, Constat 5 : tirage = variété, pas rejouabilité, Constat 6 : les deux rôdeurs s'ignorent totalement, Jet 13 — Le geste qui expose (clos 27/07/2026) (+5 more)

### Community 2 - "badge coffre-fort"
Cohesion: 0.22
Nodes (11): Le coffre-fort (libère le badge), Deux coffres (morceaux de clé), La porte rouge (sortie, exige le badge), Cachettes (9), Chaîne d'objectifs (2 morceaux → coffre-fort → badge → porte rouge), Deux rôdeurs (un par niveau), Projet Manoir (escape room), Tirage au sort à chaque partie (+3 more)

### Community 3 - "Idée parquée"
Cohesion: 0.22
Nodes (9): Le cap — du pavillon au manoir, Idée parquée : la cave (3e niveau), Idée parquée : le son (recommandé en premier), Idée parquée : les vraies textures, Idées parquées (son, textures, meubles bas, cave, etc.), Jet 12 — Le jeu dit ses règles (panneau d'accueil), Jet 7 — Étape A : rez-de-chaussée grandit (6→9 pièces), Jet 8 — Étape B : étage + rôdeurs par niveau (+1 more)

### Community 4 - "Étape Chaque"
Cohesion: 0.29
Nodes (7): Chaque partie est différente — tirage au sort + garde-fous, Garde-fou : rôdeur jamais à moins de 9 m de marche réelle du réveil, Jet 6 — Étape 2 : le garde-fou vérifie la vue, Jet 6 — Étape 3 : la maison se contrôle elle-même, Jet 6 — Étape 1 : la pièce devient une chose, Leçon : une donnée recopiée finit toujours par mentir, Scène Pièce (source unique des emplacements)

### Community 5 - "Audit reprise"
Cohesion: 0.33
Nodes (6): Audit de reprise (2026-08-06) — 70 fichiers non commités, Chantier du quartier cubique (gravité multi-face, réf Manifold Garden), bouton_dev.gd (accès dev volontaire), joueur_cube.gd, portail.gd, quartier.gd

### Community 6 - "pantin rôdeur"
Cohesion: 0.33
Nodes (6): Jet 11 — Le rôdeur incarné (pantin Meshy, clos 16/07/2026), Meshy_AI_pixellabs_voodoo_doll_biped.zip, Scène RôdeurIncarné, Corrections à l'import du pantin (orientation, boucle, taille, largeur bras), Meshy_AI_pixellabs_voodoo_doll_biped.zip — pantin du rôdeur, rodeur_perso.glb — fusion du pantin (Marche/Course/Guet)

### Community 7 - "clos 27/07/2026"
Cohesion: 0.6
Nodes (5): Jet 15 — Les noms de pièces (clos 27/07/2026), Jet 16 — La pièce d'introduction (figé 27/07/2026), Jet 17 — La carte (clos 28/07/2026), Piste 3 : le fil rouge (lisibilité — noms, intro, carte), Leçon jet 15 : édition par enregistrement de scène détruit le CSG

### Community 8 - "arbitrage Kinder,"
Cohesion: 0.6
Nodes (5): La battue — 3 pièces, 30 secondes, Le cône de vision se mesure à plat (arbitrage Kinder, jet 8), Extrapolation de fuite — 6 m au-delà (arbitrage Kinder, jet 7), Le rôdeur — vision, vitesse, poursuite, battue, Le rôdeur ne sprinte que sur proie vue (arbitrage Kinder, jet 7)

### Community 9 - "Godot addon"
Cohesion: 0.5
Nodes (4): Godot AI addon (MCP bridge éditeur Godot), Godot AI — prérequis (Godot 4.5+, uv, client MCP), Claude Code pilote Godot via MCP (Cascade abandonné), Godot (moteur de jeu)

### Community 10 - "mobilier.blend meubles,"
Cohesion: 0.67
Nodes (3): mobilier.blend, mobilier.blend — meubles, coffres, morceau de clé, ancienne silhouette, Piège : exporter une collection sans sous-collections produit un fichier vide

### Community 11 - "Meshy génération"
Cohesion: 1.0
Nodes (2): Meshy (génération du pantin rôdeur), Blender (décors et objets 3D)

### Community 12 - "Kinder lance"
Cohesion: 1.0
Nodes (2): Kinder — lance et teste le jeu à la main, Règle : test manuel obligatoire

### Community 13 - "Scène Vérification"
Cohesion: 1.0
Nodes (2): Scène Vérification (outil), verifier.bat — filet de sécurité (21 séries de contrôles)

### Community 14 - "Méthode Vision"
Cohesion: 1.0
Nodes (1): Méthode : Vision → Figer → Plan → Exécution

### Community 15 - "Règle documents"
Cohesion: 1.0
Nodes (1): Règle : 3 documents maximum

### Community 16 - "Garde-fou modules"
Cohesion: 1.0
Nodes (1): Garde-fou : 20 modules max

### Community 17 - "Scène Joueur"
Cohesion: 1.0
Nodes (1): Scène Joueur

### Community 18 - "Scène Maison"
Cohesion: 1.0
Nodes (1): Scène Maison

### Community 19 - "Scène Coffre"
Cohesion: 1.0
Nodes (1): Scène Coffre

### Community 20 - "Scène CoffreFort"
Cohesion: 1.0
Nodes (1): Scène CoffreFort

### Community 21 - "Scène Cachette"
Cohesion: 1.0
Nodes (1): Scène Cachette

### Community 22 - "Scène Sortie"
Cohesion: 1.0
Nodes (1): Scène Sortie (porte rouge)

### Community 23 - "Scène tirage,"
Cohesion: 1.0
Nodes (1): Scène Jeu (tirage, chaîne, gagné/attrapé)

## Knowledge Gaps
- **47 isolated node(s):** `Cachettes (9)`, `Tirage au sort à chaque partie`, `Jet 7 — Étape A : rez-de-chaussée grandit (6→9 pièces)`, `Jet 8 — Étape B : étage + rôdeurs par niveau`, `Jet 9 — Étape C : chaîne d'objectifs` (+42 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Meshy génération`** (2 nodes): `Meshy (génération du pantin rôdeur)`, `Blender (décors et objets 3D)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Kinder lance`** (2 nodes): `Kinder — lance et teste le jeu à la main`, `Règle : test manuel obligatoire`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Scène Vérification`** (2 nodes): `Scène Vérification (outil)`, `verifier.bat — filet de sécurité (21 séries de contrôles)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Méthode Vision`** (1 nodes): `Méthode : Vision → Figer → Plan → Exécution`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Règle documents`** (1 nodes): `Règle : 3 documents maximum`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Garde-fou modules`** (1 nodes): `Garde-fou : 20 modules max`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Scène Joueur`** (1 nodes): `Scène Joueur`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Scène Maison`** (1 nodes): `Scène Maison`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Scène Coffre`** (1 nodes): `Scène Coffre`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Scène CoffreFort`** (1 nodes): `Scène CoffreFort`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Scène Cachette`** (1 nodes): `Scène Cachette`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Scène Sortie`** (1 nodes): `Scène Sortie (porte rouge)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Scène tirage,`** (1 nodes): `Scène Jeu (tirage, chaîne, gagné/attrapé)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Socle figé (jets 1-5)` connect `clos cachettes` to `arbitrage Kinder,`, `badge coffre-fort`, `Étape Chaque`?**
  _High betweenness centrality (0.336) - this node is a cross-community bridge._
- **Why does `Le départ — réveil dans une pièce tirée au sort, sans porte d'entrée` connect `clos cachettes` to `clos 27/07/2026`?**
  _High betweenness centrality (0.146) - this node is a cross-community bridge._
- **Why does `Piste 3 : le fil rouge (lisibilité — noms, intro, carte)` connect `clos 27/07/2026` to `Constat 27/07/2026`?**
  _High betweenness centrality (0.145) - this node is a cross-community bridge._
- **What connects `Cachettes (9)`, `Tirage au sort à chaque partie`, `Jet 7 — Étape A : rez-de-chaussée grandit (6→9 pièces)` to the rest of the system?**
  _47 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `clos cachettes` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._