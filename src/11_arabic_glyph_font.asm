;==========================================================================
; ARABRAM ADDITIONS IN FORMERLY-UNUSED ROM SPACE -- $386E-$3CFF
;==========================================================================
;   REWRITTEN with corrections verified on real hardware (tape capture of
;   the ROM, SCREEN$ and BASIC program, plus an emulator snapshot). The
;   assembled bytes of this file are IDENTICAL to the original; only
;   comments, annotations and a few internal label names changed.
;   Label names referenced from files 01-10 were NOT renamed.
;
;   This whole region was $FF filler in the original 48K ROM.
;
;   MAP
;   $386E-$3894  ARAB_NEW_CTRL_HANDLER (control codes 0-5) and two tiny
;                helpers (L387B, ARAB_MODE_TOGGLE)
;   $3895-$3922  ARAB_ED_KEY_EXT (editor key front end), the key-decode
;                wrapper L38DA, the key-delivery wrapper L38F3, and
;                ARAB_GLYPH_GUARD ($3917)
;   $3923-$39EF  Arabic report-message table (28 messages)
;   $39F0-$3A3F  DIGIT FONT: Arabic-Indic digits, glyph = $3870 + 8*code
;   $3A40-$3A6B  CHARACTER FLAG TABLE for codes $40-$6B (lookup $3A00+code)
;   $3A6C-$3BC3  ISOLATED-FORM FONT: glyph = $3864 + 8*code for codes
;                $41-$6B ('A'..'k'); slots for codes $5B-$60 are not
;                letters and hold CODE (two print hooks, $3B3C-$3B6B)
;   $3BC4-$3CF5  three contextual glyph tables (final / medial / initial)
;   $3CF6-$3CFF  ARAB_PRINT_EXTRA_MSG (prints the Arabic boot title logo)
;
;   HOW ARABIC IS PRINTED
;   Keys produce plain ASCII codes internally. PO-CHAR ($0B65, hooked at
;   $0B66) calls ARAB_GLYPH_SUBSTITUTE ($145D, file 06) which returns, in
;   BC, a font base so that the normal "BC + 8*code" glyph fetch picks an
;   Arabic bitmap instead of the Latin one. Everything printed (PRINT,
;   LIST, editor, reports, keyword tokens) goes through it. Text prints
;   RIGHT-TO-LEFT. Bit 4 of (IY+1) set = substitution OFF (Latin).
;
;   BASE ADDRESSES RETURNED IN BC
;     digits  '0'-'9'            BC=$3870  -> $39F0-$3A3F
;     isolated letters           BC=$3864  -> $3A6C-$3BC3 (also fallback)
;     joined forms               BC=address of the 8 bitmap bytes inside
;                                one of the three tables below
;     not alphabetic / >= $6C    BC=(CHARS) normal Latin font
;
;   KEY CODE -> ARABIC LETTER (corrected; the old comments used a wrong
;   transliteration table, confirmed wrong by the keyword and message tables
;   decoding to real Arabic words only with this map)
;     G ا  H ب  I ة  J ت  K ث  L ج  M ح  N خ  O د  P ذ  Q ر  R ز
;     S س  T ش  U ص  V ض  W ط  X ظ  Y ع  Z غ
;     A ء  B لا  C أ  D ؤ  E إ  F ئ
;     a ف  b ق  c ك  d ل  e م  f ن  g ه  h و  i ي  j ى  k ال
;   Examples: keyword table decodes REM=BMX=لاحظ, FOR=BLd=لاجل, NOT=B=لا.
;
;   PHYSICAL KEYS (ARAB_KEY_LOOKUP_TABLE, file 06): the key pressed is
;   mapped to the code above, e.g. lowercase g->G alif, h->J ta, c->H ba,
;   d->i ya, f->d lam, b->h waw, r->a fa, u->g heh, x->W tah, z->X zah,
;   y->Y ain, t->Z ghain, v->Q ra, w->U sad, q->V dad, s->S sin, a->T shin,
;   i->N kha, o->M hah, p->L jim, l->c kaf, k->e mim, j->f nun, m->O dal,
;   n->P dhal, e->b qaf; uppercase D->A hamza, G->C, H->I, K->B lam-alef,
;   F->k al-, N->R zay, S->F, V->E, W->K tha, X->j, E->"]" (not a letter).
;   Other unmapped keys give "?".
;
;   CONTEXTUAL SHAPING (ARAB_GLYPH_SUBSTITUTE, L1510)
;   TV_FLAG $5C3C = (IY+2) context bits:
;     bit 7  the letter being printed joins the NEXT letter
;     bit 2  it does NOT join the next letter
;     bit 1  the PREVIOUS letter joined into this one
;   L1510 is called with A=letter, B=LOOKAHEAD character and sets bits 7/2.
;   Form selected:   bit2 bit1
;                     0    0    INITIAL  -> Table 3  ($3C42)
;                     0    1    MEDIAL   -> Table 2  ($3BFA)
;                     1    0    ISOLATED -> $3864 font
;                     1    1    FINAL    -> Table 1  ($3BC4)
;   A missing form falls back: medial -> initial -> isolated; final ->
;   isolated. Per-letter availability is in the FLAG TABLE:
;     bit 7 set   letter can join forward (needs a following letter)
;     bit 6 set   no INITIAL form        bit 5 set  no MEDIAL form
;     bit 4 clear a FINAL form exists (Table 1 entry)
;   (verified: every flag byte agrees with which tables hold that letter.)
;
;   CONTROL CODES 0-5
;     CHR$ 0-3  FORM OVERRIDE for the NEXT printed character (that character
;               is still printed): 0=initial, 1=medial, 2=isolated, 3=final.
;               Mechanism: $01FE (ADD A,A; LD DE,$154C; JP $0A7B) stores
;               2*code in TVDATA ($5C0E) and installs one-shot handler
;               $154C, which clears TV_FLAG bits 2/1, restores normal
;               output and JPs L387B to OR TVDATA into TV_FLAG.
;     CHR$ 4    Arabic ON : RES 4,(IY+1) and clear context bits 2/1 ($1391)
;     CHR$ 5    Latin  ON : SET 4,(IY+1)
;               The pair CHR$ 5 ... CHR$ 4 brackets a Latin run inside
;               Arabic text. Codes 4/5 occupy no screen cell.
;   The previous letter never joins forward into a control byte (it is
;   not alphabetic), so a form override only affects the letter after it.
;
;   EDITOR KEYS (rewritten key loop, ARAB_ED_KEY_EXT)
;     Symbol Shift+SPACE  inserts CHR$ 0, and while the cursor is on a
;                         CHR$ 0-3 byte each further press cycles it
;                         0->1->2->3->0 (so 1,2,3 presses give 0,1,2).
;     Symbol Shift+ENTER  Arabic keyboard: inserts the pair CHR$ 5,CHR$ 4
;                         with the cursor BETWEEN them (type a Latin run);
;                         Latin keyboard: jumps the cursor past the next
;                         CHR$ 4 (or to end of line) to resume Arabic.
;   The keyboard map follows TV_FLAG bit 6 (set = Latin map), refreshed
;   from (IY+1) bit 4 by ARAB_MODE_TOGGLE on every cursor redraw.
;
;   KNOWN QUIRKS / OPEN ITEMS
;   * $3B57 lookahead reads the byte AFTER the string when the last
;     character is printed (see ARAB_PR_STRING_HOOK), so the final letter
;     of a string variable can join forward if an alphabetic byte follows
;     it in memory. Confirmed on hardware. Left as shipped.
;   * Report 11 text decodes literally to "صحيح ك" (looks abbreviated).
;     Reports 1 and 18 share the same text.
;==========================================================================
ARAB_NEW_CTRL_HANDLER:
        CP      4                       ; control codes 0-5 arrive here from ARAB_PO_FETCH_EXT
        JP      C,ARAB_FORM_OVERRIDE_ENTRY ; codes 0-3: FORM OVERRIDE (ADD A,A; LD DE,ARAB_FORM_OVERRIDE_OUT; JP L0A7B)
        JP      Z,L1391                 ; code 4: Arabic ON ($1391: RES 4,(IY+1) then clear context bits 2,1)
        SET     4,(IY+1)                ; code 5: Latin ON (substitution off)
        RET                             ; return
