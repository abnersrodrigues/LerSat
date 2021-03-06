unit ufrmPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, System.Rtti,
  FMX.Grid.Style, FMX.ScrollBox, FMX.Grid, ACBrBase, ACBrSAT, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Data.Bind.EngExt, Fmx.Bind.DBEngExt, Fmx.Bind.Grid,
  System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.Components,
  Data.Bind.Grid, Data.Bind.DBScope

  //Units do Sistema
  , uFancyDialog, uLoading


  ;

type
  TfrmPrincipal = class(TForm)
    lay_header: TLayout;
    lay_cupons: TLayout;
    lay_itens: TLayout;
    lbl_caminho_leg: TLabel;
    lbl_caminho: TLabel;
    rect_listar: TRectangle;
    lbl_listar: TLabel;
    grd_itens: TStringGrid;
    ACBrSATCupons: TACBrSAT;
    ACBrSATItens: TACBrSAT;
    Rectangle1: TRectangle;
    StyleBook: TStyleBook;
    Rectangle2: TRectangle;
    Rectangle3: TRectangle;
    qry_cupons: TFDMemTable;
    qry_itens: TFDMemTable;
    ds_cupons: TDataSource;
    ds_itens: TDataSource;
    OpenDialog: TOpenDialog;
    qry_cuponsXCLIENTE: TStringField;
    qry_cuponsXCPFCNPJ: TStringField;
    qry_cuponsXQUANTIDADE_ITENS: TIntegerField;
    qry_cuponsXSOMA_VALOR: TCurrencyField;
    qry_cuponsXSOMA_DESCONTO: TCurrencyField;
    qry_cuponsXSOMA_VALOR_DESCONTO: TCurrencyField;
    qry_cuponsXSOMA_PAGAMENTO: TCurrencyField;
    qry_cuponsXARQUIVO: TStringField;
    qry_itensXNUMERO_ITEM: TIntegerField;
    qry_itensXCODIGO_BARRA: TStringField;
    qry_itensXPRODUTO: TStringField;
    qry_itensXQUANTIDADE: TCurrencyField;
    qry_itensXVALOR_UNITARIO: TCurrencyField;
    qry_itensXDESCONTO: TCurrencyField;
    qry_itensXVALOR_TOTAL: TCurrencyField;
    qry_itensXVALOR_TOTAL_DESCONTO: TCurrencyField;
    qry_itensXNCM: TStringField;
    qry_itensXCFOP: TStringField;
    lbl_feedback_cupom: TLabel;
    lbl_feedback_item: TLabel;
    grd_cupons: TStringGrid;
    bs_itens: TBindSourceDB;
    bs_cupons: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkGridToDataSourcebs_itens: TLinkGridToDataSource;
    LinkGridToDataSourcebs_cupons: TLinkGridToDataSource;
    Layout1: TLayout;
    lbl_qtde_cupons: TLabel;
    Layout2: TLayout;
    lbl_qtde_itens: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure grd_cuponsCellClick(const Column: TColumn; const Row: Integer);
    procedure rect_listarClick(Sender: TObject);
  private

    { Private declarations }
  public
    { Public declarations }

    fancy : TFancyDialog;


    function SATLerXML  : Boolean;
    function ListaArquivos(sDiretorio, sExtensao: String;
      iTipoExibicao     : Integer; bPasta: Boolean): TStringList;
    function ListaItens : Boolean;

  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.fmx}

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  fancy := TFancyDialog.Create(frmPrincipal);
end;

procedure TfrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  fancy.DisposeOf;

  Action := TCloseAction.caFree;
  frmPrincipal := nil;
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
  grd_cupons.Visible  := false;
  grd_itens.Visible  := false;
end;

procedure TfrmPrincipal.grd_cuponsCellClick(const Column: TColumn; const Row:
    Integer);
begin
  TLoading.Show(lay_itens, 'Aguarde listando itens');

  qry_itens.Close;
  grd_itens.Visible         := false;
  lbl_feedback_item.Visible := false;

  TThread.CreateAnonymousThread(procedure
  Begin
    Sleep(500);
    TThread.Synchronize(nil, procedure
    Begin
      TLoading.Hide;
      ListaItens;
    end);
  end).Start;
end;

