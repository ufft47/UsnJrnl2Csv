#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Parser for $UsnJrnl (NTFS)
#AutoIt3Wrapper_Res_Description=Parser for $UsnJrnl (NTFS)
#AutoIt3Wrapper_Res_Fileversion=1.0.0.8
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#Include <WinAPIEx.au3>
#Include <File.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <GuiEdit.au3>
#Include <FileConstants.au3>
Global $UsnJrnlCsv, $UsnJrnlCsvFile, $UsnJrnlDbfile, $de="|", $PrecisionSeparator=".", $PrecisionSeparator2="", $sOutputFile, $VerboseOn=false, $SurroundingQuotes=True, $PreviousUsn, $DoDefaultAll, $dol2t, $DoBodyfile, $DebugOutFile
Global $_COMMON_KERNEL32DLL=DllOpen("kernel32.dll"), $outputpath=@ScriptDir, $File, $MaxPages, $CurrentPage, $WithQuotes, $EncodingWhenOpen=2
Global $ProgressStatus, $ProgressUsnJrnl
Global $begin, $ElapsedTime, $EntryCounter, $DoScanMode1=0, $DoScanMode2=0, $DoNormalMode=1, $SectorSize=512
Global $tDelta = _WinTime_GetUTCToLocalFileTimeDelta()
Global $DateTimeFormat,$ExampleTimestampVal = "01CD74B3150770B8",$TimestampPrecision, $UTCconfig
Global $TimestampErrorVal = "0000-00-00 00:00:00"
Global $USN_Page_Size = 4096, $Remainder="", $nBytes
Global $ParserOutDir = @ScriptDir
Global $myctredit, $CheckUnicode, $checkl2t, $checkbodyfile, $checkdefaultall, $SeparatorInput, $checkquotes

$Progversion = "UsnJrnl2Csv 1.0.0.8"
If $cmdline[0] > 0 Then
	$CommandlineMode = 1
	ConsoleWrite($Progversion & @CRLF)
	_GetInputParams()
	_Main()
Else
	$CommandlineMode = 0

	$Form = GUICreate($Progversion, 540, 350, -1, -1)

	$LabelTimestampFormat = GUICtrlCreateLabel("Timestamp format:",20,20,90,20)
	$ComboTimestampFormat = GUICtrlCreateCombo("", 110, 20, 30, 25)
	$LabelTimestampPrecision = GUICtrlCreateLabel("Precision:",150,20,50,20)
	$ComboTimestampPrecision = GUICtrlCreateCombo("", 200, 20, 70, 25)

	$LabelPrecisionSeparator = GUICtrlCreateLabel("Precision separator:",280,20,100,20)
	$PrecisionSeparatorInput = GUICtrlCreateInput($PrecisionSeparator,380,20,15,20)
	$LabelPrecisionSeparator2 = GUICtrlCreateLabel("Precision separator2:",400,20,100,20)
	$PrecisionSeparatorInput2 = GUICtrlCreateInput($PrecisionSeparator2,505,20,15,20)

	$InputExampleTimestamp = GUICtrlCreateInput("",340,45,190,20)
	GUICtrlSetState($InputExampleTimestamp, $GUI_DISABLE)

	$Label1 = GUICtrlCreateLabel("Set decoded timestamps to specific region:",20,45,230,20)
	$Combo2 = GUICtrlCreateCombo("", 230, 45, 85, 25)

	$LabelSeparator = GUICtrlCreateLabel("Set separator:",20,70,70,20)
	$SaparatorInput = GUICtrlCreateInput($de,90,70,20,20)
	$SaparatorInput2 = GUICtrlCreateInput($de,120,70,30,20)
	GUICtrlSetState($SaparatorInput2, $GUI_DISABLE)
	$checkquotes = GUICtrlCreateCheckbox("Quotation mark", 160, 70, 90, 20)
	GUICtrlSetState($checkquotes, $GUI_CHECKED)
	$CheckUnicode = GUICtrlCreateCheckbox("Unicode", 255, 70, 60, 20)
	GUICtrlSetState($CheckUnicode, $GUI_UNCHECKED)

	$checkl2t = GUICtrlCreateCheckbox("log2timeline", 20, 100, 130, 20)
	GUICtrlSetState($checkl2t, $GUI_UNCHECKED)
	GUICtrlSetState($checkl2t, $GUI_DISABLE)
	$checkbodyfile = GUICtrlCreateCheckbox("bodyfile", 20, 120, 130, 20)
	GUICtrlSetState($checkbodyfile, $GUI_UNCHECKED)
	GUICtrlSetState($checkbodyfile, $GUI_DISABLE)
	$checkdefaultall = GUICtrlCreateCheckbox("dump everything", 20, 140, 130, 20)
	GUICtrlSetState($checkdefaultall, $GUI_CHECKED)
	GUICtrlSetState($checkdefaultall, $GUI_DISABLE)

	$LabelBrokenData = GUICtrlCreateLabel("Broken data:",130,100,65,20)
	$CheckScanMode1 = GUICtrlCreateCheckbox("Scan mode 1", 200, 100, 80, 20)
	GUICtrlSetState($CheckScanMode1, $GUI_UNCHECKED)
	$CheckScanMode2 = GUICtrlCreateCheckbox("Scan mode 2", 200, 120, 80, 20)
	GUICtrlSetState($CheckScanMode2, $GUI_UNCHECKED)

	$LabelUsnPageSize = GUICtrlCreateLabel("USN_PAGE_SIZE:",130,145,100,20)
	$UsnPageSizeInput = GUICtrlCreateInput($USN_Page_Size,230,145,40,20)

	$LabelTimestampError = GUICtrlCreateLabel("Timestamp ErrorVal:",290,145,100,20)
	$TimestampErrorInput = GUICtrlCreateInput($TimestampErrorVal,390,145,130,20)

	$ButtonOutput = GUICtrlCreateButton("Change Output", 420, 70, 100, 20)
	$ButtonInput = GUICtrlCreateButton("Browse $UsnJrnl", 420, 95, 100, 20)
	$ButtonStart = GUICtrlCreateButton("Start Parsing", 420, 120, 100, 20)
	$myctredit = GUICtrlCreateEdit("Current output folder: " & $outputpath & @CRLF, 0, 170, 540, 100, BitOR($ES_AUTOVSCROLL,$WS_VSCROLL))
	_GUICtrlEdit_SetLimitText($myctredit, 128000)

	_InjectTimeZoneInfo()
	_InjectTimestampFormat()
	_InjectTimestampPrecision()
	$PrecisionSeparator = GUICtrlRead($PrecisionSeparatorInput)
	$PrecisionSeparator2 = GUICtrlRead($PrecisionSeparatorInput2)
	_TranslateTimestamp()

	GUISetState(@SW_SHOW)

	While 1
		$nMsg = GUIGetMsg()
		Sleep(100)
		_TranslateSeparator()
		$PrecisionSeparator = GUICtrlRead($PrecisionSeparatorInput)
		$PrecisionSeparator2 = GUICtrlRead($PrecisionSeparatorInput2)
		_TranslateTimestamp()
		Select
			Case $nMsg = $ButtonOutput
				$newoutputpath = FileSelectFolder("Select output folder.", "",7,$ParserOutDir)
				If Not @error then
					_DisplayInfo("New output folder: " & $newoutputpath & @CRLF)
					$ParserOutDir = $newoutputpath
				EndIf
			Case $nMsg = $ButtonInput
				$File = FileOpenDialog("Select $UsnJrnl file",@ScriptDir,"All (*.*)")
				If Not @error Then _DisplayInfo("Input: " & $File & @CRLF)
			Case $nMsg = $ButtonStart
				_Main()
			Case $nMsg = $GUI_EVENT_CLOSE
				Exit
		EndSelect
	WEnd
EndIf

