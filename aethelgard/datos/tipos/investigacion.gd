extends Resource
# Una investigación (fase 2, 10/11): lo que un taller aprende y qué desbloquea. Un .tres por investigación en
# res://datos/investigaciones/. Su avance se guarda en la partida por id (investigacion.gd, clave «investigaciones»).
# requisitos: lista de diccionarios, todos obligatorios:
#   {"tipo": "material", "id": <clave_inventario>, "cantidad": n}   tener n en el inventario
#   {"tipo": "hito", "id": <hito de progreso.gd>}                    haber llegado a ese punto de la historia
#       (opcional "pista": qué decirle al jugador mientras falta, sin destripar; sin ella, «Aún no es el momento.»)
#   {"tipo": "investigacion", "id": <id>}                            haber completado otra investigación
#   {"tipo": "nivel", "heroe": "Kael"|"Lya"|"Garon", "nivel": n}      el héroe con ese nivel o más

@export var id := ""
@export var taller := ""
@export var nombre := ""
@export_multiline var desc := ""
@export var requisitos: Array = []
@export var pasos := 1                       # cuántos avances hacen falta para completarla
@export var desbloquea := PackedStringArray()   # ids de recetas
@export var borrador := true
# 14/11: condición para que salga en la pantalla del taller (la de encargos.gd: «estado_de:lugar/clave», «hito:…»,
# «material:clave=n»…). Vacía, siempre. Una investigación empezada o completada sale siempre. Sirve para no enseñar lo
# que aún no tiene sentido (p. ej., lo que da una misión que el jugador ni conoce).
@export var si := ""