procedure TfrmPrincipal.rect_listarClick(Sender: TObject);
begin
  if OpenDialog.Execute() then
    Begin
      lbl_caminho.Text := ExtractFilePath( OpenDialog.FileName );
    End;

  qry_cupons.Close;
  SATLerXML;
end;

function TfrmPrincipal.ListaArquivos(sDiretorio, sExtensao: String; iTipoExibicao: Integer; bPasta: Boolean): TStringList;
var srFiles : TSearchRec;
    iCont, iRet : Integer;
    lstSwap : TStringList;
    sCaminho : String;

begin
   try
      Result:=TStringList.Create;
      Result.Clear;

      lstSwap:=TStringList.Create;
      lstSwap.Clear;

      iRet := FindFirst(IncludeTrailingPathDelimiter(sDiretorio)+'*.'+sExtensao, faAnyFile, srFiles);

      while iRet = 0 do
         begin
            if (srFiles.Name <> '.') And (srFiles.Name <> '..') then
               begin
                  case iTipoExibicao of
                     0 : // Caminho Completo
                        begin
                           if srFiles.Attr=32 then
                              Result.Add(IncludeTrailingPathDelimiter(sDiretorio)+srFiles.Name)
                           else if srFiles.Attr=16 then
                              begin
                                 if bPasta then
                                    Result.Add('#'+IncludeTrailingPathDelimiter(sDiretorio)+srFiles.Name);

                                 sCaminho :=  '';
                                 sCaminho :=  IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(sDiretorio)+srFiles.Name);

                                 lstSwap  := ListaArquivos(sCaminho, '*', 0, true);

                                 for iCont:=0 to lstSwap.Count-1 do
                                    Result.Add(lstSwap.Strings[iCont]);

                                 lstSwap.Clear;
                              end;
                        end;
                  end;
               end;

            iRet := FindNext(srFiles);
         end;
   except
      Result:=nil;
   end;
end;

function TfrmPrincipal.ListaItens:Boolean;
var iCont : Integer;
    sArquivo : String;
begin
  try
    if not qry_cupons.IsEmpty then
       begin
          sArquivo  :=  qry_cupons.FieldByName('XARQUIVO').AsString;

          qry_itens.Open;

          if FileExists(sArquivo) then
             begin
                ACBrSATItens.CFe.Clear;
                ACBrSATItens.CFe.LoadFromFile(sArquivo);

                for iCont:=0 to ACBrSATItens.CFe.Det.Count-1 do
                   begin
                      with qry_itens do
                         begin
                            Append;

                            FieldByName('XNUMERO_ITEM').Value           := ACBrSATItens.CFe.Det.Items[iCont].nItem;
                            FieldByName('XCODIGO_BARRA').Value          := ACBrSATItens.CFe.Det.Items[iCont].Prod.cProd;
                            FieldByName('XPRODUTO').Value               := ACBrSATItens.CFe.Det.Items[iCont].Prod.xProd;
                            FieldByName('XQUANTIDADE').Value            := ACBrSATItens.CFe.Det.Items[iCont].Prod.qCom;
                            FieldByName('XVALOR_UNITARIO').Value        := ACBrSATItens.CFe.Det.Items[iCont].Prod.vUnCom;
                            FieldByName('XDESCONTO').Value              := ACBrSATItens.CFe.Det.Items[iCont].Prod.vDesc;
                            FieldByName('XVALOR_TOTAL').Value           := (ACBrSATItens.CFe.Det.Items[iCont].Prod.qCom * ACBrSATItens.CFe.Det.Items[iCont].Prod.vUnCom);
                            FieldByName('XVALOR_TOTAL_DESCONTO').Value  := (ACBrSATItens.CFe.Det.Items[iCont].Prod.qCom * ACBrSATItens.CFe.Det.Items[iCont].Prod.vUnCom) - ACBrSATItens.CFe.Det.Items[iCont].Prod.vDesc;
                            FieldByName('XNCM').Value                   := ACBrSATItens.CFe.Det.Items[iCont].Prod.NCM;
                            FieldByName('XCFOP').Value                  := ACBrSATItens.CFe.Det.Items[iCont].Prod.CFOP;

                            Post;
                         end;
                   end;

                qry_itens.First;
             end;
       end;
    Result := true;
  except
    Result := false;
  end;

  //fancy.Show(TIconDialog.Success, 'Sucesso!', 'Listagem finalizada.', 'OK');
  lbl_qtde_itens.Text := 'Total de encontrado: '+ qry_itens.RecordCount.ToString;

  if qry_itens.RecordCount < 1
  then
  Begin
    lbl_feedback_item.Text    := 'NENHUM ITEM ENCONTRADO';
    lbl_feedback_item.Visible  := true;
    grd_itens.Visible          := false;
  End
  else
  Begin
    lbl_feedback_item.Visible  := false;
    grd_itens.Visible          := true;
  End;
