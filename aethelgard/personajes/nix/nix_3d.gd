extends "res://maga_3d.gd"
# Nix 3D (V12, 13/11): cuarta heroína, maga negra. PROTOTIPO: solo sale con el interruptor «nix_v12» (grupo.gd),
# APAGADO. La relación con Naira (otra maga negra, también prototipo) la decide el usuario (docs/v12/NIX_V12.md).
#
# Modelo propio hecho con Blender por guion (fuente/crear_nix.py): personajes/nix/nix.glb, con el esqueleto de los
# héroes v2 (Mixamo, nombres y orientaciones de Lya) re-proporcionado, un atlas de 1024 horneado, cara propia con
# cejas por formas clave, LOD en el mismo GLB y sus clips (nix_clips.json). Sigue el patrón de los héroes: hereda de
# maga_3d.gd, así que el combate y la exploración la llaman como a Lya. Lo que cambia:
#   - el bastón va en el modelo (hueso «arma_d», rígido): no se crea la vara del inventario;
#   - sus movimientos son sus clips (los gestos por código solo ponen el cansancio);
#   - cada hechizo piloto tiene su gesto: lanzar_negra(escuela) → magia_lanzar (P01), magia_estado (P02) o
#     magia_culminante (P07), y espera con «await» al instante en que sale («lanzamiento» del JSON);
#   - nix_ayudante.gd pone el material de los héroes v2 (heroe_v2.gdshader) a su atlas, la cara y el parpadeo;
#   - LOD por distancia (visibility_range) entre «cuerpo_nix», «cuerpo_nix_lod1» y «cuerpo_nix_lod2».
#
# 14/11, PILOTO desde el FBX del usuario (personajes/nix/fbx/nix_fbx.gd, interruptor «nix_fbx», APAGADO): con él, carga
# nix_fbx.glb (la Nix «base lisa» del FBX, sin ropa todavía) y su JSON; el cetro va por socket en «arma_d» (el del
# inventario o el provisional), sin LOD manuales (los genera el importador) y concentrarse empieza por «canalizar» (los
# mechones se elevan con retraso). Apagado, todo lo de abajo es exactamente lo de antes.

const RUTA_NIX := "res://personajes/nix/nix.glb"
const JSON_CLIPS := "res://personajes/nix/nix_clips.json"
const Ayudante := preload("res://personajes/nix/nix_ayudante.gd")
const NixFBX := preload("res://personajes/nix/fbx/nix_fbx.gd")
const CLIPS := {"Idle": "guardia", "Walking": "andar", "Running": "correr", "Casting": "magia_lanzar"}
const BUCLES := ["reposo", "guardia", "andar", "correr", "derrota", "magia_concentrar", "defensa"]
# hechizo (escuela de magia_negra.gd) -> clip
const GESTO := {"nix_ascuas": "magia_lanzar", "nix_aguja": "magia_estado", "nix_colapso": "magia_culminante"}
const LARGO_CRISTAL := 0.44             # del puño (hueso arma_d) al centro del cristal (v2; el JSON manda si lo trae)
# LOD: hasta dónde se ve cada uno (m, cámara al personaje), con un margen de fundido
const LOD := [["cuerpo_nix", 0.0, 9.0], ["cuerpo_nix_lod1", 9.0, 18.0], ["cuerpo_nix_lod2", 18.0, 0.0]]

var v2: Node = null
var _clips := {}                         # contrato: nombre -> {duracion, bucle, eventos}
var _largo_cristal := LARGO_CRISTAL
var _i_arma := -1
var _exploracion := false
var _fbx := false                        # piloto del FBX (nix_fbx.gd)
var _ruta_json := JSON_CLIPS


func _init() -> void:
	ruta_modelo = RUTA_NIX
	rutas_extra = []
	heroe = "Nix"
	clave_esperas = "Nix"                  # sin esperas propias todavía (esperas_3d.gd no la tiene): no hace ninguna
	usa_vara = false
	vel_andar = 1.30                        # sin medir (prueba_anim_pies.gd no la tiene): provisional, piernas cortas
	vel_correr = 4.0
	_fbx = NixFBX.activo()
	if _fbx:
		ruta_modelo = NixFBX.GLB
		_ruta_json = NixFBX.JSON_CLIPS
		usa_vara = true                     # el cetro, por socket (arma_d)
		vel_andar = 1.55                    # SIN MEDIR: andar de captura de Lya con la cadera ×1,153 (piernas de Nix)
		vel_correr = 5.4


