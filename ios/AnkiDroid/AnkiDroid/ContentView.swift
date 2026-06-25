import SwiftUI
import AnkiIOSPort

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var decks: [DeckSummary] = []
    @Published private(set) var syncState = SyncState(pendingChanges: 3)
    @Published var newDeckName = ""
    @Published var accountName = ""
    @Published var alertMessage: String?

    private let deckLibrary: DeckLibrary
    private let syncCoordinator: SyncCoordinator

    init(
        deckLibrary: DeckLibrary = DeckLibrary(),
        syncCoordinator: SyncCoordinator = SyncCoordinator()
    ) {
        self.deckLibrary = deckLibrary
        self.syncCoordinator = syncCoordinator
    }

    func load() async {
        decks = await deckLibrary.listDecks()
        syncState = await syncCoordinator.currentState()
    }

    func addDeck() async {
        do {
            _ = try await deckLibrary.addDeck(named: newDeckName)
            newDeckName = ""
            decks = await deckLibrary.listDecks()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func signIn() async {
        do {
            syncState = try await syncCoordinator.signIn(accountName: accountName)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func sync() async {
        do {
            syncState = try await syncCoordinator.sync()
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
                Section("Decks") {
                    ForEach(viewModel.decks) { deck in
                        NavigationLink {
                            DeckDetailView(deck: deck)
                        } label: {
                            DeckRow(deck: deck)
                        }
                    }

                    HStack {
                        TextField("New deck name", text: $viewModel.newDeckName)
                        Button("Add") {
                            Task { await viewModel.addDeck() }
                        }
                        .disabled(viewModel.newDeckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Sync") {
                    LabeledContent("Status", value: viewModel.syncState.statusMessage)
                    LabeledContent("Pending changes", value: "\(viewModel.syncState.pendingChanges)")
                    if let lastSyncDate = viewModel.syncState.lastSyncDate {
                        LabeledContent("Last sync", value: lastSyncDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let accountName = viewModel.syncState.accountName {
                        LabeledContent("Account", value: accountName)
                    } else {
                        TextField("AnkiWeb account", text: $viewModel.accountName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Sign in") {
                            Task { await viewModel.signIn() }
                        }
                    }
                    Button("Sync now") {
                        Task { await viewModel.sync() }
                    }
                    .disabled(!viewModel.syncState.isSignedIn)
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
                    .disabled(!viewModel.syncState.isSignedIn)
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

#Preview {
    ContentView()
}
