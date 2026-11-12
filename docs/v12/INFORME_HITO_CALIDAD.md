# Informe final del «Siguiente hito de calidad» (12/11/2026)

Rama local `claude/rebelum-v12` en `D:\Aethelgard_v12`. Sin push, sin fusiones, sin releases. Punto de recuperación
anterior al hito: etiqueta `v12-antes-hito-calidad` (= `a0bab37`).

## 1. Qué cambió y en qué commit

| N.º | Encargo | Commit | Resultado |
|---|---|---|---|
| 1 | Validar en Android | `8645218`, `e4fe384`, `97e3006` | v646, v649 y v656 medidas en el Redmi (abajo) |
| — | Gran Bosque Verde optimizado (salió de la validación) | `e8f59cb` | Copas sin tramado; 14 → 21-25 FPS en medio, 27 → 30 en bajo |
| 2 | Cargas sin esperas a ciegas | `a23e131` | Precarga filtrada; aviso «Preparando el combate…» sin cifras; Bramavidrio preparado al entrar en la región |
| 3 | Pulir Bramavidrio | `a23e131` | Orden de dibujo de la v3 estable; sonidos y efectos revisados |
| 4 | Encuentro nuevo del desierto | `2c0f872` | Vidracrán, **apagado** (`encuentro_desierto_v12`) |
| 5 | Interacción del Mar de Cristal | `514d022` | Rincón opcional «el hito del cobijo» (una vez, 2 Pociones) |
| 6 | Música verificada | `1f9abfa` | Las tres canciones elegidas suenan desde sus rutas reales; SHA-256 iguales a los maestros |
| — | Bramavidrio v4 «el Ancestral» (encargo del usuario con su referencia) | ver RETOMAR | Elegible en Ajustes; **no predeterminado** (`VERSION_DEFECTO` = 2) |

## 2. Propuestas apagadas (no cambian nada mientras estén apagadas)

- `heroes_v2`, `magia_negra_v12`, `naira_v12`, `enemigos_v12`, `npc_desierto_v12` (de la segunda fase).
- `encuentro_desierto_v12`: Vidracrán en el Mar de Cristal y los grupos de prueba 14-16.
- Bramavidrio v1, v3 y v4: se eligen en Ajustes → «Bramavidrio»; por defecto, la v2.
- Pastoral Pulse como música de Pastos Verdes: elegible, no predeterminada.
- Humbaba (`humbaba_v12`): en desarrollo en `claude/v12-humbaba`; aún no integrado.

## 3. Tiempos antes y después (Redmi, Mali-G57)

| Medida | Antes | Después |
|---|---|---|
| Carga del título | 19,2 s (v649) | **10,6 s** (v656) |
| Memoria en la portada | 0,97 GB | **0,77 GB** |
| Memoria en combate | 1,08 GB | **0,83 GB** |
| Del aviso de Bramavidrio al combate | ~18 s de negro (v646) | ≤ 2,5 s (v649) → **~1,5 s** con aviso (v656) |
| Aparición de Bramavidrio | tirón al compilar sombreadores | **sin tirones** (caché de sombreadores en Android) |
| Arranque en PC | 14,8 s | 10,6 s |

## 4. Rendimiento Android medido (sin limitación térmica en ninguna sesión)

| Escena | Bajo | Medio |
|---|---|---|
| Pastos Verdes, Garganta, Oakhaven, Mar de Cristal | 30 | 30 |
| Gran Bosque Verde | 30,4 | **21-25** (sigue por debajo de 30) |
| Combate | 59-60 | 59-60 |

Detalle en `docs/v12/INFORME_REDMI_V12.md` (pruebas 3.ª a 8.ª).

**Sin medir en el teléfono:** Bramavidrio v4, Vidracrán, el rincón del Mar de Cristal y todo lo apagado. El Redmi está
desconectado. Para comparar versiones en Android hay que elegirlas en Ajustes (los argumentos de línea de órdenes no
llegan en Android).

## 5. Pruebas

- Batería completa tras el pulido y las cargas: **132 · 0 · 60 · 0**.
- Tras Vidracrán: 132 · 1 · 60 · 0; la prueba nueva era frágil, se rehízo determinista (3/3 y 2/2).
- Con la v4 integrada: ver RETOMAR (fila de la batería de la v4).

## 6. Problemas que persisten

1. **El Gran Bosque Verde en medio** va a 21-25 FPS, no a 30.
2. **La v4 no es todavía tan fiel como la referencia:** tiene la boca circular con dientes, las crestas de interior rojo,
   las placas de bronce, las runas, las cicatrices y el núcleo ámbar con cuernos, pero la cabeza apenas es más ancha
   que el cuerpo, las crestas son planas y las placas parecen tablillas. Sin mapa de normales. Hojas y vídeos en
   `D:\REBELUM_diagnostico\animaciones\2026-11-12\bramavidrio4\`.
3. **Sonido:** medido por pruebas, no escuchado por una persona (v4 y Vidracrán).
4. **Alias provisional** `naira_eclipse` → «noche» en la magia negra.
5. **Procedencia de las referencias** del gusano y de Humbaba: aportadas por el usuario; licencia sin registrar.

## 7. Estado de la partida

La partida de «REBELUM Auditoría» (`com.aethelgard.auditoria`) se respaldó antes de cada sesión en el Redmi y se
restauró idéntica después (huellas: `ajustes.cfg` `3ee5aaf2…`, `partida_exp.save` `578c1763…`, `.bak` `44e0f5dc…`;
respaldo en `D:\REBELUM_respaldos\2026-11-11_redmi_auditoria_antes_v610`). La aplicación experimental v365 no se
tocó. Las APK copiadas a Descargas se borraron.

## 8. Ramas

- Trabajo: `claude/rebelum-v12` (local).
- Especialistas integrados copiando archivos: `claude/v12-hito-cargas` @ `aa15a08`, `claude/v12-hito-brama-pulido` @
  `bef8e7f`, `claude/v12-hito-mc-interaccion` @ `4a91674`, `claude/v12-hito-encuentro-desierto` @ `9f7052e`,
  `claude/v12-bramavidrio4` @ `acfbb52`.
- En marcha: `claude/v12-humbaba` (desde `2c0f872`).

## 9. Tres prioridades

1. **Ver la v4 y decidir** la versión de Bramavidrio por defecto (y la caída de la Fractura y los sitios de golpe por
   versión). Si la v4 gusta como base, darle otra pasada de esculpido: cabeza más ancha, crestas con volumen y placas
   curvas.
2. **Humbaba**: terminar el prototipo con rig y tres animaciones, enseñarlo y seguir por etapas.
3. **Medir en el Redmi** una APK con la v4, Vidracrán y el rincón (y volver al Gran Bosque en medio).
