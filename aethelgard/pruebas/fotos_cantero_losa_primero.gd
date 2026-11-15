extends "res://pruebas/fotos_cantero_recorrido.gd"
# V12 (15/11): «Las tres marcas del cantero» (PROPUESTA) JUGADA con los controles normales en el orden «la losa
# PRIMERO», sin hablar con el aprendiz ni abrir el arcón ni ver las marcas (el caso del fallo A de la auditoría):
#   1. antes: la misión no sale en el Diario;
#   2. la losa, resuelta con las flechas: aviso de misión nueva, premio UNA vez, el Diario con la misión y «volver», el
#      arcón sigue cerrado y ninguna pista de marcas no vistas;
#   3. guardar y cargar («Continuar») con la losa abierta: igual, y la losa sigue apartada;
#   4. el aprendiz: su escena final, el Polvo de cantera UNA vez, la misión hecha; hablar otra vez no da más;
#   5. guardar y cargar al final: nada se repite ni se pierde.
# Mismos controles y ayudas que fotos_cantero_recorrido (clics en el suelo, Intro, flechas). Partida propia. «FALLOS: n».

func _jugar() -> void:
	await _frames(3)
	_preparar()
	await _cargar_region()
	if v == null or v.get("vida") == null:
		_ok(false, "no se cargó Oakhaven 3D")
		_terminar()
		return
	var E = load("res://encargos.gd")
	var mis: Dictionary = E.de("prop_cantero")
	_ok(E.estado(mis) == "oculto", "1: la misión sale en el Diario antes de nada")
	await _diario("losa1_diario_antes")

	# 2. directos a la losa (por la plaza y la raíz, sin examinar nada)
	await _ruta(A_PLAZA + [Vector2(46.8, 26.0)] + A_RAIZ + A_LOSA, "puerta → losa")
	await _foto("losa1_losa_cerrada")
	var oro0: int = Inv.oro()
	var inc0: int = Inv.cantidad("Incienso de Ceniza")
	if await _accion("Girar los anillos"):
		var m = await _cerradura()
		if m != null:
			await _resolver(m)
			await _segundos(0.6)
			await _foto("losa1_resuelta")
			_ok(m.mensaje.text.contains("Misión: Las tres marcas del cantero"),
				"2: abrir la losa primero no anuncia la misión («%s»)" % m.mensaje.text)
			await _tecla(KEY_ENTER)
			await _segundos(1.4)
	await _foto("losa1_apartada")
	_ok(Oak.cerradura_abierta("oak_losa_cantero") and Inv.oro() == oro0 + 80
		and Inv.cantidad("Incienso de Ceniza") == inc0 + 1, "2: la losa no da su premio")
	_ok(E.estado(mis) == "activo" and E.paso_actual(mis).get("id", "") == "volver",
		"2: con la losa primero, la misión no sale con «volver» (estado %s, paso %s)" % [E.estado(mis), E.paso_actual(mis).get("id", "")])
	_ok(not Oak.cerradura_abierta(), "2: abrir la losa abre el arcón")
	var pistas: Array = E.pistas_conocidas(mis)
	_ok(not pistas.any(func(x): return "muesca" in x), "2: salen pistas de marcas no vistas: %s" % str(pistas))
	await _diario("losa1_diario_volver")

	# 3. guardar y cargar con la losa abierta
	v.vida.guardar()
	await _continuar("con la losa abierta primero")
	_ok(E.estado(mis) == "activo" and E.paso_actual(mis).get("id", "") == "volver"
		and Inv.oro() == oro0 + 80, "3: tras cargar, cambia la misión o el premio")
	_ok(v.vida.arcon.get("losa_piedra") != null and (v.vida.arcon["losa_piedra"] as Node3D).position.x > 0.6,
		"3: tras cargar, la losa no sigue apartada")
	if _kael_en().distance_to(A_LOSA[-1]) > 3.0:
		await _ruta(A_PLAZA + [Vector2(46.8, 26.0)] + A_RAIZ + A_LOSA, "tras cargar → losa")
	if await _accion("Examinar"):
		await _segundos(0.5)
		_ok(Inv.oro() == oro0 + 80, "3: examinar la losa abierta da algo")

	# 4. el aprendiz
	await _ruta(DE_LOSA_A_APRENDIZ, "losa → aprendiz")
	if await _accion("Hablar con el aprendiz"):
		var r: String = await _dialogo("losa1_aprendiz_final")
		_ok(r.ends_with("prop_cantero_fin.dtl"), "4: el aprendiz no reacciona al cincel (%s)" % r.get_file())
	await _segundos(0.4)
	await _foto("losa1_aviso_polvo")
	_ok(Inv.cantidad("Polvo de cantera") == 3 and E.estado(mis) == "hecho", "4: no da el polvo o no acaba la misión")
	if await _accion("Hablar con el aprendiz"):
		var r2: String = await _dialogo("losa1_aprendiz_despues")
		_ok(r2.ends_with("prop_cantero_despues.dtl"), "4: después, el aprendiz no dice lo nuevo (%s)" % r2.get_file())
	_ok(Inv.cantidad("Polvo de cantera") == 3, "4: hablar otra vez da más polvo")
	_ok(not Oak.cerradura_abierta(), "4: el arcón se abrió solo")
	await _diario("losa1_diario_final")

	# 5. al final
	v.vida.guardar()
	var oro2: int = Inv.oro()
	await _continuar("al final, con la losa primero")
	_ok(Inv.oro() == oro2 and Inv.cantidad("Polvo de cantera") == 3 and E.estado(mis) == "hecho",
		"5: tras cargar al final, cambia algo")
	_terminar()
