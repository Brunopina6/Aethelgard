extends RefCounted
# V12, mapamundi 3D (15/11/2026): las maquetas de la región, cada una con su silueta propia para leerse de un vistazo en
# la pantalla del móvil. Hechas por código (kit.gd: una malla por maqueta, una llamada de dibujo), PROVISIONALES: son la
# propuesta de forma y color; el arte revisado (Blender) puede sustituirlas sin cambiar nada más.
#   - Oakhaven: muralla con torres, la Puerta del Sur mirando al camino, tejados rojos y pizarra, la Taberna del Cuervo
#     Oxidado, la torre de vigía, el crematorio de piedra hueso con su humo frío y, sobre todo, el Árbol Milenario (la
#     silueta que la distingue de lejos).
#   - Pastos Verdes: lomas verdes, el río con su puente de piedra, la cascada, la estela del camino y los faroles de Tilo.
#   - El Portal del Vacío: arco de oro con el remolino morado (mapa.gd: «Un arco de oro con un remolino morado»).
#   - El campamento de Pastos Verdes (PROPUESTA): dos tiendas, la hoguera y el mojón de viaje que brilla.
#   - La Cueva de los Helechos (PROPUESTA): un peñasco con la boca oscura y helechos.
#   - El Corro de los Mirlos (PROPUESTA, secreto): piedras con musgo dentro de un soto, y un mojón viejo.
#   - El poste del camino hacia el Gran Bosque Verde.

const D := preload("res://zonas3d/mapamundi/datos.gd")
const T := preload("res://zonas3d/mapamundi/terreno.gd")
const Kit := preload("res://zonas3d/mapamundi/kit.gd")
const EFECTOS := preload("res://zonas3d/mapamundi/efectos_mapamundi.gdshader")

const PIEDRA := Color(0.82, 0.76, 0.64)
const PIEDRA_HUESO := Color(0.85, 0.83, 0.78)         # #D9D4C7, el crematorio (docs/diseno/ciudades_y_lugares.md)
const TEJA := Color(0.70, 0.30, 0.20)
const PIZARRA := Color(0.30, 0.34, 0.47)
const MADERA := Color(0.46, 0.31, 0.19)
const ORO := Color(0.96, 0.78, 0.34)

var animados: Array = []                  # [nodo, tipo, base] que el mapamundi mueve cada fotograma (llama, humo)


static func suelo(p: Vector2, sobre := 0.0) -> Vector3:
	return Vector3(p.x, T.altura(p.x, p.y) + sobre, p.y)


