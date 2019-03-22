program g2048;

uses
  GraphABC, ABCObjects, ABCButtons, timers, controlUtils;

const
  /// ������ ����
  n = 4;
  ///������ �����
  tile = 100;
  /// ����� ����� �������
  zz = 5;
  /// ������ �� ������ � ������� �����
  x0 = 5;
  /// ������ �� �������� � ������� �����
  y0 = 5;
  ///������� ���������� ����� � �������
  roundRate = 5;
  ///��������� ����
  windowTitle = '2048 Game!';
  //��������� ������
  ///������� ����!
  backgroundColor = RGB(187, 173, 160);   
  ///��� ������ ������
  emptySquareColor = RGB(205, 193, 180);  
  ///�������� ������� �������������
  animTimerInterval = 1;
  ///�� ������� ������ ������ �������� ��� ��������
  animDelta = 6;
  
var
  ///����� �� �����? (��� ����� ����� ��� ����, ����� ���� ��� �� ��������, �� ��������� ����� �������� � ����� ������)
  moved: boolean := false;
  ///������������ ������
  animationTimer: Timer;
  ///��������� ������ ��� ������ � ���������
  dialogs: TDialogs;

type
  ///��������� ����������� ��������
  TDirection = (tdUp, tdDown, tdLeft, tdRight);
  
  ///��� ����� �� ������ SquareABC, ����� ������� ��� �������������� ����������
  TSquare = class(RoundRectABC)
    ///�������� ��������
    value: integer = 0; 
    changed: boolean = false; //���� ��������� ��������� �������� (������������ ��� ��������)
    ///������ ��� ��������� �������� ��������, ������ ������ ������
    procedure setNumber(number: integer); 
  end;
  
  ///������ ��� �������� �������� ������
  TSquareColor = record
    bColor, FontColor: color; 
  end;

var
  gField: array [1..n, 1..n] of TSquare; //���� ���� ������� �� ����� ���������� SquareABC!
  ///����, ����������!
  score: integer = 0; 

{**********************************************}

//�������� �����
procedure addScore(add_score: integer);
begin
  score := score + add_score;
  moved := true; //��� ���� �����������, ������ ��� �������� ���
end;

//�������� ���������� �����
procedure clearScore();
begin
  score := 0;
end;

//��� ����� ������� ����-�� ���������� �����
procedure updateScore();
begin
  window.Title := windowTitle + '; Score: ' + IntToStr(score);
end;

//�������� ��������� ��������� ����� (������ ��� �������)
function getRandomNumber(): integer;
begin
  result := Random(100) > 85 ? 4 : 2; //������ ������� ����������� ��������� ������ ������
end;

//��������������� ������� ��� �������� ������ TSquareColor �� �������� ����� � ����� ������
function createColor(bColor, FontColor: Color): TSquareColor;
begin
  result.bColor := bColor;
  result.FontColor := FontColor;
end;

procedure clearSquare(var square: TSquare);
begin
  square.Color := emptySquareColor;
  square.Text := '';
  square.value := 0;
end;

//�������� ������ �� ������� �
function getSquareByPos(x, y: integer): TSquare;
begin
  result := gField[x, y];
end;

//�������� ���� � ����������� �� �����
function getSquareColorByNumber(num: integer): TSquareColor;
begin
  case num of
    2: result := createColor(rgb(238, 228, 218), rgb(119, 110, 101));
    4: result := createColor(rgb(237, 224, 200), rgb(119, 110, 101));
    8: result := createColor(rgb(242, 177, 121), rgb(249, 246, 242));
    16: result := createColor(rgb(245, 149, 99), rgb(249, 246, 242));
    32: result := createColor(rgb(246, 124, 95), rgb(249, 246, 242));
    64: result := createColor(rgb(246, 94, 59), rgb(249, 246, 242));
    128: result := createColor(rgb(237, 207, 114), rgb(249, 246, 242));
    256: result := createColor(rgb(237, 204, 97), rgb(249, 246, 242));
    512: result := createColor(rgb(237, 200, 80), rgb(249, 246, 242));
    1024: result := createColor(rgb(237, 197, 63), rgb(249, 246, 242));
    2048: result := createColor(rgb(237, 194, 46), rgb(249, 246, 242));
    4096: result := createColor(rgb(60, 58, 50), rgb(249, 246, 242));
    else result := createColor(rgb(238, 228, 218), rgb(119, 110, 101));
  end;
