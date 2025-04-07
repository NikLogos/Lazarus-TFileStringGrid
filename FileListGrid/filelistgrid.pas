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


{
function FileIsSymlink(const AFilename: string): boolean;
function FileIsHardLink(const AFilename: string): boolean;
}
unit FileListGrid;

{$mode objfpc}{$H+}


interface


uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, LResources,
  shellapi, process, LazUTF8, LCLType, LCLIntf, {dirmon,} dirmonW, fileutil,
  iconCacheManager, dateutils, cmenu, LazFileUtils{, shlobj, windows};

const
  IID_IContextMenu2: TGUID = '{000214F4-0000-0000-C000-000000000046}';
  IID_IContextMenu3: TGUID = '{BCFCE0A0-EC17-11D0-8D10-00A0C90F2719}';

type
  TGridRow = array[0..2] of string;  // Одна строка данных (имя, размер, дата)
  TGridData = array of TGridRow;     // Массив строк данных

  //TSortFile = (smNone, smFolder, smDate, smName, smExt, smSize, smRevDate, smRevName, smRevExt, smRevSize);
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

  TSortMode = (smNone, smNameAsc, smNameDesc, smSizeAsc, smSizeDesc, smDateAsc, smDateDesc);

  { TKeyValueCollection }

  TKeyValueCollection = class(TCollection)
  private
    //function GetItem(Index: Integer): TKeyValueItem;
    procedure SetItem(Index: Integer; const Value: TKeyValueItem);
  public
    function Add: TKeyValueItem;
    function GetItem(Index: Integer): TKeyValueItem;
    function GetItemValueByKey(Key: String): String;
    function GetItemIndexByKey(Key: String): integer;
    function GetItemsCount:integer;
    procedure Clear;
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
    langTeraByte:string;
    langGoDirError:string;
    langError:string;
    langCell0:string;
    langCell1:string;
    langCell2:string;
    langLoadData:string;
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

    FIconAsk: TPortableNetworkGraphic;
    FIconDesk: TPortableNetworkGraphic;

    FImageList: TImageList;
    DirList:tstringlist;

    _DirWatch:TDirectoryWatcher;
    _ThreadStarted:boolean;

    tmpMenuList:tstringlist;

    FLastSortColumn: Integer;
    FLastSortMode: TSortMode;

    showHidden:boolean;
    showSys:boolean;

    procedure LoadFiles;
    function FileIsHidden(const FileName: string): Boolean;
    function FileIsSystem(const FileName: string): Boolean;

    procedure SortFiles(SortMode: TSortMode);
    procedure AdjustColumnWidth;
    procedure GetFileIcon(const FileName: string; Icon: TIcon);
    function FindRowByText(const SearchText: string): integer;
    procedure SelectRow(arow: Integer);
    procedure clearSelected;

    function itbs(path:string):string;

    function ParseDate(DateStr: string): TDateTime;
    function ParseSize(SizeStr: string): Int64;

  protected
    procedure DblClick; override;
    procedure Click; override;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
    procedure DrawCell(ACol, ARow: Longint; ARect: TRect; AState: TGridDrawState); override;
    procedure DrawSortIcon(ACol: Integer; AIcon: TPortableNetworkGraphic);

    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

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
    procedure _startDirWatch;
    procedure _stopDirWatch;
    function SortModeToStr(SortMode: TSortMode): string;
    function StrToSortMode(const Str: string): TSortMode;
    procedure SetSortMode(SortMode:TSortMode);

  published
    property Directory: string read FDirectory write SetDirectory;
    property OnFileSelect: TFileSelectEvent read FOnFileSelect write FOnFileSelect;
    property OnDirChange: TDirChangeEvent read FOnDirChange write FOnDirChange;
    property SelectedItem: string read selItem write selitem;
    property SelectedItems: Tstrings read selItems write selItems;
    property FilesColorUse: boolean read usefcolor write usefcolor;
    property FilesColor: TKeyValueCollection read FFilesColor write FFilesColor;
    property SortMode: TSortMode read FLastSortMode write SetSortMode;
    property FilesShowHidden: boolean read showHidden write showHidden;
    property FilesShowSys: boolean read showSys write showSys;


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