end;

function TfrmPrincipal.SATLerXML: Boolean;
var iCont, jCont : Integer;
    lstArquivos : TStringList;
    sArquivo : String;
    cValor, cDesconto, cPagamento : Currency;
begin
   try
      lstArquivos := TStringList.Create;
      lstArquivos.Clear;
      lstArquivos := ListaArquivos(IncludeTrailingPathDelimiter(Trim(lbl_caminho.Text)), 'xml', 0, true);

      qry_cupons.Open;

      if lstArquivos.Count>0 then
         begin
            for iCont:=0 to lstArquivos.Count-1 do
               begin
                  sArquivo:=lstArquivos.Strings[iCont];

                  ACBrSATCupons.CFe.Clear;
                  ACBrSATCupons.CFe.LoadFromFile(sArquivo);

                  if ACBrSATCupons.CFe.Det.Count > 0 then
                     begin
                        with qry_cupons do
                           begin
                              Append;

                              cValor:=0.00;
                              cDesconto:=0.00;
                              cPagamento:=0.00;

                              if Trim(ACBrSATCupons.CFe.Dest.xNome)<>'' then
                                 FieldByName('XCLIENTE').Value            := ACBrSATCupons.CFe.Dest.xNome
                              else
                                 FieldByName('XCLIENTE').Value            := 'N?O INFORMADO';

                              if Trim(ACBrSATCupons.CFe.Dest.xNome)<>'' then
                                 FieldByName('XCPFCNPJ').Value            := ACBrSATCupons.CFe.Dest.CNPJCPF
                              else
                                 FieldByName('XCPFCNPJ').Value            :='00000000000';

                              FieldByName('XQUANTIDADE_ITENS').Value      := ACBrSATCupons.CFe.Det.Count;

                              for jCont:=0 to ACBrSATCupons.CFe.Det.Count-1 do
                                 begin
                                    cValor                                := cValor+(ACBrSATCupons.CFe.Det.Items[jCont].Prod.vUnCom * ACBrSATCupons.CFe.Det.Items[jCont].Prod.qCom);
                                    cDesconto                             := cDesconto + ACBrSATCupons.CFe.Det.Items[jCont].Prod.vDesc;
                                 end;

                              FieldByName('XSOMA_VALOR').Value            := cValor;
                              FieldByName('XSOMA_DESCONTO').Value         := cDesconto;
                              FieldByName('XSOMA_VALOR_DESCONTO').Value   := cValor-cDesconto;

                              for jCont:=0 to ACBrSATCupons.CFe.Pagto.Count-1 do
                                 cPagamento                               := cPagamento + ACBrSATCupons.CFe.Pagto.Items[jCont].vMP;

                              FieldByName('XSOMA_PAGAMENTO').Value        := cPagamento;
                              FieldByName('XARQUIVO').Value               := sArquivo;

                              Post;
                           end;
                     end;
               end;
         end;

      fancy.Show(TIconDialog.Success, 'Sucesso!', 'Listagem finalizada.', 'OK');
      lbl_qtde_cupons.Text    := 'Total de encontrado: '+ qry_cupons.RecordCount.ToString;

      lbl_feedback_item.Text    := 'AGUARDANDO SELE??O DO CUPOM';
      lbl_feedback_item.Visible := True;

      if qry_cupons.RecordCount < 1
      then
        Begin
          lbl_feedback_cupom.Visible  := true;
          grd_cupons.Visible          := false;
        End
      else
        Begin
          lbl_feedback_cupom.Visible  := false;
          grd_cupons.Visible          := true;
        End;

      Result:=True;

   except
      Result:=False;
   end;
end;

end.
