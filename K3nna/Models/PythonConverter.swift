import Foundation

class PythonConverter: ObservableObject {
    @Published var isConverting = false
    @Published var statusMessage = ""
    @Published var conversionProgress: Double = 0
    @Published var oneFile = true
    @Published var windowed = true
    @Published var stripBinaries = false
    @Published var optimize = false
    @Published var customPyinstallerOptions = ""
    
    enum ConversionError: LocalizedError {
        case pythonNotFound
        case pyinstallerNotFound
        case conversionFailed(String)
        case invalidFile
        case processError(Int32)
        case scriptCreationFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .pythonNotFound:
                return "Python 3 not found. Please install Python 3.8 or later from python.org"
            case .pyinstallerNotFound:
                return "PyInstaller not found. Install it with: pip3 install pyinstaller"
            case .conversionFailed(let msg):
                return "Conversion failed: \(msg)"
            case .invalidFile:
                return "Invalid Python file or file not found"
            case .processError(let code):
                return "Process exited with code \(code)"
            case .scriptCreationFailed(let msg):
                return "Failed to create automation script: \(msg)"
            }
        }
    }
    
    func convert(
        pythonFile: URL,
        saveInOwnDir: Bool = true,
        createScript: Bool = true,
        iconPath: String? = nil,
        customOptions: String = "",
        completion: @escaping (Result<URL, ConversionError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Verify file exists
                guard FileManager.default.fileExists(atPath: pythonFile.path) else {
                    throw ConversionError.invalidFile
                }
                
                // Check Python is installed
                try self.verifyPython()
                
                // Check PyInstaller is installed
                try self.verifyPyInstaller()
                
                // Run PyInstaller
                let outputDir = try self.runPyInstaller(
                    pythonFile: pythonFile,
                    saveInOwnDir: saveInOwnDir,
                    iconPath: iconPath,
                    customOptions: customOptions
                )
                
                // Create automation script if requested
                if createScript {
                    try self.createAutomationScript(pythonFile: pythonFile, outputDir: outputDir, iconPath: iconPath)
                }
                
                DispatchQueue.main.async {
                    self.statusMessage = "✓ Conversion complete! Executable ready."
                    self.conversionProgress = 1.0
                    completion(.success(outputDir))
                }
            } catch {
                DispatchQueue.main.async {
                    if let convertError = error as? ConversionError {
                        completion(.failure(convertError))
                    } else {
                        completion(.failure(.conversionFailed(error.localizedDescription)))
                    }
                }
            }
        }
    }
    
    private func verifyPython() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["--version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ConversionError.pythonNotFound
        }
    }
    
    private func verifyPyInstaller() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-m", "pip", "show", "pyinstaller"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ConversionError.pyinstallerNotFound
        }
    }
    
    private func runPyInstaller(
        pythonFile: URL,
        saveInOwnDir: Bool,
        iconPath: String? = nil,
        customOptions: String = ""
    ) throws -> URL {
        let fileName = pythonFile.deletingPathExtension().lastPathComponent
        let sourceDir = pythonFile.deletingLastPathComponent()
        
        let outputDir: URL
        if saveInOwnDir {
            outputDir = sourceDir.appendingPathComponent("\(fileName)_exe")
            try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        } else {
            outputDir = sourceDir.appendingPathComponent("dist")
        }
        
        let buildDir = sourceDir.appendingPathComponent("build")
        let specFile = sourceDir.appendingPathComponent("\(fileName).spec")
        
        DispatchQueue.main.async {
            self.statusMessage = "[1/3] Preparing environment..."
            self.conversionProgress = 0.1
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        
        // Build PyInstaller arguments
        var args = [
            "-m", "PyInstaller"
        ]
        
        if oneFile {
            args.append("--onefile")
        }
        
        if windowed {
            args.append("--windowed")
        }
        
        if stripBinaries {
            args.append("--strip")
        }
        
        if optimize {
            args.append("--optimize=2")
        }
        
        // Add icon if provided
        if let iconPath = iconPath, !iconPath.isEmpty {
            args.append("--icon=\(iconPath)")
        }
        
        // Add custom options
        let customArgs = customOptions.split(separator: " ").map(String.init)
        args.append(contentsOf: customArgs)
        
        args.append(contentsOf: [
            "--clean",
            "--distpath", outputDir.path,
            "--buildpath", buildDir.path,
            "--specpath", sourceDir.path,
            pythonFile.path
        ])
        
        process.arguments = args
        process.currentDirectoryURL = sourceDir
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        DispatchQueue.main.async {
            self.statusMessage = "[2/3] Compiling Python code..."
            self.conversionProgress = 0.4
        }
        
        try process.run()
        process.waitUntilExit()
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
        
        DispatchQueue.main.async {
            self.statusMessage = "[3/3] Finalizing executable..."
            self.conversionProgress = 0.85
        }
        
        if process.terminationStatus != 0 {
            throw ConversionError.conversionFailed(errorOutput.isEmpty ? "Unknown error" : errorOutput)
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: buildDir)
        try? FileManager.default.removeItem(at: specFile)
        
        DispatchQueue.main.async {
            self.conversionProgress = 0.95
        }
        
        return outputDir
    }
    
    private func createAutomationScript(pythonFile: URL, outputDir: URL, iconPath: String? = nil) throws {
        let fileName = pythonFile.deletingPathExtension().lastPathComponent
        let sourceDir = pythonFile.deletingLastPathComponent()
        
        let scriptName = "build_\(fileName).sh"
        let scriptPath = sourceDir.appendingPathComponent(scriptName)
        
        let iconArg = iconPath.map { "--icon=\($0)" } ?? ""
        
        let scriptContent = """#!/bin/bash
# Automated build script for \(fileName)
# Generated by K3nna Python to Executable Converter

set -e

echo "========================================"
echo "  K3NNA - Python Compiler"
echo "  Building: \(fileName)"
echo "========================================"
echo ""

# Colors
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m' # No Color

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Error: Python 3 is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Python 3 found${NC}"

# Check if PyInstaller is installed
if ! python3 -m pip show pyinstaller &> /dev/null; then
    echo -e "${YELLOW}⚠ PyInstaller not found. Installing...${NC}"
    python3 -m pip install pyinstaller
fi

echo -e "${GREEN}✓ PyInstaller ready${NC}"
echo ""

# Create output directory
OUTPUT_DIR="\(fileName)_exe"
mkdir -p "$OUTPUT_DIR"

echo -e "${YELLOW}→ Building executable...${NC}"
python3 -m PyInstaller \\
    --onefile \\
    --windowed \\
    --clean \\
    \(iconArg.isEmpty ? "" : iconArg + " \\\\\n    ")\\
    --distpath "$OUTPUT_DIR" \\
    --buildpath build \\
    --specpath . \\
    \(fileName).py

echo ""
echo -e "${GREEN}✓ Build complete!${NC}"
echo -e "  Output: ${YELLOW}$OUTPUT_DIR${NC}"
echo ""

# Clean up build artifacts
rm -rf build
rm -f \(fileName).spec

echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""
echo "========================================"
echo "  Ready to distribute!"
echo "========================================"
"""
        
        try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptPath.path
        )
        
        DispatchQueue.main.async {
            self.statusMessage = "✓ Created automation script: \(scriptName)"
        }
    }
}
