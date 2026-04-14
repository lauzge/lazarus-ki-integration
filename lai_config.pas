unit lai_config;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, XMLConf; // XMLConf ist Standard-FPC und IMMER da

type
  TLAIConfig = class
  private
    FModelName: string;
    FServerURL: string;
    FConfigPath: string;
  public
    constructor Create;
    procedure Load;
    procedure Save;
    property ModelName: string read FModelName write FModelName;
    property ServerURL: string read FServerURL write FServerURL;
  end;

var
  LAIConfig: TLAIConfig;

implementation

constructor TLAIConfig.Create;
begin
  // IncludeTrailingPathDelimiter ist in SysUtils und funktioniert überall
  FConfigPath := IncludeTrailingPathDelimiter(GetUserDir + '.lazarus') + 'lazarusai_settings.xml';
  FModelName := 'codellama';
  FServerURL := 'http://localhost:11434/api/generate';
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

