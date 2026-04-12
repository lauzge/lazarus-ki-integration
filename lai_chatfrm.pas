unit lai_chatfrm;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, SynEdit,
  fphttpclient, fpjson, jsonparser, SynHighlighterPas, LazIDEIntf, IDEWindowIntf,
  Clipbrd;

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
    RequestBody.Add('model', 'llama3');
    RequestBody.Add('prompt', 'Antworte NUR mit Pascal-Code in Backticks. Aufgabe: ' + memInput.Text);
    RequestBody.Add('stream', False);

    Client.AddHeader('Content-Type', 'application/json');
    Client.RequestBody := TStringStream.Create(RequestBody.AsJSON);

    try
      // POST an Ollama
      Client.Post('http://localhost:11434/api/generate', ResponseStream);

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

  // 1. Suche den Start der Backticks
  StartPos := Pos('```', S);
  if StartPos > 0 then
  begin
    // Alles vor den Backticks UND die drei Backticks selbst löschen (+3)
    Delete(S, 1, StartPos + 2);

    // Falls direkt nach den Backticks "pascal" oder "delphi" steht,
    // löschen wir die erste Zeile komplett (bis zum ersten Linefeed)
    if Pos(#10, S) > 0 then
       Delete(S, 1, Pos(#10, S));

    // 2. Suche das Ende (die schließenden Backticks)
    EndPos := Pos('```', S);
    if EndPos > 0 then
      Result := Copy(S, 1, EndPos - 1)
    else
      Result := S; // Falls kein Ende gefunden wurde
  end
  else
    Result := FullText; // Falls gar keine Backticks da sind

  // Finales Säubern für Linux
  Result := Trim(Result);
  // Sicherstellen, dass keine Windows-Überbleibsel (#13) stören
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
end;

end.

