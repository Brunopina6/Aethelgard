# V12 · El Mar de Cristal (primer sector) — contrato técnico

Rama LOCAL `claude/rebelum-v12` (`D:\Aethelgard_v12`), desde la V11 (`33c69c2`). Este documento es el **contrato** entre
el coordinador y los especialistas: identificadores, sitios, archivos y quién toca qué. Nombres y textos: PROPUESTA
(sin canon). Canon de partida: `docs/v11/HISTORIA.md` §1 y §3. El Mar de Cristal es el corazón vitrificado del **Mar de
Arena de Calid** (lugar 4 del mapa, `mapa.gd`), no un desierto nuevo; el Lente del Sol (canon) **no se revela**.

## 1. La región

- Escena `res://zonas3d/mar_cristal_3d.tscn` + `zonas3d/mar_cristal_3d.gd` (extends `prototipos/vista3d.gd`, como la
  Garganta y Oakhaven 3D). Piezas en `zonas3d/mar_cristal/` (trazado, terreno, clima, buscador_hud…).
- `modo3d.gd`: `REGIONES[4]` → la región; en pruebas con el argumento y el ajuste «mardecristal» hasta que esté entera.
- Sector «La Orilla de Vidrio»: X de 0 a 90 m (oeste → este), Z de 0 a 110 m (norte → sur). La cámara mira al norte
  y no gira (como siempre). La entrada, al sur.

| Sitio | Dónde (x, z) | Qué hay |
|---|---|---|
| Entrada / salida al mapa | (45, 104) | el camino de la caravana |
| Campamento | centro (36, 92) | 2 tiendas con telas al viento, fogata, la cartógrafa (NPC) en (37, 96) |
| Restos de la caravana | centro (50, 60) | carro volcado medio enterrado, cajas, tela rota |
| Oasis | centro (74, 72), radio 9 | estanque, palmeras, juncos que se mecen |
| Cañón y rocas | x 4-18, z 20-80 | paredes de roca; **cobijo** bajo una roca saliente en (14, 48) |
| Ruinas enterradas | centro (45, 18) | arco y columnas medio enterrados; trampilla sellada en (45, 22) |
| Arena que tiembla (gusano) | x 60-88, z 20-50 | huesos, surcos; aquí se notan las vibraciones |
| Espejismo | (82, 30) | una palmera que tiembla y no está; en calma revela un cofre |
| Esqueleto con nota | (8, 30) | en un nicho del cañón |

## 2. Misión «La caravana perdida» (hitos `mc_*`, en `progreso.gd` hitos; datos en `datos/encargos_desierto.gd`)

1. `mc_inicio`: la cartógrafa cuenta que la caravana de su hermano no llegó; le presta a Kael **el buscador**
   (`buscador.gd`, nivel 1).
2. `mc_caravana`: Kael examina los restos; las huellas se las ha llevado el viento.
3. `mc_sello`: con el buscador, junto a los restos, sale el **Sello de la caravana** (único): marca el norte.
4. `mc_tormenta`: al volver hacia el norte se levanta **una tormenta de arena** (narrativa): visibilidad baja, el
   buscador no oye; hay que llegar al **cobijo** (14, 48) y esperar a que amaine.
5. `mc_ruinas`: la tormenta ha destapado el arco de las ruinas (antes casi enterrado).
6. `mc_llave`: con el buscador, en las ruinas, sale la **Llave de vidrio** (único).
7. `mc_superviviente`: la llave abre la trampilla; dentro, el hermano de la cartógrafa, vivo, con la sed de dos días y
   un mural de una figura coronada de cristal (pista de la Reina de los Espejismos, sin nombrarla del todo).
8. `mc_fin`: de vuelta al campamento, la recompensa (una vez): 150 monedas, el buscador queda para Kael y sube a nivel
   2, y una reliquia.

## 3. Archivos y responsables (un archivo, un responsable)

| Quién | Rama y copia | Archivos |
|---|---|---|
| Coordinador | `claude/rebelum-v12`, `D:\Aethelgard_v12` | `zonas3d/mar_cristal_3d.*`, `zonas3d/mar_cristal/*.gd`, `buscador.gd`, `modo3d.gd`, `combate.gd`, `progreso.gd`, `datos/encargos_desierto.gd`, `encargos.gd`, pruebas |
| Gráficos | `claude/v12-desierto-arte`, `D:\Aethelgard_v12_arte` | `modelos/desierto/*.glb`, `fuente/crear_desierto*.py`, `zonas3d/mar_cristal/materiales_arte.gd`, `shaders/desierto/*` |
| Narrativa | `claude/v12-desierto-narrativa`, `D:\Aethelgard_v12_narrativa` | `dialogos/mar_cristal/*`, `dialogos/personajes/mar_cristal/*`, `docs/v12/NARRATIVA_DESIERTO.md` |
| Sonido | `claude/v12-desierto-sonido`, `D:\Aethelgard_v12_sonido` | `audio/desierto/*`, claves nuevas en `sonido.gd` (solo añadir) |

## 4. Reglas del desierto (lo que ya decide el coordinador)

- **Tormenta:** narrativa (paso 4) y, después, sistémica controlada (nunca durante un diálogo, nunca más de una cada
  pocos minutos, siempre con cobijo a mano). Con tormenta: niebla y luz más bajas, viento fuerte, el buscador no oye
  («La tormenta tapa la señal») y no se puede excavar.
- **Gusano:** primero peligro ambiental en «la arena que tiembla»: aviso (temblor, surco que avanza, rugido sordo);
  si Kael sigue en la arena blanda cuando llega, emerge (encuentro especial). En roca o fuera de la zona, no.
- **Buscador:** botón propio; indicador de cercanía y pitidos más rápidos (otro tono si es raro); «Excavar» solo
  encima; los hallazgos se guardan; lo único no se repite aunque se recargue.
