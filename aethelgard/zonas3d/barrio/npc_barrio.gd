extends "res://personajes/npc_v12/npc_chibi.gd"
# DUEÑO: agente C. Un vecino del BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11): la familia chibi V12 (npc_chibi.gd, que NO
# se toca) con los bucles nuevos de los oficios del barrio (fuente/crear_npc_chibi.py: panadera, porteador y
# encargada_establo) y los puntos de AGARRE para los objetos que se llevan (BoneAttachment3D en «pecho» y «mano.R»).
#
#   var n = NpcBarrio.crear_barrio("panadera", "maela")   (sin el GLB o sin el atlas: «listo» = false y no pone nada)
#   n.poner("caminar_llevar", velocidad)                   el clip si lo tiene; si no, el más parecido (MEJOR)
#   n.agarre("pecho") / n.agarre("mano.R")                 el Node3D donde se cuelga lo que lleva
#
# Los objetos NO se reparenten ni dependen de la pose del clip: barrio_vivo.gd enseña u oculta una copia por sitio y por
# mano según su diccionario de ubicaciones (una sola por objeto) y el temporizador de cada paso.

const BUCLES := ["reposo", "caminar", "correr", "tarea", "caminar_llevar", "llevar_quieto", "amasar", "hornear",
	"cepillar"]
# Si el modelo no tiene un clip, el más parecido que sí tenga (en orden).
const MEJOR := {
	"caminar_llevar": ["caminar"], "llevar_quieto": ["reposo"], "coger": ["tarea", "reposo"], "dejar": ["coger", "tarea", "reposo"],
	"amasar": ["tarea", "reposo"], "hornear": ["tarea", "reposo"], "cepillar": ["tarea", "reposo"],
	"verter": ["tarea", "reposo"], "hablar": ["reposo"], "saludar": ["reposo"],
}
const HUESOS := ["pecho", "mano.R"]

var esqueleto: Skeleton3D
var _agarres := {}


static func crear_barrio(oficio_: String, persona_: String) -> Node3D:
	var n: Node3D = load("res://zonas3d/barrio/npc_barrio.gd").new()
	n.oficio = oficio_
	n.persona = persona_
	n.name = "NPC_" + persona_
	n._montar()
	if n.listo:
		n._preparar_barrio()
	return n


# ¿Hay modelo y atlas para esta persona?
static func hay(oficio_: String, persona_: String) -> bool:
	return existe(oficio_) and ResourceLoader.exists(ATLAS % [oficio_, persona_])


func _preparar_barrio() -> void:
	for c in BUCLES:
		if anim.has_animation(c):
			anim.get_animation(c).loop_mode = Animation.LOOP_LINEAR
	esqueleto = find_child("*", true, false) as Skeleton3D
	if esqueleto == null:
		for s in find_children("*", "Skeleton3D", true, false):
			esqueleto = s
			break
	if esqueleto == null:
		return
	for h in HUESOS:
		if esqueleto.find_bone(h) < 0:
			continue
		var b := BoneAttachment3D.new()
		b.name = "Agarre_" + h.replace(".", "_")
		b.bone_name = h
		esqueleto.add_child(b)
		_agarres[h] = b


func agarre(hueso: String) -> Node3D:
	return _agarres.get(hueso, null)


# La pose de reposo de un hueso en el espacio de este nodo (para colocar lo que cuelga de él sin depender del clip).
func reposo_hueso(hueso: String) -> Transform3D:
	if esqueleto == null or esqueleto.find_bone(hueso) < 0:
		return Transform3D.IDENTITY
	var t := esqueleto.get_bone_global_rest(esqueleto.find_bone(hueso))
	var n: Node = esqueleto
	while n != null and n != self:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


func tiene_clip(c: String) -> bool:
	return anim != null and anim.has_animation(c)


# El clip «c» (o el más parecido que tenga) a «velocidad» de reproducción. Los bucles nuevos se quedan en bucle.
func poner(c: String, velocidad := 1.0) -> void:
	if anim == null:
		return
	var real := c
	if not anim.has_animation(real):
		real = "reposo"
		for alt in MEJOR.get(c, []):
			if anim.has_animation(alt):
				real = alt
				break
	clip(real, real if real in BUCLES else "reposo", velocidad)
