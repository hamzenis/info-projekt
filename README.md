# TradeMate

Ein Projekt für das Modul "Informatik Projekt" an der Frankfurt University of Applied Sciences.\\
WS 2023/2024\\
Dozentin: Prof. Dr. Ruth Schorr

## Installation auf Mac (Chrome Browser)

Diese Installation erläutert die Schritte für das Installieren der TradeMate-Applikation im Betriebssystem MacOS unter Verwendung des Chrome Browsers.

### Grundlagen

#### Verifizieren von ZSH als Shell Standard

Zuerst muss sichergestellt werden, dass die Shell-Konfiguration im Terminal als Standard ZSH nutzt.

Hierzu den folgenden Command in das Terminal eingeben:

```shell
dscl . -read ~/ UserShell
```

Wenn folgende Zeile vom Terminal ausgegeben wird, kann der folgende Schritt zur Installation von ZSH ignoriert werden:

```shell
UserShell: /bin/zsh
```

#### Installation von ZSH

ZSH kann mithilfe von Homebrew installiert werden.
Falls Homebrew noch nicht auf dem Mac installiert ist, kann dies mit folgendem Terminal Command geschehen:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Daraufhin kann ZSH mit dem folgenden Terminal Command installiert werden:

```shell
brew install zsh
```

#### ZSH als Standard Shell einstellen

Möchte man ZSH als Standard Shell einstellen, geht das über den folgenden Terminal Command:

```shell
chsh -s `which zsh`
```

#### Installieren von Rosetta (Apple Silicon Chips)

Besitzt das Macbook anstelle eines Intel-Prozessors einen Apple Silicon-Prozessor, wird für Flutter "Rosetta" benötigt.
Rosetta wird mit folgendem Befehl im Terminal installiert:

```shell
sudo softwareupdate --install-rosetta --agree-to-license
```

Das Terminal sollte eine Bestätigung ausgeben, dass Rosetta erfolgreich installiert wurde.

#### Benötigte Entwicklertools

Folgende Anwendungen werden benötigt, um TradeMate starten zu können:

1. [Chrome Browser ](https://www.google.com/chrome/dr/download/)
2. Git (zum Klonen der TradeMate-Applikation)

Ob Git installiert ist oder nicht, kann über `git version` im Terminal überprüft werden.
Ist Git nicht installiert, informiert ein Popup darüber:

![Image.png](https://res.craft.do/user/full/71f5e172-8c0d-33f1-7162-82d4f12c0346/doc/76BC0128-0648-47BD-817C-DACE3C6B3DBD/37B0E486-C861-4ED9-84CB-3FDD5E916DE5_2/0zAGouroHDO2fIwqxaKr087YBzUhkRC5cI7K2hPntvYz/Image.png)

Mit einem Klick auf den Button “Installieren” und dem Bestätigen der Lizenzbestimmungen wird die Installation der Developer Tools, die Git enthalten, zugestimmt.

Nach erfolgreicher Installation wird mit dem Befehl `git version` die aktuelle Version von Git angezeigt.

## Installieren der Flutter SDK

Falls Homebrew noch nicht installiert wurde, kann die Installation mit folgendem Befehl im Terminal durchgeführt werden:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Installieren von Flutter mit Homebrew:

```shell
brew install --cask flutter
```

Meldet Homebrew, dass die Installation erfolgreich war, kann der Installationsstatus von Flutter und den benötigten Komponenten mit der Eingabe von `flutter doctor` im Terminal abgerufen werden.

Folgende Haken sollten gesetzt sein:

```shell
[✓] Flutter
[✓] Chrome
[✓] Network resources
```

## Installation von TradeMate

Die Installation von TradeMate erfordert Git.
Um Trademate auf einem lokalen Rechner zu installieren, geht man wie folgt vor:

Erstellen und öffnen eines neuen Ordners (hier namens "TradeMate"):

```shell
mkdir TradeMate && cd TradeMate
```

Herunterladen des Projekts von Github:

```shell
git clone https://github.com/hamzenis/info-projekt.git
```

Wurde Git neu installiert, ist ein erstmaliges Einloggen erforderlich. Hierzu bitte die Emailadresse nutzen, der durch das TradeMate-Team Zugriff auf das TradeMate-Repository gewährt wurde.

Anstelle eines Passworts wird ein sogenannter "Personal Access Token" benötigt. Dieser kann auf Github wie folgt generiert werden:
`Setting → Developer settings → personal access token → tokens (classic) → generate new token → Alle Häkchen setzen und das Verfallsdatum auf` “`no expiration`” `setzen → generate token → generierten Token kopieren und im Terminal einfügen`

War die Authentifizierung erfolgreich, wird der TradeMate-Klon im gewünschten Ordner installiert.

## Ausführen von TradeMate

Zum Ausführen der Applikation innerhalb des Ordners, in dem TradeMate installiert wurde, das Terminal öffnen und folgendes Kommando eingeben:

```shell
cd info-projekt/info_projekt && flutter run -d web-server --web-port 8080
```

> Anmerkung: `flutter run -d web-server --web-port 8080` sorgt dafür, dass ein Webserver auf dem Port 8080 im Localhost gestartet wird. Wird ein anderer Port gewählt, kann der Backend-Server nicht korrekt mit TradeMate kommunizieren!

Sofern alles funktioniert hat, sollte folgende Terminal-Meldung ausgegeben werden:

```shell
lib/main.dart is being served at http://localhost:8080
The web-server device requires the Dart Debug Chrome extension for debugging. COnsider using the Chrome or Edhe devices for an improved development workflow.

🔥 To hot restart changes while running, press "r" or "R"
for a more detailed help message, press "h". To quit, press "q".
```

Die Website ist auf Chrome erreichbar unter der URL: [`http://localhost:8080`](http://localhost:8080)

![Image.png](https://res.craft.do/user/full/71f5e172-8c0d-33f1-7162-82d4f12c0346/doc/76BC0128-0648-47BD-817C-DACE3C6B3DBD/5F593782-ECEA-4CC7-8491-64250B6DB8E2_2/TRIsBUWS77C5YP3HRRiMNQe0uO0W2YlnmM2zIRvdG4cz/Image.png)

## Support

Bei Fragen oder Problemen, kontaktiere uns unter:

- [Hamzenis Kryeziu](mailto:hamzenis.kryeziu@stud.fra-uas.de)
- [Dominique Conceicao Rosario](mailto:dominique.conceicaorosario@stud.fra-uas.de)
- [Jaqueline Brossart](mailto:jaqueline.brossart@stud.fra-uas.de)
- [Ebrahim Al Numayri](mailto:ebrahim.alnumayri@stud.fra-uas.de)
