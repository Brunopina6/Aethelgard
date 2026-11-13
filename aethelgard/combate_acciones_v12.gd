extends Node
# Esgrima de Garon y magia blanca de Lya: PILOTOS (13/11/2026; especificación del usuario en
# D:\REBELUM_diagnostico\v12\expansion\encargos_13_11\ y su adaptación en docs/v12/GARON_ESGRIMA_V12.md y
# docs/v12/LYA_MAGIA_BLANCA_V12.md). APAGADOS por defecto, cada uno con su interruptor:
#   esgrima_v12      (Engine.set_meta, argumento o Ajustes [combate] esgrima): Garon gana el recurso Compás (tope 3) y
#                    tres técnicas nuevas en ESGRIMA: Punta Gemela (garon_01, básica), Guardia en Cruz (garon_02, de
#                    estado) y Cadencia de las Siete Puntas (garon_16, culminante).
#   magia_blanca_v12 (ídem, [combate] blanca): Lya gana la pestaña «BLANCA» en MAGIA con Manantial Interior (lya_09,
#                    de estado), Custodia del Pulso (lya_15, barrera) y Restitución Plena (lya_21, culminante), y en
#                    INVOCACIÓN, debajo de Érebo, a Aurel, Faro Peregrino (lya_24): solo ella invoca, una vez por combate.
# Con los dos apagados combate.gd no cambia: cada enganche pregunta antes y, si no, no hace nada (la huella es la misma).
#
# No es un sistema paralelo: usa lo que ya hay. El daño, con las fórmulas de siempre (_dano_fisico como Juicio, sin
# crítico; las defensas de los jefes, _quitar_pv, _golpe_visual); la regeneración, el estado «aliento» de las artes (el
# de Segundo Aliento: se renueva, no se suma); la barrera, la «barrera» de las artes (la que absorbe en _quitar_pv;
# no se apila: queda la mayor); revivir, Artes.revivir y _revivir_visual (los de la Lumbre de Retorno).
# Turnos: «turno propio» = cada vez que a ese héroe le llega su turno (_siguiente_turno). Ver los documentos.
# Una sola aplicación por acción: el daño se tira UNA vez y se reparte entre los contactos (la suma es el total), el
# Compás se gana una vez como mucho, y los efectos se aplican una vez al 50 % del clip.

const AnimV12 := preload("res://combate_anim_v12.gd")
const Artes := preload("res://artes.gd")

const COMPAS_MAX := 3
const PESTANA_BLANCA := 10            # valor de la pestaña «BLANCA» en _menu_magia (8 es la magia negra; 9, DÚO)
const C_ACERO := Color(0.86, 0.9, 0.98)
const C_BRONCE := Color(1.0, 0.7, 0.38)
const C_BLANCA := Color(1.0, 0.95, 0.78)

# Costes del documento (PM de referencia 100 al final de la progresión = los del juego: grupo.gd da 4 + 3 × espíritu +
# 2 por nivel, unos 100-120 a nivel 50). Sin desbloqueo por nivel en el piloto: con pocos PM salen apagadas con su motivo.
const ESGRIMA := {
	"punta_gemela": {"id": "garon_01", "nombre": "Punta Gemela", "pm": 0, "compas": 0, "mult": 1.10, "golpes": 2,
		"gana": 1, "clip": "c12_punta_gemela",
		"desc": "Dos estocadas cortas, una con cada hoja (×1,10 en total). Si acierta: +1 Compás."},
	"guardia_cruz": {"id": "garon_02", "nombre": "Guardia en Cruz", "pm": 3, "compas": 0, "mult": 0.80, "golpes": 1,
		"gana": 1, "reduce": 0.2, "clip": "c12_guardia_cruz",
		"desc": "Corte bajo (×0,80) y cruza las hojas: el próximo golpe que reciba hace un 20 % menos, hasta su turno. +1 Compás."},
	"cadencia": {"id": "garon_16", "nombre": "Cadencia de las Siete Puntas", "pm": 32, "compas": 3, "mult": 3.80,
		"golpes": 7, "gana": 0, "cd": 4, "clip": "c12_cadencia", "corto": "Cadencia",
		"desc": "Cadencia de las Siete Puntas: siete puntas en tres frases (×3,80 en total, no cada una). Gasta 3 Compás. Espera 4 turnos suyos."},
}
const ORDEN_ESGRIMA := ["punta_gemela", "guardia_cruz", "cadencia"]

