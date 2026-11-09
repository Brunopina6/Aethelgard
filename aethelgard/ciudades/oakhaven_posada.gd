extends RefCounted
# La posada del Cuervo Oxidado (narrativa, 09/11): los servicios de la posadera —dormir, comer y escuchar rumores— como
# datos y funciones que usan igual la ciudad 2D (ciudad_oakhaven.gd) y el Oakhaven 3D que hará gráficos (T-103). Aquí no
# hay escena ni interfaz: cada una pinta los servicios a su manera y llama a estas funciones.
#
#   const Posada := preload("res://ciudades/oakhaven_posada.gd")
#   for s in Posada.servicios(): ...                    # id, nombre, detalle y precio de ahora (la noche gratis cuenta)
#   var r := Posada.dormir()       # {"ok", "gratis", "texto", "escena"}: cobra (o usa la noche gratis) y cura al grupo;
#                                  # «escena», el diálogo al despertar (charla de posada o la escena de siempre)
#   var c := Posada.comer()        # {"ok", "texto"}: cobra y recupera los PV del grupo (los PM, no)
#   var m := Posada.rumor()        # {"id", "texto", "lugar"}: el siguiente rumor sin oír (y queda oído)
#
# Lo que se guarda: lo mismo que ya guardaba la posada (oro, vida del grupo, la noche gratis) y los rumores oídos como
# estado de la ciudad («rumor_…» en «mazmorras»): una partida antigua no lo tiene y vale «sin oír».
# «Comer» es nuevo: su precio y su efecto son una PROPUESTA de narrativa (a revisar con combate y el coordinador).

const Oak := preload("res://ciudades/oakhaven.gd")
const PRECIO_DORMIR := 30             # el de siempre (zona.gd, PRECIO_POSADA: la prueba lo compara)
const PRECIO_COMER := 10              # propuesta

const SERVICIOS := [
	{"id": "dormir", "nombre": "Dormir", "detalle": "Una cama hasta el alba. PV y PM recuperados.", "precio": PRECIO_DORMIR},
	{"id": "comer", "nombre": "Sopa del día", "detalle": "Un plato caliente. Recupera los PV; los PM, no.", "precio": PRECIO_COMER},
	{"id": "rumores", "nombre": "Rumores", "detalle": "Lo que se cuenta en las mesas.", "precio": 0},
]

# La sopa del día: la primera que cumpla su condición (de la lista, de arriba abajo).
const SOPAS := [
	{"texto": "Sopa con un toque de lavanda. No se lo digas a Rosa.", "si": "hito:oak_lavanda"},
	{"texto": "Sopa de la casa, con el cucharón de verdad. Se nota.", "si": "hito:oak_favores"},
	{"texto": "Sopa de puerros. La de siempre, la que no falla."},
]

# Los rumores, de las mesas del fondo: apuntan a sitios que ya existen (un lugar del mapa o un secreto de la ciudad). Se
# cuentan de arriba abajo; «hasta»: condición con la que ya no tiene gracia contarlo (lo has visto); «cofre»: igual, si
# ese cofre ya está abierto. Ninguno revela nada que no diga ya el juego.
const RUMORES := [
	{"id": "rumor_pastos", "lugar": "Pastos Verdes", "hasta": "hito:pv_02",
		"texto": "En los Pastos hay un farolero que enciende los faroles a pleno día. Raro, raro."},
	{"id": "rumor_callejon", "lugar": "Oakhaven", "secreto": "oak_secreto_velas", "hasta": "estado:grieta",
		"texto": "En el callejón del Cuervo hay una pared que huele a cera de vela. Y nadie vive detrás."},
	{"id": "rumor_ronda", "lugar": "Oakhaven", "secreto": "oak_secreto_ronda", "cofre": "oak_cofre_ronda",
		"texto": "Desde el mercado se ve brillar algo en la muralla del este. Los niños no pueden subir."},
	{"id": "rumor_raices", "lugar": "Oakhaven", "secreto": "oak_secreto_raices", "cofre": "oak_cofre_raices",
		"texto": "Doña Encina dice que el roble guarda algo entre las raíces. Y no habla de ardillas."},
	{"id": "rumor_bosque", "lugar": "Gran Bosque Verde",
		"texto": "Del Gran Bosque Verde ya no baja nadie con hierbas. Algo ha cambiado allí dentro."},
	{"id": "rumor_garganta", "lugar": "Garganta del Diablo",
		"texto": "En la Garganta del Diablo los puentes cuelgan sobre nada. Y algo grande espera abajo."},
	{"id": "rumor_sunken", "lugar": "Sunken City",
		"texto": "Sunken City está dentro de un barco de guerra. Un barco. Entero. Y la gente vive ahí."},
	{"id": "rumor_arena", "lugar": "Mar de Arena de Calid",
		"texto": "Un buhonero juraba que bajo el Mar de Arena de Calid hay ruinas enteras."},
	{"id": "rumor_cumbres", "lugar": "Cumbres de Ciclópea",
		"texto": "Los que bajan de las Cumbres de Ciclópea traen hielo en la barba y pocas ganas de hablar."},
]
const SIN_RUMORES := "Hoy las mesas solo hablan de la niebla. Vuelve otra noche."


