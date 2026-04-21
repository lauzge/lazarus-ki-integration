unit lai_configfrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, lai_config, fphttpclient,
  fpjson, jsonparser, Dialogs, lai_strings;


type

  { TLAIConfigForm }

  TLAIConfigForm = class(TForm)
    btnDetectModels: TButton;
    btnSave: TButton;
    cbModel: TComboBox;
    cbProvider: TComboBox;
    edtAPIKey: TEdit;
    edtLanguage: TEdit;
    edtURL: TEdit;
    lblProvider: TLabel;
    lblAPIKey: TLabel;
    lblLanguage: TLabel;
    lblURL: TLabel;
    lblModel: TLabel;
    procedure btnDetectModelsClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
        ShowMessage(IntToStr(cbModel.Items.Count) + rsModelFound)
      else
        ShowMessage(rsModelNotFount);

    except
      on E: Exception do
        ShowMessage(rsConnOllamaFaild + E.Message);
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

procedure TLAIConfigForm.cbProviderChange(Sender: TObject);
begin
  case cbProvider.ItemIndex of
    0: begin // Ollama
         cbProvider.Text:='Ollama';
         edtURL.Text := 'http://localhost:11434/api/generate';
         cbModel.Text := 'codellama';
       end;
    1: begin // LM Studio
         cbProvider.Text:='LM Studio';
         edtURL.Text := 'http://localhost:1234/v1/chat/completions';
         cbModel.Text := 'model-identifier';
       end;
    2: begin // OpenAI
         cbProvider.Text:='Open AI';
         edtURL.Text := 'https://openai.com';
         cbModel.Text := 'gpt-4-turbo';
       end;
    3: begin // Mistral
         cbProvider.Text:='Mistral';
         edtURL.Text := 'https://mistral.ai';
         cbModel.Text := 'mistral-medium';
       end;
  end;
end;

procedure TLAIConfigForm.FormCreate(Sender: TObject);
begin
  lblProvider.Caption:=rsProvider;
  lblModel.Caption:=rsModel;
  lblLanguage.Caption:=rsLanguage;
  btnSave.Caption:=rsSave;
  btnDetectModels.Caption:=rsDetect;
  LoadSettings;
end;

procedure TLAIConfigForm.LoadSettings;
begin
  cbProvider.Text:=LAIConfig.Provider;
  edtURL.Text := LAIConfig.ServerURL;
  cbModel.Text := LAIConfig.ModelName;
  edtLanguage.Text := LAIConfig.Language;
  edtAPIKey.Text := LAIConfig.APIKey;
end;

procedure TLAIConfigForm.SaveSettings;
begin
  LAIConfig.Provider :=  cbProvider.Text;
  LAIConfig.ServerURL := edtURL.Text;
  LAIConfig.ModelName := cbModel.Text;
  LAIConfig.Language := edtLanguage.Text;
  LAIConfig.APIKey := edtAPIKey.Text;
  LAIConfig.Save; // Schreibt es in die XML-Datei
end;

end.

