"""Public PTY contracts for the isolated, inert profile TUI."""
import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import signal
import struct
import subprocess
import tempfile
import termios
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT_SOURCE = ROOT / "scripts" / "setup"
CLEAR = "\x1b[H\x1b[2J"
ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


def strip_ansi(value):
  return ANSI.sub("", value)


def category(category_id, name, component_id=None, component_name=None):
  components = []
  if component_id is not None:
    components.append({
      "id": component_id,
      "name": component_name,
      "description": f"Illustrative {component_name} component.",
      "items": [],
    })
  return {
    "id": category_id,
    "name": name,
    "description": f"Illustrative {name} category.",
    "requirements": [],
    "components": components,
  }


def profile(profile_id="demo", name=None, order=1, categories=None):
  if categories is None:
    categories = [
      category("dotfiles", "Dotfiles", "shell", "Shell"),
      category("fonts", "Fuentes", "font-sample", "Fuente de ejemplo"),
      category("dependencies", "Dependencias", "tools", "Herramientas"),
      category("services", "Servicios", "service-sample", "Servicio de ejemplo"),
    ]
  return {
    "schema_version": 1,
    "id": profile_id,
    "name": name or profile_id,
    "description": f"Illustrative {profile_id} profile.",
    "order": order,
    "platform": {"os": "example", "distribution": "example", "version": "1"},
    "requirements": [],
    "categories": categories,
  }


def snapshot(directory):
  result = {}
  for path in sorted(directory.rglob("*")):
    relative = str(path.relative_to(directory))
    if path.is_symlink():
      result[relative] = ("symlink", os.readlink(path))
    elif path.is_dir():
      result[relative] = ("directory",)
    else:
      result[relative] = ("file", path.read_bytes(), path.stat().st_mode & 0o777)
  return result


