# Narrativa V11: propuesta de historia (nombres, Brumín, Mar de Cristal y ganchos)

## 11/11/2026 · rama LOCAL `claude/v11-narrativa` (`D:\Aethelgard_v11_narrativa`), base `4e1f734`

**Encargo del coordinador** (directiva V11; el usuario duerme, decisión conservadora): una sola propuesta en
`docs/v11/HISTORIA.md` con los nombres del usuario contra el canon, un primer Brumín con su encargo, un encargo
arqueológico en el Mar de Cristal con un buscador de metales de Kael y un gancho personal por héroe.

### Qué he hecho
- Solo documentos. **No he ejecutado Godot ni pruebas** (orden del coordinador: la batería corre en otra copia).
- Leído (observado): biblia v2 y v3 y la propuesta v1 (`D:\Aethelgard\docs\biblia\`), `docs/narrativa/voces_heroes.md`,
  `docs/v9/`, `docs/v10/`, los informes de narrativa, `DECISIONS.md` (D-030, D-032, D-037, D-038, D-071) y, del código
  de esta rama, `mapa.gd`, `encargos.gd`, `datos/encargos_*.gd`, `artes.gd`, `combate.gd`, `grupo.gd` y
  `ciudades/oakhaven.gd`.
- Escrito `docs/v11/HISTORIA.md`, todo marcado como PROPUESTA.

### Decisiones principales (propuestas)
1. **Mar de Cristal = corazón del Mar de Arena de Calid** (arena fundida en vidrio), no un segundo desierto: Calid ya
   es canon en `mapa.gd` y así no se toca.
2. **Marca del Vacío → Marca de Penumbra:** «el Vacío» es del enemigo (hachas y Portal del Vacío) y fijaría la
   identidad del personaje de magia negra, que no se inventa.
3. **Emperador Slime del Abismo → Emperador Slime** (nombre de la V9): «del Abismo» lo ataba a la fortaleza final.
4. **Auralis, dudoso:** en la v3 es el dios del amanecer; propuesta, «el Ciervo del Alba, heraldo de Auralis».
5. **Brumín / Brumines** encajan si nacen de la bruma blanca de las cascadas (no de la niebla) y se distinguen de los
   Hollines; posible cambio de nombre de la coneja Bruma [P].
6. **Rizo**, primer Brumín, y su encargo «Las tres cosas bonitas» en Pastos Verdes, desde `hito:pv_05`, con hitos
   nuevos `brm_*`, una decisión pequeña (`decisiones.rizo_canica`) y 2 Pociones. Sin combate nuevo.
7. **«Lo que guarda el vidrio»:** el buscador sale de un diapasón de Hierro de la Falla que regala Ferro tras su
   encargo (sin cambiar ese encargo); si no se hizo, una varilla prestada. Cinco hallazgos, semillas del pasado sin
   revelar nada; apunta a la máquina de Calid sin adelantarla. Nada de Érebo.
8. Ganchos personales sin usar los pasados propuestos de la biblia: Kael y la niebla, Lya y una página de las
   sacerdotisas, Garon y un recluta borrado del libro de guardia.

### Comprobaciones
- **Observado en el código** (11/11, `4e1f734`): no existen aún Auralis, Varkhûn, Nimara, Zerath, Brumín, Espiral ni
  las magias oscuras; `INVOCACION` solo tiene a Érebo; Kael tiene las artes Alba y Escarcha; Oakhaven tiene la Torre de
  la Campana y el Libro de guardia; Nyx sigue en `grupo.gd` como «Mago negro».
- **Pendiente de verificar:** que la «û» de Varkhûn se vea en las fuentes del juego y que «Prisión de Sombras» quepa en
  el botón del menú del móvil.

### Dudas para el usuario
Las siete preguntas de `docs/v11/HISTORIA.md` §5: el encaje del Mar de Cristal, Auralis, quién invoca las nuevas
invocaciones, los dos cambios de nombre, los Brumines y la coneja Bruma, la región del Campanero y qué hacer con Nyx.

### Para otros (sin tocar sus archivos)
- **Coordinador:** si se aprueba, añadir la entrada `enc_brumin` a `datos/encargos_pastos.gd` (bloque en §2.5).
- **Gráficos y animaciones:** modelo de Rizo (§2.2) y gestos `brumin_*`, que hay que acordar.
- **Combate:** cifras de la recompensa del desierto y funciones de las magias oscuras (§1.3), solo como sugerencia.
