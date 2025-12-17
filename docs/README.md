# City Memory — Persistentes Stadtgedächtnis, Dispatch & MDT für ESX

Ein modulares FiveM‑System, das Stadtzonen, Spieler‑ und Fahrzeughistorien sowie Notrufe (Dispatch) und ein MDT (Mobile Data Terminal) zentral verbindet. Entwickelt für ESX, mit moderner NUI (HTML/CSS/JS), optionalem Radial‑Menü (ox_lib) und Interaktionen über ox_target.

Aktuelle Version der Resource: 2.1.0 (siehe `fxmanifest.lua`)
Heatmap‑Modul: v2.2 (Client‑Hinweis in `cl_zonemap.lua`)

—

## Inhalt
- Überblick & Features
- Voraussetzungen
- Installation & Update
- Datenbank (Neon PostgreSQL)
- Konfiguration (`shared/config.lua`)
- Befehle, Keybinds & Menüs
- Nutzung: Dispatch, MDT, Heatmap, ox_target
- Admin‑Dashboard
- API (Exports & Events)
- ConVars (Datenbank‑Verbindung)
- Performance & Sicherheit
- Troubleshooting & FAQ
- Changelog (Kurz)
- Lizenz & Credits

---

## Überblick & Features

- Zonen‑Speicher (Heat/Risk) mit Decay und Ereignis‑Tracking
- Dispatch‑System mit Bürger‑Notruf, Leitstellen‑UI, Einheiten‑Übersicht, Backup‑Anforderung, Wegpunkte
- MDT für Polizei: Fahndungen, Profile, Fahrzeug‑Historie, Statistiken
- Admin‑Dashboard: Live‑Statistiken, Logs, Datenexport/Reset (optional)
- Zonen‑Heatmap mit Radius‑Blips, Auto‑Aktivierung für Polizei, Legende
- Persistente Spielerprofile inkl. Reputation und Risk‑Level
- Fahrzeug‑Historie und Risiko‑Berechnung
- Radial‑Menü (ox_lib) als zentraler Einstiegspunkt
- ox_target‑Interaktionen an Welt‑Objekten (Polizei‑Computer, Leitstelle, Telefone)
- Saubere Modul‑Trennung (client/server/shared) und klar konfigurierbar

Dateien/Module (Auszug):
- Client: `client/cl_menu.lua`, `cl_dispatch.lua`, `cl_mdt.lua`, `cl_zonemap.lua`, `cl_target.lua`, `cl_effects.lua`, `cl_feedback.lua`
- Server: `server/pg.lua`, `main.lua`, `sv_zones.lua`, `sv_profiles.lua`, `sv_vehicles.lua`, `sv_police.lua`, `sv_dispatch.lua`, `sv_mdt.lua`, `sv_decay.lua`
- Shared: `shared/config.lua`, `shared/utils.lua`, `shared/zones.lua`
- NUI: `html/index.html`, `html/css/*.css`, `html/js/*.js`
- SQL: `sql/schema.sql`

---

## Voraussetzungen
- FiveM Artifact (cerulean)
- ESX (es_extended)
- ox_lib (für Radial‑Menü, Notifications)
- ox_target (optional, empfohlen – Welt‑Interaktionen)
- PostgreSQL (empfohlen: Neon Serverless)

Alle Dependencies sind im `fxmanifest.lua` hinterlegt.

---

## Installation & Update

1) Resource in den `resources`‑Ordner legen: `resources/[city]/city_memory`
2) In der `server.cfg` unter Dependencies laden, z. B. nach ESX/ox_lib/ox_target.
3) Datenbank konfigurieren (siehe ConVars unten) und Schema ausführen:
   - Entweder den Inhalt von `sql/schema.sql` in Neon/PSQL ausführen
   - Oder, falls die Resource Tabellen selbst anlegt, Logs prüfen (empfohlen: Schema einmalig manuell ausführen)
