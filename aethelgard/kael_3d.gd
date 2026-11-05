extends "res://maga_3d.gd"
# Kael 3D (modelo "Azure Starblade" de Meshy con esqueleto Mixamo).
#
# Meshy no dejó renombrar las animaciones, así que aquí se les da su nombre:
#   Idle         = _01a19b86_...   reposo con la mano en el hombro (sable al hombro)
#   Walking      = _01a19ba8_...   andar pesado con el sable al hombro (se le quita el avance)
#   Andar_normal = Walking
#   Running      = Running
#   Hit          = Face_Punch_Reaction
#   Death        = dying_backwards
#   Casting      = mage_soell_cast_7
# El FBX no trae ataque: el salto con caída cortante se hace por código (gestos "k_" de gestos_3d.gd).
# El sable es "Frostfang" (Meshy), reducido a una versión ligera: sable.obj + sus 4 texturas.
# Si no están esos archivos, se usa un sable provisional hecho por código.

const ALIAS := {
	"Idle": ["_01a19b86", "idle"],
	"Walking": ["_01a19ba8"],
	"Andar_normal": ["walking", "walk"],
	"Running": ["running", "run"],
	"Hit": ["face_punch", "hit", "impact"],
	"Death": ["dying", "death"],
	"Casting": ["cast", "spell", "soell"],
}
# Tiempos del ataque saltando (el combate los usa para mover el salto en pantalla).
const T_AGACHAR := 0.2
const T_SALTO := 0.3
const T_CORTE := 0.14
const TAM_SABLE := 0.82                      # tamaño del sable provisional respecto al modelo
const RUTA_SABLE := "res://sable.obj"        # sable de Meshy: empuñadura en el origen, hoja hacia +Y, largo 1
const LARGO_SABLE := 1.45                     # largo total del sable de Meshy (en metros, Kael mide 1,7)
const PUNTA_SABLE := 0.9                      # dónde está la punta (en el modelo de largo 1)
const VOLTEAR_FILO := false                   # true si el filo del sable mira hacia el lado contrario
const DIR_REPOSO := Vector3(-0.85, 0.5, 0.12)  # hoja en el reposo: atrás y arriba, sobre el hombro
# Mientras estos gestos están activos el sable apunta a donde se indica: [hoja, filo]
# (direcciones del personaje: adelante, arriba, derecha).
const SABLE_GESTOS := {
	"k_alto": [Vector3(-0.55, 0.8, 0.05), Vector3(0.82, 0.57, 0.0)],
	"k_corte": [Vector3(0.75, -0.65, 0.0), Vector3(-0.65, -0.75, 0.0)],
	"k_victoria": [Vector3(0.1, 1.0, 0.1), Vector3(1.0, 0.0, 0.0)],
	"k_magia": [Vector3(0.15, 1.0, 0.0), Vector3(1.0, -0.1, 0.0)],
}

var sable: Node3D
var con_arma := true          # el arma solo se lleva en combate (para el muñeco del mapa, false)
var _hoja_local := Vector3.UP     # dirección de la hoja respecto a la mano (se calcula en el reposo)
var _filo_local := Vector3.RIGHT
var _e_sable := 1.0
var _punta := 1.3


func _init() -> void:
	usa_vara = false                            # Kael lleva su sable (más abajo), no el cetro
	heroe = "Kael"
	ruta_modelo = "res://kael.fbx"
	rutas_extra = ["res://Meshy_AI_Azure_Starblade_biped_Meshy_Merged_Animations.fbx", "res://kael.glb"]


func _ready() -> void:
	super._ready()
	if skel != null and con_arma:
		_crear_sable()


