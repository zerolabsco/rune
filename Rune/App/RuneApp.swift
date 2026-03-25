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

            SettingsView(viewModel: settingsViewModel) {
                domainViewModel.reset()
                tokenViewModel.reset()
                selectedTab = 0
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
        .task {
            await settingsViewModel.bootstrap()
        }
        .task(id: settingsViewModel.isAuthenticated) {
            guard let client = settingsViewModel.client else {
                domainViewModel.reset()
                tokenViewModel.reset()
                selectedTab = 0
                return
            }

            await domainViewModel.loadDomains(client: client)
            await tokenViewModel.loadTokens(client: client)
        }
        .fullScreenCover(isPresented: onboardingBinding) {
            OnboardingView(viewModel: settingsViewModel)
        }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { settingsViewModel.requiresOnboarding },
            set: { _ in }
        )
    }
}
