program lab2;

uses
  Forms,
  main in 'main.pas' {FormMetrick};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMetrick, FormMetrick);
  Application.Run;
end.
