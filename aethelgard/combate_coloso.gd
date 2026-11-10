extends RefCounted
# El Coloso de la Falla (directiva V9, jefe 2): el jefe opcional de la Garganta del Diablo 3D, un guardián de piedra con
# inscripciones que duerme al fondo de la grieta oculta. Solo cuentas y estado del enemigo, sin escena, como
# combate_bosque.gd: combate.gd las llama. Con cualquier otro enemigo todo da exactamente lo mismo que antes (ninguna
# función de aquí tira del generador aleatorio; prueba_combate_huella).
#
# Reglas (pruebas/prueba_coloso.gd):
#   Fase 1, «La piedra que vigila»: puñetazos fuertes (a uno), lluvia de rocas (a todos, floja) y el Puño de la Falla
#     (aviso un turno antes, ×2 a uno). Lleva la PIEL DE PIEDRA: los golpes físicos le hacen la mitad.
#   Ventana: tras descargar su golpe cargado queda EXPUESTO hasta su turno siguiente (en el que se recompone y no ataca):
#     sus puntos débiles brillan y los golpes físicos hacen ×1,5; los de Kael, que sabe leer ese hueco, ×1,25 más.
#   Fase 2, «Las runas despiertan» (al 50 %, color ámbar): el golpe cargado es el Derrumbe rúnico (×1,6 a todos) y
#     alterna cada turno suyo la CORAZA RÚNICA (la magia hace la mitad; la piel de piedra se abre) y la piel de piedra
#     (los golpes hacen la mitad). Lo que lleva puesto se avisa al cambiar y se lee sobre su vida.
#   Garon lee las inscripciones (ESGRIMA, «Leer runas», solo en este combate): la piel de piedra se apaga durante sus
#     TURNOS_LECTURA turnos siguientes (no la coraza rúnica). Útil, no obligatorio: sin él, la magia y las ventanas
#     bastan.
# Premio, una sola vez (combate fijo «garganta_coloso» en «combates_ganados»): 2 Minerales rúnicos (material, se vende;
# datos/materiales/mineral_runico.tres) y el Fragmento de armadura antigua (accesorio, equipo_extra.gd).

const CLAVE := "coloso_falla"
const COMBATE := "garganta_coloso"            # combate fijo (combates_ganados)
const GRUPO := 12                             # combate.gd, GRUPOS[12]
const MULT_PIEL := 0.5                        # piel de piedra: golpes físicos
const MULT_VENTANA := 1.5                     # expuesto: golpes físicos
const MULT_KAEL := 1.25                       # Kael en la ventana, además
const MULT_CORAZA := 0.5                      # coraza rúnica: magia
const TURNOS_LECTURA := 2
const LECTURA := {"nombre": "Leer runas", "coste": 3, "color": Color("FFB347"),
	"desc": "Lee las inscripciones del Coloso: su piel de piedra se abre 2 turnos suyos.",
	"motivo": "Las runas ya están leídas."}
const MATERIAL := "Mineral rúnico"
const CANTIDAD_MATERIAL := 2
const ACCESORIO := "fragmento_armadura"
# El modelo 3D (animaciones: enemigos/coloso_falla/, con la interfaz de guardian_bosque_3d.gd). Mientras sea false, el
# combate y la Garganta usan el respaldo (la imagen del guardián de piedra, grande y gris ámbar). Para activarlo cuando
# llegue el GLB: aquí true (la figura dormida de la Garganta) y, en combate.gd ENEMIGOS["coloso_falla"], «modelo»:
# «coloso_falla» (la entrada 3D de MODELOS ya está; si faltara el GLB, combate.gd usa su respaldo 2D).
const MODELO_3D := false
const GUION_3D := "res://enemigos/coloso_falla/coloso_falla_3d.gd"
const GLB_3D := "res://enemigos/coloso_falla/coloso_falla.glb"


static func es_coloso(f) -> bool:
	return f is Dictionary and str(f.get("clave", "")) == CLAVE


