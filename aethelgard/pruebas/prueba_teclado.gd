extends "res://pruebas/prueba_mando.gd"
# El mismo recorrido sin ratón que prueba_mando.gd, con el teclado (teclas simuladas): Intro, Esc, flechas, Tab y Q / E.
#   Godot --path aethelgard --script res://pruebas/prueba_teclado.gd --fixed-fps 30 -- 3d sin_prologo


func _initialize() -> void:
	dispositivo = "teclado"
	_probar.call_deferred()