function TKeyValueCollection.GetItemIndexByKey(Key: String): integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
  begin
    if ((Items[I].Key = Key)and(key<>'')) then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

function TKeyValueCollection.GetItemsCount: integer;
begin
  result:=count;
end;

procedure TKeyValueCollection.Clear;
begin
  inherited clear;
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
  langTeraByte:=' тб';
  langGoDirError:='Ошибка доступа';
  langError:='Ошибка';
  langCell0:='Имя';
  langCell1:='Размер';
  langCell2:='Дата';
  langLoadData:='Чтение каталога';
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
  FIconFolder.LoadFromLazarusResource('FOLDER');

  FIconAsk := TPortableNetworkGraphic.Create;
  FIconDesk := TPortableNetworkGraphic.Create;

  FIconAsk.LoadFromLazarusResource('ASK');
  FIconDesk.LoadFromLazarusResource('DESK');


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
  with FFilesColor.Add do
  begin
     Key:='bgcolor';
     Value:='$00E6EEF0';
  end;
  with FFilesColor.Add do
  begin
     Key:='.sys';
     Value:='4734874';
  end;
  with FFilesColor.Add do
  begin
     Key:='system';
     Value:='4734874';
  end;
   with FFilesColor.Add do
  begin
     Key:='hidden';
     Value:='10725807';
  end;

  tmpMenuList:=tstringlist.Create;

  FLastSortMode:=smNameAsc;
  FLastSortColumn:=-1;

  showHidden:=false;
  showSys:=false;
end;

destructor TFileListGrid.Destroy;
begin
  FFilesColor.Free;

  tmpMenuList.free;

  FIconAsk.Free;
  FIconDesk.Free;
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
  {
  cells[0,0]:=langLoadData;
  cells[0,0]:=langCell0;
  application.ProcessMessages;
  }

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
//  showmessage('Хитрожопая ошибка обработчика');
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
     selectAll(false);
     result:=true;
   end
   else begin
     if withpath
     then _dirlist.Add(IncludeTrailingPathDelimiter(Fdirectory)+selecteditem)
     else _dirlist.Add(selecteditem);
     selectAll(false);
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

{
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
}


procedure TFileListGrid.AdjustColumnWidth;
var
  i, MaxWidth, TextWidth: Integer;
begin
  MaxWidth := Canvas.TextWidth(langCell0);
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

end;

function TFileListGrid.itbs(path: string): string;
begin
  result:=includetrailingbackslash(path);
end;

