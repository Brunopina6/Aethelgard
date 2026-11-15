extends SceneTree
# V12, Érebo híbrida (15/11): capturas CON VENTANA de los momentos clave de la invocación híbrida
# (invocacion_erebo_hibrida.gd) en combates de verdad contra varios enemigos: el enemigo señalado, el plano del objetivo,
# Érebo surgiendo, el acercamiento, la mano en el pecho, el corazón saliendo, el corazón (o el trozo) en la mano, el
# orbe, el ritual (vídeo) y la vuelta al combate.
# Argumentos: salida=<carpeta> grupos=9,7,18 (GRUPOS de combate.gd) erebo=exito|fallo erebo_cine=hibrida|hibrida_3d
# Ejemplo: Godot --path aethelgard -s res://pruebas/fotos_erebo_hibrida.gd -- salida=D:/x grupos=9 erebo=exito erebo_cine=hibrida
# No toca la partida real: archivo de partida de prueba (y el ejecutor aísla user://).

const ARCHIVO := "user://fotos_erebo_hibrida.save"
# fase del registro de la invocación → [segundos después, nombre de la captura]
const MOMENTOS := [["senalar", 0.6, "01_senalado"], ["objetivo", 0.7, "02_objetivo"], ["aparece", 2.0, "03_erebo_surge"],
	["acercamiento", 0.6, "04_acercamiento"], ["contacto", 0.06, "05_mano_en_el_pecho"], ["agarra", 0.45, "06_corazon_saliendo"],
	["sale", 0.35, "07_corazon_fuera"], ["se_escapa", 0.3, "07_se_escapa"], ["trozo", 0.35, "07_trozo"],
	["en_la_mano", 0.75, "08_en_la_mano"], ["orbe", 0.75, "09_orbe"], ["video_arranca", 1.2, "10_ritual_agarre"],
	["video_arranca", 6.5, "11_ritual_estallido"], ["ritual_3d", 1.0, "10_ritual_3d"], ["fallo", 0.9, "10_fallo_se_hunde"]]

var P
var G
var c = null
var salida := "D:/REBELUM_diagnostico/erebo_hibrida"
var grupos: Array = [9]
var forzado := "exito"


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("grupos="):
			grupos = []
			for g in a.substr(7).split(","):
				grupos.append(int(g))
		elif a.begins_with("erebo="):
			forzado = a.substr(6)
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	DirAccess.make_dir_recursive_absolute(salida)
	_hacer.call_deferred()


func _hacer() -> void:
	for i in 10:
		await process_frame
	for g in grupos:
		await _uno(g)
	Engine.remove_meta("archivo_partida_prueba")
	print("FIN fotos_erebo_hibrida")
	quit(0)


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var ruta := salida.path_join(nombre + ".png")
	img.save_png(ruta)
	print("FOTO ", ruta)


func _uno(grupo: int) -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	for n in ["Kael", "Lya"]:
		G.datos()[n]["nivel"] = 5
		G.datos()[n]["pv"] = -1
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Lya":
				break
			c._defender()
		await process_frame
		if c.estado != "accion":
			for e in c.enemigos:
				e["atb"] = 0.0
	var obj: Dictionary = c.enemigos[0]
	var pref := "g%02d_%s_%s_" % [grupo, String(obj["modelo"]), forzado]
	c.armonia = 1.0
	await _foto(pref + "00_antes")
	c._invocar_sobre(obj)
	var hechas := {}
	var vuelta := false
	for i in 4000:
		await process_frame
		var inv = c.get_node_or_null("EreboHibrida")
		if inv != null:
			_ultimo_registro = inv.registro.duplicate()
			var ahora: float = inv._t_juego
			for m in MOMENTOS:
				if hechas.has(m[2]):
					continue
				for r in inv.registro:
					if r[0] == m[0] and ahora >= r[1] + m[1]:
						hechas[m[2]] = true
						await _foto(pref + m[2])
						break
		elif hechas.size() > 0 and not vuelta and c.estado == "accion":
			vuelta = true
			for k in 12:
				await process_frame
			await _foto(pref + "12_vuelta")
		if c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
			break
	await _foto(pref + "13_control")
	print("REGISTRO g%d: %s · PV %d" % [grupo, str(_ultimo_registro), obj["hp"]])
	c.queue_free()
	c = null
	for i in 5:
		await process_frame


var _ultimo_registro: Array = []
