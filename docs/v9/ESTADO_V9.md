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
| 6. Expansión 3D | **En curso** | Gráficos construye con Blender el Claro del Guardián (arena del jefe, tres estados) | rama `claude/v9-sector` |
| 7. Combate y personajes | **Parcial** | Escalado de enemigos por región, en curso (combate). El arquetipo de magia negra está **pendiente**: en `grupo.gd` hay un «Mago negro» (Nyx) antiguo que hay que revisar antes | rama `claude/v9-escalado` |
| 8. Más jefes (Coloso, Campanero) | **Pendiente** | Solo diseño (directiva V9) | — |
| 9. Contenido opcional (Emperador Slime, encargos) | **Pendiente** | El sistema de encargos reutilizable, sin hacer | — |
| 10. Pulido | **Parcial** | Capturas revisadas, árbol marcado con el estilo de la región y textos de la alquimia. Falta sonido y música propios del Guardián | — |

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
| Un sector 3D ampliado | En curso (gráficos) |
| Pruebas funcionales y de regresión | Hecho: batería completa, ver `docs/v9/RETOMAR.md` |
| Comparación de rendimiento con la v293 | Parcial: el arranque en el Redmi se midió con la v418 (19-21 s, frente a 22-25 s esta mañana); la aventura, sin medir en el teléfono |
| Commits en GitHub | Pendiente de tu autorización |
| APK de pruebas | Se compila en local al cerrar la tanda |
