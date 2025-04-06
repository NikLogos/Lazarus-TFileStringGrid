{
The MIT License (MIT)

Copyright (c)  Ксенофонтов Николай aka Logos (nik.logos@gmail.com)

Данная лицензия разрешает лицам, получившим копию данного программного обеспечения и сопутствующей документации (далее — Программное обеспечение), безвозмездно использовать Программное обеспечение без ограничений, включая неограниченное право на использование, копирование, изменение, слияние, публикацию, распространение, сублицензирование и/или продажу копий Программного обеспечения, а также лицам, которым предоставляется данное Программное обеспечение, при соблюдении следующих условий:

Указанное выше уведомление об авторском праве и данные условия должны быть включены во все копии или значимые части данного Программного обеспечения.

ДАННОЕ ПРОГРАММНОЕ ОБЕСПЕЧЕНИЕ ПРЕДОСТАВЛЯЕТСЯ «КАК ЕСТЬ», БЕЗ КАКИХ-ЛИБО ГАРАНТИЙ, ЯВНО ВЫРАЖЕННЫХ ИЛИ ПОДРАЗУМЕВАЕМЫХ, ВКЛЮЧАЯ ГАРАНТИИ ТОВАРНОЙ ПРИГОДНОСТИ, СООТВЕТСТВИЯ ПО ЕГО КОНКРЕТНОМУ НАЗНАЧЕНИЮ И ОТСУТСТВИЯ НАРУШЕНИЙ, НО НЕ ОГРАНИЧИВАЯСЬ ИМИ. НИ В КАКОМ СЛУЧАЕ АВТОРЫ ИЛИ ПРАВООБЛАДАТЕЛИ НЕ НЕСУТ ОТВЕТСТВЕННОСТИ ПО КАКИМ-ЛИБО ИСКАМ, ЗА УЩЕРБ ИЛИ ПО ИНЫМ ТРЕБОВАНИЯМ, В ТОМ ЧИСЛЕ, ПРИ ДЕЙСТВИИ КОНТРАКТА, ДЕЛИКТЕ ИЛИ ИНОЙ СИТУАЦИИ, ВОЗНИКШИМ ИЗ-ЗА ИСПОЛЬЗОВАНИЯ ПРОГРАММНОГО ОБЕСПЕЧЕНИЯ ИЛИ ИНЫХ ДЕЙСТВИЙ С ПРОГРАММНЫМ ОБЕСПЕЧЕНИЕМ.


Copyright (c)  Ксенофрнтов Николай aka Logos (nik.logos@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
} 

unit dirMonW;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Windows, LazUTF8, dialogs;

type

  { TDirectoryWatcher }

  TDirectoryWatcher = class(TThread)
  private
    FDirectory: string;
    FHandle: THandle;
    FBuffer: array[0..1023] of Byte;

    FOnChange: TNotifyEvent;
    FThOnError: TNotifyEvent;

    //dirChanged:boolean;
  protected
    procedure Execute; override;

    procedure DoChange;
    procedure DoError;
  public
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnThError: TNotifyEvent read FThOnError write FThOnError;

    constructor Create(const ADirectory: string);
    destructor Destroy; override;
    //procedure ChangeThDir(const ADirectory: string);
  end;

implementation

{ TDirectoryWatcher }

procedure TDirectoryWatcher.Execute;
var
  BytesReturned: DWORD;
  Overlapped: TOverlapped;
  WaitResult: DWORD;
begin
  FillChar(Overlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, TRUE, FALSE, nil);
  if Overlapped.hEvent = 0 then
  begin
    Synchronize(@DoError);
    Exit;
  end;

  try
    while not Terminated do
    begin
      if not ReadDirectoryChangesW(FHandle, @FBuffer, SizeOf(FBuffer), False,
        FILE_NOTIFY_CHANGE_FILE_NAME or FILE_NOTIFY_CHANGE_DIR_NAME or
        FILE_NOTIFY_CHANGE_SIZE or FILE_NOTIFY_CHANGE_LAST_WRITE,
        @BytesReturned, @Overlapped, nil) then
      begin
        Synchronize(@DoError);
        Break;
      end;

      WaitResult := WaitForSingleObject(Overlapped.hEvent, 1000);
      case WaitResult of
        WAIT_OBJECT_0:
          if not Terminated then
            Synchronize(@DoChange);

        WAIT_TIMEOUT:
          Continue;

        else
        begin
          Synchronize(@DoError);
          Break;
        end;
      end;
    end;
  finally
    CancelIo(FHandle);
    CloseHandle(Overlapped.hEvent);
  end;
end;

procedure TDirectoryWatcher.DoChange;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TDirectoryWatcher.DoError;
begin
   if Assigned(FThOnError) then FThOnError(Self);
end;

constructor TDirectoryWatcher.Create(const ADirectory: string);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FDirectory := IncludeTrailingPathDelimiter(ADirectory);

  FHandle := CreateFile(PChar(UTF8ToWinCP(FDirectory)), FILE_LIST_DIRECTORY,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
    nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OVERLAPPED, 0);

  if FHandle = INVALID_HANDLE_VALUE then
  begin
    Synchronize(@DoError);
    Terminate;
  end;
end;

destructor TDirectoryWatcher.Destroy;
begin
  Terminate;
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    CancelIo(FHandle);
    CloseHandle(FHandle);
  end;
  inherited Destroy;
end;


end.

