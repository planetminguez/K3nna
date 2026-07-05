import os
import sys
import uuid
import subprocess
import threading
import json
import shutil
import tempfile
import platform
import time
from datetime import datetime
from flask import Flask, request, jsonify, send_file
from pathlib import Path

app = Flask(__name__)

UPLOAD_DIR = Path(tempfile.gettempdir()) / "k3nna_uploads"
OUTPUT_DIR = Path(tempfile.gettempdir()) / "k3nna_outputs"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

jobs = {}
jobs_lock = threading.Lock()


def get_python_path():
    for p in ["python3", "python"]:
        path = shutil.which(p)
        if path:
            return path
    return "python3"


def ts():
    return datetime.now().strftime("%H:%M:%S.%f")[:-3]


def append_log(job_id, line):
    with jobs_lock:
        jobs[job_id]["log_lines"].append(line)
        jobs[job_id]["log"] = "".join(jobs[job_id]["log_lines"])


def step_log(job_id, msg):
    append_log(job_id, f"[{ts()}] [STEP] {msg}\n")


def info_log(job_id, msg):
    append_log(job_id, f"[{ts()}] [INFO] {msg}\n")


def warn_log(job_id, msg):
    append_log(job_id, f"[{ts()}] [WARN] {msg}\n")


def ok_log(job_id, msg):
    append_log(job_id, f"[{ts()}] [ OK ] {msg}\n")


def err_log(job_id, msg):
    append_log(job_id, f"[{ts()}] [ERR ] {msg}\n")


def set_progress(job_id, pct, status_msg=None):
    with jobs_lock:
        jobs[job_id]["progress"] = pct
        if status_msg:
            jobs[job_id]["status_msg"] = status_msg


