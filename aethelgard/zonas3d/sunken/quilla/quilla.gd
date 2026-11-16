extends Node3D
# Sunken City 3D · «La Quilla, de la costilla 44 a la rampa» (V12, 16/11). EXPERIMENTAL y APAGADA: solo con el
# interruptor de sesión «sunken_quilla_v12» (banco de pruebas: «Sunken: Quilla horneada (solo en el banco)», o el
# argumento del mismo nombre en las pruebas) y solo en Auditoría o en el editor (banco_pruebas.permitido()). Apagada, la
# Sunken City de siempre no cambia: casco.gd ni siquiera carga este guion. Documento: docs/v12/SUNKEN_QUILLA.md.
#
# Qué hace (casco.gd la monta EN LUGAR del GLB de siempre):
#   - modelos/quilla.glb (fuente/crear_quilla.py): el sector entero con la Quilla rehecha y la luz HORNEADA. Lo grande
#     («fijo») con mapa de luz; lo pequeño («piezas») y lo alto de cada costilla («corona_<dm>») con la luz en los
#     vértices. Los sombreados son LOS DE LA MUESTRA DE LA CALLE (zonas3d/muestra_calle/calle_*.gdshader), cargados por
#     su ruta y nunca copiados: no hay programas nuevos que compilar (carga.gd ya los precalienta en Auditoría).
#   - Sin transparencias nuevas: la corona de cada costilla se OCULTA mientras queda entre la cámara y Kael (antes, la
#     costilla entera se volvía medio transparente). La popa, el palo mayor y la bandera llevan su luz en los vértices
#     con un material estándar sin luz (el programa de los cristales de siempre), así que siguen volviéndose medio
#     transparentes como antes cuando tapan a Kael (prototipos/vista3d.gd).
#   - Kael: las sondas (luz/quilla_luz.json: cuánto sol y cielo llega a 1 m del suelo) apagan el sol cuando pisa la
#     sombra de las casas o de una costilla, y su sombra de contacto va DENTRO de los sombreados del suelo (como en la
#     muestra). Lya y Garon comparten ese sol (es uno) y no llevan sombra de contacto [D].
#   - La cuadrilla de la Quilla (obreros.gd, PROPUESTA): trabaja fuera de lo andable y se puede hablar con ella.
# Sin el mapa de luz (pasadas de composición, arquitectura y materiales del guion de Blender), los mismos objetos con
# luz en tiempo real (StandardMaterial3D): solo para las capturas de cada pasada.

const RAIZ := "res://zonas3d/sunken/quilla/"
const MODELO := RAIZ + "modelos/quilla.glb"
const LUZ_JSON := RAIZ + "luz/quilla_luz.json"
const META := "sunken_quilla_v12"
const SH_ESTATICO := "res://zonas3d/muestra_calle/calle_estatico.gdshader"
const SH_VERTICE := "res://zonas3d/muestra_calle/calle_vertice.gdshader"
const SH_BRILLO := "res://zonas3d/muestra_calle/calle_brillo.gdshader"
const MAPA_LUZ := {"bajo": 1024, "medio": 2048, "alto": 2048}
const FANTASMAS := ["edif_popa", "edif_palo", "bandera"]
const ALTO_CORONA := 3.0                  # (crear_quilla.py: lo que queda por encima de esto es la corona)
const PALO_Z := 23.7                      # (casco.gd: la bandera se aparta con esta z, la del palo mayor + 0,5)

var casco: Node3D
var nombre_perfil := "alto"
var luz: Dictionary = {}
var horneado := false
var tex_luz_usada := ""
var coronas: Array = []                   # [{"z", "nodo", "oculta"}]
var bandera_mallas: Array = []
var _bandera_apartada := false
var materiales_sombra: Array = []         # los ShaderMaterial que dibujan la sombra de Kael
var materiales: Dictionary = {}           # clave → Material (para las pruebas)
var obreros = null                        # obreros.gd
var _sol_base := -1.0
var _amb_base := -1.0
var _sol_k := 1.0
var _cielo_k := 1.0
var _sombra_lista := false
var triangulos := 0
var mallas := 0