const BLANCA := {
	"manantial": {"id": "lya_09", "nombre": "Manantial Interior", "pm": 14, "cura_m": 0.45, "turnos": 3,
		"a": "aliado", "clip": "c12_manantial",
		"desc": "Regenera 0,45 M al empezar cada uno de sus 3 turnos siguientes. Volver a lanzarlo renueva, no suma."},
	"custodia": {"id": "lya_15", "nombre": "Custodia del Pulso", "pm": 20, "barrera_m": 1.60, "turnos": 3,
		"a": "aliado", "clip": "c12_custodia",
		"desc": "Barrera de 1,60 M durante 3 turnos suyos: absorbe antes que los PV. No se apila: queda la mayor."},
	"restitucion": {"id": "lya_21", "nombre": "Restitución Plena", "pm": 40, "cd": 3, "a": "aliado",
		"clip": "c12_restitucion",
		"desc": "Devuelve toda la vida a un aliado y le quita la corrupción (lo que limpia la Cura). No revive. Espera 3 turnos de Lya."},
	"aurel": {"id": "lya_24", "nombre": "Aurel, Faro Peregrino", "pm": 48, "cura_m": 1.20, "revive": 0.25,
		"a": "grupo", "invocacion": true, "clip": "c12_aurel",
		"desc": "Solo Lya, una vez por combate: un faro con patas de ave levanta a los caídos con el 25 % de su vida y cura 1,20 M a los demás."},
}
const ORDEN_BLANCA := ["manantial", "custodia", "restitucion"]   # (Aurel va en INVOCACIÓN, debajo de Érebo)


# ---------------------------------------------------------------- interruptores
static func esgrima_activa() -> bool:
	return _activo("esgrima_v12", "esgrima")


static func blanca_activa() -> bool:
	return _activo("magia_blanca_v12", "blanca")


static func _activo(meta: String, clave: String) -> bool:
	if Engine.has_meta(meta):
		return bool(Engine.get_meta(meta))
	if meta in OS.get_cmdline_user_args():
		return true
	var cf := ConfigFile.new()
	if cf.load("user://ajustes.cfg") != OK:
		return false
	return bool(cf.get_value("combate", clave, false))


static func elegir_en_ajustes(clave: String, si: bool) -> Error:
	Engine.set_meta("esgrima_v12" if clave == "esgrima" else "magia_blanca_v12", si)
	var cf := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := cf.load("user://ajustes.cfg")
		if err != OK:
			return err
	cf.set_value("combate", clave, si)
	return cf.save("user://ajustes.cfg")


# combate.gd, al final de _crear_interfaz: el Compás de Garon (si la esgrima está encendida) y su indicador; con la magia
# blanca, la cuenta de turnos de Lya (para la espera de Restitución Plena).
static func crear(c: Node) -> void:
	if blanca_activa():
		for h in c.heroes:
			if h["nombre"] == "Lya":
				h["c12_turnos"] = 0
	if not esgrima_activa():
		return
	for h in c.heroes:
		if h["nombre"] == "Garon":
			h["c12_compas"] = 0
			h["c12_turnos"] = 0
			var ind := Control.new()
			ind.name = "CompasGaron"
			ind.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ind.size = Vector2(60, 20)
			ind.draw.connect(func(): _dibujar_compas(ind, h))
			c.capa.add_child(ind)
			for g in c.menu.grupo:
				if is_same(g["heroe"], h):
					ind.position = g["nombre"].position + Vector2(-66, 12)
			h["c12_indicador"] = ind


static func _dibujar_compas(n: Control, h: Dictionary) -> void:
	var v: int = int(h.get("c12_compas", 0))
	for i in COMPAS_MAX:
		var p := Vector2(10 + i * 19, 10)
		var pts := PackedVector2Array([p + Vector2(0, -8), p + Vector2(7, 0), p + Vector2(0, 8), p + Vector2(-7, 0)])
		n.draw_colored_polygon(pts, C_BRONCE if i < v else Color(0.3, 0.3, 0.35, 0.8))
		pts.append(pts[0])
		n.draw_polyline(pts, Color(0.05, 0.05, 0.08, 0.9), 1.5)


# ¿Puede pagar «quien» (no siempre el actor del turno: las pruebas preguntan por otros)? Como _puede_pagar.
static func _paga(c: Node, quien: Dictionary, pm: int) -> bool:
	return c.MODO_PRUEBAS or int(quien.get("mp", 0)) >= pm


static func compas(f: Dictionary) -> int:
	return int(f.get("c12_compas", 0))


# Gana Compás (como mucho 1 por acción; tope 3). Devuelve lo ganado.
static func ganar(c: Node, f: Dictionary, n := 1) -> int:
	if not f.has("c12_compas"):
		return 0
	var antes := compas(f)
	f["c12_compas"] = mini(COMPAS_MAX, antes + n)
	var g: int = compas(f) - antes
	if g > 0:
		c._numero_flotante(f, "+%d Compás" % g, C_BRONCE, 26, Vector2(0, -36))
	if f.has("c12_indicador") and is_instance_valid(f["c12_indicador"]):
		f["c12_indicador"].queue_redraw()
	return g


# ---------------------------------------------------------------- enganches de combate.gd (sin interruptor: nada)
# _animar_golpe, tras la defensa: la Guardia en Cruz quita el 20 % al próximo golpe (y se gasta); y Defender que de
# verdad para un golpe da a Garon 1 Compás (una vez por Defender).
static func reducir(c: Node, objetivo: Dictionary, dano: int) -> int:
	if objetivo.get("c12_cruz", false):
		objetivo.erase("c12_cruz")
		dano = maxi(1, int(dano * (1.0 - ESGRIMA["guardia_cruz"]["reduce"])))
		c._numero_flotante(objetivo, "Cruz", C_ACERO, 24, Vector2(30, -20))
	if objetivo.has("c12_compas") and objetivo.get("defendiendo", false) and not objetivo.get("c12_defensa_dio", false):
		objetivo["c12_defensa_dio"] = true
		ganar(c, objetivo, 1)
	return dano