L387B:
        LD      HL,TV_FLAG                ; (name kept, used by file 06) one-shot handler tail: HL = TV_FLAG
        PUSH    AF                      ; save the character about to be printed
        LD      A,(TVDATA)               ; A = TVDATA low = 2*override code (0,2,4,6)
        OR      (HL)                    ; merge into TV_FLAG: bit1 = code&1, bit2 = code>>1
        LD      (HL),A                  ; (bits 2/1 were cleared by $154C first)
        POP     AF                      ; restore the character
        JP      ARAB_PO_FETCH_EXT       ; print it with the forced form
ARAB_MODE_TOGGLE:
        LD      HL,TV_FLAG    ; refresh TV_FLAG bit 6 (keyboard map) from substitution state
        SET     6,(HL)                  ; assume Latin keyboard
        BIT     4,(IY+1)                ; substitution off (Latin)?
        RET     NZ                      ; yes: keep bit 6 set
        RES     6,(HL)                  ; no: Arabic keyboard, clear bit 6
        RET                             ; return
ARAB_ED_KEY_EXT:
        CALL    WAIT_KEY      ; (name kept) editor key loop: wait for a key
        PUSH    AF                      ; keep key code
        LD      E,(IY-1)                ; key-click pitch
        LD      HL,$C8                  ; click duration
        LD      D,H                     ; D = 0
        CALL    BEEPER                  ; click exactly as the original editor did
        POP     AF                      ; key code
        LD      HL,L0F38                ; return address = loop again
        PUSH    HL                      ; so every handler RETurns into the loop
        LD      HL,(K_CUR)              ; HL = K_CUR (byte right of the cursor)
        CP      5                       ; key code 5 = Symbol Shift+ENTER on the Arabic keyboard
        JR      NZ,ED_KEY_4_CHECK       ; not 5
        CALL    ADD_CHAR                ; insert CHR$ 5, cursor advances past it
        DEC     A                       ; A = 4
        JP      L0F41                   ; insert CHR$ 4 to the RIGHT of the cursor (K_CUR unchanged): pair 5..4
