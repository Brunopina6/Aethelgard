# ESTADO DE LA DIRECTIVA V9 — «Operación Renacimiento Total» (10/11/2026)

**Rama:** LOCAL `claude/rebelum-v9` (`D:\Aethelgard_v9`), creada desde la **v293 verificada** (`dca4c1c`). El trabajo
posterior se recuperó tras examinarlo (`AUDITORIA_BASE.md`). **Sin push ni fusión:** la directiva pide «commits
claros en GitHub», pero CLAUDE.md exige tu autorización expresa para subir esta rama.

**Leyenda:**
- **Hecho** = implementado y probado automáticamente en el PC;
- **Parcial** = una parte;
- **Pendiente** = sin empezar;
- **Redmi** = falta probarlo en el teléfono.

## Hitos

| Hito | Estado | Qué hay | Dónde |
|---|---|---|---|
| 1. Seguridad y auditoría | **Hecho** | v293 verificada (release = commit = versionCode 293); rama nueva; cambios posteriores examinados | `docs/v9/AUDITORIA_BASE.md` |
| 2. Primer jefe regional | **Hecho** (Redmi) | Guardián del Bosque Olvidado, el primer jefe regional del juego:<br>• modelo 3D propio de Blender con 8 animaciones;<br>• dos fases con avisos;<br>• coraza de raíces y debilidad al fuego;<br>• dos desenlaces;<br>• premios exclusivos sin duplicar;<br>• reintento;<br>• persistencia | `combate.gd`, `combate_bosque.gd`, `enemigos/guardian_bosque/`, `prueba_guardian_bosque`, `prueba_guardian_modelo` |
| 3. Aventura del orbe | **Hecho** (Redmi) | Altar con orbe en las ruinas: muestra los dos futuros del bosque (purificado y caído), y verlos adelanta la investigación de Lya. Propuesta experimental: **pendiente de canon** | `zonas3d/bosque_pastos.gd`, `dialogos/bosque/bq_orbe_*.dtl`, `prueba_bosque_pastos` |
| 4. Profesiones | **Hecho** (Redmi) | Ver la tabla de abajo | `talleres.gd`, `alquimia_menu.gd`, `datos/`, `prueba_oficios` |
| 5. Oakhaven: tienda y consecuencia | **Hecho** (Redmi) | Doña Encina según el desenlace; la tienda de Oakhaven vende Hierba lunar, Savia clara y Musgo de piedra según el desenlace | `ciudades/oakhaven.gd`, `tienda.gd`, `prueba_tienda_bosque` |
| 6. Expansión 3D | **Hecho** (Redmi) | El Claro del Guardián, sector de Blender y obra propia: corro de menhires con runas, raíces, tocón-trono y tres estados (dormido, purificado y derrotado); kit ligero para los perfiles medio y bajo | `zonas3d/bosque/`, `prueba_claro_guardian` |
| 7. Combate y personajes | **Parcial** | **Escalado de enemigos hecho:** base y tope por región, jefes con margen propio, en la base igual que antes (huella idéntica); `combate_escalado.gd`, `prueba_escalado`. El arquetipo de magia negra está **pendiente**: en `grupo.gd` hay un «Mago negro» (Nyx) antiguo que hay que revisar antes | rama `claude/v9-escalado` |
| 8. Más jefes (Coloso, Campanero) | **Parcial** | **Coloso de la Falla hecho** (Redmi): jefe opcional de la Garganta 3D, al fondo de la grieta pasado el pilar del peregrino.<br>• Modelo 3D de Blender, obra propia (9 042 triángulos, 8 clips).<br>• Fase 1: piel de piedra y ventanas de vulnerabilidad tras su golpe cargado (Kael hace más daño).<br>• Fase 2: runas ámbar y coraza rúnica alterna.<br>• «Leer runas» de Garon.<br>• Premio único: Mineral rúnico y Fragmento de armadura antigua; reintento.<br>**El Campanero del Porvenir está pendiente.** | `combate_coloso.gd`, `enemigos/coloso_falla/`, `zonas3d/garganta/coloso.gd`, `prueba_coloso`, `prueba_coloso_garganta` |
| 9. Contenido opcional (Emperador Slime, encargos) | **Parcial** | **Sistema de encargos hecho:** registro de todas las regiones con el formato de misiones de Oakhaven y pestaña Encargos en el Diario.<br>• Encargos: el bosque, los futuros del orbe, noticias para Encina y **«Canela se ha perdido»** (Pip, huellas, la senda de Garon, Canela os sigue, recompensa única y Pip cambia).<br>**El Emperador Slime está pendiente.** | `encargos.gd`, `datos/encargos_pastos.gd`, `diario.gd`, `prueba_encargos` |
| 10. Pulido | **Parcial** | **Identidad sonora del Guardián** (sonido; licencias Sonniss GDC):<br>• voz de corteza, latido, raíces, rugido y derrumbe;<br>• purificación;<br>• tratamiento por etapas del combate y bosque antiguo;<br>• orbe.<br>El Coloso usa la voz de piedra; sus efectos propios están pendientes. **Nadie lo ha escuchado aún.** | `sonido.gd`, `audio/efectos/guardian/`, `prueba_audio_guardian` |

## Profesiones (hito 4)

| Oficio | Investigación | Recetas o mejoras |
|---|---|---|
| Lya (alquimia) | «Concentración arcana» y «La savia que recuerda» (con la ventaja contra el Guardián) | Poción restauradora, Esencia de enfoque y Elixir de savia purificada: **tres recetas con efecto real** |
| Kael (forja) | «El filo del bosque» | Filo de savia (+3 de ataque, **mejora**) y Corte certero (+8 % de crítico, **técnica**) |
| Garon (runas) | «Runas de corteza» | Refuerzo de corteza (+3 de defensa, **mejora defensiva**) y Runa de raíz (coraza al empezar, **encantamiento**) |
| Conjunto | «Lo que aprendimos del bosque» (pide las investigaciones de los tres) | Amuleto del claro (**fabricación cooperativa**) |

**Conexiones:**
- con la exploración: los materiales de Pastos Verdes y el orbe;
- con el jefe: se abren al resolverlo;
- con la tienda: el musgo y las hierbas de Encina.

## Criterios de entrega de la V9

| Criterio | Estado |
|---|---|
| Rama desde la v293 correcta | Hecho |
| Primer jefe funcional, dos fases, animaciones y efectos, recompensa exclusiva, victoria persistente | Hecho (Redmi pendiente) |
| Interacción con el orbe y primera consecuencia narrativa | Hecho |
| Una investigación profesional y una mejora de equipo | Hecho (varias) |
| Primer comercio funcional | Hecho (la tienda de siempre, con mercancía según el desenlace) |
| Un sector 3D ampliado | Hecho: el Claro del Guardián |
| Pruebas funcionales y de regresión | Hecho: batería completa, 95 superadas y 0 fallidas (`D:REBELUM_diagnosticopruebas�6-11-10_172904`) |
| Comparación de rendimiento con la v293 | Parcial: el arranque en el Redmi se midió con la v418 (19-21 s, frente a 22-25 s esta mañana); la aventura, sin medir en el teléfono |
| Commits en GitHub | Pendiente de tu autorización |
| APK de pruebas | Compilada en local: v471, `D:REBELUM_compilacionesAethelgard_androidauditora-20261110-6356807.apk` (280,0 MB, SHA-256 `6d9ec5d2…`); sin instalar |
