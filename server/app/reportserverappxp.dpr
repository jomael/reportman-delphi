{*******************************************************}
{                                                       }
{       Report Server Application with GUI              }
{                                                       }
{       reportserverappxp                               }
{                                                       }
{       Use the console appliation or the service       }
{       instead, it's more secure                       }
{                                                       }
{       Copyright (c) 1994-2002 Toni Martir             }
{       toni@pala.com                                   }
{                                                       }
{       This file is under the MPL license              }
{       If you enhace this file you must provide        }
{       source code                                     }
{                                                       }
{                                                       }
{*******************************************************}

// JCL_DEBUG_EXPERT_INSERTJDBG OFF
program reportserverappxp;

{%ToDo 'reportserverappxp.todo'}

{$I rpconf.inc}

uses
  Graphics,
  Forms,
{$IFNDEF MIDASOUT}
  midaslib,
{$ENDIF}
  fmainfvcl in 'fmainfvcl.pas' {FSerMainVCL},
  urepserver in 'urepserver.pas' {modserver: TDataModule},
  rpmdprotocol in '..\..\rpmdprotocol.pas';

{$R *.res}

begin
  Graphics.DefFontData.Name:=Screen.IconFont.Name;
  IsMultiThread:=True;
  Application.Initialize;
  Application.Title := 'Report Manager Report Server';
  Application.CreateForm(TFSerMainVCL, FSerMainVCL);
  FSerMainVCL.Font.Assign(Screen.IconFont);
  Application.Run;
end.
