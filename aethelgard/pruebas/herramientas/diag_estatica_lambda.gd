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
# Revisión (19/11, HIBRIDA_SALIDA_19_11_REVISION, 3 pasadas cada uno, rc apuntado en cada registro):
#   guardada_arg (guardada, pero la estática pasa inv._cb como ARGUMENTO al método esperado: la copia temporal se queda
#   en su pila) → 139 · guardada_campo (el método de B lee la anónima del nodo: el arreglo de combate_anim_v12.gd) → 0
#   otra_clase (la estática espera a un nodo de OTRO script, como los animar_golpe de los enemigos v12) → 139
#   propia (la anónima es de la propia estática, nadie le pasa nada) → 0
#   metodo_ligado (a la estática le llega un método de A ligado a una clave, no la anónima) → 0

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

	func dirigir_con(cb: Callable) -> void:
		await dirigir()
		cb.call()

	# (revisión) como el arreglo de combate_anim_v12.gd: la anónima, guardada en el nodo y vaciada en la pila, se le pasa
	# al método del nodo como argumento (leída del nodo)
	static func invocar_guardada_arg(padre: Node, cb: Callable) -> bool:
		var inv := Hijo.new()
		padre.add_child(inv)
		inv._cb = cb
		cb = Callable()
		await inv.dirigir_con(inv._cb)
		return true

	func dirigir_campo() -> void:
		var cb := _cb
		_cb = Callable()
		await dirigir_con(cb)

	# (revisión) lo mismo, pero el método del nodo LEE la anónima del nodo (la pila de la estática no la ve nunca)
	static func invocar_guardada_campo(padre: Node, cb: Callable) -> bool:
		var inv := Hijo.new()
		padre.add_child(inv)
		inv._cb = cb
		cb = Callable()
		await inv.dirigir_campo()
		return true

	# (revisión) la estática espera a un nodo de OTRO script (como los animar_golpe de los enemigos v12, que esperan al
	# modelo 3D), con la anónima en su pila
	static func invocar_otra(padre: Node, cb: Callable) -> bool:
		var inv := Otro.new()
		padre.add_child(inv)
		await inv.dirigir()
		cb.call()
		return true

	# (revisión) la anónima es de la PROPIA estática (como el «golpe» de los animar_golpe de los enemigos v12) y la estática
	# espera a un nodo de otro script; nadie le pasa nada
	static func invocar_propia(padre: Node) -> bool:
		var out := {"x": 0}
		var golpe := func(): out["x"] = 1
		var inv := Otro.new()
		padre.add_child(inv)
		await inv.dirigir()
		golpe.call()
		return true

	static func invocar_senal(padre: Node, cb: Callable) -> bool:
		var inv := Hijo.new()
		padre.add_child(inv)
		inv.dirigir_senal()
		await inv.dirigida
		cb.call()
		return true


class Otro extends Node:
	func dirigir() -> void:
		while true:
			await get_tree().process_frame


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

	func con_guardada_arg() -> void:
		var out := {"x": 0}
		await Hijo.invocar_guardada_arg(self, func(): out["x"] = 1)

	func con_guardada_campo() -> void:
		var out := {"x": 0}
		await Hijo.invocar_guardada_campo(self, func(): out["x"] = 1)

	func con_otra() -> void:
		var out := {"x": 0}
		await Hijo.invocar_otra(self, func(): out["x"] = 1)

	# (revisión) a la estática no le llega la anónima sino un método de A ligado a una clave (la anónima queda en A)
	var _pendientes := {}

	func _llamar_pendiente(k: int) -> void:
		_pendientes[k].call()

	func con_metodo_ligado() -> void:
		var out := {"x": 0}
		_pendientes[0] = func(): out["x"] = 1
		await Hijo.invocar_otra(self, _llamar_pendiente.bind(0))

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
			"guardada_arg": p.con_guardada_arg()
			"guardada_campo": p.con_guardada_campo()
			"otra_clase": p.con_otra()
			"propia": Hijo.invocar_propia(p)
			"metodo_ligado": p.con_metodo_ligado()
	if n == 6:
		print("MIN caso %s: quit" % caso)
		return true
	return false