end;

procedure animateSquare(sq: TSquare; bigger: boolean);
begin
  sq.changed := true;
  if (bigger) then
  begin
    sq.left -= animDelta;
    sq.Top -= animDelta;
    sq.Width += animDelta;
    sq.Height += animDelta;
  end else 
  begin
    sq.left += animDelta;
    sq.Top += animDelta;
    sq.Width -= animDelta;
    sq.Height -= animDelta;
  end;
end;

procedure TSquare.setNumber(number: integer);
var
  sc: TSquareColor;
begin  
  value := number;
  sc := getSquareColorByNumber(value);    //�������� ���� �������� � ���� ������ � ����������� �� ������
  Color := sc.bColor;                     //������������� ���� ��������
  FontColor := sc.FontColor;              //������������� ���� ������
  Text := IntToStr(value);                //����� �����
  animateSquare(self, value > 2); //�������� �������� � ����������� �� ��������
end;

//��������� �������� ���������� ������� ���������� � ����������� 
procedure createSquare(var square: TSquare);
begin
  square.Bordered := false;
  square.TextScale := 0.7;			//������ ������?
  square.value := 0;
end;

// ������ ������ �����������
procedure CreateFields;
var
  sq: TSquare;
begin
  for var x := 1 to n do
    for var y := 1 to n do
    begin
      sq := new TSquare(x0 + (x - 1) * (tile + zz), y0 + (y - 1) * (tile + zz), tile, tile, roundRate, emptySquareColor); //������ ������ � ���������� ��������� � ������������ � ������
      createSquare(sq);         //�������� ������ ���������� ����������
      gField[y, x] := sq; 			//������� ��������� ������ � ������
    end;
end;

procedure clearAllFields;//�������� ��� ������!!!!!
begin
  for var x := 1 to n do
    for var y := 1 to n do
      clearSquare(gField[x, y]);
end;

//���������, ����� �� ������ ����-��
function canMove(): boolean;
var
  field: TSquare;
begin
  result := false;
  //������� �������� ����� �� ����������
  for var x := 1 to n do
  begin
    for var y := 2 to n do
    begin
      field := gField[x, y];
      
      //���� ���� ���� ���� ������ ������, �� ����� �� ����� ����� ������ )
      if (field.value = 0) then
      begin
        result := true;
        exit;
      end;
    
      //���� ����� ������� ���� ���� ���� ������
      if (field.value = gField[x, y - 1].value) then 
      begin 
        result := true; //�� ������ ����� ������!
        exit;           //� ����� �����, ���� ������ ������� ���� ������
      end;
    end;
  end;
  
  //� ������ �������� ����� �� ������������
  for var y := 1 to n do
  begin
    for var x := 2 to n do
    begin
      field := gField[x, y];
      //����� �������� �� ������ ������
      if (field.value = 0) then
      begin
        result := true;
        exit;
      end;
      //����� ��������, ����� �� ������� ��� ����� �� �����������
      if (field.value = gField[x - 1, y].value) then
      begin
        result := true;
        exit;
      end;
    end;
  end;
end;

//�������� ��������� ������ ������
function getRandomEmptyField(): TSquare;
var
  positions: array[0..n * n] of Point; //������, ���� ����� ������������ ������� ��������� ������
  available_count: integer = 0;
