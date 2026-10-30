# doggos 🐾

App nativa iPhone e iPad in SwiftUI, per pasti, cure e piccoli ricordi dei propri cani.

## Funzioni

- Profili modificabili ed eliminabili con conferma del nome ed esportazione preventiva.
- Piano BARF inserito dall'utente, grammi per pasto e spesa settimanale.
- Terapie con dose testuale, giorni inclusivi e orari; registro delle somministrazioni.
- Diario di feci, peso, visite e note.
- Promemoria locali del telefono, previa autorizzazione dell'utente.
- Documenti PDF e foto, anteprima, condivisione ed eliminazione.
- Backup JSON dei dati; gli allegati si esportano separatamente.

I dati sono sul dispositivo e l'app funziona senza internet. Questa versione non sincronizza i dati con il sito web doggos. La copia JSON iPhone ha un formato separato. I due profili iniziali sono modificabili ed eliminabili e non si ricreano dopo l'eliminazione. Non sono precaricate terapie: vanno inserite secondo le indicazioni ricevute.

L'app non prescrive cure né calcola dosaggi in base al peso. Per i promemoria vengono programmati i 60 avvisi successivi; riaprendo l'app vengono aggiornati.

## Compilazione

Richiede iOS 17+, Xcode e XcodeGen. Nessuna dipendenza esterna nell'app.

```
xcodegen generate
open Doggos.xcodeproj
```

Su Codemagic sono disponibili `doggos-check` (test sul simulatore) e `doggos-testflight` (test, firma, archivio e caricamento ad Apple). Il collegamento App Store Connect è configurato nel servizio, mai nel repository. Bundle ID: `it.thisable.doggos`. L'upload non pubblica l'app sull'App Store e non avvia da solo la revisione beta esterna.

## Test

I test verificano eliminazione dei dati collegati, protezione degli altri profili, persistenza dell'eliminazione al riavvio, rimozione degli allegati, quantità dei pasti e inclusione dell'ultimo giorno delle terapie.

## Privacy

Nessuna analisi d'uso, pubblicità o server esterno. Foto e documenti sono scelti con il selettore di sistema. I dati sono salvati con la protezione file di iOS. Per cancellarli, eliminare i profili dall'app o disinstallare l'app; eventuali copie esportate restano nella destinazione scelta dall'utente.
