unit Parnassus.FmxVclForm;

{
    The goal of this unit is that, if you have a FMX form TMyFmxForm
    you should be able to use this form in a VCL application as normal as possible by creating
    the form in the following way:

    MyWrappedForm := TFmxVclForm.CreateNew(Application, TMyFmxForm);

}

interface

uses
    Parnassus.FmxContainer,
    FMX.Forms,
    Winapi.Messages,
    Winapi.Windows,
    System.Classes,
    Vcl.StdCtrls,
    Vcl.AppEvnts,
    Vcl.Forms;

type
    TFmxFormClass = class of TCommonCustomForm;

    //accessing FMX.Forms.TForm by Parnassus.TFmxForm will save a lot of trouble from needing to handle
    //two different TForm classes correctly
    //This way one only needs to include Parnassus.FmxVclForm, but not FMX.Forms
    TFmxForm = FMX.Forms.TForm;
    TFmxCustomForm = FMX.Forms.TCommonCustomForm;


    { Usage:
      TFmxVclForm.CreateNew(Owner, TOriginalForm).Show;
      (derived from TForm (not from TCustomForm) to avoid problems with legacy code, that expects TForm descendand)
    --------------------------------------------------------------------------------------------------------------}
    TFmxVclForm = class(Vcl.Forms.TForm)
    private
        FFormClass: TFmxFormClass;
        FForm: TCommonCustomForm;
        FAppEvents: TApplicationEvents;
    protected
        FFireMonkeyContainer: TFireMonkeyContainer;
        procedure FireMonkeyContainerCreateFMXForm(var Form: TCommonCustomForm);
        procedure FireMonkeyContainerDestroyFMXForm(var Form: TCommonCustomForm;
          var Action: TCloseHostedFMXFormAction);
        function PropGetFireMonkeyForm: TCommonCustomForm;

        procedure WMActivate(var Msg: TWMActivate); message WM_ACTIVATE;
        //procedure WndProc(var msg : TMessage); override;
        procedure FormIdle(Sender: TObject; var Done: Boolean);

        function CloseQuery: Boolean; override;
        procedure UpdateActions; override;

        {$HINTS OFF}
        constructor Create(AOwner: TComponent); override;
        {$HINTS ON}
    public
        function ShowModal: Integer; override;
        property FireMonkeyForm: TCommonCustomForm read PropGetFireMonkeyForm;
        constructor CreateNew(AOwner: TComponent; FormClass: TFmxFormClass); reintroduce; virtual;
    public
        class function FmxToVclForm(AFmxForm: TCommonCustomForm): TFmxVclForm;
        class function FmxToVclBorderStyle(AStyle: TFMXFormBorderStyle): TFormBorderStyle;
        class function FmxToVclFormPosition(APos: TFormPosition): TPosition;
    end;


    { For forms, that need to exhibit interfaces.
      Usage:

      type
        TFmxVclFormFoo = class(TInterfacedFmxVclForm<IFoo>, IFoo)
            property Interface1: IFoo read PropGetInterface1 implements IFoo;
        end;

      TFmxVclFormFoo.CreateNew(Owner, TOriginalForm).Show;

      coverage: http://stackoverflow.com/questions/37408689/generic-parameter-to-define-the-interface-the-generic-class-is-implementing
    --------------------------------------------------------------------------------------------------------------}
    TInterfacedFmxVclForm<T: IInterface> = class(TFmxVclForm)
        function PropGetInterface1(): T;
        property Interface1: T read PropGetInterface1;
    end;


implementation

uses
    SysUtils,
    TypInfo,
    Vcl.Controls;

type
    TCommonCustomFormCracker = class(TCommonCustomForm);


constructor TFmxVclForm.Create(AOwner: TComponent);
begin
    raise Exception.Create('TFmxVclForm does not support Create(). Please use CreateNew() instead!');
end;

constructor TFmxVclForm.CreateNew(AOwner: TComponent; FormClass: TFmxFormClass);
begin
    // From the docu:
    // Use CreateNew instead of Create to create a form without using the associated .DFM file to initialize it.
    inherited CreateNew(AOwner);
    FFormClass := FormClass;

    //programmatically create FireMonkeyContainer
    FFireMonkeyContainer := TFireMonkeyContainer.Create(Self);
    FFireMonkeyContainer.Align := alClient;
    FFireMonkeyContainer.AllowTabKey := True;
    FFireMonkeyContainer.OnCreateFMXForm := FireMonkeyContainerCreateFMXForm;
    FFireMonkeyContainer.OnDestroyFMXForm := FireMonkeyContainerDestroyFMXForm;
    FFireMonkeyContainer.Parent := Self;

    //create Form - this is necessary this early, because inherited classes may need this before
    //FireMonkeyContainerCreateFMXForm is called
    FForm := FFormClass.Create(Self);
    Self.Height := FForm.Height;
    Self.Width := FForm.Width;
    Self.BorderIcons := FForm.BorderIcons;
    Self.BorderStyle := FmxToVclBorderStyle(FForm.BorderStyle);
    Self.Caption := FForm.Caption;
    Self.Cursor := FForm.Cursor;
    Self.Left := FForm.Left;
    Self.Position := FmxToVclFormPosition(FForm.Position);
    Self.WindowState := FForm.WindowState;
    //I experienced issues for instance with poScreenCenter
    FForm.Position := TFormPosition.poDefaultPosOnly;

    //create TApplicationEvents component to be able to respond to OnIdle (for ShowModal)
    FAppEvents := TApplicationEvents.Create(Self);
    FAppEvents.OnIdle := FormIdle;
