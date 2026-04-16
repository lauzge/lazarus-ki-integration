unit lai_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls,
  MenuIntf, IDECommands, IDEWindowIntf, // Wichtig für Fenster-Registrierung
  lai_chatfrm, // Dein Chat-Formular
  SrcEditorIntf,
  LCLType,
  ProjectIntf,
  lai_configfrm,
  lai_config,
  LCLTranslator,
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
begin
  // Menüpunkt für den Chat (hast du schon)
  RegisterIDEMenuCommand(itmSecondaryTools, 'AI_Show_Chat',
    'KI Chat Fenster öffnen', nil, @ShowAIChat);

  // NEU: Menüpunkt für die Einstellungen
  RegisterIDEMenuCommand(itmSecondaryTools, 'AI_Show_Options',
    'KI Assistent Einstellungen...', nil, @ShowAIOptions);
end;


end.

