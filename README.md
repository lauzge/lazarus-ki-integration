Lazarus AI Assistant v1.2 🚀
Ein leistungsstarkes Open-Source-Plugin für die Lazarus IDE, das KI-Unterstützung (LLMs) direkt in deinen Workflow integriert. Entwickelt für Lazarus 4.6+ unter Linux, aber auch kompatibel mit Windows.
Jetzt mit voller Icon-Unterstützung und Andock-Funktion!
✨ Features

    Andockbares Chat-Fenster: Integriert sich nahtlos über das AnchorDocking-System in dein IDE-Layout.
    Multi-KI Support: Nutze lokale Modelle via Ollama oder LM Studio sowie Cloud-Dienste wie OpenAI (ChatGPT).
    Intelligente Code-Übernahme: Erkennt Pascal-Code in KI-Antworten und ersetzt markierte Bereiche im Editor mit nur einem Klick.
    Auto-Modell-Erkennung: Lädt installierte Modelle automatisch von deinem lokalen Ollama-Server.
    Internationalisierung (i18n): Vollständig übersetzt in Deutsch und Englisch.
    Konfigurations-Dialog: Bequeme Einstellung von Provider, URL, Modell, API-Key und Antwortsprache.
    Smart Shortcuts: Öffne den Chat blitzschnell mit Strg+Alt+A.

![Lazarus AI Assistant Vorschau](preview.png)

🛠 Voraussetzungen

    Lazarus IDE: Version 4.x oder höher.
    KI-Backend:
        Lokal (empfohlen): Installiere Ollama und lade ein Modell (z.B. ollama pull codellama).
        Cloud: Ein gültiger API-Key für OpenAI-kompatible Dienste.

🚀 Installation

    Klone dieses Repository in deinen Lazarus-Komponenten-Ordner:

🛠 Voraussetzungen

    Lazarus IDE: Version 4.x oder höher.
    KI-Backend:
        Lokal (empfohlen): Installiere Ollama und lade ein Modell (z.B. ollama pull codellama).
        Cloud: Ein gültiger API-Key für OpenAI-kompatible Dienste.

🚀 Installation

    Klone dieses Repository in deinen Lazarus-Komponenten-Ordner:
    bash

    git clone https://github.com/lauzge/lazarus-ki-integration

    Verwende Code mit Vorsicht.
    Öffne die Datei LazarusAI.lpk in Lazarus (Paket > Paket-Datei (.lpk) öffnen...).
    Klicke auf Kompilieren und dann auf Nutzung > Installieren.
    Lazarus startet neu und du findest den Assistenten unter Werkzeuge > KI Chat Fenster öffnen.

⚙️ Konfiguration
Gehe zu Werkzeuge > KI Assistent Einstellungen..., um:

    Deinen Provider zu wählen (Ollama, OpenAI, etc.).
    Die installierten Modelle automatisch zu laden.
    Deine bevorzugte Antwortsprache für die KI festzulegen.

📄 Lizenz
Dieses Projekt steht unter der MIT-Lizenz - siehe die LICENSE Datei für Details.
Entwickelt von lauzge - Viel Spaß beim produktiven Coden!
