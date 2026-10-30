import Foundation

struct DogProfile: Identifiable, Codable, Equatable {
    var id = UUID(); var name: String; var weight: Double; var breed = ""; var notes = ""; var color = "salvia"
}
struct Ingredient: Identifiable, Codable, Equatable { var id = UUID(); var name: String; var grams: Double }
struct FoodPlan: Identifiable, Codable, Equatable {
    var id = UUID(); var dogID: UUID; var name = "Piano BARF"; var meals = 2; var ingredients: [Ingredient]; var notes = ""
    var total: Double { ingredients.reduce(0) { $0 + $1.grams } }
}
struct Meal: Identifiable, Codable, Equatable { var id = UUID(); var dogID: UUID; var date = Date(); var grams: Double; var notes = "" }
struct Therapy: Identifiable, Codable, Equatable {
    var id = UUID(); var dogID: UUID; var name: String; var dose: String; var start: Date; var end: Date; var times: [String]; var notes = ""
    func active(on date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: start) && day <= calendar.startOfDay(for: end)
    }
}
struct Dose: Identifiable, Codable, Equatable { var id: String; var dogID: UUID; var therapyID: UUID; var date: Date; var time: String }
struct DiaryEntry: Identifiable, Codable, Equatable { var id = UUID(); var dogID: UUID; var date = Date(); var type: String; var value: String; var notes = "" }
struct Reminder: Identifiable, Codable, Equatable { var id = UUID(); var dogID: UUID; var title: String; var date: Date; var done = false; var notes = "" }
struct PetDocument: Identifiable, Codable, Equatable { var id = UUID(); var dogID: UUID; var name: String; var storedName: String }
struct AppData: Codable, Equatable {
    var version = 1
    var dogs: [DogProfile] = []
    var plans: [FoodPlan] = []
    var meals: [Meal] = []
    var therapies: [Therapy] = []
    var doses: [Dose] = []
    var diary: [DiaryEntry] = []
    var reminders: [Reminder] = []
    var documents: [PetDocument] = []
    mutating func deleteDog(_ id: UUID) {
        dogs.removeAll { $0.id == id }; plans.removeAll { $0.dogID == id }
        meals.removeAll { $0.dogID == id }; therapies.removeAll { $0.dogID == id }
        doses.removeAll { $0.dogID == id }; diary.removeAll { $0.dogID == id }
        reminders.removeAll { $0.dogID == id }; documents.removeAll { $0.dogID == id }
    }
    func valid() -> Bool {
        guard version == 1, dogs.count <= 100, Set(dogs.map(\.id)).count == dogs.count,
              dogs.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.weight.isFinite && $0.weight > 0 && $0.weight <= 150 }) else { return false }
        let ids = Set(dogs.map(\.id)); let treatments = Dictionary(therapies.map { ($0.id, $0.dogID) }, uniquingKeysWith: { a, _ in a })
        return plans.allSatisfy { ids.contains($0.dogID) && $0.meals > 0 && $0.meals <= 6 && $0.total > 0 && $0.ingredients.allSatisfy { !$0.name.isEmpty && $0.grams.isFinite && $0.grams >= 0 && $0.grams <= 10000 } }
        && Set(plans.map(\.dogID)).count == plans.count
        && meals.allSatisfy { ids.contains($0.dogID) && $0.grams.isFinite && $0.grams > 0 && $0.grams <= 10000 }
        && therapies.allSatisfy { ids.contains($0.dogID) && !$0.name.isEmpty && !$0.dose.isEmpty && $0.end >= $0.start && !$0.times.isEmpty && $0.times.count <= 6 && $0.times.allSatisfy { validTime($0) } }
        && doses.allSatisfy { ids.contains($0.dogID) && treatments[$0.therapyID] == $0.dogID && validTime($0.time) }
        && diary.allSatisfy { ids.contains($0.dogID) && !$0.value.isEmpty }
        && reminders.allSatisfy { ids.contains($0.dogID) && !$0.title.isEmpty }
        && documents.allSatisfy { ids.contains($0.dogID) && !$0.storedName.contains("/") && !$0.storedName.contains("..") }
    }
}
func validTime(_ value: String) -> Bool {
    let parts = value.split(separator: ":"); guard parts.count == 2, parts[0].count == 2, parts[1].count == 2,
    let h = Int(parts[0]), let m = Int(parts[1]) else { return false }; return (0...23).contains(h) && (0...59).contains(m)
}
func dayKey(_ date: Date) -> String {
    let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
}
func doseKey(_ therapy: Therapy, _ date: Date, _ time: String) -> String { "\(therapy.id.uuidString)|\(dayKey(date))|\(time)" }
func grams(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...1))) }
