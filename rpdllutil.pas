{*******************************************************}
{                                                       }
{       Report Manager                                  }
{                                                       }
{       rpdllutil                                       }
{       Exported functions for the Standarc C Library   }
{                                                       }
{       Copyright (c) 1994-2003 Toni Martir             }
{       toni@pala.com                                   }
{                                                       }
{       This file is under the MPL license              }
{       If you enhace this file you must provide        }
{       source code                                     }
{                                                       }
{                                                       }
{*******************************************************}

unit rpdllutil;

{$I rpconf.inc}

interface

uses SysUtils,Classes,rpreport,rpmdconsts,rppdfdriver,
{$IFDEF USEVARIANTS}
 Variants,
{$ENDIF}
 rptypes,rpeval,rptypeval,rpdatainfo,rppdfreport,
 rpparams,rpcsvdriver,rptextdriver,
{$IFDEF MSWINDOWS}
 rpexceldriver,Comobj,
 rpgdidriver,
 Graphics,
 Printers,rpvgraphutils,
{$ENDIF}
 rphtmldriver,
 rpsvgdriver;

var
 lreports:TStringList;
 lasthandle:integer;
 rplasterror:String;

function rp_new:integer;stdcall;
function rp_open(filename:PAnsiChar):integer;stdcall;
function rp_openw(filename:PWideChar):integer;stdcall;
function rp_execute(hreport:integer;outputfilename:PAnsiChar;metafile,
 compressed:integer):integer;stdcall;
function rp_executeW(hreport:integer;outputfilename:PWideChar;metafile,
 compressed:integer):integer;stdcall;
function rp_executeremote(hostname:PAnsiChar;port:integer;user,password,aliasname,reportname:PAnsiChar;outputfilename:PAnsiChar;metafile,
 compressed:integer):integer;stdcall;
function rp_executeremotew(hostname:PWideChar;port:integer;user,password,aliasname,reportname:PWideChar;outputfilename:PWideChar;metafile,
 compressed:integer):integer;stdcall;
function rp_executeremote_report(hreport:integer;hostname:PAnsiChar;port:integer;user,password,aliasname,reportname:PAnsiChar;outputfilename:PAnsiChar;metafile,
 compressed:integer):integer;stdcall;
function rp_executeremote_reportW(hreport:integer;hostname:PWideChar;port:integer;user,password,aliasname,reportname:PWideChar;outputfilename:PWideChar;metafile,
 compressed:integer):integer;stdcall;
function rp_getremoteparams(hreport:integer;hostname:PAnsiChar;port:integer;user,password,aliasname,reportname:PAnsiChar):integer;stdcall;
function rp_getremoteparamsw(hreport:integer;hostname:PWideChar;port:integer;user,password,aliasname,reportname:PWideChar):integer;stdcall;
function rp_close(hreport:integer):integer;stdcall;
function rp_lasterror:PAnsiChar;stdcall;
function rp_lasterrorw:PWideChar;stdcall;
function rp_setparamvalue(hreport:integer;paramname:pansichar;paramtype:integer;
 paramvalue:Pointer):integer;stdcall;
function rp_setparamvaluew(hreport:integer;paramname:pWidechar;paramtype:integer;
 paramvalue:Pointer):integer;stdcall;
function rp_getparamcount(hreport:integer;var paramcount:Integer):integer;stdcall;
function rp_getparamname(hreport:integer;index:integer;
 abuffer:PAnsiChar):integer;stdcall;
function rp_getparamnameW(hreport:integer;index:integer;
 abuffer:PWideChar):integer;stdcall;

{$IFDEF MSWINDOWS}
function rp_setparamvaluevar(hreport:integer;paramname:pAnsichar;
 paramvalue:OleVariant):integer;stdcall;
function rp_setparamvaluevarw(hreport:integer;paramname:pWidechar;
 paramvalue:OleVariant):integer;stdcall;
function rp_setadoconnectionstring(hreport:integer;conname:pAnsichar;
 constring:PAnsiChar):integer;stdcall;
function rp_setadoconnectionstringw(hreport:integer;conname:pWidechar;
 constring:PWideChar):integer;stdcall;
function rp_getdefaultprinter:pAnsichar;stdcall;
function rp_getdefaultprinterw:pWidechar;stdcall;
function rp_getprinters:pAnsichar;stdcall;
function rp_getprintersw:pWidechar;stdcall;
function rp_setdefaultprinter(device:pAnsichar):integer;stdcall;
function rp_setdefaultprinterw(device:pWidechar):integer;stdcall;
{$ENDIF}