# ¿Encendida? Interruptor de sesión (o argumento) Y Auditoría/editor Y los archivos (las APK de prueba 3D y la
# experimental no llevan ni esta carpeta ni los sombreados de la muestra: export_presets.cfg).
static func activado() -> bool:
	if not (bool(Engine.get_meta(META, false)) or META in OS.get_cmdline_user_args()):
		return false
	if not load("res://banco_pruebas.gd").permitido():
		return false
	for r in [MODELO, SH_ESTATICO, SH_VERTICE, SH_BRILLO]:
		if not ResourceLoader.exists(r):
			return false
	return true


static func montar(casco_: Node3D) -> Node3D:
	var q = load("res://zonas3d/sunken/quilla/quilla.gd").new()
	q.name = "Quilla"
	q.casco = casco_
	q.nombre_perfil = casco_.nombre_perfil
	casco_.add_child(q)
	q._montar()
	return q


func resumen() -> Dictionary:
	return {"kit": MODELO, "fase": luz.get("fase", "?"), "horneado": horneado, "mapa_luz": tex_luz_usada,
		"triangulos": triangulos, "mallas": mallas, "coronas": coronas.size(),
		"obreros": obreros.lista.size() if obreros != null else 0}


func _leer_luz() -> Dictionary:
	if FileAccess.file_exists(LUZ_JSON):
		var d = JSON.parse_string(FileAccess.get_file_as_string(LUZ_JSON))
		if d is Dictionary:
			return d
	return {}


func _montar() -> void:
	luz = _leer_luz()
	var res := int(MAPA_LUZ.get(nombre_perfil, 2048))
	var ruta_luz := RAIZ + "luz/quilla_luz_%d.png" % res
	horneado = bool(luz.get("horneado", false)) and ResourceLoader.exists(ruta_luz)
	var tex_luz: Texture2D = null
	if horneado:
		tex_luz = load(ruta_luz)
		tex_luz_usada = ruta_luz
	var raiz: Node3D = (load(MODELO) as PackedScene).instantiate()
	add_child(raiz)
	for n in raiz.find_children("ancla_*", "Node3D", true, false):
		casco.anclas[String(n.name).trim_prefix("ancla_")] = casco.to_local((n as Node3D).global_position)
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var nombre := String(m.name)
		var fantasma := nombre in FANTASMAS
		for s in m.mesh.get_surface_count():
			var orig := m.mesh.surface_get_material(s)
			var mat_n := orig.resource_name if orig != null else "liso"
			m.set_surface_override_material(s, _material(mat_n, tex_luz if nombre == "fijo" else null, fantasma))
		if fantasma:                                       # (vista3d cambia material_override para volverlo transparente)
			m.material_override = _material("", null, true)
			for s in m.mesh.get_surface_count():
				m.set_surface_override_material(s, null)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_contar(m.mesh)
		mallas += 1
		var cuerpo := StaticBody3D.new()
		cuerpo.name = "Choque_" + nombre
		add_child(cuerpo)
		casco._cajas(m, cuerpo)
		if nombre in ["edif_popa", "edif_palo"]:
			m.reparent(cuerpo, true)
			m.add_to_group("ocluye")                       # (medio transparente si tapa a Kael, como antes)
		elif nombre == "bandera":
			var piv: Node3D = casco._pivote_bandera(cuerpo, m)
			m.reparent(piv, true)
			bandera_mallas.append(m)
		elif nombre.begins_with("corona_"):
			coronas.append({"z": float(nombre.trim_prefix("corona_")) / 10.0, "nodo": m, "oculta": false, "halos": []})
		if cuerpo.get_child_count() == 0:
			cuerpo.queue_free()
	_crear_sombra_kael()
	_sin_compensar()
	var Obreros = load(RAIZ + "obreros.gd")
	if Obreros != null and casco.region != null:
		obreros = Obreros.new()
		obreros.name = "Obreros"
		add_child(obreros)
		obreros.preparar(self, casco.anclas, casco.mat)