func _ready() -> void:
	if FileAccess.file_exists(_ruta_json):
		var d = JSON.parse_string(FileAccess.get_file_as_string(_ruta_json))
		if d is Dictionary:
			_clips = d.get("clips", {})
			_largo_cristal = float(d.get("largo_cristal", LARGO_CRISTAL))
	super._ready()
	if skel == null:
		return
	_i_arma = skel.find_bone("arma_d")
	gestos.respirar = 0.0                   # sus clips ya respiran
	v2 = Ayudante.new()
	v2.name = "HeroeNix"
	add_child(v2)
	v2.preparar(self, "Nix")
	if _fbx:
		if vara != null:
			_largo_cristal = _vara_punta    # la magia sale de la punta del cetro
	else:
		_poner_lod()
	reposo()


func _mapear_animaciones() -> void:
	for k in CLIPS:
		if anim.has_animation(CLIPS[k]):
			nombres[k] = CLIPS[k]
	if _exploracion and anim.has_animation("reposo"):
		nombres["Idle"] = "reposo"
	for b in BUCLES:
		if anim.has_animation(b):
			anim.get_animation(b).loop_mode = Animation.LOOP_LINEAR


func _poner_lod() -> void:
	for l in LOD:
		var mi := find_child(l[0], true, false)
		if mi is GeometryInstance3D:
			mi.visibility_range_begin = l[1]
			mi.visibility_range_end = l[2]
			mi.visibility_range_begin_margin = 0.5 if l[1] > 0.0 else 0.0
			mi.visibility_range_end_margin = 0.5 if l[2] > 0.0 else 0.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED


func activar_esperas(si := true) -> bool:
	_exploracion = si
	nombres["Idle"] = "reposo" if si and anim != null and anim.has_animation("reposo") else "guardia"
	if not _muerta and marcha_actual() == "":
		reposo()
	return super.activar_esperas(si)


func instante(clip: String, evento: String, defecto := 0.5) -> float:
	return float(_clips.get(clip, {}).get("eventos", {}).get(evento, defecto))


# Un clip suyo desde el principio. Devuelve lo que dura (0 si no lo tiene).
func reproducir(clip: String, fundido := 0.15) -> float:
	if v2 != null:
		return v2.reproducir(clip, fundido)
	return 0.0


# El cristal del bastón: de ahí sale la magia.
func punto_magia() -> Vector3:
	if skel != null and _i_arma >= 0:
		return skel.global_transform * (skel.get_bone_global_pose(_i_arma) * Vector3(0, _largo_cristal, 0))
	return super.punto_magia()


# ---------------------------------------------------------------- cetro del piloto FBX (por socket)
# Como maga_3d.gd _crear_vara, pero si Nix no lleva arma equipada usa la malla del cetro provisional (solo el aspecto).
func _crear_vara() -> void:
	if not _fbx or not ResourceLoader.exists("res://inventario.gd"):
		super._crear_vara()
		return
	var inv = load("res://inventario.gd")
	var arma: Dictionary = inv.arma_de(heroe)
	if arma.is_empty() or not ResourceLoader.exists(arma.get("modelo", "")):
		arma = inv.ARMAS.get(NixFBX.CETRO_PROVISIONAL, {})
	if arma.is_empty() or not ResourceLoader.exists(arma["modelo"]):
		return
	vara = Node3D.new()
	vara.name = "CetroNix"
	skel.add_child(vara)
	var largo: float = gestos.escala * arma["largo"]
	var mi := MeshInstance3D.new()
	mi.mesh = load(arma["modelo"])
	mi.material_override = load("res://material_arma.gd").de_arma(arma, 0.4)
	mi.scale = Vector3.ONE * largo
	vara.add_child(mi)
	_vara_punta = arma["punta"] * largo
	gestos.al_terminar = _actualizar_vara


# El cetro sigue al hueso «arma_d» de cada clip (como los héroes v2).
func _actualizar_vara(sk: Skeleton3D) -> void:
	if not _fbx or _i_arma < 0:
		super._actualizar_vara(sk)
		return
	vara.global_transform = sk.global_transform * sk.get_bone_global_pose(_i_arma)


# ---------------------------------------------------------------- combate (los mismos nombres que maga_3d.gd)
func reposo() -> void:
	play("Idle", 0.25)
	if gestos != null:
		gestos.respirar = 0.0
		gestos.quitar_todos(0.3, ["cansada"])
	cansada(_cansada)
	if v2 != null and not _muerta:
		v2.poner_expresion("normal")


func lanzar_magia() -> void:
	await lanzar_negra("nix_ascuas")


# Su gesto para cada hechizo (combate.gd _resolver_negra lo pide si existe). Espera hasta que sale el hechizo.
func lanzar_negra(fam: String, _d := {}) -> void:
	var clip: String = GESTO.get(fam, "magia_lanzar")
	if gestos != null:
		gestos.quitar_todos(0.15, ["cansada"])
	reproducir(clip, 0.15)
	v2.poner_expresion("decidido", 0.4)
	var t := instante(clip, "lanzamiento", 0.7)
	if clip == "magia_culminante":
		get_tree().create_timer(instante(clip, "preparacion", 1.1)).timeout.connect(func():
			if is_instance_valid(self) and not _muerta:
				v2.poner_expresion("entrecerrados", 0.5), CONNECT_ONE_SHOT)
	await get_tree().create_timer(t).timeout
	if not _muerta:
		v2.poner_expresion("grito" if clip == "magia_culminante" else "decidido", 0.7)


