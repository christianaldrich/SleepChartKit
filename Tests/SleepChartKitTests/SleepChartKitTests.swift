import XCTest
@testable import SleepChartKit

final class SleepChartKitTests: XCTestCase {
    
    func testSleepSampleCreation() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(3600) // 1 hour
        let sample = SleepSample(stage: .asleepDeep, startDate: startDate, endDate: endDate)
        
        XCTAssertEqual(sample.stage, .asleepDeep)
        XCTAssertEqual(sample.startDate, startDate)
        XCTAssertEqual(sample.endDate, endDate)
        XCTAssertEqual(sample.duration, 3600)
    }
    
    func testSleepStageSortOrder() {
        let stages: [SleepStage] = [.asleepDeep, .awake, .asleepREM, .asleepCore]
        let sorted = stages.sorted { $0.sortOrder < $1.sortOrder }
        
        XCTAssertEqual(sorted, [.awake, .asleepREM, .asleepCore, .asleepDeep])
    }
}