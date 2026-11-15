# Guion de pruebas en el Redmi (16/11) — APK de Auditoría consolidada

> Escrito la noche del 15 al 16/11, sin el teléfono: esta noche NO se ha instalado nada ni se han tocado datos del
> Redmi. Todo lo de abajo está comprobado SOLO en el PC; nada certifica Android.

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
