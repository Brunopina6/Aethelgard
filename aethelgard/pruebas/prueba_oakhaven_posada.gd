extends SceneTree
# La posada del Cuervo Oxidado como datos (ciudades/oakhaven_posada.gd), para la ciudad 2D y el Oakhaven 3D (T-103).
# Sin ventana, con «-- sin_prologo». Partida propia (user://prueba_oakhaven_posada.save).
#   1. Los datos: dormir, comer y rumores; dormir cuesta lo mismo que en zona.gd; cada rumor apunta a un lugar del mapa o
#      a un secreto de Oakhaven que existen, con condiciones bien escritas y cofres que existen; textos que caben en la
#      caja (110 letras) y sin nada de Érebo (D-033), de lo que espera decisión del usuario (D-073) ni de Final Fantasy X.
#   2. Dormir: cobra y cura al grupo (PV y PM); con la noche gratis no cobra y la gasta; sin monedas, no; devuelve la
#      escena al despertar (una charla de posada si toca).
#   3. Comer: cobra y recupera los PV, no los PM; sin monedas, no; la sopa cambia con las misiones hechas.
#   4. Rumores: de uno en uno y sin repetir; se saltan los que ya no tienen gracia (lo visto, el cofre abierto); al
#      acabarse, la frase de siempre; lo oído se guarda y se lee, y una partida antigua sin ello vale «sin oír».
#   5. La ciudad 2D cobra la posada con este módulo (la noche gratis sigue saliendo como siempre).
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const Oak := preload("res://ciudades/oakhaven.gd")
const Posada := preload("res://ciudades/oakhaven_posada.gd")
const ARCHIVO := "user://prueba_oakhaven_posada.save"
const PROHIBIDO := ["erebo", "ladron de corazones", "corazones", "recuerdo", "memoria", "olvido", "rocio", "cripta",
	"trampilla", "conclave", "crio", "hermano", "diecisiete", "alcantarilla", "tidus", "yuna", "spira", "sinh"]

var P
var G
var I
var fallos: Array = []


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos.append(t)
	print("FALLO: ", t)


func _plano(t: String) -> String:
	var r := t.to_lower()
	for p in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		r = r.replace(p[0], p[1])
	return r


func _limpiar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("prologo_visto", true)
	G.empezar_solo()
	G.unir("Lya")


func _probar() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_datos()
	_dormir()
	_comer()
	_rumores()
	_en_2d()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	Engine.remove_meta("archivo_partida_prueba")
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _texto(t: String, donde: String, maximo := 110) -> void:
	if t.length() > maximo:
		_fallo("1: %s: %d letras: «%s»" % [donde, t.length(), t])
	var p := _plano(t)
	for x in PROHIBIDO:
		if RegEx.create_from_string("\\b%s" % x).search(p) != null:
			_fallo("1: %s: «%s» dice «%s»" % [donde, t, x])


# 1. Los datos.
func _datos() -> void:
	var ids: Array = Posada.SERVICIOS.map(func(s): return s["id"])
	if ids != ["dormir", "comer", "rumores"]:
		_fallo("1: los servicios son %s" % [ids])
	if Posada.PRECIO_DORMIR != load("res://zona.gd").PRECIO_POSADA:
		_fallo("1: dormir cuesta %d y la posada de siempre, %d" % [Posada.PRECIO_DORMIR, load("res://zona.gd").PRECIO_POSADA])
	for s in Posada.SERVICIOS:
		_texto(s["nombre"] + " " + s["detalle"], s["id"])
	for s in Posada.SOPAS:
		_texto(s["texto"], "sopa")
		if s.has("si") and Oak.error_condicion(s["si"]) != "":
			_fallo("1: sopa: %s" % Oak.error_condicion(s["si"]))
	var lugares: Array = load("res://mapa.gd").LUGARES.map(func(l): return l["nombre"]) + [load("res://mapa.gd").LUGAR_PASTOS["nombre"]]
	var secretos: Array = Oak.SECRETOS.map(func(s): return s["id"])
	var cofres: Array = Oak.COFRES.map(func(c): return c["id"])
	var vistos := {}
	for r in Posada.RUMORES:
		if vistos.has(r["id"]) or not r["id"].begins_with("rumor_"):
			_fallo("1: rumor con id repetido o sin «rumor_»: %s" % r["id"])
		vistos[r["id"]] = true
		if not r["lugar"] in lugares:
			_fallo("1: %s apunta a «%s», que no es un lugar del mapa" % [r["id"], r["lugar"]])
		if r.has("secreto") and not r["secreto"] in secretos:
			_fallo("1: %s apunta al secreto «%s», que no existe" % [r["id"], r["secreto"]])
		if r.has("cofre") and not r["cofre"] in cofres:
			_fallo("1: %s depende del cofre «%s», que no existe" % [r["id"], r["cofre"]])
		if r.has("hasta") and Oak.error_condicion(r["hasta"]) != "":
			_fallo("1: %s: %s" % [r["id"], Oak.error_condicion(r["hasta"])])
		_texto(r["texto"], r["id"])
	_texto(Posada.SIN_RUMORES, "sin rumores")
	print("RUMORES %d · SOPAS %d" % [Posada.RUMORES.size(), Posada.SOPAS.size()])


func _herir() -> void:
	for n in G.activos():
		G.guardar_vida(n, 1, 0)