end;

procedure TFmxVclForm.FireMonkeyContainerCreateFMXForm(var Form: TCommonCustomForm);
begin
    if not Assigned(Form) then
      Form := FForm;
end;

procedure TFmxVclForm.FireMonkeyContainerDestroyFMXForm(var Form: TCommonCustomForm;
  var Action: TCloseHostedFMXFormAction);
begin
    Action := fcaFree;
end;

class function TFmxVclForm.FmxToVclBorderStyle(AStyle: TFMXFormBorderStyle): TFormBorderStyle;
var
    Tmp: Integer;
begin
    //FMX: (bsNone, bsSingle, bsSizeable,           bsToolWindow, bsSizeToolWin);
    //VCL: (bsNone, bsSingle, bsSizeable, bsDialog, bsToolWindow, bsSizeToolWin);
    Tmp := Integer(AStyle);
    if Tmp >= Integer(bsToolWindow) then
      Inc(Tmp);
    Result := TFormBorderStyle(Tmp);
end;

class function TFmxVclForm.FmxToVclForm(AFmxForm: TCommonCustomForm): TFmxVclForm;
begin
    Assert(Assigned(AFmxForm));
    //---
    //Owner should always be the FmxVclForm
    if AFmxForm.Owner is TFmxVclForm then
      Result := AFmxForm.Owner as TFmxVclForm
    else
      Result := nil;
end;

class function TFmxVclForm.FmxToVclFormPosition(APos: TFormPosition): TPosition;
begin
    //FMX: TFormPosition = (poDesigned, poDefault, poDefaultPosOnly, poDefaultSizeOnly, poScreenCenter, poDesktopCenter, poMainFormCenter, poOwnerFormCenter);
    //VCL: TPosition =     (poDesigned, poDefault, poDefaultPosOnly, poDefaultSizeOnly, poScreenCenter, poDesktopCenter, poMainFormCenter, poOwnerFormCenter);
    Result := TPosition(APos);
end;

//The form should respect CloseQuery of the wrapped form
function TFmxVclForm.CloseQuery: Boolean;
begin
    Result := inherited CloseQuery;
    if Result and Assigned(FForm) and Assigned(FForm.OnCloseQuery) then
      FForm.OnCloseQuery(Self, Result);
end;


function TFmxVclForm.PropGetFireMonkeyForm: TCommonCustomForm;
begin
    Result := FForm;
    //this might not be available yet: Result := FFireMonkeyContainer.FireMonkeyForm;
end;


//Workaround for issue #12 (Caret is gone after switching applications via taskbar)
procedure TFmxVclForm.WMActivate(var Msg: TWMActivate);
begin
  if not (GetWindowLong(Handle, GWL_STYLE) and WS_CHILD = WS_CHILD) and (FormStyle <> fsMDIForm) then
    if Msg.Active <> WA_INACTIVE then
      FForm.Active := True;
    //better??
    //FForm.Active := (Msg.Active <> WA_INACTIVE);
end;

//This function and TFmxVclForm.WndProc play together to allow ShowModal of the VCL form while listening to
//ModalResult values of the FMX form
function TFmxVclForm.ShowModal: Integer;
begin
    //without this the form will close immediately once FForm ModalResult had been modified before
    if Assigned(FForm) then
      FForm.ModalResult := 0;
    Result := inherited ShowModal;
end;

procedure TFmxVclForm.UpdateActions;
begin
    //I think there is no need to call inherited UpdateActions (in this scenario) but I might be wrong:
    //inherited;
    if Assigned(FForm) then
      //access protected function UpdateActions:
      TCommonCustomFormCracker(FForm).UpdateActions();
end;

//Overwrite message handling to grab changes to ModalResult
//This did not do the job, because you could set ModalResult without triggering additional Messages (eg by keyboard)
//procedure TFmxVclForm.WndProc(var msg: TMessage);
//begin
//  inherited;
//  if (ModalResult = 0) and (Assigned(FForm)) and (FForm.ModalResult <> 0) then
//    ModalResult := FForm.ModalResult;
//end;

//Update changes to ModalResult
//this will not work, if the form never gets idle
//A solution would be to add TFmxVclForm.WndProc again, but I doubt it is really necessary
procedure TFmxVclForm.FormIdle(Sender: TObject; var Done: Boolean);
begin
  // get ModalResult of wrapped form. Otherwise TButton.ModalResult etc. wont work
  // VCL's ShowModal will check ModalResult in a loop where only Application.HandleMessage is called
  if (ModalResult = 0) and (Assigned(FForm)) and (FForm.ModalResult <> 0) then
    ModalResult := FForm.ModalResult;
end;


{ TInterfacedFmxVclForm<T> }

function TInterfacedFmxVclForm<T>.PropGetInterface1: T;
begin
    //see http://stackoverflow.com/questions/4418278/use-of-supports-function-with-generic-interface-type
    if not Supports(PropGetFireMonkeyForm(), GetTypeData(TypeInfo(T))^.Guid, Result) then
      raise Exception.Create('Interface not implemented');
end;

end.
