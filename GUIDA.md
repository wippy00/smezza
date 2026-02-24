# Guida di Sviluppo: Smezza P2P (Local-First)

## 1. Visione del Progetto
Creare un'app per la gestione delle spese di gruppo che sia **resiliente, economica e privata**. L'app deve funzionare perfettamente offline, permettere la sincronizzazione tra amici senza internet (P2P) e offrire un backup opzionale su un server leggero (PocketBase).

---

## 2. Stack Tecnologico
*   **Frontend:** Flutter
*   **Database Locale:** SQLite tramite **Drift** (per reattività e type-safety).
*   **UI:** Material 3 con supporto a **Dynamic Color**.
*   **P2P Sync:** `nearby_connections` (Google Nearby API).
*   **Server/Cloud:** PocketBase (Self-hosted o Free Tier).
*   **Identità:** UUID v4 (generati localmente).

---

## 3. Architettura dei Dati (Il Cuore)
Il database locale è la "fonte della verità". Non si cancellano mai i dati, si marcano come eliminati.

### Tabelle Principali (Schema SQLite)
1.  **Users:** `id (UUID)`, `name`, `is_me (bool)`, `updated_at`, `is_deleted`.
2.  **Groups:** `id (UUID)`, `name`, `currency_code`, `updated_at`, `is_deleted`.
3.  **Expenses:** 
    *   `id (UUID)`, `group_id`, `payer_id`, `description`, `amount`, `currency_code`.
    *   `split_type`: (EQUAL, EXACT, PERCENT, SHARES, ADJUSTMENT).
    *   `updated_at`, `is_deleted`, `is_synced (local only)`.
4.  **Expense_Splits:** 
    *   `id (UUID)`, `expense_id`, `user_id`.
    *   `calculated_amount`: Il valore monetario finale (es. 33.33).
    *   `raw_value`: Il valore di input (es. 2 quote, o 50%). Serve per l'editing.

---

## 4. Algoritmi di Splitting (Logica Frontend)
La logica deve risiedere nel codice Dart, non nel DB.

*   **Parti Uguali:** `Totale / N`. Gestire il resto aggiungendo i centesimi mancanti al primo utente.
*   **Quote (Shares):** `(Totale / Somma_Quote_Totali) * Quote_Utente`. Usato per famiglie o notti in hotel.
*   **Aggiustamento:** `(Totale - Somma_Extra) / N + Extra_Utente`.
*   **Semplificazione Debiti (Netting):**
    1.  Calcola il saldo netto di ogni utente (Pagato - Dovuto).
    2.  Separa Debitori e Creditori.
    3.  Fai pagare il debitore più grande al creditore più grande finché uno dei due si azzera.
    *   *Nota:* Eseguire separatamente per ogni valuta.

---

## 5. Protocollo di Sincronizzazione

### Logica di Merge (Last-Write-Wins)
Ogni volta che ricevi un dato (da P2P o Server):
1.  Se l'ID non esiste -> Inserisci.
2.  Se l'ID esiste -> Confronta `updated_at`.
3.  Se `Remote.updated_at > Local.updated_at` -> Aggiorna il record locale.

### Sincronizzazione P2P (Nearby)
*   **Topologia:** Star (un "Host" temporaneo e molti "Client").
*   **Handshake:** Il Client invia il proprio `last_sync_timestamp`.
*   **Delta:** L'Host risponde con tutti i record modificati dopo quel timestamp.
*   **Identity Recovery:** Un utente può ripristinare il proprio profilo scansionando un QR code con il proprio UUID e una chiave segreta, permettendo di scaricare i propri dati dal telefono di un amico.

### Sincronizzazione Server (PocketBase)
*   PocketBase funge da "Relay".
*   L'app invia i record con `is_synced = 0`.
*   PocketBase usa il campo `uuid` come chiave di ricerca invece del proprio ID interno.

---

## 6. Sicurezza e Identità
*   **Identità Offline:** Al primo avvio, l'app genera un UUID unico.
*   **Backup Kit:** L'utente deve poter esportare un QR Code "Passaporto". Questo QR contiene l'UUID necessario per essere riconosciuto dagli amici come "proprietario" dei propri debiti/crediti in caso di reinstallazione dell'app.
*   **Privacy:** Su PocketBase, le API Rules devono impedire la lettura di spese di gruppi di cui l'utente non fa parte.

---

## 7. UI/UX Guidelines (Material 3)
*   **Dashboard:** Lista gruppi con saldo totale per valuta (es. "Ti devono 10€ e 500¥").
*   **Transazioni:** Colori distinti per "Hai pagato tu" vs "Ha pagato [Nome]".
*   **Multi-valuta:** Non forzare mai il cambio. Mostra i debiti separati per valuta a meno che l'utente non imposti un tasso manuale.
*   **Semplificazione:** Un toggle chiaro nelle impostazioni del gruppo: "Semplifica debiti". Mostra un diagramma "Prima vs Dopo".

---

## 8. Roadmap di Sviluppo Consigliata

### Fase 1: Fondamenta (Local Only)
- [ ] Setup Drift SQLite con le tabelle sopra descritte.
- [ ] Implementazione delle 5 logiche di splitting in Dart.
- [ ] UI base per creare gruppi e aggiungere spese.

### Fase 2: Gestione Avanzata
- [ ] Logica multi-valuta (bilanci separati).
- [ ] Algoritmo di semplificazione dei debiti.
- [ ] Soft-delete e cronologia modifiche.