func _contar(m: Mesh) -> void:
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx = arr[Mesh.ARRAY_INDEX]
		triangulos += (idx.size() if idx != null and idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3


# El material de cada superficie, compartido entre objetos (una superficie por material y objeto).
func _material(nombre: String, tex_luz: Texture2D, fantasma: bool) -> Material:
	var clave := "%s|%s|%s" % [nombre, "luz" if tex_luz != null else "v", "f" if fantasma else ""]
	if materiales.has(clave):
		return materiales[clave]
	var m: Material
	var tex: Texture2D = null
	var ruta_tex := RAIZ + "texturas/%s.png" % nombre
	if bool(luz.get("texturas", false)) and ResourceLoader.exists(ruta_tex):
		tex = load(ruta_tex)
	if fantasma:
		var sm := StandardMaterial3D.new()                 # el de los cristales de siempre: sin luz, color del vértice
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if horneado else BaseMaterial3D.SHADING_MODE_PER_PIXEL
		sm.vertex_color_use_as_albedo = true
		if not horneado:
			sm.roughness = 1.0
		m = sm
	elif not horneado:                                     # pasadas sin hornear: luz en tiempo real
		var sm := StandardMaterial3D.new()
		sm.vertex_color_use_as_albedo = true
		sm.albedo_texture = tex
		sm.roughness = 1.0
		sm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		if nombre == "brillo":
			sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sm.albedo_texture = null
		m = sm
	elif nombre == "brillo":
		var b := ShaderMaterial.new()
		b.shader = load(SH_BRILLO)
		b.set_shader_parameter("energia", 1.45 if nombre_perfil == "alto" else 1.25)
		m = b
	else:
		var e := float(luz.get("escala", 1.0))
		var s := ShaderMaterial.new()
		s.shader = load(SH_ESTATICO if tex_luz != null else SH_VERTICE)
		s.set_shader_parameter("textura", tex)
		s.set_shader_parameter("luz_escala", e)
		if tex_luz != null:
			s.set_shader_parameter("luz", tex_luz)
		materiales_sombra.append(s)
		m = s
	materiales[clave] = m
	return m


# ================================================================= las coronas y la bandera (casco.apartar)

func apartar(z_kael: float, z_camara: float, region_: Node) -> void:
	for c in coronas:
		var quiere: bool = c["z"] > z_kael + 0.35 and c["z"] < z_camara + 1.0
		if quiere == c["oculta"]:
			continue
		c["oculta"] = quiere
		if is_instance_valid(c["nodo"]):
			(c["nodo"] as Node3D).visible = not quiere
		for h in c["halos"]:
			if is_instance_valid(h):
				(h as Node3D).visible = not quiere
	var b: bool = PALO_Z > z_kael + 0.35 and PALO_Z < z_camara + 1.0
	if b != _bandera_apartada:
		_bandera_apartada = b
		for mi in bandera_mallas:
			if is_instance_valid(mi):
				region_._transparente(mi, b)


# El halo de un farol (casco._faroles): el de las costillas 44 y 32 cuelga de su corona y se oculta con ella (si no, al
# ocultar la corona quedaba flotando sin su farol).
func halo_farol(nombre: String, halo: Node3D) -> void:
	var dm := nombre.trim_prefix("farol_")
	if not dm.is_valid_int():
		return
	for c in coronas:
		if absf(float(c["z"]) - float(dm)) < 0.05:
			c["halos"].append(halo)
			halo.visible = not c["oculta"]


# ================================================================= Kael: sondas y sombra de contacto

# La luz horneada es la misma en los tres perfiles: el brillo extra del perfil sin sombras (vista3d.gd,
# _compensar_sin_sombras: «brillo_sin_sombras» de la escena, 1,15 en Sunken) haría el bajo más claro que el medio.
# Se deshace aquí, solo con la Quilla horneada.
func _sin_compensar() -> void:
	if not horneado or Engine.has_meta("luz_sin_compensar") or bool(casco.perfil.get("sombras", false)):
		return
	var region: Node = casco.region
	var we = region.get_node_or_null("Ambiente") if region != null else null
	var k = region.get("brillo_sin_sombras") if region != null else null
	if not we is WorldEnvironment or k == null or float(k) <= 0.0:
		return
	var env: Environment = (we as WorldEnvironment).environment
	env.adjustment_brightness /= float(k)
	env.adjustment_contrast /= 1.0 + (float(k) - 1.0) * 0.3


# El sol de Kael (y de Lya y Garon, que le siguen): una copia del sol de la escena que solo les alumbra a ellos (capa
# 10). Las sondas la apagan cuando Kael pisa la sombra horneada; el sol de siempre sigue igual para el agua, los vecinos
# y la cuadrilla (antes, al bajar el único sol, la laguna se oscurecía con Kael). La sombra en tiempo real del sol de la
# escena ya no hace falta (lo horneado no la recibe ni la proyecta): la lleva solo el de Kael.
const CAPA_KAEL := 1 << 9
var sol_kael: DirectionalLight3D
var _capas_hechas := 0


func _preparar_sol_kael(escena: Node) -> void:
	var sol: DirectionalLight3D = escena.get("sol")
	if sol == null:
		return
	sol_kael = sol.duplicate() as DirectionalLight3D
	sol_kael.name = "SolKael"
	sol_kael.light_cull_mask = CAPA_KAEL
	escena.add_child(sol_kael)
	sol.light_cull_mask = sol.light_cull_mask & ~CAPA_KAEL
	sol.shadow_enabled = false
	_sol_base = sol_kael.light_energy


func _capas_grupo(escena: Node) -> void:
	var n := 0
	for raiz in [escena.get("kael"), escena.get("grupo")]:
		if raiz is Node:
			for g in (raiz as Node).find_children("*", "GeometryInstance3D", true, false):
				(g as GeometryInstance3D).layers = CAPA_KAEL
				n += 1
	_capas_hechas = n


func _crear_sombra_kael() -> void:
	var hs: Array = luz.get("hacia_sol", [-0.786, 0.530, 0.318])
	var lejos := -Vector2(hs[0], hs[2]).normalized()
	var elev := asin(clampf(float(hs[1]), -1.0, 1.0))
	var largo := clampf(1.45 / tan(maxf(elev, 0.2)), 1.2, 3.4)
	for m in materiales_sombra:
		m.set_shader_parameter("sombra_dir", lejos)
		m.set_shader_parameter("sombra_largo", largo)


# Las sondas: cuánto sol y cuánto cielo hay a 1 m sobre lo que se pisa en p (interpolado).
func sonda(p: Vector3) -> Vector2:
	var s: Dictionary = luz.get("sondas", {})
	if s.is_empty():
		return Vector2.ONE
	var o: Array = s["origen"]
	var paso: float = s["paso"]
	var nx: int = s["nx"]
	var nz: int = s["nz"]
	var fx := clampf((p.x - float(o[0])) / paso, 0.0, nx - 1.001)
	var fz := clampf((p.z - float(o[1])) / paso, 0.0, nz - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var r := Vector2.ZERO
	for par in [["sol", 0], ["cielo", 1]]:
		var a: Array = s[par[0]]
		var v00: float = a[iz * nx + ix]
		var v10: float = a[iz * nx + ix + 1]
		var v01: float = a[(iz + 1) * nx + ix]
		var v11: float = a[(iz + 1) * nx + ix + 1]
		r[par[1]] = lerpf(lerpf(v00, v10, tx), lerpf(v01, v11, tx), tz)
	return r


# Cada fotograma (sunken_3d.gd _process): la luz y la sombra de Kael y la cuadrilla.
func cada_fotograma(delta: float, escena: Node) -> void:
	var kael: Node3D = escena.get("kael")
	if kael == null:
		return
	if horneado:
		if sol_kael == null:
			_preparar_sol_kael(escena)
		if Engine.get_process_frames() % 30 == 0:                # (el grupo puede crear mallas después: las armas)
			_capas_grupo(escena)
		var v := sonda(kael.global_position)
		var k := 1.0 - exp(-6.0 * delta) if _sombra_lista else 1.0
		if not _sombra_lista:
			_capas_grupo(escena)
		_sombra_lista = true
		_sol_k = lerpf(_sol_k, v.x, k)
		_cielo_k = lerpf(_cielo_k, v.y, k)
		if sol_kael != null:
			sol_kael.light_energy = _sol_base * (0.12 + 0.88 * _sol_k)
		var s := clampf(_sol_k, 0.0, 1.0)
		var p := kael.global_position
		for m in materiales_sombra:
			m.set_shader_parameter("kael_pos", p)
			m.set_shader_parameter("sombra_fuerza", 0.62 * s)
			m.set_shader_parameter("contacto_fuerza", lerpf(0.70, 0.78, s))
			m.set_shader_parameter("sol_kael", s)
	if obreros != null:
		obreros.avanzar(delta, escena)
	if horneado:
		_luz_npcs(delta, escena)


# Ulla, Brea y la cuadrilla: el sol de la escena ya no hace sombra (_preparar_sol_kael) y lo horneado no la proyecta
# sobre ellos, así que bajo la lona y los porches salían a pleno sol. La sonda de donde está cada uno oscurece su color
# lo mismo que pierde Kael en la sombra (su sol al 12 % con el mismo ambiente: ≈ 0,6 de la luz). Cada uno lleva una
# copia opaca del material de su persona (el mismo programa: nada nuevo que compilar ni transparencias).
const SOMBRA_NPC := 0.6
var luz_npcs := {}                        # chibi → {"mat": StandardMaterial3D, "base": Color, "k": float}


func _luz_npcs(delta: float, escena: Node) -> void:
	var chibis: Array = []
	var vec = escena.get("vecinos")
	if vec is Dictionary:
		for id in vec:
			chibis.append(vec[id].get("chibi"))
	if obreros != null:
		for o in obreros.lista:
			chibis.append(o["chibi"])
	var a := 1.0 - exp(-6.0 * delta)
	for c in chibis:
		if c == null or not is_instance_valid(c) or c.malla == null:
			continue
		var d = luz_npcs.get(c)
		if d == null:
			var orig := c.malla.material_override as StandardMaterial3D
			if orig == null:
				continue
			d = {"mat": orig.duplicate(), "base": orig.albedo_color, "k": -1.0}
			c.malla.material_override = d["mat"]
			luz_npcs[c] = d
		var objetivo := lerpf(SOMBRA_NPC, 1.0, clampf(sonda((c as Node3D).global_position).x, 0.0, 1.0))
		var k: float = objetivo if d["k"] < 0.0 else lerpf(d["k"], objetivo, a)
		if absf(k - float(d["k"])) < 0.002:
			continue
		d["k"] = k
		var b: Color = d["base"]
		(d["mat"] as StandardMaterial3D).albedo_color = Color(b.r * k, b.g * k, b.b * k, b.a)


# ================================================================= la cuadrilla (para sunken_3d.gd)

func piezas() -> Array:
	return obreros.piezas() if obreros != null else []


func es_obrero(id: String) -> bool:
	return obreros != null and obreros.es_obrero(id)


func hablar(id: String, desde: Vector3) -> String:
	return obreros.hablar(id, desde) if obreros != null else ""