# _animar_golpe, en el impacto: el ataque básico de Garon que acierta da 1 Compás.
static func al_golpe_basico(c: Node, origen: Dictionary, real: int, magia: String) -> void:
	if magia == "" and real > 0 and origen.has("c12_compas") and not origen.get("c12_en_tecnica", false):
		ganar(c, origen, 1)


# _siguiente_turno, al empezar el turno de un héroe: cuenta sus turnos (esperas de las técnicas) y acaba lo que dura
# «hasta su siguiente turno» (Guardia en Cruz, el Compás de Defender) o N turnos suyos (la Custodia).
static func al_turno_heroe(c: Node, f: Dictionary) -> void:
	if f.has("c12_turnos"):
		f["c12_turnos"] = int(f["c12_turnos"]) + 1
		f.erase("c12_cruz")
		f.erase("c12_defensa_dio")
		if c.has_meta("c12_pagina_esgrima"):
			c.remove_meta("c12_pagina_esgrima")
	if f.has("c12_barrera_turnos"):
		f["c12_barrera_turnos"] = int(f["c12_barrera_turnos"]) - 1
		if int(f["c12_barrera_turnos"]) <= 0:
			f.erase("c12_barrera_turnos")
			if int(f.get("barrera", 0)) > 0:
				f["barrera"] = 0
				c._numero_flotante(f, "Custodia se apaga", C_BLANCA, 22)


# ---------------------------------------------------------------- menús
# combate.gd, _menu_garon: el coste mínimo de ESGRIMA (con la esgrima v12, Punta Gemela cuesta 0). Apagada, el mismo.
static func minimo_esgrima(actor: Dictionary, minimo: int) -> int:
	if actor.has("c12_compas") and esgrima_activa():
		return 0
	return minimo


# combate.gd, _menu_esgrima: las filas de siempre, y con la esgrima v12 las tres nuevas delante, en páginas de 3 (el
# menú muestra 4 filas: «Más ›» lleva a Juicio, Giro y Guardia; contra el Coloso, Leer runas va la primera). Apagada,
# las mismas filas.
static func con_esgrima(c: Node, items: Array) -> Array:
	var nuevas := filas_esgrima(c, c.actor)
	if nuevas.is_empty():
		return items
	var lectura: Array = items.filter(func(x): return x.get("texto", "") == c.Coloso.LECTURA["nombre"])
	var todas: Array = lectura + nuevas + items.filter(func(x): return not lectura.has(x))   # (contra el Coloso, Leer runas delante)
	var ir := func(pag: int):
		c.set_meta("c12_pagina_esgrima", pag)
		c._menu_esgrima()
	return c._paginar(todas, int(c.get_meta("c12_pagina_esgrima", 0)), ir)


# Filas para ESGRIMA (combate.gd, _menu_esgrima). Apagado o no Garon: ninguna.
static func filas_esgrima(c: Node, actor: Dictionary) -> Array:
	if not esgrima_activa() or actor.get("nombre", "") != "Garon" or not actor.has("c12_compas"):
		return []
	var r: Array = []
	for k in ORDEN_ESGRIMA:
		var t: Dictionary = ESGRIMA[k]
		var motivo := motivo_esgrima(c, actor, k)
		var der: String = ("%d PM" % t["pm"]) if t["pm"] > 0 else "0 PM"
		if t["compas"] > 0:
			der = "%s · %d◆" % [der, t["compas"]]
		r.append({"texto": t.get("corto", t["nombre"]), "accion": elegir_esgrima.bind(c, k), "derecha": der, "apagado": motivo != "",
			"falta_pm": not _paga(c, actor, t["pm"]),
			"desc": ("%s  (Compás %d/%d)" % [t["desc"], compas(actor), COMPAS_MAX]) if motivo == "" else motivo})
	return r


static func motivo_esgrima(c: Node, actor: Dictionary, k: String) -> String:
	var t: Dictionary = ESGRIMA[k]
	if not _paga(c, actor, t["pm"]):
		return Artes.motivo_pm(t["pm"], actor["mp"])
	if compas(actor) < int(t["compas"]):
		return "Necesitas %d Compás (tienes %d)." % [t["compas"], compas(actor)]
	if t.has("cd") and actor.has("c12_cd_" + k) and int(actor["c12_turnos"]) <= int(actor["c12_cd_" + k]):
		var faltan: int = int(actor["c12_cd_" + k]) - int(actor["c12_turnos"]) + 1
		return "Lista dentro de %d turno%s de Garon." % [faltan, "" if faltan == 1 else "s"]
	if c._alcanzables().is_empty():
		return "No hay a quién alcanzar."
	return ""


static func elegir_esgrima(c: Node, k: String) -> void:
	if c.actor == null or motivo_esgrima(c, c.actor, k) != "":
		return                                       # (se valida antes de pagar nada)
	c._pedir_objetivo(c._alcanzables(), func(obj): _m(c).i_esgrima(c, k, obj), c._menu_esgrima, "TOCA UN ENEMIGO")


