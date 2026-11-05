extends SceneTree

func _initialize() -> void:
	var t: Theme = root.theme
	print("tema: ", t, " tiene font Label: ", t.has_font("font", "Label") if t else false)
	var l := Label.new()
	root.add_child(l)
	var c := CanvasLayer.new()
	root.add_child(c)
	var l2 := Label.new()
	c.add_child(l2)
	await process_frame
	print("fuente label raiz: ", l.get_theme_font("font"), " base ", (l.get_theme_font("font") as FontVariation).base_font.resource_path if l.get_theme_font("font") is FontVariation else "-")
	print("fuente label en CanvasLayer: ", l2.get_theme_font("font"))
	quit()
