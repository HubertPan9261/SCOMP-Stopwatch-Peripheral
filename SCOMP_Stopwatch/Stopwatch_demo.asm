; Stopwatch demonstration: clear the largest hex digit.
;
; Left four displays: captured time in hexadecimal milliseconds.
; Right two displays: game number.
;
; SW0 selects the right digit.
; SW1 selects the left digit.
; Raise only SW9 to start a round after lowering all switches.
;
; Active playing time accumulates across rounds.
; Hardware reset starts a new game.

ORG 0

Reset:
    LOADI  4
    OUT    SW_CONTROL        ; Clear stopwatch; leave stopped

    LOADI  0
    STORE  Value
    STORE  CapturedTime
    STORE  Candidate
    OUT    LEDs
    CALL   UpdateDisplay

; Stopwatch is paused throughout round setup.
WaitAllDown:
    IN     Switches
    OUT    LEDs
    JNZ    WaitAllDown

; Generate a changing eight-bit candidate.
; The player's start timing determines the chosen number.
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
    JZERO  WaitAllDown       ; Reject 00
    STORE  Value

    CALL   UpdateDisplay

    LOADI  3
    OUT    SW_CONTROL       ; Resume accumulated playing time

; Find the larger of the two remaining digits.
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

; Ignore switches other than SW0 and SW1 during play.
; If both selection switches are raised, wait for one selection.
CheckAnswer:
    CALL   CheckOverflow

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
    JZERO  WaitSelectionDown ; Ignore an already-cleared digit
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
    LOADI  5
    OUT    SW_CONTROL       ; Capture without stopping

    IN     SW_CAPTURED
    STORE  CapturedTime

    LOAD   Value
    AND    ClearMask
    STORE  Value
    JZERO  RoundComplete

    CALL   UpdateDisplay

; Require both selection switches to be lowered before
; accepting another selection. Timing continues here.
WaitSelectionDown:
    CALL   CheckOverflow

    IN     Switches
    OUT    LEDs
    AND    SelectionMask
    JNZ    WaitSelectionDown

    JUMP   FindLargest

RoundComplete:
    LOADI  2
    OUT    SW_CONTROL       ; Exclude between-round waiting time

    LOADI  5
    OUT    SW_CONTROL       ; Capture the final paused reading

    IN     SW_CAPTURED
    STORE  CapturedTime

    CALL   UpdateDisplay

    CALL   CheckOverflow
    JUMP   WaitAllDown

; Wrong answer or overflow ends the game.
; Preserve the remaining number and final elapsed time.
GameOver:
    LOADI  2
    OUT    SW_CONTROL

    LOADI  5
    OUT    SW_CONTROL

    IN     SW_CAPTURED
    STORE  CapturedTime

    CALL   UpdateDisplay

GameOverLoop:
    IN     Switches
    OUT    LEDs
    JUMP   GameOverLoop

; ---------- Subroutines ----------

; Check status bit 2 rather than interpreting elapsed time
; as a signed number.
CheckOverflow:
    IN     SW_STATUS
    AND    OverflowMask
    JNZ    GameOver
    RETURN

; Physical display arrangement:
;
; HEX5 HEX4 HEX3 HEX2 | HEX1 HEX0
;    CapturedTime    |   Value
;
; Address 5 controls HEX5-HEX4.
; Address 4 controls HEX3-HEX0.
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

; ---------- Masks ----------

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
