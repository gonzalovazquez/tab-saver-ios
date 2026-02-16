import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TabManagerViewModel()
    @State private var newTabURL = ""
    @State private var newTabTitle = ""
    @State private var newTabTag = ""
    @State private var searchText = ""
    @State private var searchResults: [Tab] = []
    @State private var searchTask: Task<Void, Never>? = nil

    var displayedTabs: [Tab] {
        searchText.isEmpty ? viewModel.tabs : searchResults
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("📑 Saved Tabs")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(viewModel.tabs.count)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    HStack(spacing: 16) {
                        Text("Active: \(viewModel.tabs.count)")
                            .font(.caption)
                        Spacer()
                        Text("Tags: \(viewModel.tags.count)")
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Save tab section
                VStack(spacing: 8) {
                    Text("+ Save Tab")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("URL", text: $newTabURL)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                    
                    TextField("Title (optional)", text: $newTabTitle)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Tag (optional)", text: $newTabTag)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: saveNewTab) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(newTabURL.isEmpty)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search tabs...", text: $searchText)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
                
                // Status message
                if !viewModel.statusMessage.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color(.systemGray6))
                }
                
                // Tabs list
                if displayedTabs.isEmpty {
                    VStack {
                        Spacer()
                        Text("No tabs found")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(displayedTabs) { tab in
                            NavigationLink(destination: TabDetailView(tab: tab, viewModel: viewModel)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tab.title)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .lineLimit(2)
                                    
                                    Text(tab.url)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .lineLimit(1)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteTab)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.refreshTabs() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.loadConfig()
                viewModel.refreshTabs()
            }
            .onChange(of: searchText) { _, query in
                searchTask?.cancel()
                guard !query.isEmpty else {
                    searchResults = []
                    return
                }
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    viewModel.searchTabs(query: query) { results in
                        DispatchQueue.main.async {
                            searchResults = results
                        }
                    }
                }
            }
        }
    }
    
    private func saveNewTab() {
        guard !newTabURL.isEmpty else { return }

        let url = newTabURL.lowercased()
        let title = newTabTitle.isEmpty ? URL(string: url)?.host ?? "Untitled" : newTabTitle
        let tag = newTabTag.isEmpty ? nil : newTabTag

        viewModel.saveTab(url: url, title: title, tag: tag) { success in
            if success {
                newTabURL = ""
                newTabTitle = ""
                newTabTag = ""
                viewModel.refreshTabs()
            }
        }
    }
    
    private func deleteTab(at offsets: IndexSet) {
        for index in offsets {
            let tab = displayedTabs[index]
            viewModel.deleteTab(id: tab.id) { _ in
                viewModel.refreshTabs()
            }
        }
    }
}

// MARK: - Tab Detail View
struct TabDetailView: View {
    let tab: Tab
    let viewModel: TabManagerViewModel
    @Environment(\.dismiss) var dismiss
    @State private var tags: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(tab.title)
                    .font(.body)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("URL")
                    .font(.caption)
                    .foregroundColor(.gray)

                HStack {
                    Text(tab.url)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(3)

                    Button(action: {
                        UIPasteboard.general.string = tab.url
                    }) {
                        Image(systemName: "doc.on.doc")
                    }

                    Button(action: {
                        UIApplication.shared.open(URL(string: tab.url) ?? URL(fileURLWithPath: ""))
                    }) {
                        Image(systemName: "safari")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.caption)
                    .foregroundColor(.gray)
                if tags.isEmpty {
                    Text("No tags")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    FlowLayout(tags: tags)
                }
            }

            if let notes = tab.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(notes)
                        .font(.caption)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Saved")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(tab.savedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
            }

            Spacer()

            Button(role: .destructive, action: {
                viewModel.deleteTab(id: tab.id) { _ in
                    dismiss()
                }
            }) {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("Tab Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchTab(id: tab.id) { fetched in
                DispatchQueue.main.async {
                    tags = fetched?.tags ?? []
                }
            }
        }
    }
}

struct FlowLayout: View {
    let tags: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 6)], alignment: .leading, spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ContentView()
}