Func _Main()
	Global $EntryCounter=0
	GUICtrlSetData($ProgressUsnJrnl, 0)

	If Not $CommandlineMode Then
		If Int(GUICtrlRead($checkl2t) + GUICtrlRead($checkbodyfile) + GUICtrlRead($checkdefaultall)) <> 9 Then
			_DisplayInfo("Error: Output format can only be one of the options (not more than 1)." & @CRLF)
			Return
		EndIf
		If GUICtrlRead($checkl2t) = 1 Then
			$Dol2t = True
		ElseIf GUICtrlRead($checkbodyfile) = 1 Then
			$DoBodyfile = True
		ElseIf GUICtrlRead($checkdefaultall) = 1 Then
			$DoDefaultAll = True
		EndIf
	EndIf

	If Not $CommandlineMode Then
		$USN_Page_Size = GUICtrlRead($UsnPageSizeInput)
	EndIf
	If Mod($USN_Page_Size,512) Then
		If Not $CommandlineMode Then
			_DisplayInfo("Error: USN_PAGE_SIZE must be a multiple of 512" & @CRLF)
			_DumpOutput("Error: USN_PAGE_SIZE must be a multiple of 512" & @CRLF)
			Return
		Else
			_DumpOutput("Error: USN_PAGE_SIZE must be a multiple of 512" & @CRLF)
			Exit
		EndIf
	EndIf

	If Not $CommandlineMode Then
		$tDelta = _GetUTCRegion(GUICtrlRead($Combo2))-$tDelta
		If @error Then
			_DisplayInfo("Error: Timezone configuration failed." & @CRLF)
			Return
		EndIf
		$tDelta = $tDelta*-1 ;Since delta is substracted from timestamp later on
	EndIf

	If $CommandlineMode Then
		$CheckUnicode = $CheckUnicode
	Else
		$CheckUnicode = GUICtrlRead($CheckUnicode)
	EndIf
	If $CheckUnicode = 1 Then
		;$EncodingWhenOpen = 2+32 ;ucs2
		$EncodingWhenOpen = 2+128 ;utf8 w/bom
		If Not $CommandlineMode Then _DisplayInfo("UNICODE configured" & @CRLF)
		_DumpOutput("UNICODE configured" & @CRLF)
	Else
		$EncodingWhenOpen = 2
		If Not $CommandlineMode Then _DisplayInfo("ANSI configured" & @CRLF)
		_DumpOutput("ANSI configured" & @CRLF)
	EndIf

	If $CommandlineMode Then
		$PrecisionSeparator = $PrecisionSeparator
	Else
		$PrecisionSeparator = GUICtrlRead($PrecisionSeparatorInput)
	EndIf
	If StringLen($PrecisionSeparator) <> 1 Then
		If Not $CommandlineMode Then _DisplayInfo("Error: Precision separator not set properly" & @crlf)
		_DumpOutput("Error: Precision separator not set properly" & @crlf)
		Return
	EndIf

	If $CommandlineMode Then
		$checkquotes = $checkquotes
	Else
		$checkquotes = GUICtrlRead($checkquotes)
	EndIf

	If $checkquotes = 1 Then
		$WithQuotes=True
	Else
		$WithQuotes=False
	EndIf

	If Not FileExists($File) Then
		If Not $CommandlineMode Then _DisplayInfo("Error: No $UsnJrnl chosen for input" & @CRLF)
		_DumpOutput("Error: No $UsnJrnl chosen for input" & @CRLF)
		Return
	EndIf

	$TimestampStart = @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & "-" & @MIN & "-" & @SEC

	$UsnJrnlCsvFile = $ParserOutDir & "\UsnJrnl_"&$TimestampStart&".csv"
	$UsnJrnlCsv = FileOpen($UsnJrnlCsvFile, $EncodingWhenOpen)
	If @error Then
		If Not $CommandlineMode Then _DisplayInfo("Error creating: " & $UsnJrnlCsvFile & @CRLF)
		_DumpOutput("Error creating: " & $UsnJrnlCsvFile & @CRLF)
		Return
	EndIf

	$DebugOutFile = FileOpen($ParserOutDir & "\UsnJrnl_"&$TimestampStart&".log", $EncodingWhenOpen)
	If @error Then
		ConsoleWrite("Error: Could not create log file" & @CRLF)
		MsgBox(0,"Error","Could not create log file")
		Exit
	EndIf

	_DumpOutput("Using $UsnJrnl: " & $File & @CRLF)
	_DumpOutput("Quotes configuration: " & $WithQuotes & @CRLF)
	_DumpOutput("USN_PAGE_SIZE: " & $USN_Page_Size & @CRLF)

	If Not $CommandlineMode Then
		If GUICtrlRead($CheckScanMode1) = 1 And GUICtrlRead($CheckScanMode2) = 1 Then
			_DisplayInfo("Error: only 1 scan mode possible" & @CRLF)
			Return
		EndIf

		If GUICtrlRead($CheckScanMode1) = 1 Then
			$DoScanMode1 = 1
			$DoNormalMode = 0
		EndIf

		If GUICtrlRead($CheckScanMode2) = 1 Then
			$DoScanMode2 = 1
			$DoNormalMode = 0
		EndIf
	EndIf

	If $DoScanMode1=0 And $DoScanMode2=0 Then
		$DoNormalMode=1
	EndIf

	_DumpOutput("Normal mode: " & $DoNormalMode & @CRLF)
	_DumpOutput("Scan mode 1: " & $DoScanMode1 & @CRLF)
	_DumpOutput("Scan mode 2: " & $DoScanMode2 & @CRLF)

	_DumpOutput("Using DateTime format: " & $DateTimeFormat & @CRLF)
	_DumpOutput("Using timestamp precision: " & $TimestampPrecision & @CRLF)
	_DumpOutput("Timestamps presented in UTC: " & $UTCconfig & @CRLF)
	_DumpOutput("Using precision separator: " & $PrecisionSeparator & @CRLF)
;	_DumpOutput("------------------- END CONFIGURATION -----------------------" & @CRLF)

	$UsnJrnlSqlFile = $ParserOutDir & "\UsnJrnl_"&$TimestampStart&".sql"
	FileInstall("C:\temp\import-csv-usnjrnl.sql", $UsnJrnlSqlFile)
	$FixedPath = StringReplace($UsnJrnlCsvFile,"\","\\")
	Sleep(500)
#cs
	$hUsnJrnlSqlFile = FileOpen($UsnJrnlSqlFile,1)
	$UsnJrnlSqlFileContent = FileRead($hUsnJrnlSqlFile,FileGetSize($hUsnJrnlSqlFile))
	$UsnJrnlSqlFileContent = StringReplace($UsnJrnlSqlFileContent,"__PathToCsv__",$FixedPath)
	FileSetPos($hUsnJrnlSqlFile, 0, $FILE_BEGIN)
	FileWrite($hUsnJrnlSqlFile,$UsnJrnlSqlFileContent)
	ConsoleWrite("FileWrite error: " & @error & @CRLF)
	FileClose($hUsnJrnlSqlFile)
#ce
	_ReplaceStringInFile($UsnJrnlSqlFile,"__PathToCsv__",$FixedPath)
	If $CheckUnicode = 1 Then _ReplaceStringInFile($UsnJrnlSqlFile,"latin1", "utf8")

	$Progress = GUICtrlCreateLabel("Decoding $UsnJrnl info and writing to csv", 10, 280,540,20)
	GUICtrlSetFont($Progress, 12)
	$ProgressStatus = GUICtrlCreateLabel("", 10, 275, 520, 20)
	$ElapsedTime = GUICtrlCreateLabel("", 10, 290, 520, 20)
	$ProgressUsnJrnl = GUICtrlCreateProgress(0,  315, 540, 30)
	$begin = TimerInit()

	$hFile = _WinAPI_CreateFile("\\.\" & $File,2,2,7)
	If $hFile = 0 Then
		If Not $CommandlineMode Then _DisplayInfo("Error: Creating handle on file" & @CRLF)
		_DumpOutput("Error: Creating handle on file" & @CRLF)
		Return
	EndIf

	_WriteCSVHeader()

	$InputFileSize = _WinAPI_GetFileSizeEx($hFile)
	_DumpOutput("InputFileSize: " & $InputFileSize & " bytes" & @CRLF)

	AdlibRegister("_UsnJrnlProgress", 500)

	Select

		Case $DoNormalMode
			$tBuffer = DllStructCreate("byte[" & $USN_Page_Size & "]")
			$MaxPages = Ceiling($InputFileSize/$USN_Page_Size)
			For $i = 0 To $MaxPages-1
				$CurrentPage=$i
				_WinAPI_SetFilePointerEx($hFile, $i*$USN_Page_Size, $FILE_BEGIN)
				If $i = $MaxPages-1 Then $tBuffer = DllStructCreate("byte[" & $USN_Page_Size & "]")
				_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $USN_Page_Size, $nBytes)
				$RawPage = DllStructGetData($tBuffer, 1)
				$EntryCounter += _UsnProcessPage(StringMid($RawPage,3),$i*$USN_Page_Size,0)
				If Not Mod($i,1000) Then
					FileFlush($UsnJrnlCsv)
				EndIf
			Next

		Case $DoScanMode1
			$tBuffer = DllStructCreate("byte[" & $USN_Page_Size & "]")
			$MaxPages = Ceiling($InputFileSize/$USN_Page_Size)
			For $i = 0 To $MaxPages-1
				$CurrentPage=$i
				_WinAPI_SetFilePointerEx($hFile, $i*$USN_Page_Size, $FILE_BEGIN)
				If $i = $MaxPages-1 Then $tBuffer = DllStructCreate("byte[" & $USN_Page_Size & "]")
				_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $USN_Page_Size, $nBytes)
				$RawPage = DllStructGetData($tBuffer, 1)
				$TestOffset = _ScanModeUsnProcessPage(StringMid($RawPage,3))
				If Not @error Then
					$EntryCounter += _UsnProcessPage(StringMid($RawPage,3+$TestOffset),$i*$USN_Page_Size,$TestOffset)
				EndIf
				If Not Mod($i,1000) Then
					FileFlush($UsnJrnlCsv)
				EndIf
			Next

		Case $DoScanMode2
			$tBuffer = DllStructCreate("byte[" & $SectorSize & "]")
			$MaxPages = Ceiling($InputFileSize/$SectorSize)
			For $i = 0 To $MaxPages-1
				$CurrentPage=$i
				_WinAPI_SetFilePointerEx($hFile, $i*$SectorSize, $FILE_BEGIN)
				If $i = $MaxPages-1 Then $tBuffer = DllStructCreate("byte[" & $SectorSize & "]")
				_WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), $SectorSize, $nBytes)
				$RawPage = DllStructGetData($tBuffer, 1)
				$EntryCounter += _ScanModeUsnProcessPage2(StringMid($RawPage,3),$i*$SectorSize,0)
				If Not Mod($i,1000) Then
					FileFlush($UsnJrnlCsv)
				EndIf
			Next

	EndSelect

	AdlibUnRegister("_UsnJrnlProgress")
	$MaxPages = $CurrentPage
	_UsnJrnlProgress()
	ProgressOff()

	If Not $CommandlineMode Then _DisplayInfo("Entries parsed: " & $EntryCounter & @CRLF)
	_DumpOutput("Pages processed: " & $MaxPages & @CRLF)
	_DumpOutput("Entries parsed: " & $EntryCounter & @CRLF)
	If Not $CommandlineMode Then _DisplayInfo("Parsing finished in " & _WinAPI_StrFromTimeInterval(TimerDiff($begin)) & @CRLF)
	_DumpOutput("Parsing finished in " & _WinAPI_StrFromTimeInterval(TimerDiff($begin)) & @CRLF)
	_WinAPI_CloseHandle($hFile)
	FileFlush($UsnJrnlCsv)
	FileClose($UsnJrnlCsv)
	Return