ED_KEY_4_CHECK:
        CP      4              ; key code 4 = Symbol Shift+ENTER on the Latin keyboard
        JR      NZ,ED_KEY_0_CHECK       ; not 4
ED_SCAN_FWD:
        LD      A,(HL)            ; scan forward from the cursor
        CP      4                       ; found the closing CHR$ 4?
        JP      Z,L1010                 ; yes: INC HL and set K_CUR (cursor moves just past it)
        CP      13                      ; end of line?
        JP      Z,ED_CUR                ; yes: cursor to the ENTER
        INC     HL                      ; next byte
        JR      ED_SCAN_FWD             ; keep scanning
ED_KEY_0_CHECK:
        OR      A              ; key code 0 = Symbol Shift+SPACE
        JP      NZ,L253C                ; any other key: relocated original key dispatch (file 08)
        LD      A,(HL)                  ; byte right of the cursor
        CP      4                       ; already a CHR$ 0-3?
        JR      NC,ED_INSERT_CODE0      ; no: insert a new CHR$ 0
        INC     A                       ; yes: cycle it 0->1->2->3->0
        AND     3                       ; modulo 4
        LD      (HL),A                  ; store back
        RET                             ; return to the loop
ED_INSERT_CODE0:
        XOR     A             ; A = 0
        JP      L0F41                   ; insert CHR$ 0 right of the cursor (K_CUR unchanged, so the next press cycles it)
L38DA:
        RES     4,(IY+$37)              ; (name kept, called from file 02) key decode wrapper: clear marker bit (FLAGX bit 4)
        CALL    K_DECODE                ; normal key decode
        CP      $20                     ; SPACE?
        JR      Z,KEYDEC_CHECK_SHIFT    ; yes
        CP      13                      ; ENTER?
        RET     NZ                      ; neither: done
KEYDEC_CHECK_SHIFT:
        LD      C,A        ; keep code
        LD      A,$18                   ; $18 = Symbol Shift key value
        CP      B                       ; was Symbol Shift the second key?
        LD      A,C                     ; restore code
        RET     NZ                      ; no
        SET     4,(IY+$37)              ; yes: mark "Symbol Shift + SPACE/ENTER"
        RET                             ; return
L38F3:
        BIT     4,(IY+$37)              ; (name kept, jumped to from file 05) deliver the key
        JR      Z,KEYMAP_PLAIN          ; not marked
        CP      13                      ; marked ENTER?
        JR      NZ,KEYMAP_SPACE         ; no
        LD      A,4                     ; Latin keyboard (TV_FLAG bit 6 set): code 4
        BIT     6,(IY+2)                ;
        JR      NZ,KEYMAP_DONE          ;
        INC     A                       ; Arabic keyboard: code 5
        JR      KEYMAP_DONE             ;
KEYMAP_SPACE:
        CP      $20              ; marked SPACE?
        JR      NZ,KEYMAP_PLAIN         ; no
        XOR     A                       ; Symbol Shift+SPACE = key code 0
        JR      KEYMAP_DONE             ;
KEYMAP_PLAIN:
        CP      $20              ; ordinary key
        JP      C,L10C8                 ; control code: original handling
KEYMAP_DONE:
        JP      KEY_DONE2         ; deliver the key
ARAB_GLYPH_GUARD:
        CALL    NUMERIC      ; (name kept) carry CLEAR = digit
        JP      C,ALPHA                 ; not a digit: carry set only if a letter
        LD      BC,ARAB_DIGIT_FONT-8*$30 ; digit: font base for the DIGIT FONT (ARAB_DIGIT_FONT = glyph of '0')
        INC     SP                      ; drop our return address ...
        INC     SP                      ;
        RET                             ; ... and return straight out of ARAB_GLYPH_SUBSTITUTE
;
; ---- Arabic report messages ($3923): 28 messages in report-code order, each
; ---- ending in a character with bit 7 set. Text uses the key codes above.
ARAB_MSG_TABLE_AR:
        DB          $80              ; start marker
; report 0  OK  =>  جيد
        DM          "Li"
        DB          'O'+$80
; report 1  NEXT without FOR  =>  لا لاجل
        DM          "B BL"
        DB          'd'+$80
; report 2  Variable not found  =>  لا متغير
        DM          "B eJZi"
        DB          'Q'+$80
; report 3  Subscript wrong  =>  صفة خطأ
        DM          "UaI NW"
        DB          'C'+$80
; report 4  Out of memory  =>  لا ذاكرة
        DM          "B PGcQ"
        DB          'I'+$80
; report 5  Out of screen  =>  لا شاشة
        DM          "B TGT"
        DB          'I'+$80
; report 6  Number too big  =>  رقم كبير
        DM          "Qbe cHi"
        DB          'Q'+$80
; report 7  RETURN without GOSUB  =>  لا اذهب
        DM          "B GPg"
        DB          'H'+$80
; report 8  End of file  =>  نهاية ملف
        DM          "fgGiI ed"
        DB          'a'+$80
; report 9  STOP statement  =>  قف
        DM          "b"
        DB          'a'+$80
; report 10  Invalid argument  =>  لا جدال
        DM          "B LOG"
        DB          'd'+$80
; report 11  Integer out of range  =>  صحيح ك
        DM          "UMiM "
        DB          'c'+$80
