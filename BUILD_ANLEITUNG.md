# City Memory - Build Anleitung

## Ordnerstruktur einrichten

Dein Projekt sollte so aussehen:

```
city_memory/
├── src/                    ← Dein Original-Code (wird NICHT gepusht)
│   ├── server/
│   │   ├── main.lua
│   │   ├── pg.lua
│   │   ├── sv_decay.lua
│   │   ├── sv_dispatch.lua
│   │   ├── sv_mdt.lua
│   │   ├── sv_police.lua
│   │   ├── sv_profiles.lua
│   │   ├── sv_vehicles.lua
│   │   └── sv_zones.lua
│   ├── client/
│   │   ├── cl_dispatch.lua
│   │   ├── cl_effects.lua
│   │   ├── cl_feedback.lua
│   │   ├── cl_menu.lua
│   │   ├── cl_mdt.lua
│   │   ├── cl_target.lua
│   │   └── cl_zonemap.lua
│   ├── shared/
│   │   ├── config.lua
│   │   ├── utils.lua
│   │   └── zones.lua
│   ├── html/
│   │   ├── index.html
│   │   ├── css/
│   │   └── js/
│   ├── sql/
│   │   └── schema.sql
│   └── fxmanifest.lua
│
├── dist/                   ← Obfuscated Code (wird gepusht)
│   └── (wird vom build script erstellt)
│
├── build.js                ← Build Script (NICHT pushen)
├── .gitignore
├── LICENSE
└── README.md
```

## Schritt 1: Ordner umstrukturieren

```bash
# Im Terminal, im city_memory Ordner:

# Neuen src Ordner erstellen
mkdir src

# Alles in src verschieben
mv server src/
mv client src/
mv shared src/
mv html src/
mv sql src/
mv fxmanifest.lua src/
```

## Schritt 2: API Key setzen

Öffne `build.js` und ersetze:
```javascript
apiKey: process.env.LURAPH_API_KEY || 'DEIN_API_KEY_HIER',
```

Mit deinem echten Key:
```javascript
apiKey: process.env.LURAPH_API_KEY || 'c9f669aa7afa...',
```

ODER setze eine Umgebungsvariable:
```bash
export LURAPH_API_KEY="dein_key_hier"
```

## Schritt 3: Build ausführen

```bash
# Node.js muss installiert sein
node build.js
```

Das Script:
1. Liest alle Lua-Dateien aus `src/`
2. Schickt sie an Luraph API
3. Speichert obfuscated Version in `dist/`
4. Kopiert config.lua, html, sql unverändert

## Schritt 4: Git pushen

```bash
# dist Ordner ist jetzt bereit
git add dist/
git add .gitignore
git add LICENSE
git add README.md
git commit -m "Release v2.4.0"
git push
```

## Wichtig!

- `src/` wird durch .gitignore NICHT gepusht
- `build.js` wird NICHT gepusht (enthält API Key)
- Nur `dist/` ist public

## Bei Updates

1. Ändere Code in `src/`
2. Führe `node build.js` aus
3. Push `dist/`

```bash
node build.js
git add dist/
git commit -m "Update v2.4.1"
git push
```
