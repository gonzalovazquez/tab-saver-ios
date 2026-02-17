//
//  ShareViewController.swift
//  TabSaverShare
//

import UIKit

class ShareViewController: UIViewController {
    
    private let configKey = "TabManagerAPIURL"
    private let defaultAPIURL = "https://192.168.1.100:5000"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("✓ ShareViewController loaded")
        
        // Get saved API URL
        let apiURL = getSavedAPIURL()
        print("🔗 Using API URL: \(apiURL)")
        
        // Test network connection
        testNetworkConnection(apiURL: apiURL)
        
        // Get shared URL
        processSharedContent(apiURL: apiURL)
    }
    
    // MARK: - Get Saved Configuration
    
    private func getSavedAPIURL() -> String {
        // Try to get URL from UserDefaults (same as main app)
        if let savedURL = UserDefaults.standard.string(forKey: configKey) {
            print("✓ Found saved API URL: \(savedURL)")
            return savedURL
        }
        
        // Fall back to default
        print("⚠️ No saved API URL, using default: \(defaultAPIURL)")
        return defaultAPIURL
    }
    
    // MARK: - Test Network
    
    private func testNetworkConnection(apiURL: String) {
        print("🔗 Testing network connection...")
        
        let healthURL = apiURL + "/api/health"
        
        guard let url = URL(string: healthURL) else {
            print("❌ Invalid health check URL: \(healthURL)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Network test failed: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("✓ Network test passed: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    // MARK: - Process Shared Content
    
    private func processSharedContent(apiURL: String) {
        print("📋 Processing shared content...")
        
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            print("❌ No extension item found")
            completeExtension()
            return
        }
        
        itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] item, error in
            guard let url = item as? URL else {
                print("❌ Could not extract URL: \(error?.localizedDescription ?? "unknown")")
                self?.completeExtension()
                return
            }
            
            print("✓ Got URL: \(url.absoluteString)")
            
            // Get page title
            itemProvider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { title, _ in
                let finalTitle = (title as? String) ?? url.host ?? "Saved Tab"
                print("✓ Got title: \(finalTitle)")
                
                self?.saveTabToAPI(url: url.absoluteString, title: finalTitle, apiURL: apiURL)
            }
        }
    }
    
    // MARK: - Save Tab to API
    
    private func saveTabToAPI(url: String, title: String, apiURL: String) {
        print("💾 Saving tab to API...")
        
        let endpoint = apiURL + "/api/tabs"
        
        guard let apiEndpoint = URL(string: endpoint) else {
            print("❌ Invalid API URL: \(endpoint)")
            completeExtension()
            return
        }
        
        var request = URLRequest(url: apiEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["url": url, "title": title]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            print("📤 Posting to: \(endpoint)")
            print("📝 Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "empty")")
        } catch {
            print("❌ Failed to encode body: \(error)")
            completeExtension()
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            print("📩 API response received")
            
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✓ Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 201 {
                    print("✅ SUCCESS: Tab saved!")
                } else {
                    print("⚠️ Unexpected status code: \(httpResponse.statusCode)")
                }
            }
            
            if let data = data {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("✓ Response: \(jsonString)")
                }
            }
            
            self?.completeExtension()
        }.resume()
    }
    
    // MARK: - Complete Extension
    
    private func completeExtension() {
        print("✓ Completing extension")
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
