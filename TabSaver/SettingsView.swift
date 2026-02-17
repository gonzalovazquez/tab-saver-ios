import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = TabManagerViewModel()
    @State private var nasIP = ""
    @State private var connectionStatus: ConnectionStatus = .idle

    enum ConnectionStatus: Equatable {
        case idle
        case checking
        case connected
        case failed(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("API Configuration") {
                    TextField("Host", text: $nasIP, prompt: Text("example.execute-api.us-east-1.amazonaws.com"))
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .keyboardType(.URL)

                    Button(action: saveSettings) {
                        HStack {
                            if connectionStatus == .checking {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Connecting...")
                            } else {
                                Text("Save Configuration")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(nasIP.isEmpty || connectionStatus == .checking)
                }

                if connectionStatus != .idle {
                    Section {
                        switch connectionStatus {
                        case .connected:
                            Label("Connection established", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        case .failed(let message):
                            Label(message, systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                        default:
                            EmptyView()
                        }
                    }
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
        }
    }

    private func saveSettings() {
        let urlString = "https://\(nasIP)"
        connectionStatus = .checking

        guard let url = URL(string: "\(urlString)/api/health") else {
            connectionStatus = .failed("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    connectionStatus = .failed("Failed: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    connectionStatus = .failed("No response from server")
                    return
                }

                if httpResponse.statusCode == 200 {
                    viewModel.setAPIURL(urlString)
                    connectionStatus = .connected
                    viewModel.refreshTabs()
                } else {
                    connectionStatus = .failed("Server returned \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}

#Preview {
    SettingsView()
}