EndFunc

Func _UsnDecodeRecord($Record, $OffsetRecord)
	Local $DecodeOk=False
;	$UsnJrnlRecordLength = StringMid($Record,1,8)
;	$UsnJrnlRecordLength = Dec(_SwapEndian($UsnJrnlRecordLength),2)
	$UsnJrnlMajorVersion = StringMid($Record,9,4)
	$UsnJrnlMajorVersion = Dec(_SwapEndian($UsnJrnlMajorVersion),2)
	$UsnJrnlMinorVersion = StringMid($Record,13,4)
	$UsnJrnlMinorVersion = Dec(_SwapEndian($UsnJrnlMinorVersion),2)
	$UsnJrnlFileReferenceNumber = StringMid($Record,17,12)
	$UsnJrnlFileReferenceNumber = Dec(_SwapEndian($UsnJrnlFileReferenceNumber),2)
	$UsnJrnlMFTReferenceSeqNo = StringMid($Record,29,4)
	$UsnJrnlMFTReferenceSeqNo = Dec(_SwapEndian($UsnJrnlMFTReferenceSeqNo),2)
	$UsnJrnlParentFileReferenceNumber = StringMid($Record,33,12)
	$UsnJrnlParentFileReferenceNumber = Dec(_SwapEndian($UsnJrnlParentFileReferenceNumber),2)
	$UsnJrnlParentReferenceSeqNo = StringMid($Record,45,4)
	$UsnJrnlParentReferenceSeqNo = Dec(_SwapEndian($UsnJrnlParentReferenceSeqNo),2)
	$UsnJrnlUsn = StringMid($Record,49,16)
	$UsnJrnlUsn = Dec(_SwapEndian($UsnJrnlUsn),2)
	$UsnJrnlTimestamp = StringMid($Record,65,16)
	$UsnJrnlTimestamp = _DecodeTimestamp($UsnJrnlTimestamp)
	$UsnJrnlReason = StringMid($Record,81,8)
	$UsnJrnlReason = _DecodeReasonCodes("0x"&_SwapEndian($UsnJrnlReason))
	$UsnJrnlSourceInfo = StringMid($Record,89,8)
;	$UsnJrnlSourceInfo = _DecodeSourceInfoFlag("0x"&_SwapEndian($UsnJrnlSourceInfo))
	$UsnJrnlSourceInfo = "0x"&_SwapEndian($UsnJrnlSourceInfo)
	$UsnJrnlSecurityId = StringMid($Record,97,8)
	$UsnJrnlSecurityId = Dec(_SwapEndian($UsnJrnlSecurityId),2)
	$UsnJrnlFileAttributes = StringMid($Record,105,8)
	$UsnJrnlFileAttributes = _File_Attributes("0x"&_SwapEndian($UsnJrnlFileAttributes))
	$UsnJrnlFileNameLength = StringMid($Record,113,4)
	$UsnJrnlFileNameLength = Dec(_SwapEndian($UsnJrnlFileNameLength),2)
;	$UsnJrnlFileNameOffset = StringMid($Record,117,4)
;	$UsnJrnlFileNameOffset = Dec(_SwapEndian($UsnJrnlFileNameOffset),2)
	$UsnJrnlFileName = StringMid($Record,121,$UsnJrnlFileNameLength*2)
	$UsnJrnlFileName = BinaryToString("0x"&$UsnJrnlFileName,2)
	#cs
	If $VerboseOn Then
		_DumpOutput("$UsnJrnlMajorVersion: " & $UsnJrnlMajorVersion & @CRLF)
		_DumpOutput("$UsnJrnlMinorVersion: " & $UsnJrnlMinorVersion & @CRLF)
		_DumpOutput("$UsnJrnlFileReferenceNumber: " & $UsnJrnlFileReferenceNumber & @CRLF)
		_DumpOutput("$UsnJrnlMFTReferenceSeqNo: " & $UsnJrnlMFTReferenceSeqNo & @CRLF)
		_DumpOutput("$UsnJrnlParentFileReferenceNumber: " & $UsnJrnlParentFileReferenceNumber & @CRLF)
		_DumpOutput("$UsnJrnlParentReferenceSeqNo: " & $UsnJrnlParentReferenceSeqNo & @CRLF)
		_DumpOutput("$UsnJrnlUsn: " & $UsnJrnlUsn & @CRLF)
		_DumpOutput("$UsnJrnlTimestamp: " & $UsnJrnlTimestamp & @CRLF)
		_DumpOutput("$UsnJrnlReason: " & $UsnJrnlReason & @CRLF)
		_DumpOutput("$UsnJrnlSourceInfo: " & $UsnJrnlSourceInfo & @CRLF)
		_DumpOutput("$UsnJrnlSecurityId: " & $UsnJrnlSecurityId & @CRLF)
		_DumpOutput("$UsnJrnlFileAttributes: " & $UsnJrnlFileAttributes & @CRLF)
		_DumpOutput("$UsnJrnlFileName: " & $UsnJrnlFileName & @CRLF)
	EndIf
	#ce
	If Int($UsnJrnlFileReferenceNumber) > 0 And Int($UsnJrnlMFTReferenceSeqNo) > 0 And Int($UsnJrnlParentFileReferenceNumber) > 4 And $UsnJrnlFileNameLength > 0  And $UsnJrnlTimestamp<>"-" Then
		$DecodeOk=True
		If $WithQuotes Then
			FileWriteLine($UsnJrnlCsv, '"'&$OffsetRecord&'"'&$de&'"'&$UsnJrnlFileName&'"'&$de&'"'&$UsnJrnlUsn&'"'&$de&'"'&$UsnJrnlTimestamp&'"'&$de&'"'&$UsnJrnlReason&'"'&$de&'"'&$UsnJrnlFileReferenceNumber&'"'&$de&'"'&$UsnJrnlMFTReferenceSeqNo&'"'&$de&'"'&$UsnJrnlParentFileReferenceNumber&'"'&$de&'"'&$UsnJrnlParentReferenceSeqNo&'"'&$de&'"'&$UsnJrnlFileAttributes&'"'&$de&'"'&$UsnJrnlMajorVersion&'"'&$de&'"'&$UsnJrnlMinorVersion&'"'&$de&'"'&$UsnJrnlSourceInfo&'"'&$de&'"'&$UsnJrnlSecurityId&'"'&@CRLF)
		Else
			FileWriteLine($UsnJrnlCsv, $OffsetRecord&$de&$UsnJrnlFileName&$de&$UsnJrnlUsn&$de&$UsnJrnlTimestamp&$de&$UsnJrnlReason&$de&$UsnJrnlFileReferenceNumber&$de&$UsnJrnlMFTReferenceSeqNo&$de&$UsnJrnlParentFileReferenceNumber&$de&$UsnJrnlParentReferenceSeqNo&$de&$UsnJrnlFileAttributes&$de&$UsnJrnlMajorVersion&$de&$UsnJrnlMinorVersion&$de&$UsnJrnlSourceInfo&$de&$UsnJrnlSecurityId&@crlf)
		EndIf
	Else
		_DumpOutput("Error: Bad entry at offset " & $OffsetRecord & ":" & @CRLF)
		_DumpOutput(_HexEncode("0x"&$Record) & @CRLF)
	EndIf
	Return $DecodeOk