procedure TFileListGrid.SortFiles(SortMode: TSortMode);
var
  TempData: TGridData;
  i: Integer;

  // Функция сравнения с учетом всех требований
  function CompareRows(const Row1, Row2: TGridRow): Integer;
  var
    IsFolder1, IsFolder2: Boolean;
    Size1, Size2: Int64;
    Date1, Date2: TDateTime;
  begin
    // 1. Папка ".." всегда первая
    if Row1[0] = '..' then Exit(-1);
    if Row2[0] = '..' then Exit(1);

    // 2. Определяем тип элементов (папка/файл)
    IsFolder1 := (Row1[1] = langFolderName);
    IsFolder2 := (Row2[1] = langFolderName);

    // 3. Все папки идут перед файлами
    if IsFolder1 and not IsFolder2 then Exit(-1);
    if IsFolder2 and not IsFolder1 then Exit(1);

    // 4. Сравнение в зависимости от режима сортировки
    case SortMode of
      smNameAsc:  Result := UTF8CompareText(Row1[0], Row2[0]);
      smNameDesc: Result := -UTF8CompareText(Row1[0], Row2[0]);

      smSizeAsc, smSizeDesc:
      begin
        if IsFolder1 then
          // Для папок при сортировке по размеру используем сортировку по имени
          Result := UTF8CompareText(Row1[0], Row2[0])
        else
        begin
          // Для файлов - сортируем по размеру
          Size1 := ParseSize(Row1[1]);
          Size2 := ParseSize(Row2[1]);
          if Size1 < Size2 then Result := -1
          else if Size1 > Size2 then Result := 1
          else Result := UTF8CompareText(Row1[0], Row2[0]);

          if SortMode = smSizeDesc then Result := -Result;
        end;
      end;

      smDateAsc, smDateDesc:
      begin
        // Для всех элементов (и папок и файлов) используем сортировку по дате
        Date1 := ParseDate(Row1[2]);
        Date2 := ParseDate(Row2[2]);

        if Date1 < Date2 then Result := -1
        else if Date1 > Date2 then Result := 1
        else Result := UTF8CompareText(Row1[0], Row2[0]);

        if SortMode = smDateDesc then Result := -Result;
      end;
    else
      Result := 0;
    end;
  end;

  // Реализация QuickSort
  procedure QuickSort(var AData: TGridData; L, R: Integer);
  var
    I, J: Integer;
    Pivot: TGridRow;
    Temp: TGridRow;
  begin
    if L >= R then Exit;

    Pivot := AData[(L + R) div 2];
    I := L;
    J := R;

    repeat
      while CompareRows(AData[I], Pivot) < 0 do Inc(I);
      while CompareRows(AData[J], Pivot) > 0 do Dec(J);

      if I <= J then
      begin
        // Обмен строк
        Temp := AData[I];
        AData[I] := AData[J];
        AData[J] := Temp;

        Inc(I);
        Dec(J);
      end;
    until I > J;

    if L < J then QuickSort(AData, L, J);
    if I < R then QuickSort(AData, I, R);
  end;

begin

  FLastSortMode := SortMode;

  if RowCount <= 2 then Exit;

  // 1. Копируем данные во временный массив
  SetLength(TempData, RowCount - 1);
  for i := 1 to RowCount - 1 do
  begin
    TempData[i-1][0] := Cells[0, i];
    TempData[i-1][1] := Cells[1, i];
    TempData[i-1][2] := Cells[2, i];
  end;

  // 2. Сортируем данные
  if Length(TempData) > 1 then
    QuickSort(TempData, 0, High(TempData));

  // 3. Обновляем грид
  BeginUpdate;
  try
    for i := 1 to RowCount - 1 do
    begin
      Cells[0, i] := TempData[i-1][0];
      Cells[1, i] := TempData[i-1][1];
      Cells[2, i] := TempData[i-1][2];
    end;
  finally
    EndUpdate;
  end;

  // 4. Восстанавливаем выделение
  if selItem <> '' then
    SelectRow(FindRowByText(selItem));
end;


function TFileListGrid.ParseSize(SizeStr: string): Int64;
var
  NumStr: string;
  SizeUnit: string;
  Value: Double;
begin
  Result := 0;
  //SizeStr := UTF8StringReplace(SizeStr, ' ', '', [rfReplaceAll]);

  if SizeStr = langFolderName then
    Exit(0);
  if UTF8Pos(langByte, SizeStr) > 0 then
  begin
    NumStr := UTF8StringReplace(SizeStr, langByte, '', [rfReplaceAll]);
    SizeUnit := langByte;
  end
  else if UTF8Pos(langKiloByte, SizeStr) > 0 then
  begin
    NumStr := UTF8StringReplace(SizeStr, langKiloByte, '', [rfReplaceAll]);
    SizeUnit := langKiloByte;
  end
  else if UTF8Pos(langMegaByte, SizeStr) > 0 then
  begin
    NumStr := UTF8StringReplace(SizeStr, langMegaByte, '', [rfReplaceAll]);
    SizeUnit := langMegaByte;
  end
  else if UTF8Pos(langGigaByte, SizeStr) > 0 then
  begin
    NumStr := UTF8StringReplace(SizeStr, langGigaByte, '', [rfReplaceAll]);
    SizeUnit := langGigaByte;
  end
  else if UTF8Pos(langTeraByte, SizeStr) > 0 then
  begin
    NumStr := UTF8StringReplace(SizeStr, langTeraByte, '', [rfReplaceAll]);
    SizeUnit := langTeraByte;
  end
  else begin
    Exit(0);
  end;

  if TryStrToFloat(NumStr, Value) then
  begin
    if SizeUnit = langByte then
      Result := Round(Value)
    else if SizeUnit = langKiloByte then
      Result := Round(Value * 1024)
    else if SizeUnit = langMegaByte then
      Result := Round(Value * 1024 * 1024)
    else if SizeUnit = langGigaByte then
      Result := Round(Value * 1024 * 1024 * 1024)
    else if SizeUnit = langTeraByte then
      Result := Round(Value * 1024 * 1024 * 1024 * 1024);
  end;
