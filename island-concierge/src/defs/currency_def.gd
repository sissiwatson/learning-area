## Monnaie virtuelle (V0.1 : coquillages). Ajouter une monnaie, par exemple
## les perles, = créer un fichier dans data/currencies/ et le référencer dans
## data/balance/new_game.tres. Aucune monnaie ne s'achète avec de l'argent réel.
class_name CurrencyDef
extends Resource

@export var id: StringName
@export var name_key: String
@export var icon: Texture2D
