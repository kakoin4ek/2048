program g2048;

uses
  GraphABC, ABCObjects, ABCButtons, timers, controlUtils;

const
  /// размер поля
  n = 4;
  ///размер фишки
  tile = 100;
  /// зазор между фишками
  zz = 5;
  /// отступ от левого и правого краев
  x0 = 5;
  /// отступ от верхнего и нижнего краев
  y0 = 5;
  ///Степень округления углов у фигурок
  roundRate = 5;
  ///заголовок окна
  windowTitle = '2048 Game!';
  //Настройки цветов
  ///фоновый цвет!
  backgroundColor = RGB(187, 173, 160);   
  ///фон пустой клетки
  emptySquareColor = RGB(205, 193, 180);  
  ///интервал таймера анимационного
  animTimerInterval = 1;
  ///на сколько менять размер клеточки при анимации
  animDelta = 6;
  
var
  ///ходил ли игрок? (это нужно будет для того, чтобы если ход не совершён, не создавать новую клеточку в таком случае)
  moved: boolean := false;
  ///анимационный таймер
  animationTimer: Timer;
  ///экземпляр класса для работы с диалогами
  dialogs: TDialogs;

type
  ///возможные направления движения
  TDirection = (tdUp, tdDown, tdLeft, tdRight);
  
  ///наш класс на основе SquareABC, чтобы хранить тут дополнительные переменные
  TSquare = class(RoundRectABC)
    ///значение клеточки
    value: integer = 0; 
    changed: boolean = false; //если произошло изменение значения (используется для анимации)
    ///фукция для установки значения клеточки, заодно нужных цветов
    procedure setNumber(number: integer); 
  end;
  
  ///запись для хранения настроек цветов
  TSquareColor = record
    bColor, FontColor: color; 
  end;

var
  gField: array [1..n, 1..n] of TSquare; //наше поле состоит из наших доделанных SquareABC!
  ///счёт, пожалуйста!
  score: integer = 0; 

{**********************************************}

//добавить очков
procedure addScore(add_score: integer);
begin
  score := score + add_score;
  moved := true; //раз очки прибавились, значит был совершён ход
end;

//обнулить количество очков
procedure clearScore();
begin
  score := 0;
end;

//тут можно вывести куда-то количество очков
procedure updateScore();
begin
  window.Title := windowTitle + '; Score: ' + IntToStr(score);
end;

//получить случайное начальное число (двойку или четвёрку)
function getRandomNumber(): integer;
begin
  result := Random(100) > 85 ? 4 : 2; //делаем большую вероятность выпадения именно двойки
end;

//вспомогательная функция для создания записи TSquareColor из фонового цвета и цвета шрифта
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

//получить клетку по позиции её
function getSquareByPos(x, y: integer): TSquare;
begin
  result := gField[x, y];
end;

//получить цвет в зависимости от цифры
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
  sc := getSquareColorByNumber(value);    //получаем цвет клеточки и цвет шрифта в зависимости от номера
  Color := sc.bColor;                     //устанавливаем цвет клеточки
  FontColor := sc.FontColor;              //устанавливаем цвет текста
  Text := IntToStr(value);                //пишем цифру
  animateSquare(self, value > 2); //анимация клеточки в зависимости от значения
end;

//заполнить клеточку начальными пустыми значениями и параметрами 
procedure createSquare(var square: TSquare);
begin
  square.Bordered := false;
  square.TextScale := 0.7;			//размер текста?
  square.value := 0;
end;

// создаём массив квадратиков
procedure CreateFields;
var
  sq: TSquare;
begin
  for var x := 1 to n do
    for var y := 1 to n do
    begin
      sq := new TSquare(x0 + (x - 1) * (tile + zz), y0 + (y - 1) * (tile + zz), tile, tile, roundRate, emptySquareColor); //создаём клетку с указанными размерами и координатами и цветом
      createSquare(sq);         //заполним клетку начальными значениями
      gField[y, x] := sq; 			//заносим экземпляр клетки в массив
    end;
