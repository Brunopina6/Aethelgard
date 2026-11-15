# Guion de pruebas en el Redmi (15/11) — APK de Auditoría consolidada

> Escrito la noche del 15 al 15/11, sin el teléfono: esta noche NO se ha instalado nada ni se han tocado datos del
> Redmi. Todo lo de abajo está comprobado SOLO en el PC; nada certifica Android.

## PARA MAÑANA (16/11): APK `eb68d54` con las optimizaciones de la muestra — NO instalada (Redmi desconectado)

- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261116-eb68d54-local.apk` (432,0 MB, «TODO CORRECTO»),
  versionCode **854**, SHA-256 `1d318c5e11fed9eec18c95a26379b7bf32624e614662e31ff9efb18319693456`. Copiarla a Descargas
  por USB (comprobar el SHA en el teléfono) y que la instale el usuario. Instalada ahora: v849 (`4eb4f9b`).
- **Antes:** respaldo byte a byte (`adb exec-out run-as … cat`) de ajustes.cfg, partida_exp.save(.bak), calidad.log y
  SHA de los 7 archivos de `files/` (como `D:\REBELUM_respaldos6-11-15_redmi_antes_sesion_2245`).
- **Qué probar (perfil bajo; distinguir SIEMPRE: «Fija ×0,75» (1200×540), «Regulador normal» y resolución completa
  ×1,0 — esta última solo con CAL «alto», y NO declarar calidad completa por medir a ×0,75):**
  1. Primer arranque tras instalar: logcat `[carga]` (tiempo total y «fase de sombreadores») y la 1.ª entrada a la
     muestra (`[tirones] entrada 1 · instanciar→1.er dibujo … dibujo …`, caché +N). Esperado: el primer dibujo ya no
     tarda 1,26 s (los programas de la calle se compilan en la carga) — comprobar, no suponer.
  2. Segundo arranque (caché llena): `[carga]` total frente a la v849 (≈ 14-16 s) — el precalentado no debe alargarla.
  3. Entradas 2.ª y siguientes: fases «materiales y mapa de luz» y «luz.json» (en v849: 6-26 y 6-18 ms) ≈ 0.
  4. Recorrido (puerta, callejón, esquina) con «Fija» y con «Regulador normal»: FPS, picos, PSS al entrar/salir.
  5. Choques: andar contra la puerta verde, subir y bajar los escalones del callejón y los límites (son los de
     siempre: un cuerpo por caja).
- **Al terminar:** salir del banco; los 7 archivos con el mismo SHA SIN restaurar (aislamiento de la calidad).

## MUESTRA GRÁFICA DE LA CALLE en el Redmi (15/11, noche; encargo del usuario tras ver la muestra)

APK de Auditoría compilada desde `3a08f35` (contenido de `e857b93`, validado 189 · 0). La instala el usuario desde
Descargas (MIUI bloquea `adb install`). Estado previo del teléfono en `D:\REBELUM_respaldos6-11-15_redmi_antes_sesion_2100`
(ajustes `3ee5aaf2…`, partida `567c7323…`, copiados byte a byte con `adb exec-out`).
Con el perfil BAJO, desde el banco → «Muestra gráfica: una calle de Oakhaven (en pruebas)»:
1. Recorrido completo: el inicio (oeste), la puerta verde, subir el callejón (escalones, sombra) y la esquina del torreón.
2. Fluidez: `timestats` por tramo (entrada de 9 s y recorrido), media y picos del histograma; objetivo 30 FPS.
3. Memoria: PSS en el banco, al entrar, en la calle y al volver; repetir el ciclo ≥ 5 veces (¿vuelve a la misma base?).
4. Calor: temperatura de batería y estado térmico en cada ciclo, en una sesión de ≥ 10 minutos seguidos.
5. Aspecto en la pantalla real: luz horneada (bandas del ETC2 en los degradados), texturas, faroles de pie encendidos,
   la sombra de Kael y su luz en el callejón.
Al terminar: `ajustes.cfg` restaurado byte a byte, borrar `banco_pruebas.save` si existe, SHA de la partida igual.
Siguen PENDIENTES aunque todo salga bien: el cierre intermitente de Godot (0xC0000005) tras `prueba_banco_pruebas` y la
rareza de las transparencias en bajo/medio (`MUESTRA_CALLE_OAKHAVEN.md` §7).

## INSTALADA (15/11, 17:05): `dc878e9`, versionCode 834 — probada de 17:05 a 17:30

- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261115-dc878e9-local.apk` (425,5 MB),
  SHA-256 `71121b7d06ad220cb8b212df0c0b7e9e522a26029c965649d714c3e3948df964`; copia en Descargas del teléfono con el
  mismo SHA. Batería 188 · 0 (etiqueta `validado/v12/20261115-170245`).