# La pestaña «BLANCA» de Lya (combate.gd, _menu_magia).
static func pestana_pedida(nivel: int) -> bool:
	return nivel == PESTANA_BLANCA and blanca_activa()


static func pestana_blanca(c: Node, pestanas: Array, valor: int) -> void:
	if not blanca_activa() or c.actor == null or c.actor.get("nombre", "") != "Lya":
		return
	if pestanas.is_empty():                          # una sola pestaña de magias: se nombra para poder volver a ella
		pestanas.append({"texto": "MAGIA", "valor": valor, "ancho": 140.0, "accion": c._menu_magia.bind(valor)})
	pestanas.append({"texto": "BLANCA", "valor": PESTANA_BLANCA, "ancho": 120.0,
		"accion": c._menu_magia.bind(PESTANA_BLANCA)})
	c._encajar_pestanas(pestanas)


static func filas_blanca(c: Node, actor: Dictionary) -> Array:
	if not blanca_activa() or actor.get("nombre", "") != "Lya":
		return []
	var r: Array = []
	for k in ORDEN_BLANCA:
		var t: Dictionary = BLANCA[k]
		var motivo := motivo_blanca(c, actor, k)
		r.append({"texto": t["nombre"], "accion": elegir_blanca.bind(c, k), "icono": "Cura",
			"derecha": "PM ∞" if c.MODO_PRUEBAS else "%d PM" % t["pm"], "apagado": motivo != "",
			"falta_pm": not _paga(c, actor, t["pm"]), "desc": t["desc"] if motivo == "" else motivo})
	return r


static func motivo_blanca(c: Node, actor: Dictionary, k: String) -> String:
	var t: Dictionary = BLANCA[k]
	if actor.get("nombre", "") != "Lya":
		return "Solo Lya."
	if not _paga(c, actor, t["pm"]):
		return Artes.motivo_pm(t["pm"], actor["mp"])
	if t.get("invocacion", false) and c.has_meta("c12_aurel_usada"):
		return "Aurel ya acudió en este combate."
	if t.has("cd") and actor.has("c12_cd_" + k) and int(actor.get("c12_turnos", 0)) <= int(actor["c12_cd_" + k]):
		var faltan: int = int(actor["c12_cd_" + k]) - int(actor["c12_turnos"]) + 1
		return "Lista dentro de %d turno%s de Lya." % [faltan, "" if faltan == 1 else "s"]
	if t["a"] == "aliado" and c.heroes.filter(func(h): return h["hp"] > 0).is_empty():
		return "No hay a quién."
	return ""


# M, la potencia de curación de Lya: la misma cuenta que la Cura (combate.gd: «d.dano × magia_mult + magia_extra») con
# una base de 50 (la Cura I cura 45). Ver LYA_MAGIA_BLANCA_V12.md.
static func potencia(f: Dictionary) -> float:
	return 50.0 * float(f.get("magia_mult", 1.0)) + float(f.get("magia_extra", 0))


# combate.gd, _menu_lya: con Aurel disponible, INVOCACIÓN se abre aunque la Armonía no esté llena (Érebo sigue apagado
# con su motivo). Apagada la magia blanca, lo de siempre.
static func invocacion_abierta(c: Node, actor: Dictionary, lista: bool) -> bool:
	return lista or (blanca_activa() and actor.get("nombre", "") == "Lya" and motivo_blanca(c, actor, "aurel") == "")


# combate.gd, _invocar: debajo de Érebo, Aurel (solo Lya, con la magia blanca encendida). Apagada, la lista de siempre.
static func filas_invocacion(c: Node, actor: Dictionary, filas: Array) -> Array:
	if not blanca_activa() or actor.get("nombre", "") != "Lya":
		return filas
	var t: Dictionary = BLANCA["aurel"]
	var motivo := motivo_blanca(c, actor, "aurel")
	return filas + [{"texto": "Aurel", "icono": "Cura", "derecha": "PM ∞" if c.MODO_PRUEBAS else "%d PM" % t["pm"],
		"accion": elegir_blanca.bind(c, "aurel"), "apagado": motivo != "", "falta_pm": not _paga(c, actor, t["pm"]),
		"motivo": motivo, "desc": ("%s: %s" % [t["nombre"], t["desc"]]) if motivo == "" else motivo}]


static func elegir_blanca(c: Node, k: String) -> void:
	if c.actor == null or motivo_blanca(c, c.actor, k) != "":
		return
	var vuelve: Callable = c._invocar if BLANCA[k].get("invocacion", false) else c._menu_magia.bind(PESTANA_BLANCA)
	if BLANCA[k]["a"] == "aliado":
		c._pedir_objetivo(c.heroes.filter(func(h): return h["hp"] > 0), func(obj): _m(c).i_blanca(c, k, obj), vuelve,
			"TOCA A UN ALIADO")
	else:
		_m(c).i_blanca(c, k, {})


# ---------------------------------------------------------------- el motor (un nodo hijo del combate: si el combate se
# cierra a medias, Godot no reanuda sus esperas)
static func _m(c: Node) -> Node:
	var m := c.get_node_or_null("AccionesV12")
	if m == null:
		m = load("res://combate_acciones_v12.gd").new()
		m.name = "AccionesV12"
		c.add_child(m)
	return m


