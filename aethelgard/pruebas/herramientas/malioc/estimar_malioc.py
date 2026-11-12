# Coste ESTIMADO en un Mali-G57 de los sombreadores del Gran Bosque (rend2, 12/11) con el Mali Offline Compiler.
# Es una estimación estática (ciclos por vértice o por fragmento de cada pasada), no FPS del Redmi.
#   1) py -3.10 extraer_plantillas.py [trabajo]        (las plantillas GLSL de Compatibility, sacadas del ejecutable)
#   2) py -3.10 estimar_malioc.py [trabajo] [escenario.gd] [sombreadores separados por comas]
# Arma el GLSL ES 3.0 que compilaría Godot 4.7.2 (plantilla de escena + código del material traducido como lo hace su
# compilador: m_ delante de los nombres propios, VERTEX → vertex...) para cada variante que usa el juego:
#   bajo_base     la pasada base con el sol sin sombra (perfil bajo)
#   medio_base    la pasada base sin el sol (medio: el sol tiene sombra y va en otra pasada)
#   medio_aditiva la pasada del sol con sombra (sombra dura: en el móvil, soft_shadow_filter_quality.mobile = 0)
#   sombra        el mapa de sombras
# La traducción es aproximada (mismos cálculos y lecturas; no idéntica letra a letra a la de Godot): vale para comparar
# variantes entre sí. Escribe <trabajo>/malioc_resultado.json y una tabla en <trabajo>/malioc_tabla.txt.
import subprocess, re, sys, json, os

TRABAJO = sys.argv[1] if len(sys.argv) > 1 else r"D:\REBELUM_diagnostico\malioc"
ESCENARIO = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "zonas3d", "gran_bosque", "escenario.gd")
MALIOC = r"C:\Program Files\Arm\Arm Performance Studio 2026.6\mali_offline_compiler\malioc.exe"
VERT = open(os.path.join(TRABAJO, "scene_vertex.glsl"), encoding="latin1").read()
FRAG = open(os.path.join(TRABAJO, "scene_fragment.glsl"), encoding="latin1").read()
CAB = """#version 300 es
%s
#define MAX_GLOBAL_SHADER_UNIFORMS 256
#define MAX_LIGHT_DATA_STRUCTS 32
#define MAX_DIRECTIONAL_LIGHT_DATA_STRUCTS 8
#define MAX_FORWARD_LIGHTS uint(8)
#define MAX_ROUGHNESS_LOD 6.0
precision highp float;
precision highp int;
precision highp sampler2D;
precision highp samplerCube;
precision highp sampler2DArray;
precision highp sampler2DShadow;
precision highp usampler2D;
"""
VERT_MAP = [("VERTEX", "vertex"), ("NORMAL", "normal"), ("COLOR", "color_interp"), ("CUSTOM0", "custom0_attrib"),
	("MODEL_MATRIX", "model_matrix"), ("TIME", "scene_data_input.time"), ("VIEW_MATRIX", "scene_data_input.view_matrix"),
	("UV", "uv_interp")]
FRAG_MAP = [("ALBEDO", "albedo"), ("ALPHA_SCISSOR_THRESHOLD", "alpha_scissor_threshold"), ("ALPHA", "alpha"),
	("COLOR", "color"), ("UV", "uv"), ("ROUGHNESS", "roughness"), ("SPECULAR", "specular"), ("BACKLIGHT", "backlight"),
	("NORMAL", "normal"), ("FRONT_FACING", "gl_FrontFacing"), ("FRAGCOORD", "gl_FragCoord"),
	("TIME", "scene_data_block.data.time"), ("VIEW_MATRIX", "scene_data_block.data.view_matrix"), ("EMISSION", "emission")]
TIPOS = r"(?:float|int|bool|vec2|vec3|vec4|mat3|mat4|ivec2|uint)"
COMUN = ["DISABLE_LIGHT_OMNI", "DISABLE_LIGHT_SPOT", "DISABLE_LIGHT_AREA", "DISABLE_LIGHTMAP", "USE_INSTANCING"]
VARIANTES = {
	"bajo_base": COMUN + ["BASE_PASS", "APPLY_TONEMAPPING"],
	"medio_base": COMUN + ["BASE_PASS", "APPLY_TONEMAPPING", "DISABLE_LIGHT_DIRECTIONAL"],
	"medio_aditiva": COMUN + ["USE_ADDITIVE_LIGHTING", "APPLY_TONEMAPPING", "DISABLE_LIGHT_DIRECTIONAL"],
	"sombra": COMUN + ["MODE_RENDER_DEPTH", "RENDER_SHADOWS"],
}


def constantes(ruta):
	s = open(ruta, encoding="utf-8").read()
	return {m.group(1): m.group(2) for m in re.finditer(r'const\s+(\w+)\s*:=\s*"""(.*?)"""', s, re.S)}


