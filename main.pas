unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, XPMan, RegExpr, PerlRegEx, Grids, Math, VistaAltFixUnit;

type
  TArrayOfFuctionalParts = array of String;
  TFormMetrick = class(TForm)
    XPManifest: TXPManifest;
    ButtonOpenFile: TButton;
    GroupBoxInputText: TGroupBox;
    MemoInputText: TMemo;
    GroupBoxResult: TGroupBox;
    ButtonClearAll: TButton;
    ButtonExecut: TButton;
    ButtonSaveInputText: TButton;
    StringGridMetrick: TStringGrid;
    LabelMetric: TLabel;
    StringGridOperators: TStringGrid;
    LabelOperators: TLabel;
    LabelOperands: TLabel;
    StringGridOperands: TStringGrid;
    VistaAltFix: TVistaAltFix;
    procedure ButtonOpenFileClick(Sender: TObject);
    procedure ButtonClearInputTextClick(Sender: TObject);
    procedure ButtonClearAllClick(Sender: TObject);
    procedure ButtonExecutClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MemoInputTextChange(Sender: TObject);
    procedure ButtonSaveInputTextClick(Sender: TObject);
  private
    procedure FillingStringGrid();
    procedure ClearStringGrid();
    procedure DeleteExpressions(var inputText: string; searchExpression: string);
    procedure FormattingText(var inputText: string; var arrayFunctionalParts: TArrayOfFuctionalParts);
    procedure FindingExpressions(searchExpression: String; var inputText: String; var StringGrid: TStringGrid; otherFunction: Boolean);
    procedure Finding(var inputText: string);
    procedure CalculationValues();
    procedure CorrectExpression(var expression: String);
    procedure PartitionOnFunctionalParts(var inputText: String; searchExpression: String; var arrayFunctionalParts: TArrayOfFuctionalParts);
    procedure AddInStringGrid(RowCountInStart: integer; expression: String; StringGrid: TStringGrid);
  public
    { Public declarations }
  end;

var
  FormMetrick: TFormMetrick;

implementation

{$R *.dfm}

procedure TFormMetrick.FormCreate(Sender: TObject);
begin
  FillingStringGrid();
end;

procedure TFormMetrick.ButtonOpenFileClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
begin
  OpenDialog := TOpenDialog.Create(Self);
  OpenDialog.DefaultExt := GetCurrentDir;
  OpenDialog.Filter := 'Java code|*.java|Java Script|*.js|Text file|*.txt|Word file|*.doc|Word file (2013)|*.docx';
  OpenDialog.FilterIndex := 1;
  OpenDialog.Options := [ofFileMustExist];
  if OpenDialog.Execute then
  begin
    MemoInputText.Clear;
    MemoInputText.Lines.LoadFromFile(OpenDialog.FileName);
  end
  else
    MessageBox(0, '�������� ����� ��������!', '�������� �����', MB_OK + MB_TOPMOST + MB_ICONERROR);
  OpenDialog.Free();
end;

procedure TFormMetrick.MemoInputTextChange(Sender: TObject);
begin
  ClearStringGrid();
end;

procedure TFormMetrick.ButtonSaveInputTextClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
begin
  SaveDialog := TSaveDialog.Create(Self);
  SaveDialog.DefaultExt := GetCurrentDir;
  SaveDialog.Filter := 'Java code|*.java|Java Script|*.js|Text file|*.txt|Word file|*.doc|Word file (2013)|*.docx';
  SaveDialog.FilterIndex := 1;
  if SaveDialog.Execute then
  begin
    MemoInputText.Lines.SaveToFile(SaveDialog.FileName);
    Application.MessageBox(SaveDialog.Files.GetText, '���������� �����', MB_OK + MB_TOPMOST + MB_ICONASTERISK);
  end
  else
    MessageBox(0, '���������� ����� ��������!', '���������� �����', MB_OK + MB_TOPMOST + MB_ICONERROR);
  SaveDialog.Free();
