unit lai_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, LCLIntf, LazFileUtils,
  MenuIntf, IDECommands,
  ProjPackIntf, // Erforderlich für den Zugriff auf Paket-Pfade
  IDEWindowIntf, // Wichtig für Fenster-Registrierung
  lai_chatfrm, // Dein Chat-Formular
  lai_strings,
  SrcEditorIntf,
  lai_configfrm,
  lai_config,
  DefaultTranslator,
  LCLTranslator,  // Für GetLanguageIDs
  Translations;

procedure Register;

implementation

const
  AIChatWindowName = 'LAI_Chat_Window';

procedure CreateAIChatWindow(Sender: TObject; aFormName: string; var AForm: TCustomForm; DoShow: boolean);
begin
  if aFormName = AIChatWindowName then
  begin
    // Nur hier wird das Fenster erstellt!
    AForm := TLAIChatForm.Create(nil);
    if DoShow then AForm.Show;
  end;
end;

procedure ShowAIChat(Sender: TObject);
begin
  // 1. Erstellen, falls es noch nie existierte
  if not Assigned(LAIChatForm) then
    LAIChatForm := TLAIChatForm.Create(Nil);

  // 2. Sichtbarkeit im Widgetset und im Docking erzwingen
  LAIChatForm.Visible := True;

  // 3. Falls es gedockt ist, müssen wir es dem Manager "entreißen"
  if LAIChatForm.Parent <> nil then
    LAIChatForm.Parent.Visible := True;

  LAIChatForm.Show;
  LAIChatForm.BringToFront;
  LAIChatForm.SetFocus;

  // 4. Kontext übergeben
  if Assigned(SourceEditorManagerIntf.ActiveEditor) then
    LAIChatForm.SetInitialContext(SourceEditorManagerIntf.ActiveEditor.Selection);
end;

procedure ShowAIOptions(Sender: TObject);
var
  ConfigFrm: TLAIConfigForm; // Das ist dein neues Fenster
begin
  ConfigFrm := TLAIConfigForm.Create(nil);
  try
    ConfigFrm.ShowModal;
  finally
    ConfigFrm.Free;
  end;
end;

procedure Register;
var
  Lang: String;
  PODirectory: String;
begin
  // 1. Sprache ermitteln (aus LCLTranslator)
  Lang := SetDefaultLang(''); // Ermittelt die Systemsprache (z.B. 'de')

  // 2. Pfad zum languages-Ordner ermitteln
  // Unter Linux liegen installierte Pakete meist in ~/.lazarus/onlinepackagemanager/...
  // Wir nutzen die sicherste Methode, um den Pfad zur Laufzeit zu finden:
  PODirectory := AppendPathDelim(ExtractFilePath(ParamStr(0))) + 'languages';

  // FALLBACK: Falls ParamStr(0) nicht hilft, suchen wir relativ zur Unit
  // (In Lazarus 4.6 funktioniert oft dieser direkte Weg):
  if not DirectoryExists(PODirectory) then
    PODirectory := '/home/' + GetEnvironmentVariable('USER') + '/.lazarus/languages'; // Beispielpfad

  // 3. Übersetzungen laden
  // Wir laden die Strings für die Unit 'lai_strings'
  if Lang <> '' then
    Translations.TranslateUnitResourceStrings('lai_strings',
      PODirectory + '/LazarusAI.%s.po', Lang, '');

  // ... hier folgt deine restliche Register-Logik (Menüs, Shortcuts)
  // Menüpunkt für den Chat (hast du schon)
  RegisterIDEMenuCommand(itmSecondaryTools, 'AI_Show_Chat',
    'KI Chat Fenster öffnen', nil, @ShowAIChat);

  // NEU: Menüpunkt für die Einstellungen
  RegisterIDEMenuCommand(itmSecondaryTools, 'AI_Show_Options',
    'KI Assistent Einstellungen...', nil, @ShowAIOptions);
end;

end.