static func _p():
	return load("res://progreso.gd")


# Los servicios con su precio de ahora (dormir es gratis si la posadera invita).
static func servicios() -> Array:
	var r: Array = []
	for s in SERVICIOS:
		var x: Dictionary = s.duplicate()
		if x["id"] == "dormir" and _p().estado(Oak.NOMBRE, "noche_gratis"):
			x["precio"] = 0
			x["detalle"] = Oak.TEXTO_NOCHE_GRATIS
		if x["id"] == "comer":
			x["detalle"] = sopa_del_dia()
		r.append(x)
	return r


# Cobra la noche: la gratis si la hay (la gasta) o PRECIO_DORMIR. false si no hay monedas.
static func pagar_noche() -> bool:
	if Oak.usar_noche_gratis():
		return true
	return load("res://inventario.gd").gastar_oro(PRECIO_DORMIR)


static func dormir() -> Dictionary:
	var gratis: bool = _p().estado(Oak.NOMBRE, "noche_gratis")
	if not pagar_noche():
		return {"ok": false, "gratis": false, "escena": "",
			"texto": "No tienes monedas suficientes (la posada cuesta %d)." % PRECIO_DORMIR}
	load("res://grupo.gd").curar_todos()
	return {"ok": true, "gratis": gratis, "escena": Oak.escena_al_despertar(),
		"texto": Oak.TEXTO_NOCHE_GRATIS if gratis else "Descansáis en la posada. PV y PM recuperados."}


static func comer() -> Dictionary:
	if not load("res://inventario.gd").gastar_oro(PRECIO_COMER):
		return {"ok": false, "texto": "No te llega para la sopa (cuesta %d)." % PRECIO_COMER}
	var G = load("res://grupo.gd")
	for n in G.activos():
		var e: Dictionary = G.estadisticas(n)
		G.guardar_vida(n, e["pv_max"], int(G.datos()[n]["pm"]))
	return {"ok": true, "texto": sopa_del_dia() + " PV recuperados."}


static func sopa_del_dia() -> String:
	for s in SOPAS:
		if not s.has("si") or Oak.cumple(s["si"]):
			return s["texto"]
	return SOPAS[-1]["texto"]


static func rumor_oido(id: String) -> bool:
	return _p().estado(Oak.NOMBRE, id)


# Los rumores que aún tienen gracia: sin oír, y sin haber visto ya lo que cuentan.
static func rumores_disponibles() -> Array:
	var abiertos: Dictionary = Engine.get_meta("cofres_abiertos", {})
	return RUMORES.filter(func(r): return not rumor_oido(r["id"]) \
		and not (r.has("hasta") and Oak.cumple(r["hasta"])) and not abiertos.has(r.get("cofre", "")))


# El siguiente rumor (queda oído), o {"id": "", "texto": SIN_RUMORES} si no hay.
static func rumor() -> Dictionary:
	var d := rumores_disponibles()
	if d.is_empty():
		return {"id": "", "texto": SIN_RUMORES, "lugar": ""}
	var r: Dictionary = d[0]
	_p().poner_estado(Oak.NOMBRE, r["id"])
	return {"id": r["id"], "texto": r["texto"], "lugar": r["lugar"]}
