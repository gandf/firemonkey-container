unit VCLFullsizeForm;

{
    This demo demonstrates two ways to display a fullsize FMX form in a VCL application
}

interface

uses
  FMX.Forms { must be included before Vcl.Forms so that 'TForm' below refers to a VCL form, not FMX},
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Parnassus.FMXContainer, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.ComCtrls;

type
  TForm1 = class(TForm)
    FireMonkeyContainer: TFireMonkeyContainer;
    procedure FireMonkeyContainerCreateFMXForm(var Form: TCommonCustomForm);
    procedure FireMonkeyContainerDestroyFMXForm(var Form: TCommonCustomForm;
      var Action: TCloseHostedFMXFormAction);
  private
    { Private declarations }
    procedure OpenAnotherFormStandardClick(Sender: TObject);
    procedure OpenAnotherFormAlternativeClick(Sender: TObject);
    function Show3D: Boolean;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  Parnassus.FmxVclForm,
  FMXForm, FMX3DForm,
  FMX.Types;


//Traditional way:
//A container form is designed (VclFullsizeForm), a firemonkay container is placed inside.
//The VCL form is created and loads the FMX form in the predefined area
procedure TForm1.OpenAnotherFormStandardClick(Sender: TObject);
begin
  TForm1.Create(Application).Show;
end;

//Alternative way:
//VCL container form is automatically generated
procedure TForm1.OpenAnotherFormAlternativeClick(Sender: TObject);
begin
  if Show3D then
    TFmxVclForm.CreateNew(Application, TFormExample3D).Show
  else
    TFmxVclForm.CreateNew(Application, TFireMonkeyForm).Show;
end;

//This callback is only needed for the traditional way
procedure TForm1.FireMonkeyContainerCreateFMXForm(var Form: TCommonCustomForm);
var
    FmForm: TFireMonkeyForm;
begin
  if not Assigned(Form) then
  begin
    FmForm := TFireMonkeyForm.Create(Self);
    FmForm.GroupBox1.Align := TAlignLayout.alClient;      //to show it behaves right
    FmForm.Button2.Text := 'Try the Switch';
    FmForm.Button1.OnClick := OpenAnotherFormStandardClick;
    FmForm.Button2.OnClick := OpenAnotherFormAlternativeClick;
    Form := FmForm;
  end;
end;

procedure TForm1.FireMonkeyContainerDestroyFMXForm(var Form: TCommonCustomForm;
  var Action: TCloseHostedFMXFormAction);
begin
  Action := fcaFree;
end;

//The Switch position of the contained FMX form is used to determine 3D or not 3D
function TForm1.Show3D: Boolean;
begin
  Result := True;
  if FireMonkeyContainer.FireMonkeyForm is TFireMonkeyForm then
    Result := not (FireMonkeyContainer.FireMonkeyForm as TFireMonkeyForm).Switch1.IsChecked;
end;


end.