func _esperar(c: Node, s: float) -> void:
	if s > 0.0:
		await c.get_tree().create_timer(s).timeout


func _contar(c: Node, clave: String) -> void:      # (para las pruebas: cuántas veces se aplicó algo)
	c.set_meta(clave, int(c.get_meta(clave, 0)) + 1)


# Una técnica de esgrima de Garon. Se cobra al confirmar el objetivo (PM y Compás), una vez.
func i_esgrima(c: Node, k: String, obj: Dictionary) -> void:
	var quien: Dictionary = c.actor
	if motivo_esgrima(c, quien, k) != "" or obj.get("hp", 0) <= 0:
		c._mostrar_menu()
		return
	var t: Dictionary = ESGRIMA[k]
	c._ocultar_menu()
	c.estado = "accion"
	c._gastar_pm(quien, t["pm"])
	if t["compas"] > 0:
		quien["c12_compas"] = compas(quien) - int(t["compas"])
		if quien.has("c12_indicador"):
			quien["c12_indicador"].queue_redraw()
	if t.has("cd"):
		quien["c12_cd_" + k] = int(quien["c12_turnos"]) + int(t["cd"])
	quien["c12_en_tecnica"] = true
	c._actualizar()
	c.registro.text = "Garon usa %s" % t["nombre"]
	c._numero_flotante(quien, t["nombre"], c.menu.COLOR_HEROE.get("Garon", Color.WHITE), 30)
	_contar(c, "c12_aplicaciones_" + k)
	# el daño, UNA vez con la fórmula de siempre (como Juicio y Giro: sin crítico), repartido entre los contactos (la
	# suma de las partes es exactamente el total)
	var total: int = c._dano_fisico(quien, t["mult"])
	var n: int = t["golpes"]
	var partes: Array = []
	for i in n:
		partes.append(int(total / n) + (1 if i < total % n else 0))
	c.set_meta("c12_ultimo_total", total)            # (las pruebas comparan la suma de lo que llega con el total)
	c.set_meta("c12_ultimo_real", 0)
	var acerto := [false]
	var hechos := [0]
	var contacto := func(i: int):
		if obj["hp"] <= 0 or i >= n or i < hechos[0]:   # cada contacto, una vez
			return
		hechos[0] = i + 1
		var dd: int = c.Coloso.dano_recibido(int(partes[i]), "", quien, obj)   # las defensas de los jefes, como Juicio
		dd = c.Vidracran.dano_recibido(dd, "", quien, obj)
		dd = c.Humbaba.dano_recibido(dd, "", quien, obj)
		var real: int = c._quitar_pv(obj, dd)
		_contar(c, "c12_contactos")
		c.set_meta("c12_ultimo_real", int(c.get_meta("c12_ultimo_real", 0)) + real)
		if i == 0 or n == 2 or (n == 7 and i in [3, 6]):   # Cadencia: tres golpes de audio (doc); dos estocadas: dos
			AnimV12._sonido(c).golpe(n == 7 and i == 6, false, 0.0 if i == 0 or i == 6 else -5.0)
		if i == 0 or i == n - 1:
			AnimV12._sonido(c).recibe(obj)
		c._golpe_visual(obj, real, c._efecto_embuir(quien, obj) if i == 0 else "", false, 1.0)
		_marca_acero(c, obj, i, n)
		if real > 0:
			acerto[0] = true
	await _animar_esgrima(c, quien, obj, k, contacto)
	quien.erase("c12_en_tecnica")
	if acerto[0] and int(t["gana"]) > 0:
		ganar(c, quien, 1)
	if k == "guardia_cruz" and quien["hp"] > 0:
		quien["c12_cruz"] = true
		_cruz_visual(c, quien)
	c._actualizar()
	c._terminar_turno()


# Presentación: con Garon v2, su carrera (o saltito), el clip de la técnica con sus contactos y la vuelta (las mismas
# piezas que el ataque de la animación v12); con el Garon original, su Juicio de siempre con los contactos seguidos.
func _animar_esgrima(c: Node, o: Dictionary, obj: Dictionary, k: String, contacto: Callable) -> void:
	var p = o.get("p3d", null)
	var t: Dictionary = ESGRIMA[k]
	if p == null or p.get("es_v2") != true or not AnimV12._preparar(p, "Garon") or not p.anim.has_animation(t["clip"]):
		var golpear := func():                       # (los contactos seguidos, 0,12 s entre uno y otro)
			for i in t["golpes"]:
				if not is_instance_valid(c):
					return
				contacto.call(i)
				if i < t["golpes"] - 1:
					await c.get_tree().create_timer(0.12).timeout
		if p != null and p.has_method("atacar_juicio"):
			await c._anim_ataque_3d(o, obj, golpear, "atacar_juicio")
			await _esperar(c, 0.12 * (t["golpes"] - 1))
		else:
			await golpear.call()
		return
	AnimV12._accion(c, 1, "atacar_juicio")           # (con la pausa del ATB de la animación v12: como Juicio)
	await _animar_esgrima_v2(c, o, obj, k, contacto)
	await AnimV12._fin_accion(c)