begin
  result := nil; //�� ��������� ��������� ����� ������
  for var x := 1 to n do
    for var y := 1 to n do
    begin
      if (gField[x, y].value = 0) then //���� ������ ��������, �� ����� �������� � � ������
      begin
        //��������� ���������� ��������� �������� ������ ������
        positions[available_count].x := x; 
        positions[available_count].y := y;
        inc(available_count); //����������� ������� ���������� ��������� ��������
      end;
    end;
  if (available_count > 0) then //���� ���� ��������� ������, 
  begin
    var pos := positions[Random(available_count)];  //�� �������� ���� �� ��� ��������� �������
    result := gField[pos.x, pos.y];                 //� ����� � � ���������
  end;
end;

//���� �� ��� ������ ������?
function emptyFieldsExists(): boolean;
begin
  result := false;
  for var x := 1 to n do
    for var y := 1 to n do
    begin
      if gField[x, y].value = 0 then //��, ���� ���� ���� ������ ������!
      begin
        result := true;
        break; //������� ������ ���� ������, ��� ���� ���� ���� ��������� ������
      end;
    end;
end;

//������� ��������� ����� (2 ��� 4) � ��������� ������ ���������
procedure putRandomSquare();
var
  sq: TSquare;
begin
  sq := getRandomEmptyField();	//�������� ��������� ������ �������
  if (sq = nil) then //���� nil, ������ ��� ������ ������!
  begin
    //������� ���������, ���� �� ����������� ������ ����-��
    if (canMove()) then
    begin
      exit;
    end;
    
    //�����, ��� ������ ��� ������, �� ���� ���� �������� � �� �����.
    //��������, ��� �� ����� ���������, ��� ���� ��� ��������� � ���� ���������, �� �� ����� (
    dialogs.showInfo('���� ��������! ����: ' + IntToStr(score));
    exit;
  end;
  
  sq.setNumber(getRandomNumber()); //������������� ��������� ����� (2 ��� 4) ��������
end;

//�������� ������� ��� �������� ����� �����
procedure replaceSquares(square1, square2: TSquare);
var
  c, f: Color;
  t: String;
  v: Integer;
begin
  //�������� ��������� ������ ������
  c := square1.Color;
  f := square1.FontColor;
  t := square1.Text;
  v := square1.value;
  //�������� ��������� ������ ������ �� ��������� ������
  square1.Color := square2.Color;
  square1.Text := square2.Text;
  square1.value := square2.value;
  square1.FontColor := square2.FontColor;
  //�������� ��������� ������ ������ �� ������� ���������� ��������� ������
  square2.value := v;
  square2.Text := t;
  square2.Color := c;
  square2.FontColor := f;
  
  //system.Console.Writeline('MOVED! ' + t);
  moved := true; //��������� ����, ��� ��� ��� ��������!
end;

{**}

procedure moveUp();
var
  sq, new_sq: TSquare;
begin
  for var x := 1 to n do
    for var y := 2 to n do
    begin
      sq := gField[y, x];
      //sleep(100);
      //sq.Color := clBlue;
      if (sq.value <> 0) then
      begin
        
        for var i := y - 1 downto 1 do //���������� ������ ����� �� Y �� ������.
        begin
          new_sq := gField[i, x];    
          
          if (new_sq.value <> 0) then //���� ����� ����������� �� ������ ������, ���� ���������, ����� ��� ������������!
          begin
            if (new_sq.value <> sq.value) then //���� �������� ������, ��
            begin
              replaceSquares(sq, getSquareByPos(i + 1, x)); //����������� �������� ����� � ���, ��� ����
              break; //� ������ ������������
            end else //���� ������� ��������, �� ���������� ��!
            begin
              new_sq.setNumber(new_sq.value * 2); //���������� ����� �������� ��� ��������
              addScore(new_sq.value);             //�������� ��� �������� � ���������� �����
              clearSquare(sq);                    //�������� �� ��������, ������� ��������� � ������
              break;
            end;
          end;                   
          
          if (i = 1) then
            replaceSquares(sq, new_sq); //����� �� ������, ������, ������ �������� ������� ������)
        end;
        
      end;
    end;
