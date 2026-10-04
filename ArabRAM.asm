; This source targets sjasmplus (https://github.com/z00m128/sjasmplus)
; exclusively. Directives used throughout: DB (byte data), DW (word
; data), DM (text strings), ORG (set address), EQU (constant).


        INCLUDE "src/00_system_variables.asm"
        INCLUDE "src/01_restarts_and_tables.asm"
        INCLUDE "src/02_keyboard_routines.asm"
        INCLUDE "src/03_loudspeaker_routines.asm"
        INCLUDE "src/04_cassette_handling_routines.asm"
        INCLUDE "src/05_screen_and_printer_routines.asm"
        INCLUDE "src/06_executive_routines.asm"
        INCLUDE "src/07_basic_line_and_command_interpretation.asm"
        INCLUDE "src/08_expression_evaluation.asm"
        INCLUDE "src/09_arithmetic_routines.asm"
        INCLUDE "src/10_floating_point_calculator.asm"
        INCLUDE "src/11_arabic_glyph_font.asm"
        INCLUDE "src/12_zx_spectrum_char_set.asm"
; #end                            ; generic cross-assembler directive   ; (sjasmplus: END not required)

; Acknowledgements
; -----------------
; Sean Irvine               for default list of section headings
; Dr. Ian Logan             for labels and functional disassembly.
; Dr. Frank O'Hara          for labels and functional disassembly.
;
; Credits
; -------
; Alex Pallero Gonzales     for corrections.
; Mike Dailly               for comments.
; Alvin Albrecht            for comments.
; Andy Styles               for full relocatability implementation and testing.
; Andrew Owen               for ZASM compatibility and format improvements.

;   For other assemblers you may have to add directives like these near the
;   beginning - see accompanying documentation.
;   ZASM (MacOs) cross-assembler directives. (uncomment by removing ';' )
;   #target rom           ; declare target file format as binary.
;   #code   0,$4000       ; declare code segment.
;   Also see notes at Address Labels 0609 and 1CA5 if your assembler has
;   trouble with expressions.
;
;   Note. The Sinclair Interface 1 ROM written by Dr. Ian Logan and Martin
;   Brennan calls numerous routines in this ROM.
;   Non-standard entry points have a label beginning with X.


; ---------------------------------------------------------------------
; BUILD INSTRUCTIONS (sjasmplus, https://github.com/z00m128/sjasmplus)
; ---------------------------------------------------------------------
;   sjasmplus ArabRAM.asm --raw=ArabRAM_regenerated.ROM
;
; This produces a flat 16384-byte binary, verified byte-for-byte
; identical to the original ArabRAM patched ROM this file was reverse
; engineered from.
;
; (SAVEBIN was not used here because sjasmplus only allows it in "real
; device emulation mode" (DEVICE directive), which brings in ZX
; Spectrum memory-paging semantics this plain 16K ROM doesn't need.
; The --raw= command-line output achieves the same result more simply
; for a single flat ROM image like this one.)
;
; ---------------------------------------------------------------------

;************************************************************************
;** ARABRAM -- ANNOTATED PATCHED SOURCE                                 **
;** Saudi Arabian ("Arab Ram" / Autoram Computer, Jeddah) Arabic ROM     **
;** patch for the 48K ZX Spectrum, regenerated from a 16384-byte binary  **
;** diff against the standard Sinclair 48K ROM disassembly.              **
;**                                                                       **
;** This file reassembles byte-for-byte identical to the patched ROM     **
;** (verified with sjasmplus v1.24.0, github.com/z00m128/sjasmplus).      **
;**                                                                      **
;** SUMMARY OF WHAT CHANGED (see the boxed comments at each address for  **
;** full detail):                                                        **
;**   $0013/$0025/$002B/$005F  Small stub routines squeezed into unused  **
;**                            bytes between the fixed RST vectors; they **
;**                            reset keyboard-mode flags on entry to the **
;**                            editor and install a "channel output      **
;**                            vector swap" mini state-machine used for  **
;**                            special key handling.                     **
;**   $09F4-$0AD8   Rewritten PO-FETCH/character dispatcher, with THREE  **
;**                 brand-new control codes (0-5 now routed to $386E)    **
;**                 alongside a re-encoded version of the original       **
;**                 06-23d control-code jump table.                      **
;**   $0B66         Character-bitmap-address fetch is hooked to allow    **
;**                 per-key custom glyph substitution (see $145D).       **
;**   $0DF4         Column/cursor arithmetic changed from "33-C" to      **
;**                 "C-2" -- the likely mechanism behind right-to-left   **
;**                 text flow.                                           **
;**   $1391-$1554   Report/error-message printer rewritten to use a new  **
;**                 Arabic message table ($3923) instead of (or as well  **
;**                 as) the original English one; the space formerly     **
;**                 used by the English rpt-mesgs table now holds a      **
;**                 short data table of unclear purpose.                 **
;**   $145D (called from $0B66, lives in the $386E-$3CFF free-space      **
;**                 block) Glyph-substitution routine: for a specific    **
;**                 set of Latin keys, substitutes one of three custom   **
;**                 8x8 bitmaps instead of the standard font glyph --    **
;**                 almost certainly how Arabic letterforms are drawn,   **
;**                 with three tables plausibly corresponding to         **
;**                 different contextual letter shapes.                  **
;**   $18E8         Keyboard mode-indicator letter print now driven by   **
;**                 a small lookup table instead of inline comparisons,  **
;**                 consistent with one or more new mode letters.        **
;**   $386E-$3CFF   All new code/data, described block-by-block below.   **
;************************************************************************