class ProjectTests(unittest.TestCase):
  def make_project(self, records):
    temporary = tempfile.TemporaryDirectory(prefix="test-setup-tui-")
    self.addCleanup(temporary.cleanup)
    base = Path(temporary.name)
    root = base / "repo"
    scripts = root / "scripts"
    scripts.mkdir(parents=True)
    (scripts / "setup").symlink_to(SCRIPT_SOURCE)
    (root / "src").mkdir()
    for directory, manifest in records:
      path = root / "src" / directory / "profile.json"
      path.parent.mkdir(parents=True, exist_ok=True)
      if isinstance(manifest, str):
        path.write_text(manifest, encoding="utf-8")
      else:
        path.write_text(json.dumps(manifest, ensure_ascii=False), encoding="utf-8")
    home = base / "home"
    home.mkdir()
    return root, home

  def start(self, root, home, *arguments, width=80, height=24):
    session = TerminalSession(root, home, arguments, width, height)
    self.addCleanup(self.finish, session)
    session.read_for(0.15)
    return session

  def finish(self, session):
    if session.master is None:
      return
    code, restored, entered = session.close()
    self.assertTrue(restored, "terminal settings were not restored")
    if entered:
      self.assertIn("\x1b[?25h\x1b[?1049l", session.output)
    self.assertEqual(code, session.expected_exit)

  def test_sample_manifest_is_inert_and_has_four_categories(self):
    path = ROOT / "src" / "demo" / "profile.json"
    document = json.loads(path.read_text(encoding="utf-8"))
    self.assertEqual(document["schema_version"], 1)
    self.assertEqual(document["id"], "demo")
    self.assertEqual([item["name"] for item in document["categories"]], [
      "Dotfiles", "Fuentes", "Dependencias", "Servicios",
    ])
    self.assertEqual(document["requirements"], [])
    self.assertTrue(all(item["requirements"] == [] for item in document["categories"]))
    self.assertTrue(all(
      component["items"] == []
      for item in document["categories"]
      for component in item["components"]
    ))

  def test_script_is_an_executable_standalone_entrypoint(self):
    script = ROOT / "scripts" / "setup"
    self.assertTrue(script.is_file())
    self.assertTrue(os.access(script, os.X_OK))

  def test_direct_profile_skips_selector_and_starts_unselected(self):
    root, home = self.make_project([("demo", profile())])
    session = self.start(root, home, "--profile", "demo")
    screen = strip_ansi(session.screen())
    self.assertIn("Paso 1 · Categorías", screen)
    self.assertNotIn("Selecciona un perfil", screen)
    self.assertEqual(screen.count("[ ]"), 4)
    self.assertIn("Dotfiles", screen)

  def test_discovery_is_ordered_and_duplicate_ids_are_unselectable(self):
    records = [
      ("zeta", profile("zeta", "Zeta", 5)),
      ("alpha", profile("alpha", "Alpha", 1)),
      ("beta", profile("beta", "Beta", 2)),
      ("gamma", profile("gamma", "Gamma", 2)),
      ("dup-a", profile("duplicate", "Duplicate A", 3)),
      ("dup-b", profile("duplicate", "Duplicate B", 3)),
    ]
    root, home = self.make_project(records)
    session = self.start(root, home)
    screen = strip_ansi(session.screen())
    names = ["Alpha", "Beta", "Gamma", "Duplicate A", "Duplicate B", "Zeta"]
    positions = [screen.index(name) for name in names]
    self.assertEqual(positions, sorted(positions))
    for line in screen.splitlines():
      if "Duplicate " in line:
        self.assertIn("no seleccionable", line)
    self.assertIn("› Alpha", screen)
    session.send(b"\x1b[B")
    self.assertIn("› Beta", strip_ansi(session.screen()))
    session.send(b"\x1b[B")
    self.assertIn("› Gamma", strip_ansi(session.screen()))
    session.send(b"\x1b[B")
    self.assertIn("› Zeta", strip_ansi(session.screen()))
    session.send(b"\r")
    self.assertIn("Paso 2 · Categorías", strip_ansi(session.screen()))
    self.assertIn("Zeta", strip_ansi(session.screen()))

    result = subprocess.run(
      ["/usr/bin/bash", str(root / "scripts" / "setup"), "--profile", "duplicate"],
      capture_output=True,
      env={"HOME": str(home), "LANG": "C.UTF-8", "PATH": "/usr/bin:/bin", "TERM": "xterm-256color"},
      timeout=2,
    )
    self.assertEqual(result.returncode, 2)
    self.assertEqual(result.stdout, b"")
    self.assertEqual(
      result.stderr,
      b"scripts/setup: requested profile has a duplicate id and is not selectable\n",
    )

  def test_invalid_and_malformed_manifests_leave_valid_profiles_available(self):
    root, home = self.make_project([
      ("good", profile("good", "Available profile", 1)),
      ("broken", '{"schema_version":'),
    ])
    (root / "src" / "ignored").mkdir()
    session = self.start(root, home)
    screen = strip_ansi(session.screen())
    self.assertIn("Available profile", screen)
    self.assertIn("1 manifiesto inválido", screen)
    self.assertNotIn("ignored", screen)
    session.send(b"\r")
    self.assertIn("Paso 2 · Categorías", strip_ansi(session.screen()))

  def test_control_characters_are_rejected_without_terminal_injection(self):
    root, home = self.make_project([
      ("safe", profile("safe", "Safe profile", 1)),
      ("unsafe", profile("unsafe", "Unsafe\x1b[31m profile", 2)),
    ])
    session = self.start(root, home)
    screen = session.screen()
    self.assertIn("Safe profile", strip_ansi(screen))
    self.assertIn("1 manifiesto inválido", strip_ansi(screen))
    self.assertNotIn("\x1b[31m", screen)

  def test_empty_guards_back_selection_review_and_no_mutations(self):
    root, home = self.make_project([("demo", profile())])
    before_root = snapshot(root)
    before_home = snapshot(home)
    session = self.start(root, home, "--profile", "demo")

    session.send(b"\x1b[B" * 5 + b"\r")
    self.assertIn("Selecciona al menos una categoría", strip_ansi(session.screen()))
    session.send(b"\x1b[A\r")
    self.assertIn("Paso 1 · Perfil", strip_ansi(session.screen()))
    session.send(b"\r")
    self.assertIn("Paso 2 · Categorías", strip_ansi(session.screen()))

    session.send(b" ")
    session.send(b"\x1b[B ")
    session.send(b"\x1b[B" * 4 + b"\r")
    component_screen = strip_ansi(session.screen())
    self.assertIn("Componentes · Dotfiles", component_screen)
    self.assertIn("[ ] Shell", component_screen)
    session.send(b"\x1b[B\x1b[B\r")
    self.assertIn("Selecciona al menos un componente", strip_ansi(session.screen()))
    session.send(b"\x1b[B\r")
    categories_screen = strip_ansi(session.screen())
    self.assertIn("[x] Dotfiles", categories_screen)
    self.assertIn("[x] Fuentes", categories_screen)

    session.send(b"\x1b[B" * 5 + b"\r")
    session.send(b" \x1b[B\x1b[B\r")
    self.assertIn("Componentes · Fuentes", strip_ansi(session.screen()))
    self.assertIn("[ ] Fuente de ejemplo", strip_ansi(session.screen()))
    session.send(b" \x1b[B\x1b[B\r")
    review = strip_ansi(session.screen())
    self.assertIn("Revisión", review)
    self.assertIn("Dotfiles", review)
    self.assertIn("Shell", review)
    self.assertIn("Fuentes", review)
    self.assertIn("Fuente de ejemplo", review)
    self.assertIn("› ← Volver", review)
    self.assertIn("Instalar (deshabilitado)", review)
    self.assertIn("Instalación no disponible en esta plantilla.", review)
    session.send(b"\x1b[B\r")
    self.assertIn("Instalación no disponible en esta plantilla.", strip_ansi(session.screen()))
    self.assertEqual(snapshot(root), before_root)
    self.assertEqual(snapshot(home), before_home)
    session.send(b"\x1b[A\r")
    self.assertIn("[x] Fuente de ejemplo", strip_ansi(session.screen()))
    session.send(b"\x1b[B\r")
    self.assertIn("[x] Shell", strip_ansi(session.screen()))
    session.send(b"\x1b[B\r")
    categories_screen = strip_ansi(session.screen())
    self.assertIn("[x] Dotfiles", categories_screen)
    self.assertIn("[x] Fuentes", categories_screen)

  def test_scroll_resize_and_focus_survive_small_terminal(self):
    categories = [category(f"category-{index:02d}", f"Category {index:02d}") for index in range(30)]
    root, home = self.make_project([("many", profile("many", "Many categories", categories=categories))])
    session = self.start(root, home, "--profile", "many")
    self.assertIn("↓ Más", strip_ansi(session.screen()))
    session.send(b"\x1b[B" * 20)
    screen = strip_ansi(session.screen())
    self.assertIn("↑ Más", screen)
    self.assertIn("Category 20", screen)

    session.resize(24, 5)
    screen = strip_ansi(session.screen())
    self.assertIn("Amplía la terminal", screen)
    self.assertLessEqual(len(screen.splitlines()), 5)
    session.resize(80, 24)
    screen = strip_ansi(session.screen())
    self.assertIn("Category 20", screen)
    self.assertIn("↑ Más", screen)
    self.assertLessEqual(len(screen.splitlines()), 24)

  def test_escape_and_term_signal_restore_terminal(self):
    root, home = self.make_project([("demo", profile())])
    session = self.start(root, home)
    session.send(b"\x1b")
    self.assertEqual(session.process.wait(timeout=2), 0)
    self.assertIn("\x1b[?25h\x1b[?1049l", session.output)
    self.assertEqual(termios.tcgetattr(session.slave), session.original)

    signaled_root, signaled_home = self.make_project([("demo", profile())])
    signaled = self.start(signaled_root, signaled_home)
    signaled.expected_exit = 143
    signaled.process.send_signal(signal.SIGTERM)
    self.assertEqual(signaled.process.wait(timeout=2), 143)
    signaled.read_for(0.05)
    self.assertIn("\x1b[?25h\x1b[?1049l", signaled.output)
    self.assertEqual(termios.tcgetattr(signaled.slave), signaled.original)


