extends RefCounted
# GENERADO por ciudades/oakhaven_arte/fuente/hornear.py (generar_datos.py): no se edita a mano.
# Por pieza: «rect», la huella de diseño (casillas); «sprites», cada imagen con su esquina («pos», píxeles del
# mundo 2D a 64 por casilla), su tamaño, la «y» con la que se ordena frente a Kael («orden») y su tipo;
# «suelo», la calcomanía de sombra y luz; «anclas», puntos con nombre; «efectos», humo, halos y luciérnagas;
# «choques», cajas que no se pueden atravesar (centro y tamaño en casillas).

const PIEZAS := {
	"arbol": {
		"rect": Rect2i(38, 5, 4, 4),
		"sprites": [
			{"capa": "raices", "tex": "arbol_raices.webp", "pos": Vector2(2117.0, 139.0), "tam": Vector2(860.0, 848.0), "orden": 139.0, "tipo": "objeto", "escala": 2.0},
			{"capa": "cuerpo", "tex": "arbol_cuerpo.webp", "pos": Vector2(2224.0, 0.0), "tam": Vector2(712.0, 517.0), "orden": 576.0, "tipo": "edificio"},
			{"capa": "copa", "tex": "arbol_copa.webp", "pos": Vector2(2043.0, 0.0), "tam": Vector2(1035.0, 511.0), "orden": 577.28, "tipo": "edificio", "viento": 1.0},
		],
		"suelo": {"tex": "arbol_suelo.png", "pos": Vector2(1947.0, 9.0), "tam": Vector2(1304.0, 1096.0), "escala": 4.0},
		"anclas": {"farolillo_1": Vector2(2316.8, 377.6), "farolillo_2": Vector2(2790.4, 384.), "farolillo_3": Vector2(2521.6, 403.2), "tronco": Vector2(2560.0, 576.0), "luciernagas": Vector2(2560.0, 652.8), "cofre_raices": Vector2(2752.0, 192.0), "anillos": Vector2(2880.0, 608.0), "encina": Vector2(2240.0, 640.0)},
		"efectos": [{"tipo": "luciernagas", "ancla": "luciernagas", "caja": Vector2(16.0, 5.0), "cantidad": 14.0}, {"tipo": "halo", "ancla": "farolillo_1", "radio": 0.9, "fuerza": 0.45}, {"tipo": "halo", "ancla": "farolillo_2", "radio": 0.9, "fuerza": 0.45}, {"tipo": "halo", "ancla": "farolillo_3", "radio": 0.9, "fuerza": 0.45}, {"tipo": "brillo", "ancla": "cofre_raices", "radio": 0.45, "fuerza": 0.9, "color": "oro", "estado_no": "cofre_raices_abierto", "delante": 4.0}],
		"choques": [],
	},
	"botica": {
		"rect": Rect2i(33, 35, 5, 5),
		"sprites": [
			{"capa": "cuerpo", "tex": "botica_cuerpo.webp", "pos": Vector2(2092.0, 1771.0), "tam": Vector2(360.0, 809.0), "orden": 2560.0, "tipo": "edificio"},
			{"capa": "letrero", "tex": "botica_letrero.webp", "pos": Vector2(2194.0, 2414.0), "tam": Vector2(41.0, 44.0), "orden": 2611.2, "tipo": "letrero", "pivote": Vector2(2214.4, 2409.6)},
		],
		"suelo": {"tex": "botica_suelo.png", "pos": Vector2(1984.0, 1804.0), "tam": Vector2(608.0, 900.0), "escala": 4.0},
		"anclas": {"puerta": Vector2(2304.0, 2592.0), "humo0": Vector2(2272.13, 1788.8)},
		"efectos": [{"tipo": "humo", "ancla": "humo0", "color": "calido", "alto": 2.4, "escala": 0.75}],
		"choques": [],
	},
	"casa_3x4": {
		"rect": Rect2i(0, 0, 3, 4),
		"sprites": [
			{"capa": "cuerpo", "tex": "casa_3x4_cuerpo.webp", "pos": Vector2(-24.0, -472.0), "tam": Vector2(240.0, 748.0), "orden": 256.0, "tipo": "edificio"},
		],
		"suelo": {"tex": "casa_3x4_suelo.png", "pos": Vector2(-122.0, -359.0), "tam": Vector2(476.0, 752.0), "escala": 4.0},
		"anclas": {"puerta": Vector2(70.4, 288.0), "humo0": Vector2(74.67, -428.8)},
		"efectos": [{"tipo": "humo", "ancla": "humo0", "color": "calido", "alto": 2.4, "escala": 0.75}],
		"choques": [],
	},
	"casa_4x4": {
		"rect": Rect2i(0, 0, 4, 4),
		"sprites": [
			{"capa": "cuerpo", "tex": "casa_4x4_cuerpo.webp", "pos": Vector2(-24.0, -501.0), "tam": Vector2(304.0, 777.0), "orden": 256.0, "tipo": "edificio"},
		],
		"suelo": {"tex": "casa_4x4_suelo.png", "pos": Vector2(-121.0, -412.0), "tam": Vector2(540.0, 812.0), "escala": 4.0},
		"anclas": {"puerta": Vector2(70.4, 288.0), "humo0": Vector2(117.79, -457.6)},
		"efectos": [{"tipo": "humo", "ancla": "humo0", "color": "calido", "alto": 2.4, "escala": 0.75}],
		"choques": [],
	},
	"casa_4x5": {
		"rect": Rect2i(0, 0, 4, 5),
		"sprites": [
			{"capa": "cuerpo", "tex": "casa_4x5_cuerpo.webp", "pos": Vector2(-24.0, -500.0), "tam": Vector2(304.0, 840.0), "orden": 320.0, "tipo": "edificio"},
		],
		"suelo": {"tex": "casa_4x5_suelo.png", "pos": Vector2(-125.0, -463.0), "tam": Vector2(544.0, 928.0), "escala": 4.0},
		"anclas": {"puerta": Vector2(70.4, 352.0), "farol": Vector2(124.8, 206.08), "humo0": Vector2(195.3, -438.4)},
		"efectos": [{"tipo": "halo", "ancla": "farol", "radio": 1.1, "fuerza": 0.45}, {"tipo": "humo", "ancla": "humo0", "color": "calido", "alto": 2.4, "escala": 0.75}],
		"choques": [],
	},
	"casa_5x4": {
		"rect": Rect2i(0, 0, 5, 4),
		"sprites": [
			{"capa": "cuerpo", "tex": "casa_5x4_cuerpo.webp", "pos": Vector2(-20.0, -462.0), "tam": Vector2(360.0, 738.0), "orden": 256.0, "tipo": "edificio"},
		],
		"suelo": {"tex": "casa_5x4_suelo.png", "pos": Vector2(-118.0, -436.0), "tam": Vector2(596.0, 836.0), "escala": 4.0},
		"anclas": {"puerta": Vector2(156.56, 288.0), "farol": Vector2(210.96, 142.08), "humo0": Vector2(105.63, -444.8)},
		"efectos": [{"tipo": "halo", "ancla": "farol", "radio": 1.1, "fuerza": 0.45}, {"tipo": "humo", "ancla": "humo0", "color": "calido", "alto": 2.4, "escala": 0.75}],
		"choques": [],
	},
	"casa_5x5": {
		"rect": Rect2i(0, 0, 5, 5),
		"sprites": [
			{"capa": "cuerpo", "tex": "casa_5x5_cuerpo.webp", "pos": Vector2(-20.0, -469.0), "tam": Vector2(360.0, 809.0), "orden": 320.0, "tipo": "edificio"},
		],
		"suelo": {"tex": "casa_5x5_suelo.png", "pos": Vector2(-123.0, -438.0), "tam": Vector2(600.0, 904.0), "escala": 4.0},
		"anclas": {"puerta": Vector2(116.86, 352.0), "farol": Vector2(171.26, 206.08), "humo0": Vector2(171.94, -451.2)},
		"efectos": [{"tipo": "halo", "ancla": "farol", "radio": 1.1, "fuerza": 0.45}, {"tipo": "humo", "ancla": "humo0", "color": "calido", "alto": 2.4, "escala": 0.75}],
		"choques": [],
	},
	"casa_6x4": {
		"rect": Rect2i(0, 0, 6, 4),
		"sprites": [
			{"capa": "cuerpo", "tex": "casa_6x4_cuerpo.webp", "pos": Vector2(-20.0, -462.0), "tam": Vector2(424.0, 738.0), "orden": 256.0, "tipo": "edificio"},
		],
		"suelo": {"tex": "casa_6x4_suelo.png", "pos": Vector2(-124.0, -458.0), "tam": Vector2(668.0, 860.0), "escala": 4.0},
		"anclas": {"puerta": Vector2(107.14, 288.0), "humo0": Vector2(146.31, -444.8), "humo1": Vector2(81.14, -444.8)},
		"efectos": [{"tipo": "humo", "ancla": "humo0", "color": "calido", "alto": 2.4, "escala": 0.75}, {"tipo": "humo", "ancla": "humo1", "color": "calido", "alto": 2.4, "escala": 0.75}],
		"choques": [],
	},
	"casa_6x5": {
		"rect": Rect2i(0, 0, 6, 5),
		"sprites": [
			{"capa": "cuerpo", "tex": "casa_6x5_cuerpo.webp", "pos": Vector2(-20.0, -469.0), "tam": Vector2(424.0, 809.0), "orden": 320.0, "tipo": "edificio"},
		],
		"suelo": {"tex": "casa_6x5_suelo.png", "pos": Vector2(-129.0, -464.0), "tam": Vector2(672.0, 928.0), "escala": 4.0},
		"anclas": {"puerta": Vector2(201.68, 352.0), "humo0": Vector2(127.74, -451.2)},
		"efectos": [{"tipo": "humo", "ancla": "humo0", "color": "calido", "alto": 2.4, "escala": 0.75}],
		"choques": [],
	},
	"concejo": {
		"rect": Rect2i(43, 16, 9, 5),
		"sprites": [
			{"capa": "cuerpo", "tex": "concejo_cuerpo.webp", "pos": Vector2(2729.0, 496.0), "tam": Vector2(622.0, 854.0), "orden": 1344.0, "tipo": "edificio"},
			{"capa": "portico", "tex": "concejo_portico.webp", "pos": Vector2(2744.0, 1070.0), "tam": Vector2(592.0, 410.0), "orden": 1475.2, "tipo": "edificio"},
		],
		"suelo": {"tex": "concejo_suelo.png", "pos": Vector2(2603.0, 486.0), "tam": Vector2(908.0, 1136.0), "escala": 4.0},
		"anclas": {"humo": Vector2(2828.8, 515.2), "puerta": Vector2(3008.0, 1382.4), "tapiz": Vector2(2912.0, 1248.), "farol_portico_1": Vector2(2951.68, 1283.2), "farol_portico_2": Vector2(3180.8, 1283.2)},
		"efectos": [{"tipo": "humo", "ancla": "humo", "color": "calido", "alto": 2.6, "escala": 0.8}, {"tipo": "halo", "ancla": "farol_portico_1", "radio": 1.1, "fuerza": 0.45}, {"tipo": "halo", "ancla": "farol_portico_2", "radio": 1.1, "fuerza": 0.45}],
		"choques": [{"centro": Vector2(43.35, 22.85), "tam": Vector2(0.5, 0.5)}, {"centro": Vector2(45.25, 22.85), "tam": Vector2(0.5, 0.5)}, {"centro": Vector2(47.0, 22.85), "tam": Vector2(0.5, 0.5)}, {"centro": Vector2(48.75, 22.85), "tam": Vector2(0.5, 0.5)}, {"centro": Vector2(50.65, 22.85), "tam": Vector2(0.5, 0.5)}, {"centro": Vector2(51.65, 22.85), "tam": Vector2(0.5, 0.5)}],
	},
	"crematorio": {
		"rect": Rect2i(62, 7, 10, 8),
		"sprites": [
			{"capa": "cuerpo", "tex": "crematorio_cuerpo.webp", "pos": Vector2(3948.0, 136.0), "tam": Vector2(680.0, 892.0), "orden": 960.0, "tipo": "edificio"},
		],
		"suelo": {"tex": "crematorio_suelo.png", "pos": Vector2(3929.0, 121.0), "tam": Vector2(856.0, 984.0), "escala": 4.0},
		"anclas": {"humo": Vector2(4518.4, 284.8), "puerta": Vector2(4288.0, 992.0), "sello": Vector2(4288.0, 841.6)},
		"efectos": [{"tipo": "humo", "ancla": "humo", "color": "frio", "alto": 4.2, "escala": 1.2}],
		"choques": [],
	},
	"farol": {
		"rect": Rect2i(0, 0, 1, 1),
		"sprites": [
			{"capa": "farola", "tex": "farol_farola.webp", "pos": Vector2(18.0, -177.0), "tam": Vector2(28.0, 220.0), "orden": 39.68, "tipo": "objeto"},
		],
		"suelo": {"tex": "farol_suelo.png", "pos": Vector2(-75.0, -169.0), "tam": Vector2(220.0, 308.0), "escala": 4.0},
		"anclas": {"farol": Vector2(32.0, -152.32)},
		"efectos": [{"tipo": "halo", "ancla": "farol", "radio": 1.3, "fuerza": 0.5, "delante": 0.5}],
		"choques": [{"centro": Vector2(0.5, 0.5), "tam": Vector2(0.35, 0.3)}],
	},
	"grieta": {
		"rect": Rect2i(23, 35, 1, 1),
		"sprites": [
			{"capa": "cuerpo", "tex": "grieta_cuerpo.webp", "pos": Vector2(1272.0, 2052.0), "tam": Vector2(463.0, 253.0), "orden": 2304.0, "tipo": "edificio"},
		],
		"suelo": {"tex": "grieta_suelo.png", "pos": Vector2(1246.0, 2043.0), "tam": Vector2(528.0, 316.0), "escala": 4.0},
		"anclas": {"grieta": Vector2(1504.0, 2272.0), "luz": Vector2(1504.0, 2233.6)},
		"efectos": [{"tipo": "halo", "ancla": "luz", "radio": 0.8, "fuerza": 0.5, "color": "vela"}],
		"choques": [],
	},
	"guardia": {
		"rect": Rect2i(44, 45, 5, 4),
		"sprites": [
			{"capa": "cuerpo", "tex": "guardia_cuerpo.webp", "pos": Vector2(2796.0, 2418.0), "tam": Vector2(360.0, 738.0), "orden": 3136.0, "tipo": "edificio"},
			{"capa": "soportal", "tex": "guardia_soportal.webp", "pos": Vector2(2610.0, 2657.0), "tam": Vector2(210.0, 476.0), "orden": 3136.0, "tipo": "edificio"},
			{"capa": "patio", "tex": "guardia_patio.webp", "pos": Vector2(2821.0, 3125.0), "tam": Vector2(323.0, 265.0), "orden": 3388.8, "tipo": "objeto"},
		],
		"suelo": {"tex": "guardia_suelo.png", "pos": Vector2(2413.0, 2427.0), "tam": Vector2(880.0, 1104.0), "escala": 4.0},
		"anclas": {"puerta": Vector2(2976.0, 3168.0), "farol": Vector2(3030.4, 3022.08), "humo0": Vector2(3011.29, 2435.2), "brasero": Vector2(2892.8, 3136.), "libro": Vector2(2720.0, 2912.0), "farol_soportal": Vector2(2726.4, 2966.4)},
		"efectos": [{"tipo": "halo", "ancla": "farol", "radio": 1.1, "fuerza": 0.45}, {"tipo": "humo", "ancla": "humo0", "color": "calido", "alto": 2.4, "escala": 0.75}, {"tipo": "halo", "ancla": "brasero", "radio": 1.3, "fuerza": 0.55, "color": "vela"}, {"tipo": "halo", "ancla": "farol_soportal", "radio": 1.1, "fuerza": 0.45}],
		"choques": [{"centro": Vector2(45.2, 49.9), "tam": Vector2(0.8, 0.6)}, {"centro": Vector2(48.1, 50.55), "tam": Vector2(1.1, 0.8)}],
	},
	"jardin_urnas": {
		"rect": Rect2i(57, 9, 5, 5),
		"sprites": [
			{"capa": "fondo", "tex": "jardin_urnas_fondo.webp", "pos": Vector2(3658.0, 399.0), "tam": Vector2(300.0, 211.0), "orden": 614.4, "tipo": "objeto"},
			{"capa": "urnas_norte", "tex": "jardin_urnas_urnas_norte.webp", "pos": Vector2(3678.0, 554.0), "tam": Vector2(260.0, 119.0), "orden": 675.2, "tipo": "objeto"},
			{"capa": "urnas_sur", "tex": "jardin_urnas_urnas_sur.webp", "pos": Vector2(3678.0, 712.0), "tam": Vector2(260.0, 115.0), "orden": 828.8, "tipo": "objeto"},
		],
		"suelo": {"tex": "jardin_urnas_suelo.png", "pos": Vector2(3651.0, 377.0), "tam": Vector2(392.0, 460.0), "escala": 4.0},
		"anclas": {"paseo": Vector2(3808.0, 736.0)},
		"efectos": [],
		"choques": [{"centro": Vector2(59.5, 10.2), "tam": Vector2(4.2, 0.7)}, {"centro": Vector2(59.5, 12.6), "tam": Vector2(4.2, 0.7)}, {"centro": Vector2(57.4, 9.4), "tam": Vector2(0.8, 0.6)}, {"centro": Vector2(61.6, 9.3), "tam": Vector2(0.8, 0.6)}],
	},
	"mercado": {
		"rect": Rect2i(48, 27, 12, 5),
		"sprites": [
			{"capa": "puesto_1", "tex": "mercado_puesto_1.webp", "pos": Vector2(3071.0, 1562.0), "tam": Vector2(268.0, 286.0), "orden": 1852.8, "tipo": "objeto"},
			{"capa": "puesto_2", "tex": "mercado_puesto_2.webp", "pos": Vector2(3346.0, 1562.0), "tam": Vector2(268.0, 286.0), "orden": 1852.8, "tipo": "objeto"},
			{"capa": "puesto_3", "tex": "mercado_puesto_3.webp", "pos": Vector2(3621.0, 1562.0), "tam": Vector2(249.0, 286.0), "orden": 1852.8, "tipo": "objeto"},
			{"capa": "guirnalda", "tex": "mercado_guirnalda.webp", "pos": Vector2(3110.0, 1675.0), "tam": Vector2(724.0, 31.0), "orden": 1856.0, "tipo": "objeto"},
		],
		"suelo": {"tex": "mercado_suelo.png", "pos": Vector2(2996.0, 1554.0), "tam": Vector2(980.0, 384.0), "escala": 4.0},
		"anclas": {"tienda": Vector2(3456.0, 1920.0)},
		"efectos": [],
		"choques": [{"centro": Vector2(50.1, 28.0), "tam": Vector2(3.4, 1.8)}, {"centro": Vector2(54.4, 28.0), "tam": Vector2(3.4, 1.8)}, {"centro": Vector2(58.55, 28.0), "tam": Vector2(3.1, 1.8)}],
	},
	"patio_cuervo": {
		"rect": Rect2i(10, 27, 5, 4),
		"sprites": [
			{"capa": "barriles", "tex": "patio_cuervo_barriles.webp", "pos": Vector2(670.0, 1654.0), "tam": Vector2(240.0, 298.0), "orden": 1958.4, "tipo": "objeto"},
		],
		"suelo": {"tex": "patio_cuervo_suelo.png", "pos": Vector2(663.0, 1651.0), "tam": Vector2(304.0, 328.0), "escala": 4.0},
		"anclas": {"barril": Vector2(768.0, 1798.4)},
		"efectos": [],
		"choques": [{"centro": Vector2(11.3, 28.0), "tam": Vector2(1.6, 0.8)}, {"centro": Vector2(13.6, 28.2), "tam": Vector2(1.0, 0.8)}, {"centro": Vector2(12.2, 29.0), "tam": Vector2(0.8, 0.8)}, {"centro": Vector2(13.6, 30.05), "tam": Vector2(1.2, 0.9)}],
	},
	"patio_velas": {
		"rect": Rect2i(19, 36, 9, 4),
		"sprites": [
			{"capa": "altar", "tex": "patio_velas_altar.webp", "pos": Vector2(1548.0, 2303.0), "tam": Vector2(171.0, 153.0), "orden": 2441.6, "tipo": "objeto"},
		],
		"suelo": {"tex": "patio_velas_suelo.png", "pos": Vector2(1497.0, 2294.0), "tam": Vector2(276.0, 216.0), "escala": 4.0},
		"anclas": {"velas": Vector2(1632.0, 2342.4), "velas_suelo": Vector2(1632.0, 2432.)},
		"efectos": [{"tipo": "halo", "ancla": "velas", "radio": 1.5, "fuerza": 0.5, "color": "vela"}, {"tipo": "halo", "ancla": "velas_suelo", "radio": 1.2, "fuerza": 0.35, "color": "vela"}],
		"choques": [{"centro": Vector2(25.5, 37.6), "tam": Vector2(1.6, 0.9)}],
	},
	"plaza": {
		"rect": Rect2i(35, 21, 11, 10),
		"sprites": [
			{"capa": "fuente", "tex": "plaza_fuente.webp", "pos": Vector2(2446.0, 1475.0), "tam": Vector2(228.0, 297.0), "orden": 1740.8, "tipo": "objeto"},
			{"capa": "tablon", "tex": "plaza_tablon.webp", "pos": Vector2(2249.0, 1674.0), "tam": Vector2(110.0, 176.0), "orden": 1852.8, "tipo": "objeto"},
			{"capa": "flores", "tex": "plaza_flores.webp", "pos": Vector2(2725.0, 1701.0), "tam": Vector2(148.0, 133.0), "orden": 1830.4, "tipo": "objeto"},
		],
		"suelo": {"tex": "plaza_suelo.png", "pos": Vector2(2246.0, 1473.0), "tam": Vector2(684.0, 404.0), "escala": 4.0},
		"anclas": {"fuente": Vector2(2560.0, 1516.8), "tablon": Vector2(2304.0, 1760.), "flores": Vector2(2816.0, 1734.4)},
		"efectos": [],
		"choques": [{"centro": Vector2(40.0, 26.0), "tam": Vector2(3.4, 3.0)}, {"centro": Vector2(36.0, 28.8), "tam": Vector2(1.5, 0.3)}, {"centro": Vector2(44.0, 28.1), "tam": Vector2(1.7, 0.8)}],
	},
	"puerta_sur": {
		"rect": Rect2i(37, 51, 7, 5),
		"sprites": [
			{"capa": "torre_oeste", "tex": "puerta_sur_torre_oeste.webp", "pos": Vector2(2201.0, 2863.0), "tam": Vector2(218.0, 642.0), "orden": 3507.2, "tipo": "edificio"},
			{"capa": "torre_este", "tex": "puerta_sur_torre_este.webp", "pos": Vector2(2766.0, 2863.0), "tam": Vector2(217.0, 642.0), "orden": 3507.2, "tipo": "edificio"},
			{"capa": "arco", "tex": "puerta_sur_arco.webp", "pos": Vector2(2360.0, 3004.0), "tam": Vector2(464.0, 281.0), "orden": 3580.8, "tipo": "edificio"},
		],
		"suelo": {"tex": "puerta_sur_suelo.png", "pos": Vector2(2136.0, 2762.0), "tam": Vector2(936.0, 744.0), "escala": 4.0},
		"anclas": {"farol_oeste": Vector2(2406.4, 3340.8), "farol_este": Vector2(2777.6, 3340.8), "salida": Vector2(2592.0, 3552.0)},
		"efectos": [{"tipo": "halo", "ancla": "farol_oeste", "radio": 1.2, "fuerza": 0.5}, {"tipo": "halo", "ancla": "farol_este", "radio": 1.2, "fuerza": 0.5}],
		"choques": [{"centro": Vector2(36.0, 53.4), "tam": Vector2(2.4, 2.0)}, {"centro": Vector2(45.0, 53.4), "tam": Vector2(2.4, 2.0)}],
	},
	"ronda": {
		"rect": Rect2i(76, 28, 2, 14),
		"sprites": [
			{"capa": "cuerpo", "tex": "ronda_cuerpo.webp", "pos": Vector2(4850.0, 1728.0), "tam": Vector2(220.0, 1181.0), "orden": 1792.0, "tipo": "objeto"},
			{"capa": "farol_1_on", "tex": "ronda_farol_1_on.webp", "pos": Vector2(5003.0, 1856.0), "tam": Vector2(23.0, 47.0), "orden": 1793.28, "tipo": "objeto", "estado": "farol_1"},
			{"capa": "farol_2_on", "tex": "ronda_farol_2_on.webp", "pos": Vector2(5003.0, 2048.0), "tam": Vector2(23.0, 47.0), "orden": 1793.28, "tipo": "objeto", "estado": "farol_2"},
			{"capa": "farol_3_on", "tex": "ronda_farol_3_on.webp", "pos": Vector2(5003.0, 2304.0), "tam": Vector2(23.0, 47.0), "orden": 1793.28, "tipo": "objeto", "estado": "farol_3"},
		],
		"suelo": {"tex": "ronda_suelo.png", "pos": Vector2(4797.0, 1730.0), "tam": Vector2(392.0, 1248.0), "escala": 4.0},
		"anclas": {"farol_1": Vector2(5014.4, 1878.4), "farol_2": Vector2(5014.4, 2070.4), "farol_3": Vector2(5014.4, 2326.4), "subida": Vector2(4896.0, 2656.0), "cofre": Vector2(4896.0, 1824.0)},
		"efectos": [{"tipo": "halo", "ancla": "farol_1", "radio": 1.4, "fuerza": 0.55, "estado": "farol_1", "delante": 6.0}, {"tipo": "halo", "ancla": "farol_2", "radio": 1.4, "fuerza": 0.55, "estado": "farol_2", "delante": 6.0}, {"tipo": "halo", "ancla": "farol_3", "radio": 1.4, "fuerza": 0.55, "estado": "farol_3", "delante": 6.0}],
		"choques": [],
	},
	"ropa_tendida": {
		"rect": Rect2i(0, 0, 3, 1),
		"sprites": [
			{"capa": "postes", "tex": "ropa_tendida_postes.webp", "pos": Vector2(2.0, -142.0), "tam": Vector2(188.0, 176.0), "orden": 38.4, "tipo": "objeto"},
			{"capa": "ropa", "tex": "ropa_tendida_ropa.webp", "pos": Vector2(6.0, -129.0), "tam": Vector2(180.0, 71.0), "orden": 39.68, "tipo": "letrero", "pivote": Vector2(96.0, -127.36)},
		],
		"suelo": {"tex": "ropa_tendida_suelo.png", "pos": Vector2(-2.0, -127.0), "tam": Vector2(252.0, 172.0), "escala": 4.0},
		"anclas": {},
		"efectos": [],
		"choques": [{"centro": Vector2(0.11, 0.46), "tam": Vector2(0.2, 0.2)}, {"centro": Vector2(2.89, 0.46), "tam": Vector2(0.2, 0.2)}],
	},
	"subida_colina": {
		"rect": Rect2i(64, 19, 2, 6),
		"sprites": [
			{"capa": "escalera", "tex": "subida_colina_escalera.webp", "pos": Vector2(4095.0, 1203.0), "tam": Vector2(130.0, 398.0), "orden": 1203.0, "tipo": "objeto"},
		],
		"anclas": {"arriba": Vector2(4160.0, 1235.2), "abajo": Vector2(4160.0, 1580.8)},
		"efectos": [],
		"choques": [],
	},
	"taberna": {
		"rect": Rect2i(11, 19, 10, 6),
		"sprites": [
			{"capa": "cuerpo", "tex": "taberna_cuerpo.webp", "pos": Vector2(681.0, 720.0), "tam": Vector2(686.0, 901.0), "orden": 1600.0, "tipo": "edificio"},
			{"capa": "letrero", "tex": "taberna_letrero.webp", "pos": Vector2(794.0, 1441.0), "tam": Vector2(66.0, 75.0), "orden": 1670.4, "tipo": "letrero", "pivote": Vector2(832.0, 1441.92)},
		],
		"suelo": {"tex": "taberna_suelo.png", "pos": Vector2(552.0, 711.0), "tam": Vector2(972.0, 1056.0), "escala": 4.0},
		"anclas": {"humo": Vector2(784.0, 742.4), "humo_chica": Vector2(1299.2, 745.6), "farol_puerta": Vector2(985.6, 1476.48), "puerta": Vector2(1062.4, 1625.6), "letrero": Vector2(832.0, 1441.92)},
		"efectos": [{"tipo": "humo", "ancla": "humo", "color": "calido", "alto": 3.2}, {"tipo": "humo", "ancla": "humo_chica", "color": "calido", "alto": 2.2, "escala": 0.6}, {"tipo": "halo", "ancla": "farol_puerta", "radio": 1.3}],
		"choques": [],
	},
	"torre": {
		"rect": Rect2i(72, 38, 4, 4),
		"sprites": [
			{"capa": "cuerpo", "tex": "torre_cuerpo.webp", "pos": Vector2(4584.0, 1588.0), "tam": Vector2(304.0, 1110.0), "orden": 2688.0, "tipo": "edificio"},
		],
		"suelo": {"tex": "torre_suelo.png", "pos": Vector2(4482.0, 1705.0), "tam": Vector2(552.0, 1128.0), "escala": 4.0},
		"anclas": {"puerta": Vector2(4736.0, 2726.4), "farol_puerta": Vector2(4668.8, 2574.08), "campana": Vector2(4736.0, 1958.4)},
		"efectos": [{"tipo": "halo", "ancla": "farol_puerta", "radio": 1.2, "fuerza": 0.5}, {"tipo": "halo", "ancla": "campana", "radio": 1.6, "fuerza": 0.22, "parpadeo": 0.3}],
		"choques": [],
	},
}
