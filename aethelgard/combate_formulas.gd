extends RefCounted
# Fórmulas de daño del combate, sin estado (10/11: primer módulo separado de combate.gd, auditoría «combate modular»).
# Mismos cálculos y mismo orden de azar (randi_range del generador global) que tenían en combate.gd, que las sigue
# llamando con sus funciones de siempre (_dano_fisico y _dano_magia). La huella del combate debe salir idéntica.


# Golpe físico: ataque × multiplicadores (y el extra de Embuir si lleva un elemento), con ±2/+3 de azar; mínimo 1.
static func dano_fisico(quien: Dictionary, mult: float, extra_embuir: float) -> int:
	var d: float = quien["atk"] * quien.get("mult_fisico", 1.0) * mult
	if quien.get("embuir", "") != "":
		d *= 1.0 + extra_embuir
	return maxi(1, int(d) + randi_range(-2, 3))


# Magia de daño: daño del nivel × multiplicador mágico + extra, × multiplicador del héroe, con ±3 de azar; mínimo 1.
static func dano_magia(quien: Dictionary, d: Dictionary) -> int:
	var base: float = d["dano"] * quien.get("magia_mult", 1.0) + quien.get("magia_extra", 0)
	return maxi(1, int(base * quien.get("mult_magia", 1.0))) + randi_range(-3, 3)