class TerminalSession:
  def __init__(self, root, home, arguments, width, height):
    self.master, self.slave = pty.openpty()
    self.original = termios.tcgetattr(self.slave)
    self.resize(width, height)
    self.output = ""
    self.expected_exit = 0
    environment = {
      "HOME": str(home),
      "LANG": "C.UTF-8",
      "PATH": "/usr/bin:/bin",
      "TERM": "xterm-256color",
      "COLORTERM": "truecolor",
    }
    script = root / "scripts" / "setup"
    self.process = subprocess.Popen(
      ["/usr/bin/bash", str(script), *arguments],
      stdin=self.slave,
      stdout=self.slave,
      stderr=self.slave,
      env=environment,
    )

  def resize(self, width, height):
    fcntl.ioctl(self.slave, termios.TIOCSWINSZ, struct.pack("HHHH", height, width, 0, 0))
    if hasattr(self, "process") and self.process.poll() is None:
      self.process.send_signal(signal.SIGWINCH)

  def read_for(self, seconds=0.12):
    end = time.monotonic() + seconds
    data = bytearray()
    while time.monotonic() < end:
      ready, _, _ = select.select([self.master], [], [], max(0, end - time.monotonic()))
      if not ready:
        break
      try:
        data.extend(os.read(self.master, 65536))
      except OSError as error:
        if error.errno != errno.EIO:
          raise
        break
    self.output += data.decode("utf-8", errors="replace")
    return self.output

  def screen(self):
    return self.output.split(CLEAR)[-1]

  def send(self, value):
    os.write(self.master, value)
    return self.read_for()

  def close(self):
    if self.process.poll() is None:
      for _ in range(8):
        if self.process.poll() is not None:
          break
        self.send(b"\x1b")
    if self.process.poll() is None:
      self.process.terminate()
    try:
      code = self.process.wait(timeout=2)
    except subprocess.TimeoutExpired:
      self.process.kill()
      code = self.process.wait(timeout=1)
    self.read_for(0.02)
    restored = termios.tcgetattr(self.slave) == self.original
    entered = "\x1b[?1049h" in self.output
    os.close(self.master)
    os.close(self.slave)
    self.master = None
    self.slave = None
    return code, restored, entered


if __name__ == "__main__":
  unittest.main()
