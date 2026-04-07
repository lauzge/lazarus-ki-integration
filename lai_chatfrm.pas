unit lai_chatfrm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, SynEdit,
  fphttpclient, fpjson, jsonparser, SynHighlighterPas, LazIDEIntf, IDEWindowIntf;

type

  { TLAIChatForm }

  TLAIChatForm = class(TForm)
    btnSend: TButton;
    btnApplyCode: TButton;
    memInput: TMemo;
    SynOutput: TSynEdit;
    procedure btnApplyCodeClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FLastAIResponse: String; // Speichert nur die reine letzte Antwort
    function ExtractCode(const FullText: String): String;
  public
    procedure SetInitialContext(const ACode: String);
  end;

var
  LAIChatForm: TLAIChatForm;

implementation

{$R *.lfm}

uses
  AnchorDocking, AnchorDockingDsgn,
  SrcEditorIntf, StrUtils;

{ TLAIChatForm }

procedure TLAIChatForm.FormCreate(Sender: TObject);
begin
  if Assigned(DockMaster) then DockMaster.MakeDockable(Self);
  FLastAIResponse := ''; // Initialisierung gegen Laufzeitfehler
end;

procedure TLAIChatForm.SetInitialContext(const ACode: String);
begin
  if ACode <> '' then
    memInput.Text := 'Hier ist mein Code:' + LineEnding + ACode + LineEnding + 'Frage dazu: ';
end;

procedure TLAIChatForm.btnSendClick(Sender: TObject);
var
  Client: TFPHTTPClient;
  ResponseStream: TStringStream;
  RequestBody: TJSONObject;
begin
  if Trim(memInput.Text) = '' then Exit;
  btnSend.Enabled := False;

  Client := TFPHTTPClient.Create(nil);
  ResponseStream := TStringStream.Create('');
  RequestBody := TJSONObject.Create;
  try
    RequestBody.Add('model', 'llama3');
    RequestBody.Add('prompt', 'Antworte NUR mit Pascal-Code in Backticks. Aufgabe: ' + memInput.Text);
    RequestBody.Add('stream', False);

    Client.AddHeader('Content-Type', 'application/json');
    Client.RequestBody := TStringStream.Create(RequestBody.AsJSON);

    try
      Client.Post('http://localhost:11434/api/generate', ResponseStream);
      FLastAIResponse := TJSONObject(GetJSON(ResponseStream.DataString)).Strings['response'];
      FLastAIResponse := StringReplace(FLastAIResponse, #10, LineEnding, [rfReplaceAll]);

      SynOutput.Lines.Add('--- KI ---');
      SynOutput.Lines.Add(FLastAIResponse);
      memInput.Clear;
    except
      on E: Exception do ShowMessage('Fehler: ' + E.Message);
    end;
  finally
    RequestBody.Free; ResponseStream.Free; Client.Free;
    btnSend.Enabled := True;
  end;
end;

procedure TLAIChatForm.btnApplyCodeClick(Sender: TObject);
var
  Editor: TSourceEditorInterface;
  CodeToInsert: String;
begin
  if FLastAIResponse = '' then
  begin
    ShowMessage('Keine KI-Antwort vorhanden.');
    Exit;
  end;

  CodeToInsert := ExtractCode(FLastAIResponse);
  Editor := SourceEditorManagerIntf.ActiveEditor;

  if Assigned(Editor) then
  begin
    Editor.Selection := CodeToInsert;
  end else
    ShowMessage('Kein aktiver Editor gefunden.');
end;

function TLAIChatForm.ExtractCode(const FullText: String): String;
var
  S: String;
  StartPos, EndPos: Integer;
begin
  S := FullText;
  StartPos := Pos('```', S);
  if StartPos > 0 then
  begin
    Delete(S, 1, StartPos + 2);
    // Erste Zeile nach ``` löschen (da steht oft 'pascal')
    if Pos(LineEnding, S) > 0 then
      Delete(S, 1, Pos(LineEnding, S) + Length(LineEnding) - 1);

    EndPos := Pos('```', S);
    if EndPos > 0 then
      Result := Trim(Copy(S, 1, EndPos - 1))
    else
      Result := Trim(S);
  end else Result := Trim(FullText);
end;

end.

