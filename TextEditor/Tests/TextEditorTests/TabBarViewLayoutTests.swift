import CoreGraphics
import Testing
@testable import TextEditor

@Suite("TabBarViewLayout")
struct TabBarViewLayoutTests {
    @Test("All tabs fit without overflow button")
    func allFitNoOverflowButton() {
        let result = TabBarViewLayout.computeVisibleAndOverflowIndices(
            availableWidth: 400,
            tabWidths: [90, 80, 70],
            addButtonWidth: 34,
            overflowButtonWidth: 36
        )

        #expect(result.visibleIndices == [0, 1, 2])
        #expect(result.overflowIndices.isEmpty)
    }

    @Test("Threshold crossing applies overflow button width")
    func thresholdCrossingWithOverflowButton() {
        let result = TabBarViewLayout.computeVisibleAndOverflowIndices(
            availableWidth: 300,
            tabWidths: [80, 80, 80, 50],
            addButtonWidth: 30,
            overflowButtonWidth: 40
        )

        #expect(result.visibleIndices == [0, 1])
        #expect(result.overflowIndices == [2, 3])
    }

    @Test("Exact fit does not overflow")
    func exactFit() {
        let result = TabBarViewLayout.computeVisibleAndOverflowIndices(
            availableWidth: 344,
            tabWidths: [100, 120, 90],
            addButtonWidth: 34,
            overflowButtonWidth: 36
        )

        #expect(result.visibleIndices == [0, 1, 2])
        #expect(result.overflowIndices.isEmpty)
    }

    @Test("Visible and overflow preserve input order")
    func orderPreserved() {
        let result = TabBarViewLayout.computeVisibleAndOverflowIndices(
            availableWidth: 300,
            tabWidths: [60, 110, 70, 95],
            addButtonWidth: 30,
            overflowButtonWidth: 35
        )

        #expect(result.visibleIndices == [0, 1])
        #expect(result.overflowIndices == [2, 3])
        #expect(result.visibleIndices + result.overflowIndices == [0, 1, 2, 3])
    }

    @Test("Visible set shrinks progressively with width")
    func progressiveShrink() {
        let tabWidths: [CGFloat] = [90, 90, 90]
        let widths: [CGFloat] = [340, 300, 299, 210]

        let results = widths.map {
            TabBarViewLayout.computeVisibleAndOverflowIndices(
                availableWidth: $0,
                tabWidths: tabWidths,
                addButtonWidth: 30,
                overflowButtonWidth: 40
            )
        }

        let visibleCounts = results.map { $0.visibleIndices.count }
        #expect(visibleCounts == [3, 3, 2, 1])

        for result in results {
            #expect(result.visibleIndices + result.overflowIndices == [0, 1, 2])
        }
    }
}
