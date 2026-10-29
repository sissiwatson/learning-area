## Outil de développement : charge une scène, attend quelques images puis
## enregistre une capture PNG. Sert à vérifier visuellement une scène sans
## ouvrir l'éditeur (voir tools/capture.sh).
##
## godot --path . -s tools/capture.gd -- <scene.tscn> <sortie.png> [images]
extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage : -- <scene.tscn> <sortie.png> [images]")
		quit(2)
		return
	var frames := int(args[2]) if args.size() > 2 else 10
	var scene: PackedScene = load(args[0])
	root.add_child(scene.instantiate())
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var err := root.get_texture().get_image().save_png(args[1])
	quit(0 if err == OK else 1)