func magia_poderosa() -> void:
	await lanzar_negra("nix_colapso")


func fin_magia() -> void:
	if not _muerta:
		get_tree().create_timer(0.35).timeout.connect(func():
			if is_instance_valid(self) and not _muerta and String(anim.assigned_animation).begins_with("magia_"):
				reposo(), CONNECT_ONE_SHOT)


# Mientras prepara un hechizo (estado «conjuro» de combate.gd): el bastón ante sí y la mano sobre el cristal (bucle).
# Piloto FBX: antes, «canalizar» (0,9 s: los mechones delanteros suben con retraso y el superior responde) y luego el
# bucle, que mantiene los mechones arriba ondulando.
func concentrar() -> void:
	if not _muerta:
		if _fbx and anim.has_animation("canalizar") and String(anim.assigned_animation) != "magia_concentrar":
			var d := reproducir("canalizar", 0.2)
			get_tree().create_timer(maxf(d - 0.1, 0.05)).timeout.connect(func():
				if is_instance_valid(self) and not _muerta and anim.assigned_animation == "canalizar":
					anim.play("magia_concentrar", 0.15), CONNECT_ONE_SHOT)
		else:
			reproducir("magia_concentrar", 0.25)
		v2.poner_expresion("entrecerrados")


func preparar_golpe() -> void:
	reproducir("ataque", 0.15)
	v2.poner_expresion("decidido", 1.0)
	var prep := instante("ataque", "prep", 0.3)
	var imp := instante("ataque", "impacto", 0.45)
	get_tree().create_timer(prep).timeout.connect(func():
		if is_instance_valid(self) and anim.assigned_animation == "ataque" and anim.current_animation_position < imp:
			anim.speed_scale = 0.0, CONNECT_ONE_SHOT)       # espera en la preparación a que el combate diga «golpea»


func golpear() -> void:
	anim.speed_scale = 1.0
	if anim.assigned_animation == "ataque":
		anim.seek(maxf(0.0, instante("ataque", "impacto", 0.45) - 0.08), true)


func fin_golpe() -> void:
	get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(self) and not _muerta and anim.assigned_animation == "ataque":
			reposo(), CONNECT_ONE_SHOT)


func herida() -> void:
	if _muerta:
		return
	var d := reproducir("recibir_golpe", 0.05)
	v2.poner_expresion("dolor", 0.6)
	await get_tree().create_timer(maxf(d, 0.3)).timeout
	if not _muerta and anim.assigned_animation == "recibir_golpe":
		reposo()


# Defender (combate.gd _defender): cruza el bastón y se queda en guardia alta hasta su turno.
func defender() -> void:
	if _muerta:
		return
	var d := reproducir("defender", 0.12)
	v2.poner_expresion("decidido")
	get_tree().create_timer(d).timeout.connect(func():
		if is_instance_valid(self) and not _muerta and anim.assigned_animation == "defender":
			anim.play("defensa", 0.2), CONNECT_ONE_SHOT)


func fin_defensa() -> void:
	if not _muerta and anim.assigned_animation in ["defender", "defensa"]:
		reposo()


func victoria() -> void:
	if _muerta:
		return
	cansada(false)
	if gestos != null:
		gestos.quitar_todos(0.2)
	mirar(Vector3(-0.2, 0.0, 1.0), 0.4)
	reproducir("victoria", 0.2)
	v2.poner_expresion("sonrisa")


func morir() -> void:
	if _muerta:
		return
	_muerta = true
	if gestos != null:
		gestos.quitar_todos(0.3)
	anim.speed_scale = 1.0
	var d := reproducir("derribo", 0.1)
	v2.poner_expresion("dolor")
	await get_tree().create_timer(d).timeout
	if _muerta and anim.assigned_animation == "derribo":
		anim.play("derrota", 0.3)
		v2.poner_expresion("cerrados")


func revivir() -> void:
	if not _muerta:
		return
	_muerta = false
	anim.speed_scale = 1.0
	var d := reproducir("levantarse", 0.2)
	v2.poner_expresion("entrecerrados", d)
	await get_tree().create_timer(d).timeout
	if not _muerta and anim.assigned_animation == "levantarse":
		reposo()


# ---------------------------------------------------------------- exploración y conversación (como los v2)
func hablar(animo := "") -> String:
	return v2.hablar(animo) if v2 != null else ""


func expresion(nombre: String, dur := 0.0) -> void:
	if v2 != null:
		v2.poner_expresion(nombre, dur)