end;

procedure TFormMetrick.ButtonClearInputTextClick(Sender: TObject);
begin
  MemoInputText.Clear;
end;

procedure TFormMetrick.ClearStringGrid();
var
  i: integer;
begin
  for i := 1 to StringGridMetrick.RowCount - 1 do
    StringGridMetrick.Cells[2, i] := '';
  for i := 1 to StringGridOperators.RowCount - 1 do
  begin
    StringGridOperators.Cells[0, i] := '';
    StringGridOperators.Cells[1, i] := '';
  end;
  for i := 1 to StringGridOperands.RowCount - 1 do
  begin
    StringGridOperands.Cells[0, i] := '';
    StringGridOperands.Cells[1, i] := '';
  end;
  StringGridOperators.RowCount := 2;
  StringGridOperands.RowCount := 2;
end;

procedure TFormMetrick.ButtonClearAllClick(Sender: TObject);
begin
  MemoInputText.Clear;
  ClearStringGrid();
end;

procedure TFormMetrick.FillingStringGrid();
const
  PRECENTAGE_FIRST_COLUMN: real = 0.52;
  PRECENTAGE_SECOND_COLUMN: real = 0.33;
  AMOUNT_ROW: byte = 5;
begin
  StringGridOperators.Cells[0, 0] := '��������';
  StringGridOperators.Cells[1, 0] := '����������';
  StringGridOperators.Height := StringGridOperators.DefaultRowHeight * AMOUNT_ROW;
  StringGridOperands.Height := StringGridOperands.DefaultRowHeight * AMOUNT_ROW;
  StringGridOperands.Cells[0, 0] := '�������';
  StringGridOperands.Cells[1, 0] := '����������';
  with StringGridMetrick do
  begin
    ColWidths[0] := round(Width * PRECENTAGE_FIRST_COLUMN);
    ColWidths[1] := round(Width * PRECENTAGE_SECOND_COLUMN);
    ColWidths[2] := round(Width * (1 - PRECENTAGE_FIRST_COLUMN - PRECENTAGE_SECOND_COLUMN));
    Cells[0, 0] := '��������������';
    Cells[1, 0] := '�����������';
    Cells[2, 0] := '���������';
    Cells[0,1] := '���������� ���������� ����������';
    Cells[1,1] := 'n1';
    Cells[0,2] := '���������� ���������� ���������';
    Cells[1,2] := 'n2';
    Cells[0,3] := '����� ���������� ����������';
    Cells[1,3] := 'N1';
    Cells[0,4] := '����� ���������� ���������';
    Cells[1,4] := 'N2';
    Cells[0,5] := '������� ���������';
    Cells[1,5] := 'n = n1 + n2';
    Cells[0,6] := '����� ���������';
    Cells[1,6] := 'N = N1 + N2';
    Cells[0,7] := '����� ���������';
    Cells[1,7] := 'V = N*Log2(n)';
    Cells[0,8] := '������������� ����� ���������';
    Cells[1,8] := 'V* = n*log2(n)';
    Cells[0,9] := '������������� ����� ���������';
    Cells[1,9] := 'N^ = n1*log2(n1) + n2*log2(n2)';
    Cells[0,10] := '������� ���������';
    Cells[1,10] := 'L = V* / V';
    Cells[0,11] := '������� ���������[2]';
    Cells[1,11] := 'L^ = 2 * n2 / (n1 * N2)';
    Cells[0,12] := '���������������� ������������ ���������';
    Cells[1,12] := 'I = L^ * V';
    Cells[0,13] := '����� ��������� ���������������� �������';
    Cells[1,13] := 'E = N^ * log2(n / L)';
    Cells[0,14] := '�������� ����� ���������';
    Cells[1,14] := 'E'' = V * V / V* ';
  end;
end;

procedure TFormMetrick.DeleteExpressions(var inputText: String; searchExpression: String);
var
  RegExpr: TPerlRegEx;