end;

function TFileListGrid.SortModeToStr(SortMode: TSortMode): string;
begin
  case SortMode of
    smNone:     Result := 'smNone';
    smNameAsc:  Result := 'smNameAsc';
    smNameDesc: Result := 'smNameDesc';
    smSizeAsc:  Result := 'smSizeAsc';
    smSizeDesc: Result := 'smSizeDesc';
    smDateAsc:  Result := 'smDateAsc';
    smDateDesc: Result := 'smDateDesc';
  else
    Result := 'smNone';
  end;
end;


function TFileListGrid.StrToSortMode(const Str: string): TSortMode;
begin
  if Str = 'smNone' then Result := smNone
  else if Str = 'smNameAsc'  then Result := smNameAsc
  else if Str = 'smNameDesc' then Result := smNameDesc
  else if Str = 'smSizeAsc'  then Result := smSizeAsc
  else if Str = 'smSizeDesc' then Result := smSizeDesc
  else if Str = 'smDateAsc'  then Result := smDateAsc
  else if Str = 'smDateDesc' then Result := smDateDesc
  else Result := smNone;
end;

procedure TFileListGrid.SetSortMode(SortMode: TSortMode);
begin
  FLastSortMode := SortMode;

  case SortMode of
    smNameAsc, smNameDesc: FLastSortColumn := 0;
    smSizeAsc, smSizeDesc: FLastSortColumn := 1;
    smDateAsc, smDateDesc: FLastSortColumn := 2;
  else
    FLastSortColumn := -1;
  end;

  SortFiles(SortMode);
  Invalidate;
end;

function TFileListGrid.ParseDate(DateStr: string): TDateTime;
var
  Day, Month, Year, Hour, Min, Sec: Word;
begin
  Result := 0;
  if DateStr = '' then Exit;

  try
    result:=scanDateTime('dd mmm yyyy hh:nn',DateStr);
  except
    Result := 0;
  end;
end;

procedure TFileListGrid.LoadFiles;
var
  Folders, Files: TStringList;
  SR: TSearchRec;
  NewRow, i, EqPos: Integer;
  FileName, FileSize, FileDate, tmp: String;
  fsize: real;

  //FileAttr: Integer;

  function ShouldSkipFile: Boolean;
  begin
    Result := False;
    if (not ShowHidden) and ((SR.Attr and faHidden) <> 0) then Result := True;
    if (not ShowSys) and ((SR.Attr and faSysFile) <> 0) then Result := True;
  end;

