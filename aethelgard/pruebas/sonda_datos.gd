extends SceneTree
# Sonda del ejecutor de pruebas (ejecutar_pruebas.ps1): imprime dónde escribiría el juego (user:// y las
# carpetas del sistema) para comprobar que las pruebas usan una carpeta aislada y no la de la partida real.
# No escribe nada por sí misma.


func _initialize() -> void:
	print("SONDA_USER_DIR=", OS.get_user_data_dir())
	print("SONDA_DATA_DIR=", OS.get_data_dir())
	print("SONDA_CONFIG_DIR=", OS.get_config_dir())
	print("SONDA_CACHE_DIR=", OS.get_cache_dir())
	quit()
