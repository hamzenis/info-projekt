# Installationsanleitung (TradeMate)

# Installation auf den Mac (Chrome Browser):

Diese Installation besitzt schritte für das Installieren unsere TradeMate app im Betriebssystem MacOS in Verwendung mit dem Chrome Browser:

## Grundlagen:

### Verifizieren von ZSH als Shell Standard

Die erste Formalie die man erfüllen sollte, ist, dass sichergegangen wird, dass die Shell Konfiguration im Terminal als Standard “zsh” nutzt.

Die Verifikation vom ganzen wird mit diesem Command sichergestellt:

```shell
dscl . -read ~/ UserShell
```

Wenn folgende Zeile vom Terminal ausgegeben wird, dann kann der nächste Schritt zur Installation von ZSH Ignoriert werden:

```shell
UserShell: /bin/zsh
```

#### Installation von ZSH:

ZSH kann mithilfe von Homebrew Installiert werden, wenn Homebrew noch nicht auf den Mac Installiert ist, kann dies mit folgenden Terminal Command geschehen:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

daraufhin kann dann ZSH wie folgt auf den Terminal Installiert werden:

```shell
brew install zsh
```

#### ZSH als Standard Shell einstellen:

Wenn man ZSH als Standard Shell einstellen möchte, dann erfolgt dies mit dem Befehl im Terminal:

```shell
chsh -s `which zsh`
```

### Installieren von Rosetta (Apple Silicon Chips)

Wenn der Macbook ein Apple Silicon Prozessor besitzt und kein Intel Prozessor wird für Flutter Rosetta benötigt, diese Software wird simple mit folgendem Befehl im Terminal Installiert:

```shell
sudo softwareupdate --install-rosetta --agree-to-license
```

Das Terminal sollte dann am Ende die Bestätigung ausgeben dass Rosetta erfolgreich Installiert wurde.

### Benötigte Entwicklertools

Folgende Anwendungen werden benötigt um TradeMate ohne Probleme starten zu können.

Einmal wird der [Chrome Browser ](https://www.google.com/chrome/dr/download/)benötigt und Git um Problemlos die TradeMate Applikation "clonen" zu können. Um zu schauen ob Git schon im Mac installiert ist, muss man `git version` im Terminal eingebe. Wenn Git nicht installier ist sollte folgender PopUp auftauchen:

![Image.png](https://res.craft.do/user/full/71f5e172-8c0d-33f1-7162-82d4f12c0346/doc/76BC0128-0648-47BD-817C-DACE3C6B3DBD/37B0E486-C861-4ED9-84CB-3FDD5E916DE5_2/0zAGouroHDO2fIwqxaKr087YBzUhkRC5cI7K2hPntvYz/Image.png)

Mit dem Klick auf dem Button “Installieren” und das bestätigen der Lizenzbestimmung wird das Installieren von den Entwickler Tools für den MacBook Installiert, indem auch Git enthalten ist.

Nach der Erfolgreichen Installation sollte mit dem Befehl `git version` jetzt die aktuelle Version von git angezeigt werden.

## Installieren von Flutter SDK

Durch das Installieren von Homebrew im vorherigen [Schritt](https://docs.craft.do/editor/d/71f5e172-8c0d-33f1-7162-82d4f12c0346/76BC0128-0648-47BD-817C-DACE3C6B3DBD/b/9475EEF5-7276-44BC-8EEE-34412F4172CC#BE9B0652-97B9-4EF0-9A04-EFBD419D4A24) kann Flutter mithilfe von Homebrew Installiert werden, falls Homebrew noch nicht Installiert wurde kann dies einfach mit dem Befehl im Terminal passieren:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Installieren von Flutter mit Homebrew:

```shell
brew install --cask flutter
```

Wenn Homebrew als Meldung dass die Installation erfolgreich war, kann man wie folgt die Installation von Flutter mit `flutter doctor` im Terminal kontrollieren ob irgendwelche Problematik noch Offen sind.

Folgende Haken sollten als gesetzt im flutter doctor sein:

```shell
[✓] Flutter
[✓] Chrome
[✓] Network resources
```

## Installation von TradeMate

Um TradeMate installieren zu können muss man wie im [Schritt zur Installation von den nötigen Entwicklertools](https://docs.craft.do/editor/d/71f5e172-8c0d-33f1-7162-82d4f12c0346/76BC0128-0648-47BD-817C-DACE3C6B3DBD/b/9475EEF5-7276-44BC-8EEE-34412F4172CC#2883B081-C72E-4E36-BC58-BAA0ADFE75F6) Git installiert haben.

Um ein Klon vom Git Projekt zu machen und um TradeMate auf dein Lokalen Rechner zu Installieren geht man wie folgt im Terminal vor:

Optional kann entschieden werden in welchen Ordner TradeMate installiert werden soll:

Beispiel:

Im Terminal ein Ordner erstellen und Ihn öffnen mit folgenden Terminal Befehle:

```shell
mkdir TradeMate && cd TradeMate
```

TradeMate wird dann wie folgt von GitHub Runtergeladen:

```shell
git clone https://github.com/hamzenis/info-projekt.git
```

Wenn Git neu installiert wurde, wird gefragt unter welchen Nutzername man in Github angemeldet ist, bitte hierbei den GitHub Nutzername nutzen, der Zugriff auf die Repo von TradeMate hat.

Wenn der Schritt zur Passwortabfrage geschieht, dann sollte man vorher ein “personal access token” auf github generieren, dies geschieht wie folgt: `Setting → Developer settings → personal access token → tokens (classic) → generate new token → Alle Häkchen setzen und den Verfallsdatum auf` “`no expiration`” `setzen → generate token → generierter Token Kopieren und im Terminal einfügen.`

Bei Erfolgreiche Auntentifizierung sollte jetzt das Klonen vom TradeMate Projekt geschehen und auf dem gewünschten Ordner (hier TradeMate) installiert sein.

## Ausführen von TradeMate

Wenn man sich im Terminal im Ordner befindet wo Trademate installiert ist, folgenden Kommandos dann im Terminal einsetzen um TradeMate zu starten:

```shell
cd info-projekt/info_projekt && flutter run -d web-server --web-port 8080
```

> Anmerkung: `flutter run -d web-server --web-port 8080` sorgt dafür dass ein Webserver auf dem Port 8080 im Localhost gestartet wird, dies ist wichtig, weil sonst der Backend Server nicht mit TradeMate kommunizieren kann!

Wenn alles reibungslos Funktioniert hat, sollte folgende Terminal Meldung ausgegeben werden:

```shell
lib/main.dart is being served at http://localhost:8080
The web-server device requires the Dart Debug Chrome extension for debugging. COnsider using the Chrome or Edhe devices for an improved development workflow.

🔥 To hot restart changes while running, press "r" or "R"
for a more detailed help message, press "h". To quit, press "q".
```

Die Website sollte jetzt auf Chrome erreichbar sein unter die URL: [`http://localhost:8080`](http://localhost:8080)

![Image.png](https://res.craft.do/user/full/71f5e172-8c0d-33f1-7162-82d4f12c0346/doc/76BC0128-0648-47BD-817C-DACE3C6B3DBD/5F593782-ECEA-4CC7-8491-64250B6DB8E2_2/TRIsBUWS77C5YP3HRRiMNQe0uO0W2YlnmM2zIRvdG4cz/Image.png)
