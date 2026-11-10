extends Resource
# Un material (fase 2, 10/11): botín de las bestias y, más adelante, ingredientes de los talleres. Un archivo .tres por
# material en res://datos/materiales/. Es la única fuente de verdad: equipo_extra.gd y la tienda lo leen de aquí.

@export var id := ""                         # identificador estable, en minúsculas y con guiones bajos
@export var clave_inventario := ""           # cómo se guarda en el inventario y en las partidas (no cambiar nunca)
@export var nombre := ""
@export var venta := 0                       # monedas que paga la tienda por uno
@export_multiline var desc := ""
@export var de_enemigos := PackedStringArray()   # claves de combate.gd ENEMIGOS que lo dejan al caer
