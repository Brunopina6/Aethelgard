# Saca del ejecutable de Godot 4.7.2 las plantillas GLSL del sombreador de escena de Compatibility (GLES3), que van
# dentro como texto: la de vértices (con «#CODE : VERTEX») y la de fragmentos (con «#CODE : FRAGMENT» y la luz aditiva).
# Uso: py -3.10 extraer_plantillas.py [carpeta de trabajo] [ruta del Godot .exe]
#   → scene_vertex.glsl y scene_fragment.glsl en la carpeta de trabajo (por defecto D:\REBELUM_diagnostico\malioc).
# Son código de Godot (licencia MIT): se generan al usarlas y no se suben al repositorio.
import re, sys, os

TRABAJO = sys.argv[1] if len(sys.argv) > 1 else r"D:\REBELUM_diagnostico\malioc"
EXE = sys.argv[2] if len(sys.argv) > 2 else r"C:\Users\G513\Desktop\jueo personal\Godot_v4.7.2-stable_win64.exe"
b = open(EXE, "rb").read()
os.makedirs(TRABAJO, exist_ok=True)
vert = frag = None
for m in re.finditer(rb"[\x09\x0a\x0d\x20-\x7e]{3000,}", b):
	s = m.group()
	if b"#version 450" in s:                       # las de Vulkan (Forward+ y Mobile): no
		continue
	if b"#CODE : VERTEX" in s and b"instance_xform0" in s and vert is None:
		vert = s
	elif b"#CODE : FRAGMENT" in s and b"USE_ADDITIVE_LIGHTING" in s and frag is None:
		frag = s
if vert is None or frag is None:
	sys.exit("no se encontraron las plantillas")
open(os.path.join(TRABAJO, "scene_vertex.glsl"), "wb").write(vert)
open(os.path.join(TRABAJO, "scene_fragment.glsl"), "wb").write(frag)
print("plantillas: vértices %d bytes, fragmentos %d bytes en %s" % (len(vert), len(frag), TRABAJO))
