# K3nna — Python Execution Compiler

## Overview
K3nna is a web-based Python-to-executable converter that replicates the functionality of the original macOS SwiftUI app. It provides a dark/red-themed drag-and-drop interface for converting `.py` scripts into standalone executables using PyInstaller.

The original project was a macOS SwiftUI desktop app (using AppKit APIs like NSWorkspace, NSOpenPanel) which cannot run on Linux/Replit. This implementation provides equivalent functionality via a Flask web app.

## Stack
- **Backend**: Python 3.11, Flask
- **Conversion engine**: PyInstaller
- **Frontend**: Vanilla HTML/CSS/JS (no build step needed)
- **Port**: 5000

## Structure
- `app.py` — Flask server with conversion API endpoints
- `templates/index.html` — Full SPA frontend (dark/red K3nna theme)
- `K3nna/` — Original Swift source files (reference only, not compiled)

## API Endpoints
- `GET /` — Web UI
- `POST /api/convert` — Upload `.py` file, start conversion job
- `GET /api/status/<job_id>` — Poll job status and progress
- `GET /api/download/<job_id>` — Download the compiled executable
- `GET /api/download-script/<job_id>` — Download the generated `.sh` build script

## Running
```bash
python3 app.py
```
Server listens on `0.0.0.0:5000`.

## User Preferences
- Preserve the dark/red K3nna aesthetic in any UI changes