EndFunc

Func _DecodeReasonCodes($USNReasonInput)
	;ntifs.h
	Local $USNReasonOutput = ""
	If BitAND($USNReasonInput, 0x00008000) Then $USNReasonOutput &= 'BASIC_INFO_CHANGE+'
	If BitAND($USNReasonInput, 0x80000000) Then $USNReasonOutput &= 'CLOSE+'
	If BitAND($USNReasonInput, 0x00020000) Then $USNReasonOutput &= 'COMPRESSION_CHANGE+'
	If BitAND($USNReasonInput, 0x00000002) Then $USNReasonOutput &= 'DATA_EXTEND+'
	If BitAND($USNReasonInput, 0x00000001) Then $USNReasonOutput &= 'DATA_OVERWRITE+'
	If BitAND($USNReasonInput, 0x00000004) Then $USNReasonOutput &= 'DATA_TRUNCATION+'
	If BitAND($USNReasonInput, 0x00000400) Then $USNReasonOutput &= 'EA_CHANGE+'
	If BitAND($USNReasonInput, 0x00040000) Then $USNReasonOutput &= 'ENCRYPTION_CHANGE+'
	If BitAND($USNReasonInput, 0x00000100) Then $USNReasonOutput &= 'FILE_CREATE+'
	If BitAND($USNReasonInput, 0x00000200) Then $USNReasonOutput &= 'FILE_DELETE+'
	If BitAND($USNReasonInput, 0x00010000) Then $USNReasonOutput &= 'HARD_LINK_CHANGE+'
	If BitAND($USNReasonInput, 0x00004000) Then $USNReasonOutput &= 'INDEXABLE_CHANGE+'
	If BitAND($USNReasonInput, 0x00000020) Then $USNReasonOutput &= 'NAMED_DATA_EXTEND+'
	If BitAND($USNReasonInput, 0x00000010) Then $USNReasonOutput &= 'NAMED_DATA_OVERWRITE+'
	If BitAND($USNReasonInput, 0x00000040) Then $USNReasonOutput &= 'NAMED_DATA_TRUNCATION+'
	If BitAND($USNReasonInput, 0x00080000) Then $USNReasonOutput &= 'OBJECT_ID_CHANGE+'
	If BitAND($USNReasonInput, 0x00002000) Then $USNReasonOutput &= 'RENAME_NEW_NAME+'
	If BitAND($USNReasonInput, 0x00001000) Then $USNReasonOutput &= 'RENAME_OLD_NAME+'
	If BitAND($USNReasonInput, 0x00100000) Then $USNReasonOutput &= 'REPARSE_POINT_CHANGE+'
	If BitAND($USNReasonInput, 0x00000800) Then $USNReasonOutput &= 'SECURITY_CHANGE+'
	If BitAND($USNReasonInput, 0x00200000) Then $USNReasonOutput &= 'STREAM_CHANGE+'
	If BitAND($USNReasonInput, 0x00800000) Then $USNReasonOutput &= 'INTEGRITY_CHANGE+'
	If BitAND($USNReasonInput, 0x00400000) Then $USNReasonOutput &= 'TRANSACTED_CHANGE+'
	$USNReasonOutput = StringTrimRight($USNReasonOutput, 1)
	Return $USNReasonOutput
EndFunc

Func _File_Attributes($FAInput)
	Local $FAOutput = ""
	If BitAND($FAInput, 0x0001) Then $FAOutput &= 'read_only+'
	If BitAND($FAInput, 0x0002) Then $FAOutput &= 'hidden+'
	If BitAND($FAInput, 0x0004) Then $FAOutput &= 'system+'
	If BitAND($FAInput, 0x0010) Then $FAOutput &= 'directory+'
	If BitAND($FAInput, 0x0020) Then $FAOutput &= 'archive+'
	If BitAND($FAInput, 0x0040) Then $FAOutput &= 'device+'
	If BitAND($FAInput, 0x0080) Then $FAOutput &= 'normal+'
	If BitAND($FAInput, 0x0100) Then $FAOutput &= 'temporary+'
	If BitAND($FAInput, 0x0200) Then $FAOutput &= 'sparse_file+'
	If BitAND($FAInput, 0x0400) Then $FAOutput &= 'reparse_point+'
	If BitAND($FAInput, 0x0800) Then $FAOutput &= 'compressed+'
	If BitAND($FAInput, 0x1000) Then $FAOutput &= 'offline+'
	If BitAND($FAInput, 0x2000) Then $FAOutput &= 'not_indexed+'
	If BitAND($FAInput, 0x4000) Then $FAOutput &= 'encrypted+'
	If BitAND($FAInput, 0x8000) Then $FAOutput &= 'integrity_stream+'
	If BitAND($FAInput, 0x10000) Then $FAOutput &= 'virtual+'
	If BitAND($FAInput, 0x20000) Then $FAOutput &= 'no_scrub_data+'
	If BitAND($FAInput, 0x10000000) Then $FAOutput &= 'directory+'
	If BitAND($FAInput, 0x20000000) Then $FAOutput &= 'index_view+'
	$FAOutput = StringTrimRight($FAOutput, 1)
	Return $FAOutput
EndFunc

Func _DecodeSourceInfoFlag($input)
	Select
		Case $input = 0x00000001
			$ret = "USN_SOURCE_DATA_MANAGEMENT"
		Case $input = 0x00000002
			$ret = "USN_SOURCE_AUXILIARY_DATA"
		Case $input = 0x00000004
			$ret = "USN_SOURCE_REPLICATION_MANAGEMENT"
		Case Else
			$ret = "EMPTY"
	EndSelect
	Return $ret
EndFunc

Func _DecodeTimestamp($StampDecode)
	$StampDecode = _SwapEndian($StampDecode)
	$StampDecode_tmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $StampDecode)
	$StampDecode = _WinTime_UTCFileTimeFormat(Dec($StampDecode,2) - $tDelta, $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$StampDecode = $TimestampErrorVal
	ElseIf $TimestampPrecision = 3 Then
		$StampDecode = $StampDecode & $PrecisionSeparator2 & _FillZero(StringRight($StampDecode_tmp, 4))
	EndIf
	Return $StampDecode
EndFunc

Func _SwapEndian($iHex)
	Return StringMid(Binary(Dec($iHex,2)),3, StringLen($iHex))
EndFunc

Func _FillZero($inp)
	Local $inplen, $out, $tmp = ""
	$inplen = StringLen($inp)
	For $i = 1 To 4 - $inplen
		$tmp &= "0"
	Next
	$out = $tmp & $inp
	Return $out
EndFunc   ;==>_FillZero

Func _HexEncode($bInput)
    Local $tInput = DllStructCreate("byte[" & BinaryLen($bInput) & "]")
    DllStructSetData($tInput, 1, $bInput)
    Local $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", 0, _
            "dword*", 0)

    If @error Or Not $a_iCall[0] Then
        Return SetError(1, 0, "")
    EndIf
    Local $iSize = $a_iCall[5]
    Local $tOut = DllStructCreate("char[" & $iSize & "]")
    $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), _
            "dword", DllStructGetSize($tInput), _
            "dword", 11, _
            "ptr", DllStructGetPtr($tOut), _
            "dword*", $iSize)
    If @error Or Not $a_iCall[0] Then
        Return SetError(2, 0, "")
    EndIf
    Return SetError(0, 0, DllStructGetData($tOut, 1))
