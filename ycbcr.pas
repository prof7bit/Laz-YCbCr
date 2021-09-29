{ Conversion to and from YCbCr

  Copyright (C) 2021 Bernd Kreuss prof7bit@gmail.com

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version with the following modification:

  As a special exception, the copyright holders of this library give you
  permission to link this library with independent modules to produce an
  executable, regardless of the license terms of these independent modules,and
  to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a
  module which is not derived from or based on this library. If you modify
  this library, you may extend this exception to your version of the library,
  but you are not obligated to do so. If you do not wish to do so, delete this
  exception statement from your version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 51 Franklin Street - Fifth Floor, Boston, MA 02110-1335, USA.
}
unit YCbCr;

{$mode ObjFPC}{$H+}

interface

uses
  Graphics;

type
  TItuRec = (
    ituBT601,  // ITU-R BT.601, full range
    ituBT709,  // ITU-R BT.709, full range
    ituBT2020  // ITU-R BT.2020, full range
  );

procedure ColorToYCbCr(C: TColor; out Y, Cb, Cr: Byte; ItuRec: TItuRec);
function YCbCrToColor(Y, Cb, Cr: Byte; ItuRec: TItuRec): TColor;

implementation
uses
  Math;

type
  TYCbCrCoeff = array[0..10] of Double;

var
  YCbCrCoeffs: array[TItuRec] of TYCbCrCoeff;

procedure ColorToYCbCr(C: TColor; out Y, Cb, Cr: Byte; ItuRec: TItuRec);
var
  K: ^TYCbCrCoeff;
  RGB: LongInt;
  R, G, B: Byte;
begin
  RGB := ColorToRGB(C);
  R := Red(RGB);
  G := Green(RGB);
  B := Blue(RGB);
  K := @YCbCrCoeffs[ItuRec];
  Y  := EnsureRange(Round(K^[0] * R + K^[1] * G + K^[2] * B), 0, 255);
  Cb := EnsureRange(Round(K^[3] * R + K^[4] * G +   0.5 * B + 128), 0, 255);
  Cr := EnsureRange(Round(  0.5 * R + K^[5] * G + K^[6] * B + 128), 0, 255);
end;

function YCbCrToColor(Y, Cb, Cr: Byte; ItuRec: TItuRec): TColor;
var
  K: ^TYCbCrCoeff;
  Cb0, Cr0: Integer;
  R, G, B: Byte;
begin
  Cb0 := Cb - 128;
  Cr0 := Cr - 128;
  K := @YCbCrCoeffs[ItuRec];
  R := EnsureRange(Round(Y + K^[7] * Cr0               ), 0, 255);
  G := EnsureRange(Round(Y + K^[8] * Cr0 + K^[9]  * Cb0), 0, 255);
  B := EnsureRange(Round(Y               + K^[10] * Cb0), 0, 255);
  Result := RGBToColor(R, G, B);
end;

procedure InitYCbCrCoeff(ItuRec: TItuRec; Kr, Kg: Double);
var
  Kb: Double;
  K: ^TYCbCrCoeff;
begin                                  //  example values for BT601
  Kb := 1 - Kr - Kg;
  K := @YCbCrCoeffs[ItuRec];
  K^[0] := Kr;                         //  0.299
  K^[1] := Kg;                         //  0.587
  K^[2] := Kb;                         //  0.114
  K^[3] := -Kr / (2 * (Kr + Kg));      // -0.1687
  K^[4] := -Kg / (2 * (Kr + Kg));      // -0.3313
  K^[5] := -Kg / (2 * (Kg + Kb));      // -0.4187
  K^[6] := -Kb / (2 * (Kg + Kb));      // -0.0813
  K^[7] := 2 * (Kg + Kb);              //  1.402
  K^[8] := -Kr * 2 * (Kg + Kb) / Kg;   // -0.7141
  K^[9] := -Kb * 2 * (Kr + Kg) / Kg;   // -0.3441
  K^[10] := 2 * (Kr + Kg);             //  1.772
end;

initialization
  InitYCbCrCoeff(ituBT601, 0.299, 0.587);
  InitYCbCrCoeff(ituBT709, 0.2126, 0.7152);
  InitYCbCrCoeff(ituBT2020, 0.2627, 0.6780);
end.