### Fase 3: Sincronizzazione P2P
- [ ] Integrazione `nearby_connections`.
- [ ] UI per "Modalità Sync" (Host/Discovery).
- [ ] Logica di merge e risoluzione conflitti.

### Fase 4: Cloud & Backup
- [ ] Setup PocketBase.
- [ ] Login/Signup e sync automatico in background.
- [ ] Gestione immagini scontrini (compressione e upload).

### Fase 5: Rifiniture
- [ ] Esportazione identità via QR Code.
- [ ] Supporto Material You (Colori dinamici).
- [ ] Test di recupero dati offline.

---

**Promemoria:**
> "Il codice deve trattare il server come un accessorio, non come una necessità. Se il database locale è integro, l'utente deve poter fare tutto."


# Smezza: Guida all'Architettura e Sviluppo (Parte 2)

## 1. Identità Crittografica e Sicurezza
L'identità non è un semplice nome utente, ma una coppia di chiavi asimmetriche (**Ed25519**).

*   **Public Key (L'UUID):** La chiave pubblica viene codificata in **Base64URL** (circa 44 caratteri, sicura per database e URL). Questa stringa funge da **ID Univoco** dell'utente in tutto il sistema.
*   **Private Key (La Firma):** Risiede solo nel **Secure Storage** del telefono. Ogni operazione (creazione spesa, ammissione membro) deve essere firmata.
*   **Firma Digitale:** Ogni pacchetto dati include una firma. Chi riceve il dato (amico o server) verifica la firma usando la Public Key dell'autore. Se il dato viene alterato anche di un solo centesimo, la verifica fallisce.

---

## 2. Consistenza dei Dati (Hybrid Logical Clock)
Per evitare conflitti tra modifiche offline senza un server centrale, usiamo l'algoritmo **HLC**.

*   **Formato Stringa:** `timestamp_ms : counter : node_id` (es. `1738933500000:0001:p5bVp...`).
*   **Ordinamento:** Essendo una stringa con padding, il database può ordinarla lessicograficamente.
*   **Last-Write-Wins (LWW):** In fase di sincronizzazione, se ricevo un record con lo stesso UUID:
    *   Se `HLC_remoto > HLC_locale` -> **Aggiorno**.
    *   Se `HLC_remoto <= HLC_locale` -> **Ignoro**.
*   **Drift Correzione:** Se ricevo un HLC dal futuro, il mio orologio locale "salta" in avanti per mantenere la causalità.

---

## 3. PocketBase: Il "Peer" Sempre Online
PocketBase non è il "padrone" dei dati, ma un nodo paritario che funge da specchio e postino.

*   **Autenticazione Ibrida:**
    *   L'utente usa **Email/Password** su PocketBase per il backup e la sicurezza online.
    *   Il server lega l'account Email alla **Public Key** dell'utente.
*   **Validazione Crittografica (Hooks):** PocketBase agisce come un nodo P2P. Tramite **JS/Go Hooks**, verifica la firma dei dati prima di accettarli.
*   **Simmetria ID:** Usiamo l'ID di sistema di PocketBase per contenere i nostri UUID/PublicKeys, garantendo coerenza totale tra SQLite locale e Database remoto.

---

## 4. Gestione Gruppi e Amministratori (Chain of Trust)
L'autorità in un gruppo è distribuita tramite certificati firmati.

*   **Genesi:** Il creatore firma il record di creazione del gruppo (è l'**Owner**).
*   **Ammissione Membri:** Un Admin/Owner genera un record di "Ammissione" che contiene l'UUID dell'amico e lo firma.
*   **Validazione P2P:** Bob accetta dati da Alice solo se possiede il certificato di ammissione di Alice firmato dal creatore del gruppo.

---

## 5. Comunicazione e Notifiche
Niente polling. La comunicazione è basata su eventi (Push/Message).

### Flusso di Notifica "Intelligente":
1.  **App Aperta:** Sottoscrizione **WebSocket** (PocketBase Realtime) per aggiornamenti istantanei.
2.  **App Chiusa:** Il server invia un **Silent Push** (Firebase Cloud Messaging).
3.  **Vicinanza (Offline):** Sincronizzazione via **Mesh Bluetooth** (Nearby Connections).

### De-duplicazione (Anti-Disturbo):
Per evitare notifiche doppie (es. arrivano dati sia da Bluetooth che da Firebase):
*   La notifica viene generata **solo dopo** che il database SQLite ha confermato l'inserimento di un *nuovo* record.
*   Se l'UUID della spesa è già presente (perché arrivato prima via P2P), l'app scarta il segnale Firebase e non mostra nessuna notifica fastidiosa.

---

## 6. Prototipazione e Test (Roadmap Backend)
Lo sviluppo deve procedere "Headless" (senza UI) per validare la robustezza.

1.  **Generazione Chiavi:** Script Python/Dart per creare coppie Ed25519 e derivare l'ID Base64URL.
2.  **Hook PocketBase:** Implementare la logica di confronto HLC nel server per garantire che "il tempo non torni indietro".
3.  **Test di Modifica (Edit):** Verificare che modificando una spesa, la nuova firma e il nuovo HLC vengano accettati dal server e che quelli vecchi vengano rifiutati.
4.  **Simulazione Mesh:** Testare lo scambio di pacchetti JSON firmati tra due istanze del client tester.

