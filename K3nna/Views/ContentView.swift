import SwiftUI

struct ContentView: View {
    @StateObject private var converter = PythonConverter()
    @State private var draggedFiles: [URL] = []
    @State private var showResult = false
    @State private var resultURL: URL?
    @State private var resultError: String?
    @State private var conversionHistory: [ConversionRecord] = []
    @State private var saveExeInOwnDir = true
    @State private var createAutomationScript = true
    @State private var showCompletionAlert = false
    @State private var completionMessage = ""
    @State private var isHovering = false
    @State private var batchProgress: Double = 0
    @State private var batchTotal = 0
    @State private var batchCurrent = 0
    
    var body: some View {
        ZStack {
            // Metallic background with gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.08, green: 0.08, blue: 0.08), location: 0),
                    .init(color: Color(red: 0.12, green: 0.12, blue: 0.12), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated grid background
            Canvas { context in
                let gridSize: CGFloat = 30
                var y: CGFloat = 0
                while y < 800 {
                    var x: CGFloat = 0
                    while x < 900 {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + gridSize, y: y))
                        context.stroke(
                            path,
                            with: .color(Color(red: 0.8, green: 0.0, blue: 0.0, opacity: 0.03))
                        )
                        x += gridSize
                    }
                    y += gridSize
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Futuristic header
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.9, green: 0.0, blue: 0.0),
                                            Color(red: 0.6, green: 0.0, blue: 0.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Image(systemName: "hammer.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .frame(width: 48, height: 48)
                        .shadow(color: Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.5), radius: 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("K3NNA")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .tracking(2)
                                .foregroundColor(.white)
                            
                            Text("PYTHON EXECUTION COMPILER")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                        }
                        
                        Spacer()
                        
                        // Mode indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(red: 0.9, green: 0.0, blue: 0.0))
                                .frame(width: 10, height: 10)
                                .shadow(color: Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.8), radius: 4)
                            
                            Text(converter.isConverting ? "PROCESSING" : "READY")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(converter.isConverting ? Color(red: 0.9, green: 0.0, blue: 0.0) : .green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                        .cornerRadius(6)
                    }
                    .padding(16)
                }
                .background(
                    ZStack {
                        Rectangle()
                            .fill(Color(red: 0.10, green: 0.10, blue: 0.10))
                        
                        Rectangle()
                            .strokeBorder(Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.2), lineWidth: 1)
                    }
                )
                .shadow(color: Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.3), radius: 4)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Main drag-and-drop area
                        VStack(spacing: 16) {
                            ZStack {
                                // Animated border
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.9, green: 0.0, blue: 0.0),
                                                Color(red: 0.6, green: 0.0, blue: 0.0)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isHovering ? 3 : 2
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
                                    )
                                
                                VStack(spacing: 16) {
                                    // Animated icon
                                    ZStack {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.3),
                                                        Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.05)
                                                    ]),
                                                    center: .center,
                                                    startRadius: 20,
                                                    endRadius: 50
                                                )
                                            )
                                        
                                        Image(systemName: "arrow.down.doc.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                                    }
                                    .frame(height: 100)
                                    
                                    Text("DRAG & DROP PYTHON SCRIPTS")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .tracking(1)
                                        .foregroundColor(.white)
                                    
                                    Text("Or click to browse multiple files")
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .tracking(0.5)
                                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.7))
                                    
                                    if !draggedFiles.isEmpty {
                                        VStack(spacing: 8) {
                                            Divider()
                                                .background(Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.3))
                                            
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                    .font(.system(size: 12))
                                                
                                                Text("\(draggedFiles.count) file\(draggedFiles.count > 1 ? "s" : "") selected")
                                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(.green)
                                                
                                                Spacer()
                                                
                                                Button(action: { draggedFiles.removeAll() }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(24)
                            }
                            .frame(height: 280)
                            .onDrop(of: [.fileURL], isTargeted: $isHovering) { providers in
                                handleDrop(providers: providers)
                                return true
                            }
                            
                            // Options row
                            HStack(spacing: 12) {
                                Toggle(isOn: $saveExeInOwnDir) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "folder.badge.plus")
                                        Text("Save in own folder")
                                    }
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                }
                                .tint(Color(red: 0.9, green: 0.0, blue: 0.0))
                                
                                Divider()
                                
                                Toggle(isOn: $createAutomationScript) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.text")
                                        Text("Auto script (.sh)")
                                    }
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                }
                                .tint(Color(red: 0.9, green: 0.0, blue: 0.0))
                            }
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                            .cornerRadius(10)
                            
                            // Buttons
                            HStack(spacing: 12) {
                                Button(action: browseFiles) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "folder.fill")
                                        Text("BROWSE")
                                            .tracking(0.5)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                                    .padding(12)
                                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.5), lineWidth: 1)
                                    )
                                }
                                .disabled(converter.isConverting)
                                
                                Button(action: startConversion) {
                                    HStack(spacing: 8) {
                                        if converter.isConverting {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "zap.fill")
                                        }
                                        Text(converter.isConverting ? "EXECUTING..." : "EXECUTE")
                                            .tracking(0.5)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.9, green: 0.0, blue: 0.0),
                                                Color(red: 0.7, green: 0.0, blue: 0.0)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.5), radius: 6)
                                }
                                .disabled(draggedFiles.isEmpty || converter.isConverting)
                            }
                        }
                        .padding(20)
                        .background(Color(red: 0.10, green: 0.10, blue: 0.10))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.1), lineWidth: 1)
                        )
                        
                        // Batch progress
                        if converter.isConverting && batchTotal > 1 {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("BATCH PROGRESS")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                                    
                                    Spacer()
                                    
                                    Text("\(batchCurrent)/\(batchTotal)")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                                    
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.9, green: 0.0, blue: 0.0),
                                                    Color(red: 0.6, green: 0.0, blue: 0.0)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: CGFloat(batchProgress) * 300, alignment: .leading)
                                }
                                .frame(height: 8)
                                .shadow(color: Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.5), radius: 4)
                            }
                            .padding(16)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                            .cornerRadius(12)
                        }
                        
                        // Status display
                        if !converter.statusMessage.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "terminal.fill")
                                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                                    
                                    Text("SYSTEM STATUS")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                                    
                                    Spacer()
                                }
                                
                                Text(converter.statusMessage)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white)
                                    .lineLimit(3)
                                
                                if converter.isConverting {
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                                        
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 0.9, green: 0.0, blue: 0.0),
                                                        Color(red: 0.6, green: 0.0, blue: 0.0)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: CGFloat(converter.conversionProgress) * 300, alignment: .leading)
                                    }
                                    .frame(height: 6)
                                    .shadow(color: Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.5), radius: 4)
                                    
                                    Text("\(Int(converter.conversionProgress * 100))%")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                                }
                            }
                            .padding(16)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.2), lineWidth: 1)
                            )
                        }
                        
                        // Conversion history
                        if !conversionHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                                    
                                    Text("CONVERSION HISTORY")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                                    
                                    Spacer()
                                    
                                    Button(action: { conversionHistory.removeAll() }) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.6))
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                VStack(spacing: 8) {
                                    ForEach(conversionHistory.prefix(8), id: \.id) { record in
                                        HStack(spacing: 10) {
                                            Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(record.success ? .green : Color(red: 0.9, green: 0.0, blue: 0.0))
                                                .font(.system(size: 12))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(record.fileName)
                                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(.white)
                                                    .lineLimit(1)
                                                
                                                Text(record.timestamp, style: .time)
                                                    .font(.system(size: 9, design: .monospaced))
                                                    .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8, opacity: 0.6))
                                            }
                                            
                                            Spacer()
                                            
                                            if record.success {
                                                Button(action: { openFile(record.outputPath) }) {
                                                    Image(systemName: "folder.fill")
                                                        .font(.system(size: 10))
                                                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(10)
                                        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(red: 0.10, green: 0.10, blue: 0.10))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.1), lineWidth: 1)
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .alert("Conversion Complete", isPresented: $showCompletionAlert) {
            Button("Open in Finder") {
                if let url = resultURL {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
            Button("Close") {
                showCompletionAlert = false
            }
        } message: {
            Text(completionMessage)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadFileRepresentation(forTypeIdentifier: "public.data") { url, error in
                if let url = url, url.pathExtension.lowercased() == "py" {
                    DispatchQueue.main.async {
                        if !draggedFiles.contains(url) {
                            draggedFiles.append(url)
                        }
                    }
                }
            }
        }
    }
    
    private func browseFiles() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["py"]
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            draggedFiles = panel.urls
        }
    }
    
    private func startConversion() {
        guard !draggedFiles.isEmpty else { return }
        
        converter.isConverting = true
        batchTotal = draggedFiles.count
        batchCurrent = 0
        batchProgress = 0
        resultError = nil
        
        var successCount = 0
        var errorCount = 0
        var lastOutputURL: URL?
        
        let dispatchGroup = DispatchGroup()
        
        for (index, file) in draggedFiles.enumerated() {
            dispatchGroup.enter()
            
            DispatchQueue.main.async {
                batchCurrent = index + 1
                batchProgress = Double(batchCurrent) / Double(batchTotal)
                converter.statusMessage = "Converting [\(index + 1)/\(draggedFiles.count)]: \(file.lastPathComponent)"
            }
            
            converter.convert(
                pythonFile: file,
                saveInOwnDir: saveExeInOwnDir,
                createScript: createAutomationScript
            ) { result in
                switch result {
                case .success(let outputURL):
                    successCount += 1
                    lastOutputURL = outputURL
                    
                    let record = ConversionRecord(
                        fileName: file.lastPathComponent,
                        outputPath: outputURL,
                        success: true,
                        timestamp: Date()
                    )
                    DispatchQueue.main.async {
                        conversionHistory.insert(record, at: 0)
                    }
                    
                case .failure(let error):
                    errorCount += 1
                    resultError = error.localizedDescription
                    
                    let record = ConversionRecord(
                        fileName: file.lastPathComponent,
                        outputPath: nil,
                        success: false,
                        timestamp: Date()
                    )
                    DispatchQueue.main.async {
                        conversionHistory.insert(record, at: 0)
                    }
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            converter.isConverting = false
            batchCurrent = batchTotal
            batchProgress = 1.0
            
            let message: String
            if errorCount == 0 {
                message = "✓ All \(successCount) file(s) converted successfully!"
                resultURL = lastOutputURL
            } else if successCount == 0 {
                message = "✗ Failed to convert \(errorCount) file(s)"
                resultURL = nil
            } else {
                message = "⚠ Converted \(successCount) file(s), \(errorCount) failed"
                resultURL = lastOutputURL
            }
            
            completionMessage = message
            showCompletionAlert = true
            converter.statusMessage = message
            draggedFiles.removeAll()
        }
    }
    
    private func openFile(_ url: URL?) {
        guard let url = url else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

struct ConversionRecord: Identifiable {
    let id = UUID()
    let fileName: String
    let outputPath: URL?
    let success: Bool
    let timestamp: Date
}

#Preview {
    ContentView()
}