def run_conversion(job_id, file_path, options):
    python = get_python_path()
    file_path = Path(file_path)
    output_dir = OUTPUT_DIR / job_id
    output_dir.mkdir(parents=True, exist_ok=True)
    build_dir = output_dir / "build"

    with jobs_lock:
        jobs[job_id]["status"] = "running"

    try:
        # ── STEP 1: Environment info ──────────────────────────────────────────
        step_log(job_id, "═══════════════════════════════════════════════════")
        step_log(job_id, "  K3NNA — Python Execution Compiler")
        step_log(job_id, "  Starting conversion pipeline...")
        step_log(job_id, "═══════════════════════════════════════════════════")
        set_progress(job_id, 2, "Gathering environment info...")

        info_log(job_id, f"Host OS       : {platform.system()} {platform.release()} ({platform.machine()})")
        info_log(job_id, f"Python binary : {python}")

        py_ver = subprocess.check_output([python, "--version"], stderr=subprocess.STDOUT, text=True).strip()
        info_log(job_id, f"Python version: {py_ver}")

        py_prefix = subprocess.check_output([python, "-c", "import sys; print(sys.prefix)"], text=True).strip()
        info_log(job_id, f"Python prefix : {py_prefix}")

        try:
            pi_ver = subprocess.check_output(
                [python, "-m", "PyInstaller", "--version"],
                stderr=subprocess.STDOUT, text=True
            ).strip()
            info_log(job_id, f"PyInstaller   : {pi_ver}")
        except Exception:
            warn_log(job_id, "Could not detect PyInstaller version")

        info_log(job_id, f"Temp upload   : {UPLOAD_DIR}")
        info_log(job_id, f"Output dir    : {output_dir}")

        # ── STEP 2: File validation ───────────────────────────────────────────
        step_log(job_id, "─── STEP 1 / 6 ─── Validating source file")
        set_progress(job_id, 6, "Validating source file...")

        if not file_path.exists():
            err_log(job_id, f"File not found: {file_path}")
            raise FileNotFoundError(str(file_path))

        file_size = file_path.stat().st_size
        info_log(job_id, f"Script path   : {file_path}")
        info_log(job_id, f"Script name   : {file_path.name}")
        info_log(job_id, f"Script size   : {file_size:,} bytes")

        # Count lines & imports
        source = file_path.read_text(errors="replace")
        lines = source.splitlines()
        imports = [l.strip() for l in lines if l.startswith("import ") or l.startswith("from ")]
        info_log(job_id, f"Source lines  : {len(lines)}")
        info_log(job_id, f"Import stmts  : {len(imports)}")
        for imp in imports[:20]:
            info_log(job_id, f"  └─ {imp}")
        if len(imports) > 20:
            info_log(job_id, f"  └─ ... and {len(imports)-20} more")
        ok_log(job_id, "Source file validated successfully")

        # ── STEP 3: Build PyInstaller command ─────────────────────────────────
        step_log(job_id, "─── STEP 2 / 6 ─── Building PyInstaller command")
        set_progress(job_id, 12, "Building command...")

        args = [python, "-m", "PyInstaller", "--log-level", "DEBUG"]

        if options.get("oneFile", True):
            args.append("--onefile")
            info_log(job_id, "Option: --onefile         (bundle into single executable)")
        else:
            info_log(job_id, "Option: [no --onefile]    (directory output)")

        if options.get("windowed", True):
            args.append("--windowed")
            info_log(job_id, "Option: --windowed        (suppress console window)")

        if options.get("stripBinaries", False):
            args.append("--strip")
            info_log(job_id, "Option: --strip           (strip debug symbols)")

        if options.get("optimize", False):
            args.append("--optimize=2")
            info_log(job_id, "Option: --optimize=2      (Python bytecode optimization)")

        custom = options.get("customOptions", "").strip()
        if custom:
            extra = custom.split()
            args.extend(extra)
            info_log(job_id, f"Option: custom args       {extra}")

        args.extend([
            "--clean",
            "--distpath", str(output_dir / "dist"),
            "--workpath", str(build_dir),
            "--specpath", str(output_dir),
            str(file_path)
        ])

        info_log(job_id, f"Option: --clean           (remove stale build cache)")
        info_log(job_id, f"Option: --distpath        {output_dir / 'dist'}")
        info_log(job_id, f"Option: --workpath        {build_dir}")
        info_log(job_id, f"Option: --specpath        {output_dir}")
        info_log(job_id, f"Full command:")
        info_log(job_id, "  " + " ".join(str(a) for a in args))
        ok_log(job_id, "Command assembled")

        # ── STEP 4: Dependency pre-check ─────────────────────────────────────
        step_log(job_id, "─── STEP 3 / 6 ─── Pre-flight dependency check")
        set_progress(job_id, 18, "Checking dependencies...")

        for mod in ["PyInstaller", "setuptools", "pkg_resources"]:
            try:
                result = subprocess.run(
                    [python, "-c", f"import importlib; m=importlib.import_module('{mod}'); print(getattr(m,'__version__','?'))"],
                    capture_output=True, text=True, timeout=10
                )
                ver = result.stdout.strip() or "found"
                info_log(job_id, f"Module check  : {mod} == {ver}")
            except Exception:
                warn_log(job_id, f"Module check  : {mod} — not importable (may still work)")

        ok_log(job_id, "Dependency check complete")

        # ── STEP 5: Run PyInstaller ───────────────────────────────────────────
        step_log(job_id, "─── STEP 4 / 6 ─── Running PyInstaller (verbose)")
        set_progress(job_id, 22, "Running PyInstaller...")
        info_log(job_id, f"Spawning subprocess PID (pending)...")
        info_log(job_id, "Streaming output below ↓")
        append_log(job_id, f"[{ts()}] [    ] {'─'*51}\n")

        proc = subprocess.Popen(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            cwd=str(file_path.parent)
        )
        info_log(job_id, f"Subprocess PID: {proc.pid}")

        line_count = 0
        phase_progress = 22

        for raw_line in proc.stdout:
            line = raw_line.rstrip("\n")
            line_count += 1

            # Auto-advance progress based on PyInstaller phases
            low = line.lower()
            if "analysing" in low or "analyzing" in low:
                phase_progress = max(phase_progress, 30)
            elif "checking" in low:
                phase_progress = max(phase_progress, 45)
            elif "building pyz" in low:
                phase_progress = max(phase_progress, 55)
            elif "building pkg" in low:
                phase_progress = max(phase_progress, 65)
            elif "building exe" in low:
                phase_progress = max(phase_progress, 75)
            elif "appending" in low:
                phase_progress = max(phase_progress, 82)
            elif "build complete" in low or "completed successfully" in low:
                phase_progress = max(phase_progress, 88)

            if phase_progress < 88:
                phase_progress = min(phase_progress + 0.3, 88)

            set_progress(job_id, int(phase_progress))
            append_log(job_id, f"[{ts()}] [PYIS] {line}\n")

        proc.wait()
        append_log(job_id, f"[{ts()}] [    ] {'─'*51}\n")
        info_log(job_id, f"PyInstaller exited — return code: {proc.returncode}")
        info_log(job_id, f"Total output lines streamed: {line_count}")

        if proc.returncode != 0:
            err_log(job_id, "PyInstaller reported a non-zero exit code — build FAILED")
            with jobs_lock:
                jobs[job_id]["status"] = "failed"
                jobs[job_id]["progress"] = 0
                jobs[job_id]["error"] = f"PyInstaller exited with code {proc.returncode}"
            return

        ok_log(job_id, "PyInstaller finished successfully")

        # ── STEP 6: Locate executable ─────────────────────────────────────────
        step_log(job_id, "─── STEP 5 / 6 ─── Locating output executable")
        set_progress(job_id, 90, "Locating output...")

        dist_dir = output_dir / "dist"
        info_log(job_id, f"Scanning dist dir: {dist_dir}")

        executables = list(dist_dir.glob("*")) if dist_dir.exists() else []
        if not executables:
            err_log(job_id, "No files found in dist directory!")
            with jobs_lock:
                jobs[job_id]["status"] = "failed"
                jobs[job_id]["progress"] = 0
                jobs[job_id]["error"] = "No output produced by PyInstaller"
            return

        for f in executables:
            fstat = f.stat()
            info_log(job_id, f"  Found: {f.name}  ({fstat.st_size:,} bytes, {oct(fstat.st_mode)})")

        exe_path = executables[0]
        exe_size = exe_path.stat().st_size
        info_log(job_id, f"Primary output: {exe_path.name} ({exe_size / 1024 / 1024:.2f} MB)")
        ok_log(job_id, f"Executable located: {exe_path.name}")

        # ── STEP 7: Generate automation script ────────────────────────────────
        step_log(job_id, "─── STEP 6 / 6 ─── Generating automation script")
        set_progress(job_id, 94, "Generating .sh script...")

        script_content = None
        if options.get("createScript", True):
            fname = file_path.stem
            icon_arg = ""
            if options.get("iconPath"):
                icon_arg = f"    --icon={options['iconPath']} \\\n"
            script_content = f"""#!/bin/bash
# Automated build script for {fname}
# Generated by K3nna Python to Executable Converter

set -e

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m'

echo "========================================"
echo "  K3NNA - Python Compiler"
echo "  Building: {fname}"
echo "========================================"

if ! command -v python3 &> /dev/null; then
    echo -e "${{RED}}✗ Error: Python 3 is not installed${{NC}}"
    exit 1
fi
echo -e "${{GREEN}}✓ Python 3 found${{NC}}"

if ! python3 -m pip show pyinstaller &> /dev/null; then
    echo -e "${{YELLOW}}⚠ PyInstaller not found. Installing...${{NC}}"
    python3 -m pip install pyinstaller
fi
echo -e "${{GREEN}}✓ PyInstaller ready${{NC}}"

OUTPUT_DIR="{fname}_exe"
mkdir -p "$OUTPUT_DIR"

python3 -m PyInstaller \\
    --onefile \\
    --windowed \\
    --clean \\
{icon_arg}    --distpath "$OUTPUT_DIR" \\
    --workpath build \\
    --specpath . \\
    {fname}.py

rm -rf build
rm -f {fname}.spec

echo -e "${{GREEN}}✓ Build complete!${{NC}}"
echo "========================================"
"""
            script_lines = script_content.count("\n")
            info_log(job_id, f"Script name   : build_{fname}.sh")
            info_log(job_id, f"Script lines  : {script_lines}")
            ok_log(job_id, "Automation script generated")
        else:
            info_log(job_id, "Script generation skipped (option disabled)")

        # ── Cleanup ───────────────────────────────────────────────────────────
        info_log(job_id, "Cleaning up build artifacts...")
        shutil.rmtree(build_dir, ignore_errors=True)
        spec_file = output_dir / (file_path.stem + ".spec")
        spec_file.unlink(missing_ok=True)
        info_log(job_id, f"Removed: {build_dir}")
        info_log(job_id, f"Removed: {spec_file.name}")

        # ── Done ──────────────────────────────────────────────────────────────
        step_log(job_id, "═══════════════════════════════════════════════════")
        ok_log(job_id,   "  ALL STEPS COMPLETE — CONVERSION SUCCESSFUL ✓")
        step_log(job_id, f"  Output  : {exe_path.name} ({exe_size / 1024 / 1024:.2f} MB)")
        step_log(job_id, f"  Time    : {ts()}")
        step_log(job_id, "═══════════════════════════════════════════════════")

        with jobs_lock:
            jobs[job_id]["status"] = "done"
            jobs[job_id]["progress"] = 100
            jobs[job_id]["exe_name"] = exe_path.name
            jobs[job_id]["exe_path"] = str(exe_path)
            jobs[job_id]["script"] = script_content

    except Exception as e:
        err_log(job_id, f"Unhandled exception: {type(e).__name__}: {e}")
        with jobs_lock:
            jobs[job_id]["status"] = "failed"
            jobs[job_id]["progress"] = 0
            jobs[job_id]["error"] = str(e)


