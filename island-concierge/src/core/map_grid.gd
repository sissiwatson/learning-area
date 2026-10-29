## Grille de terrains d'une carte, construite à partir du plan texte d'un MapDef.
##
## Logique pure (aucune dépendance aux scènes) : interroger le terrain d'une
## cellule, savoir si elle est constructible, valider un plan.
class_name MapGrid
extends RefCounted

enum Terrain { OCEAN, LAGOON, SAND, GRASS, JUNGLE, PATH, PLOT }

const LEGEND := {
	"~": Terrain.OCEAN,
	"-": Terrain.LAGOON,
	".": Terrain.SAND,
	",": Terrain.GRASS,
	"T": Terrain.JUNGLE,
	"#": Terrain.PATH,
	"+": Terrain.PLOT,
}

var size := Vector2i.ZERO
## Erreurs de lecture du plan ; vide si le plan est valide.
var errors := PackedStringArray()
var _cells := PackedByteArray()


## Lit un plan texte. Les lignes vides en début et fin sont ignorées.
static func from_layout(layout: String, expected_size: Vector2i) -> MapGrid:
	var grid := MapGrid.new()
	grid.size = expected_size
	grid._cells.resize(expected_size.x * expected_size.y)
	grid._cells.fill(Terrain.OCEAN)

	var rows := layout.strip_edges().split("\n")
	if rows.size() != expected_size.y:
		grid.errors.append("%d lignes au lieu de %d" % [rows.size(), expected_size.y])
	for y in mini(rows.size(), expected_size.y):
		var row := rows[y].strip_edges()
		if row.length() != expected_size.x:
			grid.errors.append("ligne %d : %d caractères au lieu de %d" % [y, row.length(), expected_size.x])
		for x in mini(row.length(), expected_size.x):
			var c := row[x]
			if not LEGEND.has(c):
				grid.errors.append("ligne %d, colonne %d : caractère inconnu '%s'" % [y, x, c])
				continue
			grid._cells[y * expected_size.x + x] = LEGEND[c]
	return grid


func is_valid() -> bool:
	return errors.is_empty()


func has_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


## Terrain de la cellule ; l'extérieur de la carte est de l'océan.
func terrain_at(cell: Vector2i) -> Terrain:
	if not has_cell(cell):
		return Terrain.OCEAN
	return _cells[cell.y * size.x + cell.x] as Terrain


func is_land(cell: Vector2i) -> bool:
	var t := terrain_at(cell)
	return t != Terrain.OCEAN and t != Terrain.LAGOON


func is_buildable(cell: Vector2i) -> bool:
	return terrain_at(cell) == Terrain.PLOT


func cells_of(terrain: Terrain) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			if _cells[y * size.x + x] == terrain:
				result.append(Vector2i(x, y))
	return result
