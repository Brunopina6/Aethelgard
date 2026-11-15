extends "res://pruebas/prueba_banco_pruebas.gd"
# DIAGNÓSTICO (15/11), no prueba del juego: el cierre intermitente 0xC0000005 de Godot al TERMINAR prueba_banco_pruebas
# (ocurre tras «FALLOS: 0», durante el apagado del motor; en las pasadas buenas el motor avisa de 386 objetos y 120
# recursos que siguen vivos al salir: imágenes, texturas, fuentes, tema, sombreado, guiones). Hipótesis: recursos de
# render retenidos por variables ESTÁTICAS de guiones y por metas de Engine se liberan cuando el servidor de render ya
# no existe. Esta variante hace la misma prueba y, en _finalize (antes del apagado), vacía esas cachés y metas e
# imprime cuántos objetos había y cuántos quedan. Comparando N pasadas de cada una se ve si el cierre desaparece.
# NO cambia el juego. Uso: como prueba_banco_pruebas (--headless --script res://pruebas/diag_cierre_banco.gd).

const CACHES := {
	"res://estilo.gd": ["_tema", "_cursiva", "_normal"],
	"res://material_arma.gd": ["_shader"],
	"res://enemigos/v12_comun/enemigo_v12_3d.gd": ["_atlas_compartidos"],
	"res://datos/catalogo.gd": ["_cache"],
	"res://personajes/npc_v12/npc_chibi.gd": ["_escenas", "_materiales"],
	"res://ciudades/oakhaven_piezas.gd": ["_mats", "_blanco"],
	"res://prototipos/arbol_estilizado.gd": ["_cache"],
	"res://capa_garon.gd": ["_cache_muestras"],
	"res://prototipos/calidad_proto.gd": ["_extra_cache"],
	"res://vfx/agua_v12.gd": ["_activo_cache"],
}


func _finalize() -> void:
	var antes := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var vaciadas: Array = []
	for ruta in CACHES:
		if not ResourceLoader.has_cached(ruta):
			continue                                 # (no se usó en la prueba: no se carga ahora)
		var s = load(ruta)
		for v in CACHES[ruta]:
			var val = s.get(v)
			if val == null:
				continue
			s.set(v, {} if val is Dictionary else null)
			vaciadas.append("%s.%s" % [ruta.get_file(), v])
	var metas: Array = []
	for k in Engine.get_meta_list():
		var val = Engine.get_meta(k)
		if val is Object or val is Dictionary or val is Array:
			Engine.remove_meta(k)
			metas.append(String(k))
	print("[diag_cierre] _finalize: objetos %d → %d · cachés vaciadas: %s · metas quitadas: %s" % [antes,
		int(Performance.get_monitor(Performance.OBJECT_COUNT)), ", ".join(vaciadas), ", ".join(metas)])
