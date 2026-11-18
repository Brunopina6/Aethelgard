extends SceneTree
# V12 (18/11, Redmi: docs/v12/REDMI_18_11.md, t04_este_5 y t02_diag; RECORRIDO.md §10): REGRESIÓN del arreglo «Kael
# pegado a una fachada de lado queda medio tapado». Sin ventana y sin escena: solo los trazados y la regla de aclarado de
# sector.gd (cajas ocultables ensanchadas Comun.MARGEN_LADO en x), con la misma cuenta que diag_ciudad_fachadas.gd
# (la figura ANCHA de Kael, ±0,4 m, de 0,85 a 1,45 m: lo que se ve en la captura del Redmi).
#   1. Las cuatro piezas que pasaron a OCULTABLES siguen siéndolo (plaza_tapiz: casa_e_baja, hoja_casa_soportal_s;
#      barrio_alto: casa_rellano_e, casa_rellano_o) y MARGEN_LADO es al menos 0,2 m.
#   2. En los dos sitios del Redmi (soportal sur de la Calle Mayor y rellano 1 del Barrio Alto) lo que la escena deja sin
#      aclarar tapa < 5 % de la figura ancha; y SIN el ensanche (margen 0) taparía al menos 5 puntos más (22 % y 11 %).
# Imprime «FALLOS: n».

const P := preload("res://zonas3d/ciudad/plano.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
const D := preload("res://pruebas/diag_ciudad_fachadas.gd")
const SITIOS := {"soportal sur (t04_este_5)": Vector2(7.68, 50.5), "rellano 1 del Barrio Alto (t02_diag)": Vector2(7.69, -27.19)}
const PIEZAS := {"plaza_tapiz": ["casa_e_baja", "hoja_casa_soportal_s"], "barrio_alto": ["casa_rellano_e", "casa_rellano_o"]}
var fallos := 0


func _initialize() -> void:
	_correr.call_deferred()


func _ok(cond: bool, t: String) -> void:
	if cond:
		print("OK " + t)
	else:
		fallos += 1
		print("FALLO: " + t)


func _correr() -> void:
	_ok(Comun.MARGEN_LADO >= 0.2 - 0.0001, "1: MARGEN_LADO (ensanche en x de lo ocultable) = %.2f m (≥ 0,2)" % Comun.MARGEN_LADO)
	for s in PIEZAS:
		for id in PIEZAS[s]:
			_ok(D._es_ocultable("%s/%s" % [s, id]), "1: %s/%s es ocultable" % [s, id])
	var figura: Array = []
	for i in 9:
		for j in 3:
			figura.append(Vector3(-0.4 + i * 0.1, 0.85 + j * 0.3, 0.0))
	for nombre in SITIOS:
		var q: Vector2 = SITIOS[nombre]
		var k := Vector3(q.x, P.altura(q.x, q.y), q.y)
		var con: Array = D.tapado(k, figura, Comun.MARGEN_LADO)
		var sin: Array = D.tapado(k, figura, 0.0)
		_ok(float(con[0]) < 0.05, "2: %s: con el ensanche, tapado sin aclarar %.0f %% (< 5 %%) %s" % [nombre, float(con[0]) * 100.0, str(con[1])])
		_ok(float(sin[0]) >= float(con[0]) + 0.05, "2: %s: sin el ensanche taparía %.0f %% (al menos 5 puntos más: el arreglo hace falta) %s" % [nombre, float(sin[0]) * 100.0, str(sin[1])])
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
