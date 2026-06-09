# dotfiles

Repositorio para versionar configuraciones personales de varios
entornos en un solo lugar.

## Nombre recomendado

- `dotfiles` (forma estándar, más reconocible).

## Convención

- Cada entorno vive en una carpeta de primer nivel del repo.
- Dentro de cada entorno usamos nombres visibles, sin `.` inicial.
- Las rutas del repo representan rutas reales en `~` mediante una
  traducción simple.
- `home/` en cada entorno equivale a `~/` y conserva los nombres
  reales de dotfiles como `.bashrc`.
- `config/` en el repo equivale a `~/.config/` en el sistema.
- Si en el futuro hiciera falta, `local/` podría equivaler a `~/.local/`.
- Ejemplo: `~/.config/hypr/hyprland.conf` para Omarchy vive como
  `omarchy/config/hypr/hyprland.conf`.
- No se debe editar nada de `~/.local/share/omarchy/` desde este repo.

## Entornos incluidos

| Entorno | Carpeta | Stack |
| --- | --- | --- |
| Omarchy Linux (Arch + Hyprland) | `omarchy/` | Hyprland, Alacritty, Zellij, nvim, Mako, themes |
| Fedora en WSL2 | `wsl2-fedora/` | WezTerm, Zellij, nvim, Zsh, Starship, SSH, Git |

## Documentación

| Entorno | Índice |
| --- | --- |
| Omarchy | [`omarchy/docs/README.md`](omarchy/docs/README.md) |
| WSL2 + Fedora | [`wsl2-fedora/README.md`](wsl2-fedora/README.md) |

## Cómo funciona

El repositorio es la **fuente de verdad**. Los archivos en
`~/.config/...` (y similares) son symlinks al repo, por lo que editar
el repo impacta el sistema en vivo. Cada entorno documenta su propio
workflow:

- Omarchy: [omarchy/docs/symlinks.md](omarchy/docs/symlinks.md)
- WSL2 + Fedora: [wsl2-fedora/docs/setup.md](wsl2-fedora/docs/setup.md)

## Estado actual

Omarchy ya quedó migrado, con archivos de Hyprland, Alacritty, Zellij,
nvim, Mako y un theme (`tokyo-night-autana`) bajo control del repo.
Detalle en [omarchy/docs/README.md](omarchy/docs/README.md).

WSL2 + Fedora está documentado y operativo; detalle en
[wsl2-fedora/README.md](wsl2-fedora/README.md).