def _cuerpo(cod, nombre):
	i = cod.find("void %s()" % nombre)
	if i < 0:
		return "", cod
	j = cod.find("{", i)
	n = 0
	for k in range(j, len(cod)):
		if cod[k] == "{":
			n += 1
		elif cod[k] == "}":
			n -= 1
			if n == 0:
				return cod[j + 1:k], cod[:i] + cod[k + 1:]
	raise ValueError(nombre)


# Sombreador de Godot (texto) → piezas: uniformes, muestreadores, varyings, funciones, vertex, fragment y defines.
def spec(cod):
	modo = re.search(r"render_mode\s+([^;]*);", cod)
	modos = [m.strip() for m in modo.group(1).split(",")] if modo else []
	cod = re.sub(r"shader_type[^;]*;", "", cod)
	cod = re.sub(r"render_mode[^;]*;", "", cod)
	vert, cod = _cuerpo(cod, "vertex")
	frag, cod = _cuerpo(cod, "fragment")
	nombres = set()
	uniformes, muestreadores, varyings = [], [], []
	for m in re.finditer(r"uniform\s+(\w+)\s+(\w+)\s*(?::[^=;]*)?(?:=[^;]*)?;", cod):
		t, n = m.group(1), m.group(2)
		nombres.add(n)
		(muestreadores.append("uniform highp %s %s;" % (t, n)) if t.startswith("sampler") else uniformes.append("\t%s %s;" % (t, n)))
	cod = re.sub(r"uniform\s+[^;]*;", "", cod)
	for m in re.finditer(r"varying\s+(\w+)\s+(\w+)\s*;", cod):
		varyings.append("%s %s" % (m.group(1), m.group(2)))
		nombres.add(m.group(2))
	cod = re.sub(r"varying\s+[^;]*;", "", cod)
	for m in re.finditer(r"\b%s\s+(\w+)\s*\(" % TIPOS, cod):
		nombres.add(m.group(1))
	for texto in (cod, vert, frag):
		for m in re.finditer(r"\b%s\s+(\w+)\b(?!\s*\()" % TIPOS, texto):
			nombres.add(m.group(1))
	todo = vert + frag + cod
	usa = lambda p: re.search(r"\b%s\b" % p, todo) is not None
	defs = [d for p, d in [("UV", "UV_USED"), ("NORMAL", "NORMAL_USED"), ("COLOR", "COLOR_USED"),
		("ALPHA_SCISSOR_THRESHOLD", "ALPHA_SCISSOR_USED"), ("BACKLIGHT", "LIGHT_BACKLIGHT_USED"), ("CUSTOM0", "CUSTOM0_USED")] if usa(p)]
	if uniformes:
		defs.append("MATERIAL_UNIFORMS_USED")
	if "cull_disabled" in modos:
		defs.append("DO_SIDE_CHECK")
	for m, d in [("specular_disabled", "SPECULAR_DISABLED"), ("specular_schlick_ggx", "SPECULAR_SCHLICK_GGX"),
			("diffuse_burley", "DIFFUSE_BURLEY"), ("diffuse_lambert", "DIFFUSE_LAMBERT"), ("unshaded", "MODE_UNSHADED"),
			("shadows_disabled", "SHADOWS_DISABLED"), ("fog_disabled", "FOG_DISABLED")]:
		if m in modos:
			defs.append(d)
	if not any(m.startswith("diffuse_") for m in modos):
		defs.append("DIFFUSE_BURLEY")
	return {"nombres": nombres, "uniformes": "\n".join(uniformes), "muestreadores": "\n".join(muestreadores),
		"varyings": varyings, "globales": cod, "vertex": vert, "fragment": frag, "defines": defs}


def traducir(cod, mapa, nombres):
	for n in sorted(nombres, key=len, reverse=True):
		cod = re.sub(r"(?<![\w.])%s\b" % n, "m_" + n, cod)
	for a, b in mapa:
		cod = re.sub(r"\b%s\b" % a, b, cod)
	return cod


def armar(s, etapa, defines):
	n = s["nombres"]
	if etapa == "vert":
		glob = traducir(s["globales"] + "\n" + "\n".join("out %s;" % v for v in s["varyings"]), VERT_MAP, n)
		t = VERT.replace("#CODE : VERTEX", traducir(s["vertex"], VERT_MAP, n))
	else:
		glob = traducir(s["globales"] + "\n" + "\n".join("in %s;" % v for v in s["varyings"]), FRAG_MAP, n)
		t = FRAG.replace("#CODE : FRAGMENT", traducir(s["fragment"], FRAG_MAP, n)).replace("#CODE : LIGHT", "")
	t = t.replace("#MATERIAL_UNIFORMS", traducir(s["uniformes"], [], n)).replace("#GLOBALS", traducir(s["muestreadores"], [], n) + "\n" + glob)
	return CAB % "\n".join("#define " + d for d in defines) + t


