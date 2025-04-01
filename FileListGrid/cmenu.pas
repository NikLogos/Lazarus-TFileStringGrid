{
The MIT License (MIT)

Copyright (c)  Ксенофрнтов Николай aka Logos (nik.logos@gmail.com)

Данная лицензия разрешает лицам, получившим копию данного программного обеспечения и сопутствующей документации (далее — Программное обеспечение), безвозмездно использовать Программное обеспечение без ограничений, включая неограниченное право на использование, копирование, изменение, слияние, публикацию, распространение, сублицензирование и/или продажу копий Программного обеспечения, а также лицам, которым предоставляется данное Программное обеспечение, при соблюдении следующих условий:

Указанное выше уведомление об авторском праве и данные условия должны быть включены во все копии или значимые части данного Программного обеспечения.

ДАННОЕ ПРОГРАММНОЕ ОБЕСПЕЧЕНИЕ ПРЕДОСТАВЛЯЕТСЯ «КАК ЕСТЬ», БЕЗ КАКИХ-ЛИБО ГАРАНТИЙ, ЯВНО ВЫРАЖЕННЫХ ИЛИ ПОДРАЗУМЕВАЕМЫХ, ВКЛЮЧАЯ ГАРАНТИИ ТОВАРНОЙ ПРИГОДНОСТИ, СООТВЕТСТВИЯ ПО ЕГО КОНКРЕТНОМУ НАЗНАЧЕНИЮ И ОТСУТСТВИЯ НАРУШЕНИЙ, НО НЕ ОГРАНИЧИВАЯСЬ ИМИ. НИ В КАКОМ СЛУЧАЕ АВТОРЫ ИЛИ ПРАВООБЛАДАТЕЛИ НЕ НЕСУТ ОТВЕТСТВЕННОСТИ ПО КАКИМ-ЛИБО ИСКАМ, ЗА УЩЕРБ ИЛИ ПО ИНЫМ ТРЕБОВАНИЯМ, В ТОМ ЧИСЛЕ, ПРИ ДЕЙСТВИИ КОНТРАКТА, ДЕЛИКТЕ ИЛИ ИНОЙ СИТУАЦИИ, ВОЗНИКШИМ ИЗ-ЗА ИСПОЛЬЗОВАНИЯ ПРОГРАММНОГО ОБЕСПЕЧЕНИЯ ИЛИ ИНЫХ ДЕЙСТВИЙ С ПРОГРАММНЫМ ОБЕСПЕЧЕНИЕМ.


Copyright (c)  Ксенофонтов Николай aka Logos (nik.logos@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

Unit cmenu;

{$mode objfpc}{$H+}

interface

uses
  Windows, ShellAPI, ActiveX, ComObj, SysUtils, Classes, Controls, Forms, Menus,
  ShlObj, dialogs;

const
  IID_IContextMenu2: TGUID = '{000214F4-0000-0000-C000-000000000046}';
  IID_IContextMenu3: TGUID = '{BCFCE0A0-EC17-11D0-8D10-00A0C90F2719}';
  CMD_PROPERTIES = $0000000F; // Команда "Свойства"
type
    PItemIDListArray = ^TItemIDListArray;
    TItemIDListArray = array[0..0] of PItemIDList;



procedure ShowWindowsContextMenu(handle:HWND; sfiles:tstringlist; X, Y: Integer);

implementation

procedure ShowWindowsContextMenu(handle:HWND; sfiles:tstringlist; X, Y: Integer);
var
  ShellFolder: IShellFolder;
  //PIDL: PItemIDList;
  ContextMenu: IContextMenu;
  Menu: HMENU;
  Cmd: UINT;
  CursorPos, pt: TPoint;
  InvokeCmd: TCMInvokeCommandInfo;
  hr: HRESULT;
  FileArray: array of PItemIDList;
  FileCount: Integer;
  i: integer;
  FilePath: string;
  FileOp: TSHFileOpStruct;
  FileList: string;
begin

  if (SFiles.Count = 0) then Exit;

  // Инициализация COM
  hr := CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE);
  if Failed(hr) then Exit;

  try
    // Получаем интерфейс рабочего стола
    if Failed(SHGetDesktopFolder(ShellFolder)) then Exit;

    // Создаем массив PIDL для выбранных файлов
    FileCount := SFiles.Count;
    SetLength(FileArray, FileCount);
    try
      for I := 0 to FileCount - 1 do
      begin
        FilePath := SFiles[I];
        if Failed(SHParseDisplayName(PWideChar(UTF8Decode(FilePath)), nil, FileArray[I], 0, nil)) then
          Exit;
      end;

      // Получаем контекстное меню
      if Failed(ShellFolder.GetUIObjectOf(handle, FileCount, FileArray[0], IID_IContextMenu, nil, ContextMenu)) then
        Exit;

      // Создаем меню
      Menu := CreatePopupMenu;
      if Menu = 0 then Exit;

      try
        // Заполняем меню
        if Failed(ContextMenu.QueryContextMenu(Menu, 0, 1, $7FFF, CMF_NORMAL or CMF_EXPLORE)) then
          Exit;

        // Показываем меню
        if X = -1 then
          GetCursorPos(CursorPos)
        else
          begin
            pt:=point(X, Y);
            Windows.ClientToScreen(handle, pt);
            CursorPos:=pt;
          end;

        SetForegroundWindow(handle);
        Cmd := UINT(TrackPopupMenuEx(Menu,
              TPM_RETURNCMD or TPM_LEFTALIGN or TPM_NONOTIFY or TPM_RIGHTBUTTON,
              CursorPos.X, CursorPos.Y, handle, nil));

        // Если выбрана команда
        if Cmd > 0 then
        begin
          ZeroMemory(@InvokeCmd, SizeOf(InvokeCmd));
          InvokeCmd.cbSize := SizeOf(InvokeCmd);
          InvokeCmd.hwnd := handle;
          InvokeCmd.nShow := SW_SHOWNORMAL;

          // Специальная обработка для "Свойств"
          if Cmd = $0000000F then // 15 - команда "Свойства"
          begin
            // Правильный вызов свойств файла
            ShellExecute(handle, 'properties', PChar(SFiles[0]), nil, nil, SW_SHOW);
          end
          // Специальная обработка для "Удалить"
          else if (Cmd >= 16) and (Cmd <= 18) then // Диапазон команд удаления
          begin
            // Создаем двойной null-terminated список файлов
            FileList := '';
            for i := 0 to SFiles.Count - 1 do
              FileList := FileList + SFiles[i] + #0;
            FileList := FileList + #0;

            // Настраиваем структуру операции с файлами
            ZeroMemory(@FileOp, SizeOf(FileOp));
            FileOp.Wnd := handle;
            FileOp.wFunc := FO_DELETE;
            FileOp.pFrom := PChar(FileList);
            FileOp.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION;

            // Выполняем удаление
            SHFileOperation(FileOp);
          end
          else
          begin
            // Стандартная обработка других команд
            InvokeCmd.lpVerb := PAnsiChar(Cmd - 1);
            OleCheck(ContextMenu.InvokeCommand(InvokeCmd));
          end;
        end;
      finally
        DestroyMenu(Menu);
      end;
    finally
      // Освобождаем PIDL
      for I := 0 to FileCount - 1 do
        if FileArray[I] <> nil then
          CoTaskMemFree(FileArray[I]);
    end;
  finally
    CoUninitialize;
  end;
end;

end.

