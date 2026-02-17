//
//  Models.swift
//  TabSaver
//
//  Created by Gonzalo Vazquez on 2026-02-14.
//

import Foundation
import Combine

// MARK: - Models

struct Tab: Codable, Identifiable {
    let id: String
    let url: String
    let title: String
    let notes: String?
    let savedAt: Date
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case id, url, title, notes, tags
        case savedAt = "created_at"
    }
}

struct TagResponse: Codable {
    let id: String
    let name: String
}

// MARK: - View Model

class TabManagerViewModel: ObservableObject {
    @Published var tabs: [Tab] = []
    @Published var tags: [String] = []
    @Published var statusMessage = ""
    
    private var apiURL: String = "https://192.168.1.100:5000"
    private let configKey = "TabManagerAPIURL"
    private let appGroupDefaults = UserDefaults(suiteName: "group.com.usmakestwo.TabSaver") ?? .standard

    init() {
        loadConfig()
    }

    func loadConfig() {
        if let saved = appGroupDefaults.string(forKey: configKey) {
            apiURL = saved
        }
    }

    func setAPIURL(_ url: String) {
        apiURL = url
        appGroupDefaults.set(url, forKey: configKey)
    }
    
    // MARK: - API Calls
    
    func refreshTabs() {
        let urlString = "\(apiURL)/api/tabs"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let tabs = try decoder.decode([Tab].self, from: data)
                
                DispatchQueue.main.async {
                    self?.tabs = tabs
                }
            } catch {
                print("Failed to decode tabs: \(error)")
            }
        }.resume()
        
        loadTags()
    }
    
    func loadTags() {
        let urlString = "\(apiURL)/api/tags"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data else { return }
            
            do {
                let tagList = try JSONDecoder().decode([TagResponse].self, from: data)
                DispatchQueue.main.async {
                    self?.tags = tagList.map { $0.name }
                }
            } catch {
                print("Failed to decode tags: \(error)")
            }
        }.resume()
    }
    
    func saveTab(url: String, title: String, tag: String? = nil, completion: @escaping (Bool) -> Void) {
        let urlString = "\(apiURL)/api/tabs"
        guard let endpoint = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["url": url, "title": title]
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tabId = json["id"] as? String else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Add tag if provided
            if let tag = tag, !tag.isEmpty {
                self?.addTag(to: tabId, tag: tag) { _ in
                    DispatchQueue.main.async {
                        self?.statusMessage = "✓ Saved with tag: \(tag)"
                        completion(true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self?.statusMessage = "✓ Tab saved"
                    completion(true)
                }
            }
        }.resume()
    }
    
    func searchTabs(query: String, completion: @escaping ([Tab]) -> Void) {
        var components = URLComponents(string: "\(apiURL)/api/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]

        guard let url = components?.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            completion((try? decoder.decode([Tab].self, from: data)) ?? [])
        }.resume()
    }

    func fetchTab(id: String, completion: @escaping (Tab?) -> Void) {
        let urlString = "\(apiURL)/api/tabs/\(id)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            completion(try? decoder.decode(Tab.self, from: data))
        }.resume()
    }

    func addTag(to tabId: String, tag: String, completion: @escaping (Bool) -> Void) {
        let urlString = "\(apiURL)/api/tabs/\(tabId)/tags"
        guard let endpoint = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["tag": tag]
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            completion(error == nil)
        }.resume()
    }
    
    func deleteTab(id: String, completion: @escaping (Bool) -> Void) {
        let urlString = "\(apiURL)/api/tabs/\(id)"
        guard let endpoint = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }.resume()
    }
}
