//
//  ShareViewController.swift
//  TabManagerShare
//

import UIKit

class ShareViewController: UIViewController {

    // MARK: - Config

    private let configKey = "TabManagerAPIURL"
    private let defaultAPIURL = "https://192.168.1.100:5000"
    private let appGroupID = "group.com.usmakestwo.TabSaver"

    // MARK: - State

    private var sharedURL = ""
    private var sharedTitle = ""
    private var selectedTag: String?
    private var apiURL = ""

    // MARK: - UI

    private let pageTitleLabel = UILabel()
    private let urlLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let tagChipsScrollView = UIScrollView()
    private let tagChipsStack = UIStackView()
    private let tagTextField = UITextField()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        apiURL = getSavedAPIURL()
        setupUI()
        extractSharedContent()
        fetchTags()
    }

    // MARK: - Configuration

    private func getSavedAPIURL() -> String {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        return defaults.string(forKey: configKey) ?? defaultAPIURL
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Header
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let headerTitle = UILabel()
        headerTitle.text = "Save Tab"
        headerTitle.font = .systemFont(ofSize: 17, weight: .semibold)

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [cancelButton, headerTitle, saveButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        // Info card
        pageTitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        pageTitleLabel.numberOfLines = 2

        urlLabel.font = .systemFont(ofSize: 13)
        urlLabel.textColor = .secondaryLabel
        urlLabel.numberOfLines = 1

        let infoStack = UIStackView(arrangedSubviews: [pageTitleLabel, urlLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 4
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        let infoCard = UIView()
        infoCard.backgroundColor = .secondarySystemBackground
        infoCard.layer.cornerRadius = 10
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(infoStack)

        // Tags section
        let tagsSectionLabel = UILabel()
        tagsSectionLabel.text = "ADD TAG"
        tagsSectionLabel.font = .systemFont(ofSize: 12, weight: .medium)
        tagsSectionLabel.textColor = .secondaryLabel
        tagsSectionLabel.translatesAutoresizingMaskIntoConstraints = false

        tagChipsScrollView.showsHorizontalScrollIndicator = false
        tagChipsScrollView.translatesAutoresizingMaskIntoConstraints = false

        tagChipsStack.axis = .horizontal
        tagChipsStack.spacing = 8
        tagChipsStack.alignment = .center
        tagChipsStack.translatesAutoresizingMaskIntoConstraints = false
        tagChipsScrollView.addSubview(tagChipsStack)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()

        tagTextField.placeholder = "Or type a new tag..."
        tagTextField.borderStyle = .roundedRect
        tagTextField.autocorrectionType = .no
        tagTextField.autocapitalizationType = .none
        tagTextField.returnKeyType = .done
        tagTextField.translatesAutoresizingMaskIntoConstraints = false
        tagTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)

        // Layout
        view.addSubview(headerStack)
        view.addSubview(infoCard)
        view.addSubview(tagsSectionLabel)
        view.addSubview(tagChipsScrollView)
        view.addSubview(activityIndicator)
        view.addSubview(tagTextField)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            infoCard.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 20),
            infoCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            infoStack.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 12),
            infoStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            infoStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -12),
            infoStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -12),

            tagsSectionLabel.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 24),
            tagsSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            tagChipsScrollView.topAnchor.constraint(equalTo: tagsSectionLabel.bottomAnchor, constant: 10),
            tagChipsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tagChipsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tagChipsScrollView.heightAnchor.constraint(equalToConstant: 36),

            tagChipsStack.topAnchor.constraint(equalTo: tagChipsScrollView.topAnchor),
            tagChipsStack.leadingAnchor.constraint(equalTo: tagChipsScrollView.leadingAnchor),
            tagChipsStack.trailingAnchor.constraint(equalTo: tagChipsScrollView.trailingAnchor),
            tagChipsStack.bottomAnchor.constraint(equalTo: tagChipsScrollView.bottomAnchor),
            tagChipsStack.heightAnchor.constraint(equalTo: tagChipsScrollView.heightAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: tagChipsScrollView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: tagChipsScrollView.centerYAnchor),

            tagTextField.topAnchor.constraint(equalTo: tagChipsScrollView.bottomAnchor, constant: 12),
            tagTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tagTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Extract Shared Content

    private func extractSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else { return }

        // attributedTitle carries the page title in Firefox and some other browsers
        let itemTitle = extensionItem.attributedTitle?.string

        let urlProviders = attachments.filter { $0.hasItemConformingToTypeIdentifier("public.url") }
        let textProviders = attachments.filter { $0.hasItemConformingToTypeIdentifier("public.plain-text") }

        func resolve(url: URL, titleProviders: [NSItemProvider]) {
            DispatchQueue.main.async {
                self.sharedURL = url.absoluteString
                self.urlLabel.text = url.host
            }
            if let titleProvider = titleProviders.first {
                titleProvider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { title, _ in
                    // plain-text might be page content rather than the title in some browsers,
                    // so prefer attributedTitle when available
                    let finalTitle = itemTitle ?? (title as? String) ?? url.host ?? "Saved Tab"
                    DispatchQueue.main.async {
                        self.sharedTitle = finalTitle
                        self.pageTitleLabel.text = finalTitle
                    }
                }
            } else {
                let finalTitle = itemTitle ?? url.host ?? "Saved Tab"
                DispatchQueue.main.async {
                    self.sharedTitle = finalTitle
                    self.pageTitleLabel.text = finalTitle
                }
            }
        }

        if let urlProvider = urlProviders.first {
            urlProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] item, _ in
                guard let self else { return }
                // Validate that the resolved URL is an absolute http/https URL
                let candidate: URL?
                if let url = item as? URL {
                    candidate = url
                } else if let str = item as? String {
                    candidate = URL(string: str)
                } else {
                    candidate = nil
                }

                if let url = candidate, url.scheme == "http" || url.scheme == "https" {
                    resolve(url: url, titleProviders: textProviders)
                } else {
                    // Not a valid web URL — fall back to plain-text providers
                    self.extractFromPlainText(providers: textProviders, itemTitle: itemTitle)
                }
            }
        } else {
            extractFromPlainText(providers: textProviders, itemTitle: itemTitle)
        }
    }

    private func extractFromPlainText(providers: [NSItemProvider], itemTitle: String?) {
        guard let provider = providers.first else { return }
        provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { [weak self] item, _ in
            guard let urlString = item as? String,
                  let url = URL(string: urlString),
                  url.scheme == "http" || url.scheme == "https" else { return }
            DispatchQueue.main.async {
                self?.sharedURL = url.absoluteString
                self?.urlLabel.text = url.host
                let title = itemTitle ?? url.host ?? "Saved Tab"
                self?.sharedTitle = title
                self?.pageTitleLabel.text = title
            }
        }
    }

    // MARK: - Fetch Tags

    private func fetchTags() {
        guard let url = URL(string: "\(apiURL)/api/tags") else {
            activityIndicator.stopAnimating()
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                guard let data = data,
                      let tags = try? JSONDecoder().decode([RemoteTag].self, from: data) else { return }
                self?.renderTagChips(tags.map { $0.name })
            }
        }.resume()
    }

    private func renderTagChips(_ tags: [String]) {
        for tag in tags {
            let chip = makeChipButton(title: tag)
            tagChipsStack.addArrangedSubview(chip)
        }
    }

    private func makeChipButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true

        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        button.configuration = config
        button.setTitleColor(.systemBlue, for: .normal)

        button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func chipTapped(_ sender: UIButton) {
        guard let tag = sender.title(for: .normal) else { return }

        // Deselect all chips first
        for case let chip as UIButton in tagChipsStack.arrangedSubviews {
            chip.backgroundColor = .clear
            chip.setTitleColor(.systemBlue, for: .normal)
            chip.layer.borderColor = UIColor.systemBlue.cgColor
        }

        if selectedTag == tag {
            selectedTag = nil
        } else {
            selectedTag = tag
            sender.backgroundColor = .systemBlue
            sender.setTitleColor(.white, for: .normal)
            tagTextField.text = ""
        }
    }

    @objc private func textFieldChanged() {
        // Typing a new tag deselects any chip
        if !(tagTextField.text?.isEmpty ?? true) {
            for case let chip as UIButton in tagChipsStack.arrangedSubviews {
                chip.backgroundColor = .clear
                chip.setTitleColor(.systemBlue, for: .normal)
            }
            selectedTag = nil
        }
    }

    // MARK: - Actions

    @objc private func saveTapped() {
        guard !sharedURL.isEmpty else { return }
        let tag: String?
        if let typed = tagTextField.text, !typed.isEmpty {
            tag = typed
        } else {
            tag = selectedTag
        }
        saveTab(url: sharedURL, title: sharedTitle, tag: tag)
    }

    @objc private func cancelTapped() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    // MARK: - Save Tab

    private func saveTab(url: String, title: String, tag: String?) {
        guard let endpoint = URL(string: "\(apiURL)/api/tabs") else {
            completeExtension()
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let httpBody = try? JSONEncoder().encode(["url": url, "title": title]) else {
            completeExtension()
            return
        }
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tabId = json["id"] as? String,
                  let tag = tag, !tag.isEmpty else {
                self?.completeExtension()
                return
            }
            self?.addTag(to: tabId, tag: tag)
        }.resume()
    }

    private func addTag(to tabId: String, tag: String) {
        guard let endpoint = URL(string: "\(apiURL)/api/tabs/\(tabId)/tags") else {
            completeExtension()
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["tag": tag])

        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            self?.completeExtension()
        }.resume()
    }

    private func completeExtension() {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}

// MARK: - Models

private struct RemoteTag: Decodable {
    let id: String
    let name: String
}