4) Server starten und Konsole beobachten. Bei Erfolg erscheint u. a.:
   - `[City Memory PG] Connection via ...`
   - `Heatmap System v2.2 geladen` (Client)
5) Update: Dateien ersetzen, Changelog beachten, ggf. neue Config‑Keys ergänzen (Diff prüfen).

---

## Datenbank (Neon/PostgreSQL)

- Serverseitiger Connector: `server/pg.lua` (HTTP‑API von Neon, keine externen Libs)
- Verbindung per ConVars (siehe Abschnitt „ConVars“)
- Tabellen/Indizes siehe `sql/schema.sql`

Hinweise:
- Event‑ und Kontextdaten nutzen `JSONB` (saubere Kodierung via `json.encode`)
- Fremdschlüssel sichern Referenzdaten (Spielerprofile/Fahrzeuge)
- Decay‑Jobs laufen serverseitig (`sv_decay.lua`)

---

## Konfiguration (shared/config.lua)

Wichtige Blöcke (Auszug):

- Debug & Logging
  - `Config.Debug = true|false`
  - `Config.PersistentLogs = true|false`

- Menü (ox_lib / ox_target)
  - `Config.Menu.useRadialMenu = true`
  - `Config.Menu.useOxTarget = true`
  - `Config.Menu.enableKeybind = false` (optional Keybind für Hauptmenü, Standard `F5` wenn aktiviert)

- Jobs & Berechtigungen
  - `Config.Jobs.police`, `Config.Jobs.ems`, `Config.Jobs.admin`
  - `Config.MinGrades` (z. B. `markVehicle`, `viewFullProfile`, `closeOthersCalls`)

- Notruf‑Kategorien
  - `Config.Categories[...]` mit `label`, `priority`, `icon`, Sichtbarkeit (`police/ems`) und `heatModifier`

- Dispatch
  - `Config.Dispatch.callTimeout`, `maxActiveCalls`, `autoDeleteCompleted`, `notifyOnNewCall`, `autoSetWaypoint`

- MDT
  - `Config.MDT.enabled`, `searchCooldown`, `maxSearchResults`, `showPlayerPhotos`, `allowNotesEdit`

- Zonen & Heat/Decay
  - `Config.ZoneHeat` (Grenzwerte, Decay‑Raten, Schwellen)
  - `Config.EventCooldowns`, `Config.HeatModifiers`

- Heatmap (Zonen‑Visualisierung)
  - `Config.ZoneHeatmap.enabled`, `copMin`, `civMin`, `radius`, `interval`, `requestCooldownMs`, `enableForCivilians`, `autoEnableForCivilians`, `pruneGraceMs`

- Spielerprofil & Reputation
  - `Config.PlayerProfile`, `Config.ReputationModifiers`, `Config.RiskLevels`

- Admin
  - `Config.Admin.enabled`, `refreshInterval`, `maxLogEntries`, `allowDataExport`, `allowDataReset`

- UI‑Farben & Sounds
  - `Config.UI.*`, `Config.Sounds.*`

- ox_target Orte (Computer, Leitstelle, Telefone): `Config.TargetLocations`

Tipp: Lies die Datei `shared/config.lua` einmal komplett — viele Optionen sind selbsterklärend dokumentiert.

---

## Befehle, Keybinds & Menüs

- Commands (immer verfügbar, sofern Feature aktiv):
  - `/citymemory` oder `/cm` — Hauptmenü
  - `/notruf` — Bürger‑Notruf öffnen
  - `/dispatch` — Leitstelle öffnen (nur Dispatcher‑Jobs)
  - `/mdt` — MDT öffnen (nur Polizei)
  - `/heatmap` — Zonen‑Heatmap toggeln
  - `/cityadmin` — Admin‑Dashboard (Admin‑Gruppe)