- **Ya probado en el Redmi** (resultados en `REDMI_15_11.md`, sesión 17:05): híbrida abreviada (resistida) y completa
  (éxito), saltar a mitad, contador del Custodio hasta «Sello en 2», grupo de cuatro, mapamundi 3D con viaje rápido y
  vuelta a Oakhaven. Teléfono devuelto al estado de antes (mismos SHA).
- **Pendiente en el teléfono (lista concreta):**
  1. Híbrida contra un jefe (Guardián/Custodio) y contra Bramavidrio; mirar que el corazón y el orbe encajan con el tamaño.
  2. Selector «Érebo: invocación» → «Vídeo»: la cinemática mejorada (cabeza firme) completa y abreviada; que no quede en negro.
  3. Sonido: subir el volumen multimedia LO HACE EL USUARIO (no se toca el sistema); escuchar la híbrida, el vídeo, la
     vuelta de la música tras saltar y el mapamundi.
  4. Mapamundi: llegar andando al campamento y a la cueva provisional; medir la cueva.
  5. Oakhaven por la mañana (dormir en la posada) con el mundo vivo.
  6. Custodio: ver el Sello de Clausura lanzado (más turnos en el caso ×8).
  7. Reiniciar la app tras usar ALTO en Sunken y comprobar que el PSS vuelve a ≈790 MB.

## APK MÁS RECIENTE (15/11, tarde): validada `cbc0536` (batería 185 · 0 · 98 · 0), AÚN EN EL PC

- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261115-cbc0536-local.apk` (425,5 MB, «TODO
  CORRECTO»), versionCode **801**, versionName `androidauditora-20261115-cbc0536-local`.
  SHA-256: `3fd18e4a6560ef58e0056805f413efe905e9481d46949bdf978ffcc9446d3869`.
- **Estado del Redmi (15/11, 12:28):** respaldo nuevo verificado (693 archivos) en
  `D:\REBELUM_respaldos\2026-11-15_redmi_auditoria_antes_consolidada`; `ajustes.cfg` restaurado al del 14/11 (SHA
  `3ee5aaf2…`), `banco_pruebas.save` y su `.bak` borrados; `partida_exp.save` intacta (SHA `567c7323…`). Instalada aún
  la v717 (`687dbe7`). Después se perdió la conexión USB: NO se ha instalado nada.
- **Además de lo de abajo, qué probar con esta APK:**
  1. **Érebo híbrida** (Ajustes «Érebo: invocación cinematográfica» → «Híbrida», o banco → selector «Érebo:
     invocación»): el enemigo señalado, el acercamiento, la mano en el pecho, el corazón espectral, el ritual del vídeo
     y la vuelta. Contra un enemigo normal, uno grande (Bramavidrio), un jefe y una resistida; saltar a mitad. Coste:
     FPS y PSS, y la decodificación de `erebo_ritual*.ogv`. Nada aprobado: el usuario revisa imagen, ritmo y sonido.
  2. **Vídeo de Érebo que falla:** no se puede provocar en el teléfono sin tocar archivos; observar que nunca se queda
     en negro.
  3. **Custodio:** dos casos en el banco: «equilibrio normal» (vida de siempre) y «ver la rotación (vida ×8)».
  4. **Nix antigua** a la distancia mínima de cámara: ya no desaparece.
  5. **Sunken City** (banco): las medidas del PC están en `SUNKEN_3D_V12.md`; en el Redmi, FPS, perdidos, PSS y carga
     de la primera entrada y de las siguientes.

**APK anterior (15/11, mañana): `c04d07b` (versionCode de entonces), sustituida por la de arriba**

## La APK

- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261115-c04d07b-local.apk` (420,0 MB; «TODO CORRECTO»).
  - SHA-256: `9b42c2a4c97ef07bbfd309328041d084701fa89559bae276200880757132dd35`.
  - Commit: `c04d07b`. Contenido del juego igual que el validado `270c8ed` (`validado/v12/20261115-035801`, batería
    completa 183 · 0 · 94 · 0); `c04d07b` solo añade una medida de PC, que no va en la APK.
  - Preset «Android auditoría» (paquete `com.aethelgard.auditoria`, app «REBELUM Auditoría»).
- **Opciones experimentales que lleva (todas APAGADAS por defecto; se encienden en Ajustes o en el banco de pruebas):**
  - Sunken City 3D (nueva: «Sunken City 2D / 3D (en pruebas)» en Ajustes, o el banco de pruebas).
  - Misión del cantero (propuesta).
  - Custodio de Porcelana con sus tres especiales (solo desde el banco).
  - Nix desde el FBX (con la mano del cetro arreglada) y la capa articulada de Garon.
  - Érebo: orbe experimental e invocación cinematográfica en vídeo (sin cambios desde `5e5458d`).
  - Mundo vivo de Oakhaven, Agua mejorada y lo que ya estaba.

## Antes de instalar (obligatorio, lo dejó pendiente la sesión del 14/11)

