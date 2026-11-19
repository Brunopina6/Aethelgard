extends SceneTree
# (18/11) La DERROTA de un héroe en el combate real (su ventana 3D dentro del combate 2D, con su terreno), con ventana:
#   --script res://pruebas/fotos_derrota_combate.gd --fixed-fps 30 -- salida=<carpeta> heroe=Kael|Lya|Garon
#     [versiones=originales,v2,v3]
# Copia de fotos_capa_garon_combate.gd con el héroe a elegir y solo reposo y derrota: se recorta su zona en instantes
# fijos (cae, tumbado, tumbado más tarde), los mismos antes y después de un arreglo (docs/v12/DERROTA_SUELO_18_11.md).
# 19/11 (C-5): heroe=Naira|Nix pone el caso «Derrotas de Naira y Nix» del banco (Kael, Naira y Nix con sus interruptores
# solo en esta sesión, su nivel, sus enemigos y la llanura); «versiones=originales,fbx»: fbx es la Nix del FBX
# (nix_fbx.gd). En «ko» guarda también la pantalla entera (<heroe>_<versión>_ko_pantalla.png).

const GUION := [
	["reposo", 30, "reposo"],
	["morir", 15, "cae"], ["", 45, "ko"], ["", 60, "ko_tarde"],
]
# (19/11) Naira y Nix: más instantes en la caída (Naira mete la punta de los pies 0,14 m a los 0,8 s: diag_derrota_suelo)
# y los mismos «ko» (2 s) y «ko_tarde» (4 s) que los demás.
const GUION_RECLUTAS := [
	["reposo", 30, "reposo"],
	["morir", 15, "cae"], ["", 6, "cae_0.7"], ["", 3, "cae_0.8"], ["", 3, "cae_0.9"], ["", 33, "ko"],
	["", 60, "ko_tarde"],
]
const RECORTE := Vector2i(360, 440)

var salida := ""
var versiones: PackedStringArray = ["originales", "v2", "v3"]
var vi := -1
var c: Node
var p
var heroe := "Garon"
var garon: Dictionary
var paso := 0
var espera := 0
var hecho := -1
var fotos: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("heroe="):
			heroe = a.substr(6)
		elif a.begins_with("versiones="):
			versiones = a.substr(10).split(",")
	DirAccess.make_dir_recursive_absolute(salida)
	_siguiente.call_deferred()


func _siguiente() -> void:
	if c != null:
		_hoja()
		c.queue_free()
		c = null
	vi += 1
	if vi >= versiones.size():
		quit(0)
		return
	var v: String = versiones[vi]
	var vh := "originales" if v == "fbx" else v
	Engine.set_meta("heroes_version", vh)
	Engine.set_meta("heroes_v2", vh != "originales")
	Engine.set_meta("heroes_v3", vh == "v3")
	if heroe in ["Naira", "Nix"]:                    # como el botón del caso (banco_pruebas.gd, _combate): grupo,
		var BP = load("res://banco_pruebas.gd")      # nivel, enemigos (sus slimes) y zona
		var caso: Dictionary = BP.COMBATES["derrotas_reclutas"]
		Engine.set_meta("nix_fbx", v == "fbx")
		BP.poner_grupo(caso["activos"], BP.NIVEL_COMBATE)
		Engine.set_meta("zona", "llanura")
		Engine.set_meta("grupo_combate", int(caso["grupo"]))
	seed(7)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	paso = 0
	hecho = -1
	espera = 60
	fotos = []
	p = null


func _process(_d: float) -> bool:
	if c == null:
		return false
	c.set("tiempo_quieto", true)
	for h in c.heroes:                               # (que nadie actúe ni le peguen: solo el héroe y sus poses)
		h["atb"] = 0.0
	for e in c.enemigos:
		e["atb"] = 0.0
	if espera > 0:
		espera -= 1
		return false
	if p == null:
		for h in c.heroes:
			if h["nombre"] == heroe:
				garon = h
				p = h.get("p3d", null)
		if p == null:
			print("SIN ", heroe, " 3D en ", versiones[vi])
			_siguiente()
			return false
	var guion: Array = GUION_RECLUTAS if heroe in ["Naira", "Nix"] else GUION
	if paso >= guion.size():
		_siguiente()
		return false
	var s: Array = guion[paso]
	if hecho != paso:
		hecho = paso
		match s[0]:
			"reposo":
				p.reposo()
			"juicio":
				p.atacar_juicio(func(): pass)
			"giro":
				p.atacar_giro(func(): pass)
			"victoria":
				p.victoria()
			"morir":
				p.morir()
		espera = s[1]
		return false
	if s[2] != "":
		var img: Image = root.get_viewport().get_texture().get_image()
		var centro: Vector2 = c._a_pantalla(c._centro(garon))
		var r := Rect2i(Vector2i(centro) - RECORTE / 2 - Vector2i(0, 40), RECORTE)
		r.position = r.position.clamp(Vector2i.ZERO, img.get_size() - RECORTE)
		var rec := img.get_region(r)
		rec.save_png(salida.path_join("%s_%s_%s.png" % [heroe.to_lower(), versiones[vi], s[2]]))
		if s[2] == "ko":
			img.save_png(salida.path_join("%s_%s_ko_pantalla.png" % [heroe.to_lower(), versiones[vi]]))
		fotos.append(rec)
	paso += 1
	return false


func _hoja() -> void:
	if fotos.is_empty():
		return
	var hoja := Image.create(RECORTE.x * fotos.size(), RECORTE.y, false, Image.FORMAT_RGBA8)
	for i in fotos.size():
		var im: Image = fotos[i]
		im.convert(Image.FORMAT_RGBA8)
		hoja.blit_rect(im, Rect2i(Vector2i.ZERO, RECORTE), Vector2i(i * RECORTE.x, 0))
	hoja.save_png(salida.path_join("hoja_derrota_%s_%s.png" % [heroe.to_lower(), versiones[vi]]))