end;

procedure moveDown();
var
  sq, new_sq: TSquare;
begin
  for var x := 1 to n do
    for var y := n - 1 downto 1 do
    begin
      sq := gField[y, x];
      if (sq.value <> 0) then
      begin
        
        for var i := y + 1 to n do  //���������� ������ ���� �� ����� �� ����� �� ������� Y
        begin
          new_sq := gField[i, x];
          
          if (new_sq.value <> 0) then //���� ����� ����������� �� ������ ������, ���� ���������, ����� ��� ������������!
          begin
            if (new_sq.value <> sq.value) then //���� �������� ������, ��
            begin
              replaceSquares(sq, getSquareByPos(i - 1, x)); //����������� �������� � ���, ������� ����� �������� ����
              break; //� ������ ������������
            end else //���� ������� ��������, �� ���������� ��!
            begin
              new_sq.setNumber(new_sq.value * 2); //���������� ����� �������� ��� ��������
              addScore(new_sq.value);             //�������� ��� �������� � ���������� �����
              clearSquare(sq);                    //�������� �� ��������, ������� ��������� � ������
              break;
            end;
          end;                   
          
          if (i = n) then
            replaceSquares(sq, new_sq); //����� �� ������, ������, ������ �������� ������� ������)
        end;
        
      end;
    end;
end;

procedure moveLeft();
var
  sq, new_sq: TSquare;
begin
  for var x := 2 to n do
    for var y := 1 to n do
    begin
      sq := gField[y, x];
      if (sq.value <> 0) then
      begin
        
        for var i := x - 1 downto 1 do  //���������� ������ ����� �� ������� ������ X
        begin
          new_sq := gField[y, i];
          
          if (new_sq.value <> 0) then //���� ����� ����������� �� ������ ������, ���� ���������, ����� ��� ������������!
          begin
            if (new_sq.value <> sq.value) then //���� �������� ������, ��
            begin
              replaceSquares(sq, getSquareByPos(y, i + 1)); //����������� �������� � ���, ������� ����� �������� ����
              break; //� ������ ������������
            end else //���� ������� ��������, �� ���������� ��!
            begin
              new_sq.setNumber(new_sq.value * 2); //���������� ����� �������� ��� ��������
              addScore(new_sq.value);             //�������� ��� �������� � ���������� �����
              clearSquare(sq);                    //�������� �� ��������, ������� ��������� � ������
              break;
            end;
          end;                   
          
          if (i = 1) then
            replaceSquares(sq, new_sq); //����� �� ������, ������, ������ �������� ������� ������)
        end;
        
      end;
    end;
end;

procedure moveRight();
var
  sq, new_sq: TSquare;
begin
  for var x := n - 1 downto 1 do
    for var y := 1 to n do
    begin
      sq := gField[y, x];      
      if (sq.value <> 0) then
      begin
        
        for var i := x + 1 to n do  //���������� ������ ����� �� ������� ������ X
        begin
          new_sq := gField[y, i];
          
          if (new_sq.value <> 0) then //���� ����� ����������� �� ������ ������, ���� ���������, ����� ��� ������������!
          begin
            if (new_sq.value <> sq.value) then //���� �������� ������, ��
            begin
              replaceSquares(sq, getSquareByPos(y, i - 1)); //����������� �������� � ���, ������� ����� �������� ����
              break; //� ������ ������������
            end else //���� ������� ��������, �� ���������� ��!
            begin
              new_sq.setNumber(new_sq.value * 2); //���������� ����� �������� ��� ��������
              addScore(new_sq.value);             //�������� ��� �������� � ���������� �����
              clearSquare(sq);                    //�������� �� ��������, ������� ��������� � ������
              break;
            end;
          end;                   
          
          if (i = n) then
            replaceSquares(sq, new_sq); //����� �� ������, ������, ������ �������� ������� ������)
        end;
        
      end;
    end;