begin
  BeginUpdate;
  try
    RowCount := 1;

    Folders := TStringList.Create;
    Files := TStringList.Create;
    try
      if FindFirst(FDirectory + DirectorySeparator + '*', faAnyFile, SR) = 0 then
      begin
        repeat
          if (SR.Name <> '.') and (SR.Name<>'..') then
          begin
            // Пропускаем файлы/папки в зависимости от настроек
            if ShouldSkipFile then Continue;

            if (SR.Attr and faDirectory) <> 0 then
              Folders.Add(SR.Name + '=' + IntToStr(0) + '=' + FormatDateTime('dd mmm yyyy hh:nn', FileDateToDateTime(SR.Time)))
            else
              Files.Add(SR.Name + '=' + IntToStr(SR.Size) + '=' + FormatDateTime('dd mmm yyyy hh:nn', FileDateToDateTime(SR.Time)))
          end
          else if SR.Name = '..' then
               begin
                 // Всегда добавляем родительскую директорию, независимо от настроек
                 Folders.Add(SR.Name + '=' + '' + '=' + FormatDateTime('dd mmm yyyy hh:nn', FileDateToDateTime(SR.Time)));
               end;
        until FindNext(SR) <> 0;
        FindClose(SR);
      end;

      // Добавляем папки в список
      for i := 0 to Folders.Count - 1 do
      begin
        tmp := Folders[i];
        EqPos := Pos('=', tmp);
        if EqPos > 0 then
        begin
          FileName := Copy(tmp, 1, EqPos - 1);
          Delete(tmp, 1, EqPos);

          EqPos := Pos('=', tmp);
          FileSize := Copy(tmp, 1, EqPos - 1);
          Delete(tmp, 1, EqPos);
          FileDate := tmp;

          RowCount := RowCount + 1;
          NewRow := RowCount - 1;
          Cells[0, NewRow] := FileName;
          Cells[1, NewRow] := langFolderName;
          Cells[2, NewRow] := FileDate; // Теперь для папок тоже выводится дата
        end;
      end;

      // Добавляем файлы в список
      for i := 0 to Files.Count - 1 do
      begin
        tmp := Files[i];
        EqPos := Pos('=', tmp);
        if EqPos > 0 then
        begin
          FileName := Copy(tmp, 1, EqPos - 1);
          Delete(tmp, 1, EqPos);

          EqPos := Pos('=', tmp);
          FileSize := Copy(tmp, 1, EqPos - 1);

          // Преобразование размера
          fsize := StrToFloat(FileSize);
          if fsize < 1024 then
            FileSize := FileSize + langByte
          else if fsize < 1048576 then
            FileSize := FloatToStrF(fsize/1024, ffFixed, 8, 2) + langKiloByte
          else if fsize < 1073741824 then
            FileSize := FloatToStrF(fsize/1048576, ffFixed, 8, 2) + langMegaByte
          else
            FileSize := FloatToStrF(fsize/1073741824, ffFixed, 8, 2) + langGigaByte;

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

    sortFiles(FLastSortMode);
    SelectRow(FindRowByText(selItem));
  finally
    EndUpdate;
  end;

end;

function TFileListGrid.FileIsHidden(const FileName: string): Boolean;
var
  Attr: Integer;
begin
  Attr := FileGetAttr(FileName);
  Result := (Attr <> -1) and ((Attr and faHidden) <> 0);
end;

function TFileListGrid.FileIsSystem(const FileName: string): Boolean;

var
  Attr: Integer;
begin
  Attr := FileGetAttr(FileName);
  Result := (Attr <> -1) and ((Attr and faSysFile) <> 0);
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

  Icon: TPortableNetworkGraphic;

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

  {
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
  }

  if IsInsSelected then
  TextColor := clRed
  {else if IsFolder then
    TextColor := clBlack}
  else if (usefcolor) and (FFilesColor.GetItemsCount <> 0) then
  begin
    // Проверяем сначала атрибуты файла (системные/скрытые)
    FilePath := itbs(FDirectory) + Cells[0, ARow];

    //if FileExists(FilePath) or DirectoryExists(FilePath) then // Для обеспечения безопасности перед проверкой атрибутов
    //но, по идее, они не могут попасть в список. если оне не существуют
    if Cells[0, ARow] = '..' then TextColor:=clBlack else
    begin
      // Проверка на скрытый/системный файл
      if (ShowSys) and (FileIsSystem(FilePath)) then
      begin
        tmp := ffilescolor.GetItemValueByKey('system');
        if tmp <> '' then TextColor := StrToInt(tmp);
      end
      else if (ShowHidden) and (FileIsHidden(FilePath)) then
      begin
        tmp := ffilescolor.GetItemValueByKey('hidden');
        if tmp <> '' then TextColor := StrToInt(tmp);
      end
      // Если не системный и не скрытый, или если такие показываются - проверяем по расширению
      else
      begin
        tmp := ffilescolor.GetItemValueByKey(UTF8LowerCase(ExtractFileExt(Cells[0, ARow])));
        if tmp <> '' then
          TextColor := StrToInt(tmp);
      end;
    end;

  // Если цвет не был установлен - черный по умолчанию
  // TextColor := clBlack;

  end;
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

  { Отображение значка сортировки в заголовке при запуске }
  if (ARow = 0) and (ACol = FLastSortColumn) and (FLastSortMode <> smNone) then
  begin
    if FLastSortMode in [smNameAsc, smSizeAsc, smDateAsc] then
      Icon := FIconAsk  // Стрелка вверх
    else
      Icon := FIconDesk; // Стрелка вниз

    DrawSortIcon(ACol, Icon);
  end;
