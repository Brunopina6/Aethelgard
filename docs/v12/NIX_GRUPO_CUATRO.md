# Nix en un grupo de cuatro (V12, 15/11/2026): solo en el banco de pruebas

**Estado:** prueba de Auditoría. El usuario **no ha decidido** desde cuándo lucha Nix ni si el grupo activo pasa a
cuatro. En el juego no cambia nada: `MAX_ACTIVOS` sigue en 3 y siguen igual la incorporación, la Formación, los menús y
la exploración. Rama local `claude/v12-custodio-contador` (desde `1239e78`). Comprobado ejecutando en el PC el 15/11
con datos aislados.

## 1. Qué hay

- **Caso del banco** (`banco_pruebas.gd`, `COMBATES["grupo4"]`): «Grupo de cuatro: Kael, Lya, Garon y Nix (prueba)».
  - GRUPOS[1] (tres slimes), vida ×6, nivel 12.
  - Partida aislada del banco (`user://banco_pruebas.save`, rehecha desde BASE cada vez): no se gana nada permanente.
- **Permiso solo de sesión:**
  - `poner_grupo()` pone la meta `banco_grupo4` cuando el caso trae más de `MAX_ACTIVOS`, y la quita en los demás.
  - Está en `METAS_SESION`, así que `preparar_partida()` (cada caso) y `salir()` la quitan.
  - Ninguna partida la guarda: no está en `progreso.gd CLAVES`.
- **`grupo.gd`:**
  - `max_activos()` devuelve `MAX_ACTIVOS_BANCO` (4) solo si se cumplen las tres condiciones: la meta `banco_grupo4`,
    la del banco (`banco_pruebas`) y la APK de Auditoría o el editor.
  - En cualquier otro caso devuelve `MAX_ACTIVOS` (3).
  - Solo lo usa `activos()` para recortar. `unir()`, la Formación (`motivo_formacion`, `hay_formacion`) y los menús
    siguen con `MAX_ACTIVOS`.
- **`combate.gd`:**
  - `SITIO_CUARTO` = (640, 190): detrás y a la derecha de Lya. Lo usa `_con_reclutas()` cuando un recluta activo no
    tiene hueco (los tres de siempre están), y va el último de la lista (filas del grupo y cola).
  - Con tres activos nunca se llega ahí: siempre falta uno de los de siempre y el recluta ocupa su sitio, como antes.

## 2. Comprobado en el PC (15/11)

