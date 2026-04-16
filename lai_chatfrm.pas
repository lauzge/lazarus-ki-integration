unit lai_chatfrm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, SynEdit,
  fphttpclient, fpjson, jsonparser, SynHighlighterPas, LazIDEIntf, IDEWindowIntf,
  Clipbrd, lai_config;

type

  { TLAIChatForm }

  TLAIChatForm = class(TForm)
    btnSend: TButton;
    btnApplyCode: TButton;
    memInput: TMemo;
    SynOutput: TSynEdit;
    procedure btnApplyCodeClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
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
  // AnchorDocking registrieren
  if Assigned(DockMaster) then
    DockMaster.MakeDockable(Self);
end;

procedure TLAIChatForm.SetInitialContext(const ACode: String);
begin
  if ACode <> '' then
  begin
    // Nutze .Text statt einer einfachen Zuweisung, damit das Memo
    // den String neu parst und die Zeilenumbrüche erkennt
    memInput.Lines.Text := 'Hier ist mein Code:' + LineEnding +
                           ACode + LineEnding +
                           'Frage dazu: ';
    // Cursor ans Ende setzen
    memInput.SelStart := Length(memInput.Text);
  end;
end;


procedure TLAIChatForm.btnSendClick(Sender: TObject);
var
  Client: TFPHTTPClient;
  RequestBody: TJSONObject;
  MessagesArray, MsgObject: TJSONObject; // Für OpenAI Format
  JSONArray: TJSONArray;                 // Für OpenAI Format
  ResponseStream: TStringStream;
  JSONData: TJSONData;
  AIResponse: String;
  FullPrompt: String;
  IsChatApi: Boolean;
