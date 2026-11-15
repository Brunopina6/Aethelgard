extends RefCounted
# DUEÑO: agente C — stub de la fase 0. Firmas EXACTAS del contrato (docs/v12/BARRIO_OAKHAVEN_PLAN.md §11) con valores
# neutros: sin vecinos, piezas, misiones ni textos. Lo único que ya hace es lo que no puede faltar nunca:
#   - activado(): FALSO fuera del banco de pruebas de Auditoría (la región se activa a sí misma con la meta de sesión
#     «barrio_v12» en su _ready, solo si está en el banco; banco_pruebas.salir() la quita);
#   - puerta(id): la guardia del prólogo (plan §1): sin el prólogo visto y el hito pv_02 no se pasa por ninguna puerta.
#
# Lo que la región (zonas3d/barrio/barrio.gd) espera (docs/v12/BARRIO_OAKHAVEN.md, «Contrato»):
#   - PIEZAS: id → {"ancla", "radio", "boton", "si", "senal", "texto", "texto_sin"}. La región enseña las que tocan a la
#     zona de Kael (ancla «int_<id>_…» solo dentro de ese interior; las demás, fuera) y, al pulsar, llama a accion(pid).
#   - accion(pid) → {"texto", "efecto", "dialogo", "guardar"}: con «dialogo» la región lo empieza
#     (iniciar_dialogo); si no, enseña «texto» con el sonido «efecto»; con «guardar», guarda. {} = nada.
#   - aplicar(senal): las señales «bar:…» de Dialogic; devuelve el aviso que se enseña al acabar ("" = ninguno).
#   - registrar_dialogic(): los personajes .dch del barrio (la región lo llama en su _ready).

const NOMBRE := "oak_barrio"                         # su diccionario en «mazmorras» (solo bool)
const NOMBRE_LUGAR := "Oakhaven (barrio de prueba)"
const ACTIVO_POR_DEFECTO := false
const META := "barrio_v12"                           # meta de SESIÓN que pone la región en el banco
const TEXTO_PROLOGO := "Todavía no: termina el prólogo."

const MODOS := ["sabe", "oido", "cree"]
const NPCS := {}
const PIEZAS := {}
const MISIONES := []
const AFIRMACIONES := {}
const SABER := []


# Solo en Auditoría o en el editor, dentro del banco y con la región puesta. Fuera del banco, nunca.
static func activado() -> bool:
	if not (OS.has_feature("auditoria") or OS.has_feature("editor")):
		return ACTIVO_POR_DEFECTO
	return bool(Engine.get_meta("banco_pruebas", false)) and bool(Engine.get_meta(META, false))


static func cumple(_c) -> bool:
	return false


# Kael ya salió de Oakhaven: el mismo criterio que «cond:kael_salio» (ciudades/oakhaven.gd) y que el viaje del
# mapamundi (zonas3d/mapamundi/datos.gd, motivo_bloqueo).
static func puede_pasar() -> bool:
	return bool(Engine.get_meta("prologo_visto", false)) and load("res://progreso.gd").hito("pv_02")


# "" = se puede pasar; si no, el aviso. (stub: solo la guardia del prólogo)
static func puerta(_id: String) -> String:
	return "" if puede_pasar() else TEXTO_PROLOGO


static func paso_interno(_nombre: String) -> bool:
	return false


static func accion(_pid: String) -> Dictionary:
	return {}


static func dialogo_de(_npc: String, _veces := 0) -> String:
	return ""


static func frase(_npc: String, _veces := 0) -> String:
	return ""


static func aplicar(_senal: String) -> String:
	return ""


static func programa(_npc: String) -> String:
	return ""


static func modo_de(_npc: String, _af: String) -> String:
	return ""


static func registrar_dialogic() -> void:
	pass
