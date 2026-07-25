# Plan de implementación del flujo de setup

Este documento define el contrato de la implementación inicial del instalador
para el único perfil soportado: `omarchy`. El flujo debe ser explícito,
predecible y seguro en modo normal y `--dry-run`.

## Resultado

`./setup` es el punto de entrada único. Selecciona `omarchy`, valida la
solicitud y despacha las fases elegidas:

| Opción | Alcance |
| --- | --- |
| `--dots-only` | Manifiesto y configuración de usuario; no ejecuta otras fases. |
| `--dots` | Configuración de usuario y, en modo interactivo, selección de fases opcionales. |
| `--deps` | Paquetes declarados en `omarchy/dependencies-manifest`. |
| `--fonts` | Fuentes de usuario bajo `$HOME/.local/share/fonts/<familia>/`. |
| `--services` | Configuración de keyd y servicios de entrada aprobados. |
| `--locale` | Instalación explícita de `omarchy/etc/locale.conf`. |

La ausencia de una flag de fase no activa esa fase en modo no interactivo. Las
respuestas vacías, negativas o EOF dejan desactivada la fase correspondiente.
`--no-validate` solo se acepta con `--dots` y omite la validación final.

## Contrato de CLI

1. La raíz del repositorio se resuelve desde la ubicación de `setup`.
2. Las opciones y combinaciones se validan antes de ejecutar helpers.
3. Sin `--profile`, el modo interactivo ofrece únicamente `omarchy`.
4. `--non-interactive` exige `--profile omarchy` y no muestra preguntas.
5. Un perfil desconocido, una opción desconocida o una combinación no válida
   termina con código no cero y sin mutaciones.
6. `--dry-run` muestra las acciones sin escribir, mover, enlazar, descargar,
   instalar paquetes, ejecutar `sudo`, cambiar servicios ni modificar la sesión.

Ejemplos:

```bash
./setup --profile omarchy --dots-only --dry-run
./setup --profile omarchy --dots-only
./setup --profile omarchy --dots --non-interactive --dry-run
./setup --profile omarchy --deps --non-interactive --dry-run
```

## Responsabilidades

| Script | Responsabilidad |
| --- | --- |
| `setup` | Parsear CLI, validar opciones, preparar contexto y despachar. |
| `setup-omarchy` | Coordinar las fases del perfil `omarchy`. |
| `setup-dots` | Aplicar `omarchy/dotfiles-manifest`, backups y operaciones de usuario. |
| `setup-deps` | Leer, validar y procesar `omarchy/dependencies-manifest`. |
| `setup-fonts` | Descargar, extraer e instalar las familias de fuentes de usuario. |
| `setup-services` | Instalar keyd y habilitar/recargar keyd y ratbagd. |
| `setup-locale` | Compilar e instalar el locale declarado por el perfil. |
| `setup-validate` | Comprobar herramientas, tema y estado de Hyprland. |

Cada helper recibe argumentos explícitos y no coordina la responsabilidad de
otro helper.

## Manifiesto de dependencias

`omarchy/dependencies-manifest` usa dos campos separados por tabulador:

```text
package<TAB>name
```

Se permiten comentarios que comienzan con `#` y líneas vacías. `setup-deps`
rechaza líneas mal formadas, acciones desconocidas, nombres inválidos y
paquetes duplicados. Comprueba cada paquete con `pacman`, informa los paquetes
instalados y faltantes, y ejecuta como máximo un lote:

```bash
yay -S --needed <paquetes-faltantes>
```

El lote no se ejecuta cuando todos los paquetes están instalados o cuando se
usa `--dry-run`.

## Fuentes y seguridad

- Cada familia se instala directamente en
  `$HOME/.local/share/fonts/<familia>/`.
- Las descargas, extracciones, copias y `fc-cache` se omiten en `--dry-run`.
- Los targets existentes de dotfiles se guardan en `backup/` antes de ser
  reemplazados.
- La instalación de keyd conserva el backup y la recuperación cuando falla la
  instalación, el arranque o la recarga del servicio.
- Locale, servicios y cambios de sesión solo se ejecutan cuando su fase fue
  solicitada explícitamente.

## Archivos relevantes

- `setup`
- `omarchy/dependencies-manifest`
- `omarchy/dotfiles-manifest`
- `omarchy/utils/bash/setup-{omarchy,dots,deps,fonts,services,locale,validate}`
- `README.md`
- `docs/setup.md`
- `docs/post-setup.md`

Los archivos de spell de Neovim son cambios locales no relacionados y deben
permanecer intactos.

## Verificación

Desde la raíz del repositorio:

```bash
bash -n setup omarchy/utils/bash/setup-{omarchy,dots,deps,fonts,locale,services,validate}
tests/setup-contract.sh
./setup --help
./setup --profile omarchy --dots-only --non-interactive --dry-run
./setup --profile omarchy --dots --non-interactive --dry-run
./setup --profile omarchy --deps --non-interactive --dry-run
! ./setup --non-interactive
! ./setup --profile unsupported --dots-only
! ./setup --profile omarchy --dots-only --fonts
git diff --check
```

La verificación debe confirmar que el modo de previsualización no crea
archivos, directorios, backups ni otros efectos en el host.

## Fuera de alcance

- Implementar Ubuntu, Fedora, WSL2 u otra distribución.
- Instalar Omarchy o crear una capa compartida especulativa.
- Instalar automáticamente `omarchy/etc/fstab`, montar discos o modificar
  particiones.
- Configurar secretos, SSH real, autenticación de GitHub, WireGuard, PostgreSQL
  o Valkey como parte de `--dots`.
- Cambiar el contenido de Neovim, archivos de spell, temas o aplicaciones.
- Crear commits o modificar archivos locales no relacionados.
