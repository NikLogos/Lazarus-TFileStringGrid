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


При создании данного ПО были использованы материалы (работы) следующих авторов:

Yusuke Kamiyamane (http://p.yusukekamiyamane.com/)

Fugue Icons
Diagona Icons

Которые лицензированы по: Creative Commons (Attribution 3.0 Unported) (https://creativecommons.org/licenses/by/3.0/deed.ru#ref-appropriate-credit)
}

unit FileListGrid;

{$mode objfpc}{$H+}


interface


uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, LResources,
  shellapi, process, LazUTF8, LCLType, LCLIntf, {dirmon,} dirmonW, fileutil,
  iconCacheManager, cmenu{, shlobj, windows};

const
  IID_IContextMenu2: TGUID = '{000214F4-0000-0000-C000-000000000046}';
  IID_IContextMenu3: TGUID = '{BCFCE0A0-EC17-11D0-8D10-00A0C90F2719}';

type

  TSortFile = (smNone, smFolder, smDate, smName, smExt, smSize, smRevDate, smRevName, smRevExt, smRevSize);
  TFileSelectEvent = procedure (Sender: TObject; fName: string) of object;
  TItemSelectEvent = procedure (Sender: TObject; iName: string) of object;
  TDirChangeEvent = procedure (Sender: TObject) of object;

  TKeyValueItem = class(TCollectionItem)
  private
    FKey: string;
    FValue: string;
  published
    property Key: string read FKey write FKey;
    property Value: string read FValue write FValue;
  end;

  { TKeyValueCollection }

  TKeyValueCollection = class(TCollection)
  private
    //function GetItem(Index: Integer): TKeyValueItem;
    procedure SetItem(Index: Integer; const Value: TKeyValueItem);
  public
    function Add: TKeyValueItem;
    function GetItem(Index: Integer): TKeyValueItem;
    function GetItemValueByKey(Key: String): String;
    function GetItemsCount:integer;
    property Items[Index: Integer]: TKeyValueItem read GetItem write SetItem; default;
  end;

  { TFileListGrid }

  TFileListGrid = class(TStringGrid)
  private
    //************************ LANG
    langFolderName:string;
    langByte:string;
    langKiloByte:string;
    langMegaByte:string;
    langGigaByte:string;
    langGoDirError:string;
    langError:string;
    langCell0:string;
    langCell1:string;
    langCell2:string;
    //************************ LANG

    FDirectory: String;
    selItem: String;
    selItems:tstrings;
    usefcolor:boolean;
    FFilesColor: TKeyValueCollection;
    FOnFileSelect: TFileSelectEvent;
    FOnDirChange: TDirChangeEvent;
    FIconFolder: TPortableNetworkGraphic; //иконка папки
    //для иконок файлов (пока для винды)
    FIconFile: TIcon;
    IconManager:TIconCacheManager;

    FImageList: TImageList;
    DirList:tstringlist;

    _DirWatch:TDirectoryWatcher;
    _ThreadStarted:boolean;

    tmpMenuList:tstringlist;


    procedure LoadFiles;
    procedure AdjustColumnWidth;
    procedure GetFileIcon(const FileName: string; Icon: TIcon);
    function FindRowByText(const SearchText: string): integer;
    procedure SelectRow(arow: Integer);
    procedure clearSelected;
    procedure SafeDrawIcon(ACanvas: TCanvas; X, Y: Integer; AIcon: TIcon);


  protected
    procedure DblClick; override;
    procedure Click; override;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
    procedure DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    //procedure ShowWindowsContextMenu(X, Y: Integer);

  public
    //**********************************
    //pubmsg:string;
    //**********************************

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure RefreshList;
    procedure lvlUp;
    procedure SetDirectory(Dir: string);
    procedure thUpdList(sender:tobject);
    procedure thError(sender: tobject);
    procedure runApp(path:string; cmdline:tstringlist);
    function getSelectedItems(var _DirList:tstringlist; withPath:boolean):boolean;
    procedure selectAll(doselect:boolean);

  published
    property Directory: string read FDirectory write SetDirectory;
    property OnFileSelect: TFileSelectEvent read FOnFileSelect write FOnFileSelect;
    property OnDirChange: TDirChangeEvent read FOnDirChange write FOnDirChange;
    property SelectedItem: string read selItem write selitem;
    property SelectedItems: Tstrings read selItems write selItems;
    property FilesColorUse: boolean read usefcolor write usefcolor;
    property FilesColor: TKeyValueCollection read FFilesColor write FFilesColor ;
    procedure _startDirWatch;
    procedure _stopDirWatch;

  end;

procedure Register;

implementation

procedure Register;
begin
  {$I filelistgrid_icon.lrs}
  RegisterComponents('Misc',[TFileListGrid]);
end;

{ TKeyValueCollection }

function TKeyValueCollection.GetItem(Index: Integer): TKeyValueItem;
begin
  Result := TKeyValueItem(inherited GetItem(Index));
end;

procedure TKeyValueCollection.SetItem(Index: Integer; const Value: TKeyValueItem
  );
begin
  inherited SetItem(Index, Value);
end;

function TKeyValueCollection.Add: TKeyValueItem;
begin
  Result := TKeyValueItem(inherited Add);
end;

function TKeyValueCollection.GetItemValueByKey(Key: String): String;
var
  I: Integer;
begin
  Result := ''; // По умолчанию пустая строка, если ключ не найден
  for I := 0 to Count - 1 do
  begin
    if ((Items[I].Key = Key)and(key<>'')) then
    begin
      Result := Items[I].Value;
      Exit;
    end;
  end;
end;

function TKeyValueCollection.GetItemsCount: integer;
begin
  result:=count;
end;

{TFileListGrid}

constructor TFileListGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  //************************ LANG
  langFolderName:='<папка>';
  langByte:=' б';
  langKiloByte:=' кб';
  langMegaByte:=' мб';
  langGigaByte:=' гб';
  langGoDirError:='Ошибка доступа';
  langError:='Ошибка';
  langCell0:='Имя';
  langCell1:='Размер';
  langCell2:='Дата';
  //************************ LANG
  Parent := TWinControl(AOwner); // Устанавливаем родителя

  ColCount := 3;
  RowCount := 2;
  FixedCols := 0;

  Directory:='c:';

  Options:= Options + [goColSizing] + [goRowSelect] + [goCellEllipsis];
  Cells[0, 0] := langCell0;
  Cells[1, 0] := langCell1;
  Cells[2, 0] := langCell2;
  ColWidths[0] := 200;
  GridLineStyle := psClear;
  mouseWheelOption := mwGrid;
  font.Size:=10;
  DefaultRowHeight:=21;
  flat:=true;

  FIconFolder := TPortableNetworkGraphic.Create;
  FIconFolder.LoadFromLazarusResource('FOLDER02');

  FImageList := TImageList.Create(Self);
  FImageList.Width := 16;
  FImageList.Height := 16;
  FIconFile := TIcon.Create;
  IconManager:=TIconCacheManager.Create;

  dirlist := tstringlist.Create;

  selItems:=tstringlist.Create;

  LoadFiles;

  _ThreadStarted:=false;

  DoubleBuffered:=True;

  FFilesColor := TKeyValueCollection.Create(TKeyValueItem);

  {
  var item:TKeyValueItem;

  item:=FFilesColor.Add;
  item.Key:='.exe';
  item.Value:='$00C9A117';
  }

  with FFilesColor.Add do
  begin
     Key:='.exe';
     Value:='$00C9A117';
  end;
  with FFilesColor.Add do
  begin
     Key:='.bat';
     Value:='$00C9A117';
  end;
  with FFilesColor.Add do
  begin
     Key:='.jpg';
     Value:='$003DBE71';
  end;
  with FFilesColor.Add do
  begin
     Key:='.png';
     Value:='$003DBE71';
  end;
  with FFilesColor.Add do
  begin
     Key:='.bmp';
     Value:='$003DBE71';
  end;
  with FFilesColor.Add do
  begin
     Key:='.gif';
     Value:='$003DBE71';
  end;
  with FFilesColor.Add do
  begin
     Key:='.jpeg';
     Value:='$003DBE71';
  end;
  tmpMenuList:=tstringlist.Create;

end;

destructor TFileListGrid.Destroy;
begin
  FFilesColor.Free;

  tmpMenuList.free;

  IconManager.free;
  FIconFolder.Free;
  FIconFile.Free;

  FImageList.Free;
  dirlist.Free;
  selItems.Free;
  if _threadStarted then _stopDirWatch;
  inherited Destroy;
end;

procedure TFileListGrid.SetDirectory(Dir: string);
var
  tmp:string;
begin
  tmp:=dir;
  excludetrailingbackslash(tmp);
  if not DirectoryExists(tmp) then tmp:='c:';
  FDirectory := tmp;



  LoadFiles;
  if assigned(FOnDirChange) then FOnDirChange(self);
  if _ThreadStarted then begin
    _StopDirWatch;
    _StartDirWatch;
  end;
end;

procedure TFileListGrid.thUpdList(sender: tobject);
begin
  loadfiles;
end;

procedure TFileListGrid.thError(sender: tobject);
begin
  //showmessage('Хитрожопая ошибка обработчика');
end;

procedure TFileListGrid.runApp(path: string; cmdline: tstringlist);
var
  aprocess:tprocess;
  counter:integer;
begin
   AProcess := TProcess.Create(nil);
   try
     aProcess.InheritHandles := False;
     aProcess.Options := aProcess.Options+[poUsePipes];
     aProcess.ShowWindow := swoShow;
     for counter := 1 to GetEnvironmentVariableCount do aProcess.Environment.Add(GetEnvironmentString(counter));
     aProcess.Executable := path;
     aprocess.Parameters.AddStrings(cmdline);
     aprocess.Execute;
   except
     aProcess.Free;
   end;
end;

function TFileListGrid.getSelectedItems(var _DirList: tstringlist;
  withPath: boolean): boolean;
var
  counter:integer;
begin
   result:=false;
   if ((selectedItems.Count = 0) and ((selectedItem = '') or (selectedItem='..'))) then exit;

   _dirlist.clear;
   if selecteditems.Count > 0
   then begin
     for counter:=0 to selecteditems.Count-1 do
     if withpath
     then _dirlist.Add(IncludeTrailingPathDelimiter(Fdirectory)+selecteditems.Strings[counter])
     else _dirlist.Add(selecteditems.Strings[counter]);
     result:=true;
   end
   else begin
     if withpath
     then _dirlist.Add(IncludeTrailingPathDelimiter(Fdirectory)+selecteditem)
     else _dirlist.Add(selecteditem);
     result:=true;
   end;
end;

procedure TFileListGrid.selectAll(doselect: boolean);
var
  counter:integer;
  tmp:string;
begin
  tmp:=selectedItem;
  beginupdate;

  selitems.Clear;

  if doselect then for counter:=1 to RowCount-1 do
    if cells[0,counter]<>'..' then selItems.Add(cells[0,counter]);

  invalidate;
  endupdate;

  selectRow(findRowByText(tmp));
end;

procedure TFileListGrid._startDirWatch;
begin
  _dirWatch:=TDirectoryWatcher.Create(FDirectory);
  _dirWatch.OnChange:=@thUpdList;
  _dirWatch.OnThError:=@thError;
  _ThreadStarted:=true;
end;

procedure TFileListGrid._stopDirWatch;
begin
  if _ThreadStarted then FreeAndNil(_dirWatch);  // Освобождаем память
end;

procedure TFileListGrid.LoadFiles;
var
  Folders, Files: TStringList;
  SR: TSearchRec;
  NewRow, i, EqPos: Integer;
  FileName, FileSize, FileDate, tmp: String;
  fsize:real;
begin

  beginupdate;

  RowCount := 1;

  Folders := TStringList.Create;
  Files := TStringList.Create;
  try
    if FindFirst(FDirectory + DirectorySeparator + '*', faAnyFile, SR) = 0 then
    begin
      repeat
        if (SR.Name <> '.') {and (SR.Name <> '..')} then
        begin
          if (SR.Attr and faDirectory) <> 0 then
            Folders.Add(SR.Name)
          else
            Files.Add(SR.Name + '=' + IntToStr(SR.Size) + '=' + FormatDateTime('dd:mm:yy hh:nn:ss',FileDateToDateTime(SR.Time)));
        end;
      until FindNext(SR) <> 0;
      FindClose(SR);
    end;

    // Добавляем папки в список
    for i := 0 to Folders.Count - 1 do
    begin
      RowCount := RowCount + 1;
      NewRow := RowCount - 1;
      Cells[0, NewRow] := Folders[i];
      Cells[1, NewRow] := langFolderName;
      Cells[2, NewRow] := '';
    end;

    // Добавляем файлы в список
    for i := 0 to Files.Count - 1 do
    begin
      tmp:=Files[i];
      EqPos := Pos('=', tmp);
      if EqPos > 0 then
      begin
        FileName := Copy(tmp, 1, EqPos - 1);
        Delete(tmp, 1, EqPos);

        EqPos := Pos('=', tmp);
        FileSize := Copy(tmp, 1, EqPos - 1);

        //размер в мегабайтах
        fsize:=strtofloat(filesize);
        if fsize < 1024 then filesize:=filesize+langByte
        else if fsize < 1048576 then filesize:=floattostrf(fsize/1024,fffixed,8,2)+langKiloByte
        else if fsize < 1073741824 then filesize:=floattostrf(fsize/1048576,fffixed,8,2)+langMegaByte
        else filesize:=floattostrf(fsize/1073741824,fffixed,8,2)+langGigaByte;
        //размер в мегабайтах

        Delete(tmp, 1, EqPos);
        FileDate := tmp;
        RowCount := RowCount + 1;
        NewRow := RowCount - 1;
        Cells[0, NewRow] := FileName;
        Cells[1, NewRow] := FileSize;
        Cells[2, NewRow] := FileDate;
      end;
    end;

  finally
    Folders.Free;
    Files.Free;
  end;

  SelectRow(FindRowByText(selItem));
  endupdate;

end;


procedure TFileListGrid.AdjustColumnWidth;
var
  i, MaxWidth, TextWidth: Integer;
begin
  MaxWidth := Canvas.TextWidth('Имя');
  for i := 1 to RowCount - 1 do
  begin
    TextWidth := Canvas.TextWidth(Cells[0, i]) + 10;
    if TextWidth > MaxWidth then
      MaxWidth := TextWidth;
  end;
  ColWidths[0] := MaxWidth;
end;


procedure TFileListGrid.GetFileIcon(const FileName: string; Icon: TIcon);
var
  SHFileInfo: TSHFileInfo;
begin
  if SHGetFileInfo(PChar(FileName), 0, SHFileInfo, SizeOf(SHFileInfo), SHGFI_USEFILEATTRIBUTES or SHGFI_ICON or SHGFI_SMALLICON) <> 0 then
  begin
    Icon.Handle := SHFileInfo.hIcon;
    {$IFDEF MSWINDOWS}
    DestroyIcon(SHFileInfo.hIcon);
    {$ENDIF}
  end;
end;


function TFileListGrid.FindRowByText(const SearchText: string): integer;
var
  counter:integer;
begin
  result:=-1;
  for counter := 1 to RowCount - 1 do if UTF8CompareText(Cells[0, counter], SearchText) = 0 then begin
   Result := counter;
   Exit;
  end;
end;

procedure TFileListGrid.SelectRow(arow: Integer);
begin
  col:=1;
  if((row<>-1)and(rowcount>0)) then row:=arow;
end;

procedure TFileListGrid.clearSelected;
begin
  selitems.Clear;
  //selectedItem:='';
end;

procedure TFileListGrid.SafeDrawIcon(ACanvas: TCanvas; X, Y: Integer;
  AIcon: TIcon);
begin
  if Assigned(AIcon) and not AIcon.Empty then
    ACanvas.Draw(X, Y, AIcon);
end;

procedure TFileListGrid.DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState);
var
  tmp: string;
  i: Integer;
  CellText: string;
  r: TRect;
  offset: integer;
  FileExt: string;
  TextColor: TColor;
  IsFolder: Boolean;
  IsInsSelected: Boolean;
  FilePath: string;
