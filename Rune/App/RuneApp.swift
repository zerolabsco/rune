import SwiftUI

@main
struct RuneApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

private struct RootView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var domainViewModel = DomainViewModel()
    @StateObject private var tokenViewModel = TokenViewModel()
    @StateObject private var walletViewModel = WalletViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DomainListView(viewModel: domainViewModel, client: settingsViewModel.client)
                .tabItem {
                    Label("Domains", systemImage: "globe")
                }
                .tag(0)

            TokenListView(viewModel: tokenViewModel, client: settingsViewModel.client) { deletedTokenKey in
                do {
                    let didLogout = try settingsViewModel.logoutIfCurrentTokenDeleted(deletedTokenKey)
                    if didLogout {
                        selectedTab = 0
                    }
                } catch {
                    settingsViewModel.errorMessage = error.localizedDescription
                }
            }
                .tabItem {
                    Label("Tokens", systemImage: "key.horizontal")
                }
                .tag(1)

            SettingsView(viewModel: settingsViewModel, walletViewModel: walletViewModel) {
                domainViewModel.reset()
                tokenViewModel.reset()
                walletViewModel.reset()
                selectedTab = 0
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
        .task {
            await settingsViewModel.bootstrap()
            await syncAuthenticatedState()
        }
        .onChange(of: settingsViewModel.client) { _, _ in
            Task {
                await syncAuthenticatedState()
            }
        }
        .fullScreenCover(isPresented: onboardingBinding) {
            OnboardingView(viewModel: settingsViewModel)
        }
    }

    private func syncAuthenticatedState() async {
        guard let client = settingsViewModel.client else {
            domainViewModel.reset()
            tokenViewModel.reset()
            walletViewModel.reset()
            selectedTab = 0
            return
        }

        await domainViewModel.loadDomains(client: client)
        await tokenViewModel.loadTokens(client: client)
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { settingsViewModel.requiresOnboarding },
            set: { _ in }
        )
    }
}
