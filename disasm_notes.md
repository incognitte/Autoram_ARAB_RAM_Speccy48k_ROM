# ArabRAM (ZX Spectrum 48K Arabic ROM)
Purpose: everything learned while reverse-engineering the Arabic ROM (translating messages, re-annotating source, further analysis) without redoing the work.

Language note: Arabic text appears below as real Arabic. On the Spectrum it is stored as ASCII "key codes".

## SUMMARY
The ROM is the standard 48K Spectrum ROM (Logan/O`Hara style commented source, files 01-10) patched to print Arabic. Text is stored as ordinary ASCII bytes ("key codes"):  
- a hook in PO-CHAR swaps the character-bitmap base so letters are drawn with Arabic glyphs, chosen by letter position (isolated / initial / medial / final) using a lookahead character.  
- Printing runs right-to-left. All new code and data live in formerly-unused space `$386E-$3CFF` (file 11) plus small patches in the old canned-message area `$1391-$145C` (file 06), the keyword table (file 01) and the message table after the tape messages (file 04).  

The source files assemble to a binary IDENTICAL to the ROM read from the real machine.  

- `01 restarts_and_tables` (`RST`s, tables, `TKN_TABLE` keyword table, key tables)  
- `02 keyboard_routines` & `03 loudspeaker_routines` & `04 cassette_handling_routines` (incl. tape msgs + boot title)  
- `05 screen_and_printer_routines` & `06 executive_routines` (`START-NEW`, relocated number routines, glyph substitution)
- `07 basic_line_and_command_interpretation` & `08 expression_evaluation` & `09 arithmetic_routines` & `10 floating_point_calculator`
- `11 arabic_glyph_font` & `12 zx_spectrum_char_set` (ALL Arabic glyph data, message table, editor extensions, print hooks, then the ordinary character set at `$3D00`)

## ROM MAP OF THE ARABIC ADDITIONS

| **Address** | **Content** |
|-|-|
| `$0095-$01EC` | `TKN_TABLE`: 92 entries (dummy `?` + 91 Arabic keywords, tokens `$A5-$FF`) |
| `$01ED-$01FD` | Boot copyright line "`(c) AutoRAM Computer`" (ARAB_BOOT_COPYRIGHT_MSG, key codes 7F "` GhJhQGe ceHihJQ`") |   
| `$01FE` | `ARAB_FORM_OVERRIDE_ENTRY: ADD A,A; LD DE,$154C; JP $0A7B` (control codes 0-3) |   
| `$09E0` | Boot TITLE LOGO message (after the 5 tape messages in file 04) |   
| `$0C22 / $0C23 / $0C2A` | `PO-MSG` loop, patched: `EX DE,HL; LD A,(HL); INC HL; BIT 7,A; JP $3B3C` |   
| `$0F38` | `JP ARAB_ED_KEY_EXT` (editor key loop front end) |   
| `$1391-$145C` | Old canned messages replaced by: `L1391/L1395, L139E, L13FC, L1426/L1434, L1436` (section 8) |   
| `$145D` | `ARAB_GLYPH_SUBSTITUTE` (file 06) - called from `PO-CHAR` hook at `$0B66` |   
| `$14D6-$150F` | `ARAB_KEY_LOOKUP_TABLE` (physical key -> key code), base `$14D6-$41` |   
| `$1510` | L1510: context routine (sets `TV_FLAG` bits 7/2 from letter + lookahead) |   
| `$154C` | `ARAB_FORM_OVERRIDE_OUT`: one-shot output handler for `CHR$ 0-3: CALL L1395; CALL $002B; JP L387B` |   
| `$386E-$3894` | `ARAB_NEW_CTRL_HANDLER (codes 0-5), L387B, ARAB_MODE_TOGGLE` |   
| `$3895-$3922` | `ARAB_ED_KEY_EXT`, key-decode wrapper L38DA, key-delivery wrapper L38F3, `ARAB_GLYPH_GUARD ($3917)` |   
| `$3923-$39EF` | `ARAB_MSG_TABLE_AR` (28 Arabic report messages) |   
| `$39F0-$3A3F` | Digit font (Arabic-Indic digits), glyph = `$3870` + 8*code |   
| `$3A40-$3A6B` | Character flag table, codes `$40-$6B` (lookup `$3A00`+code) |   
| `$3A6C-$3BC3` | Isolated-form font, glyph = `$3864` + 8*code, codes `$41-$6B` (``A`..`k``) |
| `$3B3C-$3B6B` | `CODE` inside the glyph font (slots for codes `$5B-$60` are never letters): `ARAB_PO_MSG_HOOK` (`$3B3C`) and `ARAB_PR_STRING_HOOK` (`$3B57`), 2 spare bytes `$3B6A-B` |   
| `$3BC4 / $3BFA / $3C42` | Glyph table 1 FINAL (6 recs), table 2 MEDIAL (8 recs), table 3 INITIAL (20 recs); record = key byte + 8 bitmap bytes (9 bytes) |   
| `$3CF6-$3CFF` | `ARAB_PRINT_EXTRA_MSG: CALL CLS; XOR A; LD DE,$09DF; JP PO_MSG` (boot title) |   
| `$3D00` on | Normal Latin character set (`[` prints as pi glyph, `]` as an `E` glyph) |   

## KEY CODES -> ARABIC
Arabic text is stored as the ASCII codes below. To read a stored string, map each character; to write one, do the reverse. Strings print right to left, so the first stored character is the rightmost on screen, i.e. the stored order IS the reading order. Examples: REM=BMX -> لاحظ, FOR=BLd -> لاجل, NOT=B -> لا, error=NWC -> خطأ, OK=LiO -> جيد.  

- **Uppercase**: G ا  H ب  I ة  J ت  K ث  L ج  M ح  N خ  O د  P ذ  Q ر  R ز  S س  T ش  U ص  V ض  W ط  X ظ  Y ع  Z غ  
- **Hamza family**: A ء  B لا (lam-alef ligature, one cell)  C أ  D ؤ  E إ  F ئ  
- **Lowercase**: a ف  b ق  c ك  d ل  e م  f ن  g ه  h و  i ي  j ى  k ال (definite article, one cell)  
- Everything else (space, digits, punctuation, `$ # = < > : / ( )` and so on) prints as itself (digits as Arabic-Indic, `[` as pi). Codes >= $6C (lowercase l-z) are normal Latin letters.  

Per-letter data (flag byte, joining, which forms exist, physical key that types it):  

| Key | Arabic | Name | Flag | Joins fwd | Forms | Physical key typed |
|---|---|---|---|---|---|---|
| G | ا | alif | $6F | no | iso/fin | g |
| H | ب | ba | $9F | yes | iso/init/med | c |
| I | ة | ta marbuta | $7F | no | iso | H |
| J | ت | ta | $9F | yes | iso/init/med | h |
| K | ث | tha | $9F | yes | iso/init/med | W |
| L | ج | jim | $BF | yes | iso/init | p |
| M | ح | hah | $BF | yes | iso/init | o |
| N | خ | kha | $BF | yes | iso/init | i |
| O | د | dal | $7F | no | iso | m |
| P | ذ | dhal | $7F | no | iso | n |
| Q | ر | ra | $7F | no | iso | v |
| R | ز | zay | $7F | no | iso | N |
| S | س | sin | $BF | yes | iso/init | s |
| T | ش | shin | $BF | yes | iso/init | a |
| U | ص | sad | $BF | yes | iso/init | w |
| V | ض | dad | $BF | yes | iso/init | q |
| W | ط | tah | $FF | yes | iso | x |
| X | ظ | zah | $FF | yes | iso | z |
| Y | ع | ain | $8F | yes | iso/init/med/fin | y |
| Z | غ | ghain | $8F | yes | iso/init/med/fin | t |
| A | ء | hamza | $FF | yes | iso | D |
| B | لا | lam-alef | $7F | no | iso | K |
| C | أ | alef+hamza above | $7F | no | iso | G |
| D | ؤ | waw+hamza | $7F | no | iso | A |
| E | إ | alef+hamza below | $7F | no | iso | V |
| F | ئ | ya+hamza | $FF | yes | iso | S |
| a | ف | fa | $BF | yes | iso/init | r |
| b | ق | qaf | $BF | yes | iso/init | e |
| c | ك | kaf | $BF | yes | iso/init | l |
| d | ل | lam | $BF | yes | iso/init | f |
| e | م | mim | $BF | yes | iso/init | k |
| f | ن | nun | $9F | yes | iso/init/med | j |
| g | ه | heh | $8F | yes | iso/init/med/fin | u |
| h | و | waw | $7F | no | iso | b |
| i | ي | ya | $8F | yes | iso/init/med/fin | d |
| j | ى | alef maqsura | $6F | no | iso/fin | X |
| k | ال | definite article al- | $FF | yes | iso | F |

### How to type on the real keyboard (from ARAB_KEY_LOOKUP_TABLE)
the Spectrum letter key is mapped as in the last column (lowercase keys mostly; the few uppercase ones need Caps Shift in capitals mode). Unmapped keys give `?`. Uppercase `E` maps to code $5D (`]`).  
   
### Print Arabic on screen
1. Any print goes through PO-CHAR ($0B65). The patched $0B66 calls ARAB_GLYPH_SUBSTITUTE ($145D) which returns BC = a font base; the normal fetch "BC + 8*code" then draws an Arabic bitmap. Bit 4 of (IY+1) SET = substitution OFF (Latin).  
2. ARAB_GLYPH_GUARD ($3917): digit (NUMERIC carry clear) -> BC=$3870 (digit font); non-letter or code >= $6C -> normal font; letter -> shaping.  
3. Isolated letters: BC=$3864 -> glyph at $3864+8*code ($3A6C for `A` ... $3BBC for `k`).  
4. Joined forms: BC = address of the bitmap inside table 1/2/3 found by scanning for the key byte.  
5. Context bits in TV_FLAG ($5C3C) = (IY+2): bit 7 = this letter joins the NEXT letter; bit 2 = it does NOT; bit 1 = the PREVIOUS letter joined into this one; bit 6 = keyboard map (set = Latin). L1510 receives A=letter and B=LOOKAHEAD char and sets bits 7/2.  
`Form selection: bit2=0,bit1=0 -> INITIAL (table 3); bit2=0,bit1=1 -> MEDIAL (table 2); bit2=1,bit1=0 -> ISOLATED ($3864 font); bit2=1,bit1=1 -> FINAL (table 1). A missing form falls back: medial -> initial -> isolated; final -> isolated.`
6. Flag byte per letter (table at $3A40 for codes $40-$6B): bit7 = can join forward; bit6 set = no initial form; bit5 set = no medial form; bit4 clear = a final form exists. Verified against table membership for every letter.  
7. Lookahead supply: PO-MSG and token printing hook ($3B3C) pass the next message character (space at the end); PRINT-string hook ($3B57) passes the next byte in memory.  
8. QUIRK (confirmed on hardware): $3B57 does DEC B / JR NC which is always taken (carry clear from OR C at $203E), so the "end of string -> lookahead = space" fallback never runs; the last letter of a PRINTed string looks at the byte AFTER the string. A string variable followed in memory by an alphabetic byte (e.g. the next variable`s name byte) makes its last letter join forward. Literals are safe (next byte is the closing quote). Optional untested fix (same length): replace the 21 bytes at $3B57 with 23 C5 04 05 20 02 0C 0D 46 20 02 06 20 CD 10 15 D7 C1 C3 3D 20.  
9. The previous letter never joins into a control byte (not alphabetic).  
10. Right-to-left coordinates: columns count from the right edge (TAB 12 puts text starting at screen column 19). Numbers are printed units-first so the most significant digit appears on the left (section 8).  

### CONTROL CODES AND EDITOR KEYS

| **Code** | **Effect** |   
|-|-|  
| CHR$ 0..3 | FORM OVERRIDE for the NEXT printed character (still printed): 0 initial, 1 medial, 2 isolated, 3 final. Mechanism: $01FE stores 2*code in TVDATA ($5C0E), installs one-shot handler $154C (clears TV_FLAG bits 2/1, restores normal output, JP L387B which ORs TVDATA into TV_FLAG, then prints). Verified pixel-exact on hardware. |   
| CHR$ 4 | Arabic ON: RES 4,(IY+1) and clear context bits 2/1 (L1391) |   
| CHR$ 5 | Latin ON: SET 4,(IY+1). The pair CHR$ 5 ... CHR$ 4 brackets a Latin run. Codes 4/5 take no screen cell. |   

Editor (ARAB_ED_KEY_EXT at 3895, wrappers L38DA/L38F3): Symbol Shift+SPACE inserts CHR 0; while the cursor sits on a CHR$ 0-3 byte each further press cycles 0>1>2>3>0 (so 1/2/3 presses leave 0/1/2 - verified). Symbol Shift+ENTER on the ARABIC keyboard inserts CHR$ 5,CHR$ 4 with the cursor between them (verified: stored bytes 05 04); on the LATIN keyboard it moves the cursor past the next CHR$ 4 (or to end of line) to resume Arabic. TV_FLAG bit 6 is refreshed from (IY+1) bit 4 by ARAB_MODE_TOGGLE on every cursor redraw ($18E8 hook). The keyboard map follows bit 6.
   
## BOOT SPLASH
Printed by START-NEW (file 06): (1) ARAB_PRINT_EXTRA_MSG = CLS then the title message at $09E0, (2) the copyright line at $01ED.  
   
 Screen:  
- row 12, col 15: `*`   - row 13, col 15: |   - row 14, cols 11-19: YQH | QGe = `عرب | رام` = "ARAB | RAM"  
- row 23, cols 7-23: (c) GhJhQGe ceHihJQ = `(c) اوتورام كمبيوتر` = "(c) AutoRAM Computer"  
   
 Title message bytes: 06 2A 06 06 7C 17 0C 00 "YQH | QGe" 16 0C 88. Controls: $06 PRINT comma (pad to column 16 from the right), $17 TAB (16-bit), $16 AT; the final $88 is $08 with the end bit set (so AT 12,8). Messages printed right after CLS go to the LOWER-SCREEN channel; the closing AT 12,8 grows the lower window (DF_SZ 13), scrolling the three logo lines up to rows 12-14.  

## MESSAGE TABLES
### Report messages (ARAB_MSG_TABLE_AR at $3923; index = report code)

| **#** | **Original English** | **Stored key codes** | **Arabic decoded** | **Note** |   
|-|-|-|-|-|  
| 0 | OK | LiO | جيد |   |   
| 1 | NEXT without FOR | B BLd | لا لاجل | same text as 18 |   
| 2 | Variable not found | B eJZiQ | لا متغير |   |   
| 3 | Subscript wrong | UaI NWC | صفة خطأ | `صفة خطأ` = `attribute error` |   
| 4 | Out of memory | B PGcQI | لا ذاكرة |   |   
| 5 | Out of screen | B TGTI | لا شاشة |   |   
| 6 | Number too big | Qbe cHiQ | رقم كبير |   |   
| 7 | RETURN without GOSUB | B GPgH | لا اذهب |   |   
| 8 | End of file | fgGiI eda | نهاية ملف |   |   
| 9 | STOP statement | ba | قف |   |   
| 10 | Invalid argument | B LOGd | لا جدال |   |   
| 11 | Integer out of range | UMiM c | صحيح ك | decodes literally to `صحيح ك` - looks abbreviated/truncated |   
| 12 | Nonsense in BASIC | B eYfj | لا معنى |   |   
| 13 | BREAK - CONT repeats | ebWY | مقطع | `مقطع` = `interrupted/section` |   
| 14 | Out of DATA | ef GaGOI | من افادة | `من افادة` = `from statement` |   
| 15 | Invalid file name | B GSe eda | لا اسم ملف |   |   
| 16 | No room for line | B aQZ dSWQ | لا فرغ لسطر | `فرغ` (probably short for `فراغ` = room/space) |   
| 17 | STOP in INPUT | ba | قف |   |   
| 18 | FOR without NEXT | B BLd | لا لاجل | same text as 1 |   
| 19 | Invalid I/O device | B GONGd/GNQGL | لا ادخال/اخراج |   |   
| 20 | Invalid colour | B dhf | لا لون |   |   
| 21 | BREAK into program | GbWY | اقطع | `اقطع` = `cut/break` |   
| 22 | RAMTOP no good | QGe HhH ZiQ LiO | رام بوب غير جيد |   |   
| 23 | Statement lost | ViGY GeQ | ضياع امر |   |   
| 24 | Invalid stream | B GJUGd | لا اتصال | `لا اتصال` = `no connection` |   
| 25 | FN without DEF | B eKd eYQaI | لا مثل معرفة | `لا مثل معرفة` = `no like defined` |   
| 26 | Parameter error | NWC ebOGQ | خطأ مقدار |   |   
| 27 | Tape loading error | NWC JYHFI | خطأ تعبئة |   |   
   
Report code printing (MAIN-5): codes 0-9 print as a digit; codes 10-27 print as the key code code+$3E (the code adds $30, and if the result is above `9` adds 14 more: 10=`H`, 11=`I` ... 27=`Y`) = ب ة ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع, then a space, the message, a space, then line:statement. L1391 forces Arabic mode first.  

### Cassette messages (file 04, $09A..)  
- 0 "Start tape, then press any key." = ابدا الشريط واضغط مفتاحا (GHOG GdTQiW hGVZW eaJGM + `G`|$80)  
- 1 "Program:" = برمجة : (HQeLI + `:`)  
- 2 "Number array:" = تنطيم رقم : (spelled with ط)  
- 3 "Character array:" = تنطيم حرف :  
- 4 "Bytes:" = بايتس :  
   
 (each of 1-4 is preceded by CR, ends with `:`|$80)  

### Keywords (TKN_TABLE, token = code)

| **Token** | **English** | **Stored key codes** | **Arabic** |   
|-|-|-|-|  
| $A5 | RND | YThG | عشوا |   
| $A6 | INKEY$ | iGNPe$ | ياخذم$ |   
| $A7 | PI | [ | [ |   
| $A8 | FN | MGdI | حالة |   
| $A9 | POINT | fbWI | نقطة |   
| $AA | SCREEN$ | TGTI$ | شاشة$ |   
| $AB | ATTR | YRG | عزا |   
| $AC | AT | YfO | عند |   
| $AD | TAB | LOhd | جدول |   
| $AE | VAL$ | bie$ | قيم$ |   
| $AF | CODE | TaQI | شفرة |   
| $B0 | VAL | bie | قيم |   
| $B1 | LEN | Whd | طول |   
| $B2 | SIN | LG | جا |   
| $B3 | COS | LJG | جتا |   
| $B4 | TAN | Xd | ظل |   
| $B5 | ASN | bhLG | قوجا |   
| $B6 | ACS | bhLJG | قوجتا |   
| $B7 | ATN | bhXd | قوظل |   
| $B8 | LN | dhZ W | لوغ ط |   
| $B9 | EXP | GS | اس |   
| $BA | INT | UMiM | صحيح |   
| $BB | SQR | LPQ | جذر |   
| $BC | SGN | GTGQI | اشارة |   
| $BD | ABS | eWdb | مطلق |   
| $BE | PEEK | iLO | يجد |   
| $BF | IN | ai | في |   
| $C0 | USR | NGU | خاص |   
| $C1 | STR$ | eLehYI$ | مجموعة$ |   
| $C2 | CHR$ | MQa$ | حرف$ |   
| $C3 | NOT | B | لا |   
| $C4 | BIN | KfGFi | ثنائي |   
| $C5 | OR | Gh | او |   
| $C6 | AND | GiVG | ايضا |   
| $C7 | <= | <= | <= |   
| $C8 | >= | >= | >= |   
| $C9 | <> | <> | <> |   
| $CA | LINE | NW | خط |   
| $CB | THEN | GPf | اذن |   
| $CC | TO | Gdj | الى |   
| $CD | STEP | NWhI | خطوة |   
| $CE | DEF FN | MGdg eYQag | حاله معرفه |   
| $CF | CAT | cJdhL | كتلوج |   
| $D0 | FORMAT | JUeie | تصميم |   
| $D1 | MOVE | MQcg | حركه |   
| $D2 | ERASE | GeSM | امسح |   
| $D3 | OPEN # | aJM # | فتح # |   
| $D4 | CLOSE # | GZdb # | اغلق # |   
| $D5 | MERGE | OeL | دمج |   
| $D6 | VERIFY | JMbb | تحقق |   
| $D7 | BEEP | fZeI | نغمة |   
| $D8 | CIRCLE | OGFQI | دائرة |   
| $D9 | INK | MHQ | حبر |   
| $DA | PAPER | hQbI | ورقة |   
| $DB | FLASH | heV | ومض |   
| $DC | BRIGHT | BeY | لامع |   
| $DD | INVERSE | eYchS | معكوس |   
| $DE | OVER | ahb | فوق |   
| $DF | OUT | NGQL | خارج |   
| $E0 | LPRINT | GWHY W | اطبع ط |   
| $E1 | LLIST | HiGf W | بيان ط |   
| $E2 | STOP | ba | قف |   
| $E3 | READ | GbQC | اقرأ |   
| $E4 | DATA | GaGOI | افادة |   
| $E5 | RESTORE | GSJYGO | استعاد |   
| $E6 | NEW | LOO | جدد |   
| $E7 | BORDER | LhGfH | جوانب |   
| $E8 | CONTINUE | JGHY | تابع |   
| $E9 | DIM | HYO | بعد |   
| $EA | REM | BMX | لاحظ |   
| $EB | FOR | BLd | لاجل |   
| $EC | GO TO | GPgH Gdj | اذهب الى |   
| $ED | GO SUB | GbUO | اقصد |   
| $EE | INPUT | GONd | ادخل |   
| $EF | LOAD | YHG | عبا |   
| $F0 | LIST | HiGf | بيان |   
| $F1 | LET | OY | دع |   
| $F2 | PAUSE | hba | وقف |   
| $F3 | NEXT | idi | يلي |   
| $F4 | POKE | VY | ضع |   
| $F5 | PRINT | GWHY | اطبع |   
| $F6 | PLOT | QSe | رسم |   
| $F7 | RUN | TZd | شغل |   
| $F8 | SAVE | SLd | سجل |   
| $F9 | RANDOMIZE | YThGi | عشواي |   
| $FA | IF | GPG | اذا |   
| $FB | CLS | GeM T | امح ش |   
| $FC | DRAW | iQSe | يرسم |   
| $FD | CLEAR | GeM | امح |   
| $FE | RETURN | GQLY | ارجع |   
| $FF | COPY | fSN | نسخ |   

**Note:** a few are abbreviations (LN = لوغ ط, LPRINT = اطبع ط, LLIST = بيان ط, CLS = امح ش); `INKEY$` ends in a plain `$`; `PI` prints as the pi glyph; `<= >= <>. #, $` stay as symbols. Entry 0 is a dummy inverted `?` step-over byte.
   
### The "scroll?" prompt (SCRL_MSSG, file 05, ROM $0CF8)
Bytes: 80 04 51 61 59 BF 6C BF = step-over, CHR$ 4 (Arabic ON), Q a Y, `?`+$80, then `l`, `?`+$80.  
- Decoded with the section 3 map: Q = ر, a = ف, Y = ع  ->  **رفع؟** ("rafa'a" = raise / lift [the screen up]) followed by a plain Latin `?`.  
- The English message was scroll? = 7 bytes (73 63 72 6F 6C 6C BF). The patch overwrote the first 5 bytes with 04 Q a Y ?|$80 and the last two original bytes (6C BF = `l`, `?|$80`) survive. PO-MSG stops at the FIRST byte with bit 7 set, so those two bytes are DEAD (never printed, nothing refers to them). They are kept in the source (as a separate DB) so the ROM stays byte-identical.  

## RELOCATED / NEW NUMBER ROUTINES (file 06, formerly the canned messages $1391-$145C)
The English report messages and " 1982 Sinclair Research Lt" were removed. Freed space now holds routines that make numbers work in a right-to-left screen: L1391 (Arabic ON), L1395 (clear context bits 2/1), L139E (number scanner: digits copied backwards into a buffer before DEC_TO_FP, handles BIN token $C4, `.`, and exponent marker $5D = the `]` key shown as `E`), L13FC (line-number scanner, units digit first, weight 1,10,100..), L1426/L1434 (one decimal digit, replaces OUT-SP-NO), L1436 (prints a 16-bit number UNITS FIRST - replaces OUT-NUM-3 - so the most significant digit lands on the left; E=$FF no leading zeros, E=$20 leading spaces).  
