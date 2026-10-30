import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { TodayView() }.tabItem { Label("Oggi", systemImage: "pawprint.fill") }
            NavigationStack { DogsView() }.tabItem { Label("Cani", systemImage: "dog.fill") }
            NavigationStack { FoodView() }.tabItem { Label("Ciotola", systemImage: "fork.knife") }
            NavigationStack { TherapiesView() }.tabItem { Label("Cure", systemImage: "pills.fill") }
            NavigationStack { DiaryView() }.tabItem { Label("Diario", systemImage: "heart.text.clipboard") }
        }
    }
}
struct MoreMenu: View {
    var body: some View {
        Menu {
            NavigationLink(destination: RemindersView()) { Label("Promemoria", systemImage: "bell") }
            NavigationLink(destination: DocumentsView()) { Label("Documenti", systemImage: "folder") }
            NavigationLink(destination: SettingsView()) { Label("Impostazioni", systemImage: "gearshape") }
        } label: {
            Image(systemName: "ellipsis.circle").font(.title3)
        }
        .accessibilityLabel("Altre sezioni")
    }
}
extension View {
    func doggosPage(_ title: String) -> some View { self.navigationTitle(title).toolbar { ToolbarItem(placement: .topBarTrailing) { MoreMenu() } }.scrollContentBackground(.hidden).background(Palette.background) }
    func card() -> some View { self.padding(18).background(.white, in: RoundedRectangle(cornerRadius: 20)) }
}
struct DogBadge: View {
    let dog: DogProfile?
    var body: some View { Text(dog?.name ?? "Cane").font(.caption.weight(.medium)).padding(.horizontal,9).padding(.vertical,4).background(Palette.color(dog?.color ?? "salvia"), in: Capsule()) }
}
struct EmptyCard: View {
    let title: String; let text: String; var symbol = "pawprint"
    var body: some View { VStack(spacing:12) { Image(systemName:symbol).font(.largeTitle).foregroundStyle(Palette.green); Text(title).font(.headline); Text(text).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center) }.frame(maxWidth:.infinity).padding(.vertical,25).card() }
}
struct TodayView: View {
    @EnvironmentObject var store: DogStore
    @State private var date = Date(); @State private var meal = false; @State private var note = false
    var body: some View {
        ScrollView { VStack(alignment:.leading,spacing:20) {
            VStack(alignment:.leading,spacing:12) { Label("INSIEME, OGNI GIORNO", systemImage:"heart.fill").font(.caption2.weight(.semibold)).foregroundStyle(Palette.mint); Text("Piccole cure,\ngrandi amici.").font(.system(size:32,weight:.semibold,design:.rounded)); Text("Pasti, cure e ricordi.\nTutto quello che conta, con te.").font(.subheadline).foregroundStyle(.white.opacity(0.7)) }.padding(25).frame(maxWidth:.infinity,alignment:.leading).foregroundStyle(.white).background(Palette.green,in:RoundedRectangle(cornerRadius:24))
            HStack { Text("La tua famiglia").font(.title3.bold()); Spacer(); Text("\(store.data.dogs.count) cani").font(.caption).foregroundStyle(.secondary) }
            ForEach(store.data.dogs) { dog in NavigationLink { DogDetail(dogID:dog.id) } label: { HStack(spacing:15) { Image(systemName:"dog.fill").font(.system(size:32)).frame(width:55,height:55).background(.white.opacity(0.5),in:Circle()); VStack(alignment:.leading,spacing:5) { Text(dog.name).font(.title3.bold()); Text("\(grams(dog.weight)) kg").font(.caption) }; Spacer(); Image(systemName:"arrow.up.right") }.padding(18).background(Palette.color(dog.color),in:RoundedRectangle(cornerRadius:20)).foregroundStyle(Palette.green) } }
            if store.data.dogs.isEmpty { NavigationLink { DogsView() } label: { EmptyCard(title:"Un posto per ogni cane",text:"Aggiungi un profilo per iniziare.") } }
            DatePicker("La giornata",selection:$date,displayedComponents:.date).font(.headline)
            VStack(alignment:.leading,spacing:17) { Label("Le cure",systemImage:"pills").font(.headline)
                let active = store.data.therapies.filter { $0.active(on:date) }
                if active.isEmpty { Text("Nessuna terapia in programma.").foregroundStyle(.secondary).font(.subheadline) }
                ForEach(active) { t in ForEach(t.times,id:\.self) { time in
                    let done = store.data.doses.contains { $0.id == doseKey(t,date,time) }
                    Button { store.toggleDose(t,date:date,time:time) } label: { HStack(spacing:12) { Image(systemName:done ? "checkmark.circle.fill":"circle").font(.title2); VStack(alignment:.leading,spacing:5) { Text(t.name).font(.subheadline.bold()); HStack { DogBadge(dog:store.dog(t.dogID)); Text(t.dose).font(.caption).foregroundStyle(.secondary) } }; Spacer(); Text(time).font(.caption.monospacedDigit()) }.foregroundStyle(Palette.green) }.disabled(Calendar.current.startOfDay(for:date) > Calendar.current.startOfDay(for:Date()))
                } }
                Text("Spunta solo dopo la somministrazione.").font(.caption2).foregroundStyle(.secondary)
            }.card()
            VStack(alignment:.leading,spacing:14) { HStack { Label("Le ciotole",systemImage:"fork.knife").font(.headline); Spacer(); Button { meal=true } label: { Image(systemName:"plus.circle.fill") }.accessibilityLabel("Registra pasto").disabled(store.data.dogs.isEmpty) }
                ForEach(store.data.dogs) { dog in let meals=store.data.meals.filter { $0.dogID == dog.id && Calendar.current.isDate($0.date,inSameDayAs:date) }; HStack { DogBadge(dog:dog); Text("\(meals.count) pasti").font(.caption).foregroundStyle(.secondary); Spacer(); Text("\(grams(meals.reduce(0){$0+$1.grams})) g").font(.subheadline.bold()) } }
            }.card()
            Button { note=true } label: { Label("Com’è andata oggi?",systemImage:"square.and.pencil").frame(maxWidth:.infinity).padding() }.buttonStyle(.borderedProminent).disabled(store.data.dogs.isEmpty)
            Text("doggos. Fatto per chi li ama.").font(.caption2).foregroundStyle(.secondary).frame(maxWidth:.infinity).padding(.vertical)
        }.padding(20) }.doggosPage("doggos.").sheet(isPresented:$meal) { MealEditor() }.sheet(isPresented:$note) { DiaryEditor() }
    }
}
struct DogsView: View {
    @EnvironmentObject var store: DogStore; @State private var add = false
    var body: some View { List { ForEach(store.data.dogs) { d in NavigationLink { DogDetail(dogID:d.id) } label: { HStack(spacing:14) { Image(systemName:"dog.fill").font(.title2).padding(13).background(Palette.color(d.color),in:Circle()); VStack(alignment:.leading,spacing:5) { Text(d.name).font(.headline); Text("\(grams(d.weight)) kg" + (d.breed.isEmpty ? "" : " · \(d.breed)")).font(.caption).foregroundStyle(.secondary) } }.padding(.vertical,5) } }
        if store.data.dogs.isEmpty { Text("I profili eliminati non ricompaiono. Puoi aggiungere un nuovo cane quando vuoi.").font(.subheadline).foregroundStyle(.secondary) }
        Button { add=true } label: { Label("Aggiungi cane",systemImage:"plus") }
    }.doggosPage("I miei cani").sheet(isPresented:$add) { DogEditor() } }
}
struct DogDetail: View {
    @EnvironmentObject var store: DogStore
    @Environment(\.dismiss) var dismiss
    let dogID: UUID
    @State private var edit = false
    @State private var remove = false
    @State private var backup: BackupFile?
    @State private var exporting = false
    var body: some View {
        Group {
            if let dog = store.dog(dogID) {
                List {
                    Section {
                        VStack(spacing: 13) {
                            Image(systemName: "dog.fill").font(.system(size: 55)).padding(28).background(Palette.color(dog.color), in: Circle())
                            Text(dog.name).font(.largeTitle.bold())
                            Text("\(grams(dog.weight)) kg").font(.title3).foregroundStyle(.secondary)
                        }.frame(maxWidth: .infinity).padding(.vertical, 15)
                    }
                    Section("Il profilo") {
                        if !dog.breed.isEmpty { LabeledContent("Razza", value: dog.breed) }
                        if !dog.notes.isEmpty { Text(dog.notes) }
                        Button("Modifica profilo") { edit = true }
                    }
                    Section("I tuoi dati") {
                        Button { export(dog) } label: { Label("Esporta i dati del cane", systemImage: "square.and.arrow.up") }
                        Button(role: .destructive) { remove = true } label: { Label("Elimina profilo e dati", systemImage: "trash") }
                    }
                }
                .sheet(isPresented: $edit) { DogEditor(existing: dog) }
                .sheet(isPresented: $remove) { DeleteDogView(dog: dog) { remove = false; dismiss() } }
            } else {
                ContentUnavailableView("Profilo eliminato", systemImage: "dog")
            }
        }
        .doggosPage("Il profilo")
        .fileExporter(isPresented: $exporting, document: backup, contentType: .json, defaultFilename: "doggos-cane") { result in
            if case .failure(let error) = result { store.error = error.localizedDescription }
        }
    }
    func export(_ dog: DogProfile) {
        do { backup = BackupFile(data: try store.backup(dogID: dog.id)); exporting = true }
        catch { store.error = error.localizedDescription }
    }
}
struct DeleteDogView: View {
    @EnvironmentObject var store: DogStore
    @Environment(\.dismiss) var dismiss
    let dog: DogProfile
    let onDeleted: () -> Void
    @State private var name = ""
    @State private var backup: BackupFile?
    @State private var exporting = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Verranno rimossi definitivamente il profilo di \(dog.name), i pasti, il piano, le terapie, le somministrazioni, il diario, i promemoria e i documenti associati.")
                    Text("Gli altri cani non saranno modificati.").font(.subheadline).foregroundStyle(.secondary)
                }
                Section {
                    Button("Esporta prima di eliminare") {
                        do { backup = BackupFile(data: try store.backup(dogID: dog.id)); exporting = true }
                        catch { store.error = error.localizedDescription }
                    }
                    Text("Gli allegati si esportano separatamente da Documenti.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Scrivi \(dog.name) per confermare") {
                    TextField("Nome del cane", text: $name).autocorrectionDisabled()
                    Button("Elimina definitivamente", role: .destructive) {
                        if store.removeDog(dog) { onDeleted() }
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines) != dog.name)
                }
            }
            .navigationTitle("Eliminare \(dog.name)?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } } }
        }
        .fileExporter(isPresented: $exporting, document: backup, contentType: .json, defaultFilename: "doggos-cane") { result in
            if case .failure(let error) = result { store.error = error.localizedDescription }
        }
    }
}
struct DogEditor: View {
    @EnvironmentObject var store: DogStore; @Environment(\.dismiss) var dismiss
    var existing:DogProfile?; @State private var name=""; @State private var weight=""; @State private var breed=""; @State private var notes=""; @State private var color="salvia"
    var body:some View { NavigationStack { Form { Section("Il tuo compagno") { TextField("Nome",text:$name); TextField("Peso in kg",text:$weight).keyboardType(.decimalPad); TextField("Razza (facoltativa)",text:$breed); Picker("Colore",selection:$color) { Text("Salvia").tag("salvia"); Text("Pesca").tag("pesca"); Text("Lavanda").tag("lavanda") } }; Section("Note") { TextEditor(text:$notes).frame(minHeight:90) } }.navigationTitle(existing == nil ? "Aggiungi cane":"Modifica cane").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.cancellationAction) { Button("Annulla") { dismiss() } }; ToolbarItem(placement:.confirmationAction) { Button("Salva") { var dog=existing ?? DogProfile(name:name,weight:numberValue(weight)); dog.name=name.trimmingCharacters(in:.whitespacesAndNewlines); dog.weight=numberValue(weight); dog.breed=breed; dog.notes=notes; dog.color=color; if store.update({ d in d.dogs.removeAll{$0.id==dog.id}; d.dogs.append(dog) }) { dismiss() } }.disabled(name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || numberValue(weight)<=0 || numberValue(weight)>150) } }.onAppear { if let d=existing { name=d.name; weight=String(d.weight); breed=d.breed; notes=d.notes; color=d.color } } } }
}
func numberValue(_ text:String)->Double { Double(text.replacingOccurrences(of:",",with:".")) ?? 0 }
struct DogPicker: View {
    @EnvironmentObject var store:DogStore; @Binding var id:UUID?
    var body:some View { Picker("Cane",selection:$id) { Text("Scegli un cane").tag(nil as UUID?); ForEach(store.data.dogs) { Text($0.name).tag(Optional($0.id)) } }.onAppear { if id == nil { id=store.data.dogs.first?.id } } }
}
struct FoodView:View {
    @EnvironmentObject var store:DogStore; @State private var addPlan=false; @State private var editPlan:FoodPlan?; @State private var addMeal=false; @State private var editMeal:Meal?; @State private var removePlan:FoodPlan?; @State private var removeMeal:Meal?
    var body:some View { List {
        Section { Text("Inserisci le quantità giornaliere concordate con il veterinario. doggos calcola i totali e la ripartizione dei pasti.").font(.caption).foregroundStyle(.secondary) }
        Section("Piani alimentari") { ForEach(store.data.plans) { plan in VStack(alignment:.leading,spacing:12) { HStack { DogBadge(dog:store.dog(plan.dogID)); Spacer(); Button("Modifica") { editPlan=plan }.font(.caption) }; Text(plan.name).font(.headline); HStack { Text("\(grams(plan.total)) g al giorno"); Spacer(); Text("\(grams(plan.total/Double(plan.meals))) g/pasto") }.font(.subheadline); ForEach(plan.ingredients) { i in LabeledContent(i.name,value:"\(grams(i.grams)) g").font(.caption) }; Text("\(plan.meals) pasti al giorno, in parti uguali").font(.caption).foregroundStyle(.secondary); if !plan.notes.isEmpty { Text(plan.notes).font(.caption) } }.padding(.vertical,6).swipeActions { Button("Elimina",role:.destructive) { removePlan=plan } } }; Button { addPlan=true } label: { Label("Aggiungi piano",systemImage:"plus") }.disabled(store.data.dogs.isEmpty) }
        if !store.data.plans.isEmpty { Section("Spesa per 7 giorni") { ForEach(shopping,id:\.0) { item in LabeledContent(item.0,value:"\(grams(item.1/1000)) kg") } } }
        Section("Pasti registrati") { Button { addMeal=true } label: { Label("Registra pasto",systemImage:"plus") }.disabled(store.data.dogs.isEmpty); ForEach(store.data.meals.sorted{$0.date>$1.date}) { m in Button { editMeal=m } label: { HStack { VStack(alignment:.leading,spacing:6) { Text("\(store.dog(m.dogID)?.name ?? "Cane") · \(grams(m.grams)) g"); Text(m.date,format:.dateTime.day().month().hour().minute()).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName:"chevron.right").font(.caption) }.foregroundStyle(.primary) }.swipeActions { Button("Elimina",role:.destructive) { removeMeal=m } } } }
    }.doggosPage("La ciotola").sheet(isPresented:$addPlan) { PlanEditor() }.sheet(item:$editPlan) { PlanEditor(existing:$0) }.sheet(isPresented:$addMeal) { MealEditor() }.sheet(item:$editMeal) { MealEditor(existing:$0) }
    .alert("Eliminare il piano?",isPresented:Binding(get:{removePlan != nil},set:{if !$0{removePlan=nil}})) { Button("Elimina",role:.destructive) { if let p=removePlan { store.update{$0.plans.removeAll{$0.id==p.id}} } }; Button("Annulla",role:.cancel) {} }
    .alert("Eliminare il pasto?",isPresented:Binding(get:{removeMeal != nil},set:{if !$0{removeMeal=nil}})) { Button("Elimina",role:.destructive) { if let m=removeMeal { store.update{$0.meals.removeAll{$0.id==m.id}} } }; Button("Annulla",role:.cancel) {} }
    }
    var shopping:[(String,Double)] { var s:[String:Double]=[:]; for p in store.data.plans { for i in p.ingredients { s[i.name,default:0] += i.grams*7 } }; return s.sorted{$0.key<$1.key}.map{($0.key,$0.value)} }
}
struct PlanEditor:View {
    @EnvironmentObject var store:DogStore; @Environment(\.dismiss) var dismiss; var existing:FoodPlan?
    @State private var dogID:UUID?; @State private var name="Piano BARF"; @State private var meals=2; @State private var ingredients=[Ingredient(name:"",grams:0)]; @State private var notes=""; @State private var message=""
    var body:some View { NavigationStack { Form { Section { DogPicker(id:$dogID); TextField("Nome del piano",text:$name); Stepper("\(meals) pasti al giorno",value:$meals,in:1...6) }; Section("Ingredienti · grammi al giorno") { ForEach($ingredients) { $i in HStack { TextField("Ingrediente",text:$i.name); TextField("Grammi",value:$i.grams,format:.number).keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width:80); Text("g").foregroundStyle(.secondary) } }.onDelete { indices in if ingredients.count > indices.count { ingredients.remove(atOffsets:indices) } }; Button("Aggiungi ingrediente") { ingredients.append(Ingredient(name:"",grams:0)) }.disabled(ingredients.count>=20); Text("Totale: \(grams(ingredients.reduce(0){$0+$1.grams})) g").font(.headline) }; Section("Note") { TextEditor(text:$notes) }; if !message.isEmpty { Text(message).foregroundStyle(.red) } }.navigationTitle("Piano alimentare").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.cancellationAction) { Button("Annulla") { dismiss() } }; ToolbarItem(placement:.confirmationAction) { Button("Salva") { save() }.disabled(dogID==nil || name.isEmpty || ingredients.contains{$0.name.isEmpty || $0.grams<0} || ingredients.reduce(0,{$0+$1.grams})<=0) } }.onAppear { if let p=existing { dogID=p.dogID; name=p.name; meals=p.meals; ingredients=p.ingredients; notes=p.notes } } } }
    func save() { guard let id=dogID else{return}; if store.data.plans.contains(where:{$0.dogID==id && $0.id != existing?.id}) { message="Questo cane ha già un piano: modifica quello esistente."; return }; var plan=existing ?? FoodPlan(dogID:id,ingredients:ingredients); plan.dogID=id; plan.name=name; plan.meals=meals; plan.ingredients=ingredients; plan.notes=notes; if store.update({$0.plans.removeAll{$0.id==plan.id};$0.plans.append(plan)}) {dismiss()} }
}
struct MealEditor:View {
    @EnvironmentObject var store:DogStore; @Environment(\.dismiss) var dismiss; var existing:Meal?; @State private var dogID:UUID?; @State private var date=Date(); @State private var amount=""; @State private var notes=""
    var body:some View { NavigationStack { Form { DogPicker(id:$dogID); DatePicker("Data e ora",selection:$date); TextField("Quantità in grammi",text:$amount).keyboardType(.decimalPad); Section("Note") {TextEditor(text:$notes)} }.navigationTitle("Registra pasto").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.cancellationAction) { Button("Annulla"){dismiss()} }; ToolbarItem(placement:.confirmationAction) {Button("Salva"){guard let id=dogID else{return}; var m=existing ?? Meal(dogID:id,grams:numberValue(amount));m.dogID=id;m.date=date;m.grams=numberValue(amount);m.notes=notes;if store.update({$0.meals.removeAll{$0.id==m.id};$0.meals.append(m)}){dismiss()} }.disabled(dogID==nil || numberValue(amount)<=0 || numberValue(amount)>10000)} }.onAppear {if let m=existing{dogID=m.dogID;date=m.date;amount=String(m.grams);notes=m.notes}} } }
}
struct TherapiesView:View {
    @EnvironmentObject var store:DogStore; @State private var add=false; @State private var editing:Therapy?; @State private var removing:Therapy?
    var body:some View { List {
        Section { Text("Registra dose, giorni e orari ricevuti dal veterinario. L’app non calcola terapie in base al peso.").font(.caption).foregroundStyle(.secondary) }
        Section { ForEach(store.data.therapies) { t in VStack(alignment:.leading,spacing:10) { HStack {DogBadge(dog:store.dog(t.dogID));Spacer();Text(t.active(on:Date()) ? "In corso":t.start>Date() ? "In programma":"Conclusa").font(.caption).foregroundStyle(.secondary)};Text(t.name).font(.title3.bold());Text("\(t.dose) · \(t.times.count) volte al giorno").font(.subheadline);Text("\(t.start.formatted(date:.abbreviated,time:.omitted)) – \(t.end.formatted(date:.abbreviated,time:.omitted))").font(.caption).foregroundStyle(.secondary);Text(t.times.joined(separator:" · ")).font(.subheadline.monospacedDigit());if !t.notes.isEmpty{Text(t.notes).font(.caption)};Button("Modifica"){editing=t}.font(.caption) }.padding(.vertical,7).swipeActions {Button("Elimina",role:.destructive){removing=t}} };Button{add=true}label:{Label("Aggiungi terapia",systemImage:"plus")}.disabled(store.data.dogs.isEmpty) }
        Section { NavigationLink{SettingsView()}label:{Label(store.notificationsAllowed ? "Promemoria del telefono attivi":"Attiva i promemoria del telefono",systemImage:"bell")};Text("Le somministrazioni si spuntano nella sezione Oggi.").font(.caption).foregroundStyle(.secondary) }
    }.doggosPage("Le cure").sheet(isPresented:$add){TherapyEditor()}.sheet(item:$editing){TherapyEditor(existing:$0)}.alert("Eliminare questa terapia?",isPresented:Binding(get:{removing != nil},set:{if !$0{removing=nil}})){Button("Elimina",role:.destructive){if let t=removing{store.removeTherapy(t)}};Button("Annulla",role:.cancel){}}message:{Text("Saranno eliminate anche le somministrazioni registrate.")} }
}
struct TherapyEditor:View {
    @EnvironmentObject var store:DogStore; @Environment(\.dismiss) var dismiss; var existing:Therapy?
    @State private var dogID:UUID?;@State private var name="";@State private var dose="";@State private var start=Calendar.current.startOfDay(for:Date());@State private var end=Calendar.current.date(byAdding:.day,value:9,to:Calendar.current.startOfDay(for:Date()))!;@State private var times=[Calendar.current.date(bySettingHour:9,minute:0,second:0,of:Date())!];@State private var notes=""
    var body:some View { NavigationStack { Form { Section("Indicazioni ricevute") {DogPicker(id:$dogID).disabled(existing != nil && store.data.doses.contains{$0.therapyID==existing!.id});TextField("Nome del prodotto",text:$name);TextField("Dose per volta, es. 1 compressa",text:$dose);DatePicker("Primo giorno",selection:$start,displayedComponents:.date);DatePicker("Ultimo giorno incluso",selection:$end,in:start...,displayedComponents:.date)};Section("Orari giornalieri") {ForEach(times.indices,id:\.self){i in DatePicker("Orario \(i+1)",selection:$times[i],displayedComponents:.hourAndMinute)}.onDelete{indices in if times.count>indices.count{times.remove(atOffsets:indices)}};Button("Aggiungi orario"){times.append(Calendar.current.date(bySettingHour:20,minute:0,second:0,of:Date())!)}.disabled(times.count>=6)};Section("Note"){TextEditor(text:$notes)} }.navigationTitle("Terapia").navigationBarTitleDisplayMode(.inline).toolbar {ToolbarItem(placement:.cancellationAction){Button("Annulla"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("Salva"){save()}.disabled(dogID==nil || name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || dose.isEmpty || end<start)}}.onAppear{if let t=existing{dogID=t.dogID;name=t.name;dose=t.dose;start=t.start;end=t.end;notes=t.notes;times=t.times.compactMap{v in let p=v.split(separator:":").compactMap{Int($0)};guard p.count==2 else{return nil};return Calendar.current.date(bySettingHour:p[0],minute:p[1],second:0,of:Date())}}} } }
    func save(){guard let id=dogID else{return};let clock=Array(Set(times.map{time in let c=Calendar.current.dateComponents([.hour,.minute],from:time);return String(format:"%02d:%02d",c.hour!,c.minute!)})).sorted();var t=existing ?? Therapy(dogID:id,name:name,dose:dose,start:start,end:end,times:clock);t.dogID=id;t.name=name;t.dose=dose;t.start=Calendar.current.startOfDay(for:start);t.end=Calendar.current.startOfDay(for:end);t.times=clock;t.notes=notes;if store.update({$0.therapies.removeAll{$0.id==t.id};$0.therapies.append(t)}){dismiss()}}
}
struct DiaryView:View {
    @EnvironmentObject var store:DogStore;@State private var add=false;@State private var editing:DiaryEntry?;@State private var removing:DiaryEntry?
    var body:some View {List {Section {Button{add=true}label:{Label("Nuova annotazione",systemImage:"plus")}.disabled(store.data.dogs.isEmpty)};ForEach(store.data.diary.sorted{$0.date>$1.date}){entry in Button{editing=entry}label:{VStack(alignment:.leading,spacing:9){HStack{DogBadge(dog:store.dog(entry.dogID));Spacer();Text(entry.date,format:.dateTime.day().month()).font(.caption).foregroundStyle(.secondary)};Text("\(entry.type) · \(entry.value)\(entry.type=="Peso" ? " kg":"")").font(.headline);if !entry.notes.isEmpty{Text(entry.notes).font(.subheadline).foregroundStyle(.secondary)}}.foregroundStyle(.primary).padding(.vertical,6)}.swipeActions{Button("Elimina",role:.destructive){removing=entry}}};if store.data.diary.isEmpty{Text("Feci, peso, visite o una piccola nota. La loro storia inizia qui.").foregroundStyle(.secondary)}}.doggosPage("Il diario").sheet(isPresented:$add){DiaryEditor()}.sheet(item:$editing){DiaryEditor(existing:$0)}.alert("Eliminare l’annotazione?",isPresented:Binding(get:{removing != nil},set:{if !$0{removing=nil}})){Button("Elimina",role:.destructive){if let e=removing{store.update{$0.diary.removeAll{$0.id==e.id}}}};Button("Annulla",role:.cancel){}} }
}
struct DiaryEditor:View {
    @EnvironmentObject var store:DogStore;@Environment(\.dismiss)var dismiss;var existing:DiaryEntry?;@State private var dogID:UUID?;@State private var date=Date();@State private var type="Feci";@State private var value="Formate";@State private var notes=""
    let types=["Feci","Peso","Visita","Nota"];let stools=["Formate","Morbide","Liquide","Dure","Con sangue o muco"]
    var body:some View{NavigationStack{Form{DogPicker(id:$dogID);DatePicker("Data e ora",selection:$date);Picker("Tipo",selection:$type){ForEach(types,id:\.self){Text($0)}}.onChange(of:type){_,new in value=new=="Feci" ? "Formate":""};if type=="Feci"{Picker("Consistenza",selection:$value){ForEach(stools,id:\.self){Text($0)}}}else{TextField(type=="Peso" ? "Peso in kg":"Titolo",text:$value).keyboardType(type=="Peso" ? .decimalPad:.default)};Section("Note"){TextEditor(text:$notes).frame(minHeight:100)};if type=="Peso"{Text("Questa misura resta nel diario. Per cambiare il peso attuale, modifica il profilo.").font(.caption).foregroundStyle(.secondary)}}.navigationTitle("Nel diario").navigationBarTitleDisplayMode(.inline).toolbar{ToolbarItem(placement:.cancellationAction){Button("Annulla"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("Salva"){guard let id=dogID else{return};var e=existing ?? DiaryEntry(dogID:id,type:type,value:value);e.dogID=id;e.date=date;e.type=type;e.value=value;e.notes=notes;if store.update({$0.diary.removeAll{$0.id==e.id};$0.diary.append(e)}){dismiss()}}.disabled(dogID==nil || value.isEmpty || (type=="Peso" && (numberValue(value)<=0 || numberValue(value)>150)))}}.onAppear{if let e=existing{dogID=e.dogID;date=e.date;type=e.type;value=e.value;notes=e.notes}}}}
}
struct RemindersView:View {
    @EnvironmentObject var store:DogStore;@State private var add=false;@State private var editing:Reminder?;@State private var removing:Reminder?
    var body:some View{List{Section{Button{add=true}label:{Label("Aggiungi promemoria",systemImage:"plus")}.disabled(store.data.dogs.isEmpty);Text("Gli avvisi sul telefono richiedono il permesso notifiche in Impostazioni.").font(.caption).foregroundStyle(.secondary)};ForEach(store.data.reminders.sorted{$0.date<$1.date}){r in HStack(spacing:13){Button{store.update{d in if let i=d.reminders.firstIndex(where:{$0.id==r.id}){d.reminders[i].done.toggle()}}}label:{Image(systemName:r.done ? "checkmark.circle.fill":"circle").font(.title2)}.buttonStyle(.borderless).accessibilityLabel(r.done ? "Riapri promemoria":"Completa promemoria");Button{editing=r}label:{VStack(alignment:.leading,spacing:6){Text(r.title).strikethrough(r.done).font(.headline);DogBadge(dog:store.dog(r.dogID));Text(r.date,format:.dateTime.day().month().hour().minute()).font(.caption).foregroundStyle(.secondary)}}.foregroundStyle(.primary).buttonStyle(.borderless)}.padding(.vertical,4).swipeActions{Button("Elimina",role:.destructive){removing=r}}}}.doggosPage("Promemoria").sheet(isPresented:$add){ReminderEditor()}.sheet(item:$editing){ReminderEditor(existing:$0)}.alert("Eliminare il promemoria?",isPresented:Binding(get:{removing != nil},set:{if !$0{removing=nil}})){Button("Elimina",role:.destructive){if let r=removing{store.update{$0.reminders.removeAll{$0.id==r.id}}}};Button("Annulla",role:.cancel){}}}
}
struct ReminderEditor:View {
    @EnvironmentObject var store:DogStore;@Environment(\.dismiss)var dismiss;var existing:Reminder?;@State private var dogID:UUID?;@State private var title="";@State private var date=Date();@State private var notes=""
    var body:some View{NavigationStack{Form{DogPicker(id:$dogID);TextField("Cosa vuoi ricordare?",text:$title);DatePicker("Data e ora",selection:$date);Section("Note"){TextEditor(text:$notes)}}.navigationTitle("Promemoria").navigationBarTitleDisplayMode(.inline).toolbar{ToolbarItem(placement:.cancellationAction){Button("Annulla"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("Salva"){guard let id=dogID else{return};var r=existing ?? Reminder(dogID:id,title:title,date:date);r.dogID=id;r.title=title;r.date=date;r.notes=notes;if store.update({$0.reminders.removeAll{$0.id==r.id};$0.reminders.append(r)}){dismiss()}}.disabled(dogID==nil || title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)}}.onAppear{if let r=existing{dogID=r.dogID;title=r.title;date=r.date;notes=r.notes}}}}
}
struct DocumentsView:View {
    @EnvironmentObject var store:DogStore;@State private var dogID:UUID?;@State private var importing=false;@State private var preview:URL?;@State private var removing:PetDocument?
    var body:some View{List{Section("Carica un documento"){DogPicker(id:$dogID);Button{importing=true}label:{Label("Scegli PDF o foto",systemImage:"plus")}.disabled(dogID==nil);Text("Massimo 10 MB. I documenti restano su questo dispositivo.").font(.caption).foregroundStyle(.secondary)};Section("I tuoi documenti"){ForEach(store.data.documents){doc in HStack{Button{preview=store.documentURL(doc)}label:{VStack(alignment:.leading,spacing:7){Label(doc.name,systemImage:"doc.text").lineLimit(2);DogBadge(dog:store.dog(doc.dogID))}}.foregroundStyle(.primary).buttonStyle(.borderless);Spacer();ShareLink(item:store.documentURL(doc)){Image(systemName:"square.and.arrow.up")}.buttonStyle(.borderless)}.swipeActions{Button("Elimina",role:.destructive){removing=doc}}}}}.doggosPage("Documenti").quickLookPreview($preview).fileImporter(isPresented:$importing,allowedContentTypes:[.pdf,.image]){result in switch result{case .success(let url):if let id=dogID{store.addDocument(url,dogID:id)};case .failure(let error):store.error=error.localizedDescription}}.alert("Eliminare il documento?",isPresented:Binding(get:{removing != nil},set:{if !$0{removing=nil}})){Button("Elimina",role:.destructive){if let d=removing{store.removeDocument(d)}};Button("Annulla",role:.cancel){}}}
}
struct BackupFile:FileDocument {
    static var readableContentTypes:[UTType]{[.json]};var data:Data
    init(data:Data){self.data=data}
    init(configuration:ReadConfiguration)throws{data=configuration.file.regularFileContents ?? Data()}
    func fileWrapper(configuration:WriteConfiguration)throws->FileWrapper{FileWrapper(regularFileWithContents:data)}
}
struct SettingsView:View {
    @EnvironmentObject var store:DogStore;@State private var exporting=false;@State private var importing=false;@State private var backup:BackupFile?;@State private var pending:AppData?;@State private var confirmImport=false
    var body:some View{List{Section("Promemoria sul telefono"){LabeledContent("Notifiche",value:store.notificationsAllowed ? "Attive":"Non attive");Button("Attiva promemoria"){Task{await store.enableNotifications()}};Button("Apri impostazioni iPhone"){if let url=URL(string:UIApplication.openSettingsURLString){UIApplication.shared.open(url)}};Text("doggos programma i prossimi 60 avvisi. Apri regolarmente l’app per aggiornare quelli successivi.").font(.caption).foregroundStyle(.secondary)};Section("Copie dei dati"){Button{do{backup=BackupFile(data:try store.backup());exporting=true}catch{store.error=error.localizedDescription}}label:{Label("Esporta dati",systemImage:"square.and.arrow.up")};Button{importing=true}label:{Label("Importa copia iPhone",systemImage:"square.and.arrow.down")};Text("La copia JSON include profili e registrazioni. Gli allegati vanno salvati separatamente da Documenti. Il backup del sito web ha un formato diverso.").font(.caption).foregroundStyle(.secondary)};Section("Il tuo spazio"){Text("Questa versione conserva i dati sul telefono, anche senza internet. Non sincronizza automaticamente i dati con il sito doggos.").font(.subheadline);NavigationLink("Gestisci ed elimina profili"){DogsView()}};Section("doggos 1.0"){Text("Un posto per prendersi cura di loro, ogni giorno.").font(.subheadline);Text("Le dosi e i piani sono quelli inseriti da te. L’app non formula prescrizioni.").font(.caption).foregroundStyle(.secondary)}}.doggosPage("Impostazioni").fileExporter(isPresented:$exporting,document:backup,contentType:.json,defaultFilename:"doggos-iphone-\(dayKey(Date()))"){result in if case .failure(let error)=result{store.error=error.localizedDescription}}.fileImporter(isPresented:$importing,allowedContentTypes:[.json]){result in do{let url=try result.get();pending=try store.readBackup(url);confirmImport=true}catch{store.error=error.localizedDescription}}.alert("Importare la copia?",isPresented:$confirmImport){Button("Importa"){if let data=pending{_ = store.mergeBackup(data)};pending=nil};Button("Annulla",role:.cancel){pending=nil}}message:{Text("I dati con lo stesso identificativo verranno aggiornati. Gli altri saranno aggiunti. Gli allegati non sono inclusi.")}}
}