def malioc(texto, etapa, nombre):
	carpeta = os.path.join(TRABAJO, "gen")
	os.makedirs(carpeta, exist_ok=True)
	ruta = os.path.join(carpeta, "%s.%s" % (nombre, etapa))
	open(ruta, "w").write(texto)
	r = subprocess.run([MALIOC, "-c", "Mali-G57", "--format", "json", "--" + ("vertex" if etapa == "vert" else "fragment"), ruta],
		capture_output=True, text=True)
	j = json.loads(r.stdout)
	if j["schema"]["name"] == "error" or j["shaders"][0].get("errors"):
		raise RuntimeError(" | ".join(j["shaders"][0].get("errors", [])) + " :: " + ruta)
	return j


def resumen(j, etapa):
	s = j["shaders"][0]
	props = {p["name"]: p["value"] for p in s.get("properties", [])}
	filas = []
	for v in s["variants"]:
		perf = v["performance"]
		pl = perf["pipelines"]
		largo = {a: (b or 0.0) for a, b in zip(pl, perf["longest_path_cycles"]["cycle_count"])}
		total = {a: (b or 0.0) for a, b in zip(pl, perf["total_cycles"]["cycle_count"])}
		vp = {p["name"]: p["value"] for p in v.get("properties", [])}
		# con bucles de longitud desconocida (el sol en la pasada base del bajo) no hay «camino largo»: se da el total
		cic = max(largo.values()) if max(largo.values()) > 0 else max(total.values())
		filas.append({"variante": v["name"], "ciclos": round(cic, 2), "aritmetica": round(largo.get("arith_total", 0) or total.get("arith_total", 0), 2),
			"carga_guardado": round(largo.get("load_store", 0) or total.get("load_store", 0), 2), "textura": round(largo.get("texture", 0) or total.get("texture", 0), 2),
			"registros": vp.get("work_registers_used"), "solo_total": max(largo.values()) == 0})
	return {"pasadas": filas, "zs_tardio": bool(props.get("uses_late_zs_update")), "modifica_cobertura": bool(props.get("modifies_coverage"))}


def sombreadores(C):
	U, HV, H = C["UNIFORMES_HUECO"], C["HUECO_VERTICE"], C["HUECO"]
	hojas = C["SHADER_HOJAS"] % (U, HV, "")
	return {
		"hojas": hojas,
		"hojas_sin_brillo": hojas.replace("render_mode cull_disabled, specular_schlick_ggx;", "render_mode cull_disabled, specular_disabled;"),
		"hojas_ligeras": hojas.replace("render_mode cull_disabled, specular_schlick_ggx;", "render_mode cull_disabled, specular_disabled, diffuse_lambert, shadows_disabled;"),
		"hojas_hueco_pixel": C["SHADER_HOJAS"] % (U, "", H),
		"copa_maciza": C["SHADER_MACIZO"] % ("cull_back", U, HV, ""),
		"tronco_tramado": C["SHADER_MACIZO"] % ("cull_back", U, "", H),
		"tronco_sin_tramado": C["SHADER_MACIZO"] % ("cull_back", U, "", ""),
		"sotobosque": C["SHADER_MACIZO"] % ("cull_disabled", U, "", ""),
		"hierba": C["SHADER_HIERBA"],
	}


if __name__ == "__main__":
	SH = sombreadores(constantes(ESCENARIO))
	pedidos = sys.argv[3].split(",") if len(sys.argv) > 3 else list(SH)
	res = {}
	lineas = ["sombreador          variante       etapa:pasada     ciclos  aritm.  l/s   tex   reg  (ZS tardío / cobertura)"]
	for nombre in pedidos:
		s = spec(SH[nombre])
		for var, defs in VARIANTES.items():
			for etapa in ["vert", "frag"]:
				r = resumen(malioc(armar(s, etapa, s["defines"] + defs), etapa, "%s_%s" % (nombre, var)), etapa)
				res["%s|%s|%s" % (nombre, var, etapa)] = r
				for p in r["pasadas"]:
					z = ("ZS tardío" if r["zs_tardio"] else "") + (" cobertura" if r["modifica_cobertura"] else "") if etapa == "frag" else ""
					lineas.append("%-19s %-14s %s:%-9s %6.2f%s %6.2f %5.2f %5.2f  r%s  %s" % (nombre, var, etapa, p["variante"], p["ciclos"],
						"*" if p["solo_total"] else " ", p["aritmetica"], p["carga_guardado"], p["textura"], p["registros"], z))
	lineas.append("(* = con bucles de longitud desconocida: ciclos totales, no del camino más largo)")
	json.dump(res, open(os.path.join(TRABAJO, "malioc_resultado.json"), "w"), indent=1)
	open(os.path.join(TRABAJO, "malioc_tabla.txt"), "w", encoding="utf-8").write("\n".join(lineas) + "\n")
	print("\n".join(lineas))
