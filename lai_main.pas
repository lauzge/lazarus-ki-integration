unit lai_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls,
  MenuIntf, IDECommands, IDEWindowIntf, // Wichtig für Fenster-Registrierung
  lai_chatfrm; // Dein Chat-Formular

procedure Register;

implementation

const
  AIChatWindowName = 'LAI_Chat_Window';

// Diese Funktion erstellt das Fenster, wenn die IDE es anfordert
procedure CreateAIChatWindow(Sender: TObject; aFormName: string; var AForm: TCustomForm; DoShow: boolean);
begin
  if aFormName = AIChatWindowName then
  begin
    AForm := TLAIChatForm.Create(nil);
    if DoShow then AForm.Show;
  end;
end;


// Diese Prozedur wird aufgerufen, wenn man auf den Menüpunkt klickt
procedure ShowAIChat(Sender: TObject);
begin
  // Wir erstellen das Fenster direkt, falls es nicht existiert
  if not Assigned(LAIChatForm) then
    LAIChatForm := TLAIChatForm.Create(Nil);

  LAIChatForm.Show;
  LAIChatForm.BringToFront;
end;

procedure Register;
begin
  // Wir verzichten auf den WindowCreator-Service, wenn er Member-Fehler wirft
  // und registrieren nur den Menübefehl.
  RegisterIDEMenuCommand(itmSecondaryTools, 'AI_Show_Chat',
    'KI Chat Fenster öffnen', nil, @ShowAIChat);
end;

end.

