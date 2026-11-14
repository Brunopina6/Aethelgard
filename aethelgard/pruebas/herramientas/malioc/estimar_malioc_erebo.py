# Coste ESTIMADO en un Mali-G57 de los sombreadores de Érebo (erebo_3d.gd) con el Mali Offline Compiler (14/11).
# Usa las piezas de estimar_malioc.py (misma traducción aproximada a GLSL ES 3.0 de Compatibility).
#   1) py -3.10 extraer_plantillas.py <trabajo>
#   2) py -3.10 estimar_malioc_erebo.py <trabajo>
# Sombreadores: el cuerpo (con disolución), el cuerpo SIN el cálculo de la disolución (lo que se ve cuando disolver = 0),
# el charco, el orbe y el de las partículas y sprites (StandardMaterial3D sin luz, alfa, color de vértice y textura).
# Variante: «bajo_base» (pasada base con el sol sin sombra: el teatro en el móvil). Solo fragmentos y vértices de cada
# uno; es una estimación estática para comparar, no FPS del Redmi.
import os, sys, json, re

TRABAJO = sys.argv[1] if len(sys.argv) > 1 else r"D:\REBELUM_diagnostico\malioc"
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.argv = [sys.argv[0], TRABAJO]
sys.path.insert(0, AQUI)
import estimar_malioc as E  # noqa: E402
E.FRAG_MAP.append(("VIEW", "view"))     # el orbe usa VIEW (en la plantilla, «view»)

EREBO = os.path.join(AQUI, "..", "..", "..", "erebo_3d.gd")
C = E.constantes(EREBO)

# El cuerpo cuando NO se disuelve (disolver = 0): solo la textura (lo que el fragmento acaba escribiendo en ese caso).
CUERPO_ENTERO = """
shader_type spatial;
uniform sampler2D textura : source_color, filter_linear_mipmap;
void fragment() {
	vec4 c = texture(textura, UV);
	ALBEDO = c.rgb;
	ROUGHNESS = 0.8;
}
"""

# Partículas y sprites de Érebo: StandardMaterial3D sin luz, transparencia alfa, color de vértice y textura radial.
PARTICULA = """
shader_type spatial;
render_mode blend_mix, unshaded, cull_back;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap;
void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	albedo_tex *= COLOR;
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA = albedo.a * albedo_tex.a;
}
"""

SH = {
	"cuerpo_disolucion": C["SHADER_CUERPO"],
	"cuerpo_entero": CUERPO_ENTERO,
	"charco": C["SHADER_CHARCO"],
	"orbe": C["SHADER_ORBE"],
	"particula": PARTICULA,
}

if __name__ == "__main__":
	res = {}
	lineas = ["sombreador          etapa:pasada        ciclos  aritm.  l/s   tex   reg  (ZS tardío / cobertura)"]
	for nombre, cod in SH.items():
		s = E.spec(cod)
		defs = E.VARIANTES["bajo_base"]
		for etapa in ["vert", "frag"]:
			r = E.resumen(E.malioc(E.armar(s, etapa, s["defines"] + defs), etapa, "erebo_%s" % nombre), etapa)
			res["%s|%s" % (nombre, etapa)] = r
			for p in r["pasadas"]:
				z = ("ZS tardío" if r["zs_tardio"] else "") + (" cobertura" if r["modifica_cobertura"] else "") if etapa == "frag" else ""
				lineas.append("%-19s %s:%-12s %6.2f%s %6.2f %5.2f %5.2f  r%s  %s" % (nombre, etapa, p["variante"], p["ciclos"],
					"*" if p["solo_total"] else " ", p["aritmetica"], p["carga_guardado"], p["textura"], p["registros"], z))
	lineas.append("(* = con bucles de longitud desconocida: ciclos totales, no del camino más largo)")
	json.dump(res, open(os.path.join(TRABAJO, "malioc_erebo.json"), "w"), indent=1)
	open(os.path.join(TRABAJO, "malioc_erebo.txt"), "w", encoding="utf-8").write("\n".join(lineas) + "\n")
	print("\n".join(lineas))