begin
  RegExpr := TPerlRegEx.Create;
  RegExpr.Options := [preSingleLine, preMultiLine];
  RegExpr.RegEx := searchExpression;
  RegExpr.Subject := inputText;
  RegExpr.Compile;
  if (RegExpr.Match) then
  begin
    RegExpr.Replacement := ' ';
    repeat
      RegExpr.ReplaceAll;
    until (not RegExpr.MatchAgain);
    inputText := RegExpr.Subject;
  end;
  RegExpr.Destroy;
end;

procedure TFormMetrick.FormattingText(var inputText: string; var arrayFunctionalParts: TArrayOfFuctionalParts);
const
  REGEX_COMMENTS = '(\/\*.*?\*\/)|(\/\/.*?\n)';
  REGEX_IMPORTED_FILES = '((?<=import)[^\n\r]*)';
  REGEX_PARTITION_JAVA = '(\b(public\s*|private\s*|protected\s*)?(static\s*|final\s*)?([Ll]ist|class|char|int|long|String|float|double|boolean|void)\s*[\w]*\s*?(\([^\{\;]*?)?{)';
  REGEX_PARTITION_JAVASCRIPT = '((var(?!\w)\s+[\w]+\s+=\s+function\([^\{\;]*?{)|([\w.]+\s+=\s+function\([^\{\;]*?{)|(function\s\$?[\w]+\([^\{\;]*?{)|([\w]+\s*?:\s*?function\([^\{\;]*?{))';
begin
  DeleteExpressions(inputText, REGEX_COMMENTS);
  DeleteExpressions(inputText, REGEX_IMPORTED_FILES);
  PartitionOnFunctionalParts(inputText, REGEX_PARTITION_JAVA, arrayFunctionalParts);
  PartitionOnFunctionalParts(inputText, REGEX_PARTITION_JAVASCRIPT, arrayFunctionalParts);
end;

procedure TFormMetrick.CorrectExpression(var expression: String);
begin
  if (expression[Length(expression)] = '(') then  // ��� ������ ������� ������������ ����������� ���� func(
    Delete(expression, length(expression), 1);
  if (expression = 'do') then                     // ����������� ���������� ��������� do �� do while
    expression := expression + ' while';
end;

procedure TFormMetrick.PartitionOnFunctionalParts(var inputText: String; searchExpression: String; var arrayFunctionalParts: TArrayOfFuctionalParts);
var
  RegExp: TPerlRegEx;
  sizeArray, positionStart, i, counterSymbol: Integer;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Subject := inputText;
  RegExp.RegEx := searchExpression;
  sizeArray := Length(arrayFunctionalParts);
  if (RegExp.Match) then
    repeat
      RegExp.Free;
      RegExp := TPerlRegEx.Create;
      RegExp.Subject := inputText;
      RegExp.RegEx := searchExpression;
      if (RegExp.Match) then
      begin
        inc(sizeArray);
        SetLength(arrayFunctionalParts, sizeArray);
        positionStart := RegExp.GroupOffsets[0];
        i := RegExp.MatchedLength - 1;
        counterSymbol := 1;
        while (counterSymbol <> 0) do
        begin
          inc(i);
          if (inputText[positionStart + i] = '{') then
            inc(counterSymbol);
          if (inputText[positionStart + i] = '}') then
            dec(counterSymbol);
        end;
        arrayFunctionalParts[sizeArray - 1] := Copy(inputText, positionStart, i + 1);
        Delete(inputText, positionStart, i + 1);
      end;
    until not RegExp.MatchAgain;
  SetLength(arrayFunctionalParts, sizeArray + 1);
  arrayFunctionalParts[sizeArray] := inputText;
  RegExp.Free;
end;

procedure TFormMetrick.AddInStringGrid(RowCountInStart: integer; expression: String; StringGrid: TStringGrid);
var
  isFound: Boolean;
  i: Integer;