- Radial‑Menü (ox_lib):
  - Ein zentraler Eintrag „Notruf 911“ oder „Leitstelle“ je nach Job (`cl_menu.lua`)
  - Öffnet Untermenüs: Notruf, Dispatch, MDT, Heatmap, Admin

- Keybinds:
  - Historische Keybinds sind als Fallback in `Config.Keys` vorhanden, aber bei `useRadialMenu = true` deaktiviert
  - Optionales Hauptmenü‑Keybind: aktiviere `Config.Menu.enableKeybind`

---

## Persistente Spielerprofile: Reputation & Risk‑Level

Spielerprofile werden serverseitig in der Datenbank persistiert und kontinuierlich aktualisiert. Sie bilden die Grundlage für polizeiliche Einschätzungen, das MDT und bestimmte Spielmechaniken.

- Speicherung: `server/sv_profiles.lua` (Profile & Events), Daten liegen in Tabellen gemäß `sql/schema.sql`.
- Lebenszyklus: Profile werden beim ersten relevanten Event automatisch angelegt.
- Zugriff: MDT, Admin‑Dashboard und Server‑Exports (siehe API‑Abschnitt).

### Begriffe
- Reputation (0.0–1.0): Laufende Einschätzung des Verhaltens eines Spielers. 1.0 = vorbildlich, 0.0 = sehr problematisch.
- Risk‑Score (abgeleitet): Wird aus Reputation und letzten Ereignissen hergeleitet, in Stufen (hoch/mittel/niedrig) klassifiziert.

### Initialwerte & Grenzen
- Startwert: `Config.PlayerProfile.defaultReputation` (Default 0.5)
- Grenzen: `minReputation`/`maxReputation` (0.0–1.0)

### Aktualisierung der Reputation
Reputation ändert sich durch Ereignisse und passives Decay:

- Ereignisse: Jedes registrierte Event hat einen Modifier (`Config.ReputationModifiers`). Beispiele:
  - `flee_police = -0.08`
  - `weapon_vs_player = -0.10`
  - `cooperate = +0.03`
  - `surrender = +0.05`
- Server ruft bei Vorkommnissen z. B. `RegisterPlayerEvent(identifier, eventType, impact?, context?)` auf:
  - `impact` (optional) kann zusätzliche Gewichtung sein; fehlt er, nutzt der Server den vordefinierten Modifier.
  - `context` wird als `JSONB` gespeichert (Beweise, Orte, Beteiligte).
- Passives Decay/Erholung: In regelmäßigen Intervallen wird Reputation leicht Richtung neutral/positiv angepasst, konfiguriert über `Config.PlayerProfile.decayRate`.

Pseudologik (vereinfacht):
```
newRep = clamp(oldRep + modifier + impact, minReputation, maxReputation)
// Zusätzlich periodische kleine Erholung: +decayRate
```

### Risk‑Level
Aus Reputation wird ein einfaches Risikoniveau abgeleitet. Schwellen:

- `Config.RiskLevels.high` (Default 0.30): Darunter gilt der Spieler als „High‑Risk“.
- `Config.RiskLevels.medium` (Default 0.45): Darunter, aber über „high“, gilt „Medium“.
- Alles darüber: „Low“/„Normal“.

Exports (Server):
- `GetPlayerProfile(identifier)` → vollständige Profildaten
- `GetRiskLevel(identifier)` → `"high"|"medium"|"low"`
- `IsHighRisk(identifier)` → bool
- `RegisterPlayerEvent(identifier, eventType, impact?, context?)`

Hinweis: Fahrzeuge besitzen analoge Konzepte in `server/sv_vehicles.lua` (Historie, Flagging, Risiko), die im MDT sichtbar sind.

---

## Nutzung im Spiel

