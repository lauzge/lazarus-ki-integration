unit lai_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls,
  MenuIntf, IDECommands, IDEWindowIntf, // Wichtig für Fenster-Registrierung
  lai_chatfrm, // Dein Chat-Formular
  SrcEditorIntf;

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
begin
  // Wir verzichten auf IDEWindowCreators.Add, wenn es Abstürze verursacht.
  // Wir registrieren NUR den Menübefehl. Das reicht für das manuelle Management.
  RegisterIDEMenuCommand(itmSecondaryTools, 'AI_Show_Chat',
    'KI Chat Fenster öffnen', nil, @ShowAIChat);
end;

end.

