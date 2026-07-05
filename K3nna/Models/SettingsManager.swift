import Foundation
import Combine

class SettingsManager: ObservableObject {
    @Published var settings: ConversionSettings = ConversionSettings()
    private let settingsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("K3nnaSettings.json")
    
    init() {
        loadSettings()
    }
    
    func exportSettings() {
        let dialog = NSSavePanel()
        dialog.title = "Export K3nna Settings"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowedFileTypes = ["json"]
        dialog.nameFieldStringValue = "K3nnaSettings.json"
        
        if dialog.runModal() == .OK, let url = dialog.url {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(settings)
                try data.write(to: url)
                
                let alert = NSAlert()
                alert.messageText = "Settings Exported"
                alert.informativeText = "Your settings have been saved to:\n\(url.lastPathComponent)"
                alert.addButton(withTitle: "OK")
                alert.runModal()
            } catch {
                showError("Export failed: \(error.localizedDescription)")
            }
        }
    }
    
    func importSettings() {
        let dialog = NSOpenPanel()
        dialog.title = "Import K3nna Settings"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowedFileTypes = ["json"]
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.canCreateDirectories = false
        dialog.canChooseFiles = true
        
        if dialog.runModal() == .OK, let url = dialog.urls.first {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let imported = try decoder.decode(ConversionSettings.self, from: data)
                self.settings = imported
                
                let alert = NSAlert()
                alert.messageText = "Settings Imported"
                alert.informativeText = "Your settings have been loaded successfully."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            } catch {
                showError("Import failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadSettings() {
        if FileManager.default.fileExists(atPath: settingsURL.path) {
            do {
                let data = try Data(contentsOf: settingsURL)
                let decoder = JSONDecoder()
                settings = try decoder.decode(ConversionSettings.self, from: data)
            } catch {
                print("Failed to load settings: \(error)")
            }
        }
    }
    
    private func saveSettings() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .critical
        alert.runModal()
    }
}

struct ConversionSettings: Codable {
    var oneFile: Bool = true
    var windowed: Bool = true
    var stripBinaries: Bool = false
    var optimize: Bool = false
    var customPyinstallerOptions: String = ""
    var saveInOwnDir: Bool = true
    var createAutomationScript: Bool = true
    var iconPath: String = ""
    
    enum CodingKeys: String, CodingKey {
        case oneFile, windowed, stripBinaries, optimize
        case customPyinstallerOptions, saveInOwnDir, createAutomationScript, iconPath
    }
}
