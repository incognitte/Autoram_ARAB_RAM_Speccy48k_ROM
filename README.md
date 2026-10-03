# ZX Spectrum ROM Disassembly - Autoram Arab Ram

This repository contains the disassemblies and source code reconstruction for the **Autoram Arab Ram** ROM, a specialized Arabic language modification developed for the Sinclair ZX Spectrum.

---

## Overview

The **Arab Ram** ROM is a regional localization of the classic Sinclair ZX Spectrum operating system. Unlike the officially commissioned Egyptian Arabic ROMs (developed by Dr. Nabil Nazmi / Sinclair Egypt), the **Arab Ram** module was created by **Autoram Computer** (*Ramez M. al-Halaby & Co.*) based in Jeddah, Saudi Arabia. 

Autoram was widely known in the region for producing hardware and software add-ons to adapt early home computers—such as the ZX81 and ZX Spectrum—to support the Arabic language.

### Key Details
* **Brand/Developer:** Autoram Computer (Ramez M. al-Halaby & Co.)
* **Country of Origin:** Saudi Arabia (Jeddah)
* **First Released:** c. 1984 / 1986
* **Target Hardware:** Sinclair ZX Spectrum (compatible with modified systems such as the ZX Spectrum +2 with a language ROM switch)
* **Scope:** Translates and adapts the standard 48K Sinclair BASIC ROM routines for Arabic support. *(Note: Like many regional variants, it functions primarily within the 48K mode).*

---

## Copyright & Localization String

Upon boot or initialization, the localized Arabic copyright header reads:
> **عرب 🌴 رام**
> 
> **© اوتورام كمبيوتر**
> 
> *Meaning: Arab Ram © Autoram Computer*

---


## Repository Structure

* `rom/` - Original binary dumps of the Arab Ram ROM.
* `src/` - Assembled and commented source code (Z80 assembly format compatible with modern assemblers like `sjasmplus`).
* `docs/` - Technical notes, character set layouts, and historical documentation references.

---

## 🚀 Building the Disassembly

To assemble the source code and verify byte-for-byte compatibility with the original ROM:

1. Install [`sjasmplus`](https://github.com/z80-de/sjasmplus) Z80 assembler.
2. Run the build script or compile directly:
   ```bash
   make
