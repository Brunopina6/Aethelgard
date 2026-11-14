extends SceneTree
# V12 (14/11), fase 3C: la magia Agua mejorada (vfx/agua_v12.gd), EXPERIMENTAL y apagada por defecto, en combates de
# verdad (grupo 2: tres enemigos; Kael y Lya; datos aislados; con «semilla=N» en los argumentos para que cada combate
# empiece igual). Los enemigos no actúan (su barra se vacía) y tienen PV de sobra: así cada caso es el mismo combate.
#   opción      solo existe en Auditoría o editor; elegir() la guarda en [calidad_pruebas] y activo() la lee
#   apagado     Agua, Torrente y Maremoto: no se crea ninguna pieza nueva (lo de siempre, tal cual)
#   encendido   lo mismo: la anticipación nace con el círculo y antes del golpe; el orbe con el proyectil (I y II); la
#               ola antes del primer golpe (III); cada pieza de impacto nace EN el fotograma en que baja la vida de su
#               enemigo (una por enemigo golpeado) y al final no queda ninguna
#   mismo daño  el daño a cada enemigo, el fotograma de cada golpe y la tirada siguiente del azar global son idénticos
#               con la opción apagada y encendida (los efectos no gastan tiradas de más)
#   móvil       con la calidad del móvil (0,4) hay menos gotas y nada se queda
#   destellos   con «reducir destellos» los brillos van a la mitad
#   repetir     tres Agua seguidas en el mismo combate: nunca se acumulan piezas ni nodos en la escena
#   salir       borrando el combate a mitad del impacto no queda nada (ni errores de los temporizadores)
# No toca la partida real: archivo de partida de prueba y user:// aislado del ejecutor.

const ARCHIVO := "user://prueba_magia_agua_v12.save"
const MAGIAS := [["Agua", 1], ["Agua", 2], ["Agua", 3]]
const NOMBRE := {1: "Agua", 2: "Torrente", 3: "Maremoto"}

var P
var G
var AG
var c = null
var fallos: Array = []
var hechos: Array = []
var _congelar := true


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	AG = load("res://vfx/agua_v12.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		if _congelar and c != null and is_instance_valid(c) and c.estado != "accion":
			for e in c.enemigos:
				e["atb"] = 0.0


func _limpiar_metas() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	await _esperar(10)
	_ok(AG.permitido(), "la opción solo existe en Auditoría o editor y esta prueba corre en el editor")
	_ok(AG.elegir(true) == OK and AG.activo(), "elegir(true) no la enciende")
	_ok(AG.elegir(false) == OK and not AG.activo(), "elegir(false) no la apaga")
	var cf := ConfigFile.new()
	_ok(cf.load("user://ajustes.cfg") == OK and cf.has_section_key("calidad_pruebas", AG.CLAVE), "no se guarda en [calidad_pruebas]")
	for m in MAGIAS:
		var r0: Dictionary = await _caso(false, m[1])
		var r1: Dictionary = await _caso(true, m[1])
		var nom: String = NOMBRE[m[1]]
		_ok(r0.get("danos") == r1.get("danos"), "%s: el daño cambia con la opción (%s / %s)" % [nom, r0.get("danos"), r1.get("danos")])
		_ok(r0.get("golpes") == r1.get("golpes"), "%s: el momento de los golpes cambia (%s / %s)" % [nom, r0.get("golpes"), r1.get("golpes")])
		_ok(r0.get("tirada") == r1.get("tirada"), "%s: la tirada siguiente del azar cambia (%s / %s)" % [nom, r0.get("tirada"), r1.get("tirada")])
		hechos.append("%s daños %s, golpes en los fotogramas %s" % [nom, r1.get("danos"), r1.get("golpes")])
	await _caso(true, 3, "movil")
	Engine.set_meta("reducir_destellos", true)
	await _caso(true, 1, "destellos")
	Engine.remove_meta("reducir_destellos")
	await _repetir()
	await _caso(true, 1, "salir")
	AG.elegir(false)
	_limpiar_metas()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


# Combate fijo (grupo 2) hasta el turno de Lya (Kael se defiende).
func _combate() -> bool:
	_limpiar_metas()
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	for n in ["Kael", "Lya"]:
		G.datos()[n]["nivel"] = 5
		G.datos()[n]["pv"] = -1
	Engine.set_meta("zona", "llanura")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 2)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(2)
	for e in c.enemigos:
		e["hp"] = 5000
		e["hp_max"] = 5000
	return await _turno_lya()


func _turno_lya() -> bool:
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Lya":
				return true
			c._defender()
		await _esperar(1)
	return false


func _vida() -> Array:
	var r := []
	for e in c.enemigos:
		r.append(int(e["hp"]))
	return r