begin
  // Настройка высоты строки
  if FIconFolder.Height = 20 then
  begin
    DefaultRowHeight := 22;
    offset := 2;
  end
  else
  begin
    DefaultRowHeight := 20;
    offset := 1;
  end;

  IsFolder := (ARow > 0) and (Cells[1, ARow] = langFolderName);
  IsInsSelected := (selItems.Count <> 0) and (selitems.IndexOf(Cells[0, ARow]) <> -1);

  // Определяем цвет текста для всей строки
  if IsInsSelected then
    TextColor := clRed
  else if IsFolder then
    TextColor := clBlack
  else if ((usefcolor) and (FFilesColor.GetItemsCount<>0)) then
  begin
    //цвт файлов по расширениям
    tmp := ffilescolor.GetItemValueByKey(utf8lowercase(extractfileext(Cells[0, ARow])));
    if tmp<>''
    then TextColor:=strtoint(tmp)
    else TextColor:=clBlack;

  end
  else
    TextColor := clBlack;

  // Отрисовка фона для выделенных строк
  if (gdSelected in AState) and (goRowSelect in Options) then
  begin
    //Canvas.Brush.Color := $00BAC6C7; // Цвет выделения
    Canvas.FillRect(ARect);


    // Отрисовка всей строки
    for i := 0 to ColCount - 1 do
    begin
      r := CellRect(i, ARow);
      CellText := Cells[i, ARow];

      // Устанавливаем цвет текста
      Canvas.Font.Color := TextColor;

      // Особый случай для первой колонки (с иконкой)
      if (i = 0) and (ARow > 0) then
      begin
        if IsFolder then
        begin
          // Отрисовка иконки папки
          Canvas.Draw(r.Left + 2, r.Top + 2, FIconFolder);
          Canvas.TextOut(r.Left + FIconFolder.Width + 3, r.Top + offset, CellText);
        end
        else
        begin
          // Отрисовка иконки файла
          FileExt := LowerCase(ExtractFileExt(Cells[i, ARow]));
          if (FileExt <> '.exe') and (FileExt <> '') then
            Canvas.Draw(r.Left + 2, r.Top + 2, IconManager.GetFileIcon(Cells[i, ARow]))
          else
          begin
            FilePath := FDirectory + DirectorySeparator + Cells[0, ARow];
            GetFileIcon(FilePath, FIconFile);
            Canvas.Draw(r.Left + 2, r.Top + 2, FIconFile);
          end;
          Canvas.TextOut(r.Left + FIconFolder.Width + 3, r.Top + offset, CellText);
        end;
      end
      else
      begin
        // Отрисовка обычных ячеек
        Canvas.TextOut(r.Left + 3, r.Top + offset, CellText);
      end;
    end;
  end
  else
  begin
    // Обычная отрисовка (не выделенная строка)
    inherited DrawCell(ACol, ARow, ARect, AState);

    // Отрисовка иконки и текста в первой колонке
    if (ACol = 0) and (ARow > 0) then
    begin
      canvas.clear;
      Canvas.Font.Color := TextColor;

      if IsFolder then
      begin
        Canvas.Draw(ARect.Left + 2, ARect.Top + 2, FIconFolder);
      end
      else
      begin
        FileExt := LowerCase(ExtractFileExt(Cells[ACol, ARow]));
        if (FileExt <> '.exe') and (FileExt <> '') then
          Canvas.Draw(ARect.Left + 2, ARect.Top + 2, IconManager.GetFileIcon(Cells[ACol, ARow]))
        else
        begin
          FilePath := FDirectory + DirectorySeparator + Cells[0, ARow];
          GetFileIcon(FilePath, FIconFile);
          Canvas.Draw(ARect.Left + 2, ARect.Top + 2, FIconFile);
        end;
      end;
      Canvas.TextOut(ARect.Left + FIconFolder.Width + 3, ARect.Top + offset, Cells[ACol, ARow]);
    end
    else if (ARow > 0) then
    begin
      // Отрисовка текста в других колонках
      Canvas.Font.Color := TextColor;
      Canvas.TextOut(ARect.Left + 3, ARect.Top + offset, Cells[ACol, ARow]);
    end;
  end;