func _mapear_animaciones() -> void:
	var lista := anim.get_animation_list()
	for clave in ALIAS:
		for n in lista:
			if n in nombres.values() or String(n) == "RESET":
				continue
			var b := String(n).to_lower()
			var vale := false
			for pista in ALIAS[clave]:
				if pista in b:
					vale = true
			if vale:
				nombres[clave] = n
				break
	for k in ["Idle", "Walking", "Andar_normal", "Running"]:
		if nombres.has(k):
			anim.get_animation(nombres[k]).loop_mode = Animation.LOOP_LINEAR
	for k in ["Walking", "Andar_normal", "Running", "Casting", "Hit"]:
		if nombres.has(k):
			_quitar_avance(nombres[k])


# Deja la animación en el sitio: la cadera no avanza ni se aleja (solo sube y baja).
func _quitar_avance(nombre_real: String) -> void:
	var a := anim.get_animation(nombre_real)
	for t in a.get_track_count():
		if a.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not String(a.track_get_path(t)).ends_with("Hips"):
			continue
		var n := a.track_get_key_count(t)
		if n == 0:
			continue
		var p0: Vector3 = a.track_get_key_value(t, 0)
		for k in n:
			var p: Vector3 = a.track_get_key_value(t, k)
			a.track_set_key_value(t, k, Vector3(p0.x, p.y, p0.z))


# ---------------------------------------------------------------- sable provisional

func _crear_sable() -> void:
	if gestos.idx.get("mano_d", -1) < 0 or gestos.idx.get("dedo_d", -1) < 0:
		return
	sable = Node3D.new()
	sable.name = "Sable"
	sable.visible = false
	skel.add_child(sable)
	_e_sable = gestos.escala * TAM_SABLE
	var arma := _arma_equipada()
	if ResourceLoader.exists(arma["modelo"]):
		_cargar_sable_meshy(sable, gestos.escala * arma["largo"], arma)
		_punta = arma["punta"] * gestos.escala * arma["largo"]
	else:
		_piezas_sable(sable, _e_sable)
		_punta = 1.3 * _e_sable
	# se calibra cuando el reposo ya ha llevado la mano al hombro
	await get_tree().process_frame
	await get_tree().process_frame
	_calibrar()
	gestos.al_terminar = _actualizar_sable
	sable.visible = true


# Toma el reposo como referencia: cómo va el sable respecto a la mano y la postura
# del brazo con el sable al hombro (para mantenerla al correr y al andar).
func _calibrar() -> void:
	var g = gestos
	var b := skel.get_bone_global_pose(g.idx["mano_d"]).basis.orthonormalized()
	var hoja: Vector3 = g.dir(DIR_REPOSO)
	var filo: Vector3 = (g.arriba - hoja * g.arriba.dot(hoja)).normalized()
	_hoja_local = b.inverse() * hoja
	_filo_local = b.inverse() * filo
	var brazo := {}
	for par in [["brazo_d", "antebrazo_d"], ["antebrazo_d", "mano_d"], ["mano_d", "dedo_d"]]:
		var a := skel.get_bone_global_pose(g.idx[par[0]]).origin
		var c := skel.get_bone_global_pose(g.idx[par[1]]).origin
		brazo[par[0]] = [g.comp((c - a).normalized()), 180]
	g.registrar("k_hombro", brazo)


# Coloca el sable en la palma de la mano derecha cada fotograma (ya con todos los gestos puestos).
func _actualizar_sable(sk: Skeleton3D) -> void:
	if sable == null:
		return
	var g = gestos
	var mano := sk.get_bone_global_pose(g.idx["mano_d"])
	var palma := (mano.origin + sk.get_bone_global_pose(g.idx["dedo_d"]).origin) * 0.5
	var b := mano.basis.orthonormalized()
	var hoja: Vector3 = (b * _hoja_local).normalized()
	var filo: Vector3 = (b * _filo_local).normalized()
	for nombre in SABLE_GESTOS:
		var w: float = g.peso.get(nombre, 0.0)
		if w > 0.001:
			hoja = hoja.slerp(g.dir(SABLE_GESTOS[nombre][0]), w)
			filo = filo.slerp(g.dir(SABLE_GESTOS[nombre][1]), w)
	filo = (filo - hoja * filo.dot(hoja)).normalized()
	sable.global_transform = sk.global_transform * Transform3D(Basis(filo, hoja, filo.cross(hoja)), palma)