@app.route("/")
def index():
    with open("templates/index.html") as f:
        return f.read()


@app.route("/api/convert", methods=["POST"])
def convert():
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    f = request.files["file"]
    if not f.filename.endswith(".py"):
        return jsonify({"error": "Only .py files are accepted"}), 400

    options = {}
    if "options" in request.form:
        try:
            options = json.loads(request.form["options"])
        except Exception:
            pass

    job_id = str(uuid.uuid4())
    job_dir = UPLOAD_DIR / job_id
    job_dir.mkdir(parents=True, exist_ok=True)
    file_path = job_dir / f.filename
    f.save(str(file_path))

    with jobs_lock:
        jobs[job_id] = {
            "status": "queued",
            "progress": 0,
            "status_msg": "Queued",
            "log": "",
            "log_lines": [],
            "filename": f.filename,
            "exe_name": None,
            "exe_path": None,
            "script": None,
            "error": None,
        }

    t = threading.Thread(target=run_conversion, args=(job_id, file_path, options), daemon=True)
    t.start()

    return jsonify({"jobId": job_id})


@app.route("/api/status/<job_id>")
def status(job_id):
    with jobs_lock:
        job = jobs.get(job_id)
    if not job:
        return jsonify({"error": "Job not found"}), 404
    return jsonify({
        "status": job["status"],
        "progress": job["progress"],
        "status_msg": job.get("status_msg", ""),
        "filename": job["filename"],
        "exe_name": job["exe_name"],
        "error": job["error"],
    })


