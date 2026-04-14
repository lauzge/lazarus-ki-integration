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
  ResponseStream: TStringStream;
  JSONData: TJSONData;    // Fehlende Deklaration
  AIResponse: String;     // Fehlende Deklaration
begin
  if Trim(memInput.Text) = '' then Exit;

  btnSend.Enabled := False;
  Client := TFPHTTPClient.Create(nil);
  ResponseStream := TStringStream.Create('');
  RequestBody := TJSONObject.Create;

  try
    // Ollama JSON vorbereiten
    RequestBody.Add('model', LAIConfig.ModelName);
    RequestBody.Add('prompt', 'Du bist ein erfahrener Delphi/FreePascal Entwickler. ' +
                'Schreibe NUR den benötigten Code ohne lange Erklärungen. ' +
                'Umschließe den Code mit ```pascal. ' +
                'KEINE einleitenden oder abschließenden Anführungszeichen. ' +
                'Aufgabe: ' + memInput.Text);
    RequestBody.Add('stream', False);

    Client.AddHeader('Content-Type', 'application/json');
    Client.RequestBody := TStringStream.Create(RequestBody.AsJSON);

    try
      // POST an Ollama
      Client.Post(LAIConfig.ServerURL, ResponseStream);

      // JSON Antwort verarbeiten
      JSONData := GetJSON(ResponseStream.DataString);
      try
        if JSONData.JSONType = jtObject then
        begin
          AIResponse := TJSONObject(JSONData).Strings['response'];

          // WICHTIG: Verwandle die Text-Zeichen "\n" in echte Linux-Umbrüche
          AIResponse := StringReplace(AIResponse, '\n', #10, [rfReplaceAll]);
          AIResponse := StringReplace(AIResponse, '\r', '', [rfReplaceAll]); // \r entfernen
          AIResponse := AdjustLineBreaks(AIResponse, tlbsLF);

          FLastAIResponse := AIResponse;
          SynOutput.Lines.Text := AIResponse; // .Text erzwingt das Neuzeichnen der Zeilen
          try
            SynOutput.Lines.Add('--- KI Antwort ---');
            // Wir nutzen Lines.Add für die formatierte Antwort
            SynOutput.Lines.Add(AIResponse);
            SynOutput.Lines.Add('');
          finally
            SynOutput.Lines.EndUpdate;
          end;

          // Ans Ende scrollen
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

