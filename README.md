# TradeMate
Ein Projekt für das Modul "Informatik Projekt" an der Frankfurt University of Applied Sciences. <br>
WS 2023/2024 
<br>
Dozentin: **Prof. Dr. Ruth Schorr**

## Dependencies

### Flutter SDK
Zum installieren des Flutter SDKs, folge den Anweisungen auf der [offiziellen Flutter Website](https://flutter.dev/docs/get-started/install).

### Emulator
Für das Laufen auf einem Emulator müssen die entsprechenden Emulatoren installiert werden.

 Android Studio wird benötigt für den Android Emulator. Folge den Anweisungen auf der [offiziellen Android Studio Website](https://flutter.dev/docs/get-started/install).

IOS Geräte können nur auf MacOS emuliert werden. Für einen IOS Emulator folge den Anweisungen auf der [offiziellen Flutter Website](https://flutter.dev/docs/get-started/install/macos#set-up-the-ios-simulator).


## Installation

### Klonen des Repositories

```bash
git clone https://github.com/hamzenis/info-projekt.git
cd info_projekt
```

### Get flutter packages

```bash
flutter pub get
```


## Get Started

### Web
Zum starten der Anwendung in einem Webbrowser:
```bash
flutter run -d web-server --web-port 8080
```
Öffne nun einen Browser und gehe auf [http://localhost:8080](http://localhost:8080).

### Android & IOS Emulator
Zum starten der Anwendung auf einem Android Gerät:
```bash
flutter devices # Zeigt alle verfügbaren Geräte an
# Wähle ein Geräte aus und kopiere die DeviceId
flutter run -d <deviceId>
```


## Support

Bei Fragen oder Problemen, kontaktiere uns unter:
- [Hamzenis Kryeziu](mailto:hamzenis.kryeziu@stud.fra-uas.de)
- [Dominique Conceicao Rosario](mailto:dominique.conceicaorosario@stud.fra-uas.de)
- [Jaqueline Brossart](mailto:jaqueline.brossart@stud.fra-uas.de)
- [Ebrahim Al Numayri](mailto:ebrahim.alnumayri@stud.fra-uas.de)