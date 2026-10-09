# FakeCatcha

A native iOS app that screens Australian polymer banknotes ($5, $10, $20, $50 and $100, first-series and next-generation designs) for common signs of counterfeiting.

Built only with Apple frameworks: **SwiftUI, AVFoundation, Vision, Core Image, PhotosUI and UIKit**. It has no third-party packages, CocoaPods or Swift Package dependencies. All analysis runs on the device, and images are never uploaded.

> ⚠️ **FakeCatcha is a screening aid, not a certification tool.** It uses image heuristics and can be wrong in both directions. Always check the security features yourself, and follow the Reserve Bank of Australia's guidance: <https://banknotes.rba.gov.au/counterfeit-detection/>. If you think a note is counterfeit, contact your local police.

## Features

- Live camera scan (AVFoundation) with a banknote-shaped guide, or pick a photo from your library (PhotosPicker).
- Automatic note detection and perspective correction.
- Seven independent checks. Each one gives a **pass / warning / fail** result with an explanation.
- A weighted 0–100 confidence score and an overall verdict.
- An "How it works" screen covering each check and the RBA's feel / look / tilt guidance.

## How it works

| # | Check | Frameworks | What it does |
|---|-------|------------|--------------|
| 1 | **Note outline** | Vision `VNDetectRectanglesRequest`, Core Image `CIPerspectiveCorrection` | Finds the note's four corners, flattens the note and rotates it to landscape. If no outline is found but the photo itself has banknote proportions, it assumes the photo is already cropped. |
| 2 | **Size / aspect ratio** | – | Compares the flattened width:height ratio with the official RBA sizes (65 mm tall; 130 / 137 / 144 / 151 / 158 mm wide). Within 4% passes, within 8% is a warning, anything further off fails. |
| 3 | **Denomination consistency** | Vision `VNRecognizeTextRequest` | Reads the printed numerals and words (e.g. "50", "FIFTY") and compares them with the note's dominant colour. If the value and colour disagree, the check fails. |
| 4 | **Serial number format** | Vision OCR | Looks for `LL YY NNNNNN(N)`: two letters, a two-digit year of printing, then 6 digits (first series) or 7 digits (later printings), e.g. `AA 23 1234567`. It corrects common OCR confusions (O↔0, B↔8, I/L↔1…) and flags impossible years, all-zero numbers and unusual prefixes. |
| 5 | **Clear window** | Core Image to bitmap, grid statistics | Divides the note into a 16×8 grid and looks for cells that don't look like printed polymer (very different colour, and low saturation or low texture). A top-to-bottom band means a next-generation window. A small cluster means a first-series window. |
| 6 | **Colour profile** | Core Image to bitmap, HSV histogram | Measures what share of the saturated pixels fall in the expected hue range for that denomination ($5 mauve, $10 blue, $20 red/orange, $50 yellow, $100 green). It also flags washed-out, photocopy-like colour. |
| 7 | **Print sharpness** | Laplacian variance | Rough measure of fine line work. This check only ever warns, because a blurry photo looks the same as blurry print. |

The score is a weighted average (pass = 1, warning = 0.5, fail = 0; skipped checks are left out):

- **No obvious red flags**: score ≥ 80 and no failures
- **Inconclusive**: score 55–79, or exactly one failure
- **Suspicious**: score < 55, or two or more failures
- **Couldn't read the note**: no note outline found

## Limitations (please read)

- **This is not a counterfeit detector in the forensic sense.** A phone camera can't sense polymer texture, raised intaglio print, UV features or the tilt effects in the window. Those are the features the RBA relies on. A good counterfeit can pass every check here, and a worn genuine note in bad light can fail some.
- The thresholds are hand-tuned estimates. They haven't been calibrated against a dataset of genuine and counterfeit notes.
- Colour checks depend on lighting and white balance. Use even, white light.
- Aspect ratio is affected by camera angle. Hold the phone parallel to the note.
- The clear-window check needs a plain background that contrasts with the note.
- Serial numbers are printed on only one side, so scan both sides.
- The serial check validates the **format** only. It does not query the RBA's (incomplete) serial range tables.

## Project layout

```
FakeCatcha.xcodeproj
FakeCatcha/
  FakeCatchaApp.swift
  Models/        Denomination, CheckResult, AnalysisReport, SerialNumber
  Services/      CameraService, NoteAnalyzer, NoteDetector, TextRecognizer,
                 ColourAnalysis, SerialNumberParser, ScoreCalculator, AnalysisContext
    Checks/      NoteDetection, AspectRatio, Denomination, SerialNumber,
                 ClearWindow, ColourProfile, PrintSharpness
  Views/         ContentView, ScannerView, CameraPreviewView, AnalysisView,
                 ResultView, AboutView, DisclaimerView
  Utilities/     ImageUtilities, PixelSample (+ ColourMath)
  Assets.xcassets
FakeCatchaTests/ Unit tests for serial parsing, denominations, scoring, window classification
```

## Build & run

Requirements: **Xcode 15 or later**, iOS 17+ device (the camera features need a real iPhone or iPad).

1. `git clone https://github.com/ashishsin19/fakecatcha.git`
2. Open `FakeCatcha.xcodeproj` in Xcode.
3. Select the **FakeCatcha** target, go to **Signing & Capabilities**, and choose your **Team**. If the bundle identifier `com.ashishsin19.fakecatcha` is taken, change it.
4. Choose your connected iPhone as the run destination and press **⌘R**. The first time you run it, trust the developer certificate on the device under *Settings → General → VPN & Device Management*.
5. Run the unit tests with **⌘U**. They also run in the simulator.

The simulator has no camera, but you can use **Choose from Photos** there with a photo dragged into the simulator.

## Privacy

The camera and photo library are used only to analyse the image you capture or pick. Processing happens entirely on the device using Apple's Vision and Core Image frameworks. Nothing is stored or sent anywhere.

## License

MIT. See [LICENSE](LICENSE). Banknote specifications are from the Reserve Bank of Australia. This project is not affiliated with or endorsed by the RBA.
