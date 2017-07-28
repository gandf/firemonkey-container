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
    System.Classes,
    Vcl.StdCtrls,
    Vcl.Forms;

type
    TFmxFormClass = class of TCommonCustomForm;

    TFmxVclForm = class(Vcl.Forms.TCustomForm)
    private
        FFormClass: TFmxFormClass;
        FFireMonkeyContainer: TFireMonkeyContainer;
        FButton: TButton;
    protected
        procedure FireMonkeyContainerCreateFMXForm(var Form: TCommonCustomForm);
        procedure FireMonkeyContainerDestroyFMXForm(var Form: TCommonCustomForm;
          var Action: TCloseHostedFMXFormAction);
        class function FmxToVclBorderStyle(AStyle: TFMXFormBorderStyle): TFormBorderStyle;
        class function FmxToVclFormPosition(APos: TFormPosition): TPosition;
    public
        constructor CreateNew(AOwner: TComponent; FormClass: TFmxFormClass); virtual;
    end;

implementation

uses
    Vcl.Controls;


constructor TFmxVclForm.CreateNew(AOwner: TComponent; FormClass: TFmxFormClass);
begin
    // From the docu:
    // Use CreateNew instead of Create to create a form without using the associated .DFM file to initialize it.
    inherited CreateNew(AOwner);
    FFormClass := FormClass;
    FFireMonkeyContainer := TFireMonkeyContainer.Create(Self);
    FFireMonkeyContainer.Align := alClient;
    FFireMonkeyContainer.OnCreateFMXForm := FireMonkeyContainerCreateFMXForm;
    FFireMonkeyContainer.OnDestroyFMXForm := FireMonkeyContainerDestroyFMXForm;
    FFireMonkeyContainer.Parent := Self;
end;

procedure TFmxVclForm.FireMonkeyContainerCreateFMXForm(var Form: TCommonCustomForm);
begin
    if not Assigned(Form) then
    begin
        Form := FFormClass.Create(Self);
        Self.Height := Form.Height;
        Self.Width := Form.Width;
        Self.BorderIcons := Form.BorderIcons;
        Self.BorderStyle := FmxToVclBorderStyle(Form.BorderStyle);
        Self.Caption := Form.Caption;
        Self.Cursor := Form.Cursor;
        Self.Left := Form.Left;
        Self.Position := FmxToVclFormPosition(Form.Position);
        Self.WindowState := Form.WindowState;
    end;
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

class function TFmxVclForm.FmxToVclFormPosition(APos: TFormPosition): TPosition;
begin
    //FMX: TFormPosition = (poDesigned, poDefault, poDefaultPosOnly, poDefaultSizeOnly, poScreenCenter, poDesktopCenter, poMainFormCenter, poOwnerFormCenter);
    //VCL: TPosition =     (poDesigned, poDefault, poDefaultPosOnly, poDefaultSizeOnly, poScreenCenter, poDesktopCenter, poMainFormCenter, poOwnerFormCenter);
    Result := TPosition(APos);
end;

end.
