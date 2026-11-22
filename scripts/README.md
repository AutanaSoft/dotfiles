# Inert setup template

`scripts/setup` is an isolated Bash + `jq` TUI template. It reads profile data from
`src/*/profile.json`, lets you select categories and components, and presents a grouped review.
It never invokes an installer, evaluates manifest data, or modifies the system. The existing `./setup`
CLI is unchanged.

Run it from any directory:

```bash
scripts/setup
scripts/setup --profile demo
```

Manifests use `schema_version: 1` and basic metadata validation. Invalid manifests are reported while
valid profiles remain available; duplicate profile IDs are visible but unselectable. The example in
`src/demo/profile.json` has empty requirements and component `items`. Platform gates, action/handler
validation, and all installation behavior are deliberately deferred; this is not a finalized V1
catalogue.

Use ↑/↓ to move, Space to toggle, Enter to continue, and Esc to go back. The review keeps Volver
focused and shows the disabled Instalar action with `Instalación no disponible en esta plantilla.`

## Checks and visual limits

```bash
bash -n scripts/setup
python3 -B -m unittest discover -s tests/tui -p test_setup.py -v
```

The PTY tests exercise public entry, discovery, navigation, resize, terminal restoration, and the
no-mutation review. This checkout has no screenshot capture harness for this standalone TUI, so these
checks are terminal-output tests, not PNG visual proof.