func _vida(n: String) -> Array:
	return [int(G.datos()[n]["pv"]), int(G.datos()[n]["pm"])]


# 2. Dormir.
func _dormir() -> void:
	_limpiar()
	I.ganar_oro(100 - I.oro())
	_herir()
	var r := Posada.dormir()
	var e: Dictionary = G.estadisticas("Lya")
	if not r["ok"] or r["gratis"] or I.oro() != 100 - Posada.PRECIO_DORMIR or _vida("Lya") != [e["pv_max"], e["pm_max"]]:
		_fallo("2: dormir no cobra %d o no cura (%s, oro %d, Lya %s)" % [Posada.PRECIO_DORMIR, r, I.oro(), _vida("Lya")])
	if r["escena"] != Oak.ruta_dialogo("oak_posada_lya"):
		_fallo("2: al despertar sin charlas sale %s" % r["escena"])
	P.poner_estado(Oak.NOMBRE, "noche_gratis")
	P.poner_hito("pv_03")
	var oro: int = I.oro()
	r = Posada.dormir()
	if not r["ok"] or not r["gratis"] or I.oro() != oro or P.estado(Oak.NOMBRE, "noche_gratis"):
		_fallo("2: la noche gratis cobra o no se gasta (%s, oro %d)" % [r, I.oro()])
	if r["escena"] != Oak.ruta_charla("charla_conocerse"):
		_fallo("2: con PV-03 y Lya, al despertar no sale la charla (%s)" % r["escena"])
	I.gastar_oro(I.oro())
	r = Posada.dormir()
	if r["ok"] or r["escena"] != "":
		_fallo("2: sin monedas se duerme igual (%s)" % r)
	var s: Array = Posada.servicios()
	P.poner_estado(Oak.NOMBRE, "noche_gratis")
	var s2: Array = Posada.servicios()
	if s[0]["precio"] != Posada.PRECIO_DORMIR or s2[0]["precio"] != 0:
		_fallo("2: el precio de dormir que se enseña no cuenta la noche gratis (%d, %d)" % [s[0]["precio"], s2[0]["precio"]])


# 3. Comer.
func _comer() -> void:
	_limpiar()
	I.ganar_oro(50 - I.oro())
	_herir()
	var r := Posada.comer()
	var e: Dictionary = G.estadisticas("Kael")
	if not r["ok"] or I.oro() != 50 - Posada.PRECIO_COMER or _vida("Kael") != [e["pv_max"], 0]:
		_fallo("3: comer no cobra %d o no deja los PM como estaban (%s, oro %d, Kael %s)" % [Posada.PRECIO_COMER, r, I.oro(), _vida("Kael")])
	var sopa1: String = Posada.sopa_del_dia()
	P.poner_hito("oak_lavanda")
	if Posada.sopa_del_dia() == sopa1:
		_fallo("3: la sopa no cambia con la lavanda entregada")
	I.gastar_oro(I.oro())
	if Posada.comer()["ok"]:
		_fallo("3: sin monedas se come igual")


# 4. Rumores.
func _rumores() -> void:
	_limpiar()
	var oidos: Array = []
	for i in Posada.RUMORES.size() + 2:
		var r := Posada.rumor()
		if r["id"] == "":
			if r["texto"] != Posada.SIN_RUMORES:
				_fallo("4: sin rumores, la posadera dice «%s»" % r["texto"])
			break
		if r["id"] in oidos:
			_fallo("4: el rumor %s se repite" % r["id"])
		oidos.append(r["id"])
	if oidos.size() != Posada.RUMORES.size():
		_fallo("4: en una partida nueva se oyen %d rumores de %d" % [oidos.size(), Posada.RUMORES.size()])
	_limpiar()
	P.poner_hito("pv_02")
	P.poner_estado(Oak.NOMBRE, "grieta")
	Engine.set_meta("cofres_abiertos", {"oak_cofre_ronda": true})
	var quedan: Array = Posada.rumores_disponibles().map(func(r): return r["id"])
	for id in ["rumor_pastos", "rumor_callejon", "rumor_ronda"]:
		if id in quedan:
			_fallo("4: %s se sigue contando aunque ya se ha visto" % id)
	# partida antigua sin «mazmorras», y lo oído al guardar y cargar
	_limpiar()
	P.restaurar({"grupo_activo": ["Kael"], "escena_guardada": "res://mapa.tscn"})
	var primero := Posada.rumor()
	if primero["id"] != Posada.RUMORES[0]["id"]:
		_fallo("4: en una partida antigua no se empieza por el primer rumor (%s)" % primero["id"])
	if not P.guardar("res://mapa.tscn"):
		_fallo("4: no se guarda la partida de prueba")
		return
	_limpiar()
	P.cargar()
	if not Posada.rumor_oido(primero["id"]):
		_fallo("4: lo oído no se lee al cargar")
	print("RUMORES OÍDOS EN ORDEN ", oidos)


# 5. La ciudad 2D cobra con este módulo.
func _en_2d() -> void:
	var codigo := FileAccess.get_file_as_string("res://ciudad_oakhaven.gd")
	if not "Posada.pagar_noche()" in codigo:
		_fallo("5: ciudad_oakhaven.gd no cobra la posada con ciudades/oakhaven_posada.gd")
