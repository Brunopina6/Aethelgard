extends SceneTree
# HIBRIDA_SALIDA_19_11 (PC-19): el cierre con 0xC0000005 de Godot 4.7.2 reducido a lo mínimo, sin nada del juego.
# Un método de A crea una función anónima y se la pasa a una función ESTÁTICA, que espera (await) a un método de B (hijo
# de A) que espera process_frame. Se sale con quit (return true en _process) con todo pendiente.
# Uso: godot --headless --path aethelgard --script res://pruebas/herramientas/diag_estatica_lambda.gd -- caso=<caso>
# Medido (19/11, 2-3 pasadas cada uno; código 139 = 0xC0000005 en Git Bash):
#   cadena_lambda, sin_captura, sin_self → se cierra con 0xC0000005 (la anónima, en la pila de la estática)
#   nada, miembro, estatica, cadena (sin anónima), a_miembro (no estática), estatica_sola (la estática espera al árbol,
#   no a B), ligado (print.bind, no anónima) → 0
#   guardada (la anónima espera en B, no en la pila: el arreglo de invocacion_erebo_hibrida.gd) y senal (la estática
#   espera una señal de B) → 0

class Hijo extends Node:
	signal dirigida
	var _cb := Callable()

	func dirigir() -> void:
		while true:
			await get_tree().process_frame

	func dirigir_senal() -> void:
		await dirigir()
		dirigida.emit()

	static func espera_sola(cb: Callable) -> void:
		await Engine.get_main_loop().process_frame
		await Engine.get_main_loop().create_timer(100.0).timeout
		cb.call()

	func invocar_m(padre: Node, cb: Callable) -> bool:
		var inv := Hijo.new()
		padre.add_child(inv)
		await inv.dirigir()
		cb.call()
		return true

	static func invocar(padre: Node, cb: Callable) -> bool:
		var inv := Hijo.new()
		padre.add_child(inv)
		await inv.dirigir()
		cb.call()
		return true

	static func invocar_guardada(padre: Node, cb: Callable) -> bool:
		var inv := Hijo.new()
		padre.add_child(inv)
		inv._cb = cb
		cb = Callable()
		await inv.dirigir()
		inv._cb.call()
		return true

	static func invocar_senal(padre: Node, cb: Callable) -> bool:
		var inv := Hijo.new()
		padre.add_child(inv)
		inv.dirigir_senal()
		await inv.dirigida
		cb.call()
		return true


class Padre extends Node:
	func invocar_sobre(con_lambda: bool) -> void:
		var out := {"x": 0}
		var cb := func(): out["x"] = 1 if con_lambda else 0
		await Hijo.invocar(self, cb if con_lambda else Callable())

	func lambda_sin_captura() -> void:
		await Hijo.invocar(self, func(): print("x"))

	func lambda_sin_self() -> void:
		await Hijo.invocar(self, func(): pass)

	func lambda_a_miembro() -> void:
		var out := {"x": 0}
		var h := Hijo.new()
		add_child(h)
		await h.invocar_m(self, func(): out["x"] = 1)

	func lambda_estatica_sola() -> void:
		var out := {"x": 0}
		await Hijo.espera_sola(func(): out["x"] = 1)

	func metodo_ligado() -> void:
		await Hijo.invocar(self, print.bind("y"))

	func con_guardada() -> void:
		var out := {"x": 0}
		await Hijo.invocar_guardada(self, func(): out["x"] = 1)

	func con_senal() -> void:
		var out := {"x": 0}
		await Hijo.invocar_senal(self, func(): out["x"] = 1)

	func invocar_miembro() -> void:
		var inv := Hijo.new()
		add_child(inv)
		await inv.dirigir()


var n := 0
var caso := "cadena_lambda"


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("caso="):
			caso = a.substr(5)


func _process(_d: float) -> bool:
	n += 1
	if n == 2:
		var p := Padre.new()
		root.add_child(p)
		match caso:
			"miembro": p.invocar_miembro()
			"estatica": Hijo.invocar(p, Callable())
			"cadena": p.invocar_sobre(false)
			"cadena_lambda": p.invocar_sobre(true)
			"sin_captura": p.lambda_sin_captura()
			"sin_self": p.lambda_sin_self()
			"a_miembro": p.lambda_a_miembro()
			"estatica_sola": p.lambda_estatica_sola()
			"ligado": p.metodo_ligado()
			"guardada": p.con_guardada()
			"senal": p.con_senal()
	if n == 6:
		print("MIN caso %s: quit" % caso)
		return true
	return false