begin
  isFound := false;
  i := 1;
  while (RowCountInStart + i < StringGrid.RowCount - 1) and (not isFound) do
  begin
    if (StringGrid.Cells[0, RowCountInStart + i] = expression) then
    begin
      StringGrid.Cells[1, RowCountInStart + i] := IntToStr(StrToInt(StringGrid.Cells[1, RowCountInStart + i]) + 1);
      isFound := True;
    end
    else
      inc(i);
  end;
  if (not isFound) then
    with StringGrid do
    begin
      Cells[0, RowCount - 1] := expression;
      Cells[1, RowCount - 1] := '1';
      RowCount := RowCount + 1;
    end;
end;

procedure TFormMetrick.FindingExpressions(searchExpression: String; var inputText: String; var StringGrid: TStringGrid; otherFunction: Boolean);
var
  RegExp: TPerlRegEx;
  RowCountInStart: Integer;
  expression: String;
begin
  RegExp := TPerlRegEx.Create;
  RegExp.Subject := inputText;
  RegExp.RegEx := searchExpression;
  if otherFunction then
    RowCountInStart := StringGrid.RowCount - 2
  else
    RowCountInStart := 0;
  if (RegExp.Match) then
    repeat
      expression := RegExp.Groups[0];
      CorrectExpression(expression);
      AddInStringGrid(RowCountInSTart, expression, StringGrid);
    until not RegExp.MatchAgain;
  RegExp.Free;
  DeleteExpressions(inputText, searchExpression);
end;

procedure TFormMetrick.Finding(var inputText: string);
begin
  FindingExpressions('("[^\r\n]{0,}")|(''[^\r\n\'']{0,}'')', inputText, StringGridOperands, true); // ��������� ���������
  FindingExpressions('(\b[\w\s]*?\?[\w\s]*?\:[\w\s]*?\b)|\?', inputText, stringGridOperators, false); // ��������� ��������
  FindingExpressions('(\+=|-=|\*=|\/=|%=|&=|\|=|\^=|<<=|>>>=|>>=)', inputText, stringGridOperators, false); // ��������� ���������� ������������
  FindingExpressions('(\.)', inputText, StringGridOperators, false); // ��������� � ������� � ���������� ������
  FindingExpressions('(&&|\|\|)', inputText, StringGridOperators, false); //��������� ����������
  FindingExpressions('(\~|&|\||\^|<<|>>>?)', inputText, stringGridOperators, false); // ��������� ���������
  FindingExpressions('(={2,3}|!={1,2}|>=?|<=?)', inputText, StringGridOperators, false); //��������� ���������
  FindingExpressions('(=|\+{1,2}|-{1,2}|\*|\/|%|!{2})', inputText, StringGridOperators, false);  // �������������� ���������
  FindingExpressions('(!|&|\||\,|\;)', inputText, StringGridOperators, false);  // ��������� ���������
  FindingExpressions('(?<![\w])(-?\d+\.?\d*?[Ff]?(?![A-Za-z]))|(0[Xx][\w]+)', inputText, StringGridOperands, true); // �������� ���������
  FindingExpressions('(\b(for|do|while))', inputText, stringGridOperators, false); // ����� ������
  FindingExpressions('(\b[\w]* *?\()|([\w]+(?=:))', inputText, stringGridOperators, false); // ����� �������
  FindingExpressions('(\b(public\s*|private\s*|protected\s*)?(static\s*|final\s*)?([Ll]ist|class|char|int|long|String|float|double|boolean|void|var(?!\w)))', inputText, stringGridOperators, false); // ���������� ���������� � �������
  FindingExpressions('((struct\s{0,}[\w\_]{1,})|return|else|case|switch|break|continue|import|new|(?!\w)try(?!\w)|catch|finaly|typeof|(?!\w)in(?!\w))', inputText, stringGridOperators, false); // ����������������� �����
  FindingExpressions('(\b[\w]+\b)', inputText, stringGridOperands, true); // ����� ���������
  StringGridOperators.RowCount := StringGridOperators.RowCount - 1;
  StringGridOperands.RowCount := StringGridOperands.RowCount - 1;