begin
  if Trim(memInput.Text) = '' then Exit;

  btnSend.Enabled := False;
  Client := TFPHTTPClient.Create(nil);
  ResponseStream := TStringStream.Create('');
  RequestBody := TJSONObject.Create;

  // Prüfen, ob wir das OpenAI "Chat" Format brauchen (URLs mit /v1/chat/completions)
  IsChatApi := Pos('v1/chat', LowerCase(LAIConfig.ServerURL)) > 0;

  try
    FullPrompt := 'Du bist ein erfahrener Delphi/FreePascal Entwickler. ' +
                  'Deine Antwortsprache ist strikt: ' + LAIConfig.Language + '. ' +
                  'Schreibe NUR den benötigten Code ohne lange Erklärungen. ' +
                  'Umschließe den Code mit ```pascal. ' +
                  'KEINE einleitenden oder abschließenden Anführungszeichen. ' +
                  'Erklärungen müssen in ' + LAIConfig.Language + ' verfasst sein. ' +
                  'Aufgabe: ' + memInput.Text;

    // JSON Body je nach API-Typ aufbauen
    if IsChatApi then
    begin
      // OpenAI Chat Format (v1/chat/completions)
      RequestBody.Add('model', LAIConfig.ModelName);
      JSONArray := TJSONArray.Create;
      MsgObject := TJSONObject.Create;
      MsgObject.Add('role', 'user');
      MsgObject.Add('content', FullPrompt);
      JSONArray.Add(MsgObject);
      RequestBody.Add('messages', JSONArray);
    end
    else
    begin
      // Standard Ollama Format (/api/generate)
      RequestBody.Add('model', LAIConfig.ModelName);
      RequestBody.Add('prompt', FullPrompt);
      RequestBody.Add('stream', False);
    end;

    // Header setzen
    if LAIConfig.APIKey <> '' then
      Client.AddHeader('Authorization', 'Bearer ' + LAIConfig.APIKey);
    Client.AddHeader('Content-Type', 'application/json');

    Client.RequestBody := TStringStream.Create(RequestBody.AsJSON);

    try
      Client.Post(LAIConfig.ServerURL, ResponseStream);
      JSONData := GetJSON(ResponseStream.DataString);
      try
        if JSONData.JSONType = jtObject then
        begin
          // Antwort extrahieren: "response" bei Ollama, "choices[0].message.content" bei OpenAI
          if IsChatApi then
            AIResponse := JSONData.FindPath('choices[0].message.content').AsString
          else
            AIResponse := TJSONObject(JSONData).Strings['response'];

          // Formatierung für Linux/Lazarus korrigieren
          AIResponse := StringReplace(AIResponse, '\n', #10, [rfReplaceAll]);
          AIResponse := StringReplace(AIResponse, '\r', '', [rfReplaceAll]);
          AIResponse := AdjustLineBreaks(AIResponse, tlbsLF);

          FLastAIResponse := AIResponse;

          SynOutput.Lines.BeginUpdate;
          try
            SynOutput.Lines.Add('--- KI Antwort ---');
            SynOutput.Lines.Add(AIResponse);
            SynOutput.Lines.Add('');
          finally
            SynOutput.Lines.EndUpdate;
          end;

          SynOutput.CaretY := SynOutput.Lines.Count;
          memInput.Clear;
        end;
      finally
        JSONData.Free;
      end;
    except
      on E: Exception do
        SynOutput.Lines.Add('FEHLER: ' + E.Message);
    end;

    if Assigned(Client.RequestBody) then
       Client.RequestBody.Free;

  finally
    RequestBody.Free;
    ResponseStream.Free;
    Client.Free;
    btnSend.Enabled := True;
    memInput.SetFocus;
  end;
end;


procedure TLAIChatForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  // Wir zerstören das Fenster NICHT, wir verstecken es nur.
  // Das verhindert Laufzeitfehler beim erneuten Aufruf.
  CloseAction := caHide;
end;

procedure TLAIChatForm.FormDestroy(Sender: TObject);
begin
  // Falls es doch zerstört wird, Variable auf nil setzen
  if LAIChatForm = Self then
    LAIChatForm := nil;
end;

procedure TLAIChatForm.btnApplyCodeClick(Sender: TObject);
var
  Editor: TSourceEditorInterface;
  CleanCode: String;
begin
  if FLastAIResponse = '' then Exit;

  Editor := SourceEditorManagerIntf.ActiveEditor;
  if Assigned(Editor) then
  begin
    CleanCode := ExtractCode(FLastAIResponse);

    // Unter Linux/GTK2/Qt ist Selection die verlässlichste Eigenschaft.
    // Da wir in ExtractCode nun AdjustLineBreaks/StringReplace nutzen,
    // wird der Block hier korrekt als Mehrzeiler eingefügt.
    Editor.Selection := CleanCode;

    // Falls SetFocus auf ActiveView nicht geht, lassen wir es weg oder nutzen:
    if Assigned(Editor.EditorControl) then
      Editor.EditorControl.SetFocus;
  end;
end;

function TLAIChatForm.ExtractCode(const FullText: String): String;
var
  S: String;
  StartPos, EndPos: Integer;
begin
  Result := '';
  S := FullText;

  // 1. Triple-Backticks suchen
  StartPos := Pos('```', S);
  if StartPos > 0 then
  begin
    Delete(S, 1, StartPos + 2);
    // Erste Zeile (Sprachbezeichner) entfernen
    if Pos(#10, S) > 0 then Delete(S, 1, Pos(#10, S));

    EndPos := Pos('```', S);
    if EndPos > 0 then S := Copy(S, 1, EndPos - 1);
  end;

  // 2. Aggressive Reinigung der Ränder
  S := Trim(S);

  // Wir entfernen in einer Schleife alle störenden Zeichen am Anfang und Ende
  while (Length(S) > 0) and (S[1] in ['''', '"', '`']) do
    Delete(S, 1, 1);

  while (Length(S) > 0) and (S[Length(S)] in ['''', '"', '`']) do
    Delete(S, Length(S), 1);

  // 3. Finaler Linux-Check für Zeilenumbrüche
  Result := StringReplace(Trim(S), #13, '', [rfReplaceAll]);
end;


end.