`pruebas/fotos_banco_grupo4.gd`, con ventana:
- Capturas en `D:\REBELUM_diagnostico\pruebas\2026-11-15_144423\fotos_banco_grupo4\`. Revisadas a ojo.
- Los ataques son automáticos: **no es la estrategia de un jugador.**

| Qué | Resultado |
|---|---|
| Coloca | Kael, Lya, Garon y Nix. Pies en (586, 490), (722, 462), (504, 643) y (808, 561). Entre héroes ≥ 131 px; de los enemigos ≥ 272 px; todo dentro de la pantalla |
| Dibuja | 4 filas del grupo (nombre, PV, PM y ATB) en y 512, 558, 604 y 650; el bloque sube solo (`menu_combate.preparar`) |
| Turnos | Orden de héroes: Lya, Kael, Nix, Garon, Lya, Kael, Nix, Lya. Los cuatro abren su menú, eligen objetivo y atacan; un slime actúa (`g4_turno_enemigo.png`) |
| Línea de turnos (`turnos_v12`, apagada en el juego) | 6 turnos previstos, con Nix (`g4_linea_turnos.png`). Garon, el más lento, puede no caber en los 6 |
| Sin el permiso | Los mismos cuatro nombres dejan Kael, Lya y Garon (`g4_sin_permiso.png`) |
| Al salir | Sin la meta; `max_activos()` = 3 |

Observado en las capturas (no son decisiones):
- Nix, en el cuarto sitio, tapa un poco la falda de Lya con el sombrero (`g4_inicio.png`).
  - Se probó también delante, entre Garon y Lya: (530, 262), pies en (698, 633). Tapaba más a Lya y quedaba pegada a
    Garon, así que se volvió a (640, 190).
  - Una formación de cuatro de verdad pediría recolocar a los cuatro.
- Con cuatro filas del grupo, el menú de 5 opciones (Lya: ATACAR, MAGIA, INVOCACIÓN, OBJETO, HUIR; Garon: ATACAR,
  ESGRIMA, EMBUIR, OBJETO, HUIR) acaba en y ≈ 500, justo encima de la cabecera «PV PM ATB» (y ≈ 507). No se solapa,
  pero va justo; con 6 opciones se tocarían.

`pruebas/prueba_banco_pruebas.gd` (sin ventana) comprueba:
- 10 casos en pantalla.
- El combate de cuatro (4 héroes, 4 sitios y 4 filas).
- La victoria con cuatro: los cuatro reciben experiencia como siempre (Kael 18 → 22 y Nix 0 → 4).
- Que, sin el permiso o fuera del banco, siguen tres.
- Que el caso siguiente no hereda el permiso y que salir lo quita.
- **Contraprueba:** con `poner_grupo` sin poner el permiso, FALLIDA con 2 fallos (`2026-11-15_144328`).

## 3. Lo que necesitaría su incorporación definitiva (NO aplicado)

Todo esto espera la decisión del usuario sobre cuándo se une Nix y si el grupo pasa a cuatro.

1. **`grupo.gd`:**
   - `MAX_ACTIVOS` a 4, o hacerlo depender de un hito. `max_activos()` ya centraliza el recorte de `activos()`;
     `unir()`, `motivo_formacion()` y `hay_formacion()` usan aún la constante.
   - `SE_UNE_EN["Nix"]` con su hito: hoy Nix solo existe con el interruptor `nix_v12`, `disponible()`.
   - `KAEL_SIEMPRE_ACTIVO` y la Formación con cuatro.
   - Nix sigue `provisional` en `HEROES`.
2. **Incorporación narrativa:**
   - Dónde y cuándo se une. Hoy no tiene escena ni hito.
   - Su nivel al unirse: la nivelación automática sigue retirada (D-062 / T-080, pendiente).
   - `progreso.gd` le da más experiencia mientras vaya por debajo del nivel de la zona.
3. **Exploración** (`zonas3d/grupo_3d.gd`):
   - `reclutas_activos()` deja como mucho `MAX_ACTIVOS - 1 - acompañantes` reclutas. Con 4 cabría uno más en la fila.
   - Habría que probar la fila de cuatro en sitios estrechos (puentes, rutas: `prueba_grupo3d_rutas`) y su coste en el
     Redmi.
   - `zonas3d/mar_cristal/naira_mision.gd` también recorta a `MAX_ACTIVOS - 1`.
4. **Menús:**
   - `menus.gd`: «En el grupo: %d de %d» con `MAX_ACTIVOS`; fichas, equipo y estado de cuatro.
   - Tienda: equipar a cuatro.
   - Comprobar que caben en el teléfono.
5. **Combate:**
   - Un sitio pensado para el cuarto (o recolocar a los cuatro). Hoy `SITIO_CUARTO` es provisional.
   - Las filas del grupo con menús de 5-6 opciones.
   - Ataques en fila de los enemigos (`vecino()`: Prensa, Avance, Zancada) con cuatro.
   - El Sello del Custodio (círculo de 1,3 m) con más gente junta.
   - Érebo, que solo invoca Lya.
   - La línea de turnos (6 casillas).
6. **Equilibrio:**
   - Los encuentros están hechos para tres. `grupo_al_azar(4)`: `AL_AZAR_POR_TAMANO` no tiene entrada para 4 y cae en
     el azar general, como con 3.
   - El élite sale con ≥ 2 héroes.
   - Experiencia y monedas por héroe, la reserva (`PARTE_EXP_RESERVA`), la Armonía (más golpes, más rápida) y la
     dificultad de jefes y del Custodio.
   - Con cuatro, el grupo pega un tercio más por ronda.
7. **Partidas antiguas:**
   - `grupo_activo` guardado con tres sigue valiendo.
   - Con `MAX_ACTIVOS` a 4, una partida con alguien en la reserva NO lo pasa sola a activo: hace falta la Formación o
     una regla al cargar.
   - Una partida guardada con cuatro y abierta en una versión de tres se recorta a los tres primeros (`activos()`), sin
     perder datos.
8. **Pruebas que suponen tres** (habría que repasarlas):
   - `prueba_grupo_reserva` (Formación, «Solo caben 3», reserva) y `prueba_naira_mision`.
   - `prueba_banco_pruebas` (casos de tres).
   - `prueba_combate_huella` (huella con 1, 2 y 3 héroes).
   - `prueba_grupos_combate`, `prueba_incorporacion`, `prueba_equilibrio`, `prueba_rasgos_grupo` y
     `prueba_solo_lya_invoca`.
   - `grabar_grupo_movimiento` y las de la fila 3D (`prueba_grupo3d`, `prueba_grupo3d_rutas`).
   - Muchas fotos y pruebas de combate crean el grupo `["Kael", "Lya", "Garon"]` a mano.