@app.route("/api/log/<job_id>")
def get_log(job_id):
    offset = int(request.args.get("offset", 0))
    with jobs_lock:
        job = jobs.get(job_id)
    if not job:
        return jsonify({"error": "Job not found"}), 404
    lines = job["log_lines"]
    new_lines = lines[offset:]
    return jsonify({
        "lines": new_lines,
        "total": len(lines),
        "status": job["status"],
    })


@app.route("/api/download/<job_id>")
def download(job_id):
    with jobs_lock:
        job = jobs.get(job_id)
    if not job or job["status"] != "done":
        return jsonify({"error": "Not ready"}), 404
    exe_path = job["exe_path"]
    if not exe_path or not Path(exe_path).exists():
        return jsonify({"error": "File not found"}), 404
    return send_file(exe_path, as_attachment=True, download_name=job["exe_name"])


@app.route("/api/download-script/<job_id>")
def download_script(job_id):
    with jobs_lock:
        job = jobs.get(job_id)
    if not job or job["status"] != "done":
        return jsonify({"error": "Not ready"}), 404
    script = job.get("script")
    if not script:
        return jsonify({"error": "No script available"}), 404
    fname = Path(job["filename"]).stem
    tmp = tempfile.NamedTemporaryFile(mode="w", suffix=".sh", delete=False)
    tmp.write(script)
    tmp.close()
    return send_file(tmp.name, as_attachment=True, download_name=f"build_{fname}.sh")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