; report 12  Nonsense in BASIC  =>  لا معنى
        DM          "B eYf"
        DB          'j'+$80
; report 13  BREAK - CONT repeats  =>  مقطع
        DM          "ebW"
        DB          'Y'+$80
; report 14  Out of DATA  =>  من افادة
        DM          "ef GaGO"
        DB          'I'+$80
; report 15  Invalid file name  =>  لا اسم ملف
        DM          "B GSe ed"
        DB          'a'+$80
; report 16  No room for line  =>  لا فرغ لسطر
        DM          "B aQZ dSW"
        DB          'Q'+$80
; report 17  STOP in INPUT  =>  قف
        DM          "b"
        DB          'a'+$80
; report 18  FOR without NEXT  =>  لا لاجل
        DM          "B BL"
        DB          'd'+$80
; report 19  Invalid I/O device  =>  لا ادخال/اخراج
        DM          "B GONGd/GNQG"
        DB          'L'+$80
; report 20  Invalid colour  =>  لا لون
        DM          "B dh"
        DB          'f'+$80
; report 21  BREAK into program  =>  اقطع
        DM          "GbW"
        DB          'Y'+$80
; report 22  RAMTOP no good  =>  رام بوب غير جيد
        DM          "QGe HhH ZiQ Li"
        DB          'O'+$80
; report 23  Statement lost  =>  ضياع امر
        DM          "ViGY Ge"
        DB          'Q'+$80
; report 24  Invalid stream  =>  لا اتصال
        DM          "B GJUG"
        DB          'd'+$80
; report 25  FN without DEF  =>  لا مثل معرفة
        DM          "B eKd eYQa"
        DB          'I'+$80
; report 26  Parameter error  =>  خطأ مقدار
        DM          "NWC ebOG"
        DB          'Q'+$80
; report 27  Tape loading error  =>  خطأ تعبئة
        DM          "NWC JYHF"
        DB          'I'+$80
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF
        DB          $FF              ; padding to $39EF

; ---- DIGIT FONT ($39F0-$3A3F): Arabic-Indic digits. Glyph address = $3870 + 8*code
ARAB_DIGIT_FONT:

; '0' ٠
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00011000
        DB          %00011000
        DB          %00000000
        DB          %00000000
        DB          %00000000

; '1' ١
        DB          %00000000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00001000
        DB          %00000000

; '2' ٢
        DB          %00000000
        DB          %00011100
        DB          %00100000
        DB          %00100000
        DB          %00010000
        DB          %00001000
        DB          %00000100
        DB          %00000000

; '3' ٣
        DB          %00000000
        DB          %01101010
        DB          %01101010
        DB          %01010100
        DB          %01000000
        DB          %01000000
        DB          %01000000
        DB          %00000000

; '4' ٤
        DB          %00000000
        DB          %00011000
        DB          %00100000
        DB          %00010000
        DB          %00001000
        DB          %00010000
        DB          %00001100
        DB          %00000000

; '5' ٥
        DB          %00000000
        DB          %00011000
        DB          %00100100
        DB          %01000010
        DB          %01000010
        DB          %01000010
        DB          %00111100
        DB          %00000000

; '6' ٦
        DB          %00000000
        DB          %00111100
        DB          %00000100
        DB          %00000100
        DB          %00000100
        DB          %00000100
        DB          %00000100
        DB          %00000000

; '7' ٧
        DB          %00000000
        DB          %01000001
        DB          %00100010
        DB          %00100010
        DB          %00010100
        DB          %00010100
        DB          %00001000
        DB          %00000000

; '8' ٨
        DB          %00000000
        DB          %00001000
        DB          %00010100
        DB          %00010100
        DB          %00100010
        DB          %00100010
        DB          %01000001
        DB          %00000000

; '9' ٩
        DB          %00000000
        DB          %00011000
        DB          %00100100
        DB          %00011100
        DB          %00000100
        DB          %00000100
        DB          %00000100
        DB          %00000000

