extends RefCounted
# Objetos que se pueden usar en combate (el dibujo es la foto del frasco de Meshy). 15/11: la tabla vive aquí, en un
# archivo de datos sin dependencias, para que la exploración (talleres.gd) la lea SIN cargar combate.gd: cargarlo
# fuera del combate precarga una veintena de scripts de combate (tirón) y, en Pastos Verdes, el combate fijo del
# Guardián no llegaba a empezar después (prueba_bosque_pastos). combate.gd la sigue usando como OBJETOS_COMBATE.
const OBJETOS := {
	"Poción": {"que": "PV", "cura": 60, "imagen": "res://objetos/pocion.png", "color": Color(1.0, 0.35, 0.3)},
	"Éter": {"que": "PM", "cura": 25, "imagen": "res://objetos/eter.png", "color": Color(0.35, 1.0, 0.6)},
	# Alquimia de Lya (fase 3, «El bosque que no recuerda»; combate_bosque.gd). Solo salen en el menú si se tienen.
	"Esencia de enfoque": {"que": "ENFOQUE", "cura": 0, "imagen": "res://objetos/eter.png", "color": Color(0.7, 0.55, 1.0),
		"desc": "Su magia hace ×1,3 durante 3 turnos."},
	"Elixir de savia purificada": {"que": "PURIFICA", "cura": 0, "imagen": "res://objetos/pocion.png",
		"color": Color(0.55, 1.0, 0.45), "desc": "Purifica al Guardián del Bosque, en su segunda fase."},
	# V10, «La fórmula desaparecida»: el bálsamo de Mirta cura a todo el grupo (sin elegir a quién).
	"Bálsamo de Mirta": {"que": "PV_TODOS", "cura": 45, "imagen": "res://objetos/pocion.png", "color": Color(1.0, 0.7, 0.45),
		"desc": "+45 PV a todo el grupo."},
}
