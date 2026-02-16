import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = TabManagerViewModel()
    @State private var nasIP = ""
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("NAS Configuration") {
                    TextField("NAS IP:Port", text: $nasIP, prompt: Text("192.168.1.100:5000"))
                    
                    Button(action: saveSettings) {
                        Text("Save Configuration")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                
                Section("About") {
                    Text("Tab Manager v1.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("Tabs Saved")
                        Spacer()
                        Text("\(viewModel.tabs.count)")
                            .fontWeight(.bold)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadConfig()
                viewModel.refreshTabs()
            }
            .alert("Saved", isPresented: $showSuccess) {
                Button("OK") { }
            }
        }
    }
    
    private func saveSettings() {
        let urlString = "http://\(nasIP)"
        viewModel.setAPIURL(urlString)
        showSuccess = true
    }
}

#Preview {
    SettingsView()
}
