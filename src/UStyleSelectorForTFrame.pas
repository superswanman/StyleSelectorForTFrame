unit UStyleSelectorForTFrame;

interface

procedure Register;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Rtti, Vcl.Controls,
  FMX.Forms, ToolsAPI, Events, ViewSelector, ComponentDesigner;

function GetViewSelectorFrame: TViewSelectorFrame;
var
  editWindow: TWinControl;

  function FindControl(AControl: TWinControl): TViewSelectorFrame;
  var
    i: Integer;
  begin
    if AControl is TViewSelectorFrame then
      Exit(TViewSelectorFrame(AControl));
    for i := 0 to AControl.ControlCount-1 do
    begin
      if AControl.Controls[i] is TWinControl then
      begin
        Result := FindControl(TWinControl(AControl.Controls[i]));
        if Result <> nil then Exit;
      end;
    end;
    Result := nil;
  end;

begin
  Result := nil;
  editWindow := (BorlandIDEServices as INTAEditorServices).TopEditWindow.Form;
  if editWindow = nil then Exit;
  Result := FindControl(editWindow);
end;

procedure EditorViewsChanged(Self, Sender: TObject; NewTabIndex: Integer; NewViewIndex: Integer);
var
  selector: TViewSelectorFrame;
  i: Integer;
  isFMXTFrame: Boolean;
begin
  selector := GetViewSelectorFrame;
  if selector = nil then Exit;

  isFMXTFrame := (ActiveRoot <> nil) and (ActiveRoot.Root <> nil) and ActiveRoot.Root.InheritsFrom(FMX.Forms.TFrame);
  for i := 0 to selector.DeviceToolbar.ControlCount-1 do
  begin
    if (selector.DeviceToolbar.Controls[i] = selector.lblStyleTitle) or
       (selector.DeviceToolbar.Controls[i] = selector.cbStyleSelector) then Continue;
    selector.DeviceToolbar.Controls[i].Visible := not isFMXTFrame;
  end;

  if isFMXTFrame then
    selector.Show;
end;

var
  FEditorViewsChangedEvent: ^TEvent;

procedure Register;
const
  sEditorViewsChangedEvent = '@Editorform@evEditorViewsChangedEvent';
  sTEditControlQualifiedName = 'EditorControl.TEditControl';
var
  ctx: TRttiContext;
  coreIdeName: string;
  method: TMethod;
begin
  coreIdeName := ExtractFileName(ctx.FindType(sTEditControlQualifiedName).Package.Name);
  FEditorViewsChangedEvent := GetProcAddress(GetModuleHandle(PChar(coreIdeName)), sEditorViewsChangedEvent);
  if FEditorViewsChangedEvent = nil then Exit;
  method.Code := @EditorViewsChanged;
  method.Data := nil;
  FEditorViewsChangedEvent^.Add(TNotifyEvent(method));
end;

procedure Unregister;
var
  method: TMethod;
begin
  if FEditorViewsChangedEvent <> nil then
  begin
    method.Code := @EditorViewsChanged;
    method.Data := nil;
    FEditorViewsChangedEvent^.Remove(TNotifyEvent(method));
  end;
end;

initialization
finalization
  Unregister;
end.