static func mat_efecto(modo: int, a: Color, b: Color, opacidad := 1.0, velocidad := 1.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = EFECTOS
	m.set_shader_parameter("modo", modo)
	m.set_shader_parameter("color_a", a)
	m.set_shader_parameter("color_b", b)
	m.set_shader_parameter("opacidad", opacidad)
	m.set_shader_parameter("velocidad", velocidad)
	return m


static func plano(padre: Node3D, nombre: String, centro: Vector3, tam: Vector2, mat: Material, normal_arriba := true, giro := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nombre
	if normal_arriba:
		var pm := PlaneMesh.new()
		pm.size = tam
		mi.mesh = pm
	else:
		var q := QuadMesh.new()
		q.size = tam
		mi.mesh = q
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = centro
	mi.rotation.y = giro
	padre.add_child(mi)
	return mi


func crear(padre: Node3D, mat: Material, perfil: String) -> Dictionary:
	var r := {}
	r["oakhaven"] = _oakhaven(padre, mat, perfil)
	r["pastos"] = _pastos(padre, mat)
	r["portal"] = _portal(padre, mat)
	r["campamento"] = _campamento(padre, mat, perfil)
	r["cueva"] = _cueva(padre, mat)
	r["secreto"] = _secreto(padre, mat)
	r["gran_bosque"] = _poste(padre, mat)
	return r


# ================================================================= Oakhaven

func _oakhaven(padre: Node3D, mat: Material, perfil: String) -> Node3D:
	var c: Vector2 = D.SITIOS["oakhaven"]["centro"]
	var y := T.altura(c.x, c.y)
	var o := Vector3(c.x, y, c.y)
	var k := Kit.new()
	var R := 7.4
	var lados := 12
	# suelo empedrado dentro de la muralla
	k.cilindro(o + Vector3(0, -0.2, 0), R, R, 0.28, lados, Color(0.72, 0.66, 0.55))
	# muralla y torres; el hueco de la Puerta del Sur (mirando al sur, al camino)
	for i in lados:
		var a0 := TAU * (i + 0.5) / lados
		var a1 := TAU * (i + 1.5) / lados
		var p0 := o + Vector3(cos(a0), 0, sin(a0)) * R
		var p1 := o + Vector3(cos(a1), 0, sin(a1)) * R
		var medio := (p0 + p1) * 0.5
		var es_puerta := absf(wrapf(atan2(medio.z - o.z, medio.x - o.x) - PI * 0.5, -PI, PI)) < 0.2
		var largo := p0.distance_to(p1)
		var giro := -atan2(p1.z - p0.z, p1.x - p0.x)
		if not es_puerta:
			k.caja(medio, Vector3(largo, 1.35, 0.5), PIEDRA, giro)
			for m in 3:                                   # almenas
				var t := (m + 0.5) / 3.0
				k.caja(p0.lerp(p1, t) + Vector3(0, 1.35, 0), Vector3(largo / 6.0, 0.28, 0.5), PIEDRA, giro)
		if i % 3 == 0:                                    # torres
			k.cilindro(p0, 0.62, 0.58, 2.1, 8, PIEDRA.darkened(0.04))
			k.cono(p0 + Vector3(0, 2.1, 0), 0.82, 1.15, 8, TEJA)
	# Puerta del Sur: dos torres y el arco
	var puerta := o + Vector3(0, 0, R)
	for s in [-1.0, 1.0]:
		k.cilindro(puerta + Vector3(s * 1.15, 0, 0), 0.6, 0.55, 2.6, 8, PIEDRA.darkened(0.06))
		k.cono(puerta + Vector3(s * 1.15, 2.6, 0), 0.78, 1.25, 8, PIZARRA)
	k.caja(puerta + Vector3(0, 1.7, 0), Vector3(1.8, 0.6, 0.62), PIEDRA.darkened(0.08))
	k.caja(puerta + Vector3(0, 0.0, -0.05), Vector3(1.0, 1.65, 0.12), Color(0.30, 0.22, 0.15))   # el portón abierto, en sombra
	# Calle Mayor (de la puerta a la plaza) y la plaza con su fuente
	k.caja(o + Vector3(0, 0.08, R * 0.5), Vector3(1.2, 0.04, R), Color(0.80, 0.74, 0.62))
	k.cilindro(o + Vector3(0, 0.08, 0.6), 1.5, 1.5, 0.05, 10, Color(0.80, 0.74, 0.62))
	k.cilindro(o + Vector3(0, 0.1, 0.6), 0.42, 0.42, 0.3, 8, PIEDRA)
	k.cilindro(o + Vector3(0, 0.38, 0.6), 0.12, 0.08, 0.35, 6, PIEDRA)
	# El Árbol Milenario (al norte de la plaza): la silueta de la ciudad
	var arbol := o + Vector3(0.6, 0.0, -3.6)
	k.cilindro(arbol, 0.62, 0.36, 2.9, 8, Color(0.42, 0.30, 0.20))
	for raiz in 5:
		var ar := TAU * raiz / 5.0 + 0.3
		k.cilindro(arbol + Vector3(cos(ar), 0, sin(ar)) * 0.55, 0.24, 0.05, 0.6, 5, Color(0.40, 0.28, 0.18))
	var copa := Color(0.62, 0.70, 0.27)
	k.bola(arbol + Vector3(0, 3.6, 0), 2.0, copa, 0.62, 4, 9)
	k.bola(arbol + Vector3(-1.2, 3.25, 0.5), 1.25, copa.darkened(0.06), 0.7, 3, 7, 0.3)
	k.bola(arbol + Vector3(1.3, 3.35, -0.3), 1.3, copa.lightened(0.04), 0.7, 3, 7, 0.8)
	k.bola(arbol + Vector3(0.2, 4.55, -0.2), 1.25, Color(0.78, 0.70, 0.30), 0.7, 3, 7, 0.2)
	# El crematorio (piedra hueso, frío) al oeste
	var crem := o + Vector3(-4.4, 0, -0.6)
	k.caja(crem, Vector3(1.7, 1.25, 1.4), PIEDRA_HUESO)
	k.tejado(crem + Vector3(0, 1.25, 0), 1.7, 1.4, 0.55, Color(0.62, 0.64, 0.70))
	k.caja(crem + Vector3(0.45, 1.2, 0.0), Vector3(0.38, 1.3, 0.38), PIEDRA_HUESO.darkened(0.05))
	# La torre de vigía al este
	var torre := o + Vector3(4.6, 0, -2.2)
	k.cilindro(torre, 0.62, 0.5, 4.3, 8, PIEDRA.darkened(0.03))
	k.cilindro(torre + Vector3(0, 4.3, 0), 0.72, 0.72, 0.3, 8, PIEDRA)
	k.cono(torre + Vector3(0, 4.6, 0), 0.82, 1.6, 8, PIZARRA)
	# La Taberna del Cuervo Oxidado (más grande, tejado de óxido) junto a la calle
	var taberna := o + Vector3(-2.3, 0, 2.6)
	k.caja(taberna, Vector3(1.9, 1.35, 1.3), Color(0.86, 0.80, 0.66))
	k.tejado(taberna + Vector3(0, 1.35, 0), 1.9, 1.3, 0.8, Color(0.52, 0.26, 0.16))
	k.caja(taberna + Vector3(0.95, 0.65, 0.4), Vector3(0.06, 0.32, 0.36), Color(0.15, 0.13, 0.14))   # el letrero del cuervo
	# casas: tejados rojos, ocres y de pizarra, alineadas con las calles
	var rng := RandomNumberGenerator.new()
	rng.seed = 520330
	var ocupado := [Vector3(0, 0, 0.6), arbol - o, crem - o, torre - o, taberna - o]
	var radios := [1.8, 2.4, 1.3, 1.0, 1.4]
	var colores_pared := [Color(0.93, 0.89, 0.80), Color(0.88, 0.78, 0.60), Color(0.84, 0.82, 0.76), Color(0.90, 0.84, 0.70)]
	var colores_teja := [TEJA, TEJA.darkened(0.12), Color(0.62, 0.38, 0.22), PIZARRA, Color(0.76, 0.42, 0.24)]
	var casas := 0
	for intento in 160:
		if casas >= 30:
			break
		var p := Vector3(rng.randf_range(-R + 1.0, R - 1.0), 0, rng.randf_range(-R + 1.0, R - 1.0))
		if p.length() > R - 1.1 or absf(p.x) < 0.95 and p.z > 0.0:   # dentro y fuera de la Calle Mayor
			continue
		var libre := true
		for j in ocupado.size():
			var rr: float = radios[j] if j < radios.size() else 0.85
			if Vector2(p.x - ocupado[j].x, p.z - ocupado[j].z).length() < rr + 0.55:
				libre = false
				break
		if not libre:
			continue
		var ancho := rng.randf_range(0.85, 1.35)
		var fondo := rng.randf_range(0.75, 1.05)
		var alto := rng.randf_range(0.75, 1.25)
		var giro := 0.0 if rng.randf() < 0.5 else PI * 0.5
		k.caja(o + p, Vector3(ancho, alto, fondo), colores_pared[rng.randi() % colores_pared.size()], giro)
		k.tejado(o + p + Vector3(0, alto, 0), ancho, fondo, rng.randf_range(0.42, 0.62), colores_teja[rng.randi() % colores_teja.size()], giro)
		ocupado.append(p)
		casas += 1
	var nodo := Node3D.new()
	nodo.name = "Oakhaven"
	padre.add_child(nodo)
	k.instancia(nodo, "Maqueta", mat)
	# humo frío del crematorio (dos bolas que suben y se desvanecen)
	var humo_mat := mat_efecto(4, Color(0.80, 0.85, 0.92), Color.WHITE, 0.55)
	for h in 3:
		var bola := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.35
		sm.height = 0.7
		sm.radial_segments = 8
		sm.rings = 4
		bola.mesh = sm
		bola.material_override = humo_mat
		bola.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var base := crem + Vector3(0.45, 2.6, 0.0)
		bola.position = base
		nodo.add_child(bola)
		animados.append([bola, "humo", base, h / 3.0])
	return nodo


# ================================================================= Pastos Verdes

func _pastos(padre: Node3D, mat: Material) -> Node3D:
	var c: Vector2 = D.SITIOS["pastos"]["centro"]
	var o := suelo(c)
	var k := Kit.new()
	var verde := Color(0.42, 0.68, 0.30)
	# lomas
	k.bola(o + Vector3(1.6, -0.5, -2.6), 2.4, verde, 0.42, 3, 9)
	k.bola(o + Vector3(-2.4, -0.4, -1.8), 1.8, verde.lightened(0.05), 0.45, 3, 8, 0.4)
	k.bola(o + Vector3(3.2, -0.5, 1.6), 1.6, verde.darkened(0.04), 0.4, 3, 8, 0.2)
	# la peña de la cascada (al norte) y el río que baja hacia el sur
	var pena := o + Vector3(1.0, 0, -3.6)
	k.bola(pena + Vector3(0, 0.6, 0), 1.5, Color(0.58, 0.56, 0.52), 0.95, 3, 7)
	k.bola(pena + Vector3(-1.2, 0.3, 0.3), 1.0, Color(0.54, 0.52, 0.48), 0.9, 3, 6, 0.5)
	k.bola(pena + Vector3(1.2, 0.3, 0.2), 1.1, Color(0.60, 0.58, 0.53), 0.9, 3, 6, 0.9)
	# el puente de piedra que cruza el río (este-oeste)
	var puente := o + Vector3(1.0, 0, 0.6)
	k.caja(puente + Vector3(0, 0.45, 0), Vector3(2.4, 0.18, 0.75), PIEDRA)
	for s in [-1.0, 1.0]:
		k.caja(puente + Vector3(s * 0.95, 0, 0), Vector3(0.4, 0.5, 0.75), PIEDRA.darkened(0.06))
		k.caja(puente + Vector3(0, 0.63, s * 0.33), Vector3(2.4, 0.16, 0.08), PIEDRA.darkened(0.1))
	# la estela del camino y los faroles de Tilo (de pie, con su luz por emisión)
	k.caja(o + Vector3(-3.4, 0, 2.4), Vector3(0.3, 0.9, 0.18), Color(0.66, 0.64, 0.58))
	for f in [Vector3(-2.2, 0, 3.4), Vector3(-0.6, 0, 1.6), Vector3(2.6, 0, 0.0)]:
		k.cilindro(o + f, 0.05, 0.05, 1.1, 5, Color(0.22, 0.20, 0.18))
		k.caja(o + f + Vector3(0, 1.1, 0), Vector3(0.22, 0.24, 0.22), Color(1.0, 0.85, 0.45), 0.0, Color(1.0, 0.9, 0.55))
	# flores (lavanda y amarillas) a manchas
	var rng := RandomNumberGenerator.new()
	rng.seed = 660478
	for f in 26:
		var p := Vector3(rng.randf_range(-4.5, 4.5), 0, rng.randf_range(-1.5, 4.0))
		if absf(p.x - 1.0) < 0.6:
			continue
		var col := Color(0.66, 0.52, 0.86) if f % 2 == 0 else Color(0.98, 0.86, 0.36)
		k.bola(suelo(c + Vector2(p.x, p.z), 0.08), 0.12, col, 0.8, 2, 4)
	var nodo := Node3D.new()
	nodo.name = "PastosVerdes"
	padre.add_child(nodo)
	k.instancia(nodo, "Maqueta", mat)
	# el agua: el río (franjas que bajan) y la cascada (espuma que cae)
	var rio_mat := mat_efecto(0, Color(0.20, 0.56, 0.72), Color(0.86, 0.96, 1.0), 1.0, 0.8)
	var rio := plano(nodo, "Rio", o + Vector3(1.0, 0.1, 0.9), Vector2(0.9, 7.6), rio_mat)
	rio.rotation.y = 0.0
	var cas_mat := mat_efecto(1, Color(0.62, 0.84, 0.95), Color(0.98, 1.0, 1.0), 0.95, 1.0)
	var cascada := plano(nodo, "Cascada", pena + Vector3(0, 0.85, 1.25), Vector2(0.9, 1.7), cas_mat, false)
	cascada.rotation.x = -0.25
	return nodo


# ================================================================= Portal del Vacío

func _portal(padre: Node3D, mat: Material) -> Node3D:
	var c: Vector2 = D.SITIOS["portal"]["centro"]
	var o := suelo(c)
	var k := Kit.new()
	k.cilindro(o + Vector3(0, -0.1, 0), 1.6, 1.8, 0.3, 10, Color(0.70, 0.66, 0.58))   # la losa
	var radio := 1.3
	var seg := 11
	for i in seg:                                         # el arco de oro (media circunferencia de piezas)
		var a0 := PI * i / seg
		var a1 := PI * (i + 1) / seg
		var p0 := o + Vector3(cos(a0) * radio, 1.1 + sin(a0) * radio, 0)
		var p1 := o + Vector3(cos(a1) * radio, 1.1 + sin(a1) * radio, 0)
		var m := (p0 + p1) * 0.5
		var xf := Transform3D(Basis(Vector3(0, 0, 1), (a0 + a1) * 0.5 + PI * 0.5), m)
		k.caja_t(xf, Vector3(p0.distance_to(p1) + 0.08, 0.28, 0.3), ORO)
	for s in [-1.0, 1.0]:
		k.caja(o + Vector3(s * radio, 0.18, 0), Vector3(0.32, 0.95, 0.32), ORO.darkened(0.08))
	var nodo := Node3D.new()
	nodo.name = "PortalDelVacio"
	padre.add_child(nodo)
	k.instancia(nodo, "Maqueta", mat)
	var rem := plano(nodo, "Remolino", o + Vector3(0, 1.15, 0), Vector2(2.5, 2.5),
		mat_efecto(2, Color(0.38, 0.16, 0.62), Color(0.86, 0.62, 1.0), 0.92, 1.0), false)
	rem.name = "Remolino"
	return nodo


# ================================================================= campamento (PROPUESTA)

func _campamento(padre: Node3D, mat: Material, perfil: String) -> Node3D:
	var c: Vector2 = D.SITIOS["campamento"]["centro"]
	var o := suelo(c)
	var k := Kit.new()
	# dos tiendas (lona clara y lona roja)
	for t in [[Vector3(-1.6, 0, 1.2), Color(0.92, 0.86, 0.70)], [Vector3(1.3, 0, 1.7), Color(0.74, 0.34, 0.24)]]:
		var p: Vector3 = o + t[0]
		k.cono(p, 0.9, 1.6, 6, t[1])                   # tiendas de pico: se leen desde arriba
		k.cilindro(p + Vector3(0, 1.5, 0), 0.04, 0.03, 0.35, 4, MADERA)
		k.caja(p + Vector3(0, 0, 0.62), Vector3(0.32, 0.55, 0.06), Color(0.25, 0.18, 0.12), 0.0)   # la puerta en sombra
	# la hoguera: piedras en corro y troncos
	for i in 7:
		var a := TAU * i / 7.0
		k.bola(o + Vector3(cos(a) * 0.48, 0.06, sin(a) * 0.48), 0.13, Color(0.55, 0.53, 0.50), 0.7, 2, 5)
	k.caja(o + Vector3(0, 0.02, 0), Vector3(0.7, 0.12, 0.14), MADERA, 0.6)
	k.caja(o + Vector3(0, 0.02, 0), Vector3(0.7, 0.12, 0.14), MADERA.darkened(0.1), -0.7)
	# un tronco para sentarse y un hatillo
	k.caja(o + Vector3(-0.2, 0, -1.2), Vector3(1.3, 0.28, 0.32), MADERA, 0.15)
	k.bola(o + Vector3(1.4, 0.15, -0.4), 0.22, Color(0.62, 0.52, 0.36), 0.8, 2, 5)
	# el mojón de viaje (el punto donde se elige destino): piedra con una runa que brilla
	var mojon := o + Vector3(2.3, 0, -1.4)
	k.caja(mojon, Vector3(0.42, 1.0, 0.3), Color(0.64, 0.62, 0.58))
	k.caja(mojon + Vector3(0, 0.55, 0.16), Vector3(0.22, 0.26, 0.02), Color(1.0, 0.86, 0.45), 0.0, Color(1.0, 0.9, 0.5))
	var nodo := Node3D.new()
	nodo.name = "Campamento"
	padre.add_child(nodo)
	k.instancia(nodo, "Maqueta", mat)
	var llama_mat := mat_efecto(3, Color(0.95, 0.25, 0.08), Color(1.0, 0.92, 0.45), 1.0)
	for g in [0.0, PI * 0.5]:
		var llama := plano(nodo, "Llama", o + Vector3(0, 0.4, 0), Vector2(0.55, 0.7), llama_mat, false, g)
		animados.append([llama, "llama", llama.position, g])
	if perfil == "alto":                                   # la luz de la hoguera, solo en el perfil alto
		var luz := OmniLight3D.new()
		luz.name = "LuzHoguera"
		luz.light_color = Color(1.0, 0.62, 0.3)
		luz.light_energy = 1.4
		luz.omni_range = 4.5
		luz.position = o + Vector3(0, 0.7, 0)
		nodo.add_child(luz)
		animados.append([luz, "luz", luz.position, 0.0])
	return nodo


# ================================================================= Cueva de los Helechos (PROPUESTA)

func _cueva(padre: Node3D, mat: Material) -> Node3D:
	var c: Vector2 = D.SITIOS["cueva"]["centro"]
	var e: Vector2 = D.SITIOS["cueva"]["entrada"]
	var o := suelo(c, -0.3)
	var hacia := Vector3(e.x - c.x, 0, e.y - c.y).normalized()       # hacia la entrada (la boca mira hacia allí)
	var lado := Vector3(-hacia.z, 0, hacia.x)
	var k := Kit.new()
	var roca := Color(0.52, 0.48, 0.43)
	k.bola(o + Vector3(0, 1.4, 0) - hacia * 1.0, 3.0, roca, 0.85, 4, 9)
	k.bola(o + lado * 2.2 + Vector3(0, 0.9, 0), 2.0, roca.lightened(0.05), 0.9, 3, 7, 0.4)
	k.bola(o - lado * 2.3 + Vector3(0, 0.8, 0) - hacia * 0.4, 2.1, roca.darkened(0.05), 0.85, 3, 7, 0.9)
	k.bola(o + Vector3(0, 3.6, 0) - hacia * 1.6, 1.6, roca.lightened(0.1), 0.8, 3, 6, 0.2)
	# la boca: un hueco oscuro en la cara que mira a la entrada, con dintel
	var boca := o + hacia * 1.75 + Vector3(0, 0.3, 0)
	var giro := atan2(hacia.x, hacia.z)
	k.caja(boca, Vector3(1.5, 1.6, 0.5), Color(0.06, 0.05, 0.06), giro, Color(0.12, 0.1, 0.1))
	k.caja(boca + Vector3(0, 1.55, 0) + hacia * 0.1, Vector3(2.1, 0.4, 0.6), roca.darkened(0.1), giro)
	# helechos a los lados de la boca
	for s in [-1.0, 1.0]:
		for f in 3:
			var p: Vector3 = boca + lado * s * (1.1 + f * 0.35) + hacia * (0.6 - f * 0.2)
			k.cono(Vector3(p.x, T.altura(p.x, p.z), p.z), 0.32, 0.55, 5, Color(0.30, 0.58, 0.26).lightened(f * 0.05))
	var nodo := Node3D.new()
	nodo.name = "Cueva"
	padre.add_child(nodo)
	k.instancia(nodo, "Maqueta", mat)
	return nodo


# ================================================================= Corro de los Mirlos (secreto, PROPUESTA)

func _secreto(padre: Node3D, mat: Material) -> Node3D:
	var c: Vector2 = D.SITIOS["secreto"]["centro"]
	var o := suelo(c)
	var k := Kit.new()
	var musgo := Color(0.50, 0.58, 0.44)
	for i in 7:
		var a := TAU * i / 7.0 + 0.2
		var p := o + Vector3(cos(a), 0, sin(a)) * 1.7
		k.caja(Vector3(p.x, T.altura(p.x, p.z) - 0.05, p.z), Vector3(0.32, 0.55 + 0.12 * (i % 3), 0.26), musgo, a)
	k.caja(o, Vector3(0.38, 0.9, 0.24), Color(0.62, 0.62, 0.56), 0.4)          # el mojón viejo del centro
	k.bola(o + Vector3(0.45, 0.1, 0.25), 0.16, Color(0.58, 0.44, 0.30), 0.8, 2, 5)   # la ofrenda (un hatillo)
	k.cilindro(o + Vector3(0, -0.04, 0), 1.2, 1.2, 0.06, 9, Color(0.40, 0.62, 0.30))
	var nodo := Node3D.new()
	nodo.name = "CorroDeLosMirlos"
	padre.add_child(nodo)
	k.instancia(nodo, "Maqueta", mat)
	# losas sueltas de la senda casi borrada
	var losas := Kit.new()
	var lin: Array = T.suavizar(D.SENDA_SECRETA, 1.3)
	for p in lin:
		losas.cilindro(suelo(p, -0.02), 0.28, 0.28, 0.07, 6, Color(0.70, 0.66, 0.56))
	losas.instancia(nodo, "Losas", mat, false)
	return nodo


# ================================================================= poste hacia el Gran Bosque

func _poste(padre: Node3D, mat: Material) -> Node3D:
	var c: Vector2 = D.SITIOS["gran_bosque"]["centro"] + Vector2(-1.8, -1.4)
	var o := suelo(c)
	var k := Kit.new()
	k.cilindro(o, 0.08, 0.07, 1.6, 5, MADERA)
	k.caja(o + Vector3(0.25, 1.25, 0), Vector3(0.9, 0.25, 0.06), MADERA.lightened(0.1), -0.7)
	var nodo := Node3D.new()
	nodo.name = "PosteGranBosque"
	padre.add_child(nodo)
	k.instancia(nodo, "Maqueta", mat)
	return nodo


# Cada fotograma: la llama tiembla, el humo sube y se deshace, la luz de la hoguera parpadea.
func animar(t: float) -> void:
	for a in animados:
		var n: Node3D = a[0]
		if not is_instance_valid(n):
			continue
		match a[1]:
			"humo":
				var f := fmod(t * 0.22 + a[3], 1.0)
				n.position = a[2] + Vector3(sin(t * 0.7 + a[3] * 6.0) * 0.15, f * 2.2, f * 0.4)
				n.scale = Vector3.ONE * lerpf(0.6, 1.6, f)
				(n as MeshInstance3D).transparency = f
			"llama":
				n.scale = Vector3(1.0 + sin(t * 9.0 + a[3]) * 0.08, 1.0 + sin(t * 11.0 + a[3] * 2.0) * 0.12, 1.0)
			"luz":
				(n as OmniLight3D).light_energy = 1.3 + sin(t * 10.0) * 0.15 + sin(t * 23.0) * 0.08
