import XCTest
@testable import Doggos

final class DoggosTests: XCTestCase {
    func testCascadeLeavesOtherDog() throws {
        let a=DogProfile(name:"Uno",weight:20), b=DogProfile(name:"Due",weight:30)
        var d=AppData();d.dogs=[a,b]
        d.meals=[Meal(dogID:a.id,grams:100),Meal(dogID:b.id,grams:200)]
        d.plans=[FoodPlan(dogID:a.id,ingredients:[Ingredient(name:"Ingrediente",grams:100)])]
        let t=Therapy(dogID:a.id,name:"Terapia di test",dose:"Dose indicata",start:Date(),end:Date(),times:["09:00"])
        d.therapies=[t];d.doses=[Dose(id:"dose",dogID:a.id,therapyID:t.id,date:Date(),time:"09:00")]
        d.diary=[DiaryEntry(dogID:a.id,type:"Nota",value:"Test")]
        d.reminders=[Reminder(dogID:a.id,title:"Test",date:Date())]
        d.documents=[PetDocument(dogID:a.id,name:"Test",storedName:"test.pdf")]
        d.deleteDog(a.id)
        XCTAssertEqual(d.dogs,[b]);XCTAssertEqual(d.meals.count,1);XCTAssertEqual(d.meals[0].dogID,b.id)
        XCTAssertTrue(d.plans.isEmpty && d.therapies.isEmpty && d.doses.isEmpty && d.diary.isEmpty && d.reminders.isEmpty && d.documents.isEmpty)
        XCTAssertTrue(d.valid())
    }
    @MainActor func testDeletionSurvivesReopeningAndRemovesFiles() throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:root)}
        let s=DogStore(directory:root);let dog=try XCTUnwrap(s.data.dogs.first)
        let doc=PetDocument(dogID:dog.id,name:"Prova.pdf",storedName:"prova.pdf")
        try Data("test".utf8).write(to:s.documentURL(doc));XCTAssertTrue(s.update{$0.documents.append(doc)})
        XCTAssertTrue(s.removeDog(dog));XCTAssertFalse(FileManager.default.fileExists(atPath:s.documentURL(doc).path))
        let reopened=DogStore(directory:root);XCTAssertFalse(reopened.data.dogs.contains{$0.id==dog.id});XCTAssertEqual(reopened.data.dogs.count,1)
        XCTAssertTrue(reopened.removeDog(reopened.data.dogs[0]));XCTAssertTrue(DogStore(directory:root).data.dogs.isEmpty)
    }
    func testPlanTotalsAndInvalidWeight() {
        let p=FoodPlan(dogID:UUID(),ingredients:[Ingredient(name:"A",grams:250),Ingredient(name:"B",grams:50)])
        XCTAssertEqual(p.total,300);XCTAssertEqual(p.total/Double(p.meals),150)
        var d=AppData();d.dogs=[DogProfile(name:"Cane",weight:-1)];XCTAssertFalse(d.valid())
        XCTAssertFalse(validTime("25:00"));XCTAssertFalse(validTime("09:60"));XCTAssertTrue(validTime("09:00"))
    }
    func testTherapyLastDayInclusive() throws {
        var calendar=Calendar(identifier:.gregorian);calendar.timeZone=try XCTUnwrap(TimeZone(secondsFromGMT:0))
        let start=try XCTUnwrap(calendar.date(from:DateComponents(year:2026,month:11,day:1)))
        let end=try XCTUnwrap(calendar.date(byAdding:.day,value:9,to:start))
        let t=Therapy(dogID:UUID(),name:"Test",dose:"Test",start:start,end:end,times:["09:00"])
        XCTAssertTrue(t.active(on:end,calendar:calendar));XCTAssertFalse(t.active(on:calendar.date(byAdding:.day,value:1,to:end)!,calendar:calendar))
    }
}