end;

procedure TFileListGrid.DrawSortIcon(ACol: Integer;
  AIcon: TPortableNetworkGraphic);
var
  Rect: TRect;
begin
  Rect := CellRect(ACol, 0);
  Canvas.Draw(
    Rect.Right - AIcon.Width - 5,
    Rect.Top + (Rect.Height - AIcon.Height) div 2,
    AIcon
  );
end;

procedure TFileListGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  ACol, ARow: Integer;
  CellR: TRect;
  NewSortMode: TSortMode;
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

  //сортировка
  if Button = mbLeft then
  begin
    MouseToCell(X, Y, ACol, ARow);
    if ARow = 0 then // Клик по заголовку
    begin
      case ACol of
        0: // Сортировка по имени
        begin
          if FLastSortColumn = 0 then
          begin
            if FLastSortMode = smNameAsc then
              NewSortMode := smNameDesc
            else
              NewSortMode := smNameAsc;
          end
          else
            NewSortMode := smNameAsc;
        end;

        1: // Сортировка по размеру
        begin
          if FLastSortColumn = 1 then
          begin
            if FLastSortMode = smSizeAsc then
              NewSortMode := smSizeDesc
            else
              NewSortMode := smSizeAsc;
          end
          else
            NewSortMode := smSizeAsc;
        end;

        2: // Сортировка по дате
        begin
          if FLastSortColumn = 2 then
          begin
            if FLastSortMode = smDateAsc then
              NewSortMode := smDateDesc
            else
              NewSortMode := smDateAsc;
          end
          else
            NewSortMode := smDateAsc;
        end;
      else
        Exit;
      end;

      FLastSortColumn := ACol;
      FLastSortMode := NewSortMode;
      //SortFiles(NewSortMode);
      LoadFiles;
    end;
  end;
end;

procedure TFileListGrid.DblClick;
var
  AProcess: TProcess;
  i:integer;

  ClickPoint: TPoint;
  ACol, ARow: Integer;
begin
  // Получаем координаты клика
  ClickPoint := ScreenToClient(Mouse.CursorPos);
  MouseToCell(ClickPoint.X, ClickPoint.Y, ACol, ARow);

  // Если кликнули по заголовку (ARow = 0) - ничего не делаем
  if ARow = 0 then Exit;

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
       if FileIsExecutable(itbs(FDirectory)+Cells[0, Row]) then begin
         AProcess := TProcess.Create(nil);
         try
           try
            aProcess.InheritHandles := False;
            aProcess.Options := aProcess.Options+[poUsePipes];
            aProcess.ShowWindow := swoShow;
            for I := 1 to GetEnvironmentVariableCount do aProcess.Environment.Add(GetEnvironmentString(I));
            aProcess.Executable := FDirectory + DirectorySeparator + Cells[0, Row];
            aprocess.Execute;
           except
              on E: exception do opendocument(itbs(FDirectory)+Cells[0, Row])
           end;
         finally
           aprocess.Free;
         end;
      end;
    end;
  end;
end;

procedure TFileListGrid.Click;
begin
  inherited Click;
  if rowcount > 1 then selItem := Cells[0, Row];

  if (Assigned(FOnFileSelect)and(fileexists(FDirectory + DirectorySeparator + Cells[0, Row])))
  then FOnFileSelect(Self, FDirectory + DirectorySeparator + Cells[0, Row]); // Выбор файла
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