1. La app quedó dentro del banco: borrar `files/banco_pruebas.save`.
2. Restaurar `files/ajustes.cfg` desde `D:\REBELUM_respaldos\2026-11-14_redmi_auditoria_antes_v694_a_nueva`.
3. Comprobar por SHA-256 que los 538 archivos coinciden con `sha_tel_todo.txt` y que `partida_exp.save` no cambió.
4. Hacer un respaldo nuevo con fecha antes de instalar (nunca sobrescribir uno anterior).
5. Copiar la APK a Descargas; la instala el usuario (MIUI bloquea `adb install`).

## Qué probar, en este orden

1. **Arranque y continuidad.** Arranque en frío hasta la portada (el 14/11: 13,0 s). «Continuar» carga la partida de
   siempre en su sitio. Novedad invisible: las partidas se validan al leerlas (si una estuviera mal, se recupera la
   copia «.bak»); con las copias reales del PC y del Redmi de los respaldos (29) el validador las acepta todas.
2. **Protagonistas v2/v3 de pie** 30 s cada uno: FPS, fotogramas perdidos y PSS (`dumpsys meminfo`).
3. **Paso entre los vecinos de Oakhaven** por la mañana y por la tarde (en el PC atascaban: Bastián por la mañana en
   la Calle del Mercado y Rosa al anochecer en la Calle del Árbol; ahora van por la orilla). Ir con el dedo de la
   Puerta del Sur a la plaza, a la torre y al Árbol. Con el mundo vivo encendido también.
   - Tocar más lejos mientras Kael anda: ya no debe pararse a medias (arreglado para todas las regiones).
4. **Nix y la capa de Garon** (banco → Nix «Desde el FBX» y capa «Articulada»): la mano del cetro cerrada; capucha y
   flequillo (¿tapan un ojo?); altura de Nix junto al grupo; la capa al andar, girar y atacar; coste en FPS.
5. **Érebo y magias** (banco → Érebo y Agua): sin cambios esta noche; si hay tiempo, lo pendiente del guion del 14/11
   (vídeo abreviado y completo, sincronía del sonido, salto con el dedo, Agua mejorada).
6. **Cantero, cerraduras y recompensas** (banco → «Misión del cantero: Activa» → Oakhaven):
   - abrir la LOSA PRIMERO, sin hablar con el aprendiz: el Diario debe mostrar la misión con «volver» (arreglado);
   - placas legibles a la distancia de juego, la losa con el dedo, abandonar la cerradura a medias;
   - el polvo en la Alquimia; Ferro no compra el Hierro de la Falla mientras lo espera.
7. **Sunken City 3D (nueva)** (banco → «Sunken City 3D (en pruebas)», entra por el muelle):
   - recorrido: muelle → brecha de la popa → la Quilla bajo las costillas → rampa → Cubierta Mayor (palo, Brea,
     tienda, proa con el mascarón) y los desvíos (Archivo del Águila con Ulla; balcón de la lona);
   - la misión «El sello de la capitana» (Ulla → adivinanza de Brea → el sello en la driza → Ulla) y el Diario;
   - el secreto: «la costilla que no alumbra» (tabla suelta junto a la costilla sin farol, una vez);
   - la recompensa: Bronce del Águila → investigarlo en la forja de Kael → «Guarda del Águila» (+2 de vitalidad, una
     vez); el bronce no debe salir a la venta hasta forjarla;
   - salir al mapa y volver a entrar; guardar a mitad y cargar;
   - **medir** en bajo y medio: FPS, perdidos, PSS. En el PC: 40-75 llamadas de dibujo en bajo, 54-103 en medio,
     81-152 en alto (Lya y Garon ponen unas 70.000 de las primitivas). Ojo con las costillas que se vuelven
     translúcidas al tapar a Kael: transparencia a pantalla casi completa (coste en el Mali).
   - Arte PROVISIONAL (procedural): juzgar composición y legibilidad, no el acabado.
8. **Custodio** (banco → Custodio, ahora con vida ×8 para ver la rotación): Prensa del Umbral, Avance del Portón y el
   nuevo **Sello de Clausura** (disco de cerradura en el suelo, golpe a 1,30 s, «Lento» 1 turno). ¿Se leen las tres
   marcas? Cifras PROPUESTAS, sin equilibrar.
9. **Rendimiento y memoria tras varios recorridos:** mapa → Oakhaven → Sunken → Pastos y vuelta, 3-5 veces, mirando
   PSS en cada vuelta. En el PC (5 vueltas) la memoria quedó estable: +0,0 MB de la 2.ª a la 5.ª, 0 nodos huérfanos.

## Al terminar
- Volver a dejar en «No» o «Apagado» lo que se haya encendido en Ajustes.
- Salir del banco con «Salir del banco» (no deja nada en la sesión).
- Copiar al PC los registros de rendimiento (`files/rendimiento_*.csv`) si se abrió el panel RND.
