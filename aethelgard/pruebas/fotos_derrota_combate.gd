extends SceneTree
# (18/11) La DERROTA de un héroe en el combate real (su ventana 3D dentro del combate 2D, con su terreno), con ventana:
#   --script res://pruebas/fotos_derrota_combate.gd --fixed-fps 30 -- salida=<carpeta> heroe=Kael|Lya|Garon
#     [versiones=originales,v2,v3]
# Copia de fotos_capa_garon_combate.gd con el héroe a elegir y solo reposo y derrota: se recorta su zona en instantes
# fijos (cae, tumbado, tumbado más tarde), los mismos antes y después de un arreglo (docs/v12/DERROTA_SUELO_18_11.md).
# 19/11 (C-5): heroe=Naira|Nix pone el caso «Derrotas de Naira y Nix» del banco (Kael, Naira y Nix con sus interruptores
# solo en esta sesión, su nivel, sus enemigos y la llanura); «versiones=originales,fbx»: fbx es la Nix del FBX
# (nix_fbx.gd). En «ko» guarda también la pantalla entera (<heroe>_<versión>_<foto>_pantalla.png). La imagen sale a la
# resolución del viewport del juego (1280×720), aunque la ventana sea mayor (--resolution 1600x720).

# Cada paso: [acción, fotograma de la foto CONTADO DESDE LA ÚLTIMA ACCIÓN (reposo o morir), nombre, pantalla entera].
# (19/11, revisión) Antes eran esperas encadenadas y cada paso sumaba 2 fotogramas sin contar (ponerse y la foto): los
# nombres de Naira y Nix no eran su instante. Ahora la foto sale en el fotograma escrito y se imprime el instante real
# («foto … fotogramas tras …»). Los de siempre conservan los mismos instantes que el 18/11 (las mismas fotos de antes y
# después de un arreglo): cae a 16 fotogramas de morir() (0,53 s), ko a 63 (2,10 s) y ko_tarde a 125 (4,17 s).
const GUION := [
	["reposo", 31, "reposo"],
	["morir", 16, "cae"], ["", 63, "ko", true], ["", 125, "ko_tarde"],
]
# (19/11) Naira y Nix: más instantes en la caída. El nombre es el instante tras morir() (a 30 fotogramas por segundo):
# 0,83 s es la muestra en la que diag_derrota_suelo da los pies de Naira más bajos (−0,14 m).
const GUION_RECLUTAS := [
	["reposo", 31, "reposo"],
	["morir", 15, "cae_0.50s"], ["", 21, "cae_0.70s"], ["", 24, "cae_0.80s"], ["", 25, "cae_0.83s"],
	["", 27, "cae_0.90s"], ["", 60, "ko_2.00s", true], ["", 120, "ko_4.00s"],
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
var fr := 0                  # fotogramas del guion (desde que el héroe está listo)
var fr_accion := 0           # fotograma de la última acción (reposo o morir)
var accion := ""


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
	fr = 0
	fr_accion = 0
	accion = ""
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
	fr += 1
	var s: Array = guion[paso]
	if hecho != paso:
		hecho = paso
		if s[0] != "":
			fr_accion = fr
			accion = s[0]
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
		if s[0] != "":
			return false
	if fr - fr_accion < int(s[1]):
		return false
	print("foto %s %s: %d fotogramas tras %s() = %.2f s" % [versiones[vi], s[2], fr - fr_accion, accion,
		(fr - fr_accion) / 30.0])
	if s[2] != "":
		var img: Image = root.get_viewport().get_texture().get_image()
		var centro: Vector2 = c._a_pantalla(c._centro(garon))
		var r := Rect2i(Vector2i(centro) - RECORTE / 2 - Vector2i(0, 40), RECORTE)
		r.position = r.position.clamp(Vector2i.ZERO, img.get_size() - RECORTE)
		var rec := img.get_region(r)
		rec.save_png(salida.path_join("%s_%s_%s.png" % [heroe.to_lower(), versiones[vi], s[2]]))
		if s.size() > 3 and s[3]:
			img.save_png(salida.path_join("%s_%s_%s_pantalla.png" % [heroe.to_lower(), versiones[vi], s[2]]))
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
