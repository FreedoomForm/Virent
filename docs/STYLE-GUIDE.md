# Virent Style Guide

Inspired by BarqScoot (github.com/RishiAhuja/BarqScoot) — clean, light, modern.

## Design language

```text
Theme            Light by default, dark optional
Primary          #3489FF  (BarqScoot teal-blue)
Background       #FFFFFF  (light)  /  #1F2937  (dark)
Surface          #FFFFFF  (light)  /  #111827  (dark)
Text primary     #000000  (light)  /  #FFFFFF  (dark)
Text secondary   #6B7280  (light)  /  #9CA3AF  (dark)
Text muted       #9CA3AF  (light)  /  #6B7280  (dark)
Border           #E5E7EB  (light)  /  #374151  (dark)
Radius           16 px   (cards, modals)
                 12 px   (buttons)
                 999 px  (pills, badges)
Spacing          4 8 12 16 20 24 32 40 56  (8 px grid + 4 / 20)
Shadow           0.05 black, blur 10, offset (0, 2)  (subtle)
Typography       Plus Jakarta Sans (mobile + web), Segoe UI Variable (Windows)
                 weights: 400 / 500 / 600 / 700
                 sizes: 12 / 14 / 16 / 18 / 24 / 28 / 32
Icons            Material Icons (mobile), Segoe MDL2 Assets (Windows)
                 NO emoji anywhere in the UI
```

## Color tokens (light)

```text
primary            #3489FF   primary action, FAB, links
primaryHover       #2A75E0
primaryDisabled    #B3D1FF
onPrimary          #FFFFFF   text on primary

bg                 #FFFFFF
bgAlt              #F9FAFB
surface            #FFFFFF
surfaceAlt         #F3F4F6
border             #E5E7EB
borderStrong       #D1D5DB

textPrimary        #111827
textSecondary      #4B5563
textMuted          #9CA3AF
textDisabled       #D1D5DB
textOnPrimary      #FFFFFF

success            #16A34A
successBg          #DCFCE7
warning            #D97706
warningBg          #FEF3C7
danger             #DC2626
dangerBg           #FEE2E2
info               #0284C7
infoBg             #E0F2FE
```

## Color tokens (dark)

```text
primary            #3489FF
onPrimary          #FFFFFF

bg                 #1F2937
bgAlt              #111827
surface            #1F2937
surfaceAlt         #374151
border             #374151
borderStrong       #4B5563

textPrimary        #F9FAFB
textSecondary      #D1D5DB
textMuted          #9CA3AF
textDisabled       #4B5563

success            #22C55E
warning            #F59E0B
danger             #EF4444
info               #38BDF8
```

## Component patterns

### Button

```text
Height         48 px (md)  /  40 px (sm)  /  56 px (lg)
Padding        20 px horizontal
Radius         12 px
Font           14 px / 600 weight
FilledButton   bg = primary, color = white, hover = primaryHover
OutlinedButton bg = transparent, border = border, color = textPrimary
TextButton     bg = transparent, color = primary
Disabled       bg = primaryDisabled, color = white
```

### Card

```text
Padding        16 px (default)  /  12 px (compact)
Radius         16 px
Shadow         0.05 black, blur 10, offset (0, 2)
Border         1 px solid border (optional, for emphasis)
Header         font 16 / 600, color textPrimary
Subtitle       font 14 / 400, color textSecondary
```

### Input

```text
Height         48 px
Radius         12 px
Border         1 px solid border
Focus border   2 px solid primary
Error border   2 px solid danger
Label          font 12 / 600, color textSecondary
Help text      font 12 / 400, color textMuted
Error text     font 12 / 400, color danger
```

### Badge / pill

```text
Padding        4 px / 12 px
Radius         999 px (full)
Font           12 px / 600
Variants       success / warning / danger / info / neutral
```

### ListView (Win32 desktop)

```text
Header         bg = surfaceAlt, text = textSecondary, font 12 / 600
Row            bg = surface, hover = surfaceAlt, text = textPrimary
Selected       bg = primary, text = white
Grid lines     1 px solid border
```

### Bottom navigation (mobile)

```text
Height         60 px + 35 px (for FAB notch)
Background     surface
Border top     1 px solid border
Items          4 (History / Rides / Wallet / Profile)
Active color   primary
Inactive color textMuted
FAB            64 px, primary, white icon (QR scanner)
```

### Sidebar (desktop)

```text
Width          220 px
Background     surface
Item height    42 px
Active item    bg = primary, text = white
Inactive item  bg = transparent, text = textSecondary
Icon           18 px Segoe MDL2 Assets, 16 px left padding
Label          14 px / 500 weight
```

## Layout

```text
Mobile           SafeArea + 16 px content padding
Desktop          220 px sidebar + content area with 16 px padding
Window (default) 1280 x 860 px
```

## Iconography

```text
Mobile          @expo/vector-icons -> Ionicons (Material icons name space)
                Tab bar:    map / route / wallet / notifications / settings
                Actions:    add / close / checkmark / alert / search / filter
                Status:     ellipse (online) / cloud-offline / warning

Desktop         Segoe MDL2 Assets (Windows 10+ built-in)
                Sidebar:    Home / Settings / Car / Route / People / MapPin /
                            Region / MapLayers / BarChart / Audit / CreditCard /
                            BatteryCharging / Plug / Message / Settings / DocumentLines
                Actions:    Add / Cancel / Accept / Warning / Refresh / Export
                Status:     StatusCircle (green / red)
```

## Motion

```text
duration fast  150 ms
duration med   200 ms
duration slow  300 ms
easing         cubic-bezier(0.4, 0.0, 0.2, 1)
```

## What changed from the previous (dark violet) design

```text
Before                          After
----------------------------    -----------------------------
Dark theme (#0F172A bg)         Light theme (#FFFFFF bg)
Violet primary (#7C3AED)        Teal-blue primary (#3489FF)
Inter font                      Plus Jakarta Sans
8 px radius                     16 px radius
No FAB                          Center FAB for QR scanner
Text-only bottom tabs           Icon + label bottom tabs
Emoji icons                     Material / MDL2 icons
```
