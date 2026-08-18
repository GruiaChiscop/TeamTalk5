import SwiftUI

@main
struct iTeamTalkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var serverListModel = ServerListModel(session: AppDelegate.session)

    var body: some Scene {
        WindowGroup {
            ServerListView(model: serverListModel)
        }
    }
}
