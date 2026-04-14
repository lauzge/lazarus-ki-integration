unit lai_configfrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, lai_config, fphttpclient,
  fpjson, jsonparser, Dialogs;


type

  { TLAIConfigForm }

  TLAIConfigForm = class(TForm)
    btnDetectModels: TButton;
    btnSave: TButton;
    cbModel: TComboBox;
    edtURL: TEdit;
    lblURL: TLabel;
    lblModel: TLabel;
    procedure btnDetectModelsClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    procedure LoadSettings;
    procedure SaveSettings;
  public

  end;

var
  LAIConfigForm : TLAIConfigForm;

implementation

{$R *.lfm}

procedure TLAIConfigForm.btnDetectModelsClick(Sender: TObject);
var
  Client: TFPHTTPClient;
  Response, TargetURL: String; // Neue Variable für die URL
  JSONData, ModelEntry: TJSONData;
  I: Integer;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    try
      // Fix für "Illegal qualifier": Wir nutzen StringReplace aus SysUtils
      TargetURL := StringReplace(edtURL.Text, '/generate', '/tags', [rfReplaceAll]);

      Response := Client.Get(TargetURL);
      JSONData := GetJSON(Response);
      try
        cbModel.Items.BeginUpdate;
        cbModel.Items.Clear;

        // Zugriff auf das "models" Array
        if JSONData.FindPath('models') <> nil then
        begin
          for I := 0 to JSONData.FindPath('models').Count - 1 do
          begin
            ModelEntry := JSONData.FindPath('models').Items[I];
            cbModel.Items.Add(ModelEntry.FindPath('name').AsString);
          end;
        end;
      finally
        JSONData.Free;
        cbModel.Items.EndUpdate;
      end;

      if cbModel.Items.Count > 0 then
        ShowMessage(IntToStr(cbModel.Items.Count) + ' Modelle gefunden!')
      else
        ShowMessage('Keine Modelle gefunden. Läuft Ollama?');

    except
      on E: Exception do
        ShowMessage('Verbindung zu Ollama fehlgeschlagen: ' + E.Message);
    end;
  finally
    Client.Free;
  end;
end;

procedure TLAIConfigForm.btnSaveClick(Sender: TObject);
begin
  SaveSettings;
  if Owner is TForm then TForm(Owner).ModalResult := mrOk;
end;

procedure TLAIConfigForm.LoadSettings;
begin
  edtURL.Text := LAIConfig.ServerURL;
  cbModel.Text := LAIConfig.ModelName;
end;

procedure TLAIConfigForm.SaveSettings;
begin
  LAIConfig.ServerURL := edtURL.Text;
  LAIConfig.ModelName := cbModel.Text;
  LAIConfig.Save; // Schreibt es in die XML-Datei
end;

end.

