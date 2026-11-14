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


static func activo() -> bool:
	if Engine.has_meta("nix_fbx"):
		return bool(Engine.get_meta("nix_fbx"))
	# V12 (14/11): y, SOLO en Auditoría o en el editor, la opción de Ajustes ([calidad_pruebas] nix_fbx)
	return "nix_fbx" in OS.get_cmdline_user_args() or POR_DEFECTO \
		or load("res://prototipos/calidad_proto.gd").extra_activo("nix_fbx")
