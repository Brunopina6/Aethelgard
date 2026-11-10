extends RefCounted
# Reglas de «El bosque que no recuerda» en el combate (fase 3, 10/11; docs/fase3_bosque/AVENTURA_JUGABLE.md).
# Solo cuentas, sin escena: combate.gd las llama. El resto de enemigos y héroes no cambia (si nadie lleva Enfoque ni
# hay Guardián, todo da exactamente lo mismo que antes: prueba_combate_huella).
#   - El Guardián del Bosque Olvidado: en su segunda fase, coraza de raíces (golpes físicos a la mitad) y débil al fuego
#     (×1,5). Si Lya completó «La savia que recuerda», su magia le hace ×1,25 (la ventaja de la investigación).
#   - Esencia de enfoque: la magia de quien la toma hace ×1,3 durante sus 3 turnos siguientes.
#   - Elixir de savia purificada: solo sirve contra el Guardián y solo en su segunda fase.

const CLAVE_GUARDIAN := "guardian_bosque"
const COMBATE := "pastos_guardian"            # combate fijo (combates_ganados)
const DECISION := "guardian_bosque"           # clave en «decisiones»: "purificado" o "derrotado"
const MAGIAS_FUEGO := ["Fuego", "Llamarada", "Infierno"]
const MULT_CORAZA := 0.5
const MULT_FUEGO := 1.5
const MULT_LYA := 1.25
const MULT_ENFOQUE := 1.3
const TURNOS_ENFOQUE := 3
const ESENCIA := "Esencia de enfoque"
const ELIXIR := "Elixir de savia purificada"
const INVESTIGACION_VENTAJA := "lya_savia"


static func es_guardian(f: Dictionary) -> bool:
	return str(f.get("clave", "")) == CLAVE_GUARDIAN


# Daño que recibe un enemigo según quién y con qué le pega. «magia» = familia ("Fuego", "Agua"…) o "" si es físico.
static func dano_recibido(dano: int, magia: String, origen: Dictionary, objetivo: Dictionary, lya_sabe: bool) -> int:
	var m := 1.0
	if magia != "" and int(origen.get("enfoque_turnos", 0)) > 0:
		m *= MULT_ENFOQUE
	if es_guardian(objetivo):
		if objetivo.get("fase2", false):
			if magia == "":
				m *= MULT_CORAZA
			elif magia in MAGIAS_FUEGO:
				m *= MULT_FUEGO
		if lya_sabe and magia != "" and str(origen.get("nombre", "")) == "Lya":
			m *= MULT_LYA
	if is_equal_approx(m, 1.0):
		return dano
	return maxi(1, int(round(dano * m)))


# ¿Puede usarse el Elixir sobre este enemigo ahora? "" si sí; si no, el motivo (para el registro del combate).
static func elixir_sobre(objetivo: Dictionary) -> String:
	if not es_guardian(objetivo):
		return "El elixir solo sirve contra el Guardián del Bosque."
	if objetivo.get("hp", 0) <= 0:
		return "Ya no hace falta."
	if not objetivo.get("fase2", false):
		return "elixir_fase1"
	return ""


# Desenlace guardado (o "" si aún no se ha resuelto).
static func desenlace() -> String:
	return str(Engine.get_meta("decisiones", {}).get(DECISION, ""))


static func apuntar(desenlace_: String) -> void:
	var d: Dictionary = Engine.get_meta("decisiones", {})
	d[DECISION] = desenlace_
	Engine.set_meta("decisiones", d)