func _animar_esgrima_v2(c: Node, o: Dictionary, obj: Dictionary, k: String, contacto: Callable) -> void:
	var p = o["p3d"]
	var t: Dictionary = ESGRIMA[k]
	var m = AnimV12._m(c)
	_contar(c, "c12_via_clip")
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var hueco: float = c.ANIM[o["modelo"]].get("distancia", 120.0) + c.ANIM[obj["modelo"]].get("distancia", 120.0) * 0.4
	var destino := base + Vector2(c._centro(obj).x + hueco - c._centro(o).x, (c._pos_ataque(obj).y - o["pos"].y) * 0.8)
	if obj.has("centro_ofs") and o.has("centro_ofs"):
		destino.y = base.y + (c._suelo_de(obj).y - c._suelo_de(o).y)
	var sitio = c._sitio_golpe(o, obj)
	if sitio != null:
		destino = sitio
	o["animando"] = true
	rig.z_index = 5
	p.mirar(Vector3(-1, 0, 0.1), 0.12)
	if k == "cadencia":                              # la culminante se anuncia: cruza y abre las hojas, y la cámara
		AnimV12._clip(p, "c12_tecnica_carga", 0.15)
		await _esperar(c, 0.6)
		c._destello(c._centro(o) + Vector2(0, -20), C_BRONCE.lightened(0.3), 1.0)
		await _esperar(c, 0.2)
	else:
		AnimV12._clip(p, "c12_arranque", 0.1)
		await _esperar(c, 0.24)
	await m._ir_y_frenar(c, o, destino, 1.1)
	if k == "cadencia":
		AnimV12.camara(c, (c._centro(o) + c._centro(obj)) * 0.5, 1.09, 0.4, 2.0, 0.5)
	var d := AnimV12._clip(p, t["clip"], 0.12)
	var eventos: Array = []                          # los instantes de contacto del clip (los del JSON)
	var datos = JSON.parse_string(FileAccess.get_file_as_string("res://personajes/heroes_v2/garon/garon_v2_combate_v12.json"))
	var ev: Dictionary = datos["clips"][t["clip"]]["eventos"] if datos is Dictionary else {}
	for kk in ev:
		eventos.append(float(ev[kk]))
	eventos.sort()
	var ya := 0.0
	for i in eventos.size():
		await _esperar(c, eventos[i] - ya)
		ya = eventos[i]
		contacto.call(i)
		m._parada(c, [o, obj], 0.04 if eventos.size() > 2 else AnimV12.PARADA)
	await _esperar(c, d - ya)
	await m._volver_corriendo(c, o, base)
	rig.z_index = 0
	o["animando"] = false


# Una magia blanca de Lya (o la invocación). Se cobra al confirmar; el efecto, una vez, al 50 % del clip.
func i_blanca(c: Node, k: String, obj: Dictionary) -> void:
	var quien: Dictionary = c.actor
	var t: Dictionary = BLANCA[k]
	if motivo_blanca(c, quien, k) != "" or (t["a"] == "aliado" and obj.get("hp", 0) <= 0):
		c._mostrar_menu()
		return
	c._ocultar_menu()
	c.estado = "accion"
	c._gastar_pm(quien, t["pm"])
	if t.get("invocacion", false):
		c.set_meta("c12_aurel_usada", true)
	if t.has("cd"):
		quien["c12_cd_" + k] = int(quien.get("c12_turnos", 0)) + int(t["cd"])
	c._actualizar()
	c.registro.text = "Lya %s %s" % ["invoca a" if t.get("invocacion", false) else "lanza", t["nombre"]]
	_contar(c, "c12_aplicaciones_" + k)
	quien["animando"] = true
	quien["curo"] = true                             # (como Cura: los enemigos listos irán a por quien cura)
	var circulo = c._carga_magia(quien, "Cura", 1.3 if t.get("invocacion", false) else 1.0)
	var p = quien.get("p3d", null)
	var d := 0.0
	var lanza := 0.5
	var v2: bool = p != null and p.get("es_v2") == true and AnimV12._preparar(p, "Lya") and p.anim.has_animation(t["clip"])
	if v2:
		AnimV12._accion(c, 1, "magia_Lya")           # (con la pausa del ATB de la animación v12: como sus magias)
		_contar(c, "c12_via_clip")
		d = AnimV12._clip(p, t["clip"], 0.15)
		lanza = d * 0.5
		if t.get("invocacion", false):
			AnimV12.camara(c, Vector2(c._centro(quien).x - 200, c._centro(quien).y), 1.06, 0.5, 2.0, 0.6)
		await _esperar(c, lanza)
	elif p != null and p.has_method("lanzar_magia"):
		await p.lanzar_magia()
	else:
		await _esperar(c, 0.5)
	var M: float = potencia(quien)
	match k:
		"manantial":
			var regen: float = t["cura_m"] * M / maxf(1.0, float(obj["hp_max"]))
			Artes.dar_aliento(obj, t["turnos"], regen)
			_brotes(c, obj)
			c._sonar("aliento")
			c._numero_flotante(obj, "Manantial", C_BLANCA, 30)
		"custodia":
			var cantidad := int(t["barrera_m"] * M)
			if cantidad >= int(obj.get("barrera", 0)):
				obj["barrera"] = cantidad
				obj["barrera_escarcha"] = false
				obj["c12_barrera_turnos"] = t["turnos"]
			c._sena_arte("guardia", obj)
			c._sonar("guardia")
			c._numero_flotante(obj, "Custodia %d" % int(obj["barrera"]), C_BLANCA, 30)
		"restitucion":
			c.Humbaba.al_curar(obj)                  # (lo que limpia la Cura: la corrupción de Humbaba)
			var cura: int = obj["hp_max"] - obj["hp"]
			obj["hp"] = obj["hp_max"]
			c._efecto_cura(obj)
			c._destello(c._centro(obj), C_BLANCA, 1.4)   # (un destello sobre él: sin blanco a pantalla completa)
			c._numero_flotante(obj, "+%d" % cura, c.C_CURA, 36)
			c.set_meta("c12_ultima_cura", cura)
		"aurel":
			await _aurel(c, quien, t, M)
	c._actualizar()
	c._quitar_carga(circulo)
	await _esperar(c, maxf(0.6, d - lanza) if d > 0.0 else 1.0)
	if p != null and is_instance_valid(p):
		if v2 and p.has_method("reposo"):
			p.reposo()
		elif p.has_method("fin_magia"):
			p.fin_magia()
	if v2:
		await AnimV12._fin_accion(c)
	quien["animando"] = false
	c._terminar_turno()


