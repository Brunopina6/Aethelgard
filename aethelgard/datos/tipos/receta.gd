extends Resource
# Una receta de taller (fase 2, 10/11): qué materiales gasta y qué da. Un .tres por receta en res://datos/recetas/.
# «borrador»: aún no aprobada para el juego; ningún sistema jugable la ofrece (talleres.gd la ignora fuera de pruebas).

@export var id := ""
@export var taller := ""                     # alquimia (Lya), forja (Kael) o armaduras (Garon): catalogo.TALLERES
@export var nombre := ""
@export var materiales := {}                 # clave_inventario del material → cantidad
@export var resultado := ""                  # id del objeto que da (inventario, equipo_extra o un material)
@export var cantidad := 1
@export var investigacion := ""              # id de la investigación que la desbloquea ("" = desde el principio)
@export_multiline var desc := ""            # qué hace, para la pantalla del taller (opcional)
@export var borrador := true
