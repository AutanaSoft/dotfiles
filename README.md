# dotfiles

Repositorio para versionar configuraciones personales de varios entornos en un solo lugar.

## Nombre recomendado

- Usa `dotfiles`.
- `dotfiles` es la forma estandar y mas reconocible.
- `dotsfiles` no es habitual y suena a error tipografico.

## Convencion

- Cada entorno vive en una carpeta de primer nivel del repo.
- Dentro de cada entorno usamos nombres visibles, sin `.` inicial.
- Las rutas del repo representan rutas reales en `~` mediante una traduccion simple.
- `home/` en cada entorno equivale a `~/` y conserva los nombres reales de dotfiles como `.bashrc`.
- `config/` en el repo equivale a `~/.config/` en el sistema.
- Si en el futuro hiciera falta, `local/` podria equivaler a `~/.local/`.
- Ejemplo: `~/.config/hypr/hyprland.conf` para Omarchy vive como `omarchy/config/hypr/hyprland.conf`.
- No se debe editar nada de `~/.local/share/omarchy/` desde este repo.

## Estructura

- `omarchy/`
- `wsl2-fedora/`
- `fedora/`

## Uso

- Todo lo especifico de Omarchy va en `omarchy/`.
- Todo lo especifico de WSL2 con Fedora va en `wsl2-fedora/`.
- Si luego tienes una instalacion Fedora normal, va en `fedora/`.
- Si algun archivo termina siendo comun entre varios entornos, podemos despues extraerlo a una carpeta compartida, pero por ahora conviene empezar separado para evitar mezclar casos.

## Estado actual

La base inicial de Omarchy ya quedo movida a:

- `omarchy/config/hypr/`
- `omarchy/config/waybar/`
- `omarchy/config/walker/`
- `omarchy/config/alacritty/`
- `omarchy/config/mako/`
- `omarchy/config/omarchy/themes/`
- `omarchy/config/omarchy/hooks/`

## Siguiente paso natural

Podemos hacer una de estas dos cosas:

1. Crear la estructura base equivalente para `wsl2-fedora/`.
2. Preparar una estrategia de despliegue con `stow` o symlinks por perfil.
