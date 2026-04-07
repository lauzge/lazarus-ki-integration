{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit LazarusAI;

{$warn 5023 off : no warning about unused units}
interface

uses
  lai_main, lai_chatfrm, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('lai_main', @lai_main.Register);
end;

initialization
  RegisterPackage('LazarusAI', @Register);
end.
