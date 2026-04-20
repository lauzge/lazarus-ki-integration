unit lai_strings;

{$mode objfpc}{$H+}

interface

resourcestring
  // Chatfenster
  rsFormName = 'KI Assistent';
  rsThinking = 'KI arbeitet...';
  rsResponseIn = 'Antwort in %.2f Sek. erhalten';
  rsResponseOut = 'FEHLER: Keine Antwort vom Server erhalten.';
  rsHttpError = 'HTTP FEHLER: ';
  rsSend = 'Senden';
  rsApplyCode = 'Code übernehmen';
  rsErrorHeader = 'FEHLER: %s';
  rsFullPrompt01 = 'Du bist ein erfahrener Delphi/FreePascal Entwickler. ' +
                  'Deine Antwortsprache ist strikt: ';
  rsFullPrompt02 = 'Schreibe NUR den benötigten Code ohne lange Erklärungen. ' +
                  'Umschließe den Code mit ```pascal. ' +
                  'KEINE einleitenden oder abschließenden Anführungszeichen. ' +
                  'Erklärungen müssen in ';
  rsFullPrompt03 = ' verfasst sein. ' +
                  'Aufgabe: ';
  rsMyCode = 'Hier ist mein Code:';
  rsQuestionAbout = 'Frage dazu: ';

  // Konfigurationsfenster
  rsConfigTitle = 'KI Assistent Einstellungen';
  rsModel = 'Modell:';
  rsLanguage = 'Sprache:';
  rsSave = 'Speichern';
  rsDetect = 'Modelle laden';
  rsProvider = 'Anbieter';
  rsModelFound = ' Modelle gefunden!';
  rsModelNotFount = 'Keine Modelle gefunden. Läuft Ollama?';
  rsConnOllamaFaild = 'Verbindung zu Ollama fehlgeschlagen: ';

implementation
end.

