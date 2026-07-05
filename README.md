# K3nna - Python to Executable Converter

A macOS application that converts Python scripts into standalone executables using a drag-and-drop GUI built with SwiftUI.

## Features

- 🖱️ Drag-and-drop interface for Python scripts
- 🔨 Converts Python files to standalone executables
- 📊 Real-time conversion progress tracking
- ✨ Clean, modern SwiftUI interface
- ⚡ Fast batch processing support
- 🕐 Conversion history with quick access

## Requirements

- macOS 12.0 or later
- Xcode 13.0 or later
- Python 3.8 or later
- PyInstaller: `pip3 install pyinstaller`

## Installation

1. Clone the repository:
   ```bash
   git clone git@github.com:planetminguez/K3nna.git
   cd K3nna
   ```

2. Open the project in Xcode:
   ```bash
   open K3nna.xcodeproj
   ```

3. Build and run (⌘R)

## Setup

Before using the app, ensure PyInstaller is installed:

```bash
pip3 install pyinstaller
```

Optionally, you can also install other bundling tools:

```bash
# Alternative: py2exe (Windows)
pip3 install py2exe

# Alternative: pyenv for version management
brew install pyenv
```

## Usage

1. Launch the K3nna application
2. Drag a Python script (.py) into the window, or click "Browse" to select one
3. Click "Convert" to start the conversion
4. The executable will be created in the `dist/` folder next to your Python script
5. View recent conversions in the history section

## Project Structure

```
K3nna/
├── K3nna/
│   ├── K3nnaApp.swift              # Main app entry point
│   ├── Views/
│   │   ├── ContentView.swift       # Main UI with drag-drop
│   │   └── ResultView.swift        # Conversion result display
│   ├── Models/
│   │   └── PythonConverter.swift   # Conversion logic & PyInstaller wrapper
│   └── Assets.xcassets/            # App assets
├── K3nna.xcodeproj/                # Xcode project file
├── README.md
└── .gitignore
```

## How It Works

1. **Validation**: Checks that Python 3 and PyInstaller are installed
2. **Conversion**: Runs PyInstaller with optimized settings:
   - `--onefile` - Creates a single executable
   - `--windowed` - Removes console window on macOS
   - `--clean` - Cleans up temporary files
3. **Output**: Saves executable to `dist/` folder
4. **History**: Tracks recent conversions for quick access

## Configuration

You can customize PyInstaller options in `K3nna/Models/PythonConverter.swift`:

```swift
process.arguments = [
    "-m", "PyInstaller",
    "--onefile",          // Single file vs directory
    "--windowed",         // No console window
    "--icon=icon.icns",   // Add custom icon
    // Add more options as needed
]
```

## Troubleshooting

### "Python 3 not found"
- Install Python from [python.org](https://www.python.org)
- Or use Homebrew: `brew install python3`

### "PyInstaller not found"
- Install PyInstaller: `pip3 install pyinstaller`

### Conversion fails
- Check for syntax errors in your Python script
- Ensure all dependencies are listed in requirements.txt
- Try running PyInstaller manually for more detailed error messages:
  ```bash
  pyinstaller --onefile --windowed your_script.py
  ```

## License

MIT License

## Author

Created by planetminguez
