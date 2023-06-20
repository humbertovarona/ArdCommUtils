unit ArUtils;

interface

uses
  Types, SysUtils;

Type
  TStrArr = Array [1..25] of String;
  TCalibArr = Array [1..2] of Real;


function SplitString(Str : String; Separator : String) : TStrArr;
function ConvertGPSDataToFilename(GPS_Date : String) : String;
function FindAndDeleteSubstring(Str : String; Substr : String) : String;
procedure CreateProfile(GPS_Date : String; var Datafile : TextFile; CalibParam : TCalibArr);
Procedure CloseProfile(var Datafile : TextFile);
procedure WriteProfileData(var Datafile : TextFile; Data : TStrArr; diffTime : String);
function CalibrateParam(const OldValue : String; CalibrationValue : Real) : String;
function RemovePackageTerminals(StrData : String) : String;
function ValidateData(StrData : String) : Boolean;
function StringToFloatSkipping(strval : string): Real;
function StringToDateTimeSkipping(strval : string): TDateTime;

implementation

function SplitString(Str : String; Separator : String) : TStrArr;
var
  Position, NumOfStr : Integer;
  OutStrings : TStrArr;
  CText : String;
begin
  NumOfStr:=1;
  CText := Str;
  Position:=Pos(Separator,CText);
  While Position <> 0 do
    begin
      OutStrings[NumOfStr]:=Copy(CText, 1, Position-1);
      Delete(CText, 1, Position);
      Inc(NumOfStr);
      Position:=Pos(Separator, CText);
      if Position=0 then
      OutStrings[NumOfStr]:=Copy(CText, 1, 19);
    end;
  Result:=OutStrings;
end;


function FindAndDeleteSubstring(Str : String; Substr : String) : String;
var
  Position : Integer;
  StrTemp : String;
begin
  StrTemp:=Str;
  Position:=Pos(Substr, StrTemp);
  While Position <> 0 do
    begin
      Delete(StrTemp, Position, 1);
      Position:=Pos(Substr, StrTemp);
    end;
    Result:=StrTemp;
end;


function ConvertGPSDataToFilename(GPS_Date : String) : String;

var
  Str : String;
begin
  Str:=FindAndDeleteSubstring(GPS_Date, '/');
  Result:=Copy(Str,1,8);
end;

function DateToFilename(GPS_Date : String; Extension : String) : String;
var
  filename : String;
begin
  filename:=Copy(GPS_Date,5,4)+Copy(GPS_Date,1,2)+Copy(GPS_Date,3,2);
  Result:=filename+Extension;
end;

procedure CreateProfile(GPS_Date : String; var Datafile : TextFile; CalibParam : TCalibArr);
var
  Profilename : String;
  DD : String;
begin
  Profilename:=ConvertGPSDataToFilename(GPS_Date);
  Profilename:= 'C:/Logs/Data/'+DateToFilename(Profilename, '.logs');

  AssignFile(Datafile,Profilename);
  if FileExists(Profilename) then
    Append(Datafile)
  else
    Rewrite(Datafile);
  Writeln(Datafile, 'BEGP');
  DD:=FindAndDeleteSubstring(GPS_Date, '/');
  DD:=FindAndDeleteSubstring(DD, ' ');
  DD:=FindAndDeleteSubstring(DD, ':');
  Writeln(Datafile, DD);
  Writeln(Datafile, 'CALIB ',FloatToStr(CalibParam[1]),';',FloatToStr(CalibParam[2]));
end;

Procedure CloseProfile(var Datafile : TextFile);
begin
  Writeln(Datafile, 'ENDP');
  CloseFile(Datafile);
end;

function DeleteLastChar(Str: String) : String;
begin
  Result:=Copy(Str,1,Length(Str)-1);
end;

procedure WriteProfileData(var Datafile : TextFile; Data : TStrArr; diffTime : String);
begin
  //---------------------------------------------------------------------------------
  //Writeln(Datafile, DeleteLastChar(Data[4]),';',Data[3],';',Data[5],';',Data[6],';',Data[1],';',Data[2])   // Just to simulate the data packet from the sensors
  //---------------------------------------------------------------------------------
  // Qitar comentario de la proxima linea cuando este activa la funcion GPS
  Writeln(Datafile, DeleteLastChar(Data[4]),';',diffTime,';',Data[3],';',Data[5],';',Data[6],';',Data[1],';',Data[2])
end;

function CalibrateParam(const OldValue : String; CalibrationValue : Real) : String;
var
  NewParam : Extended;
begin
  NewParam:=StringToFloatSkipping(OldValue)+CalibrationValue;
  Result:=FloatToStr(NewParam);
end;

function RemovePackageTerminals(StrData : String) : String;
var
  StrPackage : String;
begin
  StrPackage := StrData;
  Delete(StrPackage,1,6);
  Delete(StrPackage,Length(StrPackage)-5,6);
  Result := StrPackage
end;


function GetHeadPackage(StrData : String) : String;
begin
  Result := Copy(StrData,1,6)
end;

function GetEndPackage(StrData : String) : String;
begin
  Result := Copy(StrData,Length(StrData)-5,6)
end;

function ValidateData(StrData : String) : boolean;
var
  BStr, EStr : String[6];
begin
  BStr:=GetHeadPackage(StrData);
  EStr:=GetEndPackage(StrData);
  if (BStr='!BEGD!') and (EStr='!ENDD!') then
    Result:=true
  else
    Result:=false;
end;

function StringToFloatSkipping(strval : string): Real;
var
   strTemp: string;
   i: Integer;
begin
  strTemp := '';
  for i := 1 to length(strval) do
    if strval[i] in ['-','.','0'..'9'] then
      strTemp:=strTemp + strval[i];
  Result := StrToFloat(strTemp);
end;

function StringToDateTimeSkipping(strval : string): TDateTime;
var
   strTemp : string;
   i : Integer;
   D, M, Y, H, Mi, S: Word;
begin
  strTemp := '';
  for i := 1 to length(strval) do
    if strval[i] in [' ','/',':','0'..'9'] then
      strTemp := strTemp + strval[i];
  M:=StrToInt(Copy(strTemp, 1, 2));
  D:=StrToInt(Copy(strTemp, 4, 2));
  Y:=StrToInt(Copy(strTemp, 7, 4));
  H:=StrToInt(Copy(strTemp, 12, 2));
  Mi:=StrToInt(Copy(strTemp, 15, 2));
  S:=StrToInt(Copy(strTemp, 18, 2));
  Result := EncodeDate(Y, M, D)+EncodeTime(H, Mi, S, 0);
end;

end.