end;

procedure TFormMetrick.CalculationValues();
var
   i: integer;
   dictionaryOperators,dictionaryOperands: Integer;
   amountOperators, amountOperands: Integer;
begin
  if (StringGridOperators.RowCount > 1) and (StringGridOperands.RowCount > 1) then
  begin
    dictionaryOperators := StringGridOperators.RowCount - 1;
    dictionaryOperands := StringGridOperands.RowCount - 1;
    amountOperators := 0;
    for i := 1 to StringGridOperators.RowCount - 1 do
      amountOperators := amountOperators + StrToInt(StringGridOperators.Cells[1, i]);
    amountOperands := 0;
    for i := 1 to StringGridOperands.RowCount - 1 do
      amountOperands := amountOperands + StrToInt(StringGridOperands.Cells[1, i]);
    with StringGridMetrick do
    begin
      Cells[2,1] := IntToStr(dictionaryOperators);
      Cells[2,2] := IntToStr(dictionaryOperands);
      Cells[2,3] := IntToStr(amountOperators);
      Cells[2,4] := IntToStr(amountOperands);
      Cells[2,5] := IntToStr(dictionaryOperators + dictionaryOperands);
      Cells[2,6] := IntToStr(amountOperators + amountOperands);
      Cells[2,7] := FloatToStrF(StrToFloat(Cells[2,6]) * Log2(StrToFloat(Cells[2,5])), ffGeneral, 6, 2);
      Cells[2,8] := FloatToStrF(dictionaryOperands * Log2(dictionaryOperands), ffGeneral, 6, 2); // StrToFloat(Cells[2,5]
      Cells[2,9] := FloatToStrF(dictionaryOperators * Log2(dictionaryOperators) + dictionaryOperands * Log2(dictionaryOperands), ffGeneral, 6, 2);
      Cells[2,10] := FloatToStrF(StrToFloat(Cells[2,8]) / StrToFloat(Cells[2,7]), ffGeneral, 6, 2);
      Cells[2,11] := FloatToStrF(2 * dictionaryOperands / (dictionaryOperators * amountOperands), ffGeneral, 6, 2);
      Cells[2,12] := FloatToStrF(StrToFloat(Cells[2,11]) * StrToFloat(Cells[2,7]), ffGeneral, 6, 2);
      Cells[2,13] := FloatToStrF(StrToFloat(Cells[2,9]) * Log2(StrToFloat(Cells[2,5]) / StrToFloat(Cells[2,10])), ffGeneral, 6, 2);
      Cells[2,14] := FloatToStrF((StrToFloat(Cells[2,7]) * StrToFloat(Cells[2,7]) / StrToFloat(Cells[2,8])), ffGeneral, 6, 2);
    end;
  end
  else
  begin
    for i := 1 to StringGridMetrick.RowCount - 1 do
      StringGridMetrick.Cells[2,i] := '-';
    Application.MessageBox('������ ����� �� �������� ����������� ����� �� ����� �, ����������, ��������� ������.','��������!', MB_OK + MB_TOPMOST);
  end;
end;

procedure TFormMetrick.ButtonExecutClick(Sender: TObject);
var
  inputText: string;
  arrayFunctionalParts: TArrayOfFuctionalParts;
  i: integer;
begin
  ClearStringGrid;
  inputText := MemoInputText.Text;
  FormattingText(inputText, arrayFunctionalParts);
  //MemoInputText.Clear;
  for  i := 0 to length(arrayFunctionalParts) - 1 do
  begin
    Finding(arrayFunctionalParts[i]);
    //MemoInputText.Lines.Add(arrayFunctionalParts[i]);
  end;
  CalculationValues;
end;

end.