EndFunc

Func _WinTime_GetUTCToLocalFileTimeDelta()
	Local $iUTCFileTime=864000000000		; exactly 24 hours from the origin (although 12 hours would be more appropriate (max variance = 12))
	$iLocalFileTime=_WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If @error Then Return SetError(@error,@extended,-1)
	Return $iLocalFileTime-$iUTCFileTime	; /36000000000 = # hours delta (effectively giving the offset in hours from UTC/GMT)
EndFunc

Func _WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If $iUTCFileTime<0 Then Return SetError(1,0,-1)
	Local $aRet=DllCall($_COMMON_KERNEL32DLL,"bool","FileTimeToLocalFileTime","uint64*",$iUTCFileTime,"uint64*",0)
	If @error Then Return SetError(2,@error,-1)
	If Not $aRet[0] Then Return SetError(3,0,-1)
	Return $aRet[2]
EndFunc

Func _WinTime_UTCFileTimeFormat($iUTCFileTime,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
;~ 	If $iUTCFileTime<0 Then Return SetError(1,0,"")	; checked in below call

	; First convert file time (UTC-based file time) to 'local file time'
	Local $iLocalFileTime=_WinTime_UTCFileTimeToLocalFileTime($iUTCFileTime)
	If @error Then Return SetError(@error,@extended,"")
	; Rare occassion: a filetime near the origin (January 1, 1601!!) is used,
	;	causing a negative result (for some timezones). Return as invalid param.
	If $iLocalFileTime<0 Then Return SetError(1,0,"")

	; Then convert file time to a system time array & format & return it
	Local $vReturn=_WinTime_LocalFileTimeFormat($iLocalFileTime,$iFormat,$iPrecision,$bAMPMConversion)
	Return SetError(@error,@extended,$vReturn)
EndFunc

Func _WinTime_LocalFileTimeFormat($iLocalFileTime,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
;~ 	If $iLocalFileTime<0 Then Return SetError(1,0,"")	; checked in below call

	; Convert file time to a system time array & return result
	Local $aSysTime=_WinTime_LocalFileTimeToSystemTime($iLocalFileTime)
	If @error Then Return SetError(@error,@extended,"")

	; Return only the SystemTime array?
	If $iFormat=0 Then Return $aSysTime

	Local $vReturn=_WinTime_FormatTime($aSysTime[0],$aSysTime[1],$aSysTime[2],$aSysTime[3], _
		$aSysTime[4],$aSysTime[5],$aSysTime[6],$aSysTime[7],$iFormat,$iPrecision,$bAMPMConversion)
	Return SetError(@error,@extended,$vReturn)
EndFunc

Func _WinTime_LocalFileTimeToSystemTime($iLocalFileTime)
	Local $aRet,$stSysTime,$aSysTime[8]=[-1,-1,-1,-1,-1,-1,-1,-1]

	; Negative values unacceptable
	If $iLocalFileTime<0 Then Return SetError(1,0,$aSysTime)

	; SYSTEMTIME structure [Year,Month,DayOfWeek,Day,Hour,Min,Sec,Milliseconds]
	$stSysTime=DllStructCreate("ushort[8]")

	$aRet=DllCall($_COMMON_KERNEL32DLL,"bool","FileTimeToSystemTime","uint64*",$iLocalFileTime,"ptr",DllStructGetPtr($stSysTime))
	If @error Then Return SetError(2,@error,$aSysTime)
	If Not $aRet[0] Then Return SetError(3,0,$aSysTime)
	Dim $aSysTime[8]=[DllStructGetData($stSysTime,1,1),DllStructGetData($stSysTime,1,2),DllStructGetData($stSysTime,1,4),DllStructGetData($stSysTime,1,5), _
		DllStructGetData($stSysTime,1,6),DllStructGetData($stSysTime,1,7),DllStructGetData($stSysTime,1,8),DllStructGetData($stSysTime,1,3)]
	Return $aSysTime
EndFunc

Func _WinTime_FormatTime($iYear,$iMonth,$iDay,$iHour,$iMin,$iSec,$iMilSec,$iDayOfWeek,$iFormat=4,$iPrecision=0,$bAMPMConversion=False)
	Local Static $_WT_aMonths[12]=["January","February","March","April","May","June","July","August","September","October","November","December"]
	Local Static $_WT_aDays[7]=["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

	If Not $iFormat Or $iMonth<1 Or $iMonth>12 Or $iDayOfWeek>6 Then Return SetError(1,0,"")

	; Pad MM,DD,HH,MM,SS,MSMSMSMS as necessary
	Local $sMM=StringRight(0&$iMonth,2),$sDD=StringRight(0&$iDay,2),$sMin=StringRight(0&$iMin,2)
	; $sYY = $iYear	; (no padding)
	;	[technically Year can be 1-x chars - but this is generally used for 4-digit years. And SystemTime only goes up to 30827/30828]
	Local $sHH,$sSS,$sMS,$sAMPM

	; 'Extra precision 1': +SS (Seconds)
	If $iPrecision Then
		$sSS=StringRight(0&$iSec,2)
		; 'Extra precision 2': +MSMSMSMS (Milliseconds)
		If $iPrecision>1 Then
;			$sMS=StringRight('000'&$iMilSec,4)
			$sMS=StringRight('000'&$iMilSec,3);Fixed an erronous 0 in front of the milliseconds
		Else
			$sMS=""
		EndIf
	Else
		$sSS=""
		$sMS=""
	EndIf
	If $bAMPMConversion Then
		If $iHour>11 Then
			$sAMPM=" PM"
			; 12 PM will cause 12-12 to equal 0, so avoid the calculation:
			If $iHour=12 Then
				$sHH="12"
			Else
				$sHH=StringRight(0&($iHour-12),2)
			EndIf
		Else
			$sAMPM=" AM"
			If $iHour Then
				$sHH=StringRight(0&$iHour,2)
			Else
			; 00 military = 12 AM
				$sHH="12"
			EndIf
		EndIf
	Else
		$sAMPM=""
		$sHH=StringRight(0 & $iHour,2)
	EndIf

	Local $sDateTimeStr,$aReturnArray[3]

	; Return an array? [formatted string + "Month" + "DayOfWeek"]
	If BitAND($iFormat,0x10) Then
		$aReturnArray[1]=$_WT_aMonths[$iMonth-1]
		If $iDayOfWeek>=0 Then
			$aReturnArray[2]=$_WT_aDays[$iDayOfWeek]
		Else
			$aReturnArray[2]=""
		EndIf
		; Strip the 'array' bit off (array[1] will now indicate if an array is to be returned)
		$iFormat=BitAND($iFormat,0xF)
	Else
		; Signal to below that the array isn't to be returned
		$aReturnArray[1]=""
	EndIf

	; Prefix with "DayOfWeek "?
	If BitAND($iFormat,8) Then
		If $iDayOfWeek<0 Then Return SetError(1,0,"")	; invalid
		$sDateTimeStr=$_WT_aDays[$iDayOfWeek]&', '
		; Strip the 'DayOfWeek' bit off
		$iFormat=BitAND($iFormat,0x7)
	Else
		$sDateTimeStr=""
	EndIf

	If $iFormat<2 Then
		; Basic String format: YYYYMMDDHHMM[SS[MSMSMSMS[ AM/PM]]]
		$sDateTimeStr&=$iYear&$sMM&$sDD&$sHH&$sMin&$sSS&$sMS&$sAMPM
	Else
		; one of 4 formats which ends with " HH:MM[:SS[:MSMSMSMS[ AM/PM]]]"
		Switch $iFormat
			; /, : Format - MM/DD/YYYY
			Case 2
				$sDateTimeStr&=$sMM&'/'&$sDD&'/'
			; /, : alt. Format - DD/MM/YYYY
			Case 3
				$sDateTimeStr&=$sDD&'/'&$sMM&'/'
			; "Month DD, YYYY" format
			Case 4
				$sDateTimeStr&=$_WT_aMonths[$iMonth-1]&' '&$sDD&', '
			; "DD Month YYYY" format
			Case 5
				$sDateTimeStr&=$sDD&' '&$_WT_aMonths[$iMonth-1]&' '
			Case 6
				$sDateTimeStr&=$iYear&'-'&$sMM&'-'&$sDD
				$iYear=''
			Case Else
				Return SetError(1,0,"")
		EndSwitch
		$sDateTimeStr&=$iYear&' '&$sHH&':'&$sMin
		If $iPrecision Then
			$sDateTimeStr&=':'&$sSS
;			If $iPrecision>1 Then $sDateTimeStr&=':'&$sMS
			If $iPrecision>1 Then $sDateTimeStr&=$PrecisionSeparator&$sMS
		EndIf
		$sDateTimeStr&=$sAMPM
	EndIf
	If $aReturnArray[1]<>"" Then
		$aReturnArray[0]=$sDateTimeStr
		Return $aReturnArray
	EndIf
	Return $sDateTimeStr
EndFunc

Func _DisplayInfo($DebugInfo)
	GUICtrlSetData($myctredit, $DebugInfo, 1)
EndFunc

Func _DisplayProgress()
	ProgressSet(Round((($CurrentPage / $MaxPages) * 100), 2), Round(($CurrentPage / $MaxPages) * 100, 2) & "  % finished parsing", "")
EndFunc

Func _WriteCSVHeader()
	If $DoDefaultAll Then
		$UsnJrnl_Csv_Header = "Offset"&$de&"FileName"&$de&"USN"&$de&"Timestamp"&$de&"Reason"&$de&"MFTReference"&$de&"MFTReferenceSeqNo"&$de&"MFTParentReference"&$de&"MFTParentReferenceSeqNo"&$de&"FileAttributes"&$de&"MajorVersion"&$de&"MinorVersion"&$de&"SourceInfo"&$de&"SecurityId"
	ElseIf $dol2t Then
		$UsnJrnl_Csv_Header = "Date"&$de&"Time"&$de&"Timezone"&$de&"MACB"&$de&"Source"&$de&"SourceType"&$de&"Type"&$de&"User"&$de&"Host"&$de&"Short"&$de&"Desc"&$de&"Version"&$de&"Filename"&$de&"Inode"&$de&"Notes"&$de&"Format"&$de&"Extra"
	ElseIf $DoBodyfile Then
		$UsnJrnl_Csv_Header = "MD5"&$de&"name"&$de&"inode"&$de&"mode_as_string"&$de&"UID"&$de&"GID"&$de&"size"&$de&"atime"&$de&"mtime"&$de&"ctime"&$de&"crtime"
	EndIf
	FileWriteLine($UsnJrnlCsv, $UsnJrnl_Csv_Header & @CRLF)
EndFunc

Func _InjectTimeZoneInfo()
$Regions = "UTC: -12.00|" & _
	"UTC: -11.00|" & _
	"UTC: -10.00|" & _
	"UTC: -9.30|" & _
	"UTC: -9.00|" & _
	"UTC: -8.00|" & _
	"UTC: -7.00|" & _
	"UTC: -6.00|" & _
	"UTC: -5.00|" & _
	"UTC: -4.30|" & _
	"UTC: -4.00|" & _
	"UTC: -3.30|" & _
	"UTC: -3.00|" & _
	"UTC: -2.00|" & _
	"UTC: -1.00|" & _
	"UTC: 0.00|" & _
	"UTC: 1.00|" & _
	"UTC: 2.00|" & _
	"UTC: 3.00|" & _
	"UTC: 3.30|" & _
	"UTC: 4.00|" & _
	"UTC: 4.30|" & _
	"UTC: 5.00|" & _
	"UTC: 5.30|" & _
	"UTC: 5.45|" & _
	"UTC: 6.00|" & _
	"UTC: 6.30|" & _
	"UTC: 7.00|" & _
	"UTC: 8.00|" & _
	"UTC: 8.45|" & _
	"UTC: 9.00|" & _
	"UTC: 9.30|" & _
	"UTC: 10.00|" & _
	"UTC: 10.30|" & _
	"UTC: 11.00|" & _
	"UTC: 11.30|" & _
	"UTC: 12.00|" & _
	"UTC: 12.45|" & _
	"UTC: 13.00|" & _
	"UTC: 14.00|"
GUICtrlSetData($Combo2,$Regions,"UTC: 0.00")
EndFunc
#cs
Func _GetUTCRegion()
	$UTCRegion = GUICtrlRead($Combo2)
	If $UTCRegion = "" Then Return SetError(1,0,0)
	$part1 = StringMid($UTCRegion,StringInStr($UTCRegion," ")+1)
	Global $UTCconfig = $part1
	If StringRight($part1,2) = "15" Then $part1 = StringReplace($part1,".15",".25")
	If StringRight($part1,2) = "30" Then $part1 = StringReplace($part1,".30",".50")
	If StringRight($part1,2) = "45" Then $part1 = StringReplace($part1,".45",".75")
	$DeltaTest = $part1*36000000000
	Return $DeltaTest
EndFunc
#ce
Func _GetUTCRegion($UTCRegion)
	If $UTCRegion = "" Then Return SetError(1,0,0)

	If StringInStr($UTCRegion,"UTC:") Then
		$part1 = StringMid($UTCRegion,StringInStr($UTCRegion," ")+1)
	Else
		$part1 = $UTCRegion
	EndIf
	Global $UTCconfig = $part1
	If StringRight($part1,2) = "15" Then $part1 = StringReplace($part1,".15",".25")
	If StringRight($part1,2) = "30" Then $part1 = StringReplace($part1,".30",".50")
	If StringRight($part1,2) = "45" Then $part1 = StringReplace($part1,".45",".75")
	$DeltaTest = $part1*36000000000
	Return $DeltaTest
EndFunc

Func _TranslateSeparator()
	; Or do it the other way around to allow setting other trickier separators, like specifying it in hex
	GUICtrlSetData($SaparatorInput,StringLeft(GUICtrlRead($SaparatorInput),1))
	GUICtrlSetData($SaparatorInput2,"0x"&Hex(Asc(GUICtrlRead($SaparatorInput)),2))
EndFunc

Func _InjectTimestampFormat()
Local $Formats = "1|" & _
	"2|" & _
	"3|" & _
	"4|" & _
	"5|" & _
	"6|"
	GUICtrlSetData($ComboTimestampFormat,$Formats,"6")
EndFunc

Func _InjectTimestampPrecision()
Local $Precision = "None|" & _
	"MilliSec|" & _
	"NanoSec|"
	GUICtrlSetData($ComboTimestampPrecision,$Precision,"NanoSec")
EndFunc

Func _TranslateTimestamp()
	Local $lPrecision,$lTimestamp,$lTimestampTmp
	$DateTimeFormat = StringLeft(GUICtrlRead($ComboTimestampFormat),1)
	$lPrecision = GUICtrlRead($ComboTimestampPrecision)
	Select
		Case $lPrecision = "None"
			$TimestampPrecision = 1
		Case $lPrecision = "MilliSec"
			$TimestampPrecision = 2
		Case $lPrecision = "NanoSec"
			$TimestampPrecision = 3
	EndSelect
	$lTimestampTmp = _WinTime_UTCFileTimeToLocalFileTime("0x" & $ExampleTimestampVal)
	$lTimestamp = _WinTime_UTCFileTimeFormat(Dec($ExampleTimestampVal,2), $DateTimeFormat, $TimestampPrecision)
	If @error Then
		$lTimestamp = $TimestampErrorVal
	ElseIf $TimestampPrecision = 3 Then
		$lTimestamp = $lTimestamp & $PrecisionSeparator2 & _FillZero(StringRight($lTimestampTmp, 4))
	EndIf
	GUICtrlSetData($InputExampleTimestamp,$lTimestamp)
EndFunc

Func _UsnJrnlProgress()
    GUICtrlSetData($ProgressStatus, "Processing UsnJrnl page " & $CurrentPage & " of " & $MaxPages & ", total entries: " & $EntryCounter)
    GUICtrlSetData($ElapsedTime, "Elapsed time = " & _WinAPI_StrFromTimeInterval(TimerDiff($begin)))
	GUICtrlSetData($ProgressUsnJrnl, 100 * $CurrentPage / $MaxPages)
EndFunc

Func _DumpOutput($text)
   ConsoleWrite($text)
   If $DebugOutFile Then FileWrite($DebugOutFile, $text)
EndFunc

Func _UsnProcessPage($TargetPage,$OffsetFile,$OffsetChunk)
	Local $LocalUsnCounter = 0, $NextOffset = 1, $TotalSizeOfPage = StringLen($TargetPage), $OffsetRecord=0
	Do
		$SizeOfNextUsnRecord = StringMid($TargetPage,$NextOffset,8)
		$SizeOfNextUsnRecord = Dec(_SwapEndian($SizeOfNextUsnRecord),2)
		If $SizeOfNextUsnRecord = 0 Then
;			_DumpOutput("Zero padding at offset 0x" & Hex(Int($CurrentPage*$USN_Page_Size+(($NextOffset-1)/2))) & @CRLF)
			ExitLoop
		EndIf
		$SizeOfNextUsnRecord = $SizeOfNextUsnRecord*2
		$NextUsnRecord = StringMid($TargetPage,$NextOffset,$SizeOfNextUsnRecord)
		$FileNameLength = StringMid($TargetPage,$NextOffset+112,4)
		$FileNameLength = Dec(_SwapEndian($FileNameLength),2)
		$OffsetRecord = "0x" & Hex(Int($OffsetFile + ($OffsetChunk + $NextOffset)/2))
		$LocalUsnCounter += _UsnDecodeRecord($NextUsnRecord, $OffsetRecord)
		$NextOffset+=$SizeOfNextUsnRecord
	Until $NextOffset-$SizeOfNextUsnRecord > $TotalSizeOfPage
	Return $LocalUsnCounter
EndFunc

Func _ScanModeUsnProcessPage($TargetPage)
	Local $NextOffset = 1, $TotalSizeOfPage = StringLen($TargetPage)
	Do
		$SizeOfNextUsnRecord = StringMid($TargetPage,$NextOffset,8)
		$SizeOfNextUsnRecord = Dec(_SwapEndian($SizeOfNextUsnRecord),2)
		$SizeOfNextUsnRecord = $SizeOfNextUsnRecord*2
		$NextUsnRecord = StringMid($TargetPage,$NextOffset,$SizeOfNextUsnRecord)
		If _ScanModeUsnDecodeRecord($NextUsnRecord) Then
;			_DumpOutput("Found entry at offset 0x" & Hex(Int($CurrentPage*$USN_Page_Size+(($NextOffset-1)/2))) & @CRLF)
;			_DumpOutput(_HexEncode("0x"&$NextUsnRecord) & @CRLF)
			Return $NextOffset-1
		Else
;			_DumpOutput("Bad entry at offset 0x" & Hex(Int($CurrentPage*$USN_Page_Size+(($NextOffset-1)/2))) & @CRLF)
;			_DumpOutput(_HexEncode("0x"&$NextUsnRecord) & @CRLF)
			$NextOffset+=2
		EndIf

	Until $NextOffset >= $TotalSizeOfPage
	Return SetError(1,0,0)
EndFunc

Func _ScanModeUsnProcessPage2($TargetPage,$OffsetFile,$OffsetChunk)
	Local $LocalUsnCounter = 0, $NextOffset = 1, $TotalSizeOfPage = StringLen($TargetPage)
	Do
		$SizeOfNextUsnRecord = StringMid($TargetPage,$NextOffset,8)
		$SizeOfNextUsnRecord = Dec(_SwapEndian($SizeOfNextUsnRecord),2)
		$SizeOfNextUsnRecord = $SizeOfNextUsnRecord*2
		$NextUsnRecord = StringMid($TargetPage,$NextOffset,$SizeOfNextUsnRecord)
		If _ScanModeUsnDecodeRecord($NextUsnRecord) Then
;			_DumpOutput("Found entry at offset 0x" & Hex(Int($CurrentPage*$USN_Page_Size+(($NextOffset-1)/2))) & @CRLF)
;			_DumpOutput(_HexEncode("0x"&$NextUsnRecord) & @CRLF)
			$OffsetRecord = "0x" & Hex(Int($OffsetFile + ($OffsetChunk + $NextOffset)/2))
			$LocalUsnCounter += _UsnDecodeRecord($NextUsnRecord, $OffsetRecord)
			$NextOffset+=$SizeOfNextUsnRecord
;			Return $NextOffset-1
		Else
;			_DumpOutput("Bad entry at offset 0x" & Hex(Int($CurrentPage*$USN_Page_Size+(($NextOffset-1)/2))) & @CRLF)
;			_DumpOutput(_HexEncode("0x"&$NextUsnRecord) & @CRLF)
			$NextOffset+=2
		EndIf

	Until $NextOffset > $TotalSizeOfPage
	Return $LocalUsnCounter
EndFunc

Func _ScanModeUsnDecodeRecord($Record)
	$UsnJrnlRecordLength = StringMid($Record,1,8)
	$UsnJrnlRecordLength = Dec(_SwapEndian($UsnJrnlRecordLength),2)
	If $UsnJrnlRecordLength > $USN_Page_Size Then Return SetError(1,0,0)
	$UsnJrnlMajorVersion = StringMid($Record,9,4)
	$UsnJrnlMajorVersion = Dec(_SwapEndian($UsnJrnlMajorVersion),2)
	If $UsnJrnlMajorVersion < 2 And $UsnJrnlMajorVersion > 4 Then Return SetError(1,0,0)
;	$UsnJrnlMinorVersion = StringMid($Record,13,4)
;	$UsnJrnlMinorVersion = Dec(_SwapEndian($UsnJrnlMinorVersion),2)
	$UsnJrnlFileReferenceNumber = StringMid($Record,17,12)
	$UsnJrnlFileReferenceNumber = Dec(_SwapEndian($UsnJrnlFileReferenceNumber),2)
	If $UsnJrnlFileReferenceNumber = 0 Then Return SetError(1,0,0)
	$UsnJrnlMFTReferenceSeqNo = StringMid($Record,29,4)
	$UsnJrnlMFTReferenceSeqNo = Dec(_SwapEndian($UsnJrnlMFTReferenceSeqNo),2)
	If $UsnJrnlMFTReferenceSeqNo = 0 Then Return SetError(1,0,0)
	$UsnJrnlParentFileReferenceNumber = StringMid($Record,33,12)
	$UsnJrnlParentFileReferenceNumber = Dec(_SwapEndian($UsnJrnlParentFileReferenceNumber),2)
	If $UsnJrnlParentFileReferenceNumber < 5 Then Return SetError(1,0,0)
	$UsnJrnlParentReferenceSeqNo = StringMid($Record,45,4)
	$UsnJrnlParentReferenceSeqNo = Dec(_SwapEndian($UsnJrnlParentReferenceSeqNo),2)
	If $UsnJrnlParentReferenceSeqNo = 0 Then Return SetError(1,0,0)
	$UsnJrnlUsn = StringMid($Record,49,16)
	$UsnJrnlUsn = Dec(_SwapEndian($UsnJrnlUsn),2)
	If $UsnJrnlUsn = 0 Then Return SetError(1,0,0)
	$UsnJrnlTimestamp = StringMid($Record,65,16)
	$UsnJrnlTimestamp = _DecodeTimestamp($UsnJrnlTimestamp)
	If $UsnJrnlTimestamp = $TimestampErrorVal Then Return SetError(1,0,0)
	$UsnJrnlReason = StringMid($Record,81,8)
	$UsnJrnlReason = Dec(_SwapEndian($UsnJrnlReason),2)
	If $UsnJrnlReason = 0 Then Return SetError(1,0,0)
;	$UsnJrnlSourceInfo = StringMid($Record,89,8)
;	$UsnJrnlSourceInfo = "0x"&_SwapEndian($UsnJrnlSourceInfo)
;	$UsnJrnlSecurityId = StringMid($Record,97,8)
;	$UsnJrnlSecurityId = Dec(_SwapEndian($UsnJrnlSecurityId),2)
;	$UsnJrnlFileAttributes = StringMid($Record,105,8)
;	$UsnJrnlFileAttributes = _File_Attributes("0x"&_SwapEndian($UsnJrnlFileAttributes))
	$UsnJrnlFileNameLength = StringMid($Record,113,4)
	$UsnJrnlFileNameLength = Dec(_SwapEndian($UsnJrnlFileNameLength),2)
	If $UsnJrnlFileNameLength = 0 Then Return SetError(1,0,0)
	$UsnJrnlFileNameOffset = StringMid($Record,117,4)
	$UsnJrnlFileNameOffset = Dec(_SwapEndian($UsnJrnlFileNameOffset),2)
	If $UsnJrnlFileNameOffset <> 60 Then Return SetError(1,0,0)
	$UsnJrnlFileName = StringMid($Record,121,$UsnJrnlFileNameLength*2)
	$UsnJrnlFileName = BinaryToString("0x"&$UsnJrnlFileName,2)
	If @error Or $UsnJrnlFileName = "" Or StringLen($UsnJrnlFileName)>$UsnJrnlRecordLength*2 Or StringLen($UsnJrnlFileName)>255 Then Return SetError(1,0,0)
#cs
;	_DumpOutput("$UsnJrnlMajorVersion: " & $UsnJrnlMajorVersion & @CRLF)
;	_DumpOutput("$UsnJrnlMinorVersion: " & $UsnJrnlMinorVersion & @CRLF)
	_DumpOutput("$UsnJrnlFileReferenceNumber: " & $UsnJrnlFileReferenceNumber & @CRLF)
	_DumpOutput("$UsnJrnlMFTReferenceSeqNo: " & $UsnJrnlMFTReferenceSeqNo & @CRLF)
	_DumpOutput("$UsnJrnlParentFileReferenceNumber: " & $UsnJrnlParentFileReferenceNumber & @CRLF)
	_DumpOutput("$UsnJrnlParentReferenceSeqNo: " & $UsnJrnlParentReferenceSeqNo & @CRLF)
	_DumpOutput("$UsnJrnlUsn: " & $UsnJrnlUsn & @CRLF)
	_DumpOutput("$UsnJrnlTimestamp: " & $UsnJrnlTimestamp & @CRLF)
;	_DumpOutput("$UsnJrnlReason: " & $UsnJrnlReason & @CRLF)
;	_DumpOutput("$UsnJrnlSourceInfo: " & $UsnJrnlSourceInfo & @CRLF)
;	_DumpOutput("$UsnJrnlSecurityId: " & $UsnJrnlSecurityId & @CRLF)
;	_DumpOutput("$UsnJrnlFileAttributes: " & $UsnJrnlFileAttributes & @CRLF)
	_DumpOutput("$UsnJrnlFileName: " & $UsnJrnlFileName & @CRLF)
#ce
	Return 1
EndFunc

Func _GetInputParams()
	Local $TimeZone, $OutputFormat, $ScanMode
	For $i = 1 To $cmdline[0]
		;ConsoleWrite("Param " & $i & ": " & $cmdline[$i] & @CRLF)
		If StringLeft($cmdline[$i],13) = "/UsnJrnlFile:" Then $File = StringMid($cmdline[$i],14)
		If StringLeft($cmdline[$i],12) = "/OutputPath:" Then $ParserOutDir = StringMid($cmdline[$i],13)
		If StringLeft($cmdline[$i],10) = "/TimeZone:" Then $TimeZone = StringMid($cmdline[$i],11)
		If StringLeft($cmdline[$i],14) = "/OutputFormat:" Then $OutputFormat = StringMid($cmdline[$i],15)
		If StringLeft($cmdline[$i],11) = "/Separator:" Then $SeparatorInput = StringMid($cmdline[$i],12)
		If StringLeft($cmdline[$i],15) = "/QuotationMark:" Then $checkquotes = StringMid($cmdline[$i],16)
		If StringLeft($cmdline[$i],9) = "/Unicode:" Then $CheckUnicode = StringMid($cmdline[$i],10)
		If StringLeft($cmdline[$i],10) = "/ScanMode:" Then $ScanMode = StringMid($cmdline[$i],11)
		If StringLeft($cmdline[$i],10) = "/TSFormat:" Then $DateTimeFormat = StringMid($cmdline[$i],11)
		If StringLeft($cmdline[$i],13) = "/TSPrecision:" Then $TimestampPrecision = StringMid($cmdline[$i],14)
		If StringLeft($cmdline[$i],22) = "/TSPrecisionSeparator:" Then $PrecisionSeparator = StringMid($cmdline[$i],23)
		If StringLeft($cmdline[$i],23) = "/TSPrecisionSeparator2:" Then $PrecisionSeparator2 = StringMid($cmdline[$i],24)
		If StringLeft($cmdline[$i],12) = "/TSErrorVal:" Then $TimestampErrorVal = StringMid($cmdline[$i],13)
		If StringLeft($cmdline[$i],13) = "/UsnPageSize:" Then $USN_Page_Size = StringMid($cmdline[$i],14)
	Next

	If StringLen($ScanMode) > 0 Then
		If $ScanMode <> 0 And $ScanMode <> 1 And $ScanMode <> 2 Then
			ConsoleWrite("Error: Incorect ScanMode: " & $ScanMode & @CRLF)
			Exit
		EndIf
	Else
		$ScanMode = 0
	EndIf
	Select
		case $ScanMode = 0
			$DoNormalMode = 1
			$DoScanMode1 = 0
			$DoScanMode2 = 0
		case $ScanMode = 1
			$DoNormalMode = 0
			$DoScanMode1 = 1
			$DoScanMode2 = 0
		case $ScanMode = 2
			$DoNormalMode = 0
			$DoScanMode1 = 0
			$DoScanMode2 = 1
	EndSelect

	If StringLen($TimeZone) > 0 Then
		Select
			Case $TimeZone = "-12.00"
			Case $TimeZone = "-11.00"
			Case $TimeZone = "-10.00"
			Case $TimeZone = "-9.30"
			Case $TimeZone = "-9.00"
			Case $TimeZone = "-8.00"
			Case $TimeZone = "-7.00"
			Case $TimeZone = "-6.00"
			Case $TimeZone = "-5.00"
			Case $TimeZone = "-4.30"
			Case $TimeZone = "-4.00"
			Case $TimeZone = "-3.30"
			Case $TimeZone = "-3.00"
			Case $TimeZone = "-2.00"
			Case $TimeZone = "-1.00"
			Case $TimeZone = "0.00"
			Case $TimeZone = "1.00"
			Case $TimeZone = "2.00"
			Case $TimeZone = "3.00"
			Case $TimeZone = "3.30"
			Case $TimeZone = "4.00"
			Case $TimeZone = "4.30"
			Case $TimeZone = "5.00"
			Case $TimeZone = "5.30"
			Case $TimeZone = "5.45"
			Case $TimeZone = "6.00"
			Case $TimeZone = "6.30"
			Case $TimeZone = "7.00"
			Case $TimeZone = "8.00"
			Case $TimeZone = "8.45"
			Case $TimeZone = "9.00"
			Case $TimeZone = "9.30"
			Case $TimeZone = "10.00"
			Case $TimeZone = "10.30"
			Case $TimeZone = "11.00"
			Case $TimeZone = "11.30"
			Case $TimeZone = "12.00"
			Case $TimeZone = "12.45"
			Case $TimeZone = "13.00"
			Case $TimeZone = "14.00"
			Case Else
				$TimeZone = "0.00"
		EndSelect
	Else
		$TimeZone = "0.00"
	EndIf

	$tDelta = _GetUTCRegion($TimeZone)-$tDelta
	If @error Then
		_DisplayInfo("Error: Timezone configuration failed." & @CRLF)
	Else
		_DisplayInfo("Timestamps presented in UTC: " & $UTCconfig & @CRLF)
	EndIf
	$tDelta = $tDelta*-1

	If StringLen($File) > 0 Then
		If Not FileExists($File) Then
			ConsoleWrite("Error input $UsnJrnl file does not exist." & @CRLF)
			Exit
		EndIf
	EndIf
#cs
	If StringLen($OutputFormat) > 0 Then
		If $OutputFormat = "l2t" Then $checkl2t = 1
		If $OutputFormat = "bodyfile" Then $checkbodyfile = 1
		If $OutputFormat = "all" Then $checkdefaultall = 1
		If $checkl2t + $checkbodyfile = 0 Then $checkdefaultall = 1
	Else
		$checkdefaultall = 1
	EndIf
#ce
	$checkdefaultall = 1
	$DoDefaultAll = 1
	$dol2t = 0
	$DoBodyfile = 0

	If StringLen($PrecisionSeparator) <> 1 Then $PrecisionSeparator = "."
	If StringLen($SeparatorInput) <> 1 Then $SeparatorInput = "|"

	If StringLen($TimestampPrecision) > 0 Then
		Select
			Case $TimestampPrecision = "None"
				ConsoleWrite("Timestamp Precision: " & $TimestampPrecision & @CRLF)
				$TimestampPrecision = 1
			Case $TimestampPrecision = "MilliSec"
				ConsoleWrite("Timestamp Precision: " & $TimestampPrecision & @CRLF)
				$TimestampPrecision = 2
			Case $TimestampPrecision = "NanoSec"
				ConsoleWrite("Timestamp Precision: " & $TimestampPrecision & @CRLF)
				$TimestampPrecision = 3
		EndSelect
	Else
		$TimestampPrecision = 1
	EndIf

	If StringLen($DateTimeFormat) > 0 Then
		If $DateTimeFormat <> 1 And $DateTimeFormat <> 2 And $DateTimeFormat <> 3 And $DateTimeFormat <> 4 And $DateTimeFormat <> 5 And $DateTimeFormat <> 6 Then
			$DateTimeFormat = 6
		EndIf
	Else
		$DateTimeFormat = 6
	EndIf
EndFunc