"""Check restart and shutdown without starting a real greeter."""
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

with tempfile.TemporaryDirectory(prefix="loginpanel-supervisor-") as directory:
    root = Path(directory)
    record = root / "children"
    panel = root / "loginpanel"
    panel.write_text("#!" + sys.executable + "\n" + f"""
import os, signal, time
from pathlib import Path
record = Path({str(record)!r})
first = not record.exists()
with record.open('a') as stream:
    stream.write(str(os.getpid()) + '\\n')
if first:
    raise SystemExit(1)
signal.signal(signal.SIGTERM, lambda *args: exit(0))
while True:
    time.sleep(0.1)
""")
    panel.chmod(0o700)
    process = subprocess.Popen([sys.argv[1]], env={**os.environ, "PATH": directory + ":" + os.environ["PATH"]})
    try:
        deadline = time.monotonic() + 8
        children = []
        while time.monotonic() < deadline:
            children = record.read_text().splitlines() if record.exists() else []
            if len(children) >= 2:
                break
            time.sleep(0.05)
        assert len(children) == 2, "Supervisor did not restart the failed greeter"
        time.sleep(0.1)
        process.send_signal(signal.SIGTERM)
        assert process.wait(timeout=5) == 0
        try:
            os.kill(int(children[-1]), 0)
        except ProcessLookupError:
            pass
        else:
            raise AssertionError("Supervisor left its greeter running")
        assert len(record.read_text().splitlines()) == 2
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        for child in record.read_text().splitlines() if record.exists() else []:
            try:
                os.kill(int(child), signal.SIGTERM)
            except ProcessLookupError:
                pass
print("supervisor: PASS")
