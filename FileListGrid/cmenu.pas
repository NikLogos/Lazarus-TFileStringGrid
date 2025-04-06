unit cmenu;

{$mode objfpc}{$H+}

interface

uses
  Windows, ShellAPI, ActiveX, ComObj, SysUtils, Classes, ShlObj, Dialogs;

procedure ShowWindowsContextMenu(handle: HWND; sfiles: TStringList; X, Y: Integer);

implementation

const
  VERB_PROPERTIES = 'properties';

type
  TShowPropertiesCallback = class
    class procedure ShowProperties(const FileName: string);
  end;

class procedure TShowPropertiesCallback.ShowProperties(const FileName: string);
var
  sei: TShellExecuteInfo;
begin
  ZeroMemory(@sei, SizeOf(sei));
  sei.cbSize := SizeOf(sei);
  sei.lpVerb := 'properties';
  sei.lpFile := PChar(FileName);
  sei.nShow := SW_SHOW;
  sei.fMask := SEE_MASK_INVOKEIDLIST;
  ShellExecuteExW(@sei);
end;

function GetContextMenuForFiles(Handle: HWND; Files: TStringList; out Menu: HMENU; out ContextMenu: IContextMenu): Boolean;
var
  ShellFolder: IShellFolder;
  pidl: PItemIDList;
  FileArray: array of PItemIDList;
  i: Integer;
begin
  Result := False;
  if Files.Count = 0 then Exit;

  // Получаем интерфейс рабочего стола
  if Failed(SHGetDesktopFolder(ShellFolder)) then Exit;

  // Получаем PIDL для всех файлов
  SetLength(FileArray, Files.Count);
  try
    for i := 0 to Files.Count - 1 do
    begin
      if Failed(SHParseDisplayName(PWideChar(UTF8Decode(Files[i])), nil, pidl, 0, nil)) then Exit;
      FileArray[i] := pidl;
    end;

    // Получаем контекстное меню
    if Failed(ShellFolder.GetUIObjectOf(Handle, Files.Count, FileArray[0], IID_IContextMenu, nil, ContextMenu)) then Exit;

    // Создаем меню
    Menu := CreatePopupMenu;
    if Menu = 0 then Exit;

    // Заполняем меню
    if Failed(ContextMenu.QueryContextMenu(Menu, 0, 1, $7FFF, CMF_NORMAL or CMF_EXPLORE)) then
    begin
      DestroyMenu(Menu);
      Exit;
    end;

    Result := True;
  finally
    // Освобождаем PIDL
    for i := 0 to High(FileArray) do
      if FileArray[i] <> nil then
        CoTaskMemFree(FileArray[i]);
  end;
end;

procedure ShowWindowsContextMenu(handle: HWND; sfiles: TStringList; X, Y: Integer);
var
  ContextMenu: IContextMenu;
  Menu: HMENU;
  Cmd: UINT;
  CursorPos: TPoint;
  InvokeCmd: TCMInvokeCommandInfo;
begin
  if (sfiles = nil) or (sfiles.Count = 0) then Exit;

  // Инициализация COM
  OleCheck(CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE));
  try
    // Получаем контекстное меню
    if not GetContextMenuForFiles(handle, sfiles, Menu, ContextMenu) then Exit;

    try
      // Показываем меню
      if X = -1 then
        GetCursorPos(CursorPos)
      else
      begin
        CursorPos := Point(X, Y);
        Windows.ClientToScreen(handle, CursorPos);
      end;

      SetForegroundWindow(handle);
      Cmd := UINT(TrackPopupMenuEx(Menu,
            TPM_RETURNCMD or TPM_LEFTALIGN or TPM_NONOTIFY or TPM_RIGHTBUTTON,
            CursorPos.X, CursorPos.Y, handle, nil));

      // Если выбрана команда "Свойства"
      if Cmd = $0000000F then
      begin
        // Используем ShellExecuteEx для правильного отображения свойств
        TShowPropertiesCallback.ShowProperties(sfiles[0]);
      end
      else if Cmd > 0 then
      begin
        // Обработка других команд
        ZeroMemory(@InvokeCmd, SizeOf(InvokeCmd));
        InvokeCmd.cbSize := SizeOf(InvokeCmd);
        InvokeCmd.hwnd := handle;
        InvokeCmd.lpVerb := MAKEINTRESOURCEA(Cmd - 1);
        InvokeCmd.nShow := SW_SHOWNORMAL;
        OleCheck(ContextMenu.InvokeCommand(InvokeCmd));
      end;
    finally
      DestroyMenu(Menu);
    end;
  finally
    CoUninitialize;
  end;
end;

end.

