extends RefCounted
# Nix desde el FBX del usuario (V12, 14/11): PILOTO APAGADO. Interruptor y rutas.
#
# Es la Nix «base lisa» del FBX de Meshy «Silver Sentinel» (cara, ojos amatista, pelo plateado con el mechón superior
# y los dos delanteros), reducida a 11.968 triángulos con su textura rehorneada (1024 en el GLB), el esqueleto común de
# los héroes v2 (el de Lya re-situado en sus articulaciones), 36 huesos que deforman (6 de mechones) y sus clips.
# Fuentes y guiones: personajes/nix/fbx/fuente_blender/ y docs/v12/NIX_PILOTO_FBX.md.
# 14/11, VESTUARIO CANÓNICO (p8_vestuario.py): la ropa va en otra malla del mismo GLB («ropa_nix», 7.513 triángulos, un
# material con atlas de 1024): capucha con forro púrpura y el pelo recogido dentro, capa corta, corpiño con el emblema
# dorado de la espalda (Ojo de Horus en estrella de seis puntas), mangas, peplo, faldones largos abiertos por delante,
# tabardo, medias asimétricas, botas y bolsas; 54 huesos (6 nuevos: faldon_i_1/2, faldon_d_1/2, capa y capucha) con su
# movimiento horneado en los 23 clips. El mono del FBX pasa a negro y el pelo a gris ceniza. Cetro PROPIO (cetro_nix.glb,
# p9_cetro.py) en el socket «arma_d» cuando no lleva arma equipada.
#
# Solo cuenta si además está encendido el de Nix («nix_v12», grupo.gd): sin él Nix no existe en ninguna partida.
# Se enciende con Engine.set_meta("nix_fbx", true) o el argumento «-- nix_fbx». Apagado, nix_3d.gd carga su nix.glb
# de siempre y se comporta exactamente igual que antes.

const GLB := "res://personajes/nix/fbx/nix_fbx.glb"
const JSON_CLIPS := "res://personajes/nix/fbx/nix_fbx_clips.json"
const POR_DEFECTO := false
# Su cetro propio (independiente del cuerpo, por socket): si Nix no lleva arma equipada, se pone en «arma_d» (solo el
# aspecto: no se equipa ni da estadísticas). La punta mágica (centro de la amatista) a 0,50 m del puño, en las unidades
# del esqueleto. Si faltara, el del inventario como antes.
const CETRO := "res://personajes/nix/fbx/cetro_nix.glb"
const CETRO_PUNTA := 0.50
const CETRO_PROVISIONAL := "cetro_loto"
# 14/11 (tarde): el cuerpo lleva el material de los v2 con una emisión SUAVE solo en el iris (nix_fbx_cuerpo.gdshader).
const SHADER_CUERPO := "res://personajes/nix/fbx/nix_fbx_cuerpo.gdshader"
# 19/11 (C-6): la ROPA lleva el material de los v2 con la emisión de los ornamentos (oro y amatistas), APAGADA salvo
# mientras Nix usa una habilidad (nix_fbx_ropa.gdshader, uniforme «ornamentos»; lo mueve nix_3d.gd).
const SHADER_ROPA := "res://personajes/nix/fbx/nix_fbx_ropa.gdshader"
# Intensidades (valor de «ornamentos»): 0 apagada, 1 básica, 2 fuerte, 3 suprema. DECISIÓN REVISABLE (sin la del usuario).
const NIVELES := [0.0, 0.8, 1.6, 2.8]
const BASICA := 1
const FUERTE := 2
const SUPREMA := 3
# Qué intensidad lleva cada habilidad (DECISIÓN REVISABLE, docs/v12/NIX_PILOTO_FBX.md §12): los dos hechizos de rango I,
# básica; la canalización (concentrarse mientras se prepara un hechizo con barra), fuerte; el culminante de rango VI
# que gasta los tres sellos de Eclipse, suprema. Uno nuevo sin fila: por los sellos que gasta (3 suprema, 2 fuerte).
const NIVEL_HECHIZO := {"nix_ascuas": BASICA, "nix_aguja": BASICA, "nix_colapso": SUPREMA}
const NIVEL_CANALIZAR := FUERTE


static func activo() -> bool:
	if Engine.has_meta("nix_fbx"):
		return bool(Engine.get_meta("nix_fbx"))
	# V12 (14/11): y, SOLO en Auditoría o en el editor, la opción de Ajustes ([calidad_pruebas] nix_fbx)
	return "nix_fbx" in OS.get_cmdline_user_args() or POR_DEFECTO \
		or load("res://prototipos/calidad_proto.gd").extra_activo("nix_fbx")


# Ojos amatista legibles a la distancia del juego: cambia el shader del material que puso el ayudante de los v2 en
# «cuerpo_nix» por el suyo (los mismos parámetros + la emisión del iris). La ropa no cambia. Devuelve si lo puso.
static func poner_iris(nodo: Node) -> bool:
	var mi := nodo.find_child("cuerpo_nix", true, false) as MeshInstance3D
	if mi == null or not ResourceLoader.exists(SHADER_CUERPO):
		return false
	var sm := mi.get_surface_override_material(0) as ShaderMaterial
	if sm == null:
		return false
	sm.shader = load(SHADER_CUERPO)
	return true


# Ornamentos de la ropa (19/11, C-6): cambia el shader del material que puso el ayudante de los v2 en «ropa_nix» por
# el suyo (los mismos parámetros + la emisión, a 0). Devuelve ese material (null si no se pudo).
static func poner_ornamentos(nodo: Node) -> ShaderMaterial:
	var mi := nodo.find_child("ropa_nix", true, false) as MeshInstance3D
	if mi == null or not ResourceLoader.exists(SHADER_ROPA):
		return null
	var sm := mi.get_surface_override_material(0) as ShaderMaterial
	if sm == null:
		return null
	sm.shader = load(SHADER_ROPA)
	sm.set_shader_parameter("ornamentos", 0.0)
	return sm


# La intensidad de un hechizo (índice de NIVELES).
static func nivel_de(fam: String, d := {}) -> int:
	if NIVEL_HECHIZO.has(fam):
		return NIVEL_HECHIZO[fam]
	var s := int(d.get("sellos", 0))
	return SUPREMA if s >= 3 else (FUERTE if s == 2 else BASICA)