# Un lanzamiento de Agua de nivel «nivel» observado fotograma a fotograma.
# modo: "" | "movil" (calidad del móvil) | "destellos" | "salir" (borra el combate a mitad del impacto)
func _caso(encendido: bool, nivel: int, modo := "") -> Dictionary:
	var caso := "%s %s%s" % [NOMBRE[nivel], "encendido" if encendido else "apagado", (" " + modo) if modo != "" else ""]
	AG.elegir(encendido)
	if not await _combate():
		_ok(false, "%s: no llega el turno de Lya" % caso)
		return {}
	if modo == "movil":
		c.calidad = c.CALIDAD_MOVIL["particulas"]
		c.max_efectos_3d = c.CALIDAD_MOVIL["max_efectos_3d"]
	var lya: Dictionary = c.actor
	lya["pm"] = 999
	var hp0 := _vida()
	var antes := hp0.duplicate()
	var vistos := {}
	var golpes: Array = []
	var carga_antes := false
	var ola_antes := false
	var proyectil_visto := false
	var max_vivos := 0
	var fr := 0
	var tras_golpe := -1
	var gotas_impacto := -1
	var brillo := -1.0
	c._elegir_hechizo("Agua", nivel, true)
	while fr < 900:
		await _esperar(1)
		fr += 1
		var vida := _vida()
		var golpeados := 0
		for i in vida.size():
			if vida[i] < antes[i]:
				golpeados += 1
		antes = vida
		var nuevos := 0
		for x in get_nodes_in_group(AG.GRUPO):
			if x.is_queued_for_deletion():
				continue
			if x.modo == "carga" and golpes.is_empty():
				carga_antes = true
			if x.modo == "ola" and golpes.is_empty():
				ola_antes = true
			if x.modo == "proyectil":
				proyectil_visto = true
			if x.modo == "impacto" and not vistos.has(x.get_instance_id()):
				vistos[x.get_instance_id()] = true
				nuevos += 1
				_ok(x.t <= 0.07, "%s: la pieza de impacto no nace en el golpe (t=%.3f)" % [caso, x.t])
				gotas_impacto = (x.datos["gotas"] as Array).size()
				brillo = x.brillo
		max_vivos = maxi(max_vivos, AG.vivos(self))
		if golpeados > 0:
			golpes.append(fr)
			if tras_golpe < 0:
				tras_golpe = fr
		_ok(nuevos == (golpeados if encendido else 0), "%s: fotograma %d, %d enemigos golpeados y %d piezas de impacto nuevas" % [caso, fr, golpeados, nuevos])
		if modo == "salir" and tras_golpe >= 0 and fr >= tras_golpe + 4:
			_ok(AG.vivos(self) > 0, "%s: no hay piezas vivas para probar la salida" % caso)
			c.queue_free()
			c = null
			await _esperar(45)                         # pasa el temporizador de 0,7 s del impacto (sin combate)
			_ok(AG.vivos(self) == 0, "%s: tras borrar el combate quedan %d piezas" % [caso, AG.vivos(self)])
			hechos.append(caso)
			return {}
		if tras_golpe >= 0 and fr >= tras_golpe + 8 and c.estado != "accion":
			break
	_ok(not golpes.is_empty(), "%s: la magia no llega a golpear" % caso)
	if encendido:
		_ok(carga_antes, "%s: no hay anticipación antes del golpe" % caso)
		_ok(vistos.size() == (3 if nivel >= 2 else 1), "%s: %d piezas de impacto (esperadas %d)" % [caso, vistos.size(), 3 if nivel >= 2 else 1])
		if nivel < 3:
			_ok(proyectil_visto, "%s: no hay orbe de agua en el proyectil" % caso)
		else:
			_ok(ola_antes, "%s: la ola no está antes del primer golpe" % caso)
		if modo == "movil":
			_ok(gotas_impacto > 0 and gotas_impacto <= 12, "%s: con la calidad del móvil hay %d gotas por impacto" % [caso, gotas_impacto])
		if modo == "destellos":
			_ok(is_equal_approx(brillo, 0.5), "%s: con reducir destellos el brillo es %s" % [caso, brillo])
		hechos.append("%s: máx. %d piezas a la vez" % [caso, max_vivos])
	else:
		_ok(max_vivos == 0, "%s: con la opción apagada aparecen %d piezas" % [caso, max_vivos])
	await _esperar(80)                                 # 2,7 s: todo se ha disipado
	_ok(AG.vivos(self) == 0, "%s: al terminar quedan %d piezas" % [caso, AG.vivos(self)])
	var danos := []
	var fin := _vida()
	for i in fin.size():
		danos.append(hp0[i] - fin[i])
	var r := {"danos": danos, "golpes": golpes, "tirada": randi()}
	c.queue_free()
	c = null
	await _esperar(5)
	return r


# Tres Agua seguidas en el mismo combate (encendida): nada se acumula.
func _repetir() -> void:
	AG.elegir(true)
	if not await _combate():
		_ok(false, "repetir: no llega el turno de Lya")
		return
	var hijos: Array = []
	for vez in 3:
		c.actor["pm"] = 999
		c._elegir_hechizo("Agua", 1, true)
		var vio := false
		for i in 400:
			await _esperar(1)
			vio = vio or AG.vivos(self, "impacto") > 0
			_ok(AG.vivos(self, "impacto") <= 1, "repetir %d: %d impactos a la vez" % [vez + 1, AG.vivos(self, "impacto")])
			if vio and c.estado != "accion":
				break
		_ok(vio, "repetir %d: no hay impacto" % (vez + 1))
		await _esperar(80)
		_ok(AG.vivos(self) == 0, "repetir %d: quedan %d piezas" % [vez + 1, AG.vivos(self)])
		hijos.append([c.escena.get_child_count(), c.sombras.get_child_count()])
		if vez < 2 and not await _turno_lya():
			_ok(false, "repetir: no vuelve el turno de Lya")
			break
	_ok(hijos.size() == 3 and hijos[0] == hijos[2], "repetir: la escena crece entre lanzamientos (%s)" % [hijos])
	hechos.append("repetir ×3: nodos de la escena %s" % [hijos])
	c.queue_free()
	c = null
	await _esperar(5)
