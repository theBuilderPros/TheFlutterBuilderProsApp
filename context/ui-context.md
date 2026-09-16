# UI Context

## Direction

theBuilderPros uses a restrained, professional mobile visual language inspired by clear professional-network products while retaining the theBuilderPros logo palette.

The current interface is light mode only.

## Visual Hierarchy

- neutral light page background
- white cards, fields, and bottom navigation
- black primary and secondary typography
- neutral borders and subtle shadows
- orange for primary actions and focused emphasis
- violet for selected navigation, focus states, supporting badges, and small accent slices

Avoid large orange or violet backgrounds. Avoid dim/gray text. Avoid decorative colored strips on cards.

## Current Tokens

| Role | Token | Value |
| --- | --- | --- |
| Orange | `AppColors.primary` / `accent` | `#F35A12` |
| Orange dark | `AppColors.primaryDark` | `#D94A08` |
| Orange soft | `AppColors.primarySoft` / `accentSoft` | `#FFF0E8` |
| Violet | `AppColors.violet` / `secondary` | `#5B20E5` |
| Violet soft | `AppColors.violetSoft` | `#EEE8FF` |
| Background | `AppColors.background` | `#F4F2F1` |
| Surface | `AppColors.surface` | `#FFFFFF` |
| Text | `AppColors.textPrimary` / `textSecondary` | `#000000` |
| Border | `AppColors.border` | `#DED9E8` |

## Typography

`AppTheme` declares Inter as the app family and uses bold, black headings with black body/label text. If custom font files are later bundled, configure them in `pubspec.yaml`; do not assume a declared family is embedded when it is not.

## Components

### Page Header

- official stacked theBuilderPros logo on the left
- notification control on the right
- page title and subtitle
- a left-aligned underline at about 32% of content width
- underline is mostly orange with a small violet ending

### Cards

- white surface
- 20px current runtime radius
- neutral border
- subtle shadow
- no orange, violet, or per-App top strip

### Navigation

- white Material 3 bottom NavigationBar
- violet selected indicator on a violet-soft pill
- Home, Rewards, Apps
- hidden while App Detail is open

### Buttons and Inputs

- primary filled action: orange with white text
- outlined/supporting action: violet/neutral
- input surface: white
- focused border: violet
- stadium/pill treatment for primary themed buttons

### Badges

- orange-soft status badges for general status
- violet-soft badges for following/level/count support
- keep badge usage compact

## Screen Inventory

- Home: profile card, balance card, followed Apps
- Rewards: balance, segmented Receive/Send, QR placeholder, Reward ID, send fields
- Apps: search and App cards
- App Detail: overview, follow action, WIP, Committed Work, Work History

## Accessibility and Responsiveness

- preserve strong black text contrast
- keep tap targets large enough for touch
- respect SafeArea
- use scrolling layouts for compact devices
- add semantic labels and real form validation during logic integration
- test overflow on narrow devices before release
