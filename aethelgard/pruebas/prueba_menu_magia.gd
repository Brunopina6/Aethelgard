extends SceneTree
# Abre el menú de magia cuando le toca a un héroe: primero los niveles y luego el nivel II.

var c: Node
var frames := 0
var paso := 0


func _initialize() -> void:
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _process(_d: float) -> bool:
	frames += 1
	if paso == 0 and c.estado == "menu" and c.actor != null and c.actor["nombre"] == "Lya":
		c._menu_magia()
		paso = 1
		frames = 0
	elif paso == 1 and frames == 15:
		print("niveles: ", c.lista.get_child_count())
		c._menu_magia_nivel(2)
		paso = 2
		frames = 0
	elif paso == 2 and frames == 15:
		print("nivel II: ", c.lista.get_child_count())
		return true
	elif paso == 0 and c.estado == "menu" and c.actor != null:
		c._defender()                            # Kael se defiende para que llegue el turno de Lya
	return false
