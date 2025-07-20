# SleepChartKit

A clean, lightweight SwiftUI package for displaying beautiful sleep stage visualizations with comprehensive HealthKit integration.

## Features

- 📊 **Timeline Visualization** - Interactive sleep stage timeline with smooth stage transitions
- 🎨 **Customizable Colors** - Define your own color scheme for different sleep stages
- ⏰ **Time Axis** - Clear time labels showing sleep session duration
- 📋 **Legend** - Duration summary for each sleep stage
- 🏥 **HealthKit Integration** - Native support for `HKCategoryValueSleepAnalysis` data
- 🌍 **Localization Support** - Configurable display names for internationalization
- 🔧 **SOLID Architecture** - Clean, testable, and extensible design
- 📱 **Cross-Platform** - iOS 15+, macOS 12+, watchOS 8+, tvOS 15+

## Installation

### Swift Package Manager

Add SleepChartKit to your project via Xcode:

1. File → Add Package Dependencies
2. Enter: `https://github.com/yourusername/SleepChartKit`
3. Select version and add to target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/SleepChartKit", from: "1.0.0")
]
```

## Quick Start

### Basic Usage

```swift
import SwiftUI
import SleepChartKit

struct ContentView: View {
    let sleepSamples = [
        SleepSample(stage: .asleepDeep, startDate: date1, endDate: date2),
        SleepSample(stage: .asleepCore, startDate: date2, endDate: date3),
        SleepSample(stage: .asleepREM, startDate: date3, endDate: date4),
        SleepSample(stage: .awake, startDate: date4, endDate: date5)
    ]
    
    var body: some View {
        SleepChartView(samples: sleepSamples)
            .padding()
    }
}
```

### HealthKit Integration

```swift
import SwiftUI
import HealthKit
import SleepChartKit

@available(iOS 16.0, *)
struct HealthKitSleepView: View {
    @State private var healthKitSamples: [HKCategorySample] = []
    
    var body: some View {
        // Direct HealthKit integration
        SleepChartView(healthKitSamples: healthKitSamples)
            .padding()
            .onAppear {
                loadHealthKitData()
            }
    }
    
    private func loadHealthKitData() {
        // Your HealthKit data loading logic
        // healthKitSamples = fetchedSamples
    }
}
```

## Sleep Stages

SleepChartKit supports the following sleep stages:

- **Awake** - Periods of wakefulness
- **REM Sleep** - Rapid Eye Movement sleep
- **Light Sleep** - Core/light sleep stages
- **Deep Sleep** - Deep sleep stages
- **Unspecified Sleep** - General sleep periods
- **In Bed** - Time spent in bed (filtered when other stages present)

## Customization

### Custom Colors

```swift
struct MyColorProvider: SleepStageColorProvider {
    func color(for stage: SleepStage) -> Color {
        switch stage {
        case .awake: return .red
        case .asleepREM: return .purple
        case .asleepCore: return .blue
        case .asleepDeep: return .indigo
        case .asleepUnspecified: return .gray
        case .inBed: return .secondary
        }
    }
}

SleepChartView(
    samples: sleepSamples,
    colorProvider: MyColorProvider()
)
```

### Custom Display Names

```swift
// Using custom names
let customNameProvider = CustomSleepStageDisplayNameProvider(customNames: [
    .awake: "Awake",
    .asleepREM: "REM Sleep", 
    .asleepCore: "Light Sleep",
    .asleepDeep: "Deep Sleep",
    .asleepUnspecified: "Unknown Sleep",
    .inBed: "In Bed"
])

SleepChartView(
    samples: sleepSamples,
    displayNameProvider: customNameProvider
)
```

### Localization Support

```swift
// Using localized strings from your app's bundle
let localizedProvider = LocalizedSleepStageDisplayNameProvider(
    bundle: .main,
    tableName: "SleepStages"
)

SleepChartView(
    samples: sleepSamples,
    displayNameProvider: localizedProvider
)
```

Create a `SleepStages.strings` file:
```
"sleep_stage_awake" = "Awake";
"sleep_stage_asleepREM" = "REM Sleep";
"sleep_stage_asleepCore" = "Light Sleep";
"sleep_stage_asleepDeep" = "Deep Sleep";
"sleep_stage_asleepUnspecified" = "Sleep";
"sleep_stage_inBed" = "In Bed";
```

### Custom Duration Formatting

```swift
struct MyDurationFormatter: DurationFormatter {
    func format(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours):\(String(format: "%02d", minutes))"
    }
}

SleepChartView(
    samples: sleepSamples,
    durationFormatter: MyDurationFormatter()
)
```

### Complete Customization Example

```swift
@available(iOS 16.0, *)
SleepChartView(
    healthKitSamples: healthKitSamples,
    colorProvider: MyColorProvider(),
    durationFormatter: MyDurationFormatter(),
    displayNameProvider: LocalizedSleepStageDisplayNameProvider()
)
```

## Architecture

SleepChartKit follows SOLID principles with a clean, modular architecture:

### Core Components

- **SleepChartView** - Main chart container
- **SleepTimelineGraph** - Timeline visualization with Canvas
- **SleepTimeAxisView** - Time labels and axis
- **SleepLegendView** - Sleep stage legend

### Data Models

- **SleepSample** - Represents a sleep period
- **SleepStage** - Enum of sleep stages
- **TimeSpan** - Time axis labels

### Services (Protocols)

- **SleepStageColorProvider** - Stage color customization
- **SleepStageDisplayNameProvider** - Stage display name customization
- **DurationFormatter** - Duration text formatting
- **TimeSpanGenerator** - Time axis customization

## HealthKit Integration

SleepChartKit provides native support for HealthKit sleep analysis data with automatic conversion and type safety.

### Direct HealthKit Usage

```swift
import HealthKit
import SleepChartKit

@available(iOS 16.0, *)
func createChart(with healthKitSamples: [HKCategorySample]) -> some View {
    // Direct integration - automatically converts HealthKit samples
    SleepChartView(healthKitSamples: healthKitSamples)
}
```

### Manual Conversion

```swift
// Convert individual samples
let sleepSample = SleepSample(healthKitSample: hkSample)

// Batch convert samples
let sleepSamples = SleepSample.samples(from: healthKitSamples)

// Create chart with converted samples
SleepChartView(samples: sleepSamples)
```

### Working with SleepStage and HealthKit

```swift
// Convert between SleepStage and HKCategoryValueSleepAnalysis
let sleepStage = SleepStage(healthKitValue: .asleepREM) // Optional conversion
let healthKitValue = sleepStage.healthKitValue // Direct conversion

// Use with color providers
let color = colorProvider.color(for: .asleepREM) // HKCategoryValueSleepAnalysis
```

### Availability

HealthKit integration requires:
- iOS 16.0+ / macOS 13.0+ / watchOS 9.0+
- HealthKit framework available

## Requirements

- iOS 15.0+
- macOS 12.0+
- watchOS 8.0+
- tvOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

SleepChartKit is available under the MIT license. See the LICENSE file for more info.

## Example
<img width="1920" height="1080" alt="Shots Mockups (43)" src="https://github.com/user-attachments/assets/4bb626ef-51e0-40cb-ab10-220226abf814" />

*Sample sleep chart showing a night's sleep with deep sleep, REM, and wake periods.*
