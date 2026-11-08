# TASKS: tareas de AETHELGARD / REBELUM

**Actualizado el 2026-11-08 a las 23:05 (hora local, UTC+1).**
- Copia del usuario: `rebelum-3d` @ `b8e042d` (la protección del guardado, [D-066](DECISIONS.md#d-066)).
- Árbol del encargo: `rebelum-alpha` @ `375cc8c` (el prólogo, T-081).
- Desde las 22:00, organización por especialistas: [T-082](#t-082) a [T-088](#t-088).

**Estados**
- **Pendiente:** sin empezar.
- **En curso:** con trabajo activo.
- **Bloqueada:** espera una decisión, un permiso o un dispositivo del usuario, o está en pausa por orden suya.
- **Terminada:** con evidencia comprobable.

**Reglas de este archivo**
- Los identificadores son estables y no se reutilizan.
- Una tarea terminada sin evidencia vuelve a pendiente.
- Una prueba que nadie ha ejecutado figura como pendiente.

**Cuidado con la palabra «fase»:** hay tres numeraciones distintas. Están explicadas en el glosario de
[MEMORIA_CHAT.md](MEMORIA_CHAT.md#glosario-de-fases).

## Resumen

| ID | Tarea | Estado | Prioridad |
|---|---|---|---|
| [T-001](#t-001) | Sistema de memoria y continuidad | Terminada (sin confirmar en Git) | — |
| [T-002](#t-002) | Publicar la memoria en `memoria-desarrollo` | Terminada; se repite en cada hito | — |
| [T-010](#t-010) | Fase 2.0 del plan 3D: preparación segura | Terminada | — |
| [T-011](#t-011) | APK experimental local | Terminada (compilada) | — |
| [T-012](#t-012) | APK «Prueba 3D» de Pastos Verdes | Terminada (compilada) | — |
| [T-020](#t-020) | Encargo, Fase 0: línea base, respaldo y diagnóstico | Terminada | — |
| [T-021](#t-021) | Pastos Verdes 3D desde el mapa (encargo 2.1-2.2; plan 2.3-2.4) | Terminada en PC; falta el móvil | Alta |
| [T-022](#t-022) | Región 3D completa (encargo 2.3-2.5; plan 2.4-2.5) | Hecha en el PC (misión, grupo activo, cofre, mirador, objetivo y combate real); faltan escuchar y el Redmi | Alta |
| [T-023](#t-023) | Cierre del perfil bajo: precalentado y sombra precalculada (plan 2.1) | En curso: tirones de diálogos y de la primera vez, arreglados en el PC; faltan el Redmi y la sombra | Media |
| [T-024](#t-024) | Métricas de referencia y matriz de cobertura | Pendiente | Media |
| [T-025](#t-025) | Entrada: mando, teclado y foco; Android TV (plan 2.2) | En curso: hecha en el PC con eventos simulados (`e6e52c4`); faltan el Redmi, un teclado y un mando reales, los ajustes y la TV | Media |
| [T-026](#t-026) | Combate híbrido: coste de las ventanas 3D | Pendiente | Baja |
| [T-027](#t-027) | Preset de exportación para PC | Pendiente | Baja |
| [T-030](#t-030) | Audio unificado (Fase 2.6) | En curso: buses, volúmenes, ajustes y gestor con ambientes CC0 hechos (`40fb5b8`); faltan música con permiso, efectos y la escucha | Media |
| [T-040](#t-040) | Magia aditiva, estados, tablero, habilidades e IA | Pendiente | Media |
| [T-050](#t-050) | Invocaciones nuevas, cinemáticas y VFX | Pendiente | Baja |
| [T-051](#t-051) | Nueva invocación de Érebo (Fase 2.7) | Bloqueada (decisiones) | Media |
| [T-060](#t-060) | Optimización continua y cierre técnico | Pendiente | Media |
| [T-061](#t-061) | Activar por defecto las optimizaciones de vegetación | Bloqueada (autorización) | Media |
| [T-062](#t-062) | Césped distribuible en lugar de EmacE | Pendiente | Media |
| [T-063](#t-063) | Créditos de Meshy y paquete entregable | Pendiente | Media |
| [T-070](#t-070) | Licencias pendientes (inventario hecho) | Bloqueada (usuario) | Alta |
| [T-071](#t-071) | Decisiones narrativas de la biblia v3 | Bloqueada (usuario) | Media |
| [T-072](#t-072) | Decisiones D1-D12 de la cinemática de Érebo | Bloqueada (usuario) | Media |
| [T-073](#t-073) | Decisiones D1-D7 sobre las Skills | Bloqueada (usuario) | Baja |
| [T-074](#t-074) | Preguntas de GitHub y pre-releases | Bloqueada (usuario) | Baja |
| [T-075](#t-075) | Commit del bloque B | Bloqueada (usuario) | Media |
| [T-076](#t-076) | Que una sesión sin partida cargada no pise la partida completa | Terminada en alpha (`86a58af`) y en la copia habitual (`b8e042d`) | — |
| [T-077](#t-077) | `prueba_guardado` con un archivo propio | Terminada en alpha (`86a58af`) | — |
| [T-078](#t-078) | Validar las APK en el Redmi | Bloqueada (usuario): la v54 ya está en sus Descargas ([D-065](DECISIONS.md#d-065)); falta instalarla y probarla | Media |
| [T-079](#t-079) | Repositorio privado para descargar las APK de prueba en el móvil | Terminada | — |
| [T-080](#t-080) | Decidir la nivelación automática de quien se une al grupo (D-062) | Bloqueada (usuario) | Baja |
| [T-081](#t-081) | El primer diálogo: presentación, cámara, texto y gestos (encargo del 08/11 por la noche) | En curso (prólogo hecho, `375cc8c`) | Alta |
| [T-082](#t-082) | Organización por especialistas: coordinador y cinco subagentes (encargo del 08/11, 22:00) | En curso | Alta |
| [T-083](#t-083) | Sonido: primera tanda de efectos de la biblioteca del usuario en eventos reales | En curso (tanda 1) | Alta |
| [T-084](#t-084) | Animaciones: la mano de Kael en el diálogo inicial y gestos naturales | En curso (tanda 1) | Alta |
| [T-085](#t-085) | Gráficos: el mapamundi (costas, agua, relieve, biomas, lugares y rótulos) | Pendiente | Alta |
| [T-086](#t-086) | Narrativa: el diálogo inicial y la misión de Pastos Verdes | Pendiente | Media |
| [T-087](#t-087) | Combate: estabilidad con uno, dos y tres héroes y eventos sonoros de ataque e impacto | Pendiente | Media |
| [T-088](#t-088) | GitHub: rama de integración y ramas por área, con revisión antes de cada push | En curso (tanda 1 subida) | Alta |
| [T-089](#t-089) | Mejorar todas las ciudades del juego (encargo del 08/11, 23:05) | Pendiente | Alta |
| [T-090](#t-090) | Muchos sitios nuevos que explorar, coherentes con el canon y el mapamundi | Pendiente | Alta |
| [T-091](#t-091) | Magias nuevas, sin cambiar las existentes | Pendiente | Alta |
| [T-092](#t-092) | Equipo nuevo: accesorios y armas especiales (encargo del 08/11, 23:35) | Pendiente | Alta |
| [T-093](#t-093) | Enemigos nuevos, con identidad táctica | Pendiente | Alta |
| [T-094](#t-094) | Compañeros de viaje: propuesta y versión que no cambie el canon | Pendiente | Media |

## Continuidad

### T-001
**Sistema de memoria y continuidad**
- **Estado:** terminada. Detalle y evidencia en [docs/memory/archive/2026-11-08_tareas_terminadas.md](docs/memory/archive/2026-11-08_tareas_terminadas.md#t-001).

### T-002
**Publicar la memoria en `memoria-desarrollo`**
- **Estado:** terminada. Detalle y evidencia en [docs/memory/archive/2026-11-08_tareas_terminadas.md](docs/memory/archive/2026-11-08_tareas_terminadas.md#t-002).

## Fase 2.0 y compilaciones

### T-010
**Fase 2.0 del plan 3D: preparación segura**
- **Estado:** terminada. Detalle y evidencia en [docs/memory/archive/2026-11-08_tareas_terminadas.md](docs/memory/archive/2026-11-08_tareas_terminadas.md#t-010).

### T-011
**APK experimental local**
- **Estado:** terminada. Detalle y evidencia en [docs/memory/archive/2026-11-08_tareas_terminadas.md](docs/memory/archive/2026-11-08_tareas_terminadas.md#t-011).

### T-012
**APK «Prueba 3D» de Pastos Verdes**
- **Estado:** terminada. Detalle y evidencia en [docs/memory/archive/2026-11-08_tareas_terminadas.md](docs/memory/archive/2026-11-08_tareas_terminadas.md#t-012).

## Encargo único (reanudado el 07/11 a las 16:30: ver [D-046](DECISIONS.md#d-046))

### T-020
**Encargo, Fase 0: línea base, respaldo y diagnóstico**
- **Estado:** terminada. Detalle y evidencia en [docs/memory/archive/2026-11-08_tareas_terminadas.md](docs/memory/archive/2026-11-08_tareas_terminadas.md#t-020).

### T-021
**Pastos Verdes 3D accesible desde el recorrido normal (encargo: Fase 1, puntos 2.1-2.2; plan 3D: 2.3-2.4)**
- **Estado:** terminada. Detalle y evidencia en [docs/memory/archive/2026-11-08_tareas_terminadas.md](docs/memory/archive/2026-11-08_tareas_terminadas.md#t-021).

### T-022
**Región 3D completa (encargo: Fase 1, puntos 2.3-2.5; plan 3D: 2.4-2.5)**
- **Estado:** en curso desde el 2026-11-07. **Prioridad:** alta. **Dependencias:** T-021. **Decisión:**
  [D-052](DECISIONS.md#d-052).
- **Hecho** (`e212400`, rama `rebelum-alpha`): la misión del corte alfa.
  - PV-02 al entrar y PV-03 en el camino.
  - Tilo, el farolero (figura provisional), junto al puente: PV-05, su recordatorio, PV-14 con la mecha y la despedida.
  - La estela del camino (detalle de lore «pastos_estela»).
  - El centinela del mirador: PV-06, el combate fijo «pastos_centinela» con dos Grimfang, y PV-07 al ganarlo.
  - Botón «Hablar con Tilo» o «Examinar».
  - **Pruebas:** `prueba_ruta_alpha`, nueva, recorre la misión entera con Dialogic de verdad y el combate fijo
    cargado. Batería `2026-11-07_170431`: **19 superadas, 0 fallidas**, 10 manuales y 0 no seguras.
  - **APK:** `D:\REBELUM_compilaciones\Aethelgard_exp-20261107-07ac036.apk`, de 244,7 MB.
    - SHA-256 `f63e99b18f5172705454d12ec25e693ae35beacd2e29848925f018cb6cf444b9`.
    - Es de prueba privada, con el aviso `NO_DISTRIBUIR`.
- **Hecho el 2026-11-08** (`65fda8b` y `3976565`, rama `rebelum-alpha`): **Lya y Garon siguen a Kael**
  ([D-055](DECISIONS.md#d-055)).
  - `zonas3d/grupo_3d.gd`, que la región crea si los dos están en el grupo de la partida.
  - El botón GRUPO mide lo que cuestan.
  - **Pruebas** (batería `2026-11-08_163510`): **20 superadas, 0 fallidas**, 11 manuales y 0 no seguras. La partida
    real no cambió.
    - `prueba_grupo3d`, nueva, recorre el camino, cruza el puente y da media vuelta sobre él: Lya queda a 1,80 m como
      mucho de Kael y Garon a 1,93 m de Lya; nadie pisa zonas prohibidas, flota ni atraviesa a otro. También comprueba
      que reaparecen detrás de Kael y que con «grupo»: false no salen.
    - `prueba_grupo3d_fotos`, nueva, saca 14 capturas en los perfiles bajo y alto. Revisadas a ojo
      (`D:\REBELUM_diagnostico\pruebas\2026-11-08_163228\prueba_grupo3d_fotos`): siguen en fila por el puente y se
      apartan en la media vuelta.
    - Con las capturas se corrigieron dos cosas: la separación pasó de 1,5 a 1,8 m, y Garon, quieto, ya no apunta a
      Lya con las espadas.
  - **Coste medido en el PC** (banco GRUPO, sin tope, a 20 m; `D:\REBELUM_diagnostico\sondas\2026-11-08_163317`):

    | Perfil | Sin grupo | Con grupo | Diferencia |
    |---|---|---|---|
    | bajo | 2,8 ms | 3,2 ms | +0,4 ms, +6 dibujos, +44k triángulos y +46 MB de vídeo |
    | medio | 3,0 ms | 3,4 ms | +0,4 ms |
    | alto | 3,1 ms | 3,6 ms | +0,5 ms |

    Con el tope de 30 FPS, el bajo con grupo da 30,1 FPS sin tirones. Son datos del PC; falta medir en el Redmi.
  - **APK:** `Aethelgard_exp-20261108-3976565.apk` (versionCode 41), subida como «08/11/2026 · Prueba v41»
    ([T-079](#t-079)).
    - SHA-256 `8f3f52ef4275c85c20672e3aa0e44236a5e1068e460c71238e4180d636392188`.
- **Hecho el 2026-11-08 por la tarde** (`d4db508` y `21d2e21`, rama `rebelum-alpha`):
  - **El cofre del árbol mágico** ([D-057](DECISIONS.md#d-057)). `prueba_cofre3d` comprueba:
    - que Kael llega andando desde el puente;
    - el premio una sola vez (50 monedas) y el sonido sin saturar;
    - que sigue abierto tras guardar (en el archivo de verdad de la prueba), un combate real con vuelta, volver a
      entrar y cargar la partida.
  - **La cinemática del mirador** ([D-058](DECISIONS.md#d-058)). `prueba_mirador` comprueba:
    - la primera vez, con el hito guardado antes de terminar;
    - que no hay control y que vuelven la cámara y el control;
    - que no se repite en una visita posterior;
    - saltarla con Escape, tras lo que no suena nada más.
  - **Capturas** (`prueba_region3d_fotos`, `D:\REBELUM_diagnostico\pruebas\2026-11-08_171143`): cofre y cinemática en
    bajo y alto, revisadas a ojo. Por ellas se giró el cofre y se subieron los planos de la cinemática.
  - **Batería `2026-11-08_171230`: 23 superadas, 0 fallidas**, 12 manuales y 0 no seguras. La partida real no cambió.
  - **APK:** subida como «08/11/2026 · Prueba v44» (`exp-20261108-21d2e21`) ([T-079](#t-079)).
- **Hecho después** (`3d5f63d`, [D-059](DECISIONS.md#d-059)):
  - el grupo se une con la misión;
  - el objetivo en pantalla y el rombo dorado.
  - **`prueba_grupo3d_rutas`**, nueva: 3 series de destinos al azar, alcanzables y con semilla fija, más sitios
    difíciles, medias vueltas y la cámara a 9, 20 y 34 m.
    - Kael anda 181 m y llega a todos los destinos.
    - En cada fotograma: 0 zonas prohibidas, 0 fuera del suelo, 0 obstáculos atravesados y 0 rezagados; dos
      fotogramas juntos.
    - Comprueba también que en el juego normal se cuentan los pasos: los encuentros siguen activos. Solo las pruebas
      los ponen a 0.
  - **`prueba_centinela`**, nueva: el combate del centinela **jugado de verdad** (ataques automáticos, `-- auto`).
    - El grupo inicial lo gana en 64 s de juego y pasa de 150 a 186 monedas; se guarda.
    - Después: cinemática, PV-07, PV-14, salir al mapa, volver y cargar, sin repetir nada.
    - **Alcance:** ataques automáticos, sin magias ni objetos. No prueba la estrategia de un jugador.
  - `prueba_ruta_alpha` comprueba quién acompaña a Kael y el objetivo en cada paso de la misión.
  - **Batería `2026-11-08_172719`: 25 superadas, 0 fallidas** y 12 manuales.
- **Medido en el PC** (08/11, 17:30; `pruebas/medir_ruta.gd`, commit `3d5f63d`):
  - **Condiciones:** el mismo recorrido para todas (andar, puente ida y vuelta, cofre, Tilo, entrada al combate,
    combate y vuelta), los mismos fotogramas (`--fixed-fps 30`), sin tope, a 1280×720 y con un proceso por condición.
  - **Equipo:** Ryzen 7 4800H, RTX 3050 Laptop, 16 GB, Godot 4.7.2.
  - **Datos:** `D:\REBELUM_diagnostico\mediciones\2026-11-08_ruta_grupo\` (`comparacion.md` y los JSON).

  | Fase | Bajo, mediana (p95) | Alto, mediana (p95) |
  |---|---|---|
  | andar | 2,93 → 3,42 ms (17,7 → 19,1) | 3,27 → 3,68 ms (20,4 → 19,0) |
  | puente | 2,92 → 3,56 ms (3,5 → 4,7) | 3,24 → 3,85 ms (3,7 → 4,5) |
  | interacción | 2,91 → 3,33 ms (3,5 → 4,1) | 3,21 → 3,73 ms (3,9 → 4,5) |
  | combate | 4,07 → 3,97 ms (el grupo no está) | 3,87 → 3,93 ms |

  - **Con el grupo:** +46 MB de memoria de vídeo (texturas de los dos modelos) y +6 dibujos y +43k triángulos en bajo
    (+12 y +86k en alto). La carga de la región pasa de 1,7 a 2,2 s.
  - **Coste identificado y arreglado** (`ce2094b`): generar el sonido del cofre al abrirlo daba un tirón de unos 180 ms.
    Ahora se prepara al cargar, y el p99 de la interacción baja de 33 a 6 ms.
  - **Costes identificados y sin tocar:**
    - la primera vez que se abre un diálogo de Dialogic, unos 180 ms (con y sin grupo);
    - al empezar a andar, el p95 sube a unos 18 ms con picos de 50 ms, con y sin grupo. Probablemente son sombreados
      que se compilan (T-023).
  - **Solo orienta:** el PC no es el Redmi. Lo que cuesta el grupo allí se mide con el banco GRUPO.
- **APK:** «08/11/2026 · Prueba v47» (`exp-20261108-091d1d1`) ([T-079](#t-079)).
- **Hecho después** (`e670a5d`, [D-060](DECISIONS.md#d-060)), a petición del usuario («Sí. Antes de que Lya se una en
  PV-03, los combates aleatorios deben ser solo de Kael…»):
  - el grupo activo es la fuente común de la exploración, el combate, los menús, la tienda y el guardado;
  - los encuentros al azar dependen de cuántos son, para que Kael solo pueda ganarlos;
  - avisos del guardado y la opción de desarrollo «Probar la misión desde el principio», en otra ranura.
  - **Pruebas:** `prueba_grupos_combate` (grupos de 1, 2 y 3), `prueba_partida` (casos 7 y 8) y
    `prueba_ranura_prueba`. Batería `2026-11-08_175301`: **27 superadas, 0 fallidas** y 13 manuales.
- **Después, los tirones** (`e630b02`, [D-061](DECISIONS.md#d-061)): ver [T-023](#t-023).
- **APK:** «08/11/2026 · Prueba v50» (`exp-20261108-36502e9`) ([T-079](#t-079)).
- **Falta:**
  - **escuchar** el sonido del cofre y las campanas;
  - la opinión visual del usuario y medir el grupo en el Redmi (botón GRUPO);
  - revisar con ventana el aspecto de Tilo, la estela y las salidas.
- **Objetivo:**
  - NPC, diálogos, interacción, cofres y encuentros.
  - De la zona al combate y de vuelta, tras ganar, huir o perder, sin resolver dos veces el mismo encuentro o botín.
  - Guardado y carga de partidas antiguas y nuevas, con campos ausentes y vuelta al 2D.
- **Criterio de aceptación:**
  - Un recorrido reproducible desde el flujo experimental, con las pruebas aisladas registradas.
  - Del plan 3D, punto 2.5:
    - la misión de PV-02 a PV-14 se completa en el PC;
    - los hitos sobreviven a guardar y cargar;
    - `prueba_dialogos` y `prueba_ruta_alpha` salen en verde.

### T-023
**Cierre del perfil bajo: precalentado de sombreados y sombra precalculada (plan 3D: 2.1)**
- **Estado:** en curso. **Prioridad:** media.
- **Hecho el 2026-11-08 por la tarde** (`e630b02`, [D-061](DECISIONS.md#d-061)), medido en el PC con
  `pruebas/medir_primeras_veces.gd` (pantalla de carga real, dos pasadas, primer arranque y con caché; datos en
  `D:\REBELUM_diagnostico\primeras_veces\comparacion.md`):
  - **Diálogos:** la interfaz de Dialogic se prepara oculta en la pantalla de carga y se reutiliza. El primer diálogo
    pasa de 184 a 9-11 ms y cada uno de los siguientes, de 54-56 a 6-7 ms.
  - **Al andar:** los árboles que tapan a Kael usan una copia transparente guardada, y una vitrina dibuja en la entrada,
    en negro, cada material de la escena. El primer paseo pasa de picos de 41 ms (tras instalar) y 19 ms (con caché) a
    4-5 ms; cada oclusión, de unos 11 a 3-4,7 ms.
  - **Lo que crece:** la pantalla de carga, un fotograma de unos 30 ms; la entrada en la región, en negro, unos
    0,1-0,2 s en el PC.
  - **Pruebas:** `prueba_dialogo_interfaz`, nueva. Batería `2026-11-08_184433`: **28 superadas, 0 fallidas** y
    16 manuales; capturas de la región, del grupo y del diálogo revisadas, iguales que antes.
  - **Falta:** medirlo en el Redmi (tiempos de carga, tirones que queden y si la caché de sombreados funciona en el
    Mali-G57), y la sombra precalculada.
- **Dependencias:** necesita el Redmi para medir (T-078).
- **Contexto [historial]:** el perfil bajo daba unos 34,5 ms de mediana en el Redmi, todavía sin 30 FPS estables.
- **Medido en el Redmi el 2026-11-08** (región 3D, APK `989d35e`, sin seguidores):
  - **TOPE** (con el tope de 30 FPS), bajo a 20 m: **30,1 FPS**, p95 de 34,0 ms y 0 % de tirones.
  - **PRUEBA** (sin tope), bajo a 20 m: mediana de **21,5 ms** (cumple ≤ 31) y p95 de **38,4 ms** (se pasa de ≤ 38 por
    0,4 ms). A 34 m: 27,1 y 49,6 ms.
  - **Sin medir:** los picos de más de 100 ms y el tiempo de carga.
  - **Registros:** `D:\REBELUM_diagnostico\redmi_2026-11-08_region\`. Las tablas completas están en el relevo
    archivado ([docs/memory/archive/2026-11-08_relevo_anterior.md](docs/memory/archive/2026-11-08_relevo_anterior.md)).
  - **Cuidado al leerlo** (corrección del 08/11): que la mediana sin tope sea 21,5 ms no garantiza unos 12 ms libres
    dentro de los 33,3 ms de 30 FPS. Cuentan el p95 (38,4 ms), los picos, la memoria y las cargas. Lo que cueste el
    grupo hay que medirlo en el Redmi (banco GRUPO).
  - **Siguiente:** precalcular la sombra para bajar el p95 sin tope, y medir en el Redmi los picos y las cargas.
  - **Candidatos medidos en el PC el 08/11** (`medir_ruta.gd`; ver [T-022](#t-022)), ya arreglados en `e630b02`:
    - picos de unos 50 ms al empezar a andar (sombreados que se compilan);
    - unos 180 ms la primera vez que se abre un diálogo de Dialogic.
- **Criterio de aceptación** (plan 3D, punto 2.1), medido en el Redmi con el escenario y Kael en bajo:
  - mediana ≤ 31 ms y p95 ≤ 38 ms;
  - ningún pico > 100 ms después del precalentado;
  - carga de la escena ≤ 4 s;
  - sin pérdida visual;
  - el perfil alto queda intacto ([D-020](DECISIONS.md#d-020)).

### T-024
**Métricas de referencia y matriz de cobertura**
- **Estado:** pendiente. **Prioridad:** media.
- **Objetivo:** lo que piden las fases 0 y 5 del encargo:
  - FPS, mediana y percentil 95 del tiempo por fotograma, y picos;
  - memoria, llamadas de dibujo, tiempos de carga y tamaño de la APK;
  - una matriz breve de cobertura por fase.
- **Criterio de aceptación:** una tabla en `docs/` con el equipo, la escena, el perfil y el resultado. No se atribuyen al
  móvil resultados medidos en el PC.

### T-025
**Entrada: mando, teclado y foco; Android TV (plan 3D: 2.2)**
- **Estado:** **hecha en el PC con eventos simulados** (`rebelum-alpha` @ `e6e52c4`, 08/11 a las 19:55). Falta
  validarla con hardware: el Redmi, un teclado y un mando reales. Android TV, después. **Prioridad:** media.
- **Criterio de aceptación** (plan 3D, punto 2.2):
  - el juego 2D se juega entero solo con un DS4: inicio, mapa, zona, combate, menús y diálogos;
  - el táctil sigue funcionando como hoy;
  - `prueba_mando`, `prueba_foco` y las pruebas táctiles salen en verde.
- **Objetivo:** jugar con DualShock 4, teclado o pantalla táctil, con menús navegables por foco. Después, Android TV
  (Ugoos SK1).
- **Hecho el 2026-11-08 por la noche** (rama `rebelum-alpha`, [D-063](DECISIONS.md#d-063)), con prioridad para
  Android y PC:
  - acciones de teclado y mando, el autoload `Entrada` y el foco visible;
  - exploración, ventanas, combate, diálogos y pantalla de carga sin ratón;
  - una pulsación, una acción; el mando desconectado deja seguir.
  - **Pruebas nuevas** (todas con eventos **simulados**: teclas y botones de mando de verdad inyectados en Godot):
    - `prueba_foco`: menús, tienda, diario, barra del mapa, ciudad y mando desconectado;
    - `prueba_mando` y `prueba_teclado`: el recorrido sin ratón, desde la pantalla de carga (partida de prueba) hasta
      el mapa, con PV-02, andar, la cámara, hablar con Tilo y un combate;
    - `prueba_precalentado`: lo que se prepara antes de jugar no provoca nada de juego;
    - `prueba_dialogo_interfaz`, ampliada: opciones, señales y una pulsación, una acción (con control: sin el filtro,
      falla).
  - **Táctil:** `prueba_toque`, `prueba_dpad` y las de la región siguen en verde; la prueba de las capturas con el dedo
    enseña el menú sin el marco del foco.
  - `prueba_grupos_combate` exige la experiencia exacta que reparte `combate.gd`, y que huir o perder no den
    ninguna. Fallaba al azar: si el único enemigo del grupo 7 (un Slime cobarde) huye, se gana sin experiencia, como
    manda el juego.
  - **El ejecutor** apunta cualquier Godot que no haya lanzado y da la hora de cada cambio de la carpeta real. Al
    pasarse de tiempo una prueba, solo cierra lo suyo ([D-010](DECISIONS.md#d-010)).
- **Evidencia** (ejecutado aislado; batería `2026-11-08_195103`, sobre lo que es `e6e52c4`): **32 superadas, 0
  fallidas**, 17 manuales y 0 no seguras. La partida real, la carpeta real de datos y el proyecto, sin cambios; ningún
  otro Godot.
  - `prueba_foco_fotos` (con ventana, `2026-11-08_195003`): 7 capturas revisadas a ojo. El marco dorado se ve en la
    carga, la barra del mapa, el menú del grupo, el «+» de un atributo, la ciudad y la tienda; con el dedo no sale.
  - `prueba_grupos_combate`, tres pasadas sueltas en verde; en una se repitió el Slime huido del grupo 7.
- **APK:** «08/11/2026 · Prueba v52» (`exp-20261108-edf52cd`, [T-079](#t-079)), para la prueba táctil en el Redmi.
- **Pruebas manuales abiertas** (no las puedo hacer yo: aquí no hay mando, y el Redmi está reservado):
  1. **Redmi, táctil:**
     - andar tocando y con la cruceta;
     - los botones de la barra, «Entrar» y la acción;
     - diálogos con «SEGUIR»;
     - el combate tocando (filas, deslizar ATACAR, pestañas de magia, objetivo, saltar la invocación);
     - menús, tienda y diario.
     - Comprobar que al tocar no sale el marco dorado y que la barra no se queda con el foco.
  2. **Teclado real en el PC:** el recorrido sin ratón (Intro, Esc, Tab, flechas, WASD, Q / E y + / -).
  3. **Mando real** (DS4 o de tipo Xbox), en el PC y en Android por Bluetooth:
     - que cada botón haga lo que dice la tabla de D-063;
     - una desconexión de verdad y su aviso.
  4. **A ojo, tu opinión:** las capturas del foco las revisé yo (lámina en
     `D:\REBELUM_diagnostico\pruebas\2026-11-08_195003\prueba_foco_fotos\lamina_foco.png`); falta la tuya.
  5. **Android TV** (Ugoos SK1) y su mando a distancia: más adelante.
- **Falta:**
  - más ajustes: ya hay una pestaña «Ajustes» con el sonido ([T-030](#t-030)); faltan los de controles y gráficos;
  - los textos de combate en modo mando («TOCA UN ENEMIGO»);
  - los iconos por mando;
  - pausa y salir con Atrás fuera del combate;
  - Android TV.
- **Plan:** [docs/entrada/android_tv_dualshock4_plan.md](docs/entrada/android_tv_dualshock4_plan.md).

### T-026
**Combate híbrido: coste de las ventanas 3D**
- **Estado:** pendiente. **Prioridad:** baja.
- **Objetivo:** medir lo que cuestan los SubViewports por personaje antes de cambiar la arquitectura (Fase 1 del
  encargo).

### T-027
**Preset de exportación para PC**
- **Estado:** pendiente. **Prioridad:** baja.
- **Objetivo:** el encargo pide probar el ejecutable de PC exportado, y hoy no hay preset para Windows.

### T-030
**Audio unificado (Fase 2.6; Fase 4 del encargo)**
- **Estado:** **en curso.** Hechos en `rebelum-alpha` la base técnica (`e44fb9e`, [D-064](DECISIONS.md#d-064)) y el
  gestor de música y ambiente con ambientes CC0 (`40fb5b8`, [D-067](DECISIONS.md#d-067)). Faltan música con permiso
  para la exploración, efectos nuevos y la escucha. **Prioridad:** media.
- **Hecho después, el gestor** ([D-067](DECISIONS.md#d-067), `40fb5b8`): contexto por escena y lugar, fundidos, la
  misma pista sin reiniciar al volver, el combate con su música y la exploración siguiendo donde iba, pausa de la app y
  silencio controlado donde no hay pista con permiso. Inventario de cada sonido: `docs/audio/inventario_sonidos.md`
  (en `rebelum-alpha`), con asignación, señal y escucha por separado.
  - **Evidencia:** `prueba_musica` (muda, con el recorrido real mapa → Oakhaven → combate → mapa); `prueba_musica_senal`
    (con ventana: ambientes de −29 a −39 dBFS, combate −20 dBFS, carga en silencio; WAV para escuchar en
    `D:\REBELUM_diagnostico\pruebas\2026-11-08_210056\prueba_musica_senal\`); batería `2026-11-08_210443`: 35
    superadas y 1 fallida (`prueba_choque`, un encuentro al azar ajeno al cambio; corregida y en verde tres veces).
  - **APK:** «08/11/2026 · Prueba v57» (`exp-20261108-40fb5b8`), también en las Descargas del Redmi.
  - **Pendiente de verificar:** la escucha, en el PC y en el Redmi (cortes del bucle, volumen frente a la música,
    siseo del bosque).
- **Hecho el 2026-11-08 por la noche** ([D-064](DECISIONS.md#d-064)):
  - buses Musica, Efectos, Interfaz y Ambiente (`default_bus_layout.tres`); cada sonido en el suyo, y el sonido al
    escribir de Dialogic, en Interfaz;
  - volúmenes de 0 a 100 % (autoload `Sonido`), guardados en `user://ajustes.cfg`, aparte de la partida, solo al
    cambiarlos;
  - pestaña «Ajustes» en el menú del grupo, con ◀ ▶, la cifra, una barra y una muestra corta del bus al cambiarlo.
    También cubre los «ajustes» que faltaban en [T-025](#t-025) (solo el sonido).
  - **Evidencia** (ejecutado aislado): `prueba_audio`, **muda** (adónde va cada sonido y con qué volumen, no cómo
    suena); batería `2026-11-08_201034`: 33 superadas y 0 fallidas; captura de la pestaña revisada a ojo.
  - **Medido en el PC:** la primera pulsación en Música, unos 18 ms con 6 fotogramas incluidos. Con la campana del
    mirador como muestra eran unos 180 ms, y se cambió.
  - **Pendiente de verificar:** escucharlo en el PC y en el Redmi (que cada volumen se note y que al 100 % suene como
    antes).
  - **APK:** «08/11/2026 · Prueba v54» (`exp-20261108-2776729`, [T-079](#t-079)).
- **Dependencias:** un flujo jugable estable (T-021 y T-022). Para distribuir algo, además, las licencias (T-070).
- **Objetivo:**
  - Buses y un gestor de música.
  - Música para el mapa, las zonas, la isla, la mazmorra, el título, Pastos Verdes y los jefes.
  - Efectos de sonido para ataques, impactos, magia, objetos, victoria, derrota, pasos, cofres, puertas y menús.
- **Criterio de aceptación:**
  - Cada evento suena una sola vez.
  - La escucha en el PC se registra aparte de la ejecución muda.
  - Inventario de cada sonido: original, recurso derivado, evento, licencia y evidencia.
- **Referencias:**
  - [D-043](DECISIONS.md#d-043) y [docs/audio/](docs/audio/);
  - el ZIP de Suno: `C:\Users\G513\Downloads\Telegram Desktop\Aethelgard_Musica_Pastos_Verdes_Godot.zip`;
  - la biblioteca `D:\qtorrent\sound effect`, con 157 candidatos.

### T-040
**Magia aditiva, estados, tablero, habilidades e IA (Fase 2 del encargo)**
- **Estado:** pendiente. **Prioridad:** media. **Regla:** [D-048](DECISIONS.md#d-048): el catálogo actual no cambia.
- **Criterio de aceptación:**
  - Regresiones del catálogo actual antes y después.
  - Identificadores estables.
  - Las partidas antiguas siguen cargando.
- **Propuestas de partida:** en [MEMORIA_CHAT.md](MEMORIA_CHAT.md).

### T-050
**Invocaciones nuevas, cinemáticas y VFX (Fase 3 del encargo)**
- **Estado:** pendiente. **Prioridad:** baja.
- **Dependencias:** el canon que decida el usuario (T-071).

### T-051
**Nueva invocación de Érebo (Fase 2.7)**
- **Estado:** bloqueada: faltan las decisiones D1-D12 (T-072). **Prioridad:** media.
- **Plan:** [docs/erebo/invocacion_erebo_plan_final.md](docs/erebo/invocacion_erebo_plan_final.md) y
  [docs/erebo/invocacion_erebo_cinematica.md](docs/erebo/invocacion_erebo_cinematica.md).
- **Criterio de aceptación:**
  - Se cumplen las reglas de [D-038](DECISIONS.md#d-038).
  - La animación no decide el daño dos veces.
  - El salto deja la misma resolución.

### T-060
**Optimización continua y cierre técnico (Fase 5 del encargo)**
- **Estado:** pendiente. **Prioridad:** media.
- **Metas:** 30 FPS en el perfil ligero del Redmi y 60 FPS en un PC capaz ([D-021](DECISIONS.md#d-021)).

### T-061
**Activar por defecto las optimizaciones de vegetación (LOD, mallas indexadas y sombras C+)**
- **Estado:** bloqueada: necesita la autorización del usuario ([D-025](DECISIONS.md#d-025)). **Prioridad:** media.

### T-062
**Césped distribuible en lugar de EmacE**
- **Estado:** pendiente. **Prioridad:** media.
- **Objetivo:** un césped con licencia clara para la app, como matas opacas más densas, porque EmacE no se puede
  redistribuir.

### T-063
**Créditos de Meshy y paquete entregable**
- **Estado:** pendiente. **Prioridad:** media. **Decisión:** [D-050](DECISIONS.md#d-050).
- **Objetivo:** que algún día pueda haber una APK **entregable**.
- **Pasos:**
  1. Una pantalla o un archivo de créditos con la atribución de Meshy: «Model created with Meshy – CC BY 4.0 License».
     Con ella, los modelos de Meshy se pueden distribuir con cualquier plan (las condiciones están en el inventario).
  2. Un preset o un modo del script de compilación que **se niegue** a compilar si queda dentro algo de
     `licencias_pendientes.txt`.
- **Dependencias:** las respuestas del usuario en T-070.
- **Criterio de aceptación:** una compilación entregable sin ningún patrón de `licencias_pendientes.txt`.

## Decisiones y recursos que dependen del usuario

### T-070
**Licencias pendientes**
- **Estado:** bloqueada: depende del usuario. **Prioridad:** alta.
- **Inventario hecho el 2026-11-07:** `D:\Aethelgard_alpha\docs\versiones\inventario_licencias.md` (commit `e8b9ed4`,
  rama `rebelum-alpha`).
  - Tiene 13 grupos con derechos pendientes. Para cada uno dice qué usos bloquea: commit, prueba privada o APK
    entregable.
  - Recoge las condiciones de Meshy y de Suno, leídas ese día en sus páginas oficiales.
  - `licencias_pendientes.txt` tiene ya los patrones que faltaban.
- **Meshy:**
  - Con el plan gratuito, CC BY 4.0 (uso comercial con atribución). Con plan de pago, los modelos son del usuario.
  - Con los créditos (T-063), se pueden distribuir con cualquiera de los dos planes.
  - **Falta que el usuario confirme** que las imágenes que subió a Meshy eran suyas o libres.
- **Suno:**
  - Con el plan gratuito, solo uso personal no comercial. Suscribirse después no da derechos retroactivos.
  - **El 08/11 el usuario dijo:** «la música de suno no son libres».
    - Las cuatro pistas se tratan como no libres: solo en pruebas privadas locales, nunca en commits ni en APK que salgan
      del PC, tampoco en el repositorio de pruebas.
    - Para el juego publicado harían falta pistas generadas y descargadas con un plan de pago durante la suscripción,
      o sustitutas.
- **Falta confirmar:**
  - el plan de Meshy (personajes, armas, árboles y guardián);
  - con qué se sustituyen las cuatro pistas de Suno en una APK entregable, o si se generan de nuevo con plan de pago;
  - «The Last Encounter» (CC-BY-SA 3.0) y la recopilación «500 Game Sound Effects»;
  - el origen de `sonidos/erebo_*.wav` y `musica_combate_normal.mp3`;
  - el origen de `espada2.obj`, `hacha.obj`, `hoja_infernal.obj`, `vara.obj`, `averno.obj` y `diamante_azul.obj`, que
    no figuran en `docs/recursos.md`.
- **Criterio de aceptación:**
  - Cada recurso tiene su licencia y su evidencia en [docs/recursos.md](docs/recursos.md).
  - [docs/versiones/licencias_pendientes.txt](docs/versiones/licencias_pendientes.txt) está al día.

### T-071
**Decisiones narrativas de la biblia v3**
- **Estado:** bloqueada: depende del usuario.
- **Qué falta:** las 12 preguntas de §8.2 y las 16 decisiones de §10.7 de
  [docs/biblia/rebelum_biblia_narrativa_v3.md](docs/biblia/rebelum_biblia_narrativa_v3.md).

### T-072
**Decisiones D1-D12 de la cinemática de Érebo**
- **Estado:** bloqueada: depende del usuario.
- **Dónde:** [docs/erebo/invocacion_erebo_cinematica.md](docs/erebo/invocacion_erebo_cinematica.md).

### T-073
**Decisiones D1-D7 sobre las Skills**
- **Estado:** bloqueada: depende del usuario.
- **Dónde:** [docs/herramientas/propuesta_skills.md](docs/herramientas/propuesta_skills.md). Las 26 Skills `aet-*` están
  desfasadas.

### T-074
**Preguntas de GitHub y pre-releases**
- **Estado:** bloqueada: depende del usuario.
- **Dónde:** [docs/versiones/automatizacion_prereleases.md](docs/versiones/automatizacion_prereleases.md).

### T-075
**Commit del bloque B**
- **Estado:** bloqueada: depende del usuario ([D-006](DECISIONS.md#d-006)).

### T-076
**Que una sesión sin partida cargada no pise la partida completa**
- **Estado:** terminada. Detalle y evidencia en [docs/memory/archive/2026-11-08_tareas_terminadas.md](docs/memory/archive/2026-11-08_tareas_terminadas.md#t-076).

### T-077
**`prueba_guardado` con un archivo propio**
- **Estado:** terminada. Detalle y evidencia en [docs/memory/archive/2026-11-08_tareas_terminadas.md](docs/memory/archive/2026-11-08_tareas_terminadas.md#t-077).

### T-078
**Validar las APK en el Redmi**
- **Estado:** bloqueada: el usuario conecta el móvil cuando lo decida ([D-013](DECISIONS.md#d-013)).
- **Primera validación hecha el 2026-11-08** ([D-053](DECISIONS.md#d-053)):
  - la APK experimental `989d35e`, instalada por el usuario desde Descargas, se instala aparte de la app estable;
  - Pastos Verdes 3D funciona;
  - los bancos PRUEBA y TOPE dan los resultados de [T-023](#t-023).
  - **Faltan** la opinión visual del usuario y validar el control táctil a fondo.
- **Qué validar:**
  - que se instala junto a la app estable sin tocar sus datos;
  - el arranque;
  - Pastos Verdes 3D;
  - el rendimiento del perfil bajo;
  - el control táctil.

### T-079
**Repositorio privado para descargar las APK de prueba en el móvil**
- **Estado:** terminada. Detalle y evidencia en [docs/memory/archive/2026-11-08_tareas_terminadas.md](docs/memory/archive/2026-11-08_tareas_terminadas.md#t-079).

### T-080
**Decidir la nivelación automática de quien se une al grupo**
- **Estado:** bloqueada: espera la decisión del usuario. **Prioridad:** baja.
- **Contexto:** en `e670a5d` puse que Lya y Garon llegaran al nivel del más alto al unirse. El usuario pidió
  comprobarlo, y esa regla no existía en el juego: se quitó el 08/11 por la noche y quien se une conserva sus datos
  ([D-060](DECISIONS.md#d-060)). Queda como propuesta: [D-062](DECISIONS.md#d-062).
- **Comprobado:** `prueba_grupos_combate` comprueba que unirse no cambia ningún dato y que los combates de dos y tres
  héroes se ganan con todos en el nivel 1.
- **Para cerrarla:** que el usuario decida si la quiere (y si también «llegar descansado»).

### T-081
**El primer diálogo: presentación, cámara, texto y gestos (encargo del 08/11 por la noche)**
- **Estado:** en curso. El prólogo está hecho y probado (`375cc8c`, [D-068](DECISIONS.md#d-068)). Falta poder verlo
  en el Redmi (el botón de desarrollo «Probar el prólogo», diseñado en [SESSION_HANDOFF.md](SESSION_HANDOFF.md)) y
  revisarlo en el teléfono. Sigue en [T-084](#t-084) y [T-086](#t-086). **Prioridad:** alta.
- **Petición** [usuario]: «El diálogo que aparece al abrir el juego me parece pobre. Quiero mejorar su presentación y
  las animaciones de los personajes.» Primero localizarlo arrancando con una partida aislada (partida nueva y
  existente), observarlo con ventana y guardar capturas o vídeo de referencia; después mejorar esa conversación
  completa antes de extender el estilo.
- **Alcance:** entrada que sitúe al jugador, encuadres y pausas con intención; respiración, miradas, gestos breves y
  reacciones sin que todos se muevan siempre; texto de Dialogic legible en móvil (tipografía, contraste, márgenes,
  interlocutor, indicador de continuar, opciones); saltar la secuencia y recuperar cámara y control.
- **Reglas:** conservar los hechos del argumento, hitos, recompensas y canon (se pueden pulir frases manteniendo su
  sentido y la voz de cada personaje); una pulsación por acción (una completa la frase, la siguiente avanza); misión
  separada de las animaciones; medir antes y después; capturas antes/después.
- **Evidencia** (22:00, `375cc8c`, comprobado ejecutando y aislado): `prueba_prologo` (entero, saltar en el diálogo y
  saltar en la entrada) y la batería completa: 37 superadas, 0 fallidas, 19 manuales y 0 no seguras
  (`D:\REBELUM_diagnostico\pruebas\2026-11-08_214904\resumen.md`). Capturas antes y después y medidas en
  `D:\REBELUM_diagnostico\prologo_antes_despues\` ([D-068](DECISIONS.md#d-068)). Sin probar en el Redmi.

### T-082
**Organización por especialistas: coordinador y cinco subagentes (encargo del 08/11, 22:00)**
- **Estado:** en curso. **Prioridad:** alta. **Responsable:** el coordinador.
- **Petición** [usuario]: «Organiza el desarrollo de AETHELGARD mediante subagentes especializados, con un agente
  principal que coordine, revise e integre su trabajo.» Áreas: gráficos, sonido, narrativa, combate y animaciones.
- **Criterio de aceptación:**
  - comprobado qué subagentes admite la versión instalada y con qué aislamiento;
  - los cinco especialistas, configurados en `.claude/agents/` con el formato admitido y usados de verdad al delegar;
  - cada uno con su copia de trabajo, su rama y su informe en `docs/memory/agents/`;
  - sin compilaciones, importaciones ni medidas que compitan.
- **Reglas:** [D-069](DECISIONS.md#d-069).
- **Evidencia** (22:25, comprobado ejecutando):
  - subagentes reales, en segundo plano, con aviso al terminar;
  - los cinco especialistas en `.claude/agents/especialista-*.md` (commit `1c17763` en `integracion-experimental`);
  - **límite:** esta sesión no reconoce los tipos propios porque la carpeta no existía al empezar («Agent type
    'especialista-sonido' not found»). Se usan subagentes `general-purpose` que leen su archivo como instrucciones;
  - el `isolation: worktree` parte de `main`: en su lugar, copias de trabajo manuales con la caché `.godot` copiada;
  - tanda 1 lanzada a las 22:27 (sonido y animaciones).

### T-083
**Sonido: primera tanda de efectos de la biblioteca del usuario en eventos reales**
- **Estado:** en curso desde las 22:27 (tanda 1), en `D:\Aethelgard_sonido`, rama `area-sonido`. **Prioridad:** alta.
  **Responsable:** especialista de sonido.
- **Petición** [usuario]: aprovechar `D:\qtorrent\sound effect` para que las acciones del juego tengan respuesta
  sonora. Pasos e interacción; ataques físicos, impactos y defensas; cofres, puertas, objetos y recompensas; victoria,
  derrota y menús; río, cascada, viento y naturaleza; habilidades nuevas y eventos narrativos autorizados.
- **Criterio de aceptación:**
  - inventario y candidatos revisados, y licencia comprobable de cada efecto;
  - una primera tanda integrada desde eventos reales (no toda la biblioteca), con derivados optimizados y los
    originales intactos;
  - los buses actuales; volúmenes, límites de sonidos simultáneos y prioridades;
  - probadas las repeticiones, cancelaciones, pausa, cambio de escena y silencio;
  - una tabla por efecto: fuente, recurso, evento, licencia y evidencia;
  - si no se puede escuchar, se dice y se preparan muestras.
- **Reglas:** el catálogo mágico no cambia; si sonorizar una magia exige cambiar su presentación, se deja para una
  decisión aparte. Nada de Suno en APK ni en GitHub.

### T-084
**Animaciones: la mano de Kael en el diálogo inicial y gestos naturales**
- **Estado:** en curso desde las 22:27 (tanda 1), en `D:\Aethelgard_animaciones`, rama `area-animaciones`.
  **Prioridad:** alta. **Responsable:** especialista de animaciones.
- **Petición** [usuario]: revisar la pose de Kael «con la mano junto a la cabeza mientras habla Lya». Encontrar la
  causa (clip, duración, transición, mezcla, esqueleto o pose procedural) y corregirla.
  - Gestos naturales: reposo cómodo, miradas a quien habla, reacciones breves, transiciones suaves, pies apoyados y
    armas en su sitio, sin movimiento constante.
  - Conservar el resaltado de quien habla.
- **Hallazgo previo** (22:00, observado en el archivo): en el prólogo, la mano está en la propia ilustración
  `dialogos/retratos/kael.png`, la única de Kael.
- **Criterio de aceptación:**
  - la causa, demostrada, y la secuencia completa, comprobada en movimiento;
  - comprobado avanzar rápido, saltar, reabrir el diálogo y volver al juego;
  - capturas comparables y, si se puede, un vídeo corto antes/después.

### T-085
**Gráficos: el mapamundi**
- **Estado:** pendiente (tanda 2). **Prioridad:** alta. **Responsable:** especialista de gráficos.
- **Petición** [usuario]: «La captura muestra costas escalonadas, grandes manchas planas y poco detalle geográfico.»
  - Analizar cómo se genera y se dibuja antes de elegir la técnica. No basta con ampliar la imagen.
  - Lo que pide: costas cuidadas, agua con profundidad, relieve, montañas, bosques y biomas; ciudades, caminos y lugares
    legibles; iconos y rótulos coherentes; composición y paleta para el móvil.
- **Criterio de aceptación:**
  - destinos, identificadores, conexiones, posiciones funcionales, encuentros y progreso, iguales;
  - una comparación visual que oriente la implementación;
  - comprobado a la resolución del juego y al tamaño de la pantalla del Redmi;
  - memoria, carga y tiempos por fotograma, medidos;
  - la procedencia de cada recurso, registrada;
  - el mapa actual se conserva como alternativa hasta que el nuevo supere las pruebas.

### T-086
**Narrativa: el diálogo inicial y la misión de Pastos Verdes**
- **Estado:** pendiente (tanda 2, con animaciones). **Prioridad:** media. **Responsable:** especialista de narrativa.
- **Petición** [usuario]: más ritmo, claridad y personalidad.
  - Quitar repeticiones y frases difíciles de leer en el móvil.
  - Las personalidades guían reacciones y gestos; la intención de cada intervención se coordina con animaciones.
- **Criterio de aceptación:**
  - canon, hitos, recompensas y restricciones de revelación, intactos; los cambios grandes, como propuestas;
  - continuidad comprobada con Kael solo, la incorporación de Lya y la llegada de Garon: el texto, los personajes
    presentes y el estado de la misión coinciden.

### T-087
**Combate: estabilidad y respuesta**
- **Estado:** pendiente (tanda 3, con sonido). **Prioridad:** media. **Responsable:** especialista de combate.
- **Petición** [usuario]:
  - encuentros con uno, dos y tres héroes, niveles reales de incorporación y controles;
  - objetivos válidos, personajes ausentes, victoria, huida, derrota, recompensas y vuelta a la exploración;
  - con sonido: que el ataque y el impacto suenen una sola vez y a la vez que la resolución real.
- **Reglas:**
  - no cambian las magias, Esgrima, Embuir, Érebo, la Armonía ni la progresión autorizada;
  - la nivelación automática sigue retirada ([T-080](#t-080));
  - no se tocan fórmulas para acomodar animaciones.

### T-088
**GitHub: rama de integración y ramas por área**
- **Estado:** en curso: primera publicación hecha (22:20). **Prioridad:** alta. **Responsable:** el coordinador.
- **Petición** [usuario]: [D-070](DECISIONS.md#d-070).
- **Criterio de aceptación:**
  - antes de cada push, el repositorio privado comprobado y los archivos y diferencias, revisados;
  - nada de secretos, partidas, cachés, exportaciones del chat, archivos ajenos, APK, bibliotecas completas ni
    binarios grandes;
  - los permisos de publicación de los recursos, comprobados; lo que no se pueda publicar, documentado con ruta local,
    procedencia y requisitos;
  - sin force push ni pushes simultáneos.
- **Evidencia, primera publicación** (22:20, comprobado ejecutando):
  - subidas `integracion-experimental`, `area-sonido` y `area-animaciones` @ `1c17763`, comprobadas con
    `git ls-remote`;
  - lo nuevo para GitHub: 220 archivos y 30,3 MB, casi todo código y textos. Los únicos binarios son los cinco
    ambientes CC0 de 5-6 MB ([D-067](DECISIONS.md#d-067));
  - sin secretos, partidas, APK ni Suno;
  - el repositorio sigue privado, con un solo usuario y sin invitaciones;
  - Git LFS está instalado, pero el repositorio no lo usa, así que no se activa.

### T-089
**Mejorar todas las ciudades del juego**
- **Estado:** pendiente: va después de las tandas 1 a 3. **Prioridad:** alta. Decisión: [D-071](DECISIONS.md#d-071).
- **Petición** [usuario, 08/11, 23:05]: «quiero que mejores todas ciudades del juego quiero un juego ambicioso».
- **Criterio de aceptación:**
  - inventario de las ciudades que existen (2D y 3D) y de lo que tiene cada una;
  - mejora visible de composición, vida (NPC, detalle, luz) y legibilidad en el móvil, con antes y después;
  - funciones intactas: tiendas, posadas, NPC, misiones, entradas y salidas;
  - rendimiento medido antes y después.

### T-090
**Muchos sitios nuevos que explorar**
- **Estado:** pendiente: va después de las tandas 1 a 3. **Prioridad:** alta. Decisión: [D-071](DECISIONS.md#d-071).
- **Petición** [usuario, 08/11, 23:05]: «con muchos sitios para explorar».
- **Criterio de aceptación:**
  - lugares nuevos coherentes con el canon (biblia v2) y con el mapamundi, cada uno con algo que hacer: secretos,
    cofres, combates o vistas;
  - accesibles desde el juego y con las conexiones probadas;
  - lo que cambie la historia va como propuesta;
  - rendimiento medido.

### T-091
**Magias nuevas, sin cambiar las existentes**
- **Estado:** pendiente: va con la tanda de combate o después. **Prioridad:** alta. Decisión:
  [D-071](DECISIONS.md#d-071).
- **Petición** [usuario, 08/11, 23:05]: «crea más magias».
- **Criterio de aceptación:**
  - cada magia nueva, con una función táctica clara, acceso desde el juego (quién la aprende y cuándo), coste,
    objetivos, animación y sonido coherentes;
  - las doce existentes, Esgrima, Embuir, Érebo, la Armonía y el ATB, sin cambios;
  - pruebas, y compatibilidad con las partidas antiguas.
- **Ampliado (23:35):** «CRE DIREFERENTES MAGIAS INSPIRATE EN EXPEDITION 33 Y FINAL FANTASY Y OTROS JUEGOS RPG».
  Solo principios, sin copiar nombres, diseños ni escenas ([D-072](DECISIONS.md#d-072)).

### T-092
**Equipo nuevo: accesorios y armas especiales**
- **Estado:** pendiente: va con la tanda de combate o después. **Prioridad:** alta. Decisión:
  [D-072](DECISIONS.md#d-072).
- **Petición** [usuario, 08/11, 23:35]: «AÑADE TAMBIEN ACESORIOS CREA ARMA ESPECIALES».
- **Criterio de aceptación:**
  - accesorios y armas especiales con efectos claros, que se consigan en el juego (cofres, tiendas o secretos) y se
    equipen desde un menú con teclado, mando y táctil;
  - sin equipo, el combate da los mismos resultados que hoy, y las pruebas de equilibrio no cambian;
  - partidas antiguas compatibles (claves nuevas al final y valores por defecto);
  - pruebas.

### T-093
**Enemigos nuevos, con identidad táctica**
- **Estado:** pendiente: va con la tanda de combate o después. **Prioridad:** alta. Decisión:
  [D-072](DECISIONS.md#d-072).
- **Petición** [usuario, 08/11, 23:35]: «ENEMIGOS».
- **Criterio de aceptación:**
  - cada enemigo nuevo, con un patrón y una debilidad que se puedan leer en combate;
  - coherente con su lugar y con el mundo; modelo o figura y animación reutilizados o creados con las herramientas
    locales, con su procedencia;
  - los encuentros ya probados de Pastos Verdes no cambian sin pruebas;
  - rendimiento medido.

### T-094
**Compañeros de viaje**
- **Estado:** pendiente. **Prioridad:** media. Decisión: [D-072](DECISIONS.md#d-072).
- **Petición** [usuario, 08/11, 23:35]: «AMIGOS DE VIAJE».
- **Criterio de aceptación:**
  - una propuesta de compañeros (quiénes son, de dónde salen, qué aportan), marcada como propuesta para la biblia;
  - el grupo jugable (Kael, Lya y Garon) no cambia sin la decisión del usuario;
  - mientras, solo acompañantes que no toquen el canon (un guía o un NPC que acompaña un tramo), si encajan.
