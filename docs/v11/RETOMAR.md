# RETOMAR la V11 («El despertar de Aethelgard»)

Si la conversación se corta, empieza aquí. Antes, sigue el protocolo de `D:\Aethelgard\CLAUDE.md`: comprueba la
memoria en GitHub y lee `SESSION_HANDOFF.md`.

## Git

- **Trabajo:** `claude/rebelum-v11` en **`D:\Aethelgard_v11`**. LOCAL, sin subir ni fusionar.
  - Nace de `claude/rebelum-v10` @ `173dadf` (la V10, con los arreglos vistos en el Redmi).
  - La directiva V11 prohíbe esta noche el push, las fusiones con ramas compartidas y las APK oficiales.
- **Especialistas:**
  - `claude/v11-narrativa` (`D:\Aethelgard_v11_narrativa`), ya fusionada. Solo documentos: `docs/v11/HISTORIA.md`,
    propuesta sin canon;
  - se conservan; no se borran.
- **Ramas compartidas sin tocar:** `main`, `desarollo` e `integracion-experimental`.

## Base comprobada

- La V11 parte del código de `f2b3ff4`.
  - Batería completa en `822927a`: 103 superadas, 1 fallida y 43 manuales. La fallida era `prueba_equilibrio`, que es
    inestable: repetida, pasó 3 de 3.
  - Las pruebas de Oakhaven pasaron en `f2b3ff4`.
- La primera batería en `173dadf` se paró a medias (8 superadas), porque se empezó a editar el combate mientras corría.
  La siguiente, completa, es la de `4e1f734`.

## Hecho (ver `MEJORAS_COMBATE.md`)

- Hito B, en `4e1f734`:
  - panel de objetivos a la derecha;
  - lista de INVOCACIÓN;
  - interrupción del golpe preparado y guardia rota del Slime.
- Batería en `4e1f734`: **105 superadas, 0 fallidas, 43 manuales, 0 no seguras**.
- Filo Arcano (Kael + Lya), en la pestaña DÚO: `6e7d9fe`. Pasaron sus pruebas y las de combate relacionadas; la batería
  completa, todavía no.

## Comprobar que todo sigue bien

Desde PowerShell, en `D:\Aethelgard_v11`:

```
powershell -ExecutionPolicy Bypass -File .\ci_local.ps1
```

No edites archivos de esta copia mientras corre: la batería compara el estado de Git antes y después.

## Siguiente paso

1. Batería completa tras `6e7d9fe`.
2. **Hito C**, Oakhaven:
   - gremio de aventureros mínimo y con contenido (contratos, rango, reputación);
   - el primer proyecto de reconstrucción, que cambie la ciudad de verdad.
3. **Hito E:** el Brumín Rizo y su encargo (propuesta de narrativa en `HISTORIA.md` §2).
4. **Hito D:** el primer sector del Mar de Cristal y el buscador de metales.
5. En el Redmi, cuando vuelva (nada de esto se ha probado en el teléfono):
   - el panel con el dedo;
   - el 25 % de la interrupción;
   - los FPS con la lista abierta.