function FindReportIndex(hreport:integer):integer;
function FindReport(hreport:integer):TRpReport;
procedure rplibdoinit;
{$IFDEF LINUX}
procedure DLLHandler(Reason: Integer);
{$ENDIF}

implementation


procedure rplibdoinit;
var
 found:boolean;
 aclass:TPersistentClass;
begin
 if Assigned(lreports) then
  exit;
 lreports:=TStringList.Create;
 lreports.sorted:=True;
 lasthandle:=1;
 rplasterror:='';
 aclass:=GetClass('TRpReport');
 found:=true;
 if aclass=nil then
  found:=false;
 if found then
 begin
  rpreport.RegisterRpReportClasses;
  rptypeval.DefaultDecimals:=2;
 end;
end;


function FindReportIndex(hreport:integer):integer;
var
 index:integer;
begin
 rplibdoinit;
 index:=lreports.IndexOf(IntToStr(hreport));
 if index<0 then
  Raise Exception.Create(SRpSInvReportHandle+' - '+IntTostr(hreport));
 Result:=index;
end;

function FindReport(hreport:integer):TRpReport;
var
 index:integer;
begin
 rplibdoinit;
 index:=FindReportIndex(hreport);
 Result:=TRpReport(lreports.Objects[index]);
end;

function rp_open(filename:PAnsiChar):integer;
begin
 Result:=rp_openw(PWideChar(WideString(filename)));
end;


function rp_openw(filename:PWideChar):integer;
var
 report:TRpReport;
begin
 rplibdoinit;
 rplasterror:='';
 try
  report:=TRpReport.Create(nil);
  try
   report.LoadFromFile(filename);
   inc(lasthandle);
   Result:=lasthandle;
   lreports.AddObject(IntToStr(lasthandle),report);
  except
   on E:Exception do
   begin
    report.free;
    raise;
   end;
  end;
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;

function rp_new:integer;
var
 report:TRpReport;
begin
 rplibdoinit;
 rplasterror:='';
 try
  report:=TRpReport.Create(nil);
  try
   inc(lasthandle);
   Result:=lasthandle;
   lreports.AddObject(IntToStr(lasthandle),report);
  except
   on E:Exception do
   begin
    report.free;
    raise;
   end;
  end;
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;

function rp_execute(hreport:integer;outputfilename:PAnsiChar;metafile,compressed:integer):integer;
begin
 Result:=rp_executew(hreport,PWideChar(WideString(outputfilename)),metafile,compressed);
end;

