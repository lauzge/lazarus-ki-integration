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

  end;

var
  LAIChatForm: TLAIChatForm;

implementation

{$R *.lfm}

uses
  AnchorDocking, AnchorDockingDsgn,
  SrcEditorIntf, StrUtils;

{ TLAIChatForm }

procedure TLAIChatForm.btnSendClick(Sender: TObject);
var
  Client: TFPHTTPClient;
  RequestBody: TJSONObject;
  ResponseStream: TStringStream;
  JSONData: TJSONData;
  AIResponse: String;
begin
  if Trim(memInput.Text) = '' then Exit;

  // UI sperren während des Requests
  btnSend.Enabled := False;
  Client := TFPHTTPClient.Create(nil);
  ResponseStream := TStringStream.Create('');
  RequestBody := TJSONObject.Create;

  try
    // Ollama JSON vorbereiten
    RequestBody.Add('model', 'llama3');
    RequestBody.Add('prompt', memInput.Text);
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

          // WICHTIG: Zeilenumbrüche für Windows/Lazarus korrigieren
          // Ersetzt Linux-LF (#10) durch System-LineEnding (#13#10)
          AIResponse := StringReplace(AIResponse, #10, LineEnding, [rfReplaceAll]);
          // Doppelte Umbrüche bereinigen, falls vorhanden
          AIResponse := StringReplace(AIResponse, #13#13#10, #13#10, [rfReplaceAll]);

          FLastAIResponse := AIResponse; // Hier speichern wir nur die Antwort der KI
          SynOutput.Lines.Add(AIResponse);

          // Text ans Ende von SynEdit anfügen
          SynOutput.Lines.BeginUpdate;
          try
            SynOutput.Lines.Add('--- ' + FormatDateTime('HH:NN', Now) + ' ---');

            // Wir setzen den Cursor ans Ende und fügen den Text ein
            SynOutput.CaretY := SynOutput.Lines.Count + 1;
            SynOutput.SelText := AIResponse + LineEnding;
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

procedure TLAIChatForm.FormCreate(Sender: TObject);
begin
  // AnchorDocking Integration
  if Assigned(DockMaster) then
    DockMaster.MakeDockable(Self);

  // Verhindert, dass das Fenster beim Schließen komplett zerstört wird,
  // falls die IDE es nur verstecken will
  Self.AllowDropFiles := True;
end;



procedure TLAIChatForm.btnApplyCodeClick(Sender: TObject);
var
  Editor: TSourceEditorInterface;
begin
  // Wir parsen nur die letzte Antwort, nicht den ganzen Chat-Verlauf!
  Editor.Selection := ExtractCode(FLastAIResponse);
  Self.Close;
end;

function TLAIChatForm.ExtractCode(const FullText: String): String;
var
  StartPos, EndPos: Integer;
  WorkText: String;
begin
  Result := '';
  WorkText := FullText;

  // 1. Suche den LETZTEN Block mit ``` (falls mehrere Antworten im Chat sind)
  StartPos := RPos('```', WorkText); // RPos sucht von hinten (Unit StrUtils nötig!)

  if StartPos > 0 then
  begin
    // Wir brauchen aber den ANFANG des letzten Blocks, also suchen wir das Paar davor
    // Einfachere Logik: Wir nehmen den Text ab dem ersten ``` nach dem letzten Trenner
    StartPos := Pos('```', WorkText);

    if StartPos > 0 then
    begin
      Delete(WorkText, 1, StartPos + 2);

      // Sprachbezeichner wie "pascal", "delphi" oder "free-pascal" entfernen
      WorkText := TrimLeft(WorkText);
      if Pos('pascal', LowerCase(Copy(WorkText, 1, 10))) = 1 then Delete(WorkText, 1, 6);
      if Pos('delphi', LowerCase(Copy(WorkText, 1, 10))) = 1 then Delete(WorkText, 1, 6);

      // Ende des Blocks suchen
      EndPos := Pos('```', WorkText);
      if EndPos > 0 then
        Result := Trim(Copy(WorkText, 1, EndPos - 1))
      else
        Result := Trim(WorkText);
    end;
  end;

  // Falls GAR KEINE Backticks gefunden wurden, geben wir den ganzen Text zurück
  // (vielleicht hat die KI die Backticks vergessen)
  if Result = '' then Result := FullText;
end;




end.

