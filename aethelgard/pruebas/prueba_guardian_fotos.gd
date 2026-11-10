extends "res://pruebas/prueba_guardian_modelo.gd"
# Capturas del Guardián del Bosque en un combate de verdad (fase 3): la misma prueba que prueba_guardian_modelo.gd,
# con sus comprobaciones, y además las capturas en <carpeta> (con ventana; ejecutar_pruebas.ps1 -Manual le da {salida}).
#   --script res://pruebas/prueba_guardian_fotos.gd --fixed-fps 30 -- <carpeta>


func _initialize() -> void:
	super._initialize()
	for a in OS.get_cmdline_user_args():
		if not "=" in a:
			fotos = a
			break
