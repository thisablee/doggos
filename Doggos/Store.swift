import Foundation
import Combine
import UserNotifications

@MainActor final class DogStore: ObservableObject {
    @Published private(set) var data = AppData()
    @Published var error: String?
    @Published var notificationsAllowed = false
    private let directory: URL
    private let file: URL
    let documentsDirectory: URL
    private var saveAvailable = true
    init(directory: URL? = nil, seed: Bool = true) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Doggos", isDirectory: true)
        file = self.directory.appendingPathComponent("data.json")
        documentsDirectory = self.directory.appendingPathComponent("Documents", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: file.path) {
                let saved = try JSONDecoder().decode(AppData.self, from: Data(contentsOf: file))
                guard saved.valid() else { throw StoreError.invalidBackup }
                data = saved
            } else {
                if seed { data.dogs = [DogProfile(name: "Jack", weight: 30), DogProfile(name: "Reyna", weight: 20, color: "pesca")] }
                try persist(data)
            }
        } catch { self.error = "Non riesco ad aprire l’archivio. I dati esistenti non sono stati sovrascritti."; saveAvailable = false }
    }
    func dog(_ id: UUID) -> DogProfile? { data.dogs.first { $0.id == id } }
    @discardableResult func update(_ edit: (inout AppData) -> Void) -> Bool {
        guard saveAvailable else { error = "L’archivio non è disponibile. Chiudi e riapri l’app."; return false }
        var next = data; edit(&next)
        guard next.valid() else { error = "Controlla i dati: quantità, date e cane associato devono essere validi."; return false }
        do { try persist(next); data = next; Task { await refreshNotifications() }; return true }
        catch { self.error = "Salvataggio non riuscito. Controlla lo spazio disponibile e riprova."; return false }
    }
    private func persist(_ value: AppData) throws {
        let encoded = try JSONEncoder().encode(value)
        try encoded.write(to: file, options: [.atomic, .completeFileProtectionUnlessOpen])
    }
    func removeDog(_ dog: DogProfile) -> Bool {
        let docs = data.documents.filter { $0.dogID == dog.id }
        do { for doc in docs { let url = documentURL(doc); if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) } } }
        catch { self.error = "Non riesco a eliminare gli allegati. Riprova prima di eliminare il profilo."; return false }
        return update { $0.deleteDog(dog.id) }
    }
    func removeTherapy(_ therapy: Therapy) { update { d in d.therapies.removeAll { $0.id == therapy.id }; d.doses.removeAll { $0.therapyID == therapy.id } } }
    func toggleDose(_ therapy: Therapy, date: Date, time: String) {
        guard Calendar.current.startOfDay(for: date) <= Calendar.current.startOfDay(for: Date()) else { return }
        let id = doseKey(therapy, date, time)
        update { d in if d.doses.contains(where: { $0.id == id }) { d.doses.removeAll { $0.id == id } }
            else { d.doses.append(Dose(id: id, dogID: therapy.dogID, therapyID: therapy.id, date: date, time: time)) } }
    }
    func documentURL(_ document: PetDocument) -> URL { documentsDirectory.appendingPathComponent(document.storedName) }
    func addDocument(_ source: URL, dogID: UUID) {
        let access = source.startAccessingSecurityScopedResource(); defer { if access { source.stopAccessingSecurityScopedResource() } }
        do {
            let bytes = try Data(contentsOf: source)
            guard !bytes.isEmpty && bytes.count <= 10 * 1024 * 1024 else { throw StoreError.tooLarge }
            var doc = PetDocument(dogID: dogID, name: source.lastPathComponent, storedName: "")
            doc.storedName = doc.id.uuidString + "." + source.pathExtension.lowercased().filter { $0.isLetter || $0.isNumber }
            let target = documentURL(doc); try bytes.write(to: target, options: [.atomic, .completeFileProtectionUnlessOpen])
            if !update({ $0.documents.append(doc) }) { try? FileManager.default.removeItem(at: target) }
        } catch { self.error = error.localizedDescription }
    }
    func removeDocument(_ document: PetDocument) {
        do { let url = documentURL(document); if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
            update { $0.documents.removeAll { $0.id == document.id } }
        } catch { self.error = "Documento non eliminato. Riprova." }
    }
    func backup(dogID: UUID? = nil) throws -> Data {
        var copy = data
        if let id = dogID { for dog in copy.dogs where dog.id != id { copy.deleteDog(dog.id) } }
        copy.documents = []
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(copy)
    }
    func readBackup(_ url: URL) throws -> AppData {
        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        let bytes = try Data(contentsOf: url); guard bytes.count <= 10 * 1024 * 1024 else { throw StoreError.tooLarge }
        var value = try JSONDecoder().decode(AppData.self, from: bytes); value.documents = []
        guard value.valid() else { throw StoreError.invalidBackup }; return value
    }
    func mergeBackup(_ backup: AppData) -> Bool {
        update { d in
            func merge<T: Identifiable>(_ old: [T], _ new: [T]) -> [T] { let ids = Set(new.map(\.id)); return old.filter { !ids.contains($0.id) } + new }
            d.dogs = merge(d.dogs, backup.dogs); d.plans = merge(d.plans, backup.plans); d.meals = merge(d.meals, backup.meals)
            d.therapies = merge(d.therapies, backup.therapies); d.doses = merge(d.doses, backup.doses)
            d.diary = merge(d.diary, backup.diary); d.reminders = merge(d.reminders, backup.reminders)
        }
    }
    func enableNotifications() async {
        do { notificationsAllowed = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]); await refreshNotifications() }
        catch { self.error = "Non riesco ad attivare i promemoria." }
    }
    func refreshNotifications() async {
        let center = UNUserNotificationCenter.current(); let settings = await center.notificationSettings()
        notificationsAllowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        guard notificationsAllowed else { return }
        center.removeAllPendingNotificationRequests()
        let calendar = Calendar.current, now = Date(); var events: [(String, Date, String, String)] = []
        for t in data.therapies {
            for offset in 0..<60 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)), t.active(on: day) else { continue }
                for time in t.times {
                    let parts = time.split(separator: ":").compactMap { Int($0) }
                    guard parts.count == 2, let when = calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: day), when > now else { continue }
                    let id = doseKey(t, day, time); if data.doses.contains(where: { $0.id == id }) { continue }
                    events.append((id, when, "\(dog(t.dogID)?.name ?? "Il tuo cane") · \(t.name)", t.dose))
                }
            }
        }
        for r in data.reminders where !r.done && r.date > now { events.append((r.id.uuidString, r.date, r.title, dog(r.dogID)?.name ?? "doggos")) }
        for e in events.sorted(by: { $0.1 < $1.1 }).prefix(60) {
            let content = UNMutableNotificationContent(); content.title = e.2; content.body = e.3; content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year,.month,.day,.hour,.minute], from: e.1), repeats: false)
            do { try await center.add(UNNotificationRequest(identifier: e.0, content: content, trigger: trigger)) }
            catch { self.error = "Alcuni promemoria non sono stati programmati. Riapri l’app e riprova." }
        }
    }
}
enum StoreError: LocalizedError {
    case invalidBackup, tooLarge
    var errorDescription: String? { switch self { case .invalidBackup: return "Copia dei dati non valida o incompatibile."; case .tooLarge: return "Il file deve essere inferiore a 10 MB." } }
}
