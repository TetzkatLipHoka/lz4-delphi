unit LZ4;

interface

{$I LZ4.inc}

{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}

uses
  types,
  lz4d.lz4hc;

function CompressLZ4( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False ) : Int64; overload;
function CompressLZ4( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False ) : Int64; overload;

function CompressLZ4_HC( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64; overload;
function CompressLZ4_HC( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64; overload;

function CompressLZ4_Frame( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64; overload;
function CompressLZ4_Frame( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64; overload;

function ExtractLZ4( Source : PByte; Len : Cardinal; var Decompressed : TByteDynArray ) : Int64; overload;
function ExtractLZ4( Source : PByte; Len : Cardinal; var Decompressed : Pointer ) : Int64; overload;
function ExtractLZ4_Frame( Source : PByte; Len : Cardinal; var Decompressed : TByteDynArray ) : Int64; overload;
function ExtractLZ4_Frame( Source : PByte; Len : Cardinal; var Decompressed : Pointer ) : Int64; overload;

{$IFDEF TESTCASE}
function TestLZ4( FileName : string; Mode : Byte = 0; Header : boolean = False; SaveDebugFiles : Boolean = False ) : Int64;
{$ENDIF TESTCASE}

implementation

uses
{$IFDEF TESTCASE}
  Classes, SysUtils, Dialogs,
{$ENDIF TESTCASE}
  lz4d.Imports, // NativeUInt = Cardinal below D2010 (C1118 with $R+ otherwise)
  lz4d.lz4, lz4d.lz4frame;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
const
  HEADER_ = AnsiString( 'lz4' );
  HEADER_LEN_ = Length( HEADER_ );
  HEADER_HC_ = AnsiString( 'lz4hc' );
  HEADER_HC_LEN_ = Length( HEADER_HC_ );
  HEADER_FRAME_ = AnsiString( 'lz4f' );
  HEADER_FRAME_LEN_ = Length( HEADER_FRAME_ );
type
  tHeader = Array [ 0..HEADER_LEN_-1 ] of AnsiChar;
  pHeader = ^tHeader;
  tHeaderHC = Array [ 0..HEADER_HC_LEN_-1 ] of AnsiChar;
  pHeaderHC = ^tHeaderHC;
  tHeaderFrame = Array [ 0..HEADER_FRAME_LEN_-1 ] of AnsiChar;
  pHeaderFrame = ^tHeaderFrame;

function CompressLZ4( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False ) : Int64;
var
  OutSize : Integer;
  Offset  : Byte;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  SetLength( Compressed, 0 );

  OutSize := {$IFDEF UNDERSCORE}_LZ4_compressBound{$ELSE}LZ4_compressBound{$ENDIF}( Len );
  if Header then
    Offset := SizeOf( Len )+HEADER_LEN_
  else
    Offset := SizeOf( Len );
  SetLength( Compressed, OutSize+Offset );

  if Header then
    begin
    Move( HEADER_[ 1 ], Compressed[ 0 ], HEADER_LEN_ );
    Move( Len, Compressed[ HEADER_LEN_ ], SizeOf( Len ) );
    end
  else
    Move( Len, Compressed[ 0 ], SizeOf( Len ) );

  Result := {$IFDEF UNDERSCORE}_LZ4_compress_default{$ELSE}LZ4_compress_default{$ENDIF}( Source, @Compressed[ Offset ], Len, OutSize );
  if ( result > 0 ) then
    begin
    Inc( Result, Offset );

    if ( Result <> OutSize+Offset ) then
      SetLength( Compressed, Result );
    end
  else
    SetLength( Compressed, 0 );
end;

function CompressLZ4( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False ) : Int64;
var
  bCompressed : PByte;
  OutSize     : Integer;
  Offset      : Byte;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  if ( Compressed <> nil ) then
    ReallocMem( Compressed, 0 );

  OutSize := {$IFDEF UNDERSCORE}_LZ4_compressBound{$ELSE}LZ4_compressBound{$ENDIF}( Len );
  if Header then
    Offset := SizeOf( Len )+HEADER_LEN_
  else
    Offset := SizeOf( Len );
  ReallocMem( Compressed, OutSize+Offset );

  bCompressed := Compressed;

  if Header then
    begin
    Move( HEADER_[ 1 ], bCompressed^, HEADER_LEN_ );
    Inc( bCompressed, HEADER_LEN_ );
    end;
  Move( Len, bCompressed^, SizeOf( Len ) );
  Inc( bCompressed, SizeOf( Len ) );

  Result := {$IFDEF UNDERSCORE}_LZ4_compress_default{$ELSE}LZ4_compress_default{$ENDIF}( Source, bCompressed, Len, OutSize );
  if ( result > 0 ) then
    begin
    Inc( Result, Offset );
    if ( Result <> OutSize+Offset ) then
      ReallocMem( Compressed, Result );
    end
  else
    ReallocMem( Compressed, 0 );
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CompressLZ4_HC( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64;
var
  OutSize : Integer;
  Offset  : Byte;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  SetLength( Compressed, 0 );

  OutSize := {$IFDEF UNDERSCORE}_LZ4_compressBound{$ELSE}LZ4_compressBound{$ENDIF}( Len );
  if Header then
    Offset := SizeOf( Len )+HEADER_HC_LEN_
  else
    Offset := SizeOf( Len );
  SetLength( Compressed, OutSize+Offset );

  if Header then
    begin
    Move( HEADER_HC_[ 1 ], Compressed[ 0 ], HEADER_HC_LEN_ );
    Move( Len, Compressed[ HEADER_HC_LEN_ ], SizeOf( Len ) );
    end
  else
    Move( Len, Compressed[ 0 ], SizeOf( Len ) );

  Result := {$IFDEF UNDERSCORE}_LZ4_compress_HC{$ELSE}LZ4_compress_HC{$ENDIF}( Source, @Compressed[ Offset ], Len, OutSize, CompressionLevel );
  if ( result > 0 ) then
    begin
    Inc( Result, Offset );

    if ( Result <> OutSize+Offset ) then
      SetLength( Compressed, Result );
    end
  else
    SetLength( Compressed, 0 );
end;

function CompressLZ4_HC( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64;
var
  bCompressed : PByte;
  OutSize     : Integer;
  Offset      : Byte;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  if ( Compressed <> nil ) then
    ReallocMem( Compressed, 0 );

  OutSize := {$IFDEF UNDERSCORE}_LZ4_compressBound{$ELSE}LZ4_compressBound{$ENDIF}( Len );
  if Header then
    Offset := SizeOf( Len )+HEADER_HC_LEN_
  else
    Offset := SizeOf( Len );
  ReallocMem( Compressed, OutSize+Offset );

  bCompressed := Compressed;

  if Header then
    begin
    Move( HEADER_HC_[ 1 ], bCompressed^, HEADER_HC_LEN_ );
    Inc( bCompressed, HEADER_HC_LEN_ );
    end;
  Move( Len, bCompressed^, SizeOf( Len ) );
  Inc( bCompressed, SizeOf( Len ) );

  Result := {$IFDEF UNDERSCORE}_LZ4_compress_HC{$ELSE}LZ4_compress_HC{$ENDIF}( Source, bCompressed, Len, OutSize, CompressionLevel );
  if ( result > 0 ) then
    begin
    Inc( Result, Offset );
    if ( Result <> OutSize+Offset ) then
      ReallocMem( Compressed, Result );
    end
  else
    ReallocMem( Compressed, 0 );
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function CompressLZ4_Frame( Source : PByte; Len : Cardinal; var Compressed : TByteDynArray; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64;
var
  OutSize : Integer;
  Offset  : Byte;
  Prefs   : LZ4F_preferences_t;
  Res     : NativeUInt;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  SetLength( Compressed, 0 );

  FillChar( Prefs, SizeOf( Prefs ), 0 );
  Prefs.compressionLevel := CompressionLevel;
  OutSize := {$IFDEF UNDERSCORE}_LZ4F_compressFrameBound{$ELSE}LZ4F_compressFrameBound{$ENDIF}( Len, @Prefs );
  if Header then
    Offset := SizeOf( Len )+HEADER_FRAME_LEN_
  else
    Offset := SizeOf( Len );
  SetLength( Compressed, OutSize+Offset );

  if Header then
    begin
    Move( HEADER_FRAME_[ 1 ], Compressed[ 0 ], HEADER_FRAME_LEN_ );
    Move( Len, Compressed[ HEADER_FRAME_LEN_ ], SizeOf( Len ) );
    end
  else
    Move( Len, Compressed[ 0 ], SizeOf( Len ) );

  // 2026-11-24: check with LZ4F_isError - the error codes are huge size_t values, on Win32
  // they were taken as a size (> 0), and on an error a positive 1 came back
  Res := {$IFDEF UNDERSCORE}_LZ4F_compressFrame{$ELSE}LZ4F_compressFrame{$ENDIF}( @Compressed[ Offset ], OutSize, Source, Len, @Prefs );
  if ( {$IFDEF UNDERSCORE}_LZ4F_isError{$ELSE}LZ4F_isError{$ENDIF}( Res ) = 0 ) and ( Res > 0 ) then
    begin
    Result := Int64( Res )+Offset;
    if ( Result <> OutSize+Offset ) then
      SetLength( Compressed, Result );
    end
  else
    begin
    SetLength( Compressed, 0 );
    result := -1;
    end;
end;

function CompressLZ4_Frame( Source : PByte; Len : Cardinal; var Compressed : Pointer; Header : boolean = False; CompressionLevel : Byte = LZ4HC_CLEVEL_MAX ) : Int64;
var
  bCompressed : PByte;
  OutSize     : Integer;
  Offset      : Byte;
  Prefs   : LZ4F_preferences_t;
  Res     : NativeUInt;
begin
  result := -100;
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;
  if ( Compressed <> nil ) then
    ReallocMem( Compressed, 0 );

  FillChar( Prefs, SizeOf( Prefs ), 0 );
  Prefs.compressionLevel := CompressionLevel;
  OutSize := {$IFDEF UNDERSCORE}_LZ4F_compressFrameBound{$ELSE}LZ4F_compressFrameBound{$ENDIF}( Len, @Prefs );
  if Header then
    Offset := SizeOf( Len )+HEADER_FRAME_LEN_
  else
    Offset := SizeOf( Len );
  ReallocMem( Compressed, OutSize+Offset );

  bCompressed := Compressed;

  if Header then
    begin
    Move( HEADER_FRAME_[ 1 ], bCompressed^, HEADER_FRAME_LEN_ );
    Inc( bCompressed, HEADER_FRAME_LEN_ );
    end;
  Move( Len, bCompressed^, SizeOf( Len ) );
  Inc( bCompressed, SizeOf( Len ) );

  Res := {$IFDEF UNDERSCORE}_LZ4F_compressFrame{$ELSE}LZ4F_compressFrame{$ENDIF}( bCompressed, OutSize, Source, Len, @Prefs );
  if ( {$IFDEF UNDERSCORE}_LZ4F_isError{$ELSE}LZ4F_isError{$ENDIF}( Res ) = 0 ) and ( Res > 0 ) then
    begin
    Result := Int64( Res )+Offset;
    if ( Result <> OutSize+Offset ) then
      ReallocMem( Compressed, Result );
    end
  else
    begin
    ReallocMem( Compressed, 0 );
    result := -1;
    end;
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Header kind of a buffer: 0 = none, 1 = 'lz4', 2 = 'lz4hc', 3 = 'lz4f'.
// 2026-11-24: lengths are checked before the header is read (up to 5 bytes were
// read from shorter buffers), and 'lz4f' is compared with 4 characters (the old
// pHeaderFrame pointed to the 5-character type: frame data was never detected and
// fell through to 'lz4', which cut 3 bytes and read 'f' + 3 bytes as the size).
function HeaderKind( Source : PByte; Len : Cardinal ) : Integer;
begin
  result := 0;
  if ( Len >= Cardinal( HEADER_HC_LEN_ ) ) and ( pHeaderHC( Source )^ = HEADER_HC_ ) then
    result := 2
  else if ( Len >= Cardinal( HEADER_FRAME_LEN_ ) ) and ( pHeaderFrame( Source )^ = HEADER_FRAME_ ) then
    result := 3
  else if ( Len >= Cardinal( HEADER_LEN_ ) ) and ( pHeader( Source )^ = HEADER_ ) then
    result := 1;
end;

procedure SkipHeader( var Source : PByte; var Len : Cardinal; Kind : Integer );
var
  n : Cardinal;
begin
  case Kind of
    1 : n := HEADER_LEN_;
    2 : n := HEADER_HC_LEN_;
    3 : n := HEADER_FRAME_LEN_;
  else
    n := 0;
  end;
  Inc( Source, n );
  Dec( Len, n );
end;

// Original size in front of the data. LZ4 cannot expand more than 255:1, so a larger
// value is corrupt data (and would only end in an out-of-memory exception).
function ReadOutSize( var Source : PByte; var Len : Cardinal; out OutSize : Cardinal ) : Boolean;
begin
  result := False;
  OutSize := 0;
  if ( Len < SizeOf( OutSize ) ) then
    Exit;
  OutSize := PCardinal( Source )^;
  Inc( Source, SizeOf( OutSize ) );
  Dec( Len, SizeOf( OutSize ) );
  result := ( OutSize > 0 ) and ( Int64( OutSize ) <= Int64( Len )*255+64 );
end;

// Return values of the extract functions: decompressed size, or negative on errors
// (-100 parameter/format, -1 corrupt or truncated data). The decompressed size must
// match the stored size, otherwise the data is rejected.
function ExtractLZ4( Source : PByte; Len : Cardinal; var Decompressed : TByteDynArray ) : Int64;
var
  OutSize : Cardinal;
  Kind    : Integer;
begin
  result := -100;
  SetLength( Decompressed, 0 );
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;

  Kind := HeaderKind( Source, Len );
  if ( Kind = 3 ) then
    begin
    result := ExtractLZ4_Frame( Source, Len, Decompressed ); // was a recursive call of ExtractLZ4 itself
    Exit;
    end;
  SkipHeader( Source, Len, Kind );
  if not ReadOutSize( Source, Len, OutSize ) then
    Exit;
  SetLength( Decompressed, OutSize );

  result := {$IFDEF UNDERSCORE}_LZ4_decompress_safe{$ELSE}LZ4_decompress_safe{$ENDIF}( Source, @Decompressed[ 0 ], Len, OutSize );
  if ( result <> OutSize ) then
    begin
    SetLength( Decompressed, 0 );
    if ( result >= 0 ) then
      result := -1;
    end;
end;

function ExtractLZ4( Source : PByte; Len : Cardinal; var Decompressed : Pointer ) : Int64;
var
  OutSize : Cardinal;
  Kind    : Integer;
begin
  result := -100;
  if ( Decompressed <> nil ) then
    ReallocMem( Decompressed, 0 );
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;

  Kind := HeaderKind( Source, Len );
  if ( Kind = 3 ) then
    begin
    result := ExtractLZ4_Frame( Source, Len, Decompressed );
    Exit;
    end;
  SkipHeader( Source, Len, Kind );
  if not ReadOutSize( Source, Len, OutSize ) then
    Exit;
  GetMem( Decompressed, OutSize );

  result := {$IFDEF UNDERSCORE}_LZ4_decompress_safe{$ELSE}LZ4_decompress_safe{$ENDIF}( Source, Decompressed, Len, OutSize );
  if ( result <> OutSize ) then
    begin
    ReallocMem( Decompressed, 0 );
    if ( result >= 0 ) then
      result := -1;
    end;
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Whole frame in one LZ4F_decompress call: 0 = frame complete. 2026-11-24: the sizes
// are NativeUInt - LZ4F_decompress writes/reads size_t through the pointers, with
// Cardinal variables that was 8 bytes into/out of 4-byte variables on Win64.
function DecodeFrame( Source : PByte; Len : Cardinal; Dest : Pointer; OutSize : Cardinal ) : Int64;
var
  ctx     : PLZ4F_dctx;
  Opts    : LZ4F_decompressOptions_t;
  DstLen, SrcLen, Res : NativeUInt;
begin
  result := -1;
  ctx := nil;
  Res := {$IFNDEF UNDERSCORE}LZ4F_createDecompressionContext{$ELSE}_LZ4F_createDecompressionContext{$ENDIF}( @ctx, LZ4F_VERSION );
  if ( {$IFNDEF UNDERSCORE}LZ4F_isError{$ELSE}_LZ4F_isError{$ENDIF}( Res ) <> 0 ) then
    Exit;
  FillChar( Opts, SizeOf( Opts ), 0 );
  DstLen := OutSize;
  SrcLen := Len;
  Res := {$IFDEF UNDERSCORE}_LZ4F_decompress{$ELSE}LZ4F_decompress{$ENDIF}( ctx, Dest, @DstLen, Source, @SrcLen, @Opts );
  if ( {$IFNDEF UNDERSCORE}LZ4F_isError{$ELSE}_LZ4F_isError{$ENDIF}( Res ) = 0 ) and ( Res = 0 ) and ( DstLen = OutSize ) then
    result := OutSize;
  {$IFNDEF UNDERSCORE}LZ4F_freeDecompressionContext{$ELSE}_LZ4F_freeDecompressionContext{$ENDIF}( ctx );
end;

function ExtractLZ4_Frame( Source : PByte; Len : Cardinal; var Decompressed : TByteDynArray ) : Int64;
var
  OutSize : Cardinal;
  Kind    : Integer;
begin
  result := -100;
  SetLength( Decompressed, 0 );
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;

  Kind := HeaderKind( Source, Len );
  if ( Kind = 1 ) or ( Kind = 2 ) then
    begin
    result := ExtractLZ4( Source, Len, Decompressed ); // block format
    Exit;
    end;
  SkipHeader( Source, Len, Kind );
  if not ReadOutSize( Source, Len, OutSize ) then
    Exit;
  SetLength( Decompressed, OutSize );
  result := DecodeFrame( Source, Len, @Decompressed[ 0 ], OutSize );
  if ( result < 0 ) then
    SetLength( Decompressed, 0 );
end;

function ExtractLZ4_Frame( Source : PByte; Len : Cardinal; var Decompressed : Pointer ) : Int64;
var
  OutSize : Cardinal;
  Kind    : Integer;
begin
  result := -100;
  if ( Decompressed <> nil ) then
    ReallocMem( Decompressed, 0 );
  if ( Source = nil ) OR ( Len = 0 ) then
    Exit;

  Kind := HeaderKind( Source, Len );
  if ( Kind = 1 ) or ( Kind = 2 ) then
    begin
    result := ExtractLZ4( Source, Len, Decompressed );
    Exit;
    end;
  SkipHeader( Source, Len, Kind );
  if not ReadOutSize( Source, Len, OutSize ) then
    Exit;
  GetMem( Decompressed, OutSize );
  result := DecodeFrame( Source, Len, Decompressed, OutSize );
  if ( result < 0 ) then
    ReallocMem( Decompressed, 0 );
end;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
{$IFDEF TESTCASE}
function TestLZ4( FileName : string; Mode : Byte = 0; Header : boolean = False; SaveDebugFiles : Boolean = False ) : Int64;
var
  sIn : TMemoryStream;

  function PointerToArray : Int64;
  var
    sCompress, sOut : TMemoryStream;
    aDecompressed : TByteDynArray;
    S : String;
  begin
    SetLength( aDecompressed, 0 );

    sCompress := TMemoryStream.Create;
    if ( Mode = 1 ) then
      result := CompressLZ4_HC( sIn.Memory, sIn.Size, aDecompressed, Header )
    else if ( Mode = 2 ) then
      result := CompressLZ4_Frame( sIn.Memory, sIn.Size, aDecompressed, Header )
    else
      result := CompressLZ4( sIn.Memory, sIn.Size, aDecompressed, Header );
    if ( result <= 0 ) then
      begin
      sCompress.free;
      result := -3;
      Exit;
      end;

    sCompress.Write( aDecompressed[ 0 ], Length( aDecompressed ) );
    SetLength( aDecompressed, 0 );
    if SaveDebugFiles then
      begin
      if ( Mode = 2 ) then
        S := ChangeFileExt( FileName, '.LZ4F' )
      else if ( Mode = 1 ) then
        S := ChangeFileExt( FileName, '.LZ4HC' )
      else
        S := ChangeFileExt( FileName, '.LZ4' );
      sCompress.SaveToFile( S );
      end;

    sOut := TMemoryStream.Create;
    sCompress.Position := 0;
    SetLength( aDecompressed, 0 );
    if ( Mode = 2 ) then
      result := ExtractLZ4_Frame( sCompress.Memory, sCompress.Size, aDecompressed )
    else
      result := ExtractLZ4( sCompress.Memory, sCompress.Size, aDecompressed );
    if ( result <= 0 ) then
      begin
      sOut.free;
      sCompress.free;
      result := -2;
      Exit;
      end;
    sOut.Write( aDecompressed[ 0 ], Length( aDecompressed ) );
    SetLength( aDecompressed, 0 );

    if ( sIn.Size <> sOut.Size ) OR NOT CompareMem( sIn.Memory, sOut.Memory, sIn.Size ) then
      result := -1;
    if SaveDebugFiles then
      sOut.SaveToFile( ChangeFileExt( FileName, '.extract' ) );

    sOut.free;
    sCompress.free;
  end;

  function PointerToPointer : Int64;
  var
    sCompress, sOut : TMemoryStream;
    pDecompressed : Pointer;
    S : String;
  begin
    pDecompressed := nil;

    sCompress := TMemoryStream.Create;
    if ( Mode = 1 ) then
      result := CompressLZ4_HC( sIn.Memory, sIn.Size, pDecompressed, Header )
    else if ( Mode = 2 ) then
      result := CompressLZ4_Frame( sIn.Memory, sIn.Size, pDecompressed, Header )
    else
      result := CompressLZ4( sIn.Memory, sIn.Size, pDecompressed, Header );
    if ( result <= 0 ) then
      begin
      sCompress.free;
      result := -3;
      Exit;
      end;

    sCompress.Write( pDecompressed^, result );
    ReallocMem( pDecompressed, 0 );
    if SaveDebugFiles then
      begin
      if ( Mode = 2 ) then
        S := ChangeFileExt( FileName, '.LZ4F' )
      else if ( Mode = 1 ) then
        S := ChangeFileExt( FileName, '.LZ4HC' )
      else
        S := ChangeFileExt( FileName, '.LZ4' );
      sCompress.SaveToFile( S );
      end;

    sOut := TMemoryStream.Create;
    sCompress.Position := 0;
    pDecompressed := nil;
    if ( Mode = 2 ) then
      result := ExtractLZ4_Frame( sCompress.Memory, sCompress.Size, pDecompressed )
    else
      result := ExtractLZ4( sCompress.Memory, sCompress.Size, pDecompressed );
    if ( result <= 0 ) then
      begin
      sOut.free;
      sCompress.free;
      result := -2;
      Exit;
      end;
    sOut.Write( PByte( pDecompressed )^, result );
    ReallocMem( pDecompressed, 0 );

    if ( sIn.Size <> sOut.Size ) OR NOT CompareMem( sIn.Memory, sOut.Memory, sIn.Size ) then
      result := -1;
    if SaveDebugFiles then
      sOut.SaveToFile( ChangeFileExt( FileName, '.extract' ) );

    sOut.free;
    sCompress.free;
  end;
begin
  result := -999;
  if NOT FileExists( FileName ) then
    Exit;

  sIn := TMemoryStream.Create;
  sIn.LoadFromFile( FileName );
  sIn.Position := 0;

  result := PointerToArray;
  case result of
  -999 : ShowMessage( 'PointerToArray: Invalid File' );
    -3 : ShowMessage( 'PointerToArray: Failed compress' );
    -2 : ShowMessage( 'PointerToArray: Failed decompress' );
    -1 : ShowMessage( 'PointerToArray: Size invalid or CompareMem failed' );
     0 : ShowMessage( 'PointerToArray: Failed to Extract' );
//    else
//       ShowMessage( 'PointerToArray: OK' );
  end;
  if ( result < 0 ) then
    begin
    sIn.Free;
    Exit;
    end;

  result := PointerToPointer;
  case result of
  -999 : ShowMessage( 'PointerToPointer: Invalid File' );
    -3 : ShowMessage( 'PointerToPointer: Failed compress' );
    -2 : ShowMessage( 'PointerToPointer: Failed decompress' );
    -1 : ShowMessage( 'PointerToPointer: Size invalid or CompareMem failed' );
     0 : ShowMessage( 'PointerToPointer: Failed to Extract' );
//    else
//       ShowMessage( 'PointerToPointer: OK' );
  end;
  if ( result < 0 ) then
    begin
    sIn.Free;
    Exit;
    end;
  sIn.free;
end;

//initialization
//  TestLZ4( ParamStr( 0 ) + '_', 2, True, True );
{$ENDIF TESTCASE}  

end.