function rp_executew(hreport:integer;outputfilename:PWideChar;metafile,compressed:integer):integer;
var
 report:TRpReport;
 acompressed:boolean;
 adriver:TRpPdfDriver;
{$IFDEF MSWINDOWS}
 mono:boolean;
 horzres,vertres:integer;
 abitmap:TBitmap;
{$ENDIF}
begin
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  if compressed=0 then
   acompressed:=false
  else
   acompressed:=true;
  report:=FindReport(hreport);
  case metafile of
   0:
    begin
     rppdfdriver.PrintReportPDF(report,'',false,true,1,99999,1,
      StrPas(outputfilename),acompressed,false);
    end;
   1:
    begin
     rppdfdriver.PrintReportToMetafile(report,'',false,true,1,99999,1,
      StrPas(outputfilename),false);
    end;
   2:
    begin
     report.TwoPass:=true;
     adriver:=TRpPdfDriver.Create;
     try
      report.PrintAll(adriver);
      ExportMetafileToCSV(report.metafile,StrPas(outputfilename),true,true,
        1,9999,',');
     finally
      adriver.free;
     end;
    end;
   3,10:
    begin
     report.TwoPass:=true;
     adriver:=TRpPdfDriver.Create;
     try
      if (metafile=10) then
      begin
       ExportReportToHtmlSingle(report,StrPas(outputfilename));
      end
      else      
      begin
        report.PrintAll(adriver);
        ExportMetafileToHtml(report.Metafile,'',StrPas(outputfilename),
          true,true,1,9999);
      end
     finally
      adriver.free;
     end;
    end;
   4:
    begin
     report.TwoPass:=true;
     adriver:=TRpPdfDriver.Create;
     try
      report.PrintAll(adriver);
      ExportMetafileToSVG(report.Metafile,'',StrPas(outputfilename),
       true,true,1,9999);
     finally
      adriver.free;
     end;
    end;
   5:
    begin
{$IFDEF MSWINDOWS}
     report.TwoPass:=true;
     adriver:=TRpPdfDriver.Create;
     try
      report.PrintAll(adriver);
      horzres:=100;
      vertres:=100;
      mono:=true;
      if AskBitmapProps(horzres,vertres,mono) then
      begin
       abitmap:=MetafileToBitmap(report.Metafile,true,mono,horzres,vertres);
       try
        if assigned(abitmap) then
         abitmap.SaveToFile(StrPas(outputfilename));
       finally
        abitmap.free;
       end;
      end;
     finally
      adriver.free;
     end;
{$ENDIF}
{$IFDEF LINUX}
    raise Exception.Create(SRpError+'-'+SRpParameter+':'+'metafile'+
     ' function:rp_execute, bitmap output not supported, use rp_bitmap instead ');
{$ENDIF}
    end;
   6:
    begin
     report.TwoPass:=true;
     adriver:=TRpPdfDriver.Create;
     try
      report.PrintAll(adriver);
      SaveMetafileToTextFile(report.Metafile,StrPas(outputfilename));
     finally
      adriver.free;
     end;
    end;
   7:
    begin
     report.TwoPass:=true;
     adriver:=TRpPdfDriver.Create;
     try
      report.PrintAll(adriver);
      ExportMetafileToTextPro(report.metafile,StrPas(outputfilename),true,true,
        1,9999);
     finally
      adriver.free;
     end;
    end;
   8,9:
    begin
{$IFDEF MSWINDOWS}
     report.TwoPass:=true;
     adriver:=TRpPdfDriver.Create;
     try
      report.PrintAll(adriver);
       ExportMetafileToExcel(report.Metafile,StrPas(outputfilename),
        true,false,true,1,9999,metafile=9);
     finally
      adriver.free;
     end;
{$ENDIF}
{$IFDEF LINUX}
    raise Exception.Create(SRpError+'-'+SRpParameter+':'+'metafile'+
     ' function:rp_execute, excel output not supported ');
{$ENDIF}
    end;

   else
    raise Exception.Create(SRpError+'-'+SRpParameter+':'+'metafile'+
     ' function:rp_execute ');
  end;
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;

function rp_getremoteparams(hreport:integer;hostname:PAnsiChar;port:integer;user,password,aliasname,reportname:PAnsiChar):integer;stdcall;
begin
 Result:=rp_getremoteparamsw(hreport,PWideChar(WideString(hostname)),port,PWideChar(WideString(user)),pWidechar(WideString(password)),pWidechar(WideString(aliasname)),pWidechar(WideString(reportname)));
end;

function rp_getremoteparamsw(hreport:integer;hostname:PWideChar;port:integer;user,password,aliasname,reportname:PWideChar):integer;stdcall;
var
  pdfreport:TPDFReport;
  report:TRpReport;
begin
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  report:=FindReport(hreport);
  pdfreport:=TPDFReport.Create(nil);
  try
   pdfreport.GetRemoteParams(hostname,port,user,password,aliasname,reportname);
   report.params.Assign(pdfreport.Report.Params);
  finally
   pdfreport.free;
  end;
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;

function rp_executeremote_report(hreport:integer;hostname:PAnsiChar;port:integer;user,password,aliasname,reportname:PAnsiChar;outputfilename:PAnsiChar;metafile,
 compressed:integer):integer;
begin
  rp_executeremote_reportw(hreport,PWideChar(WideString(hostname)),port,PWideChar(WideString(user)),PWidechar(WideString(password)),PWidechar(WideString(aliasname)),PWidechar(WideString(reportname)),
   PWideChar(WideString(outputfilename)),metafile,compressed);
end;

function rp_executeremote_reportw(hreport:integer;hostname:PWideChar;port:integer;user,password,aliasname,reportname:PWideChar;outputfilename:PWideChar;metafile,
 compressed:integer):integer;
var
 pdfreport:TPDFReport;
 report:TRpReport;
 memstream:TMemoryStream;
