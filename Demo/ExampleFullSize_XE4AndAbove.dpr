program ExampleFullSize_XE4AndAbove;

uses
  Vcl.Forms,
  VCLFullsizeForm in 'VCLFullsizeForm.pas' {Form1},
  FMXForm in 'FMXForm.pas' {FireMonkeyForm},
  FMX3DForm in 'FMX3DForm.pas' {FormExample3D};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TFormExample3D, FormExample3D);
  Application.Run;
end.
