extends "res://pruebas/prueba_zarzalin_modelo.gd"
# Capturas de Zarzalín desde la cámara del combate (T-097): la misma prueba que prueba_zarzalin_modelo.gd, con sus
# comprobaciones, y además las capturas en <carpeta> (con ventana; ejecutar_pruebas.ps1 -Manual le da {salida}).
#   --script res://pruebas/prueba_zarzalin_fotos.gd --fixed-fps 30 -- <carpeta> [tam=1.25]


func _initialize() -> void:
	super._initialize()
	for a in OS.get_cmdline_user_args():
		if not "=" in a:
			fotos = a
			break
