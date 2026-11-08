extends SceneTree
# Sonda de verificar_ejecutor.ps1: no termina nunca, a propósito. Al agotarse su tiempo, ejecutar_pruebas.ps1 debe
# cerrarla a ella (y a su proceso hijo) y a nada más: ningún otro Godot abierto mientras tanto.

func _initialize() -> void:
	print("SONDA_TIEMPO: en marcha, sin terminar")