# ¿Lleva puesta la piel de piedra (golpes físicos a la mitad)?
static func piel_activa(f: Dictionary) -> bool:
	if not es_coloso(f) or f.get("expuesto", false) or int(f.get("lectura_turnos", 0)) > 0:
		return false
	return not coraza_activa(f)


# ¿Lleva puesta la coraza rúnica (magia a la mitad)? Solo en la fase 2 y nunca expuesto.
static func coraza_activa(f: Dictionary) -> bool:
	return es_coloso(f) and f.get("fase2", false) and f.get("coraza_runica", false) and not f.get("expuesto", false)


# Daño que recibe un enemigo. «magia» = familia ("Fuego", "Agua"…) o "" si es físico. Si no es el Coloso, «dano» tal cual.
static func dano_recibido(dano: int, magia: String, origen: Dictionary, objetivo: Dictionary) -> int:
	if not es_coloso(objetivo):
		return dano
	var m := 1.0
	if magia == "":
		if objetivo.get("expuesto", false):
			m = MULT_VENTANA * (MULT_KAEL if str(origen.get("nombre", "")) == "Kael" else 1.0)
		elif piel_activa(objetivo):
			m = MULT_PIEL
	elif coraza_activa(objetivo):
		m = MULT_CORAZA
	if is_equal_approx(m, 1.0):
		return dano
	return maxi(1, int(round(dano * m)))


# Garon lee las inscripciones: "" si puede; si no, el motivo.
static func motivo_lectura(f: Dictionary) -> String:
	if not es_coloso(f) or f.get("hp", 0) <= 0:
		return "No hay inscripciones que leer."
	if int(f.get("lectura_turnos", 0)) > 0:
		return LECTURA["motivo"]
	return ""


static func leer(f: Dictionary) -> void:
	f["lectura_turnos"] = TURNOS_LECTURA


# Al acabar cada turno del Coloso: la lectura de Garon se gasta y, en la fase 2, cambia de defensa. Devuelve lo que ha
# cambiado («lectura_fin», «coraza» o «piel») para que combate.gd lo avise.
static func fin_turno(f: Dictionary) -> Array:
	var r: Array = []
	if int(f.get("lectura_turnos", 0)) > 0:
		f["lectura_turnos"] = int(f["lectura_turnos"]) - 1
		if f["lectura_turnos"] <= 0:
			r.append("lectura_fin")
	if f.get("fase2", false) and f["hp"] > 0:
		f["coraza_runica"] = not f.get("coraza_runica", false)
		r.append("coraza" if f["coraza_runica"] else "piel")
	return r


# Lo que se lee sobre su vida (combate.gd _actualizar).
static func estados(f: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	if f.get("expuesto", false):
		r.append("✦ Expuesto")
	elif coraza_activa(f):
		r.append("Coraza rúnica")
	elif piel_activa(f):
		r.append("Piel de piedra")
	if int(f.get("lectura_turnos", 0)) > 0:
		r.append("Runas leídas: %d" % int(f["lectura_turnos"]))
	return r


# Premio de la primera victoria (combate.gd _fin_combate, solo si el combate fijo aún no estaba ganado). Devuelve el aviso.
static func dar_premio() -> String:
	var textos: Array = []
	if ResourceLoader.exists("res://inventario.gd"):
		load("res://inventario.gd").agregar_objeto(MATERIAL, CANTIDAD_MATERIAL)
		textos.append("+%d %s" % [CANTIDAD_MATERIAL, MATERIAL])
	textos.append(load("res://equipo_extra.gd").conseguir(ACCESORIO))
	return "  ".join(textos.filter(func(t): return t != ""))


# ¿Usa la Garganta su modelo 3D dormido? (MODELO_3D y los dos archivos)
static func modelo_3d_listo() -> bool:
	return MODELO_3D and ResourceLoader.exists(GUION_3D) and ResourceLoader.exists(GLB_3D)
