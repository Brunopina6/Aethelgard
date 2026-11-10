# RETOMAR la V10

Si la conversación se corta, empieza aquí. Antes, sigue el protocolo de `D:\Aethelgard\CLAUDE.md`: comprueba la
memoria en GitHub y lee `SESSION_HANDOFF.md`.

## Estado de Git (10/11/2026, 21:45)

- **Trabajo:** `claude/rebelum-v10` en `D:\Aethelgard_v10`. LOCAL, sin subir ni fusionar.
- **Último commit con código:** `c2eb155`. Después, solo documentos.
- **Especialistas, ya fusionados:** `claude/v10-narrativa` (`D:\Aethelgard_v10_narrativa`) y `claude/v10-distrito`
  (`D:\Aethelgard_v10_distrito`). Se conservan; no se borran.
- **Base:** `claude/rebelum-v9` @ `3795769` (`D:\Aethelgard_v9`), también LOCAL.
- **GitHub:** `integracion-experimental` @ `b4e26e2`, `main` @ `d4b2d16` y `desarollo` @ `2d1adc4`, sin tocar.

## Comprobar que todo sigue bien

Desde PowerShell, en `D:\Aethelgard_v10` (resultado esperado: 103 · 0 · 43 · 0):

```
powershell -ExecutionPolicy Bypass -File .\ci_local.ps1
```

Cuidado: la importación sin editor borra el registro de Dialogic de `project.godot`. `ci_local.ps1` lo restaura. Si
importas a mano, ejecuta después `git restore aethelgard/project.godot`.

## APK

- La de la V10 es `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261110-c2eb155.apk` (v520). Está sin
  instalar.
- La v499 es de la V9: no sirve para la V10.
- Para probar en el Redmi:
  1. copiarla a Descargas por USB (con `export MSYS_NO_PATHCONV=1` si es desde Git Bash);
  2. comprobar el tamaño y el SHA-256;
  3. la instala el usuario;
  4. seguir `PENDIENTES_REDMI.md`.

## Siguiente paso concreto

1. **Si el usuario vuelve con el Redmi:** copiar la v520 y seguir `PENDIENTES_REDMI.md`.
2. **Si autoriza fusionar y subir:**
   - batería otra vez;
   - fusionar `claude/rebelum-v10` en la rama que diga;
   - push sin force.
   - La APK **no** va a GitHub: lleva recursos con licencia pendiente.
3. **Sin el Redmi**, lo que queda (`ESTADO_V10.md`, problemas conocidos):
   - sonido del distrito: martillo, fragua y pozo, y los pasos en la calle nueva;
   - Hilda y Mirta con algo de rutina en 3D;
   - una prueba de combate del Bálsamo y la runa.
4. **Que el usuario apruebe o cambie** los personajes y textos propuestos (Ferro, Hilda, Mirta, los encargos y el pozo).

## Documentos de la V10 (`docs/v10/`)

- `DISENO_V10.md`: el contrato técnico.
- `ESTADO_V10.md`.
- `OAKHAVEN_CIUDAD_VIVA.md`.
- `FORJA_KAEL.md`, `TALLER_GARON.md` y `BOTICA_LYA.md`.
- `ENCARGOS_OAKHAVEN.md`.
- `PRUEBAS_V10.md`.
- `PENDIENTES_REDMI.md`.
- Este archivo.

Los informes de los especialistas están en `docs/memory/agents/`: `narrativa_v10_oakhaven.md` y
`graficos_v10_distrito.md`.
