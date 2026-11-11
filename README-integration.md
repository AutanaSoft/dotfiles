# Integración de la interfaz TUI

Los archivos de esta carpeta son una propuesta de cambio local, sin commit ni push.

1. Copiar `setup-tui` a la raíz del repositorio y conservar el permiso ejecutable (`chmod +x setup-tui`).
2. Aplicar `setup-entrypoint.patch` en la raíz con `git apply /ruta/setup-entrypoint.patch`.
3. Ejecutar `./setup` o `./setup --tui` desde una terminal interactiva.
4. Usar `./setup --profile omarchy --dots-only --dry-run` para conservar el flujo CLI previo.

La TUI selecciona Omarchy o Fedora WSL2, fases y modo de simulación, muestra el comando exacto y requiere confirmar antes de ejecutar. La simulación viene activada inicialmente. No utiliza dependencias externas, solo Bash y un terminal ANSI compatible. Para automatización o procesos sin TTY, seguir utilizando la CLI explícita.

Pruebas recomendadas en el checkout real:

```bash
bash -n setup setup-tui
./tests/run.sh
./setup --help
./setup --profile omarchy --deps --non-interactive --dry-run
./setup --profile fedora-wsl2 --deps --non-interactive --dry-run
```

Para verificar la TUI sin modificar el host, mantener marcada `Preview only (no changes)` y usar `Review selection` seguido de Enter.
