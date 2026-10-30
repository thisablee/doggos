import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool { UNUserNotificationCenter.current().delegate = self; return true }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { completionHandler([.banner,.sound]) }
}
@main struct DoggosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = DogStore()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup { RootView().environmentObject(store).tint(Palette.green).preferredColorScheme(.light)
            .alert("Un momento", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) { Button("Ho capito") { store.error = nil } } message: { Text(store.error ?? "") }
            .task { await store.refreshNotifications() }
            .onChange(of: phase) { _, next in if next == .active { Task { await store.refreshNotifications() } } }
        }
    }
}
enum Palette {
    static let green = Color(red: 0.16, green: 0.31, blue: 0.24)
    static let background = Color(red: 0.97, green: 0.98, blue: 0.95)
    static let mint = Color(red: 0.89, green: 0.94, blue: 0.83)
    static let peach = Color(red: 0.97, green: 0.89, blue: 0.81)
    static func color(_ name: String) -> Color { name == "pesca" ? peach : name == "lavanda" ? Color(red: 0.92, green: 0.89, blue: 0.96) : mint }
}