### Notruf & Dispatch
- Bürger öffnen das Notruf‑UI über Menü oder `/notruf`
- Leitstellen‑Mitarbeiter öffnen die Dispatch‑UI (`/dispatch` oder Menü)
- Features: Anrufe annehmen/abschließen, Einheiten zuweisen, Backup anfordern, automatischer Wegpunkt (konfigurierbar)
- Dateien: `client/cl_dispatch.lua`, `server/sv_dispatch.lua`, NUI `html/js/dispatch.js`

### MDT (Polizei)
- Zugriff über Menü oder `/mdt` (nur Polizei)
- Features: Fahndungsliste, Spieler‑/Fahrzeugsuche, Profile, Notizen, Statistiken
- Dateien: `client/cl_mdt.lua`, `server/sv_mdt.lua`, `server/sv_profiles.lua`, `server/sv_vehicles.lua`, NUI `html/js/mdt.js`

### Heatmap (Zonen)
- Persistente Blips: Zonen‑Blips bleiben bestehen und werden in‑place aktualisiert (kein Flackern)
- Pruning: Zonen, die nicht mehr gemeldet werden, werden nach Gnadenfrist entfernt (Default 60s)
- Auto‑Aktivierung für Polizei bei Dienstantritt
- Zivilisten optional via `/heatmap` (konfigurierbar) und optional auto‑aktivierbar
- Farben: Grün < 0.4, Orange ≥ 0.4, Rot ≥ 0.7; Transparenz skaliert mit Heat
- Intervall standardmäßig 30s; Serverseitiges Rate‑Limit 5s pro Spieler
- Dateien: `client/cl_zonemap.lua`, `server/sv_zones.lua`, NUI `html/js/heatmap.js`

### ox_target Interaktionen
- Computer (MDT/Dispatch), Leitstellentische, Telefone — Standorte in `Config.TargetLocations`
- Dateien: `client/cl_target.lua`

---

## Admin‑Dashboard
- Aktivierung über `Config.Admin.enabled = true`
- Öffnen via Menü oder `/cityadmin` (Benutzergruppe: `admin`/`superadmin`)
- Features: Live‑Statistiken, Logs, Anruf‑Übersicht, optionaler Datenexport/Reset
- Dateien: `client/cl_mdt.lua` (Admin‑Teil), `server/sv_mdt.lua`, `server/sv_dispatch.lua`

---

## API (Exports & Events)

Auszug relevanter Exports:

Client‑Exports
- Dispatch (`client/cl_dispatch.lua`):
  - `OpenCallUI()`, `OpenDispatchUI()`, `CloseAllUI()`
  - `IsDispatchOpen() -> bool`, `IsCallUIOpen() -> bool`
- MDT/Admin (`client/cl_mdt.lua`):
  - `OpenMDT()`, `OpenAdminDashboard()`, `CloseMDT()`, `CloseAdmin()`
  - `IsMDTOpen() -> bool`, `IsAdminOpen() -> bool`
- Heatmap (`client/cl_zonemap.lua`):
  - `IsHeatmapActive() -> bool`, `SetHeatmapActive(state: bool)`
  - `ToggleHeatmap()`, `ClearHeatmap()`, `RefreshHeatmap()`

Server‑Exports
- Profile (`server/sv_profiles.lua`):
  - `GetPlayerProfile(identifier)`, `GetRiskLevel(identifier)`, `IsHighRisk(identifier)`
  - `RegisterPlayerEvent(identifier, eventType, impact, context)`
- Fahrzeuge (`server/sv_vehicles.lua`):
  - `GetVehicleHistory(plate)`, `IsVehicleFlagged(plate)`, `GetVehicleRiskLevel(plate)`
  - `RegisterVehicleEvent(plate, eventType, context)`
- Zonen (`server/sv_zones.lua`):
  - `GetZoneHeat(zoneId)`, `GetHotZones(minHeat)`, `GetZoneFromCoords(vec3)`
  - `RegisterZoneEvent(zoneId, eventType, severity, sourceIdentifier)`
- Dispatch (`server/sv_dispatch.lua`):
  - `GetActiveCalls()`

