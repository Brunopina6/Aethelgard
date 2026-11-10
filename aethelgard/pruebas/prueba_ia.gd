extends SceneTree
# IA de los enemigos en un combate de verdad (10/11: antes solo imprimía y pasaba aunque el combate no avanzara).
# Con «-- auto semilla=7»: los héroes atacan solos (combate.gd) y el azar es siempre el mismo. Comprueba:
#   1. El combate termina (victoria o derrota) antes del límite, sin quedarse en un estado intermedio.
#   2. Los enemigos actúan: el cartel nombra a un enemigo haciendo algo, y los héroes también actúan.
#   3. El final es coherente: con victoria, ningún enemigo en pie; con derrota, ningún héroe en pie.
# Sigue escribiendo cada mensaje del cartel, como antes, para leer qué hace cada uno.

const LIMITE := 3000                                # fotogramas (100 s de juego con --fixed-fps 30)

var c: Node
var mensajes: Array = []
var frames := 0
var fallos := 0


func _initialize() -> void:
	if not "auto" in OS.get_cmdline_user_args():
		print("FALLO: falta «-- auto» (los héroes no actuarían solos)")
		quit(1)
		return
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _process(_d: float) -> bool:
	if c == null:
		return true
	frames += 1
	if c.registro != null and (mensajes.is_empty() or c.registro.text != mensajes[-1]):
		mensajes.append(c.registro.text)
		print("  ", c.registro.text)
	var en_fin: bool = c.estado == "fin" and frames > 60
	var victoria: bool = en_fin and not mensajes.is_empty() and String(mensajes[-1]).begins_with("+")
	var derrota: bool = en_fin and c.heroes.all(func(h): return int(h["hp"]) <= 0)
	if not victoria and not derrota and frames < LIMITE:
		return false
	_comprobar(victoria, derrota)
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
	return true


func _comprobar(victoria: bool, derrota: bool) -> void:
	if not victoria and not derrota:
		_fallo("el combate no termina en %d fotogramas (estado «%s»; %d mensajes)" % [LIMITE, c.estado, mensajes.size()])
	var nombres_enemigos: Array = c.enemigos.map(func(e): return String(e["nombre"]))
	var nombres_heroes: Array = c.heroes.map(func(h): return String(h["nombre"]))
	var actua_enemigo := false
	var actua_heroe := false
	for m in mensajes:
		for n in nombres_enemigos:
			if String(m).begins_with(n):
				actua_enemigo = true
		for n in nombres_heroes:
			if String(m).begins_with(n):
				actua_heroe = true
	if not actua_enemigo:
		_fallo("ningún enemigo actúa (enemigos %s)" % [nombres_enemigos])
	if not actua_heroe:
		_fallo("ningún héroe actúa (héroes %s)" % [nombres_heroes])
	if victoria and c.enemigos.any(func(e): return int(e["hp"]) > 0):
		_fallo("se dan las recompensas con enemigos en pie")
	print("IA: %d mensajes, %s en %d fotogramas" % [mensajes.size(), "victoria" if victoria else ("derrota" if derrota else "sin final"), frames])