; ---- CHARACTER FLAG TABLE ($3A40-$3A6B), one byte per code $40-$6B (lookup = $3A00+code)
;      bit7 joins forward | bit6 no initial | bit5 no medial | bit4 clear = has final form
ARAB_GLYPH_FLAG_TABLE:
ARAB_GLYPH_FLAG_LOOKUP_BASE EQU ARAB_GLYPH_FLAG_TABLE - $40
        DB          $FF; '@' (not a letter, unused): joins fwd; forms: isolated
        DB          $FF; 'A' ء hamza: joins fwd; forms: isolated
        DB          $7F; 'B' لا lam-alef: no fwd join; forms: isolated
        DB          $7F; 'C' أ alef+hamza above: no fwd join; forms: isolated
        DB          $7F; 'D' ؤ waw+hamza: no fwd join; forms: isolated
        DB          $7F; 'E' إ alef+hamza below: no fwd join; forms: isolated
        DB          $FF; 'F' ئ ya+hamza: joins fwd; forms: isolated
        DB          $6F; 'G' ا alif: no fwd join; forms: isolated, final
        DB          $9F; 'H' ب ba: joins fwd; forms: isolated, initial, medial
        DB          $7F; 'I' ة ta marbuta: no fwd join; forms: isolated
        DB          $9F; 'J' ت ta: joins fwd; forms: isolated, initial, medial
        DB          $9F; 'K' ث tha: joins fwd; forms: isolated, initial, medial
        DB          $BF; 'L' ج jim: joins fwd; forms: isolated, initial
        DB          $BF; 'M' ح hah: joins fwd; forms: isolated, initial
        DB          $BF; 'N' خ kha: joins fwd; forms: isolated, initial
        DB          $7F; 'O' د dal: no fwd join; forms: isolated
        DB          $7F; 'P' ذ dhal: no fwd join; forms: isolated
        DB          $7F; 'Q' ر ra: no fwd join; forms: isolated
        DB          $7F; 'R' ز zay: no fwd join; forms: isolated
        DB          $BF; 'S' س sin: joins fwd; forms: isolated, initial
        DB          $BF; 'T' ش shin: joins fwd; forms: isolated, initial
        DB          $BF; 'U' ص sad: joins fwd; forms: isolated, initial
        DB          $BF; 'V' ض dad: joins fwd; forms: isolated, initial
        DB          $FF; 'W' ط tah: joins fwd; forms: isolated
        DB          $FF; 'X' ظ zah: joins fwd; forms: isolated
        DB          $8F; 'Y' ع ain: joins fwd; forms: isolated, initial, medial, final
        DB          $8F; 'Z' غ ghain: joins fwd; forms: isolated, initial, medial, final
        DB          $7F; '[' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F; '\' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F; ']' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F; '^' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F; '_' (not a letter, unused): no fwd join; forms: isolated
        DB          $7F; '`' (not a letter, unused): no fwd join; forms: isolated
        DB          $BF; 'a' ف fa: joins fwd; forms: isolated, initial
        DB          $BF; 'b' ق qaf: joins fwd; forms: isolated, initial
        DB          $BF; 'c' ك kaf: joins fwd; forms: isolated, initial
        DB          $BF; 'd' ل lam: joins fwd; forms: isolated, initial
        DB          $BF; 'e' م mim: joins fwd; forms: isolated, initial
        DB          $9F; 'f' ن nun: joins fwd; forms: isolated, initial, medial
        DB          $8F; 'g' ه heh: joins fwd; forms: isolated, initial, medial, final
        DB          $7F; 'h' و waw: no fwd join; forms: isolated
        DB          $8F; 'i' ي ya: joins fwd; forms: isolated, initial, medial, final
        DB          $6F; 'j' ى alef maqsura: no fwd join; forms: isolated, final
        DB          $FF; 'k' ال definite article al-: joins fwd; forms: isolated

; ---- ISOLATED-FORM FONT ($3A6C-$3BC3): glyph = $3864 + 8*code, codes $41-$6B.
; ---- (also the fallback glyph when a joined form does not exist)
ARAB_ISOLATED_FONT:

; 'A' ء hamza
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00001110
        DB          %00011100
        DB          %00000000
        DB          %00000000

; 'B' لا lam-alef
        DB          %00000000
        DB          %00100010
        DB          %00010010
        DB          %00001010
        DB          %00000110
        DB          %00001100
        DB          %00000000
        DB          %00000000

; 'C' أ alef+hamza above
        DB          %00000000
        DB          %00011010
        DB          %00110010
        DB          %00000010
        DB          %00000010
        DB          %00000001
        DB          %00000000
        DB          %00000000

; 'D' ؤ waw+hamza
        DB          %00000000
        DB          %00001100
        DB          %00011000
        DB          %00000010
        DB          %00000101
        DB          %00000011
        DB          %00000001
        DB          %00001110

; 'E' إ alef+hamza below
        DB          %00000000
        DB          %00000010
        DB          %00000010
        DB          %00000010
        DB          %00000010
        DB          %00000001
        DB          %00001100
        DB          %00011000

; 'F' ئ ya+hamza
        DB          %00000000
        DB          %00000000
        DB          %00011000
        DB          %00110001
        DB          %00000001
        DB          %11111110
        DB          %00000000
        DB          %00000000

; 'G' ا alif
        DB          %00000000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00010000
        DB          %00000000
        DB          %00000000

; 'H' ب ba
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %01000001
        DB          %01000001
        DB          %00111110
        DB          %00000000
        DB          %00001000

; 'I' ة ta marbuta
        DB          %00000000
        DB          %00010100
        DB          %00000000
        DB          %00001100
        DB          %00010100
        DB          %00001011
        DB          %00000000
        DB          %00000000

; 'J' ت ta
        DB          %00000000
        DB          %00000000
        DB          %00010100
        DB          %01000001
        DB          %01000001
        DB          %00111110
        DB          %00000000
        DB          %00000000

; 'K' ث tha
        DB          %00000000
        DB          %00001000
        DB          %00010100
        DB          %01000001
        DB          %01000001
        DB          %00111110
        DB          %00000000
        DB          %00000000

; 'L' ج jim
        DB          %00000000
        DB          %00011100
        DB          %00100011
        DB          %00001110
        DB          %00110000
        DB          %01000100
        DB          %01000000
        DB          %00111110

; 'M' ح hah
        DB          %00000000
        DB          %00001100
        DB          %00010011
        DB          %00000100
        DB          %00011010
        DB          %00100001
        DB          %00100000
        DB          %00011100

