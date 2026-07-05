import SwiftUI

struct ContentView: View {
    @StateObject private var converter = PythonConverter()
    @State private var draggedFile: URL?
    @State private var showResult = false
    @State private var resultURL: URL?
    @State private var resultError: String?
    @State private var conversionHistory: [ConversionRecord] = []
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.95, blue: 1.0),
                    Color(red: 0.90, green: 0.95, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "hammer.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("K3nna")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Python to Executable Converter")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .background(Color.white)
                .shadow(radius: 2)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Main drag-and-drop area
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 2, dash: [8])
                                    )
                                    .foregroundColor(.blue.opacity(0.5))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.blue.opacity(0.05))
                                    )
                                
                                VStack(spacing: 12) {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.blue)
                                    
                                    Text("Drag Python scripts here")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("or click browse below")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    if let file = draggedFile {
                                        VStack(spacing: 4) {
                                            Divider()
                                                .padding(.vertical, 8)
                                            
                                            Label(file.lastPathComponent, systemImage: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .frame(height: 220)
                            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                                handleDrop(providers: providers)
                                return true
                            }
                            
                            // Buttons
                            HStack(spacing: 12) {
                                Button(action: browseFiles) {
                                    Label("Browse", systemImage: "folder.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.blue)
                                .disabled(converter.isConverting)
                                
                                Button(action: startConversion) {
                                    if converter.isConverting {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                            Text("Converting...")
                                        }
                                        .frame(maxWidth: .infinity)
                                    } else {
                                        Label("Convert", systemImage: "hammer.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .disabled(draggedFile == nil || converter.isConverting)
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        
                        // Status display
                        if !converter.statusMessage.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Status")
                                        .font(.headline)
                                    Spacer()
                                }
                                
                                Text(converter.statusMessage)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                if converter.isConverting {
                                    ProgressView(value: converter.conversionProgress)
                                        .tint(.blue)
                                }
                            }
                            .padding(12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(12)
                        }
                        
                        // Conversion history
                        if !conversionHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.blue)
                                    Text("Recent Conversions")
                                        .font(.headline)
                                    Spacer()
                                }
                                
                                VStack(spacing: 8) {
                                    ForEach(conversionHistory.prefix(5), id: \.id) { record in
                                        HStack {
                                            Image(systemName: record.success ? "checkmark.circle" : "xmark.circle")
                                                .foregroundColor(record.success ? .green : .red)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(record.fileName)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                Text(record.timestamp, style: .time)
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            if record.success {
                                                Button(action: { openFile(record.outputPath) }) {
                                                    Image(systemName: "folder")
                                                        .font(.caption)
                                                }
                                                .buttonStyle(.plain)
                                                .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(12)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showResult) {
            ResultView(
                isPresented: $showResult,
                resultURL: resultURL,
                error: resultError,
                onOpenFolder: { url in
                    if let url = url {
                        NSWorkspace.shared.open(url)
                    }
                }
            )
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadFileRepresentation(forTypeIdentifier: "public.data") { url, error in
                if let url = url, url.pathExtension.lowercased() == "py" {
                    DispatchQueue.main.async {
                        draggedFile = url
                        converter.statusMessage = "Selected: \(url.lastPathComponent)"
                    }
                }
            }
        }
    }
    
    private func browseFiles() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["py"]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.urls.first {
            draggedFile = url
            converter.statusMessage = "Selected: \(url.lastPathComponent)"
        }
    }
    
    private func startConversion() {
        guard let file = draggedFile else { return }
        
        converter.isConverting = true
        converter.statusMessage = "Converting \(file.lastPathComponent)..."
        resultError = nil
        
        converter.convert(pythonFile: file) { result in
            converter.isConverting = false
            
            switch result {
            case .success(let outputURL):
                resultURL = outputURL
                resultError = nil
                
                let record = ConversionRecord(
                    fileName: file.lastPathComponent,
                    outputPath: outputURL,
                    success: true,
                    timestamp: Date()
                )
                conversionHistory.insert(record, at: 0)
                
                converter.statusMessage = "✓ Conversion complete!"
                draggedFile = nil
                showResult = true
                
            case .failure(let error):
                resultError = error.localizedDescription
                
                let record = ConversionRecord(
                    fileName: file.lastPathComponent,
                    outputPath: nil,
                    success: false,
                    timestamp: Date()
                )
                conversionHistory.insert(record, at: 0)
                
                converter.statusMessage = "✗ Error: \(error.localizedDescription)"
                showResult = true
            }
        }
    }
    
    private func openFile(_ url: URL?) {
        guard let url = url else { return }
        NSWorkspace.shared.open(url.deletingLastPathComponent())
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
