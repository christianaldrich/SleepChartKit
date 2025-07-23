import SwiftUI

/// A SwiftUI view that displays sleep data as a circular chart with color-coded sleep stages.
///
/// The chart displays sleep stages as arc segments around a circle, with each segment's
/// size proportional to the time spent in that sleep stage. The chart includes customizable
/// colors and styling options.
///
/// ## Usage
/// ```swift
/// // Basic usage with sleep samples
/// SleepCircularChartView(samples: sleepSamples)
///
/// // With custom styling
/// SleepCircularChartView(
///     samples: sleepSamples,
///     colorProvider: customColorProvider,
///     lineWidth: 20,
///     size: 200
/// )
/// ```
public struct SleepCircularChartView: View {
    
    // MARK: - Properties
    
    /// The sleep samples to display in the chart
    private let samples: [SleepSample]
    
    /// Provider for sleep stage colors
    private let colorProvider: SleepStageColorProvider
    
    /// Width of the circular segments
    private let lineWidth: CGFloat
    
    /// Size of the circular chart
    private let size: CGFloat
    
    /// Background color of the chart
    private let backgroundColor: Color
    
    /// Whether to show labels inside the circle
    private let showLabels: Bool
    
    // MARK: - Initialization
    
    /// Creates a new circular sleep chart view with the specified configuration.
    ///
    /// - Parameters:
    ///   - samples: The sleep samples to display
    ///   - colorProvider: Provider for sleep stage colors (default: DefaultSleepStageColorProvider)
    ///   - lineWidth: Width of the circular segments (default: 16)
    ///   - size: Size of the circular chart (default: 160)
    ///   - backgroundColor: Background color of the chart (default: clear)
    ///   - showLabels: Whether to show time labels (default: true)
    public init(
        samples: [SleepSample],
        colorProvider: SleepStageColorProvider = DefaultSleepStageColorProvider(),
        lineWidth: CGFloat = 16,
        size: CGFloat = 160,
        backgroundColor: Color = .clear,
        showLabels: Bool = true
    ) {
        self.samples = samples
        self.colorProvider = colorProvider
        self.lineWidth = lineWidth
        self.size = size
        self.backgroundColor = backgroundColor
        self.showLabels = showLabels
    }
    
    // MARK: - Computed Properties
    
    /// Total duration of all sleep samples
    private var totalDuration: TimeInterval {
        samples.reduce(0) { $0 + $1.duration }
    }
    
    /// Sleep start and end times for the entire sleep session
    private var sleepPeriod: (start: Date, end: Date)? {
        guard let firstSample = samples.first, let lastSample = samples.last else { return nil }
        return (start: firstSample.startDate, end: lastSample.endDate)
    }
    
    /// Sleep segments with calculated angles for 24-hour circular rendering
    private var sleepSegments: [SleepSegment] {
        guard let sleepPeriod = sleepPeriod else { return [] }
        
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: sleepPeriod.start)
        
        var segments: [SleepSegment] = []
        
        for sample in samples {
            let startOffset = sample.startDate.timeIntervalSince(dayStart)
            let endOffset = sample.endDate.timeIntervalSince(dayStart)
            
            // Convert time to angles (24 hours = 360 degrees, starting at top = -90)
            let startAngle = (startOffset / (24 * 3600)) * 360 - 90
            let endAngle = (endOffset / (24 * 3600)) * 360 - 90
            
            segments.append(SleepSegment(
                stage: sample.stage,
                startAngle: startAngle,
                endAngle: endAngle,
                duration: sample.duration,
                startDate: sample.startDate,
                endDate: sample.endDate
            ))
        }
        
