unit lai_chatfrm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, SynEdit,
  fphttpclient, fpjson, jsonparser, SynHighlighterPas, LazIDEIntf, IDEWindowIntf,
  Clipbrd, lai_config, lai_strings;

type

  { TLAIChatForm }

  TLAIChatForm = class(TForm)
    btnSend: TButton;
    btnApplyCode: TButton;
    lblStatus: TLabel;
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
  Caption := rsFormName;
  lblStatus.Caption:='';
  btnSend.Caption:=rsSend;
  btnApplyCode.Caption:=rsApplyCode;
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
  StartTime: QWord;
  Duration: Double;
  Client: TFPHTTPClient;
  RequestBody, MsgObject: TJSONObject;
  JSONArray: TJSONArray;
  ResponseStream: TStringStream;
  JSONData, TempNode: TJSONData;
  AIResponse: String;
  FullPrompt: String;
  IsChatApi: Boolean;
begin
  if Trim(memInput.Text) = '' then Exit;

  StartTime := GetTickCount64; // Startzeit merken
  // Feedback an: Button sperren und Text anzeigen
  btnSend.Enabled := False;
  lblStatus.Caption := rsThinking;
  lblStatus.Repaint; // Erzwingt das sofortige Zeichnen unter Linux

  Client := TFPHTTPClient.Create(nil);
  // Wir setzen ein Timeout, falls die KI mal hängen bleibt (z.B. 60 Sekunden)
  Client.IOTimeout := 60000;

  ResponseStream := TStringStream.Create('');
  RequestBody := TJSONObject.Create;

  // Erkennt automatisch, ob wir das OpenAI-Chat-Format benötigen
  IsChatApi := Pos('v1/chat', LowerCase(LAIConfig.ServerURL)) > 0;

  try
    FullPrompt := 'Du bist ein erfahrener Delphi/FreePascal Entwickler. ' +
                  'Deine Antwortsprache ist strikt: ' + LAIConfig.Language + '. ' +
                  'Schreibe NUR den benötigten Code ohne lange Erklärungen. ' +
                  'Umschließe den Code mit ```pascal. ' +
                  'KEINE einleitenden oder abschließenden Anführungszeichen. ' +
                  'Erklärungen müssen in ' + LAIConfig.Language + ' verfasst sein. ' +
                  'Aufgabe: ' + memInput.Text;

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

    if LAIConfig.APIKey <> '' then
      Client.AddHeader('Authorization', 'Bearer ' + LAIConfig.APIKey);
    Client.AddHeader('Content-Type', 'application/json');

    Client.RequestBody := TStringStream.Create(RequestBody.AsJSON);

    try
      Client.Post(LAIConfig.ServerURL, ResponseStream);

      // Fehlerprüfung: Wenn der Stream leer ist, gab es ein Problem
      if ResponseStream.Size = 0 then
      begin
         SynOutput.Lines.Add('FEHLER: Keine Antwort vom Server erhalten.');
         Exit;
      end;

      JSONData := GetJSON(ResponseStream.DataString);
      try
        AIResponse := '';
        if IsChatApi then
          AIResponse := JSONData.FindPath('choices[0].message.content').AsString
        else
          AIResponse := TJSONObject(JSONData).Strings['response'];

        if AIResponse <> '' then
        begin
          // Wichtig für Linux: Erst Unescape, dann Formatierung
          AIResponse := StringReplace(AIResponse, '\n', #10, [rfReplaceAll]);
          AIResponse := StringReplace(AIResponse, '\"', '"', [rfReplaceAll]);
          AIResponse := AdjustLineBreaks(AIResponse, tlbsLF);

          FLastAIResponse := AIResponse;

          SynOutput.Lines.BeginUpdate;
          try
            SynOutput.Lines.Add('--- KI Antwort ---');
            // Nutze .Text für den gesamten Block, damit SynEdit die Zeilen umbricht
            SynOutput.SelStart := Length(SynOutput.Text);
            SynOutput.SelText := AIResponse + LineEnding;
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
        SynOutput.Lines.Add('HTTP FEHLER: ' + E.Message);
    end;

    if Assigned(Client.RequestBody) then Client.RequestBody.Free;

    // Zeit berechnen (Millisekunden in Sekunden)
    Duration := (GetTickCount64 - StartTime) / 1000;
    lblStatus.Caption := Format(rsResponseIn, [Duration]);

  finally
    btnSend.Enabled := True;
    RequestBody.Free;
    ResponseStream.Free;
    Client.Free;
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