; 'N' خ kha
        DB          %00000000
        DB          %01001100
        DB          %00010011
        DB          %00000100
        DB          %00011010
        DB          %00100001
        DB          %00100000
        DB          %00011100

; 'O' د dal
        DB          %00000000
        DB          %00000000
        DB          %00000010
        DB          %00000001
        DB          %00000001
        DB          %00001110
        DB          %00000000
        DB          %00000000

; 'P' ذ dhal
        DB          %00000010
        DB          %00000000
        DB          %00000010
        DB          %00000001
        DB          %00000001
        DB          %00001110
        DB          %00000000
        DB          %00000000

; 'Q' ر ra
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000001
        DB          %00000001
        DB          %00000010
        DB          %00001100

; 'R' ز zay
        DB          %00000000
        DB          %00000000
        DB          %00000100
        DB          %00000000
        DB          %00000001
        DB          %00000001
        DB          %00000010
        DB          %00001100

; 'S' س sin
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00010101
        DB          %00011111
        DB          %10010000
        DB          %10010000
        DB          %11110000

; 'T' ش shin
        DB          %00000100
        DB          %00001010
        DB          %00000000
        DB          %00010101
        DB          %00011111
        DB          %10010000
        DB          %10010000
        DB          %11110000

; 'U' ص sad
        DB          %00000000
        DB          %00000000
        DB          %00000110
        DB          %00001001
        DB          %00011110
        DB          %01010000
        DB          %01010000
        DB          %01110000

; 'V' ض dad
        DB          %00000000
        DB          %00010000
        DB          %00000110
        DB          %00001001
        DB          %00011110
        DB          %01010000
        DB          %01010000
        DB          %01110000

; 'W' ط tah
        DB          %00000000
        DB          %00010000
        DB          %00010000
        DB          %00010110
        DB          %00011001
        DB          %11111111
        DB          %00000000
        DB          %00000000

; 'X' ظ zah
        DB          %00000000
        DB          %00010100
        DB          %00010000
        DB          %00010110
        DB          %00011001
        DB          %11111111
        DB          %00000000
        DB          %00000000

; 'Y' ع ain
        DB          %00000000
        DB          %00000000
        DB          %00011000
        DB          %00100000
        DB          %00011100
        DB          %00100000
        DB          %00100000
        DB          %00011110

; 'Z' غ ghain
        DB          %00000000
        DB          %00010000
        DB          %00000110
        DB          %00001000
        DB          %00011100
        DB          %00100000
        DB          %00100000
        DB          %00011110

