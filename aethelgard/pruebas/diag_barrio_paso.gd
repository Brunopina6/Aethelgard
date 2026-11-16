extends SceneTree
# DIAGNÓSTICO (16/11), no prueba: por qué Kael se para ≈ 2,5 m antes de su destino en el recorrido jugado del barrio
# integrado (A+B+C). Entra en el barrio desde el banco, pone a Kael en un sitio y un destino del recorrido, avanza y,
# en cada tramo de 0,25 m de la recta, dice si _prohibido, qué vecino ocupa, y la altura del suelo.
# Uso: --path aethelgard --script res://pruebas/diag_barrio_paso.gd -- 3d sin_prologo

const ESCENA := "res://zonas3d/barrio/barrio.tscn"


func _initialize() -> void:
	_ir.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _ir() -> void:
	var BP = load("res://banco_pruebas.gd")
	BP.preparar_partida()
	BP.poner_grupo(["Kael", "Lya", "Garon"])
	Engine.set_meta("prologo_visto", true)
	change_scene_to_file(ESCENA)
	for i in 300:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == ESCENA and current_scene.get("kael") != null:
			break
	await _frames(30)
	var v = current_scene
	for caso in [[Vector3(-34, 0, 2), Vector3(-30, 0, 2)], [Vector3(-6, 0.4, 0), Vector3(0, 0.4, 0)]]:
		v._colocar_kael(caso[0])
		await _frames(5)
		v.destino = caso[1]
		await _frames(90)
		var k: Vector3 = v.kael.global_position
		print("[diag] de %s a %s → queda en %s (destino %s)" % [str(caso[0]), str(caso[1]), str(k), str(v.destino)])
		var d: Vector3 = caso[1] - caso[0]
		d.y = 0
		for i in int(d.length() / 0.25) + 1:
			var p: Vector3 = caso[0] + d.normalized() * 0.25 * i
			var ocup := ""
			if v.vivo != null:
				for id in v.vivo.vecinos:
					var q: Vector3 = v.vivo.vecinos[id]["pos"]
					if v.vivo.vecinos[id]["visible"] and Vector2(p.x - q.x, p.z - q.z).length() < v.vivo.RADIO_OCUPA:
						ocup += "%s(%s,lugar «%s») " % [id, str(q), v.vivo.vecinos[id]["lugar"]]
			var y = v._altura_suelo(p, k.y)
			print("[diag]   %s prohibido=%s alt=%s %s" % [str(p), str(v._prohibido(p)), str(y), ocup])
	quit(0)
