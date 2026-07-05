import SwiftUI

struct AdvancedOptionsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var converter: PythonConverter
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ADVANCED PYINSTALLER OPTIONS")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(red: 0.10, green: 0.10, blue: 0.10))
            .borderBottom(width: 1, color: Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.2))
            
            ScrollView {
                VStack(spacing: 16) {
                    // PyInstaller Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COMPILATION OPTIONS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                        
                        Toggle(isOn: $converter.oneFile) {
                            Text("--onefile")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .tint(Color(red: 0.9, green: 0.0, blue: 0.0))
                        
                        Toggle(isOn: $converter.windowed) {
                            Text("--windowed (No console)")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .tint(Color(red: 0.9, green: 0.0, blue: 0.0))
                        
                        Toggle(isOn: $converter.stripBinaries) {
                            Text("--strip (Remove debug symbols)")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .tint(Color(red: 0.9, green: 0.0, blue: 0.0))
                        
                        Toggle(isOn: $converter.optimize) {
                            Text("--optimize (Python optimization)")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .tint(Color(red: 0.9, green: 0.0, blue: 0.0))
                    }
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                    .cornerRadius(10)
                    
                    // Custom Arguments
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CUSTOM ARGUMENTS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                        
                        TextEditor(text: $converter.customPyinstallerOptions)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                            .background(Color(red: 0.08, green: 0.08, blue: 0.08))
                            .cornerRadius(8)
                            .frame(height: 120)
                        
                        Text("Example: --hidden-import=module --additional-hooks-dir=/path")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8, opacity: 0.6))
                    }
                    .padding(12)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                    .cornerRadius(10)
                    
                    // Save Settings
                    HStack(spacing: 12) {
                        Button(action: { settingsManager.exportSettings() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("EXPORT")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.3), lineWidth: 1)
                            )
                        }
                        
                        Button(action: { settingsManager.importSettings() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                Text("IMPORT")
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(16)
            }
            
            // Close Button
            Button(action: { isPresented = false }) {
                Text("DONE")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.9, green: 0.0, blue: 0.0),
                                Color(red: 0.7, green: 0.0, blue: 0.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
            .padding(16)
            .background(Color(red: 0.10, green: 0.10, blue: 0.10))
            .borderTop(width: 1, color: Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.2))
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.08))
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct IconPickerView: View {
    @Binding var isPresented: Bool
    @Binding var selectedIconPath: String
    @ObservedObject var converter: PythonConverter
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SELECT APP ICON")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(red: 0.10, green: 0.10, blue: 0.10))
            .borderBottom(width: 1, color: Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.2))
            
            VStack(spacing: 16) {
                Text("Supported formats: .icns, .png, .jpg")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8, opacity: 0.7))
                
                if !selectedIconPath.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(URL(fileURLWithPath: selectedIconPath).lastPathComponent)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { selectedIconPath = "" }) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(Color(red: 0.9, green: 0.0, blue: 0.0))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.12))
                    .cornerRadius(8)
                }
                
                Button(action: browseForIcon) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                        Text("BROWSE FOR ICON")
                            .tracking(0.5)
                    }
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.9, green: 0.0, blue: 0.0),
                                Color(red: 0.7, green: 0.0, blue: 0.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(16)
            
            Button(action: { isPresented = false }) {
                Text("CLOSE")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color(red: 0.15, green: 0.15, blue: 0.15))
                    .cornerRadius(8)
            }
            .padding(16)
            .background(Color(red: 0.10, green: 0.10, blue: 0.10))
            .borderTop(width: 1, color: Color(red: 0.9, green: 0.0, blue: 0.0, opacity: 0.2))
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.08))
        .frame(minWidth: 400, minHeight: 350)
    }
    
    private func browseForIcon() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["icns", "png", "jpg", "jpeg"]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.urls.first {
            selectedIconPath = url.path
        }
    }
}

extension View {
    func borderTop(width: CGFloat, color: Color) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(color)
                .frame(height: width)
            self
        }
    }
    
    func borderBottom(width: CGFloat, color: Color) -> some View {
        VStack(spacing: 0) {
            self
            Rectangle()
                .fill(color)
                .frame(height: width)
        }
    }
}