begin
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  report:=FindReport(hreport);
  pdfreport:=TPDFReport.Create(nil);
  try
   memstream:=TMemoryStream.Create;
   try
    report.SaveToStream(memstream);
    memstream.Seek(0,soFromBeginning);
    pdfreport.LoadFromStream(memstream);
   finally
    memstream.free;
   end;
   pdfreport.PDFFilename:=outputfilename;
   pdfreport.Compressed:=(compressed<>0);
   pdfreport.AsMetafile:=(metafile<>0);
   pdfreport.ExecuteRemote(hostname,port,user,password,aliasname,reportname);
  finally
   pdfreport.free;
  end;
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;

function rp_executeremote(hostname:PAnsiChar;port:integer;user,password,aliasname,reportname:PAnsiChar;outputfilename:PAnsiChar;metafile,
 compressed:integer):integer;
begin
 Result:= rp_executeremotew(PWidechar(WideString(hostname)),port,PWidechar(WideString(user)),PWidechar(WideString(password)),pWidechar(WideString(aliasname)),PWidechar(WideString(reportname)),
   pWidechar(WideString(outputfilename)),metafile,compressed);
end;

function rp_executeremotew(hostname:PWideChar;port:integer;user,password,aliasname,reportname:PWideChar;outputfilename:PWideChar;metafile,
 compressed:integer):integer;
var
 pdfreport:TPDFReport;
begin
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  pdfreport:=TPDFReport.Create(nil);
  try
   pdfreport.PDFFilename:=outputfilename;
   pdfreport.Compressed:=(compressed<>0);
   pdfreport.AsMetafile:=(metafile<>0);
   pdfreport.ExecuteRemote(hostname,port,user,password,aliasname,reportname);
  finally
   pdfreport.free;
  end;
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;


function rp_close(hreport:integer):integer;
var
 index:integer;
begin
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  index:=FindReportIndex(hreport);
  TRpReport(lreports.Objects[index]).free;
  lreports.delete(index);
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;

{$IFDEF MSWINDOWS}
function rp_setdefaultprinter(device:pAnsichar):integer;
begin
  Result:=rp_setdefaultprinterw(PWideChar(WideString(device)));
end;

function rp_setdefaultprinterw(device:pWidechar):integer;
var
 adevice:string;
 i:integer;
 itemindex:integer;
 printerlist:string;
