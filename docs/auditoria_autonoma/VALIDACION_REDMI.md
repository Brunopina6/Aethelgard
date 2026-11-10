# VALIDACIÓN EN EL REDMI — 10/11/2026

**Dispositivo:** REDMI A7 Pro (Mali-G57, Android 16), por USB y ADB, autorizado. **App de pruebas aparte:**
`com.aethelgard.auditoria` («REBELUM Auditoría»), compilada de esta rama: v386 (`31237e1`) y, tras la corrección,
v387 (`94a6592`). **No se tocaron** la app estable (`com.aethelgard.juego`, v1), la «Prueba 3D»
(`com.aethelgard.prueba3d`, v24) ni la «Exp» (`com.aethelgard.experimental`, v365): ni se desinstalaron, ni se
sobrescribieron, ni se borraron datos. Todas las pruebas de partida, incluida la corrupción a propósito, se hicieron
solo con la partida de la app de pruebas (`run-as`, porque la compilación es depurable), con copia previa.

Capturas: `D:\REBELUM_diagnostico\redmi\2026-11-10_auditoria\`. FPS medidos con los tiempos de presentación de
Android (SurfaceFlinger) y con el banco TOPE del juego.

## Superadas (comprobado en el teléfono)

| Prueba | Resultado |
|---|---|
| Instalación aparte | v386 y v387 instaladas como app nueva; las otras tres apps, intactas |
| Arranque | primero 61 s hasta el menú (compila sombreadores; la v293 tardó 58 s); siguientes 22-25 s |
| Pantalla de carga | logotipo REBELUM y barra; tras la corrección, «TOCA PARA EMPEZAR» |
| Prólogo | sale en partida nueva; la partida guardada a mitad **no** lo da por visto |
| Prólogo interrumpido | cierre forzado a mitad → al volver a abrir, el prólogo sale otra vez |
| Prólogo terminado | recorrido entero con toques (SEGUIR) → `prologo_visto: true`; al volver a abrir, ya no sale |
| Mapa: lugar más cercano | entre Portal del Vacío y Pastos Verdes, con la cruceta: «Cruzar el portal» cerca del portal y «Entrar: Pastos Verdes» en cuanto Pastos queda más cerca (seis pasos) |
| Entrada a Pastos Verdes 3D | primera vez ~24 s (compila sus sombreadores); vuelta a la región tras combate, bien |
| Diálogos con toques | el prólogo y los de la misión avanzan tocando |
| Combate | encuentro real (dos limos): menú, magia Fuego (−8 PM, 23 de daño), ataque del enemigo, HUD (PV, PM, Armonía), victoria y vuelta |
| Recompensas | dos héroes a nivel 2 (18 de experiencia) y 168 monedas en la partida guardada |
| Guardado | la partida guarda `"formato": 2` |
| Partida dañada | contenido roto a propósito → se aparta en «.danada», se carga la copia buena (idéntica a la de seguridad), aviso en pantalla y se sigue jugando |
| Continuar | tras la corrección, la partida guardada sigue donde estaba |
| Registros | sin cierres (búfer de cierres vacío), sin errores de script; solo los avisos esperados de la prueba de corrupción |

## FPS medidos (comparados con las medidas anteriores equivalentes)

| Dónde | Ahora (v386) | Antes (v336/v293, 09/11) |
|---|---|---|
| Pastos Verdes 3D, bajo, 20 m | **30,1** (p95 34,0 ms) | 30,1 (34,0) |
| Pastos Verdes 3D, medio, 20 m | 27,4 (p95 42,0) | 27,1 (42,2) |
| Pastos Verdes 3D, medio, 34 m | 23,1 (p95 47,8) | 23,0 (49,6) |
| Pastos Verdes 3D, alto, 20 m | 10,3 (p95 111,6) | 10,2 (118,4) |
| Combate (menú y Fuego) | **59,9** (p95 17,0) | 59,9 (17,0) |
| Garganta 3D | no medida de nuevo: **su código es idéntico** al de la v365, medida el 09/11 en este Redmi: 59,9 (p95 17,0) | — |
| Memoria en Pastos Verdes 3D | 390-398 MB | 365 MB (v336, con menos contenido integrado) |

## Corregido durante la validación

- **«Mando conectado» y «PULSA INTRO» sin mando** (`entrada.gd`, `94a6592`). El Redmi anuncia como mando su sensor de
  huellas («gf-keys», sin mapa de mando conocido). Con pantalla táctil, el juego ya no empieza en modo mando ni avisa de
  los que Android anuncia al abrir; un mando de verdad sigue funcionando (pasa a modo mando con su primera pulsación).
  Comprobado en el Redmi (v387): «TOCA PARA EMPEZAR», sin aviso, y la partida continúa. Pruebas de entrada en el PC:
  6 de 6.

## Pendiente (no automatizable con fiabilidad o fuera de alcance)

- **Garganta 3D de nuevo en esta compilación:** llegar desde Pastos Verdes con toques a ciegas no fue fiable (Kael se
  atascó bajo un árbol). Vale la medida del 09/11 porque el código es idéntico.
- **Tocar el sensor de huellas durante la partida:** podría mandar una «tecla» y cambiar los textos a los de teclado;
  ahora queda registrado si pasa («Entrada: modo … por …»). Probarlo tocando el sensor.
- **Mando y teclado reales**, audio por el altavoz y temperatura en sesiones largas.
- **Interrupción en mitad de un guardado** en el teléfono: no se puede provocar un fallo real del disco sin riesgo; lo
  cubren las pruebas del PC (`prueba_guardado_fallos`).

## Batería completa en el PC tras la corrección

`ci_local.ps1` (10/11, 12:54): **79 superadas, 0 fallidas**, 41 manuales, 0 no seguras; partida y carpeta real sin
cambios. Resumen: `D:\REBELUM_diagnostico\pruebas\2026-11-10_125416\resumen.md`.

## Recomendación

Se puede fusionar con `integracion-experimental`: todo lo comprobable en el Redmi funciona, no hay regresiones de
rendimiento, la corrección de entrada está probada en el teléfono y la batería completa pasa. Lo pendiente (Garganta
3D con esta compilación, sensor de huellas, mando y teclado reales) no bloquea la fusión.
