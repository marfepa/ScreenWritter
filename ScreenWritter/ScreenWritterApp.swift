import SwiftUI

@main
struct ScreenWritterApp: App {
    @State private var store = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .task {
                    await store.load()
                    await store.importSharedItems()
                }
                .onOpenURL { url in
                    Task {
                        await store.open(url)
                    }
                }
        }
    }
}