begin
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  adevice:=UpperCase(device);
  itemindex:=-1;
  printerlist:='';
  for i:=0 to printer.printers.count-1 do
  begin
   if UpperCase(printer.printers.strings[i])=adevice then
   begin
    itemindex:=i;
    break;
   end;
   printerlist:=printerlist+printer.printers.strings[i]+#10;
  end;
  if itemindex<0 then
   Raise Exception.Create(SRpErrorOpenImp+':'+device+#10+printerlist);
  SwitchToPrinterIndex(itemindex);
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;


function rp_getprinters:pAnsichar;
begin
 Result:=PAnsiChar(AnsiString(rp_getprintersw));
end;

function rp_getprintersw:pWidechar;
var
 i:integer;
 aresult:String;
begin
 rplibdoinit;
 rplasterror:='';
 try
  aresult:='';
  for i:=0 to printer.printers.count-1 do
  begin
   if i>0 then
    aResult:=aResult+#10;
   aResult:=aResult+printer.printers[i];
  end;
  Result:=PWidechar(aresult);
 except
  on E:Exception do
  begin
   Result:=PWideChar(E.Message);
  end;
 end;
end;

function rp_getdefaultprinter:pAnsichar;
begin
 Result:=PAnsiChar(AnsiString(rp_getdefaultprinterw));
end;


function rp_getdefaultprinterw:pWidechar;
var
 aresult:String;
begin
 rplibdoinit;
 rplasterror:='';
 try
  aResult:='';
  if printer.printerindex>0 then
   aResult:=printer.printers[printer.printerindex];
  Result:=PWidechar(aresult);
 except
  on E:Exception do
  begin
   Result:=PWideChar(E.Message);
  end;
 end;
end;


{$ENDIF}

function rp_setparamvalue(hreport:integer;paramname:pAnsichar;paramtype:integer;
 paramvalue:Pointer):integer;
begin
 Result:=rp_setparamvaluew(hreport,PWidechar(WideString(paramname)),paramtype,paramvalue);
end;

function rp_setparamvaluew(hreport:integer;paramname:pWidechar;paramtype:integer;
 paramvalue:Pointer):integer;
var
 report:TRpReport;
 aparam:TRpParam;
begin
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  report:=FindReport(hreport);
  aparam:=report.params.ParamByName(Strpas(paramname));
  case paramtype of
   1:
    aparam.Value:=Null;
   3:
    aparam.Value:=integer(paramvalue^);
   5:
    aparam.Value:=double(paramvalue^);
   6:
    aparam.Value:=Currency(paramvalue^);
   7:
    aparam.Value:=TDateTime(paramvalue^);
   8:
    aparam.Value:=WideCharToString(PWideChar(paramvalue));
   11:
    aparam.Value:=Boolean(paramvalue^);
   14:
{$IFDEF USEVARIANTS}
    aparam.Value:=Int64(paramvalue^);
{$ENDIF}
{$IFNDEF USEVARIANTS}
    aparam.Value:=Integer(paramvalue^);
{$ENDIF}
   256:
    aparam.Value:=StrPas(PChar(paramvalue));
   else
    Raise Exception.Create(SRpEvalType+' - '+IntToStr(paramtype));
  end;
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;

function rp_getparamname(hreport:integer;index:integer;abuffer:PAnsiChar):integer;
begin
 Result:=rp_getparamnamew(hreport,index,PWidechar(WideString(abuffer)));
end;


function rp_getparamnamew(hreport:integer;index:integer;abuffer:PWideChar):integer;
var
 report:TRpReport;
 aparam:TRpParam;
begin
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  report:=FindReport(hreport);
  aparam:=report.params.items[index];
  StrPCopy(abuffer,aparam.Name);
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;


function rp_getparamcount(hreport:integer;var paramcount:Integer):integer;
var
 report:TRpReport;
begin
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  report:=FindReport(hreport);
  paramcount:=report.Params.Count;
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;


{$IFDEF MSWINDOWS}
function rp_setparamvaluevar(hreport:integer;paramname:pAnsichar;
 paramvalue:OleVariant):integer;
 begin
  Result:=rp_setparamvaluevarw(hreport,PWideChar(WideString(paramname)),paramvalue);

 end;


function rp_setparamvaluevarw(hreport:integer;paramname:pWidechar;
 paramvalue:OleVariant):integer;
var
 report:TRpReport;
 aparam:TRpParam;
begin               
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  report:=FindReport(hreport);
  aparam:=report.params.ParamByName(Strpas(paramname));
  aparam.Value:=paramvalue;
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;

function rp_setadoconnectionstring(hreport:integer;conname:pAnsichar;
 constring:PAnsiChar):integer;
 begin
   Result:=rp_setadoconnectionstringw(hreport,PWideChar(WideString(conname)),PWideChar(WideString(constring)));
 end;

function rp_setadoconnectionstringw(hreport:integer;conname:pWidechar;
 constring:PWideChar):integer;
var
 report:TRpReport;
 dbinfo:TRpDatabaseInfoItem;
 index:Integer;
begin
 rplibdoinit;
 rplasterror:='';
 Result:=1;
 try
  report:=FindReport(hreport);
  index:=report.DatabaseInfo.IndexOf(StrPas(conname));
  if index<0 then
   Raise Exception.Create(SRPDabaseAliasNotFound+' - '+StrPas(conname));
  dbinfo:=report.DatabaseInfo.Items[index];
  dbinfo.ADOConnectionString:=StrPas(constring);
 except
  on E:Exception do
  begin
   rplasterror:=E.Message;
   Result:=0;
  end;
 end;
end;

{$ENDIF}


function rp_lasterror:PAnsiChar;
begin
 rplibdoinit;
 Result:=PAnsiChar(AnsiString(rplasterror));
end;

function rp_lasterrorw:PWideChar;
begin
 rplibdoinit;
 Result:=PWideChar(rplasterror);
end;


procedure FreeAllReports;
var
 i:integer;
begin
 for i:=0 to lreports.count-1 do
 begin
  TRpReport(lreports.Objects[i]).free;
 end;
 lreports.clear;
end;

{$IFDEF LINUX}
procedure DLLHandler(Reason: Integer);
begin
 // 0 means unloading, 1 means loading.
 if Reason = 0 then
 // Now we want to remove our signal handler.
 UnhookSignal(RTL_SIGDEFAULT);
end;
{$ENDIF}



initialization
 lreports:=nil;
 rplibdoinit;
finalization
 FreeAllReports;
 lreports.free;
 lreports:=nil;
end.