Events (Auszug)
- Client→Server: `city_memory:requestZoneHeat` (Heatmap)
- Server→Client: `city_memory:receiveZoneHeat` (Heatmap‑Daten), `city_memory:clearHeatmap`
- UI‑Events (NUI) siehe `html/js/*.js` und die `RegisterNUICallback`‑Blöcke in den Client‑Skripten

Hinweis: Interne Hilfsfunktionen wie `IsPoliceJob`, `IsEMSJob`, `IsDispatcherJob` kommen aus den Shared‑Utils/Config.

---

## ConVars (DB‑Verbindung)

Option 1 — Einzelne Werte:
```
set city_memory_pg_host "ep-xxxxx.eu-central-1.aws.neon.tech"
set city_memory_pg_port "5432"
set city_memory_pg_database "city_memory"
set city_memory_pg_user "dein_user"
set city_memory_pg_password "dein_passwort"
```

Option 2 — Connection String:
```
set city_memory_pg_connection "postgresql://user:pass@host/database?sslmode=require"
```

Fallback (Legacy):
```
set pg_connection_string "postgresql://user:pass@host/database?sslmode=require"
```

Bei Start validiert `server/pg.lua` die Verbindung und gibt den gewählten Modus in der Konsole aus.

---

## Performance & Sicherheit

- Heatmap: Persistente Blips mit Pruning (Default Gnadenfrist 60s). Intervall/Radius sinnvoll wählen; bei sehr vielen Spielern Intervall eher erhöhen.
- Server‑Cooldowns für Requests verhindern Spam
- `Config.Debug` nur in Entwicklung aktivieren (mehr Logs)
- Zugriffsrechte über ESX‑Jobs und `Config.MinGrades` steuern
- Admin‑Funktionen nur für `admin`/`superadmin`

---

## Troubleshooting & FAQ

Neon HTTP 400 bei SQL‑Requests
- Ursache oft fehlerhafte SQL oder Constraint‑Verstoß
- Aktiviere `Config.Debug = true` → Query + Response werden gekürzt geloggt
- Häufige Ursachen:
  - Fremdschlüsselverletzung `player_events.identifier` → Profil existiert noch nicht; wird beim nächsten Event automatisch angelegt (ab 2.0.0+) oder manuell erstellen
  - `event_type` zu lang/ungültig (max 30, Normalisierung `[a-z0-9_-]`)
  - Ungültiges JSON in `context` → wird als `JSONB` gespeichert; bei `nil` `NULL::jsonb`

Heatmap zeigt nichts
- `Config.ZoneHeatmap.enabled = true`?
- Als Zivilist gelten `civMin`‑Schwellen (Default 0.50)
- Server‑Cooldown (Default 5s) abwarten, Intervall 30s beachten

MDT/Dispatch öffnen nicht
- Job/Berechtigung korrekt? (Dispatcher/Polizei)
- ox_lib/ox_target korrekt geladen?
- NUI blockiert? Fokus via ESC schließen

---

## Changelog (Kurz)

2.2 (Heatmap‑Modul)
- Auto‑Aktivierung für Polizei, Onboarding‑Hinweis, Legende
- Verbesserte Farb/Alpha‑Skalierung und Exports

2.1.0 (Resource)
- Neues Radial‑Menü (`cl_menu.lua`)
- ox_target‑Interaktionen (`cl_target.lua`)
- Überarbeitetes Dispatch/MDT, Admin‑Erweiterungen
- Verbesserte DB‑Schicht (Neon, HTTP), Decay/Modifiers

---

## Lizenz & Credits

- Autor: Andreas Konopka
- Abhängigkeiten: es_extended, ox_lib, ox_target
- Lizenz: Nutzung gemäß Server‑Richtlinien; prüfe ggf. interne Vorgaben. Externe Bibliotheken unter deren jeweiliger Lizenz.

Beiträge, Issues und Vorschläge sind willkommen.