        return segments
    }
    
    /// Gray background segments for non-sleep periods in the 24-hour circle
    private var backgroundSegments: [BackgroundSegment] {
        guard let sleepPeriod = sleepPeriod else { return [] }
        
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: sleepPeriod.start)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        var backgroundSegs: [BackgroundSegment] = []
        
        // Before sleep period
        if sleepPeriod.start > dayStart {
            let startOffset = dayStart.timeIntervalSince(dayStart)
            let endOffset = sleepPeriod.start.timeIntervalSince(dayStart)
            
            let startAngle = (startOffset / (24 * 3600)) * 360 - 90
            let endAngle = (endOffset / (24 * 3600)) * 360 - 90
            
            backgroundSegs.append(BackgroundSegment(
                startAngle: startAngle,
                endAngle: endAngle
            ))
        }
        
        // After sleep period
        if sleepPeriod.end < dayEnd {
            let startOffset = sleepPeriod.end.timeIntervalSince(dayStart)
            let endOffset = dayEnd.timeIntervalSince(dayStart)
            
            let startAngle = (startOffset / (24 * 3600)) * 360 - 90
            let endAngle = (endOffset / (24 * 3600)) * 360 - 90
            
            backgroundSegs.append(BackgroundSegment(
                startAngle: startAngle,
                endAngle: endAngle
            ))
        }
        
        return backgroundSegs
    }
    
    /// Start time for label display
    private var startTime: String? {
        samples.first?.startDate.formatted(date: .omitted, time: .shortened)
    }
    
    /// End time for label display
    private var endTime: String? {
        samples.last?.endDate.formatted(date: .omitted, time: .shortened)
    }
    
    /// Total sleep duration formatted
    private var totalSleepDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            backgroundColor
            
            // Circular chart segments using Canvas for better control
            Canvas { context, canvasSize in
                drawCircularChart(context: context, canvasSize: canvasSize)
            }
            
            // Sun and moon symbols
            if let sleepPeriod = sleepPeriod {
                sleepStartEndSymbols(sleepPeriod: sleepPeriod)
            }
            
            // Center content
            if showLabels {
                VStack(spacing: 4) {
                    Text(totalSleepDuration)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let startTime = startTime, let endTime = endTime {
                        Text("\(startTime) - \(endTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(width: size + 32, height: size + 32)
    }
    
    // MARK: - Symbol Views
    
    /// Sun and moon symbols positioned on top of the colored segments within the chart
    @ViewBuilder
    private func sleepStartEndSymbols(sleepPeriod: (start: Date, end: Date)) -> some View {
        if let firstSegment = sleepSegments.first,
           let lastSegment = sleepSegments.last {
            
            // Position symbols very close to the start and end points (minimal padding)
            let paddingDegrees: Double = 2
            let firstSymbolAngle = firstSegment.startAngle + paddingDegrees
            let lastSymbolAngle = lastSegment.endAngle - paddingDegrees
            
            // Position symbols on the inner ring segments
            let outerRadius = size / 2
            let outerRingRadius = outerRadius - (lineWidth * 0.6)
            let innerRingRadius = outerRingRadius
            let symbolOffset = innerRingRadius
            
            // Moon symbol with consistent padding from start
            Image(systemName: "moon.fill")
                .foregroundColor(.white)
                .font(.caption2)
                .offset(
                    x: symbolOffset * cos(firstSymbolAngle * .pi / 180),
                    y: symbolOffset * sin(firstSymbolAngle * .pi / 180)
                )
            
            // Sun symbol with consistent padding from end
            Image(systemName: "sun.max.fill")
                .foregroundColor(.white)
                .font(.caption2)
                .offset(
                    x: symbolOffset * cos(lastSymbolAngle * .pi / 180),
                    y: symbolOffset * sin(lastSymbolAngle * .pi / 180)
                )
        }
    }
    
    // MARK: - Drawing Methods
    
    /// Draws the circular chart using Canvas for precise control
    private func drawCircularChart(context: GraphicsContext, canvasSize: CGSize) {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        // Calculate radii for concentric rings design
        let outerRadius = size / 2
        let outerRingRadius = outerRadius - (lineWidth * 0.6) // Outer background ring position
        let outerRingStrokeWidth = lineWidth * 1.5 // Outer ring stroke width
        let innerRingRadius = outerRingRadius // Inner ring centered on outer ring stroke
        
        // Draw outer background ring (complete circle) FIRST
        let outerRingPath = Path { path in
            path.addArc(
                center: center,
                radius: outerRingRadius,
                startAngle: Angle.degrees(0),
                endAngle: Angle.degrees(360),
                clockwise: false
            )
        }
        
        context.stroke(
            outerRingPath,
            with: .color(Color.gray.opacity(0.2)),
            style: StrokeStyle(
                lineWidth: outerRingStrokeWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
        
        // Draw gray background segments for non-sleep periods on inner ring (ON TOP)
        for backgroundSegment in backgroundSegments {
            let startAngle = Angle.degrees(backgroundSegment.startAngle)
            let endAngle = Angle.degrees(backgroundSegment.endAngle)
            
            var path = Path()
            path.addArc(
                center: center,
                radius: innerRingRadius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            
            context.stroke(
                path,
                with: .color(Color.gray.opacity(0.2)),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .butt,
                    lineJoin: .miter
                )
            )
        }
        
        // Draw sleep stage segments on inner ring
        for segment in sleepSegments {
            let startAngle = Angle.degrees(segment.startAngle)
            let endAngle = Angle.degrees(segment.endAngle)
            let segmentColor = colorProvider.color(for: segment.stage)
            
            // Create path for the arc segment on inner ring
            var path = Path()
            path.addArc(
                center: center,
                radius: innerRingRadius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            
            // Stroke segments on inner ring with straight caps
            context.stroke(
                path,
                with: .color(segmentColor),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .butt,
                    lineJoin: .miter
                )
            )
        }
        
        // Add custom rounded caps for inner ring segments
        if let firstSegment = sleepSegments.first,
           let lastSegment = sleepSegments.last {
            
            let firstStartAngle = Angle.degrees(firstSegment.startAngle)
            let lastEndAngle = Angle.degrees(lastSegment.endAngle)
            
            // Calculate positions for the inner ring caps
            let firstStartX = center.x + innerRingRadius * cos(CGFloat(firstStartAngle.radians))
            let firstStartY = center.y + innerRingRadius * sin(CGFloat(firstStartAngle.radians))
            let lastEndX = center.x + innerRingRadius * cos(CGFloat(lastEndAngle.radians))
            let lastEndY = center.y + innerRingRadius * sin(CGFloat(lastEndAngle.radians))
            
            // Draw semicircle cap at start of inner ring
            let startCapColor = colorProvider.color(for: firstSegment.stage)
            let startCapPath = Path { path in
                let innerCapRadius = innerRingRadius - lineWidth / 2
                
                let innerX = center.x + innerCapRadius * cos(CGFloat(firstStartAngle.radians))
                let innerY = center.y + innerCapRadius * sin(CGFloat(firstStartAngle.radians))
                
                // Draw semicircle cap for inner ring
                path.move(to: CGPoint(x: innerX, y: innerY))
                path.addArc(
                    center: CGPoint(x: firstStartX, y: firstStartY),
                    radius: lineWidth / 2,
                    startAngle: firstStartAngle + Angle.degrees(180),
                    endAngle: firstStartAngle,
                    clockwise: false
                )
                path.addLine(to: CGPoint(x: innerX, y: innerY))
            }
            context.fill(startCapPath, with: .color(startCapColor))
            
            // Draw semicircle cap at end of inner ring
            let endCapColor = colorProvider.color(for: lastSegment.stage)
            let endCapPath = Path { path in
                let innerCapRadius = innerRingRadius - lineWidth / 2
                
                let innerX = center.x + innerCapRadius * cos(CGFloat(lastEndAngle.radians))
                let innerY = center.y + innerCapRadius * sin(CGFloat(lastEndAngle.radians))
                
                // Draw semicircle cap for inner ring
                path.move(to: CGPoint(x: innerX, y: innerY))
                path.addArc(
                    center: CGPoint(x: lastEndX, y: lastEndY),
                    radius: lineWidth / 2,
                    startAngle: lastEndAngle,
                    endAngle: lastEndAngle + Angle.degrees(180),
                    clockwise: false
                )
                path.addLine(to: CGPoint(x: innerX, y: innerY))
            }
            context.fill(endCapPath, with: .color(endCapColor))
        }
    }
}

// MARK: - Supporting Types

/// Represents a segment of the circular sleep chart
private struct SleepSegment {
    let id = UUID()
    let stage: SleepStage
    let startAngle: Double
    let endAngle: Double
    let duration: TimeInterval
    let startDate: Date
    let endDate: Date
}

/// Represents a background segment for non-sleep periods
private struct BackgroundSegment {
    let id = UUID()
    let startAngle: Double
    let endAngle: Double
}

// MARK: - Preview

#if DEBUG
struct SleepCircularChartView_Previews: PreviewProvider {
    static var previews: some View {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .hour, value: 22, to: baseDate)!
        
        let samples = [
            SleepSample(stage: .inBed, startDate: startDate, endDate: calendar.date(byAdding: .minute, value: 15, to: startDate)!),
            SleepSample(stage: .asleepCore, startDate: calendar.date(byAdding: .minute, value: 15, to: startDate)!, endDate: calendar.date(byAdding: .hour, value: 2, to: startDate)!),
            SleepSample(stage: .asleepDeep, startDate: calendar.date(byAdding: .hour, value: 2, to: startDate)!, endDate: calendar.date(byAdding: .hour, value: 4, to: startDate)!),
            SleepSample(stage: .asleepREM, startDate: calendar.date(byAdding: .hour, value: 4, to: startDate)!, endDate: calendar.date(byAdding: .hour, value: 6, to: startDate)!),
            SleepSample(stage: .awake, startDate: calendar.date(byAdding: .hour, value: 6, to: startDate)!, endDate: calendar.date(byAdding: .hour, value: 6, to: startDate)!.addingTimeInterval(600)),
            SleepSample(stage: .asleepCore, startDate: calendar.date(byAdding: .hour, value: 6, to: startDate)!.addingTimeInterval(600), endDate: calendar.date(byAdding: .hour, value: 8, to: startDate)!)
        ]
        
        VStack(spacing: 40) {
            SleepCircularChartView(samples: samples)
            
            SleepCircularChartView(
                samples: samples,
                lineWidth: 20,
                size: 200
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
