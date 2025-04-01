{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit filelist;

{$warn 5023 off : no warning about unused units}
interface

uses
  FileListGrid, dirMonW, IconCacheManager, cmenu, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('FileListGrid', @FileListGrid.Register);
end;

initialization
  RegisterPackage('filelist', @Register);
end.
