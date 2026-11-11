"""Public terminal contracts for the Bash Profiles demo; no setup is executed."""
import errno
import fcntl
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

ROOT = Path(__file__).resolve().parent
ERROR_DETAIL = (
  "Simulated EACCES while reading the declared setup reference; demo fixtures only."
)
CLEAR = "\x1b[H\x1b[2J"


class Terminal:
  def __init__(self, scenario="normal", width=80, height=24, delay="0.12", fault=False,
               colorterm="truecolor", extra_env=None, expected_exit=0):
    self.master, self.slave = pty.openpty()
    self.original = termios.tcgetattr(self.slave)
    self.resize(width, height)
    env = dict(os.environ, TERM="xterm-256color", PROFILE_DEMO_SCENARIO=scenario,
               PROFILE_DEMO_DELAY=delay, PROFILE_DEMO_TEST_FAULT="render" if fault else "")
    if colorterm is None:
      env.pop("COLORTERM", None)
    else:
      env["COLORTERM"] = colorterm
    if extra_env:
      env.update(extra_env)
    self.expected_exit = expected_exit
    self.process = subprocess.Popen(["bash", str(ROOT / "demo.sh")], stdin=self.slave,
                                    stdout=self.slave, stderr=self.slave, env=env)
    self.output = ""

  def resize(self, width, height):
    fcntl.ioctl(self.slave, termios.TIOCSWINSZ, struct.pack("HHHH", height, width, 0, 0))

  def read(self, seconds=0.22):
    end = time.monotonic() + seconds
    data = b""
    while time.monotonic() < end:
      if select.select([self.master], [], [], max(0, end - time.monotonic()))[0]:
        try:
          data += os.read(self.master, 65536)
        except OSError as error:
          if error.errno != errno.EIO:
            raise
          break
    self.output += data.decode("utf-8", errors="replace")
    return self.output

  def send(self, key):
    os.write(self.master, key)
    return self.read()

  def screen(self):
    return self.output.split(CLEAR)[-1]

  def close(self):
    if self.process.poll() is None:
      self.send(b"\x1b")
    try:
      code = self.process.wait(timeout=2)
    except subprocess.TimeoutExpired:
      self.process.kill()
      self.process.wait()
      raise AssertionError("Esc did not exit")
    self.read(0.02)
    restored = termios.tcgetattr(self.slave) == self.original
    entered = "\x1b[?1049h" in self.output
    if entered:
      assert "\x1b[?25h\x1b[?1049l" in self.output
    os.close(self.master)
    os.close(self.slave)
    return code, restored, entered


