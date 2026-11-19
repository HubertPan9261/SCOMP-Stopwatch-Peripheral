; Two-digit stopwatch game.
;
; Left four displays: captured time in hexadecimal milliseconds.
; Right two displays: game digits, or EE when the game ends.
;
; SW0 selects the right digit.
; SW1 selects the left digit.
; Lower all switches, then raise only SW9 to start a round.
;
; Ten seconds of active playing time across all rounds.
; Between-round waiting time does not count.
; Hardware reset restarts the game.

ORG 0

Reset:
    LOADI  4
    OUT    SW_CONTROL        ; Clear stopwatch; remain stopped

    LOADI  0
    STORE  Value
    STORE  CapturedTime
    STORE  Candidate
    OUT    LEDs
    CALL   UpdateDisplay

; Stopwatch remains paused during round setup.
WaitAllDown:
    IN     Switches
    OUT    LEDs
    JNZ    WaitAllDown

; Generate a changing two-digit hexadecimal number.
Counting:
    LOAD   Candidate
    ADDI   1
    AND    ByteMask
    STORE  Candidate

    IN     Switches
    OUT    LEDs
    JZERO  Counting

    SUB    Bit9
    JZERO  StartRound
    JUMP   WaitAllDown

StartRound:
    LOAD   Candidate
    JZERO  WaitAllDown
    STORE  Value

    CALL   UpdateDisplay

    LOADI  3
    OUT    SW_CONTROL        ; Resume accumulated active time

FindLargest:
    LOAD   Value
    AND    NibbleMask
    STORE  RightDigit

    LOAD   Value
    SHIFT  -4
    AND    NibbleMask
    STORE  LeftDigit

    LOAD   RightDigit
    STORE  Largest

    LOAD   LeftDigit
    SUB    Largest
    JPOS   UseLeftDigit
    JUMP   CheckAnswer

UseLeftDigit:
    LOAD   LeftDigit
    STORE  Largest

; Accept exactly one selection switch.
CheckAnswer:
    CALL   CheckTime

    IN     Switches
    OUT    LEDs
    AND    SelectionMask
    STORE  Pattern
    JZERO  CheckAnswer

    SUB    Bit0
    JZERO  SelectedRight

    LOAD   Pattern
    SUB    Bit1
    JZERO  SelectedLeft

    JUMP   CheckAnswer

SelectedRight:
    LOAD   RightDigit
    JZERO  WaitSelectionDown
    STORE  SelectedDigit

    LOAD   ClearRight
    STORE  ClearMask
    JUMP   CompareDigit

SelectedLeft:
    LOAD   LeftDigit
    JZERO  WaitSelectionDown
    STORE  SelectedDigit

    LOAD   ClearLeft
    STORE  ClearMask

CompareDigit:
    LOAD   SelectedDigit
    SUB    Largest
    JNZ    GameOver

CorrectAnswer:
    CALL   CheckTime

    LOADI  5
    OUT    SW_CONTROL        ; Capture; continue counting

    IN     SW_CAPTURED
    STORE  CapturedTime

    LOAD   Value
    AND    ClearMask
    STORE  Value
    JZERO  RoundComplete

    CALL   UpdateDisplay

; Lower both selection switches before selecting again.
; Stopwatch continues running during this wait.
WaitSelectionDown:
    CALL   CheckTime

    IN     Switches
    OUT    LEDs
    AND    SelectionMask
    JNZ    WaitSelectionDown

    JUMP   FindLargest

RoundComplete:
    LOADI  2
    OUT    SW_CONTROL        ; Pause between rounds

    CALL   CheckTime         ; Check final paused time too

    LOADI  5
    OUT    SW_CONTROL

    IN     SW_CAPTURED
    STORE  CapturedTime

    CALL   UpdateDisplay
    JUMP   WaitAllDown

; Wrong selection, timeout, or overflow.
GameOver:
    LOADI  2
    OUT    SW_CONTROL        ; Preserve final elapsed time

    LOADI  5
    OUT    SW_CONTROL

    IN     SW_CAPTURED
    STORE  CapturedTime

    LOAD   EndMarker
    STORE  Value             ; EE on the right two displays

    CALL   UpdateDisplay

GameOverLoop:
    IN     Switches
    OUT    LEDs
    JUMP   GameOverLoop

; ---------- Subroutines ----------

CheckTime:
    IN     SW_STATUS
    AND    OverflowMask
    JNZ    GameOver

    IN     SW_ELAPSED

    ; A set sign bit means unsigned time >= 32768 ms,
    ; which is already beyond our 10000 ms limit.
    JNEG   GameOver

    SUB    TimeLimit
    JNEG   TimeRemaining
    JUMP   GameOver

TimeRemaining:
    RETURN

; HEX5 HEX4 HEX3 HEX2 | HEX1 HEX0
;    CapturedTime    |   Value
UpdateDisplay:
    LOAD   CapturedTime
    SHIFT  -8
    AND    ByteMask
    OUT    Hex1

    LOAD   CapturedTime
    AND    ByteMask
    SHIFT  8
    ADD    Value
    OUT    Hex0
    RETURN

; ---------- Variables ----------

Value:          DW 0
Candidate:      DW 0
CapturedTime:   DW 0
RightDigit:     DW 0
LeftDigit:      DW 0
Largest:        DW 0
SelectedDigit:  DW 0
ClearMask:      DW 0
Pattern:        DW 0

; ---------- Constants ----------

TimeLimit:      DW 10000
EndMarker:      DW &H00EE

NibbleMask:     DW &H000F
ByteMask:       DW &H00FF
SelectionMask:  DW &H0003
OverflowMask:   DW &H0004

Bit0:           DW &H0001
Bit1:           DW &H0002
Bit9:           DW &H0200

ClearRight:     DW &H00F0
ClearLeft:      DW &H000F

; ---------- I/O addresses ----------

Switches:       EQU &H000
LEDs:           EQU &H001
Hex0:           EQU &H004
Hex1:           EQU &H005

SW_CONTROL:     EQU &H070
SW_ELAPSED:     EQU &H071
SW_CAPTURED:    EQU &H072
SW_STATUS:      EQU &H073
