program LerSat;

uses
  System.StartUpCopy,
  FMX.Forms,
  ufrmPrincipal in 'src\ufrmPrincipal.pas' {frmPrincipal},
  uFancyDialog in 'src\uFancyDialog.pas',
  uLoading in 'src\uLoading.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
