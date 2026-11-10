extends RefCounted
# Avisos cortos de «El bosque que no recuerda» (fase 3, narrativa, 10/11): Pastos Verdes 3D tras pv_14
# (docs/fase3_bosque/AVENTURA_JUGABLE.md). Cada texto es una frase para el aviso en pantalla o el registro del combate:
# dos líneas de la caja como mucho. Sin Érebo, sin Final Fantasy X. «objetivo_pistas» lleva %d (pistas halladas).
# Uso: const TextosBosque := preload("res://dialogos/notas/bosque.gd") y TextosBosque.TEXTOS["manantial"].

const TEXTOS := {
	# Exploración
	"arbol_marcado": "Un árbol de corteza gris. Unas runas pálidas laten despacio bajo la piel.",
	"rec_hierba_lunar": "Hierba lunar: crece junto al agua y brilla un poco en la sombra.",
	"rec_musgo_piedra": "Musgo de piedra: áspero y frío, agarrado a la roca desde hace siglos.",
	"rec_savia_clara": "Savia clara: gotas limpias de un árbol sano. Huele a lluvia.",
	"ramas_bloqueadas": "Ramas caídas, enredadas y pesadas. Detrás parece que sigue un camino.",
	"manantial": "Agua fría y limpia. El grupo recupera fuerzas y Lya llena la cantimplora.",
	"manantial_ya": "Ya habéis bebido. El manantial seguirá aquí la próxima vez.",
	"ciervo": "Un ciervo de niebla cruza el claro… y se deshace en cuanto os acercáis.",
	"cofre_senda": "Un cofre de peregrino, escondido al final de la senda.",
	"guardian_dormido_pronto": "Algo enorme duerme entre las raíces. Aún no sabéis qué es… ni qué le pasa.",
	"claro_purificado": "El claro está en flor. Entre las raíces brota un manantial nuevo.",
	"claro_derrotado": "Un tocón enorme y callado. Las runas se han apagado.",
	# Registro del combate contra el Guardián
	"elixir_fase1": "El elixir resbala por la corteza. Aún está demasiado fuerte.",
	"purificacion": "La savia empapa las raíces. ¡El Guardián vuelve en sí!",
	"fase2": "¡El bosque entero despierta!",
	# Objetivo en pantalla
	"objetivo_pistas": "Busca más señales del olvido (%d/3).",
}