# Aurel, Faro Peregrino: una aparición breve (1,4 s; un faro con patas de ave dibujado en 2D, sin modelo ni luz) y su
# efecto, una vez: los caídos se levantan con el 25 % y los demás se curan 1,20 M.
func _aurel(c: Node, quien: Dictionary, t: Dictionary, M: float) -> void:
	var vivos: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	var pie := Vector2(-INF, 0.0)                     # detrás del grupo, a la derecha del último, con los pies en su suelo
	var suelo := 0.0
	for h in c.heroes:
		pie.x = maxf(pie.x, c._suelo_de(h).x)
		suelo += c._suelo_de(h).y / c.heroes.size()
	pie = Vector2(pie.x + 120.0, suelo - 40.0)
	var dur := 1.9                                   # (el documento: visible 0,5-1,5 s; con la entrada y la salida, 1,9)
	var faro: Node2D = c._dibujo(pie, dur, _pinta_aurel, false)
	faro.z_index = -1
	faro.scale = Vector2(1.45, 1.45)
	var luz: Node2D = c._dibujo(pie, dur, _pinta_aurel_luz, true)   # (su luz, aditiva, delante: el haz barre a los enemigos)
	luz.z_index = 4
	luz.scale = faro.scale
	c._sonar("aliento")
	await _esperar(c, 0.8)
	for h in c.heroes:
		if h["hp"] <= 0:
			var pv: int = Artes.revivir(h, t["revive"], c.cola)
			c._revivir_visual(h)
			c._numero_flotante(h, "+%d" % pv, c.C_CURA, 34)
			_contar(c, "c12_revividos")
		elif vivos.has(h):
			var cura: int = mini(int(t["cura_m"] * M), h["hp_max"] - h["hp"])
			h["hp"] += cura
			c._efecto_cura(h)
			c._numero_flotante(h, "+%d" % cura, c.C_CURA, 34)
	await _esperar(c, 0.7)


# Aurel dibujado (2D, sin texturas): una torre de faro de piedra clara con dos franjas, su galería y la linterna, sobre
# dos patas de ave (rodilla hacia atrás, tres dedos) que pisan el suelo y se alternan; entra subiendo y sale apagándose.
static func _a_aurel(k: float) -> float:
	return clampf(minf(k / 0.2, (1.0 - k) / 0.22), 0.0, 1.0)


