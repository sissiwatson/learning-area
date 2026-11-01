## Catégories comptables des mouvements du porte-monnaie, d'après le préfixe
## de leur motif (ex. « commission:bk_0003 »). Sert aux futurs bilans
## financiers : le confort de jeu n'est jamais une charge d'exploitation.
class_name LedgerCategoriesDef
extends Resource

## Préfixe du motif (ou motif exact) -> catégorie. Le préfixe le plus long gagne.
@export var prefixes: Dictionary[String, StringName] = {}
