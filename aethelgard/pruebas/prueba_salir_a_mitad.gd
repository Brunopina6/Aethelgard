extends SceneTree
# CIERRES_19_11: salir del juego a mitad de una animación ESTÁTICA no cierra Godot con 0xC0000005 (PC-19 y PC-21:
# docs/v12/HIBRIDA_SALIDA_19_11.md y docs/v12/CIERRES_19_11.md). Sin ventana, con datos aislados (los hereda el hijo).
# El cierre ocurre en el apagado del motor, después del último print: la prueba no puede verlo en su propio proceso.
# Por eso lanza un Godot HIJO por caso con pruebas/herramientas/diag_salir_hibrida.gd, que sale (quit(0)) a mitad, y
# comprueba su código de salida (0; el cierre da −1073741819 = 0xC0000005), que el hijo llegó al punto de salida pedido
# y que no dejó errores de script:
#   hibrida_mano  la invocación híbrida de Érebo en «mano» (invocacion_erebo_hibrida.gd invocar; antes de 208ea8b,
#                 0xC0000005 siempre)
#   ataque_v12    el ataque v12 de Lya, 30 fotogramas después de empezar (combate_anim_v12.gd ataque_lya; antes de
#                 1ee5644, 0xC0000005 siempre)
#   golpe_v12     el golpe del Vidracrán (encuentro_desierto_v12), 10 fotogramas después de empezar: comprueba además
#                 que ese golpe guardó en combate.gd un «impacto» NUEVO (_ligar, PC-21: la lista de claves no vacía)
# (CIERRES_19_11_REVISION) El código de salida no basta para PC-21: sin el arreglo, el juego ya salía con 0. Por eso,
# además, una comprobación en el texto de combate.gd: en _animar_golpe, la llamada a la estática animar_golpe de CADA
# uno de los diez enemigos v12 (ENEMIGOS_LIGADOS) pasa «_ligar(impacto)» y no la anónima «impacto».
# Cada hijo, con tope de tiempo (se cierra si se pasa; 3 × TOPE_MS por debajo del tope de la lista, 450 s, para que
# esta prueba cierre siempre a su hijo antes de que el ejecutor la cierre a ella) y su registro en user:// (--log-file).

const DIAG := "res://pruebas/herramientas/diag_salir_hibrida.gd"
const TOPE_MS := 100000
const CASOS := [
	["hibrida_mano", ["erebo=exito", "fase=mano"], ["DIAG sale en «mano»"]],
	["ataque_v12", ["heroes_v2", "combate_anim_v12", "erebo=exito", "fase=ataque:30"], ["DIAG sale 30 fotogramas tras el ataque de Lya · v12 true"]],
	["golpe_v12", ["encuentro_desierto_v12", "grupo=14", "erebo=exito", "fase=golpe_enemigo:10"],
		["DIAG estatica combate_vidracran.gd · impacto guardado nuevo [", "DIAG sale 10 fotogramas tras el golpe del enemigo"]],
]
# lo que, además del texto, tiene que cumplir el registro de cada caso (expresión regular)
const PATRONES := {
	"golpe_v12": "DIAG estatica combate_vidracran\\.gd · impacto guardado nuevo \\[\\d",
}
# los diez enemigos v12 cuya estática animar_golpe espera a nodos (PC-21), por el nombre de su constante en combate.gd
const ENEMIGOS_LIGADOS := ["Humbaba", "Vidracran", "Centinela", "Golem", "Gorthor", "Peon", "Velador", "Custodio",
	"Velaria", "Cencerrante"]

var fallos := 0


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(texto: String) -> void:
	fallos += 1
	print("FALLO: ", texto)


func _comprobar_ligados() -> void:
	var texto := FileAccess.get_file_as_string("res://combate.gd")
	if texto == "":
		_fallo("no se pudo leer res://combate.gd")
		return
	var bien := []
	for nombre in ENEMIGOS_LIGADOS:
		var lineas := []
		for l in texto.split("\n"):
			if ("await %s.animar_golpe(" % nombre) in l:
				lineas.append(l.strip_edges())
		if lineas.size() != 1:
			_fallo("combate.gd: %d llamadas «await %s.animar_golpe(» (se esperaba 1)" % [lineas.size(), nombre])
		elif not "_ligar(impacto)" in lineas[0]:
			_fallo("combate.gd: %s.animar_golpe no recibe «_ligar(impacto)» (PC-21): %s" % [nombre, lineas[0]])
		else:
			bien.append(nombre)
	print("ligados en combate.gd: %d de %d %s" % [bien.size(), ENEMIGOS_LIGADOS.size(), bien])


func _probar() -> void:
	_comprobar_ligados()
	var godot := OS.get_executable_path()
	var proyecto := ProjectSettings.globalize_path("res://")
	for caso in CASOS:
		var log_hijo := ProjectSettings.globalize_path("user://salir_a_mitad_%s.log" % caso[0])
		if FileAccess.file_exists(log_hijo):
			DirAccess.remove_absolute(log_hijo)
		var args := PackedStringArray(["--headless", "--path", proyecto, "--log-file", log_hijo, "--script", DIAG, "--"])
		args.append_array(PackedStringArray(caso[1]))
		var t0 := Time.get_ticks_msec()
		var pid := OS.create_process(godot, args)
		if pid <= 0:
			_fallo("%s: no se pudo lanzar el Godot hijo (%s)" % [caso[0], godot])
			continue
		while OS.is_process_running(pid) and Time.get_ticks_msec() - t0 < TOPE_MS:
			OS.delay_msec(200)
		if OS.is_process_running(pid):
			OS.kill(pid)
			_fallo("%s: el hijo no terminó en %d s (cerrado)" % [caso[0], TOPE_MS / 1000])
			continue
		var rc := OS.get_process_exit_code(pid)
		var texto := FileAccess.get_file_as_string(log_hijo) if FileAccess.file_exists(log_hijo) else ""
		var sale := ""
		for l in texto.split("\n"):
			if l.begins_with("DIAG sale") or l.begins_with("DIAG estatica"):
				sale += " · " + l.strip_edges()
		print("%s: código de salida %d en %.1f s%s" % [caso[0], rc, (Time.get_ticks_msec() - t0) / 1000.0, sale])
		if rc != 0:
			_fallo("%s: el hijo salió con %d (0xC0000005 = -1073741819), no con 0" % [caso[0], rc])
		for esperado in caso[2]:
			if not esperado in texto:
				_fallo("%s: el hijo no llegó a «%s» (registro: %s)" % [caso[0], esperado, log_hijo])
		if PATRONES.has(caso[0]):
			var re := RegEx.create_from_string(PATRONES[caso[0]])
			if re.search(texto) == null:
				_fallo("%s: el registro no cumple «%s» (sin «impacto» guardado nuevo: ¿la estática recibe la anónima?)" % [caso[0], PATRONES[caso[0]]])
		for malo in ["SCRIPT ERROR", "Parse Error", "FALLO"]:
			if malo in texto:
				_fallo("%s: el registro del hijo tiene «%s» (%s)" % [caso[0], malo, log_hijo])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
