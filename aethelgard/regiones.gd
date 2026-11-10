extends RefCounted
# Identificadores estables de los lugares del mapa (10/11, auditoría: «IDs permanentes de regiones»). Hoy las partidas
# guardan el índice del lugar («lugar.indice») y el código usa índices (mapa.gd, modo3d.gd). Estos ids de texto no
# cambian aunque se reordene la lista: sirven para que una migración futura pase de índices a ids sin perder partidas.
# No se usan todavía para guardar (sin migración activa): solo traducen en los dos sentidos.

const IDS := {
	0: "oakhaven",
	1: "gran_bosque_verde",
	2: "garganta_del_diablo",
	3: "cumbres_de_ciclopea",
	4: "mar_de_arena_de_calid",
	5: "sunken_city",
	6: "valle_de_los_ecos",
	7: "templo_sumergido_de_atlantis",
	8: "abismo_de_ceniza",
	9: "portal_del_vacio",
	10: "pastos_verdes",
}


static func id_de(indice: int) -> String:
	return IDS.get(indice, "")


static func indice_de(id: String) -> int:
	for k in IDS:
		if IDS[k] == id:
			return k
	return -1
