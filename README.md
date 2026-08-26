# BiteLedger

Your intake, double-entry. BiteLedger is a personal, offline-first calorie and macro ledger for iPhone. It posts packaged foods from [Open Food Facts](https://world.openfoodfacts.org) as debit lines against a daily energy budget. There is no account, no ads, no analytics and no medical advice — only a ruled food book on the device.

## Architecture

The app uses **MVVM + Combine**. Each screen has a `BLG*ViewModel` that exposes `@Published` outputs and accepts `PassthroughSubject` inputs. View controllers bind with `.sink` into a `Set<AnyCancellable>`. Catalogue work uses `URLSession.dataTaskPublisher`. Storage lives in an actor (`BLGLedgerStore`) and is bridged to the presentation layer with `Future`, so view controllers never use `async/await`.

This shape fits a ledger: every keystroke, scan and post is a stream of inputs, and the page must stay consistent when a slower request is cancelled. `switchToLatest` drops stale search pages; a 150 ms spinner gate keeps the book from flickering.

UIKit + one `Main.storyboard` + segues owns navigation. A custom drawer (`BLGDrawerContainerController`) slides over the ledger. There is no tab bar.

## Unique feature

**Double-entry ledger + CSV export.** Every eaten row is a debit against the day's kcal budget. The Ledger front page shows the running balance. The Statement scene lists the day with a balance column and exports a CSV folio through `UIActivityViewController`. Planner horizon is **14 days**. Petty Cash (snack) is eaten-only; a future date remaps it to Midday.

## How this app differs

BiteLedger is batch 21AUG app 02 of 30. It does not share source with the other apps. Naming is `BLG*`, organisation is by feature, persistence is raw `libsqlite3` (WAL, prepared statements), search is Open Food Facts `/api/v2/search` with an explicit fields list and `page_size=16`, and the day key is `yyyy-MM-dd`. The visual system is ledger paper (Georgia, cream and ink, hard edges), not a generic fitness kit.

## Build

```bash
cd App02_BiteLedger
/Users/belzephyrus/Documents/gambling/21AUG/tools/xcodegen/bin/xcodegen generate
xcodebuild -scheme BiteLedger -destination 'generic/platform=iOS' build
xcodebuild -scheme BiteLedger -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Requirements: iOS 17+, Swift 6.2, Xcode with iPhone SDK. SPM pulls [apple/swift-collections](https://github.com/apple/swift-collections) for `OrderedDictionary`. Bundle ID is `com.biteledger.ledger`. User-Agent: `BiteLedger/1.0 (iOS; +https://biteledger.pro)`.

## AI art

Style: vintage steel engraving / banknote etching.

Base prompt reused on every asset:

```
vintage steel engraving, banknote guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border
```

Exact prompts:

**blg_AppIcon** — 1024x1024  
`vintage steel engraving, banknote guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, the app's single emblem, centred, filling the canvas edge to edge`

**blg_Splash** — 1290x2796  
`vintage steel engraving, banknote guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a vertical hero composition with a calm, uncluttered centre band`

**blg_Onboarding1** — 1024x1536  
`vintage steel engraving, banknote guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a person or object representing discovering what is in packaged food`

**blg_Onboarding2** — 1024x1536  
`vintage steel engraving, banknote guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a scanning or measuring motif showing a product being identified`

**blg_Onboarding3** — 1024x1536  
`vintage steel engraving, banknote guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a goal or target motif showing daily progress being met`

**blg_EmptyLog** — 1024x1024  
`vintage steel engraving, banknote guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, an empty vessel, surface or container waiting to be filled`

**blg_EmptySearch** — 1024x1024  
`vintage steel engraving, banknote  guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a search motif that has come back with nothing found`

**blg_EmptyPlan** — 1024x1024  
`vintage steel engraving, banknote  guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, an empty schedule, grid or horizon with nothing scheduled`

**blg_EmptyWish** — 1024x1024  
`vintage steel engraving, banknote guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, an empty basket, list or shelf`

**blg_SlotOpeningEntry** — 512x512  
`vintage steel engraving, banknote guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a morning motif appropriate to the theme`

**blg_SlotMiddayEntry** — 512x512  
`vintage steel engraving, banknote  guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a midday motif appropriate to the theme`

**blg_SlotClosingEntry** — 512x512  
`vintage steel engraving, banknote  guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, an evening motif appropriate to the theme`

**blg_SlotPettyCash** — 512x512  
`vintage steel engraving, banknote  guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a small extra or in-between motif appropriate to the theme`

**blg_MacroProtein** — 512x512  
`vintage steel engraving, banknote  ​​guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a symbol standing for protein, rendered as a single clear emblem`

**blg_MacroCarbs** — 512x512  
`vintage steel engraving, banknote guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a symbol standing for carbohydrate, rendered as a single clear emblem`

**blg_MacroFat** — 512x512  
`vintage steel engraving, banknote  guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a symbol standing for dietary fat, rendered as a single clear emblem`

**blg_ProductPlaceholder** — 600x600  
`vintage steel engraving, banknote  ​guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a generic packaged grocery item with no readable branding`

**blg_CardBackdrop** — 1200x800  
`vintage steel engraving, banknote  ​guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, an abstract backdrop suitable for sitting behind a product card`

**blg_Texture** — 2048x2048  
`vintage steel engraving, banknote  ​guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a seamless repeating surface pattern`

**blg_ControlFace** — 512x512  
`vintage steel engraving, banknote  ​guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, the face of a single physical control such as a dial, key or slider handle`

**blg_ScanOverlay** — 1024x1024  
`vintage steel engraving, banknote  ​guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a framing reticle or targeting bracket, open in the middle`

**blg_TwistHero** — 1024x1024  
`vintage steel engraving, banknote  ​guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, an emblem representing this app's signature feature`

**blg_SuccessMark** — 512x512  
`vintage steel engraving, banknote  ​guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a confirmation mark or celebratory emblem`

**blg_HeaderDecor** — 1200x600  
`vintage steel engraving, banknote  ​guilloche etching, fine crosshatch linework, sepia ink on aged cream paper, ornate border, a wide decorative band or ornament`

The live camera overlay is a procedural UIKit path (`BLGScanLineView`), not the asset. `blg_Texture` is a seamless hatch generated so four tiles meet without a seam. The app icon is 1024×1024, opaque, no alpha channel.
