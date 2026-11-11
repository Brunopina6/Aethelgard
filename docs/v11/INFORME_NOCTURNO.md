# Informe de la noche · V11 «El despertar de Aethelgard» (11/11/2026)

Para leer al despertar. El resumen está en este primer apartado; el detalle, en los documentos enlazados.

## En una frase

El combate tiene más decisiones y se lee mejor; Oakhaven tiene un gremio con contratos, un primer proyecto que cambia la
plaza y un juego de taberna; y está la lógica del buscador de metales. **Todo está probado en el PC y nada en el
Redmi.** Nada se ha subido ni fusionado.

## Dónde está

- **Rama LOCAL:** `claude/rebelum-v11`, en `D:\Aethelgard_v11`, desde la V10 (`173dadf`).
- **Para seguir:** `docs/v11/RETOMAR.md`.
- **Prohibido esta noche y respetado:**
  - el push, también el de la memoria (un intento se bloqueó y no se envió nada);
  - las fusiones con ramas compartidas;
  - las APK oficiales;
  - tocar las partidas reales;
  - el Redmi.

## Lo que se puede ver al jugar (en el PC)

1. **Combate:**
   - **lista de enemigos a la derecha** al elegir objetivo, con nombre, PV y estado; los derrotados apagados;
   - **lista de INVOCACIÓN** con Érebo, su coste y qué hace;
   - **cortar golpes preparados** quitándoles el 25 % de su vida, y la magia rompe la guardia del Slime;
   - **técnicas DÚO:** Filo Arcano (Kael + Lya), Quiebra (Kael + Garon) y Barrera Rúnica (Lya + Garon);
   - **enemigos de élite** con ★ (uno de cada seis encuentros al azar).
   - Ver `MEJORAS_COMBATE.md`.
2. **Oakhaven:**
   - **tablón del Gremio de aventureros** en la plaza, con 6 contratos (derrotar, entregar y cumplir) y rangos
     Bronce, Plata y Oro;
   - **primer proyecto de reconstrucción:** los braseros de la plaza, que se encienden de verdad.
   - Ver `GREMIO.md`.
3. **«Las parejas del Cuervo»:** un juego de memoria en el Patio del Cuervo, sin apuestas. Ver `MINIJUEGOS.md`.
4. **Buscador de metales:** solo la lógica, todavía sin región. Ver `BUSCADOR_METALES.md`.
5. **Propuesta de narrativa:** nombres revisados contra el canon, el primer Brumín (Rizo) y el encargo arqueológico, con
   7 preguntas para ti. Ver `HISTORIA.md`.

## Pruebas

| Commit | Superadas | Fallidas | Manuales | No seguras |
|---|---|---|---|---|
| `4e1f734` | 105 | 0 | 43 | 0 |
| `fbab55c` | 106 | 0 | 43 | 0 |
| `d3db250` | 106 | 0 | 43 | 0 |
| `88987e3` | 107 | 0 | 43 | 0 |

- En cada batería, tu partida real del PC no cambió.
- **Pruebas nuevas:** `prueba_v11_combate`, `prueba_gremio`, `prueba_taberna` y `prueba_buscador`.
- **Pruebas antiguas que esperan otra cosa, a propósito y explicado en cada una:**
  - la huella del combate, en un combate, porque la magia rompe la guardia del Slime;
  - las pestañas de Kael, que tiene DÚO de más con Lya en el grupo.
- **Capturas con ventana** en `D:\REBELUM_diagnostico\fase2\2026-11-11_v11_fotos_combate`, `_fotos_gremio` y
  `_fotos_taberna`.

## Lo que NO se ha hecho (y por qué)

- **Mar de Cristal (región):** es una región 3D entera y no cabía con calidad en una noche. El buscador tiene su lógica
  lista.
- **Brumín, ESPIRAL, invocaciones nuevas, magia negra, armas nuevas, mapamundi, cielo y jefes nuevos:** sin empezar.
  - Los nombres están revisados en `HISTORIA.md`.
  - La magia negra espera al personaje que la usará, que no tiene identidad aprobada.
- **APK de auditoría de la V11:** no se ha compilado.
- **Redmi:** desconectado. Ver `PENDIENTES_REDMI.md`.

## Lo que necesito de ti

1. Probar en el Redmi (`PENDIENTES_REDMI.md`), cuando quieras, con una APK que puedo compilar.
2. Contestar a las preguntas de canon de `HISTORIA.md` §5 y aprobar o cambiar los nombres del gremio y del juego.
3. Decir si se integra la V11 y en qué rama.
