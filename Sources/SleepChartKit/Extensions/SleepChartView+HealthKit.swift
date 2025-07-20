#if canImport(HealthKit)
import SwiftUI
import HealthKit

@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
public extension SleepChartView {
    /// Convenience initializer for HealthKit sleep samples
    init(
        healthKitSamples: [HKCategorySample],
        colorProvider: SleepStageColorProvider = DefaultSleepStageColorProvider(),
        durationFormatter: DurationFormatter = DefaultDurationFormatter(),
        timeSpanGenerator: TimeSpanGenerator = DefaultTimeSpanGenerator(),
        displayNameProvider: SleepStageDisplayNameProvider = DefaultSleepStageDisplayNameProvider()
    ) {
        let sleepSamples = SleepSample.samples(from: healthKitSamples)
        self.init(
            samples: sleepSamples,
            colorProvider: colorProvider,
            durationFormatter: durationFormatter,
            timeSpanGenerator: timeSpanGenerator,
            displayNameProvider: displayNameProvider
        )
    }
}
#endif