# Arma que lleva Kael según el inventario (inventario.gd); si no hay inventario, el sable Frostfang.
func _arma_equipada() -> Dictionary:
	var arma := {"modelo": RUTA_SABLE, "color": "res://sable_color.jpg", "normal": "res://sable_normal.png",
		"metal": "res://sable_metal.png", "rugosidad": "res://sable_rugosidad.png", "brillo": "",
		"largo": LARGO_SABLE, "punta": PUNTA_SABLE}
	if ResourceLoader.exists("res://inventario.gd"):
		var elegida: Dictionary = load("res://inventario.gd").arma_de("Kael")
		if not elegida.is_empty():
			arma = elegida
	return arma


# Arma de Meshy con sus texturas (color, relieve, metal, rugosidad y brillo).
func _cargar_sable_meshy(s: Node3D, largo: float, arma: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = load(arma["modelo"])
	mi.material_override = load("res://material_arma.gd").de_arma(arma)   # con brillo (sin quedar blanco)
	mi.scale = Vector3(-largo if VOLTEAR_FILO else largo, largo, largo)
	s.add_child(mi)


func _malla(m: Mesh, color: Color, pos: Vector3, metal := 0.0, brillo := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metal
	mat.roughness = 0.3 if metal > 0.0 else 0.7
	if brillo > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = brillo
	mi.material_override = mat
	mi.position = pos
	return mi


# Hoja a lo largo de +Y desde la empuñadura; el filo mira hacia +X.
func _piezas_sable(s: Node3D, e: float) -> void:
	var mango := CylinderMesh.new()
	mango.top_radius = 0.022 * e
	mango.bottom_radius = 0.022 * e
	mango.height = 0.27 * e
	s.add_child(_malla(mango, Color(0.12, 0.17, 0.36), Vector3(0, -0.03, 0) * e))
	var pomo := SphereMesh.new()
	pomo.radius = 0.04 * e
	pomo.height = 0.08 * e
	s.add_child(_malla(pomo, Color(0.95, 0.76, 0.3), Vector3(0, -0.18, 0) * e, 0.8))
	var guarda := BoxMesh.new()
	guarda.size = Vector3(0.28, 0.05, 0.075) * e
	s.add_child(_malla(guarda, Color(0.95, 0.76, 0.3), Vector3(0, 0.13, 0) * e, 0.8))
	var gema := SphereMesh.new()
	gema.radius = 0.028 * e
	gema.height = 0.056 * e
	s.add_child(_malla(gema, Color(0.35, 0.7, 1.0), Vector3(0, 0.13, 0.03) * e, 0.0, 1.5))
	var hoja := BoxMesh.new()
	hoja.size = Vector3(0.13, 1.0, 0.024) * e
	s.add_child(_malla(hoja, Color(0.88, 0.92, 0.98), Vector3(0, 0.655, 0) * e, 0.6))
	var punta := CylinderMesh.new()
	punta.top_radius = 0.0
	punta.bottom_radius = 0.092 * e
	punta.height = 0.17 * e
	punta.radial_segments = 4
	var mp := _malla(punta, Color(0.88, 0.92, 0.98), Vector3(0, 1.24, 0) * e, 0.6)
	mp.rotation_degrees = Vector3(0, 45, 0)
	mp.scale = Vector3(1, 1, 0.2)
	s.add_child(mp)
	var runas := BoxMesh.new()
	runas.size = Vector3(0.03, 0.78, 0.026) * e
	s.add_child(_malla(runas, Color(0.4, 0.75, 1.0), Vector3(0, 0.62, 0) * e, 0.0, 2.0))


# ---------------------------------------------------------------- movimientos

func reposo() -> void:
	play("Idle", 0.25)
	gestos.respirar = 0.0
	gestos.quitar_todos(0.3, ["k_cansado"])
	cansada(_cansada)


func cansada(si: bool) -> void:
	_cansada = si
	if _muerta:
		return
	gestos.poner("k_cansado", 1.0 if si else 0.0, 0.5)
	anim.speed_scale = 0.8 if si else 1.0


# Andar normal con el sable al hombro (el andar pesado de Meshy le hace mirar al suelo;
# si lo prefieres, cambia "Andar_normal" por "Walking").
func andar() -> void:
	_base_movimiento()
	play("Andar_normal" if nombres.has("Andar_normal") else "Walking")
	gestos.poner("k_hombro", 1.0, 0.15)


func correr() -> void:
	_base_movimiento()
	play("Running")
	gestos.poner("k_hombro", 1.0, 0.15)     # el sable sigue en el hombro al correr


func herida() -> void:
	if _muerta:
		return
	if not nombres.has("Hit"):
		super.herida()
		return
	play("Hit", 0.08)
	anim.speed_scale = 1.6
	await get_tree().create_timer(1.1).timeout
	if not _muerta and anim.current_animation == nombres["Hit"]:
		reposo()


func lanzar_magia() -> void:
	if not nombres.has("Casting"):
		await super.lanzar_magia()
		return
	gestos.quitar_todos(0.15)
	gestos.poner("k_magia", 1.0, 0.4)          # sable vertical, punta arriba
	anim.speed_scale = 1.2
	play("Casting", 0.15)
	await get_tree().create_timer(0.85).timeout   # momento en que extiende las manos


func fin_magia() -> void:
	reposo()


# La magia de Kael sale de la punta del sable.
func punto_magia() -> Vector3:
	if sable == null or not sable.visible:
		return super.punto_magia()
	return sable.global_transform * Vector3(0, _punta, 0)


# Ataque: se agacha, salta con el sable en alto y cae cortando. "impacto" se llama al tocar al enemigo.
func ataque_salto(impacto: Callable) -> void:
	if _muerta:
		return
	anim.speed_scale = 1.0
	play("Idle", 0.15)
	gestos.quitar_todos(0.1)
	gestos.poner("k_agachar", 1.0, T_AGACHAR * 0.9)
	await get_tree().create_timer(T_AGACHAR).timeout
	gestos.quitar("k_agachar", 0.12)
	gestos.poner("k_alto", 1.0, T_SALTO * 0.6)
	await get_tree().create_timer(T_SALTO).timeout
	gestos.quitar("k_alto", T_CORTE * 0.8)
	gestos.poner("k_corte", 1.0, T_CORTE * 0.8)
	await get_tree().create_timer(T_CORTE).timeout
	impacto.call()
	await get_tree().create_timer(0.3).timeout
	gestos.quitar("k_corte", 0.35)
	await get_tree().create_timer(0.3).timeout
	reposo()


func victoria() -> void:
	if _muerta:
		return
	cansada(false)
	reposo()
	mirar(Vector3(-0.2, 0.0, 1.0), 0.4)
	gestos.poner("k_victoria", 1.0, 0.45)
	var t := create_tween()
	t.tween_property(ajuste, "position:y", ajuste.position.y + 0.15, 0.18).set_ease(Tween.EASE_OUT)
	t.tween_property(ajuste, "position:y", ajuste.position.y, 0.22).set_ease(Tween.EASE_IN)


func morir() -> void:
	if _muerta:
		return
	if not nombres.has("Death"):
		super.morir()
		return
	_muerta = true
	gestos.respirar = 0.0
	gestos.quitar_todos(0.3)
	anim.speed_scale = 1.0
	play("Death", 0.15)


func revivir() -> void:
	if not _muerta:
		return
	if not nombres.has("Death"):
		super.revivir()
		return
	_muerta = false
	reposo()
