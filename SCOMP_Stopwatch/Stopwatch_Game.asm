; ECE 2031 - Lab 8
; Knock out the largest hex digit.
; SW3 selects the leftmost digit; SW0 selects the rightmost.

ORG 0

Reset:
    LOADI  0
    STORE  Score
    STORE  Value
    OUT    Hex1
    OUT    Hex0
    OUT    Timer         ; Reset timer once per game

; Wait for all switches to be lowered before a round.
WaitAllDown:
    CALL   CheckTime

    IN     Switches
    OUT    LEDs
    JNZ    WaitAllDown

; Increment rapidly until only SW9 is raised.
Counting:
    CALL   CheckTime

    LOAD   Value
    ADDI   1
    STORE  Value

    IN     Switches
    OUT    LEDs
    JZERO  Counting

    SUB    Bit9
    JZERO  StartRound
    JUMP   WaitAllDown

StartRound:
    LOAD   Value
    OUT    Hex0
    JZERO  WaitAllDown   ; Nothing to knock out if already 0000

; Extract all four nibbles and find the largest.
FindLargest:
    LOAD   Value
    AND    Mask
    STORE  Nibble1

    LOAD   Value
    SHIFT  -4
    AND    Mask
    STORE  Nibble2

    LOAD   Value
    SHIFT  -8
    AND    Mask
    STORE  Nibble3

    LOAD   Value
    SHIFT  -12
    AND    Mask
    STORE  Nibble4

    LOAD   Nibble1
    STORE  Largest

    LOAD   Nibble2
    SUB    Largest
    JPOS   UseNibble2
    JUMP   CheckNibble3

UseNibble2:
    LOAD   Nibble2
    STORE  Largest

CheckNibble3:
    LOAD   Nibble3
    SUB    Largest
    JPOS   UseNibble3
    JUMP   CheckNibble4

UseNibble3:
    LOAD   Nibble3
    STORE  Largest

CheckNibble4:
    LOAD   Nibble4
    SUB    Largest
    JPOS   UseNibble4
    JUMP   CheckAnswer

UseNibble4:
    LOAD   Nibble4
    STORE  Largest

; Read the player's selection.
CheckAnswer:
    CALL   CheckTime

    IN     Switches
    OUT    LEDs
    STORE  Pattern

CheckSW0:
    LOAD   Pattern
    AND    Bit0
    JNZ    Selected0

CheckSW1:
    LOAD   Pattern
    AND    Bit1
    JNZ    Selected1

CheckSW2:
    LOAD   Pattern
    AND    Bit2
    JNZ    Selected2

CheckSW3:
    LOAD   Pattern
    AND    Bit3
    JNZ    Selected3

    JUMP   CheckAnswer

; Extract the selected digit and choose its clearing mask.
; Ignore switches corresponding to zero digits.
Selected0:
    LOAD   Value
    AND    Mask
    JZERO  CheckSW1
    STORE  SelectedDigit

    LOAD   Clear0
    STORE  ClearMask
    JUMP   CompareDigit

Selected1:
    LOAD   Value
    SHIFT  -4
    AND    Mask
    JZERO  CheckSW2
    STORE  SelectedDigit

    LOAD   Clear1
    STORE  ClearMask
    JUMP   CompareDigit

Selected2:
    LOAD   Value
    SHIFT  -8
    AND    Mask
    JZERO  CheckSW3
    STORE  SelectedDigit

    LOAD   Clear2
    STORE  ClearMask
    JUMP   CompareDigit

Selected3:
    LOAD   Value
    SHIFT  -12
    AND    Mask
    JZERO  CheckAnswer
    STORE  SelectedDigit

    LOAD   Clear3
    STORE  ClearMask
    JUMP   CompareDigit

; Comparing values allows any tied largest digit to count.
CompareDigit:
    LOAD   SelectedDigit
    SUB    Largest
    JNZ    GameOver

CorrectAnswer:
    ; Zero only the selected nibble.
    LOAD   Value
    AND    ClearMask
    STORE  Value

    ; Add one point and update score display.
    LOAD   Score
    ADDI   1
    STORE  Score
    OUT    Hex1

    ; Update number display.
    LOAD   Value
    OUT    Hex0
    JZERO  WaitAllDown
    JUMP   FindLargest

; Keep the final score and number displayed until reset.
GameOver:
    IN     Switches
    OUT    LEDs
    JUMP   GameOver

; ---------- Subroutines ----------

CheckTime:
    IN     Timer
    ADDI   -100
    JNEG   TimeRemaining
    JUMP   GameOver

TimeRemaining:
    RETURN

; ---------- Variables ----------

Score:         DW 0
Value:         DW 0
Largest:       DW 0
Pattern:       DW 0
SelectedDigit: DW 0
ClearMask:     DW 0

Nibble1:       DW 0
Nibble2:       DW 0
Nibble3:       DW 0
Nibble4:       DW 0

; ---------- Masks ----------

Mask:   DW &H000F

Bit0:   DW &H0001
Bit1:   DW &H0002
Bit2:   DW &H0004
Bit3:   DW &H0008
Bit9:   DW &H0200

Clear0: DW &HFFF0
Clear1: DW &HFF0F
Clear2: DW &HF0FF
Clear3: DW &H0FFF

; ---------- I/O addresses ----------

Switches: EQU 0
LEDs:     EQU 1
Timer:    EQU 2
Hex0:     EQU 4
Hex1:     EQU 5
