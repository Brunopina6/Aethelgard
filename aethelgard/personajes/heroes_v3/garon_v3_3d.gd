extends "res://personajes/heroes_v2/garon_v2_3d.gd"
# Garon v3 (V12; detrás de la elección «Protagonistas: v3 (prueba)», APAGADA por defecto).
#
# Hereda TODO de garon_v2_3d.gd (mismos clips, instantes y API de combate, exploración y conversación) y solo cambia
# el modelo (personajes/heroes_v3/garon/garon_v3.glb: GEOMETRÍA PROPIA sobre el MISMO esqueleto, crear_heroes_v3.py y
# garon_v3.py), la cara y los materiales (heroe_v3_ayudante.gd). Si falta el GLB v3, se comporta como su v2.

const HeroesV3 := preload("res://personajes/heroes_v3/heroes_v3.gd")
const AyudanteV3 := preload("res://personajes/heroes_v3/heroe_v3_ayudante.gd")

var es_v3 := false


func _cargar_modelo() -> void:
	var glb: String = HeroesV3.GLB["Garon"]
	if ResourceLoader.exists(glb) and (ruta_modelo in HeroesV2.ORIGINALES["Garon"] or ruta_modelo == ""
			or ruta_modelo == HeroesV2.GLB["Garon"]):
		ruta_modelo = glb
		es_v3 = true
	super._cargar_modelo()


func _ready() -> void:
	super._ready()
	HeroesV3.cambiar_ayudante(self, "Garon", AyudanteV3)


# ---------------------------------------------------------------- la mirada en la visera (solo v3)
# Los v2 de Garon no tenían cara (yelmo cerrado). La v3 lleva dos brillos en la sombra de la visera que cambian con
# los mismos momentos que Kael y Lya: guardia (decidido), ataque (grito), golpe recibido (dolor), victoria (sonrisa),
# derribo (dolor y luego apagados), levantarse (cansado).
func _expr(nombre: String, dur := 0.0) -> void:
	if es_v3 and v2 != null and v2.has_method("tiene_cara") and v2.tiene_cara():
		v2.poner_expresion(nombre, dur)


func reposo() -> void:
	super.reposo()
	if not _muerta:
		_expr("normal" if _exploracion else "decidido")


func herida() -> void:
	if not _muerta:
		_expr("dolor", 0.7)
	await super.herida()


func victoria() -> void:
	super.victoria()
	if not _muerta:
		_expr("sonrisa")


func morir() -> void:
	if _muerta:
		return
	_expr("dolor")
	await super.morir()
	if _muerta:
		_expr("cerrados")


func revivir() -> void:
	if _muerta:
		_expr("entrecerrados", 1.4)
	await super.revivir()


func atacar_juicio(impacto: Callable) -> void:
	_expr("grito", 1.6)
	await super.atacar_juicio(impacto)


func atacar_giro(impacto: Callable) -> void:
	_expr("grito", 1.8)
	await super.atacar_giro(impacto)


func expresion(nombre: String, dur := 0.0) -> void:
	_expr(nombre, dur)
