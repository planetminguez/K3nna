import SwiftUI

struct ResultView: View {
    @Binding var isPresented: Bool
    let resultURL: URL?
    let error: String?
    let onOpenFolder: (URL?) -> Void
    
    var isSuccess: Bool {
        error == nil && resultURL != nil
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if isSuccess {
                // Success state
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    
                    Text("Conversion Successful!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let url = resultURL {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Output Location")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                    Text(url.lastPathComponent)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                .padding(8)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.green.opacity(0.05))
                .cornerRadius(12)
            } else {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.red)
                    
                    Text("Conversion Failed")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.red.opacity(0.05))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: { isPresented = false }) {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                if isSuccess, let url = resultURL {
                    Button(action: { onOpenFolder(url) }) {
                        Label("Open Folder", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 400)
    }
}

#Preview {
    ResultView(
        isPresented: .constant(true),
        resultURL: URL(fileURLWithPath: "/Users/test/dist/myapp"),
        error: nil,
        onOpenFolder: { _ in }
    )
}
