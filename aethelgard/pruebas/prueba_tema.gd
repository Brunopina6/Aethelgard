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
	# (10/11) con aserciones: la fuente de los textos es la del juego (Saira Condensed), también en una CanvasLayer
	var fallos := 0
	for lb in [l, l2]:
		var f = lb.get_theme_font("font")
		var base: String = (f as FontVariation).base_font.resource_path if f is FontVariation else (f.resource_path if f != null else "")
		if not "SairaCondensed" in base:
			fallos += 1
			print("FALLO: un texto no usa la fuente del juego (%s)" % base)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
