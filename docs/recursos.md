# Recursos externos de Aethelgard (origen y licencia)

Antes de meter un modelo, textura o sonido en el juego se anota aquí. Si la licencia prohíbe redistribuir los
archivos originales, solo se guarda en Git el resultado convertido.

| Recurso | Origen | Licencia / condición | Dónde se usa | Original en Git |
|---|---|---|---|---|
| Kael, Lya, Garon, Érebo, Grimfang (modelos) | Meshy (cuenta del autor) | Según el plan de Meshy del autor | Combate | Sí |
| Movimientos de doble espada (Garon) | Pack «Dual-Blade Combat Essentials» (Patreon, Drop 38) | Uso comercial permitido; prohibido redistribuir los archivos | `garon_espadas.res` (convertido) | **No** (solo el convertido) |
| Sprites de vegetación `decorado/quaternius/` | Quaternius | CC0 (ver `LICENCIA_CC0.txt`) | Zonas 2D | Sí |
| Árboles y arbustos de Meshy (arce, abedul, glicinia, perenne, arbusto, helecho, guardián) | Meshy (cuenta del autor) | Según el plan de Meshy del autor (pendiente de confirmar) | Fase 2, en evaluación | Pendiente |
| Logo de REBELUM | Imagen aportada por el autor | Del autor | `marca/rebelum_logo.webp` (pantalla de título de prueba) | Sí |
| Textura de matas de hojas | Generada por código (`pruebas/herramientas/textura_hojas.gd`) | Propia | `modelos/hojas/matas.png` | Sí |
| Stylized Nature MegaKit [Standard] (selección de árboles, arbustos, flores y helecho) | Quaternius | CC0 (`vegetacion_prueba/quaternius/LICENSE_Quaternius.txt`) | `vegetacion_prueba/` (prueba aislada, experimental) | Pendiente (se subirá solo lo que se use, cuando se decida la vegetación). El ZIP original ya no está en Descargas (no aparece en el equipo, comprobado el 2026-11-06) |
| Stylized Grass v1.3.0 (mata, sombreado de viento, texturas) | EmacEArt | Uso personal y comercial permitido en proyectos propios; **prohibido vender o redistribuir los archivos**, ni solos, ni modificados, ni dentro de otro paquete (`vegetacion_prueba/emace/LICENSE_EmacEArt.txt`) | `vegetacion_prueba/` (prueba aislada; perfil alto) | **No**, ni siquiera en el repositorio privado: `aethelgard/vegetacion_prueba/emace/` está en `.gitignore`. Copia local en `vegetacion_prueba/emace/`; el ZIP original ya no está en Descargas |
| Ambientes `audio/ambiente/` (pradera, bosque, viento, mazmorra, desierto) | Colección «500 GAME SOUND EFFECTS» de la biblioteca del autor (`D:\qtorrent\sound effect`), con la fuente de cada archivo: isaiah658 «Ambient Bird Sounds», Luke.RUSTLTD «wind1», Pixel-boy «Superpowers assets sound effects» y JaggedStone «Loopable Dungeon Ambience» (OpenGameArt) | CC0, comprobado en cada página de OpenGameArt el 2026-11-08 | Ambientes de cada lugar (`musica.gd`); bucles hechos con `pruebas/herramientas/preparar_ambientes.gd` | Sí (los bucles convertidos; los originales se quedan en la biblioteca). Detalle en `docs/audio/inventario_sonidos.md` |
