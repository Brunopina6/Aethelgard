# RETOMAR la V11 («El despertar de Aethelgard»)

Si la conversación se corta, empieza aquí. Antes, sigue el protocolo de `D:\Aethelgard\CLAUDE.md`: comprueba la
memoria en GitHub y lee `SESSION_HANDOFF.md`.

## Git

- **Trabajo:** `claude/rebelum-v11` en **`D:\Aethelgard_v11`**. LOCAL, sin subir ni fusionar.
  - Nace de `claude/rebelum-v10` @ `173dadf`.
  - Último commit: el de `git -C D:\Aethelgard_v11 log -1`.
- **Esta noche la directiva prohíbe:**
  - el push, también el de la memoria;
  - fusionar con ramas compartidas;
  - las APK oficiales;
  - tocar las partidas reales.
- **Especialistas:** `claude/v11-narrativa` (`D:\Aethelgard_v11_narrativa`), ya fusionada. Solo trae documentos.
- **Ramas compartidas sin tocar:** `main`, `desarollo` e `integracion-experimental`.

## Hecho esta noche (todo probado solo en el PC)

| Hito | Qué | Commit | Documento |
|---|---|---|---|
| B | Panel de objetivos, lista de INVOCACIÓN, interrupción y guardia rota | `4e1f734` | `MEJORAS_COMBATE.md` |
| B | Técnicas combinadas: Filo Arcano, Quiebra y Barrera Rúnica | `6e7d9fe`, `30b837e` | `MEJORAS_COMBATE.md` |
| B | Enemigos de élite | `d3db250` | `MEJORAS_COMBATE.md` §5 |
| C | Gremio de aventureros (tablón, contratos, rangos) | `142b72b` | `GREMIO.md` |
| C | Primer proyecto de reconstrucción (braseros de la plaza) | `fbab55c` | `GREMIO.md` |
| E | «Las parejas del Cuervo» (minijuego completo) | `5e9ea5c` | `MINIJUEGOS.md` |
| — | Propuesta de narrativa (nombres, Brumín Rizo, Mar de Cristal) | `be55874` | `HISTORIA.md` |

## Baterías

| Commit | Superadas | Fallidas | Manuales | No seguras |
|---|---|---|---|---|
| `4e1f734` | 105 | 0 | 43 | 0 |
| `fbab55c` | 106 | 0 | 43 | 0 |
| `d3db250` | 106 | 0 | 43 | 0 |

La última, si existe, está en `INFORME_NOCTURNO.md`.

## Cambios en lo que esperan pruebas antiguas (buscados y explicados)

- **`pruebas/referencias/huella_combate.txt`:** solo cambia E2, porque la magia rompe la guardia del Slime. La
  cabecera lo explica.
- **`prueba_artes_combate` y `prueba_controles_nuevos`:** con Lya en el grupo, Kael tiene además la pestaña DÚO.
- **`prueba_combate_huella`:** pide el objetivo de Érebo después de la lista de invocaciones.

## Comprobar que todo sigue bien

Desde PowerShell, en `D:\Aethelgard_v11`:

```
powershell -ExecutionPolicy Bypass -File .\ci_local.ps1
```

No edites archivos de esta copia mientras corre: la batería compara el estado de Git antes y después.

## Siguiente paso

1. **Hito D:** el primer sector del Mar de Cristal y el buscador de metales.
   - Hay una propuesta del encargo arqueológico en `HISTORIA.md` §3.
   - Es lo más grande que queda: una región 3D nueva.
2. **Hito E:** el Brumín Rizo (`HISTORIA.md` §2). Necesita su modelo (gráficos) y su encargo en Pastos Verdes.
3. **Hito F:** más magias y equipo. La magia negra espera al personaje que la usará.
4. **Hito G y H:** el mapamundi, el cielo y los jefes nuevos. Sin empezar.
5. **En el Redmi, cuando vuelva** (ver `PENDIENTES_REDMI.md`): nada de la V11 se ha probado en el teléfono.
