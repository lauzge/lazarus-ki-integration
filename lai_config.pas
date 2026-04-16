unit lai_config;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, XMLConf;

type
  TLAIConfig = class
  private
    FModelName: string;
    FServerURL: string;
    FConfigPath: string;
    FLanguage: string;
    FAPIKey: string;     // NEU: Hier das Feld hinzufügen
  public
    constructor Create;
    procedure Load;
    procedure Save;
    property ModelName: string read FModelName write FModelName;
    property ServerURL: string read FServerURL write FServerURL;
    property Language: string read FLanguage write FLanguage;
    property APIKey: string read FAPIKey write FAPIKey; // NEU: Hier die Property
  end;

var
  LAIConfig: TLAIConfig;

implementation

constructor TLAIConfig.Create;
begin
  FConfigPath := IncludeTrailingPathDelimiter(GetUserDir + '.lazarus') + 'lazarusai_settings.xml';
  FModelName := 'codellama';
  FServerURL := 'http://localhost:11434/api/generate';
  FLanguage := 'Deutsch';
  FAPIKey := ''; // Standardmäßig leer
end;

procedure TLAIConfig.Load;
var
  Config: TXMLConfig;
begin
  Config := TXMLConfig.Create(nil);
  try
    Config.Filename := FConfigPath;
    FModelName := Config.GetValue('ModelName', 'codellama');
    FServerURL := Config.GetValue('ServerURL', 'http://localhost:11434/api/generate');
    FLanguage := Config.GetValue('Language', 'Deutsch');
    FAPIKey := Config.GetValue('APIKey', ''); // Laden
  finally
    Config.Free;
  end;
end;

procedure TLAIConfig.Save;
var
  Config: TXMLConfig;
begin
  Config := TXMLConfig.Create(nil);
  try
    Config.Filename := FConfigPath;
    Config.SetValue('ModelName', FModelName);
    Config.SetValue('ServerURL', FServerURL);
    Config.SetValue('Language', FLanguage);
    Config.SetValue('APIKey', FAPIKey); // Speichern
    Config.Flush;
  finally
    Config.Free;
  end;
end;

initialization
  LAIConfig := TLAIConfig.Create;
  LAIConfig.Load;

finalization
  LAIConfig.Free;

end.