static func _pinta_aurel(n: Node2D, k: float) -> void:
	var a := _a_aurel(k)
	var sube := (1.0 - a) * 18.0
	var paso := sin(k * TAU * 1.5)
	var pata := Color(0.6, 0.44, 0.24, a)
	var oscuro := Color(0.3, 0.24, 0.2, a)
	for lado in [-1.0, 1.0]:
		var cad := Vector2(lado * 13.0, -104.0 + sube)
		var alza: float = maxf(0.0, paso * lado) * 10.0
		var tob := Vector2(lado * 13.0 - 6.0 - alza * 0.4, -16.0 - alza)
		var rod := Vector2(lado * 13.0 + 20.0, (cad.y + tob.y) * 0.5)   # la rodilla de ave, hacia atrás
		n.draw_polyline(PackedVector2Array([cad, rod, tob]), pata, 8.0, true)
		n.draw_circle(rod, 5.0, pata)
		for dedo in [Vector2(-24, 2), Vector2(-12, 5), Vector2(9, 1)]:
			n.draw_line(tob, tob + dedo + Vector2(0, alza), pata, 3.0, true)
	var y0 := -100.0 + sube
	var y1 := -228.0 + sube
	var ancho := func(y: float) -> float: return lerpf(30.0, 19.0, (y - y0) / (y1 - y0))
	var cuerpo := PackedVector2Array([Vector2(-30, y0), Vector2(30, y0), Vector2(19, y1), Vector2(-19, y1)])
	n.draw_colored_polygon(cuerpo, Color(0.94, 0.9, 0.82, a))
	for franja in [[-132.0, -146.0], [-176.0, -190.0]]:                # dos franjas de color teja
		var ya: float = franja[0] + sube
		var yb: float = franja[1] + sube
		n.draw_colored_polygon(PackedVector2Array([Vector2(-ancho.call(ya), ya), Vector2(ancho.call(ya), ya),
			Vector2(ancho.call(yb), yb), Vector2(-ancho.call(yb), yb)]), Color(0.7, 0.42, 0.34, a))
	n.draw_colored_polygon(PackedVector2Array([Vector2(-8, y0), Vector2(8, y0), Vector2(8, y0 - 18), Vector2(0, y0 - 24),
		Vector2(-8, y0 - 18)]), oscuro)                                    # la puerta
	n.draw_line(Vector2(0, -158 + sube), Vector2(0, -166 + sube), oscuro, 3.0)   # una ventana
	cuerpo.append(cuerpo[0])
	n.draw_polyline(cuerpo, Color(0.45, 0.38, 0.33, a), 2.0, true)
	n.draw_rect(Rect2(-26, y1 - 6, 52, 6), oscuro)                         # la galería
	var brillo := 0.85 + 0.15 * sin(k * 30.0)
	n.draw_rect(Rect2(-14, y1 - 30, 28, 24), Color(1.0, 0.86 * brillo, 0.5 * brillo, a))   # la linterna
	for x in [-14.0, 0.0, 14.0]:
		n.draw_line(Vector2(x, y1 - 30), Vector2(x, y1 - 6), oscuro, 2.0)
	n.draw_colored_polygon(PackedVector2Array([Vector2(-19, y1 - 30), Vector2(19, y1 - 30), Vector2(0, y1 - 52)]), oscuro)
	n.draw_circle(Vector2(0, y1 - 55), 3.5, Color(0.9, 0.75, 0.4, a))


static func _pinta_aurel_luz(n: Node2D, k: float) -> void:
	var a := _a_aurel(k)
	var centro := Vector2(0, -246.0 + (1.0 - a) * 18.0)
	for i in 4:
		n.draw_circle(centro, 16.0 + i * 14.0, Color(1.0, 0.82, 0.45, 0.16 * a))
	var giro: float = PI + sin(k * PI * 1.6) * 0.32                      # el haz barre hacia los enemigos
	var dir := Vector2(cos(giro), sin(giro))
	var lado := Vector2(-dir.y, dir.x)
	n.draw_colored_polygon(PackedVector2Array([centro + lado * 8.0, centro - lado * 8.0,
		centro + dir * 440.0 - lado * 60.0, centro + dir * 440.0 + lado * 60.0]), Color(1.0, 0.9, 0.62, 0.09 * a))


# ---------------------------------------------------------------- efectos (ligeros: trazos y sprites con el material
# aditivo del combate; sin partículas que gasten el azar, sin luces, sin texturas nuevas)
static func _marca_acero(c: Node, obj: Dictionary, i: int, n: int) -> void:
	var ctr: Vector2 = c._centro(obj) + Vector2(sin(i * 2.3) * 26.0, cos(i * 1.7) * 30.0)
	var largo := 46.0 if n > 2 else 70.0
	var dir := Vector2(cos(0.5 + i * 0.9), sin(0.5 + i * 0.9))
	c._trazo_luz(PackedVector2Array([ctr - dir * largo * 0.5, ctr + dir * largo * 0.5]), C_ACERO, 0.35 if n > 2 else 0.5, 0.18)


static func _cruz_visual(c: Node, f: Dictionary) -> void:
	var ctr: Vector2 = c._centro(f) + Vector2(-30, -10)
	c._trazo_luz(PackedVector2Array([ctr + Vector2(-38, -38), ctr + Vector2(38, 38)]), C_ACERO, 0.8, 0.6)
	c._trazo_luz(PackedVector2Array([ctr + Vector2(38, -38), ctr + Vector2(-38, 38)]), C_ACERO, 0.8, 0.6)
	c._numero_flotante(f, "Guardia en Cruz", C_ACERO, 26, Vector2(0, -30))


static func _brotes(c: Node, f: Dictionary) -> void:
	for i in 3:
		var s: Sprite2D = c._brillo(Color(0.75, 1.0, 0.7))
		s.position = c._suelo_de(f) + Vector2(-30 + i * 30, -10)
		s.scale = Vector2(0.05, 0.05)
		c.escena.add_child(s)
		var tw: Tween = c.create_tween().bind_node(s)
		tw.tween_interval(i * 0.15)
		tw.tween_property(s, "scale", Vector2(0.25, 0.4), 0.35)
		tw.parallel().tween_property(s, "position:y", s.position.y - 60.0, 0.6)
		tw.tween_property(s, "modulate:a", 0.0, 0.4)
		tw.tween_callback(s.queue_free)
