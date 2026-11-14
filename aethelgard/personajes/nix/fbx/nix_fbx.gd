extends RefCounted
# Nix desde el FBX del usuario (V12, 14/11): PILOTO APAGADO. Interruptor y rutas.
#
# Es la Nix «base lisa» del FBX de Meshy «Silver Sentinel» (cara, ojos amatista, pelo plateado con el mechón superior
# y los dos delanteros), reducida a 11.968 triángulos con su textura rehorneada (1024 en el GLB), el esqueleto común de
# los héroes v2 (el de Lya re-situado en sus articulaciones), 36 huesos que deforman (6 de mechones) y sus clips.
# Fuentes y guiones: personajes/nix/fbx/fuente_blender/ y docs/v12/NIX_PILOTO_FBX.md. SIN ROPA todavía (mono gris):
# capucha, capa, faldones, medias, emblema y cetro canónico están pendientes; el cetro es el provisional del inventario.
#
# Solo cuenta si además está encendido el de Nix («nix_v12», grupo.gd): sin él Nix no existe en ninguna partida.
# Se enciende con Engine.set_meta("nix_fbx", true) o el argumento «-- nix_fbx». Apagado, nix_3d.gd carga su nix.glb
# de siempre y se comporta exactamente igual que antes.

const GLB := "res://personajes/nix/fbx/nix_fbx.glb"
const JSON_CLIPS := "res://personajes/nix/fbx/nix_fbx_clips.json"
const POR_DEFECTO := false
# El cetro canónico (independiente, por socket) no está modelado: mientras, si Nix no lleva arma equipada, se dibuja
# en su socket «arma_d» la malla de este cetro del inventario (solo el aspecto: no se equipa ni da estadísticas).
const CETRO_PROVISIONAL := "cetro_loto"


static func activo() -> bool:
	if Engine.has_meta("nix_fbx"):
		return bool(Engine.get_meta("nix_fbx"))
	# V12 (14/11): y, SOLO en Auditoría o en el editor, la opción de Ajustes ([calidad_pruebas] nix_fbx)
	return "nix_fbx" in OS.get_cmdline_user_args() or POR_DEFECTO \
		or load("res://prototipos/calidad_proto.gd").extra_activo("nix_fbx")