end;

procedure TFileListGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  ACol, ARow: Integer;
  CellR: TRect;
begin
  inherited;

  if Button = mbRight then
  begin
    MouseToCell(X, Y, ACol, ARow);

    // Получаем реальные границы ячейки
    if (ARow >= FixedRows) and (ARow < RowCount) then
      CellR := CellRect(ACol, ARow)
    else
      CellR := Rect(0, 0, 0, 0);

    // Проверяем, что клик был внутри реальных границ ячейки
    if (ARow >= FixedRows) and (ARow < RowCount) and
       PtInRect(CellR, Point(X, Y)) then
    begin
      Row := ARow;
      getSelectedItems(tmpMenuList,true);
      ShowWindowsContextMenu(handle,tmpMenuList, X, Y);
    end
    else
    begin
      tmpMenuList.Clear;
      tmpMenuList.Add(FDirectory);
      ShowWindowsContextMenu(handle,tmpMenuList, X, Y);
    end;
  end;
end;


procedure TFileListGrid.DblClick;
var
  AProcess: TProcess;
  i:integer;
begin
  if (Row > 0) then
  begin
    if Cells[0, Row] = '..' then begin
      lvlUp;

    end
    else if DirectoryExists(FDirectory + DirectorySeparator + Cells[0, Row]) then begin
      dirlist.Add(Cells[0, Row]);
      SetDirectory(FDirectory + DirectorySeparator + Cells[0, Row]); // Открытие папки
      //**************** ошибки перехода
      if FileGetAttr(FDirectory + DirectorySeparator + Cells[0, Row]) < 0
      then begin
        if MessageDlg(langError, langGoDirError, mtError, [mbOk], 0) = mrOk then lvlUp;
      end;
      clearSelected;
    end
    else begin
       AProcess := TProcess.Create(nil);
       try
        aProcess.InheritHandles := False;
        aProcess.Options := aProcess.Options+[poUsePipes];
        aProcess.ShowWindow := swoShow;
        for I := 1 to GetEnvironmentVariableCount do aProcess.Environment.Add(GetEnvironmentString(I));
        aProcess.Executable := FDirectory + DirectorySeparator + Cells[0, Row];
        aprocess.Execute;
        except
          aProcess.Free;
          opendocument(FDirectory + DirectorySeparator + Cells[0, Row]);
        end;
    end;
  end;