end;

procedure clearAllFields;//очистить все клетки!!!!!
begin
  for var x := 1 to n do
    for var y := 1 to n do
      clearSquare(gField[x, y]);
end;

//проверяет, можно ли ходить куда-то
function canMove(): boolean;
var
  field: TSquare;
begin
  result := false;
  //сначала проверка чисел по вертикалям
  for var x := 1 to n do
  begin
    for var y := 2 to n do
    begin
      field := gField[x, y];
      
      //если есть хоть одна пустая клетка, то игрок уж точно может ходить )
      if (field.value = 0) then
      begin
        result := true;
        exit;
      end;
    
      //Если можно сложить хоть одну пару клеток
      if (field.value = gField[x, y - 1].value) then 
      begin 
        result := true; //то значит можно ходить!
        exit;           //И нужно выйти, ведь дальше незачем цикл гонять
      end;
    end;
  end;
  
  //а теперь проверка чисел по горизонталям
  for var y := 1 to n do
  begin
    for var x := 2 to n do
    begin
      field := gField[x, y];
      //снова проверка на пустую клетку
      if (field.value = 0) then
      begin
        result := true;
        exit;
      end;
      //снова проверка, можно ли сложить два числа по горизонтали
      if (field.value = gField[x - 1, y].value) then
      begin
        result := true;
        exit;
      end;
    end;
  end;
end;

//получить случайную пустую клетку
function getRandomEmptyField(): TSquare;
var
  positions: array[0..n * n] of Point; //массив, куда будут складываться позиции свободных клеток
  available_count: integer = 0;
begin
  result := nil; //по умолчанию результат будет НИЧЕГО
  for var x := 1 to n do
    for var y := 1 to n do
    begin
      if (gField[x, y].value = 0) then //если клетка свободна, то нужно добавить её в массив
      begin
        //сохраняем координаты очередной найденой пустой клетки
        positions[available_count].x := x; 
        positions[available_count].y := y;
        inc(available_count); //увеличиваем счётчик количества свободных клеточек
      end;
    end;
  if (available_count > 0) then //если есть свободные клетки, 
  begin
    var pos := positions[Random(available_count)];  //то выбираем одну из них случайным образом
    result := gField[pos.x, pos.y];                 //и выдаём её в результат
  end;
end;

//есть ли ещё пустые клетки?
function emptyFieldsExists(): boolean;
begin
  result := false;
  for var x := 1 to n do
    for var y := 1 to n do
    begin
      if gField[x, y].value = 0 then //да, есть хоть одна пустая клетка!
      begin
        result := true;
        break; //незачем дальше цикл гонять, раз есть хоть одна свободная клетка
      end;
    end;
end;

//создать случайное число (2 или 4) в случайный пустой квадратик
procedure putRandomSquare();
var
  sq: TSquare;
begin
  sq := getRandomEmptyField();	//получаем случайный пустой квадрат
  if (sq = nil) then //Если nil, значит нет пустых клеток!
  begin
    //сначала проверить, есть ли возможность ходить куда-то
    if (canMove()) then
    begin
      exit;
    end;
    
    //Иначе, раз нельзя уже ходить, то типа игра окончена и всё такое.
    //согласен, что не очень правильно, что этот код находится в этой процедуре, но да ладно (
    dialogs.showInfo('Игра окончена! Счёт: ' + IntToStr(score));
    exit;
  end;
  
  sq.setNumber(getRandomNumber()); //устанавливаем случайный номер (2 или 4) клеточке
end;

//поменять местами две клеточки между собой
procedure replaceSquares(square1, square2: TSquare);
var
  c, f: Color;
  t: String;
  v: Integer;
