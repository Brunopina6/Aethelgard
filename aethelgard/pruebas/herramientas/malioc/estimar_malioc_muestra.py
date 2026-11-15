# Coste ESTIMADO en un Mali-G57 de los sombreadores de la MUESTRA GRÁFICA de una calle de Oakhaven (15/11,
# zonas3d/muestra_calle/*.gdshader) con el Mali Offline Compiler. Estimación estática (ciclos por vértice o fragmento),
# no FPS del Redmi. Usa las piezas de estimar_malioc.py (misma traducción aproximada a GLSL ES 3.0 de Compatibility).
#   1) py -3.10 extraer_plantillas.py <trabajo>
#   2) py -3.10 estimar_malioc_muestra.py <trabajo>
# Son sombreados «unshaded» (la luz va horneada): solo la pasada base con el mapeo de tonos (la del perfil bajo y el
# medio: el sol no ilumina estos materiales). Escribe <trabajo>/malioc_muestra.json y <trabajo>/malioc_muestra.txt.
import sys, os, json

TRABAJO = sys.argv[1] if len(sys.argv) > 1 else r"D:\REBELUM_diagnostico\muestra_calle_15_11\malioc"
sys.argv = [sys.argv[0], TRABAJO]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import estimar_malioc as E

E.FRAG_MAP.insert(0, ("INV_VIEW_MATRIX", "scene_data_block.data.inv_view_matrix"))
E.FRAG_MAP.insert(0, ("UV2", "uv2"))
E.FRAG_MAP.insert(0, ("VERTEX", "vertex"))


def armar(s, etapa, defines):
	"""Como E.armar, pero con los varyings declarados ANTES de las funciones globales (sombra_kael los lee)."""
	n = s["nombres"]
	io = "out" if etapa == "vert" else "in"
	mapa = E.VERT_MAP if etapa == "vert" else E.FRAG_MAP
	glob = E.traducir("\n".join("%s %s;" % (io, v) for v in s["varyings"]) + "\n" + s["globales"], mapa, n)
	if etapa == "vert":
		t = E.VERT.replace("#CODE : VERTEX", E.traducir(s["vertex"], mapa, n))
	else:
		t = E.FRAG.replace("#CODE : FRAGMENT", E.traducir(s["fragment"], mapa, n)).replace("#CODE : LIGHT", "")
	t = t.replace("#MATERIAL_UNIFORMS", E.traducir(s["uniformes"], [], n)).replace("#GLOBALS",
		E.traducir(s["muestreadores"], [], n) + "\n" + glob)
	return E.CAB % "\n".join("#define " + d for d in defines) + t


E.armar = armar
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "zonas3d", "muestra_calle")
SOMBREADORES = ["calle_estatico", "calle_vertice", "calle_hoja", "calle_brillo"]
VARIANTE = E.COMUN + ["BASE_PASS", "APPLY_TONEMAPPING", "DISABLE_LIGHT_DIRECTIONAL"]

res = {}
lineas = ["sombreador        etapa:pasada     ciclos  aritm.  l/s   tex   reg  (ZS tardío / cobertura)"]
for nombre in SOMBREADORES:
	cod = open(os.path.join(RAIZ, nombre + ".gdshader"), encoding="utf-8").read()
	s = E.spec(cod)
	if "UV2" in cod:
		s["defines"].append("UV2_USED")
	for etapa in ["vert", "frag"]:
		r = E.resumen(E.malioc(E.armar(s, etapa, s["defines"] + VARIANTE), etapa, "muestra_%s" % nombre), etapa)
		res["%s|%s" % (nombre, etapa)] = r
		for p in r["pasadas"]:
			z = ("ZS tardío" if r["zs_tardio"] else "") + (" cobertura" if r["modifica_cobertura"] else "") if etapa == "frag" else ""
			lineas.append("%-17s %s:%-9s %6.2f%s %6.2f %5.2f %5.2f  r%s  %s" % (nombre, etapa, p["variante"], p["ciclos"],
				"*" if p["solo_total"] else " ", p["aritmetica"], p["carga_guardado"], p["textura"], p["registros"], z))
json.dump(res, open(os.path.join(TRABAJO, "malioc_muestra.json"), "w"), indent=1)
open(os.path.join(TRABAJO, "malioc_muestra.txt"), "w", encoding="utf-8").write("\n".join(lineas) + "\n")
print("\n".join(lineas))