; ---- slots for codes $5B-$60 ('[' '\' ']' '^' '_' '`') are never letters:
; ---- they hold the two print hooks below ($3B3C-$3B6B, 48 bytes).
ARAB_PO_MSG_HOOK:
        ; $3B3C: JP from $0C22 (PO-MSG/PO-TOKENS loop). A=char (bit 7 = last char of the message), HL -> next char, Z flag from BIT 7,A
        JR      NZ,ARAB_PO_MSG_LAST     ; last character of the message
        LD      B,(HL)                  ; B = LOOKAHEAD = the next character
        RES     7,B                     ; strip the end-of-message bit
        CALL    L1510                   ; set context bits 7/2 from A and the lookahead B
        CALL    PO_SAVE                 ; print A
        JP      L0C23                   ; continue the loop
ARAB_PO_MSG_LAST:
        RES     7,A          ; last char: clear bit 7
        LD      B,$20                   ; lookahead = space (nothing follows)
        CALL    L1510                   ; context bits
        CALL    PO_SAVE                 ; print
        JP      L0C2A                   ; leave the loop
ARAB_PR_STRING_HOOK:
        ; $3B57: JP from $203C (PRINT of a string). A=current char, BC=chars remaining AFTER it, HL=current address
        INC     HL                      ; HL -> next character
        PUSH    BC                      ; save the count
        DEC     B                       ; (see QUIRK) does not alter carry
        JR      NC,ARAB_PR_NEXT         ; ALWAYS taken: carry is clear from the OR C at $203E
        DEC     C                       ; never executed ...
        LD      B,$20                   ; ... intended fallback: lookahead = space at end of string
        JR      NC,ARAB_PR_CTX          ; ... (never executed)
ARAB_PR_NEXT:
        LD      B,(HL)           ; B = byte after the current character, EVEN PAST THE END OF THE STRING
ARAB_PR_CTX:
        CALL    L1510             ; context bits
        RST     $10                     ; print A
        POP     BC                      ; restore the count
        JP      L203D                   ; next iteration of PR-STRING
        DB          $FF, $FF             ; spare. QUIRK FIX (optional, untested, same size): replace the 21 bytes at
                                         ; ARAB_PR_STRING_HOOK with 23 C5 04 05 20 02 0C 0D 46 20 02 06 20 CD 10 15
                                         ; D7 C1 C3 3D 20 (tests BC=0 without touching A; lookahead = $20 at the end)

; 'a' ف fa
        DB          %00000000
        DB          %00001000
        DB          %00000011
        DB          %00000011
        DB          %10000001
        DB          %01111110
        DB          %00000000
        DB          %00000000

; 'b' ق qaf
        DB          %00000000
        DB          %00101000
        DB          %00000010
        DB          %00000101
        DB          %10000111
        DB          %10000001
        DB          %01111110
        DB          %00000000

; 'c' ك kaf
        DB          %00000000
        DB          %00001101
        DB          %00001001
        DB          %00011101
        DB          %01000001
        DB          %00111110
        DB          %00000000
        DB          %00000000

; 'd' ل lam
        DB          %00000000
        DB          %00000001
        DB          %00000001
        DB          %00000001
        DB          %00000001
        DB          %00100001
        DB          %00100001
        DB          %00011110

; 'e' م mim
        DB          %00000000
        DB          %00000000
        DB          %00000010
        DB          %00000101
        DB          %00001010
        DB          %00001000
        DB          %00001000
        DB          %00001000

; 'f' ن nun
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00100001
        DB          %00101001
        DB          %00100001
        DB          %00011110

; 'g' ه heh
        DB          %00000000
        DB          %00000000
        DB          %00011000
        DB          %00100100
        DB          %00100100
        DB          %00011000
        DB          %00000000
        DB          %00000000

; 'h' و waw
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000010
        DB          %00000101
        DB          %00000011
        DB          %00000001
        DB          %00001110

; 'i' ي ya
        DB          %00000000
        DB          %00000000
        DB          %00000010
        DB          %01000100
        DB          %01000010
        DB          %00111100
        DB          %00000000
        DB          %00101000

; 'j' ى alef maqsura
        DB          %00000000
        DB          %00000000
        DB          %00001110
        DB          %00010000
        DB          %01001110
        DB          %01000001
        DB          %01000010
        DB          %00111100

; 'k' ال definite article al-
        DB          %00000000
        DB          %00010010
        DB          %00010010
        DB          %00010010
        DB          %00010010
        DB          %11111101
        DB          %00000000
        DB          %00000000


; ---- TABLE 1 ($3BC4, 6 records): FINAL forms (previous letter joins in, nothing follows).
; ---- Record = [key code][8-byte bitmap]. Only letters whose flag bit 4 is clear.
ARAB_GLYPH_TABLE_1:

; key 'G' ا alif (FINAL form)
        DB          $47
        DB          %00000000
        DB          %00000010
        DB          %00000010
        DB          %00000010
        DB          %00000010
        DB          %00000001
        DB          %00000000
        DB          %00000000

; key 'Y' ع ain (FINAL form)
        DB          $59
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00011100
        DB          %00001000
        DB          %00010111
        DB          %00100000
        DB          %00011110

; key 'Z' غ ghain (FINAL form)
        DB          $5A
        DB          %00000000
        DB          %00001000
        DB          %00000000
        DB          %00011100
        DB          %00001000
        DB          %00010111
        DB          %00100000
        DB          %00011110

; key 'g' ه heh (FINAL form)
        DB          $67
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00001100
        DB          %00010100
        DB          %00001011
        DB          %00000000
        DB          %00000000

; key 'i' ي ya (FINAL form)
        DB          $69
        DB          %00000000
        DB          %00000000
        DB          %00000110
        DB          %01001001
        DB          %01000101
        DB          %00111000
        DB          %00000000
        DB          %00101000

; key 'j' ى alef maqsura (FINAL form)
        DB          $6A
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000110
        DB          %00001001
        DB          %01000100
        DB          %01000010
        DB          %00111100


; ---- TABLE 2 ($3BFA, 8 records): MEDIAL forms (joined both sides). Flag bit 5 clear.
ARAB_GLYPH_TABLE_2:

; key 'H' ب ba (MEDIAL form)
        DB          $48
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00001000
        DB          %11110111
        DB          %00000000
        DB          %00001000

; key 'J' ت ta (MEDIAL form)
        DB          $4A
        DB          %00000000
        DB          %00000000
        DB          %00010100
        DB          %00000000
        DB          %00001000
        DB          %11110111
        DB          %00000000
        DB          %00000000

; key 'K' ث tha (MEDIAL form)
        DB          $4B
        DB          %00000000
        DB          %00001000
        DB          %00010100
        DB          %00000000
        DB          %00001000
        DB          %11110111
        DB          %00000000
        DB          %00000000

; key 'Y' ع ain (MEDIAL form)
        DB          $59
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00001110
        DB          %00000100
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'Z' غ ghain (MEDIAL form)
        DB          $5A
        DB          %00000000
        DB          %00000100
        DB          %00000000
        DB          %00001110
        DB          %00000100
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'f' ن nun (MEDIAL form)
        DB          $66
        DB          %00000000
        DB          %00000000
        DB          %00001000
        DB          %00000000
        DB          %00001000
        DB          %11110111
        DB          %00000000
        DB          %00000000

; key 'g' ه heh (MEDIAL form)
        DB          $67
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %11100011
        DB          %00010100
        DB          %00001000

; key 'i' ي ya (MEDIAL form)
        DB          $69
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00001000
        DB          %11110111
        DB          %00000000
        DB          %00010100


; ---- TABLE 3 ($3C42, 20 records): INITIAL forms (joins the next letter only). Flag bit 6 clear.
ARAB_GLYPH_TABLE_3:

; key 'H' ب ba (INITIAL form)
        DB          $48
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000010
        DB          %00000010
        DB          %11111100
        DB          %00000000
        DB          %00010000

; key 'J' ت ta (INITIAL form)
        DB          $4A
        DB          %00000000
        DB          %00000000
        DB          %01010000
        DB          %00000010
        DB          %00000010
        DB          %11111100
        DB          %00000000
        DB          %00000000

; key 'K' ث tha (INITIAL form)
        DB          $4B
        DB          %00000000
        DB          %00100000
        DB          %01010000
        DB          %00000010
        DB          %00000010
        DB          %11111100
        DB          %00000000
        DB          %00000000

; key 'L' ج jim (INITIAL form)
        DB          $4C
        DB          %00000000
        DB          %00000000
        DB          %00001000
        DB          %00010100
        DB          %00000010
        DB          %11111111
        DB          %00000000
        DB          %00001000

; key 'M' ح hah (INITIAL form)
        DB          $4D
        DB          %00000000
        DB          %00000000
        DB          %00001000
        DB          %00010100
        DB          %00000010
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'N' خ kha (INITIAL form)
        DB          $4E
        DB          %00000000
        DB          %00000010
        DB          %00001000
        DB          %00010100
        DB          %00000010
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'S' س sin (INITIAL form)
        DB          $53
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00010101
        DB          %11101010
        DB          %00000000
        DB          %00000000

; key 'T' ش shin (INITIAL form)
        DB          $54
        DB          %00000000
        DB          %00000100
        DB          %00001010
        DB          %00000000
        DB          %00010101
        DB          %11101010
        DB          %00000000
        DB          %00000000

; key 'U' ص sad (INITIAL form)
        DB          $55
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000110
        DB          %00101001
        DB          %11011111
        DB          %00000000
        DB          %00000000

; key 'V' ض dad (INITIAL form)
        DB          $56
        DB          %00000000
        DB          %00001000
        DB          %00000000
        DB          %00000110
        DB          %00101001
        DB          %11011111
        DB          %00000000
        DB          %00000000

; key 'Y' ع ain (INITIAL form)
        DB          $59
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000110
        DB          %00001000
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'Z' غ ghain (INITIAL form)
        DB          $5A
        DB          %00000000
        DB          %00000100
        DB          %00000000
        DB          %00000110
        DB          %00001000
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'a' ف fa (INITIAL form)
        DB          $61
        DB          %00000000
        DB          %00001000
        DB          %00000011
        DB          %00000011
        DB          %00000001
        DB          %11111110
        DB          %00000000
        DB          %00000000

; key 'b' ق qaf (INITIAL form)
        DB          $62
        DB          %00000000
        DB          %00010001
        DB          %00000100
        DB          %00001010
        DB          %00000110
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'c' ك kaf (INITIAL form)
        DB          $63
        DB          %00000000
        DB          %00000100
        DB          %00001000
        DB          %00011110
        DB          %00000001
        DB          %11111111
        DB          %00000000
        DB          %00000000

; key 'd' ل lam (INITIAL form)
        DB          $64
        DB          %00000000
        DB          %00000001
        DB          %00000001
        DB          %00000001
        DB          %00000001
        DB          %11111110
        DB          %00000000
        DB          %00000000

; key 'e' م mim (INITIAL form)
        DB          $65
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000110
        DB          %11111001
        DB          %00000110
        DB          %00000000

; key 'f' ن nun (INITIAL form)
        DB          $66
        DB          %00000000
        DB          %00001000
        DB          %00000000
        DB          %00000010
        DB          %00000010
        DB          %11111100
        DB          %00000000
        DB          %00000000

; key 'g' ه heh (INITIAL form)
        DB          $67
        DB          %00000000
        DB          %00011000
        DB          %00100100
        DB          %00101110
        DB          %00110010
        DB          %11111100
        DB          %00000000
        DB          %00000000

; key 'i' ي ya (INITIAL form)
        DB          $69
        DB          %00000000
        DB          %00000000
        DB          %00000000
        DB          %00000010
        DB          %00000010
        DB          %11111100
        DB          %00000000
        DB          %00101000

; ---- Letters in no table (O P Q R W X h, A-F, I, k) always use the isolated font.
; ---- ARAB_PRINT_EXTRA_MSG ($3CF6): boot-splash helper.  Patched call at $1295 (START-NEW, file 06).
; ---- Clears the screen, then prints the ARABIC TITLE LOGO: the message that follows the
; ---- cassette messages in file 04, starting at $09E0 (DE=$09DF is the inverted last byte of the
; ---- previous message, the step-over byte).  Screen result (row/column of the 8x8 cells):
; ----       row 12, col 15 : *        row 13, col 15 : |        row 14, cols 11-19 : عرب | رام
; ----       i.e. "ARAB | RAM"  (key codes "YQH | QGe").
ARAB_PRINT_EXTRA_MSG:
        CALL    CLS                   ; clear the screen (leaves the lower-screen channel open)
        XOR     A                       ; message number 0 ...
        LD      DE,TAPE_MSG_4_END       ; ... after the step-over byte (end of tape message 4, file 04; boot title follows)
        JP      PO_MSG                   ; print it (PO-MSG returns to START-NEW)
        