extends SceneTree
# Fallos del disco al guardar (10/11, auditoría de progreso.gd: escribir()). Archivo propio en user:// (la pasada usa
# datos aislados: ejecutar_pruebas.ps1) y fallos simulados con los interruptores de progreso.gd, sin tocar la partida
# real. En cada caso se comprueba que la última partida buena se puede cargar.
#   1. Guardado normal: la principal es la nueva y la anterior queda en «.bak»; no queda «.tmp».
#   2. Falla el primer renombrado (sistemas que no renombran encima): se quita la principal ya copiada y se reintenta.
#   3. Fallan los dos renombrados: devuelve false, la principal vuelve (la anterior) y el «.tmp» guarda la nueva.
#   4. Falla la copia «.bak»: devuelve false y la principal no se toca.
#   5. No se puede abrir el «.tmp»: devuelve false y nada cambia.
#   6. Sin principal y con un «.tmp» bueno de un intento fallido: un guardado que vuelve a fallar no pierde ese «.tmp»
#      (se guarda antes en «.bak»), y uno que funciona deja la nueva.
#   7. Principal ilegible y renombrado que no puede sobrescribirla: se aparta en «.danada» y se guarda la nueva.

const ARCHIVO := "user://prueba_guardado_fallos.save"

var P
var fallos := 0


func _initialize() -> void:
	P = load("res://progreso.gd")
	_probar()
	quit(1 if fallos > 0 else 0)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _limpiar() -> void:
	for extra in ["", ".bak", ".tmp", ".danada", ".bak.danada"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	P.fallos_renombrar = 0
	P.falla_copia = false
	P.falla_escritura = false


func _partida(n: int) -> Dictionary:
	return {"version": 1, "n": n, "escena": "res://mapa.tscn", "datos": {"oro": 100 * n}}


func _n(extra := "") -> int:
	var d = P.leer(ARCHIVO + extra)
	return int(d["n"]) if d is Dictionary else -1


func _probar() -> void:
	_limpiar()
	# 1
	if not P.escribir(_partida(1), ARCHIVO) or not P.escribir(_partida(2), ARCHIVO):
		_fallo("1: el guardado normal devuelve false")
	if _n() != 2 or _n(".bak") != 1 or FileAccess.file_exists(ARCHIVO + ".tmp"):
		_fallo("1: principal %d, «.bak» %d, «.tmp» %s" % [_n(), _n(".bak"), FileAccess.file_exists(ARCHIVO + ".tmp")])
	# 2
	P.fallos_renombrar = 1
	if not P.escribir(_partida(3), ARCHIVO):
		_fallo("2: con un renombrado fallido devuelve false")
	if _n() != 3 or _n(".bak") != 2:
		_fallo("2: principal %d, «.bak» %d (esperado 3 y 2)" % [_n(), _n(".bak")])
	# 3
	P.fallos_renombrar = 2
	if P.escribir(_partida(4), ARCHIVO):
		_fallo("3: con dos renombrados fallidos devuelve true")
	if _n() != 3:
		_fallo("3: la principal no vuelve a la anterior (es %d)" % _n())
	if _n(".tmp") != 4:
		_fallo("3: el «.tmp» no guarda la partida nueva (es %d)" % _n(".tmp"))
	P.fallos_renombrar = 0
	# 4
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + ".tmp"))
	P.falla_copia = true
	if P.escribir(_partida(5), ARCHIVO):
		_fallo("4: sin copia «.bak» devuelve true")
	if _n() != 3:
		_fallo("4: la principal cambió sin copia de seguridad (es %d)" % _n())
	P.falla_copia = false
	# 5
	var antes := FileAccess.get_file_as_string(ARCHIVO)
	P.falla_escritura = true
	if P.escribir(_partida(6), ARCHIVO):
		_fallo("5: sin poder escribir devuelve true")
	if FileAccess.get_file_as_string(ARCHIVO) != antes:
		_fallo("5: la principal cambió sin poder escribir")
	P.falla_escritura = false
	# 6
	_limpiar()
	P.escribir(_partida(7), ARCHIVO)
	P.fallos_renombrar = 1                          # deja la 8 solo en «.tmp» (sin principal no hay segundo intento)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + ".bak"))
	if P.escribir(_partida(8), ARCHIVO) or _n(".tmp") != 8:
		_fallo("6: preparación: la 8 debería quedarse solo en «.tmp» (es %d)" % _n(".tmp"))
	P.fallos_renombrar = 0
	P.falla_escritura = true                        # un intento que vuelve a fallar…
	P.escribir(_partida(9), ARCHIVO)
	P.falla_escritura = false
	if _n(".tmp") != 8 and _n(".bak") != 8:
		_fallo("6: se perdió la 8, la única copia que quedaba (tmp %d, bak %d)" % [_n(".tmp"), _n(".bak")])
	var f := FileAccess.open(ARCHIVO + ".tmp", FileAccess.WRITE)   # …o uno que trunca el «.tmp» a medias
	f.store_string("{\"n\": 8, \"cort")
	f.close()
	if _n(".bak") != 8:
		_fallo("6: la 8 no está a salvo en «.bak» antes de reescribir el «.tmp» (bak %d)" % _n(".bak"))
	if not P.escribir(_partida(10), ARCHIVO) or _n() != 10:
		_fallo("6: el guardado siguiente no deja la nueva (es %d)" % _n())
	# 7
	_limpiar()
	f = FileAccess.open(ARCHIVO, FileAccess.WRITE)
	f.store_string("esto no es una partida")
	f.close()
	P.fallos_renombrar = 1                          # como si no se pudiera renombrar encima
	if not P.escribir(_partida(11), ARCHIVO) or _n() != 11:
		_fallo("7: con una principal ilegible no se guarda la nueva (es %d)" % _n())
	if FileAccess.get_file_as_string(ARCHIVO + ".danada") != "esto no es una partida":
		_fallo("7: la principal ilegible no se apartó en «.danada»")
	_limpiar()
	print("FALLOS: %d" % fallos)