begin
  //запомним параметры первой клетки
  c := square1.Color;
  f := square1.FontColor;
  t := square1.Text;
  v := square1.value;
  //поменяем параметры первой клетки на параметры второй
  square1.Color := square2.Color;
  square1.Text := square2.Text;
  square1.value := square2.value;
  square1.FontColor := square2.FontColor;
  //поменяем параметры второй клетки на заранее сохранённые параметры первой
  square2.value := v;
  square2.Text := t;
  square2.Color := c;
  square2.FontColor := f;
  
  //system.Console.Writeline('MOVED! ' + t);
  moved := true; //установим флаг, что ход был совершён!
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
        
        for var i := y - 1 downto 1 do //пробежимся циклом вверх по Y до начала.
        begin
          new_sq := gField[i, x];    
          
          if (new_sq.value <> 0) then //если вдруг встретилась не пустая клетка, надо проверить, вдруг она складываемая!
          begin
            if (new_sq.value <> sq.value) then //если значения разные, то
            begin
              replaceSquares(sq, getSquareByPos(i + 1, x)); //передвинуть клеточку рядом с той, что выше
              break; //и просто АСТАНАВИТЕСЬ
            end else //если совпало значение, то объединить их!
            begin
              new_sq.setNumber(new_sq.value * 2); //установить новое значение для клеточки
              addScore(new_sq.value);             //добавить это значение к количеству очков
              clearSquare(sq);                    //очистить ту клеточку, которая сложилась с первой
              break;
            end;
          end;                   
          
          if (i = 1) then
            replaceSquares(sq, new_sq); //дошли до начала, значит, просто поменять местами клетки)
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
        
        for var i := y + 1 to n do  //пробежимся циклом вниз до конца по этому же столбцу Y
        begin
          new_sq := gField[i, x];
          
          if (new_sq.value <> 0) then //если вдруг встретилась не пустая клетка, надо проверить, вдруг она складываемая!
          begin
            if (new_sq.value <> sq.value) then //если значения разные, то
            begin
              replaceSquares(sq, getSquareByPos(i - 1, x)); //передвинуть клеточку к той, которая имеет значение иное
              break; //и просто АСТАНАВИТЕСЬ
            end else //если совпало значение, то объединить их!
            begin
              new_sq.setNumber(new_sq.value * 2); //установить новое значение для клеточки
              addScore(new_sq.value);             //добавить это значение к количеству очков
              clearSquare(sq);                    //очистить ту клеточку, которая сложилась с первой
              break;
            end;
          end;                   
          
          if (i = n) then
            replaceSquares(sq, new_sq); //дошли до начала, значит, просто поменять местами клетки)
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
        
        for var i := x - 1 downto 1 do  //пробежимся циклом влево по текущей строке X
        begin
          new_sq := gField[y, i];
          
          if (new_sq.value <> 0) then //если вдруг встретилась не пустая клетка, надо проверить, вдруг она складываемая!
          begin
            if (new_sq.value <> sq.value) then //если значения разные, то
            begin
              replaceSquares(sq, getSquareByPos(y, i + 1)); //передвинуть клеточку к той, которая имеет значение иное
              break; //и просто АСТАНАВИТЕСЬ
            end else //если совпало значение, то объединить их!
            begin
              new_sq.setNumber(new_sq.value * 2); //установить новое значение для клеточки
              addScore(new_sq.value);             //добавить это значение к количеству очков
              clearSquare(sq);                    //очистить ту клеточку, которая сложилась с первой
              break;
            end;
          end;                   
          
          if (i = 1) then
            replaceSquares(sq, new_sq); //дошли до начала, значит, просто поменять местами клетки)
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
        
        for var i := x + 1 to n do  //пробежимся циклом влево по текущей строке X
        begin
          new_sq := gField[y, i];
          
          if (new_sq.value <> 0) then //если вдруг встретилась не пустая клетка, надо проверить, вдруг она складываемая!
          begin
            if (new_sq.value <> sq.value) then //если значения разные, то
            begin
              replaceSquares(sq, getSquareByPos(y, i - 1)); //передвинуть клеточку к той, которая имеет значение иное
              break; //и просто АСТАНАВИТЕСЬ
            end else //если совпало значение, то объединить их!
            begin
              new_sq.setNumber(new_sq.value * 2); //установить новое значение для клеточки
              addScore(new_sq.value);             //добавить это значение к количеству очков
              clearSquare(sq);                    //очистить ту клеточку, которая сложилась с первой
              break;
            end;
          end;                   
          
          if (i = n) then
            replaceSquares(sq, new_sq); //дошли до начала, значит, просто поменять местами клетки)
        end;
        
      end;
    end;
