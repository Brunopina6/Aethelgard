extends Control
# Prototipo navegable del Firmamento de los Ecos (V12, 12/11) para comparar los tres conceptos en el editor (F6 sobre
# firmamento_demo.tscn) o en la APK de Auditoría. Enciende el interruptor SOLO en esta sesión, da 30 orbes de prueba
# (conceder_prueba: solo Auditoría o editor) y abre el tablero; el botón «Concepto» del panel cambia de concepto.
# No guarda la partida: lo que se compre aquí se pierde al salir.

func _ready() -> void:
	var O = load("res://firmamento/orbes.gd")
	Engine.set_meta(O.INTERRUPTOR, true)
	if O.saldo() == 0:
		O.conceder_prueba(30)
	var f = load("res://firmamento/firmamento.gd").new()
	f.cerrado.connect(func(): get_tree().quit())
	add_child(f)
