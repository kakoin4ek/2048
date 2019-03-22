unit controlUtils;

uses
  ABCObjects, ABCButtons, GraphABC;

type
  TBtnClickEvent = procedure;
  TBtnPosition = (bpLeft, bpCenter, bpRight);
  
  TControlUtils = class(ContainerABC)
  private 
    counter: integer = 1;
  public 
    constructor create;
    ///отцентрировать относительно окна, учитывая реальный размер
    procedure setToCenter();
    procedure addMenuButton(btn_text: string; on_click: TBtnClickEvent);
  end;
  
  ///небольшой класс для показа "диалоговых" окон или просто инфо-сообщений
  TDialogs = class
  private 
    _userClickEvent: TBtnClickEvent;
    _modalVisible: boolean = false; //просто флаг. если открыто модальное окно
    lastBaseObj: ObjectABC;
    lastText: TextABC;
    buttons: array of ButtonABC;
    buttonsCount: integer = 0;
    ///возвращает готовый текстовый объект, отцентрированный
    function getBaseObject(text: string): RectangleABC;
    function makeButton(text: string; onClick: TBtnClickEvent; btnPosition: TBtnPosition): ButtonABC;
    procedure onOKBtnClick;
    procedure onCancelBtnClick;
  public 
    constructor create;
    procedure showInfo(text: string);
    procedure showConfirm(text: string; onOK: TBtnClickEvent);
    procedure closeLastDialog;
    procedure pressOK;
    function modalVisible: boolean; //возвращает true, если сейчас активно модальное окно
  end;

procedure TDialogs.pressOK;
begin
  onOKBtnClick();
end;

procedure TDialogs.showConfirm(text: string; onOK: TBtnClickEvent);
var
  okBtn, cancelBtn: ButtonABC;
begin
  getBaseObject(text);
  okBtn := makeButton('OK', onOKBtnClick, bpLeft);
  _userClickEvent := onOk;
  cancelBtn := makeButton('Отмена', onCancelBtnClick, bpRight);
end;

function TDialogs.modalVisible: boolean;
begin
  result := _modalVisible;
end;

procedure TDialogs.closeLastDialog;
begin
  lastBaseObj.Destroy();
  lastText.Destroy();
  for var i := 0 to buttonsCount - 1 do
    buttons[i].Destroy();
  SetLength(buttons, 0);
  buttonsCount := 0;
  _userClickEvent := nil;
  _modalVisible := false;
end;

procedure TDialogs.onCancelBtnClick;
begin
  closeLastDialog();
end;

procedure TDialogs.onOKBtnClick;
begin
  if (_userClickEvent <> nil) then
    _userClickEvent();
  closeLastDialog();
end;

function TDialogs.makeButton(text: string; onClick: TBtnClickEvent; btnPosition: TBtnPosition): ButtonABC;
var
  btn: ButtonABC;
  left: integer;
  width: integer;
begin
  width := 100; //по-умолчанию кнопка будет вооот такой ширины
  if (TextWidth(text) >= 100) then //но если вдруг текста много...
    width := TextWidth(text) + 4;
  
  case (btnPosition) of
    bpLeft:     left := lastBaseObj.Left;
    bpCenter:   left := lastBaseObj.Left + lastBaseObj.Width div 2 - width div 2;
    bpRight:    left := (lastBaseObj.Left + lastBaseObj.Width) - width;
  end;
  btn := new ButtonABC(left, lastBaseObj.top + lastBaseObj.height, width, 30, text, clOrange);
  btn.FontColor := clWhite;
  btn.FontStyle := fsBold;
  btn.OnClick := onClick;
  
  SetLength(buttons, buttonsCount + 1);
  buttons[buttonsCount] := btn;
  inc(buttonsCount);
  
  result := btn;
end;

function TDialogs.getBaseObject(text: string): RectangleABC;
var
  t: TextABC;
  r: RectangleABC;
begin
  t := new TextABC(0, 0, 14, text, clWhite);
  r := new RectangleABC(window.Width div 2 - TextWidth(text) div 2, window.Height div 2 - TextHeight(text) div 2 - 60, t.Width + 7, t.Height + 7, RGB(167, 153, 140));
  t.Left := r.Left + 3;
  t.Top := r.Top + 3;
  t.ToFront;
  lastText := t;
  lastBaseObj := r;
  result := r;
  _modalVisible := true;
end;

procedure TDialogs.showInfo(text: string);
var
  okBtn: ButtonABC;
begin
  getBaseObject(text);
  okBtn := makeButton('OK', onOKBtnClick, bpCenter);
end;

constructor TDialogs.create;
begin
  SetLength(buttons, 0);
end;

{********}

procedure TControlUtils.setToCenter();
begin
  left := window.Width div 2 - Width div 2;
  top  := window.Height div 2 - Height div 2;
end;


procedure TControlUtils.addMenuButton(btn_text: string; on_click: TBtnClickEvent);
var
  btn: ButtonABC;
begin
  btn := new ButtonABC(left, top + 42 * counter, 100, 40, btn_text, clOrange);
  btn.FontStyle := fsBold;
  btn.FontColor := clWhite;
  btn.Owner := self;
  //
  btn.OnClick := on_click;
  Add(btn);
  inc(counter);
end;

constructor TControlUtils.create;
begin
  inherited create(0, 0);
  //Center := Window.Center;
  
end;

end.