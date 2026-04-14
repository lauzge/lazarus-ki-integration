unit lai_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls,
  MenuIntf, IDECommands, IDEWindowIntf, // Wichtig für Fenster-Registrierung
  lai_chatfrm, // Dein Chat-Formular
  SrcEditorIntf,
  LCLType;

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

procedure Register;
var
  AICat: TIDECommandCategory;
  IDEShortCut: TIDEShortCut;
begin
  // 1. Kategorie registrieren (Eltern-Kategorie, Name, Beschreibung)
  // Wir nutzen nil als ersten Parameter für die Hauptkategorie
  AICat := RegisterIDECommandCategory(nil, 'AICommands', 'KI Assistent');

  // 2. Shortcut definieren (Strg+Alt+A)
  // Wir nutzen direkt die Word/ShiftState Variante, um NullShortcut-Fehler zu vermeiden

  // 3. Den Befehl registrieren
  // Wir nutzen nil für das TNotifyEvent (6. Param)
  // und @ShowAIChat für die TNotifyProcedure (7. Param)
  RegisterIDECommand(AICat, 'ShowAIChatCommand', 'KI Chat öffnen',
    VK_A, [ssCtrl, ssAlt], nil, @ShowAIChat);

  // 4. Den Menüeintrag im Werkzeuge-Menü registrieren
  RegisterIDEMenuCommand(itmSecondaryTools, 'AI_Show_Chat',
    'KI Chat Fenster öffnen', nil, @ShowAIChat);
end;


end.

