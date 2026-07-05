import Foundation

class PythonConverter: ObservableObject {
    @Published var isConverting = false
    @Published var statusMessage = ""
    @Published var conversionProgress: Double = 0
    
    enum ConversionError: LocalizedError {
        case pythonNotFound
        case pyinstallerNotFound
        case conversionFailed(String)
        case invalidFile
        case processError(Int32)
        
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
            }
        }
    }
    
    func convert(pythonFile: URL, completion: @escaping (Result<URL, ConversionError>) -> Void) {
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
                let outputDir = try self.runPyInstaller(pythonFile: pythonFile)
                
                DispatchQueue.main.async {
                    self.statusMessage = "✓ Conversion complete! Executable saved to dist/"
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
    
    private func runPyInstaller(pythonFile: URL) throws -> URL {
        let fileName = pythonFile.deletingPathExtension().lastPathComponent
        let workingDir = pythonFile.deletingLastPathComponent()
        let outputDir = workingDir.appendingPathComponent("dist")
        let buildDir = workingDir.appendingPathComponent("build")
        let specFile = workingDir.appendingPathComponent("\(fileName).spec")
        
        // Update status
        DispatchQueue.main.async {
            self.statusMessage = "Preparing conversion..."
            self.conversionProgress = 0.1
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        
        // PyInstaller arguments
        process.arguments = [
            "-m", "PyInstaller",
            "--onefile",               // Single executable
            "--windowed",              // No console window
            "--clean",                 // Clean build
            "--distpath", outputDir.path,
            "--buildpath", buildDir.path,
            pythonFile.path
        ]
        
        process.currentDirectoryURL = workingDir
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        // Read output as it comes
        let outputHandle = pipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading
        
        DispatchQueue.main.async {
            self.statusMessage = "Running PyInstaller..."
            self.conversionProgress = 0.3
        }
        
        try process.run()
        process.waitUntilExit()
        
        let errorData = errorHandle.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
        
        DispatchQueue.main.async {
            self.conversionProgress = 0.9
        }
        
        if process.terminationStatus != 0 {
            throw ConversionError.conversionFailed(errorOutput.isEmpty ? "Unknown error" : errorOutput)
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: buildDir)
        try? FileManager.default.removeItem(at: specFile)
        
        DispatchQueue.main.async {
            self.conversionProgress = 1.0
        }
        
        return outputDir
    }
}