end;


procedure TFileListGrid.Click;
begin
  inherited Click;
  if rowcount > 1 then selItem := Cells[0, Row];
  if (Assigned(FOnFileSelect)and(fileexists(FDirectory + DirectorySeparator + Cells[0, Row]))) then FOnFileSelect(Self, FDirectory + DirectorySeparator + Cells[0, Row]); // Выбор файла
end;

procedure TFileListGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  case key of
    VK_RETURN:dblclick;
    VK_UP:click;
    VK_DOWN:click;
    VK_INSERT:begin
      if ((selItems.Count<>0)and(selitems.IndexOf(selitem) <> -1)) then begin
        selitems.Delete(selitems.IndexOf(selitem));
        invalidate; //обновление ячеек
        selectrow(FindRowByText(selitem)+1);
      end else begin
        if ((selitem<>'..') and (selitem<>FDirectory)) then begin
          selitems.Add(selItem);
          invalidate;
          selectrow(FindRowByText(selitem)+1);
        end;
      end;
    end;
    VK_MULTIPLY:if selectedItems.Count = 0 then selectAll(true) else selectAll(false);
  end;
end;

procedure TFileListGrid.RefreshList;
begin
  loadFiles;
end;

procedure TFileListGrid.lvlUp;
begin
   fdirectory:=excludetrailingbackslash(fdirectory);
   delete(fdirectory,fdirectory.LastIndexOf('\')+1,length(fdirectory)-fdirectory.LastIndexOf('\')+1);
   if fdirectory<>'' then SetDirectory(ExcludeTrailingBackSlash(FDirectory)); // Переход на уровень выше
   if dirlist.Count<>0 then begin
     selectrow(FindRowByText(dirlist.Strings[dirlist.Count-1]));
     dirlist.Delete(dirlist.Count-1);
   end;
   clearselected;
end;


initialization
{$I img.lrs}

end.