end;

procedure move(direction: TDirection);
begin
  moved := false; //сбросим флаг сделанного хода
  //выполнить ход в нужную сторону
  case direction of
    tdUP: moveUp();
    tdDown: moveDown();
    tdLeft: moveLeft();
    tdRight: moveRight();
  end;
  //обновить в заголовке окна количество очков после очередного хода
  updateScore();  
  //Если ход был освершён, то добавить ещё клеточку
  if moved then
    putRandomSquare();
end;

procedure newGame();
begin
  clearAllFields(); //При нажатии на Esc можно сделать что-то вроде меню и т.д.
  clearScore();
  putRandomSquare();
  putRandomSquare();
end;

procedure KeyDown(Key: integer);
begin
  //если открыто какое-то диалоговое окно!
  if dialogs.modalVisible then
  begin
    case Key of
      VK_RETURN: dialogs.pressOK;
      VK_ESCAPE: dialogs.closeLastDialog();
    end;
    exit;
  end;
  
  //если нет открытого диалогового окна
  case Key of 
    VK_UP: move(tdUp);
    VK_DOWN: move(tdDown);
    VK_LEFT: move(tdLeft);
    VK_RIGHT: move(tdRight);
    VK_Escape: dialogs.showConfirm('Вы действительно хотите начать заново?', newGame);
  end; 
end;

//анимационный таймер
procedure animTimerProc;
var
  sq: TSquare;
begin
  //плавное изменение размеров обратно до изначального
  for var x := 1 to n do
    for var y := 1 to n do
    begin
      sq := gField[x, y];
      
      if (sq.changed) then
      begin
        if (sq.Width > tile) then //если размер больше, надо уменьшать
        begin
          sq.left += 1;
          sq.Top += 1;
          sq.Width -= 1;
          sq.Height -= 1;
        end else //иначе увеличивать наоборот )
        begin
          sq.left -= 1;
          sq.Top -= 1;
          sq.Width += 1;
          sq.Height += 1;
        end;
      end;
      
      if (sq.Width = tile) then //если размер стал изначальным,
      begin
        sq.changed := false;    //то пометить клетку, как нормальную, не изменённую, чтобы таймер больше не трогал её пока
        continue;
      end;
    end;
end;

//обработчики событий для кнопок меню

procedure onNewGameClick;
begin
  newGame();
end;

var
  cu: TControlUtils;

begin
  Randomize();                    //инициализация генератора случайных чисел
  Window.Title := windowTitle;    //заголовок окошка
  OnKeyDown := KeyDown;           //зададим наш обработчик нажатия кнопок
  SetWindowSize(2 * x0 + (tile + zz) * n - zz, 2 * y0 + (tile + zz) * n - zz); //задаём размер окошка, учитывая размеры всех клеток и отступов
  Window.IsFixedSize := True;     //чтобы нельзя было менять размер окошка
  Window.Clear(backgroundColor);  //"очистим" окно фоновым цветом
  Window.CenterOnScreen();        //окно пусть будет по центру экрана
  CreateFields();                 //создадим поля-полюшки
  //создаём и запускаем таймер, отвечающий за анимации
  animationTimer := new Timer(animTimerInterval, animTimerProc);
  animationTimer.start;
  //создаём объект для работы с диалоговыми окошками
  dialogs := new TDialogs;
  
  {
  cu := new TControlUtils();
  cu.addMenuButton('Новая игра', onNewGameClick);
  cu.addMenuButton('LOL?!', onTestGameClick);
  cu.setToCenter();
  }
  
  //начинается всё с двух клеток
  putRandomSquare(); 
  putRandomSquare(); 
end.