class DemoTests(unittest.TestCase):
  def launch(self, *args, **kwargs):
    terminal = Terminal(*args, **kwargs)
    self.addCleanup(self.finish, terminal)
    terminal.read()
    return terminal

  def finish(self, terminal):
    if terminal.master is not None:
      code, restored, entered = terminal.close()
      terminal.master = None
      self.assertTrue(restored)
      if entered:
        self.assertIn("\x1b[?25h\x1b[?1049l", terminal.output)
      self.assertEqual(code, terminal.expected_exit)

  def test_normal_bounded_navigation_and_return(self):
    t = self.launch()
    self.assertIn("Select profile", t.screen())
    t.send(b"\x1b[A\r")
    self.assertIn("Selected fixture: omarchy", t.screen())
    t.send(b"\x1b")
    t.send(b"\x1b[B\x1b[B\r")
    self.assertIn("Selected fixture: fedora-wsl2", t.screen())
    t.send(b"\x1b")
    t.send(b"\r")
    self.assertIn("Selected fixture: fedora-wsl2", t.screen())
    t.send(b"\x1b")

  def test_first_unavailable_is_skipped_in_both_directions(self):
    t = self.launch("first-unavailable")
    self.assertIn("omarchy · Unavailable", t.screen())
    t.send(b"\x1b[A\r")
    self.assertIn("Selected fixture: fedora-wsl2", t.screen())
    t.send(b"\x1b")

  def test_all_unavailable(self):
    t = self.launch("all-unavailable")
    self.assertEqual(t.screen().count("· Unavailable"), 2)
    self.assertIn("No compatible profiles available.", t.screen())
    t.send(b"\x1b[B\x1b[A\r")
    self.assertNotIn("SIMULATION ONLY", t.screen())
    self.assertNotIn("48;2;41;47;57", t.screen())

  def test_empty(self):
    t = self.launch("empty")
    self.assertIn("No profiles available.", t.screen())
    self.assertNotIn("Navigate", t.screen())
    t.send(b"\r")
    self.assertIn("No profiles available.", t.screen())

  def test_error_wraps_detail_without_retry(self):
    t = self.launch("error", width=36)
    self.assertIn("Availability check failed.", t.screen())
    self.assertIn("38;2;229;139;139", t.screen())
    self.assertIn("EACCES", t.screen())
    plain = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", t.screen())
    detail = " ".join(line.strip(" │\r") for line in plain.splitlines())
    self.assertIn(ERROR_DETAIL, detail)
    before = t.screen()
    t.send(b"\x1b[A\x1b[B\r")
    self.assertEqual(t.screen(), before)
    self.assertNotIn("No compatible", t.screen())

  def test_long_scroll_and_return(self):
    t = self.launch("long", height=18)
    self.assertNotIn("↑ More", t.screen())
    self.assertIn("↓ More", t.screen())
    for _ in range(10):
      t.send(b"\x1b[B")
    before = t.screen()
    self.assertIn("↑ More", before)
    t.send(b"\r")
    self.assertIn("Selected fixture: fixture-09", t.screen())
    t.send(b"\x1b")
    self.assertEqual(t.screen(), before)
    for _ in range(30):
      os.write(t.master, b"\x1b[B")
    t.read()
    self.assertNotIn("↓ More", t.screen())
    self.assertIn("↑ More", t.screen())

  def test_return_changes_availability(self):
    t = self.launch("return-change")
    t.send(b"\x1b[B\r")
    self.assertIn("Selected fixture: fedora-wsl2", t.screen())
    t.send(b"\x1b")
    self.assertIn("fedora-wsl2 · Unavailable", t.screen())
    t.send(b"\r")
    self.assertIn("Selected fixture: omarchy", t.screen())
    t.send(b"\x1b")

  def test_loading_blocks_navigation_but_not_escape(self):
    t = self.launch(delay="2")
    self.assertIn("Checking profile availability...", t.screen())
    self.assertLess(t.screen().index("Checking profile availability..."), t.screen().index("┘"))
    t.send(b"\x1b[B\r")
    self.assertNotIn("SIMULATION ONLY", t.screen())
    start = time.monotonic()
    t.send(b"\x1b")
    self.assertEqual(t.process.wait(timeout=0.5), 0)
    self.assertLess(time.monotonic() - start, 0.6)

  def test_spinner_animates_during_nonblocking_check(self):
    t = self.launch(delay="2")
    t.read(0.38)
    frames = [frame for frame in t.output.split(CLEAR) if "Checking profile availability..." in frame]
    spinner = set("⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏")
    seen = {next((glyph for glyph in spinner if glyph in frame), "") for frame in frames}
    self.assertGreaterEqual(len(seen - {""}), 2)

  def test_return_loading_keeps_list_and_blocks_selection(self):
    t = self.launch(delay="0.6")
    t.read(0.5)
    t.send(b"\x1b[B\r")
    t.send(b"\x1b")
    screen = t.screen()
    self.assertIn("fedora-wsl2", screen)
    self.assertGreater(screen.index("Checking profile availability..."), screen.index("┘"))
    t.send(b"\x1b[A\r")
    t.read(0.4)
    t.send(b"\r")
    self.assertIn("Selected fixture: fedora-wsl2", t.screen())
    t.send(b"\x1b")

  def test_narrow_and_resize(self):
    t = self.launch(width=32, height=24)
    screen = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", t.screen())
    self.assertIn("Choose the environment", screen)
    self.assertIn("configure", screen)
    self.assertIn("…", screen)
    self.assertIn("Enter Select", screen)
    self.assertIn("Esc Exit", screen)
    self.assertTrue(all(len(line) < 32 for line in screen.splitlines()))
    t.resize(100, 30)
    t.read()
    self.assertIn("Choose the environment to configure", t.screen())
    t.resize(12, 6)
    t.read()
    self.assertIn("Esc Exit", t.screen())

  def test_exception_and_signals_restore_terminal(self):
    t = self.launch(fault=True, expected_exit=1)
    self.assertIn("Simulated render exception", t.output)
    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
      t = self.launch()
      t.process.send_signal(sig)
      t.read()
      self.assertEqual(t.process.poll(), 0)

  def test_visual_hierarchy_panel_padding_and_focus_block(self):
    raw = self.launch().screen()
    lines = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", raw).splitlines()
    top = next(i for i, line in enumerate(lines) if "┌" in line)
    bottom = next(i for i, line in enumerate(lines) if "┘" in line)
    self.assertIn("\x1b[1mSelect profile\x1b[22m", raw)
    self.assertEqual(lines[top].index("┌"), 8)
    self.assertEqual(len(lines[top].strip()), 64)
    self.assertEqual(lines[top + 1].strip(" │"), "")
    self.assertEqual(lines[bottom - 1].strip(" │"), "")
    self.assertTrue(lines[top + 2].startswith("        │  omarchy"))
    self.assertEqual(bottom - top, 7)
    self.assertEqual(lines[top - 1].strip(), "")
    self.assertEqual(lines[bottom + 1].strip(), "")
    focus = "\x1b[48;2;41;47;57m"
    focused = [line for line in raw.splitlines() if focus in line]
    self.assertEqual(len(focused), 2)
    for line in focused:
      block = line.split(focus, 1)[1].split("\x1b[48;2;20;23;28m", 1)[0]
      block = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", block)
      self.assertTrue(block.startswith(" ") and block.endswith(" "))
      self.assertEqual(len(block), 60)
      self.assertNotIn("\x1b[1m", line)

  def test_layout_budget_and_fixed_chrome_while_scrolling(self):
    for width, height in ((80, 24), (80, 18), (32, 24), (32, 18), (26, 16)):
      with self.subTest(width=width, height=height):
        t = self.launch("long", width=width, height=height)

        def lines():
          return re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", t.screen()).splitlines()

        before = lines()
        self.assertIn("Select profile", "\n".join(before))
        self.assertIn("Esc Exit", "\n".join(before))
        for _ in range(12):
          os.write(t.master, b"\x1b[B")
        t.read()
        after = lines()
        self.assertLessEqual(len(after), height)
        self.assertTrue(all(len(line) < width for line in after))
        self.assertEqual(next(i for i, line in enumerate(before) if "Select profile" in line),
                         next(i for i, line in enumerate(after) if "Select profile" in line))
        self.assertEqual(next(i for i, line in enumerate(before) if "Esc Exit" in line),
                         next(i for i, line in enumerate(after) if "Esc Exit" in line))
        self.assertIn("↑ More", t.screen())
        self.assertIn("↓ More", t.screen())
        self.finish(t)

  def test_utf8_panel_rows_keep_the_same_border_column(self):
    for scenario, width in (("first-unavailable", 80), ("long", 32)):
      with self.subTest(scenario=scenario, width=width):
        t = self.launch(scenario, width=width)
        lines = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", t.screen()).splitlines()
        border = next(line for line in lines if "┌" in line)
        right = border.index("┐")
        for line in lines:
          if "│" in line:
            self.assertEqual(line.rindex("│"), right)
        self.finish(t)

  def test_narrow_return_preserves_viewport_during_and_after_check(self):
    t = self.launch("long", width=36, height=24, delay="0.6")
    t.read(0.5)
    for _ in range(10):
      os.write(t.master, b"\x1b[B")
    t.read()
    def panel():
      plain = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", t.screen())
      return plain[plain.index("┌"):plain.index("┘") + 1]
    before = panel()
    t.send(b"\r")
    t.send(b"\x1b")
    self.assertIn("Checking profile", t.screen())
    self.assertEqual(panel(), before)
    t.read(0.5)
    self.assertEqual(panel(), before)

  def test_color_fallback_uses_256_color_without_truecolor_codes(self):
    screen = self.launch(colorterm=None).screen()
    self.assertIn("38;5;", screen)
    self.assertIn("48;5;", screen)
    self.assertNotIn(";2;", screen)

  def test_central_tsv_has_order_and_no_availability_flag(self):
    rows = (ROOT / "fixtures.tsv").read_text(encoding="utf-8").splitlines()
    self.assertEqual(rows[0].split("\t"), ["order", "id", "name", "description", "setup"])
    profiles = [row.split("\t") for row in rows[1:]]
    self.assertEqual([row[1] for row in profiles], ["omarchy", "fedora-wsl2"])
    self.assertTrue(all(len(row) == 5 for row in profiles))
    self.assertTrue(all(row[4].startswith("../../") for row in profiles))
    self.assertNotIn("available", rows[0].split("\t"))
    self.assertNotIn("printf '%b'", (ROOT / "demo.sh").read_text(encoding="utf-8"))

  def test_filesystem_availability_is_read_only_file_and_execute_check(self):
    with tempfile.TemporaryDirectory(prefix="test-fixtures-fs-", dir=ROOT) as directory:
      root = Path(directory)
      script_dir = root / "prototypes" / "profile-selector"
      script_dir.mkdir(parents=True)
      omarchy_setup = root / "omarchy" / "utils" / "bash" / "setup-omarchy"
      fedora_setup = root / "fedora-wsl2" / "utils" / "bash" / "setup-fedora-wsl2"
      omarchy_setup.parent.mkdir(parents=True)
      fedora_setup.parent.mkdir(parents=True)
      marker = root / "must-not-run"
      omarchy_setup.write_text(f"#!/usr/bin/env bash\nprintf ran > '{marker}'\n", encoding="utf-8")
      omarchy_setup.chmod(0o755)
      fedora_setup.write_text("not executable\n", encoding="utf-8")
      fedora_setup.chmod(0o644)
      registry = root / "fixtures.tsv"
      registry.write_text(
        "order\tid\tname\tdescription\tsetup\n"
        "1\tomarchy\tomarchy\tExecutable fixture\t../../omarchy/utils/bash/setup-omarchy\n"
        "2\tfedora-wsl2\tfedora-wsl2\tNon-executable fixture\t../../fedora-wsl2/utils/bash/setup-fedora-wsl2\n"
        "3\tmissing\tmissing\tMissing fixture\t../../omarchy/utils/bash/not-present\n",
        encoding="utf-8")
      t = self.launch("filesystem", extra_env={
        "PROFILE_DEMO_SETUP_ROOT": str(script_dir),
        "PROFILE_DEMO_FIXTURE_FILE": str(registry),
      })
      self.assertIn("omarchy", t.screen())
      self.assertNotIn("omarchy · Unavailable", t.screen())
      self.assertIn("fedora-wsl2 · Unavailable", t.screen())
      self.assertIn("missing · Unavailable", t.screen())
      t.send(b"\r")
      self.assertIn("Selected fixture: omarchy", t.screen())
      self.assertFalse(marker.exists())
      t.send(b"\x1b")
      t.send(b"\x1b")
      self.assertEqual(t.process.wait(timeout=1), 0)
      self.finish(t)

  def test_invalid_fixture_rows_are_rejected_without_terminal_controls(self):
    with tempfile.TemporaryDirectory(prefix="test-fixtures-invalid-", dir=ROOT) as directory:
      registry = Path(directory) / "invalid.tsv"
      registry.write_text(
        "order\tid\tname\tdescription\tsetup\n"
        "1\tbad\tbad\tunsafe \x1b[31mtext\t../../not-run\n", encoding="utf-8")
      t = self.launch(extra_env={"PROFILE_DEMO_FIXTURE_FILE": str(registry)}, expected_exit=1)
      t.process.wait(timeout=1)
      self.assertIn("Profile demo: invalid fixtures row 2", t.output)
      self.assertNotIn("\x1b[31m", t.output)
      self.assertNotIn("\x1b[?1049h", t.output)
      self.finish(t)

  def test_non_tty_has_explicit_error(self):
    result = subprocess.run(["bash", str(ROOT / "demo.sh")], capture_output=True)
    self.assertEqual(result.returncode, 2)
    self.assertEqual(result.stdout, b"")
    self.assertEqual(result.stderr, b"Profile demo requires an interactive terminal.\n")


if __name__ == "__main__":
  unittest.main()
