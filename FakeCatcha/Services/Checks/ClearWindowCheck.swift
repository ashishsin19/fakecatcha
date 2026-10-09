import Foundation

/// Heuristic search for the transparent polymer window.
///
/// The note is divided into a grid. Cells that look unlike the printed polymer
/// (very different colour from the note's median, and either much less saturated
/// or much less textured) are window candidates, because through the window you
/// see the background instead of ink.
///
/// * Next-generation notes have a window running top to bottom → a vertical band of candidates.
/// * First-series notes have a small window → a compact cluster of candidates.
struct ClearWindowCheck: NoteCheck {
    let kind = CheckKind.clearWindow

    static let columns = 16
    static let rows = 8

    struct Cell {
        let colour: (r: Double, g: Double, b: Double)
        let saturation: Double
        let edgeEnergy: Double
    }

    enum Finding: Equatable {
        case verticalBand(columns: Int)
        case smallWindow(cells: Int)
        case tooUneven
        case notFound
    }

    func evaluate(_ context: AnalysisContext, denomination: Denomination?) -> CheckResult {
        guard context.noteBoundsKnown, let sample = context.sample else {
            return CheckResult(kind, .skipped, summary: "Note outline not available.")
        }
        let cells = ClearWindowCheck.cells(from: sample)
        let candidates = ClearWindowCheck.candidateMask(for: cells)
        let finding = ClearWindowCheck.classify(candidates)

        switch finding {
        case .verticalBand(let columns):
            return CheckResult(kind, .pass,
                               summary: "Found a top-to-bottom window region (next-generation design).",
                               detail: "Band about \(columns) grid column(s) wide. Still check by hand: the window should be clear, with the printed features inside it changing as you tilt the note.")
        case .smallWindow(let count):
            return CheckResult(kind, .pass,
                               summary: "Found a small window-like region (first-series design).",
                               detail: "\(count) grid cell(s) differ from the printed polymer. Check by hand that it is actually transparent and contains an embossed/printed image.")
        case .tooUneven:
            return CheckResult(kind, .warn,
                               summary: "Lighting or background too uneven to locate the window.",
                               detail: "Use even light and a plain background of a different colour from the note.")
        case .notFound:
            return CheckResult(kind, .warn,
                               summary: "Couldn't find a clear window.",
                               detail: "Place the note on a plain background that contrasts with the note colour so the window shows through. Every genuine Australian polymer note has a clear window – paper or plastic-film copies often don't.")
        }
    }

    static func cells(from sample: PixelSample) -> [[Cell]] {
        let luma = sample.lumaBuffer()
        var grid: [[Cell]] = []
        for row in 0..<rows {
            var line: [Cell] = []
            let y0 = row * sample.height / rows
            let y1 = max(y0 + 1, (row + 1) * sample.height / rows)
            for column in 0..<columns {
                let x0 = column * sample.width / columns
                let x1 = max(x0 + 1, (column + 1) * sample.width / columns)
                var r = 0.0, g = 0.0, b = 0.0, sat = 0.0, edge = 0.0
                var count = 0.0
                for y in y0..<min(y1, sample.height) {
                    for x in x0..<min(x1, sample.width) {
                        let c = sample.rgb(x: x, y: y)
                        r += c.r; g += c.g; b += c.b
                        sat += ColourMath.hsv(r: c.r, g: c.g, b: c.b).s
                        let here = luma[y * sample.width + x]
                        if x + 1 < sample.width { edge += abs(luma[y * sample.width + x + 1] - here) }
                        if y + 1 < sample.height { edge += abs(luma[(y + 1) * sample.width + x] - here) }
                        count += 1
                    }
                }
                let n = max(count, 1)
                line.append(Cell(colour: (r / n, g / n, b / n), saturation: sat / n, edgeEnergy: edge / n))
            }
            grid.append(line)
        }
        return grid
    }

    static func candidateMask(for grid: [[Cell]]) -> [[Bool]] {
        let all = grid.flatMap { $0 }
        guard !all.isEmpty else { return [] }
        let median = (r: ColourMath.median(all.map { $0.colour.r }),
                      g: ColourMath.median(all.map { $0.colour.g }),
                      b: ColourMath.median(all.map { $0.colour.b }))
        let medianSaturation = ColourMath.median(all.map { $0.saturation })
        let medianEdge = ColourMath.median(all.map { $0.edgeEnergy })

        return grid.map { line in
            line.map { cell in
                let distance = ColourMath.distance(cell.colour, median)
                let lowSaturation = cell.saturation < max(0.10, medianSaturation * 0.7)
                let lowTexture = cell.edgeEnergy < medianEdge * 0.6
                return (distance > 0.20 && (lowSaturation || lowTexture)) || distance > 0.35
            }
        }
    }

    static func classify(_ mask: [[Bool]]) -> Finding {
        let rows = mask.count
        guard rows > 2, let columns = mask.first?.count, columns > 2 else { return .notFound }

        let total = mask.flatMap { $0 }.filter { $0 }.count
        if Double(total) > Double(rows * columns) * 0.40 { return .tooUneven }

        // Vertical band: an interior column where most interior rows are candidates.
        let interiorRows = 1..<(rows - 1)
        var bandColumns = 0
        for column in 1..<(columns - 1) {
            let hits = interiorRows.filter { mask[$0][column] }.count
            if Double(hits) >= Double(interiorRows.count) * 0.6 { bandColumns += 1 }
        }
        if (1...5).contains(bandColumns) { return .verticalBand(columns: bandColumns) }

        // Small window: a connected cluster of 2-12 interior candidate cells.
        var visited = Array(repeating: Array(repeating: false, count: columns), count: rows)
        var bestCluster = 0
        for row in 1..<(rows - 1) {
            for column in 1..<(columns - 1) where mask[row][column] && !visited[row][column] {
                var stack = [(row, column)]
                visited[row][column] = true
                var size = 0
                while let next = stack.popLast() {
                    let (r, c) = next
                    size += 1
                    for (dr, dc) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                        let nr = r + dr, nc = c + dc
                        guard nr >= 1, nr < rows - 1, nc >= 1, nc < columns - 1,
                              mask[nr][nc], !visited[nr][nc] else { continue }
                        visited[nr][nc] = true
                        stack.append((nr, nc))
                    }
                }
                if (2...12).contains(size) { bestCluster = max(bestCluster, size) }
            }
        }
        if bestCluster > 0 { return .smallWindow(cells: bestCluster) }
        return .notFound
    }
}
