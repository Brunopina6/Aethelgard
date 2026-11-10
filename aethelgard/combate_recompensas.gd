extends RefCounted
# Recompensas del combate (fase 2 de la modularización, 10/11): las cuentas de experiencia y monedas que antes estaban
# dentro de combate.gd (_repartir_exp). Solo cuentas, sin estado ni escena: combate.gd sigue mostrando los textos, los
# sonidos y las subidas de nivel. Mismos resultados que antes (prueba_combate_huella y prueba_recompensas).

# Lo que dan los enemigos derrotados: los que huyen no dan nada.
static func de_enemigos(enemigos: Array) -> Dictionary:
	var total := 0
	var oro := 0
	for e in enemigos:
		if e.get("huido", false):
			continue
		total += int(e.get("exp", 0))
		oro += int(e.get("oro", 0))
	return {"exp": total, "oro": oro}


# Experiencia de un héroe: la de todos los enemigos por el multiplicador de su nivel en la zona (progreso.mult_exp).
# Los caídos ganan la mitad (división entera, como antes).
static func exp_de_heroe(total: int, mult: float, caido: bool) -> int:
	var cantidad := int(round(total * mult))
	return cantidad / 2 if caido else cantidad