end;

procedure move(direction: TDirection);
begin
  moved := false; //������� ���� ���������� ����
  //��������� ��� � ������ �������
  case direction of
    tdUP: moveUp();
    tdDown: moveDown();
    tdLeft: moveLeft();
    tdRight: moveRight();
  end;
  //�������� � ��������� ���� ���������� ����� ����� ���������� ����
  updateScore();  
  //���� ��� ��� ��������, �� �������� ��� ��������
  if moved then
    putRandomSquare();
end;

procedure newGame();
begin
  clearAllFields(); //��� ������� �� Esc ����� ������� ���-�� ����� ���� � �.�.
  clearScore();
  putRandomSquare();
  putRandomSquare();
end;

procedure KeyDown(Key: integer);
begin
  //���� ������� �����-�� ���������� ����!
  if dialogs.modalVisible then
  begin
    case Key of
      VK_RETURN: dialogs.pressOK;
      VK_ESCAPE: dialogs.closeLastDialog();
    end;
    exit;
  end;
  
  //���� ��� ��������� ����������� ����
  case Key of 
    VK_UP: move(tdUp);
    VK_DOWN: move(tdDown);
    VK_LEFT: move(tdLeft);
    VK_RIGHT: move(tdRight);
    VK_Escape: dialogs.showConfirm('�� ������������� ������ ������ ������?', newGame);
  end; 
end;

//������������ ������
procedure animTimerProc;
var
  sq: TSquare;
begin
  //������� ��������� �������� ������� �� ������������
  for var x := 1 to n do
    for var y := 1 to n do
    begin
      sq := gField[x, y];
      
      if (sq.changed) then
      begin
        if (sq.Width > tile) then //���� ������ ������, ���� ���������
        begin
          sq.left += 1;
          sq.Top += 1;
          sq.Width -= 1;
          sq.Height -= 1;
        end else //����� ����������� �������� )
        begin
          sq.left -= 1;
          sq.Top -= 1;
          sq.Width += 1;
          sq.Height += 1;
        end;
      end;
      
      if (sq.Width = tile) then //���� ������ ���� �����������,
      begin
        sq.changed := false;    //�� �������� ������, ��� ����������, �� ���������, ����� ������ ������ �� ������ � ����
        continue;
      end;
    end;
end;

//����������� ������� ��� ������ ����

procedure onNewGameClick;
begin
  newGame();
end;

var
  cu: TControlUtils;

begin
  Randomize();                    //������������� ���������� ��������� �����
  Window.Title := windowTitle;    //��������� ������
  OnKeyDown := KeyDown;           //������� ��� ���������� ������� ������
  SetWindowSize(2 * x0 + (tile + zz) * n - zz, 2 * y0 + (tile + zz) * n - zz); //����� ������ ������, �������� ������� ���� ������ � ��������
  Window.IsFixedSize := True;     //����� ������ ���� ������ ������ ������
  Window.Clear(backgroundColor);  //"�������" ���� ������� ������
  Window.CenterOnScreen();        //���� ����� ����� �� ������ ������
  CreateFields();                 //�������� ����-�������
  //������ � ��������� ������, ���������� �� ��������
  animationTimer := new Timer(animTimerInterval, animTimerProc);
  animationTimer.start;
  //������ ������ ��� ������ � ����������� ��������
  dialogs := new TDialogs;
  
  {
  cu := new TControlUtils();
  cu.addMenuButton('����� ����', onNewGameClick);
  cu.addMenuButton('LOL?!', onTestGameClick);
  cu.setToCenter();
  }
  
  //���������� �� � ���� ������
  putRandomSquare(); 
  putRandomSquare(); 
end.