import SwiftUI
import AnkiIOSPort

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var decks: [DeckSummary] = []
    @Published private(set) var syncState = SyncState()
    @Published private(set) var statistics: StudyStatistics?
    @Published var newDeckName = ""
    @Published var username = ""
    @Published var password = ""
    @Published var alertMessage: String?
    @Published var isBackendUnavailable = false

    private let collectionBackend: any AnkiCollectionBackend
    private let syncBackend: any AnkiSyncBackend

    init(
        collectionBackend: any AnkiCollectionBackend = DefaultAnkiBackends.collectionBackend(),
        syncBackend: any AnkiSyncBackend = DefaultAnkiBackends.syncBackend()
    ) {
        self.collectionBackend = collectionBackend
        self.syncBackend = syncBackend
    }

    func load() async {
        do {
            decks = try await collectionBackend.listDecks()
            statistics = try await collectionBackend.statistics()
            syncState = try await syncBackend.currentSyncState()
            isBackendUnavailable = false
        } catch AnkiBackendOperationError.officialBackendNotLinked {
            isBackendUnavailable = true
            syncState = SyncState(statusMessage: AnkiBackendOperationError.officialBackendNotLinked.localizedDescription)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func createDeck() async {
        do {
            _ = try await collectionBackend.createDeck(named: newDeckName)
            newDeckName = ""
            decks = try await collectionBackend.listDecks()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func login() async {
        do {
            let credentials = try AnkiWebCredentials(username: username, password: password)
            syncState = try await syncBackend.login(credentials: credentials)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func sync() async {
        do {
            syncState = try await syncBackend.sync()
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isBackendUnavailable {
                    Section("Backend required") {
                        Label("This build will not fake AnkiWeb or scheduling.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("Package and link the official Anki Rust backend for Apple platforms before enabling real review, AnkiWeb sync, imports, editing, statistics, filtered decks, and media support.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Decks") {
                    if viewModel.decks.isEmpty {
                        ContentUnavailableView("No collection loaded", systemImage: "rectangle.stack", description: Text("Decks will appear after the official backend opens the Anki collection."))
                    } else {
                        ForEach(viewModel.decks) { deck in
                            NavigationLink {
                                DeckDetailView(deck: deck)
                            } label: {
                                DeckRow(deck: deck)
                            }
                        }
                    }

                    HStack {
                        TextField("New deck name", text: $viewModel.newDeckName)
                        Button("Create") {
                            Task { await viewModel.createDeck() }
                        }
                        .disabled(viewModel.newDeckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isBackendUnavailable)
                    }
                }

                Section("Study") {
                    NavigationLink("Review due cards") {
                        FeatureStatusView(title: "Review due cards", systemImage: "rectangle.stack.badge.play")
                    }
                    .disabled(viewModel.isBackendUnavailable)
                    NavigationLink("Custom study / filtered deck") {
                        FeatureStatusView(title: "Custom study / filtered deck", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .disabled(viewModel.isBackendUnavailable)
                }

                Section("Add / Import") {
                    NavigationLink("Add note / card") {
                        FeatureStatusView(title: "Add note / card", systemImage: "plus.rectangle.on.rectangle")
                    }
                    .disabled(viewModel.isBackendUnavailable)
                    NavigationLink("Import .apkg / .colpkg") {
                        FeatureStatusView(title: "Import .apkg / .colpkg", systemImage: "square.and.arrow.down")
                    }
                    .disabled(viewModel.isBackendUnavailable)
                }

                Section("Browse / Edit") {
                    NavigationLink("Card browser") {
                        FeatureStatusView(title: "Card browser", systemImage: "magnifyingglass")
                    }
                    .disabled(viewModel.isBackendUnavailable)
                }

                Section("Statistics") {
                    if let statistics = viewModel.statistics {
                        LabeledContent("Studied today", value: "\(statistics.studiedToday)")
                        LabeledContent("Accuracy", value: statistics.reviewAccuracy.formatted(.percent.precision(.fractionLength(1))))
                        LabeledContent("Time", value: Duration.seconds(statistics.studiedSeconds).formatted())
                    } else {
                        Text("Statistics require the official collection backend.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Sync AnkiWeb") {
                    LabeledContent("Status", value: viewModel.syncState.statusMessage)
                    if let accountName = viewModel.syncState.accountName {
                        LabeledContent("Account", value: accountName)
                    } else {
                        TextField("AnkiWeb username", text: $viewModel.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("AnkiWeb password", text: $viewModel.password)
                        Button("Log in with AnkiWeb") {
                            Task { await viewModel.login() }
                        }
                        .disabled(viewModel.isBackendUnavailable)
                    }
                    Button("Sync now") {
                        Task { await viewModel.sync() }
                    }
                    .disabled(viewModel.isBackendUnavailable || viewModel.syncState.accountName == nil)
                }

                Section("Media / accessibility") {
                    Label("Images, audio, MathJax, TTS, night mode, whiteboard, and answer input must be driven by the same backend-backed collection and media paths.", systemImage: "photo.on.rectangle.angled")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("AnkiDroid")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.sync() }
                    } label: {
                        Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(viewModel.isBackendUnavailable || viewModel.syncState.accountName == nil)
                }
            }
            .task { await viewModel.load() }
            .alert("AnkiDroid", isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { viewModel.alertMessage = nil }
            } message: {
                Text(viewModel.alertMessage ?? "")
            }
        }
    }
}

private struct DeckRow: View {
    let deck: DeckSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(deck.name).font(.headline)
            HStack(spacing: 12) {
                Label("\(deck.newCount) new", systemImage: "sparkles")
                Label("\(deck.learningCount) learning", systemImage: "clock")
                Label("\(deck.reviewCount) review", systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

private struct DeckDetailView: View {
    let deck: DeckSummary

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
            Text(deck.name)
                .font(.largeTitle.bold())
            Text("\(deck.dueCount) cards due")
                .font(.title3)
            Button("Study now") {}
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle(deck.name)
    }
}

private struct FeatureStatusView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text("Disabled until the official Anki Rust backend is linked for this iOS build.")
        )
    }
}

#Preview {
    ContentView()
}
