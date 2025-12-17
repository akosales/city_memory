# City Memory System

(See existing documentation above...)

## Troubleshooting: Neon HTTP 400 bei SQL-Requests

Wenn in der Serverkonsole Meldungen wie „[City Memory PG] HTTP Error 400“ erscheinen, liegt meistens ein Fehler in der ausgeführten SQL-Anweisung oder bei Constraints im Schema vor. So gehst du vor:

1) Fehlermeldung vollständig lesen
- Aktiviere Debug (in `shared/config.lua`: `Config.Debug = true`).
- Der Connector protokolliert dann die gekürzte, final interpolierte SQL-Query und den Response-Body (erste ~2 kB). Daraus lässt sich meist eine genaue Ursache ablesen (z. B. „violates foreign key constraint“ oder „value too long for type“).

2) Häufige Ursachen und Lösungen
- Fremdschlüsselverletzung in `player_events.identifier` → Stelle sicher, dass es in `player_profiles` bereits einen Datensatz mit dieser `identifier` gibt. Das Script legt Profile bei Bedarf automatisch an (ab Version 2.0.0+ via `EnsurePlayerProfile`).
- `event_type` zu lang oder mit ungültigen Zeichen → Es sind max. 30 Zeichen erlaubt (`VARCHAR(30)`). Seit 2.0.0+ wird der Event-Typ normalisiert (`[a-z0-9_-]`) und auf 30 Zeichen gekürzt.
- Ungültiges JSON in `context` → Das Feld ist `JSONB`. Ab 2.0.0+ wird `context` stets mit `json.encode` kodiert und als `?::jsonb` eingefügt. Bei `nil` wird `NULL::jsonb` verwendet.

3) Weitere Tipps
- Prüfe, ob die `server.cfg` korrekt konfiguriert ist (ConVars `city_memory_pg_*` oder `city_memory_pg_connection`/`pg_connection_string`).
- Nutze NeonDBs SQL-Editor, um das Schema (`sql/schema.sql`) erneut auszuführen, falls Tabellen/Indizes fehlen sollten.

4) Beispiel-Logs (gekürzt)
```
[City Memory PG] HTTP Error 400
Query: INSERT INTO player_events (identifier, event_type, impact, context) VALUES ('char1:...','weapon_vs_npc',-0.03,NULL::jsonb)
Response: {"error":"insert or update on table \"player_events\" violates foreign key constraint"}
```
Lösung: Profil anlegen lassen (passiert automatisch beim nächsten Event), oder manuell einen Eintrag in `player_profiles` erstellen.

## Feature: Zonen‑Heatmap (Heat‑Blips) auf der Karte

Mit der Heatmap werden die aktuellen Heat‑Werte der Stadtzonen direkt auf der Karte visualisiert. Polizei sieht damit auf einen Blick Hotspots, Zivilisten (optional) nur starke Hotspots.

### Was macht das Feature?
- Erstellt farbige Radius‑Blips pro Zone (Größe konfigurierbar)
- Farbe abhängig vom Heat:
  - Grün (< 0.4), Orange (≥ 0.4), Rot (≥ 0.7)
- Transparenz skaliert mit Heat (Alpha ~40–220)
- Automatisches Refresh im Intervall (Standard 30 s)
- Serverseitiger Filter: Polizei/Zivilisten sehen unterschiedliche Schwellen
- Serverseitiges Rate‑Limit pro Spieler (Default 5 s)

### Dateien
- Client: `client/cl_zonemap.lua`
- Server: `server/sv_zones.lua` (liefert Zone‑Heat via Event)
- Config: `shared/config.lua` → Block `Config.ZoneHeatmap`
- Zonen: `shared/zones.lua` (liefert `coords`/`center` + `radius`)
- Manifest: `fxmanifest.lua` bindet `client/cl_zonemap.lua` ein

### Nutzung im Spiel
- Toggle per Tastendruck: F8
- Oder als Command: `/heatmap`
- Polizei: sieht Zonen mit Heat ≥ 0.10 (Default)
- Zivilisten: sehen Zonen mit Heat ≥ 0.50 (Default)

### Konfiguration
In `shared/config.lua`:

```lua
Config.ZoneHeatmap = {
    enabled = true,           -- Feature aktivieren/deaktivieren
    copMin = 0.10,            -- Mindest‑Heat für Polizei
    civMin = 0.50,            -- Mindest‑Heat für Zivilisten
    radius = 150.0,           -- Blip‑Radius (Meter)
    interval = 30000,         -- Client‑Updateintervall (ms)
    requestCooldownMs = 5000, -- Serverseitiges Rate‑Limit (ms)
    maxZones = 80             -- Reserve/Limit (derzeit rein informativ)
}
```

Optional kannst du in `shared/zones.lua` pro Zone ein eigenes `center` setzen. Wenn `center` fehlt, wird `coords` verwendet.

### Rechte / Sichtbarkeit
- Der Server ermittelt anhand des ESX‑Jobs (siehe `Config.Jobs`) automatisch, ob der Spieler Polizist ist und wendet `copMin` oder `civMin` an.
- Es gibt keine gesonderte ACL: Die Sichtbarkeit ist rein über Job/Ziel‑Schwellen geregelt.

### Performance‑Hinweise
- Blips werden vor jedem Update bereinigt und neu gesetzt.
- Server hat pro Spieler ein Request‑Cooldown (Default 5 s).
- Standard‑Intervall 30 s ist für City‑Größe ausreichend. Bei sehr vielen Zonen/Spielern kann das Intervall erhöht werden.

### Datenbank
- Es sind keine Schema‑Änderungen erforderlich. Die Heatmap nutzt die bestehenden Heat‑Werte aus `zone_memory`.
- Bei Erstinstallation stelle sicher, dass das Schema `sql/schema.sql` einmalig ausgeführt wurde (oder die Resource die Tabellen bereits angelegt/gefüllt hat).

### Troubleshooting
- Heatmap zeigt keine Blips:
  - Prüfe, ob `Config.ZoneHeatmap.enabled = true` ist.
  - Als Zivilist erscheinen nur Zonen mit Heat ≥ `civMin` (Default 0.50). Teste als Polizei oder senke den Schwellenwert testweise.
  - Prüfe Server‑Konsole auf Rate‑Limit: Wenn du zu schnell togglest, kann die Antwort verzögert sein (Cooldown).
- „HTTP Error 400“ in Logs: hat mit der Heatmap nichts zu tun; siehe Abschnitt „Neon HTTP 400 bei SQL‑Requests“ oben.

### Erweiterungen (optional)
- Blip‑Icons für extreme Hotspots (statt Radius)
- Pulsierende Blips ab Heat ≥ 0.8
- NUI‑Legende mit Heat‑Skala
- 3D‑Marker in der Welt für höchste Heat‑Zonen
