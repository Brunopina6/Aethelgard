extends SceneTree
# Abre el menú de magia cuando le toca a Lya: primero el nivel que recuerda el menú y luego el nivel II.
# El menú de combate vive en menu_combate.gd: sus opciones están en c.menu.filas, y el nivel se elige con
# c._menu_magia(nivel). Antes la prueba leía c.lista y llamaba a c._menu_magia_nivel(), que ya no existen:
# el error abortaba el fotograma y la prueba se quedaba esperando para siempre.
# Termina con quit(1) y «FALLO» si algo sale mal, o si el turno de Lya no llega en FRAMES_MAX fotogramas.

const FRAMES_MAX := 1800        # 60 s a 30 FPS fijos

var c: Node
var frames := 0
var total := 0
var paso := 0


func _initialize() -> void:
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _fallo(texto: String) -> void:
	print("FALLO: ", texto)
	quit(1)


func _process(_d: float) -> bool:
	frames += 1
	total += 1
	if total > FRAMES_MAX:
		_fallo("el turno de Lya no llegó en %d fotogramas (estado=%s)" % [FRAMES_MAX, c.estado])
		return false
	if paso == 0 and c.estado == "menu" and c.actor != null and c.actor["nombre"] == "Lya":
		c._menu_magia()
		paso = 1
		frames = 0
	elif paso == 1 and frames == 15:
		var n: int = c.menu.filas.size()
		print("magias del nivel que recuerda el menú: ", n)
		if c.estado != "magia" or n == 0:
			_fallo("el menú de magia no se abrió (estado=%s, filas=%d)" % [c.estado, n])
			return false
		c._menu_magia(2)
		paso = 2
		frames = 0
	elif paso == 2 and frames == 15:
		var n: int = c.menu.filas.size()
		print("magias tras pedir el nivel II: ", n, " (si Lya aún no tiene nivel II, el menú vuelve al I)")
		if n == 0:
			_fallo("el menú de magia quedó vacío al cambiar de nivel")
			return false
		print("OK menú de magia de Lya")
		return true
	elif paso == 0 and c.estado == "menu" and c.actor != null:
		c._defender()                            # los demás se defienden para que llegue el turno de Lya
	return false
