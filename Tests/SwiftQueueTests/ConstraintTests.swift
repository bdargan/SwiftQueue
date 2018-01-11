//
// Created by Lucas Nelaupe on 11/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import XCTest
@testable import SwiftQueue

class ConstraintTests: XCTestCase {

    func testPeriodicJob() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .periodic(count: 5)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 5)
        XCTAssertEqual(job.onCompleteCalled, 1)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 0)
    }

    func testRetryFailJobWithRetryConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .retry(delay: 0)

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(max: 2)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 2)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRetryFailJobWithRetryDelayConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .retry(delay: 0.1)

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(max: 2)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 2)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRetryFailJobWithCancelConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .cancel

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(max: 2)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 1)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRetryFailJobWithExponentialConstraint() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = .exponential(initial: 0)

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(max: 2)
                .schedule(manager: manager)

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 3)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 2)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testRepeatableJobWithExponentialBackoffRetry() {
        let job = TestJob()
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        job.result = JobError()
        job.retryConstraint = RetryConstraint.exponential(initial: 0.1)

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .retry(max: 1)
                .periodic()
                .schedule(manager: manager)

        job.await(TimeInterval(10))

        XCTAssertEqual(job.onRunJobCalled, 2)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 1)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testCancelRunningOperation() {
        let job = TestJob(10)
        let type = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .schedule(manager: manager)

        runInBackgroundAfter(0.1) {
            manager.cancelAllOperations()
        }

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)
    }

    func testCancelRunningOperationByTag() {
        let job = TestJob(10)
        let type = UUID().uuidString

        let tag = UUID().uuidString

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManager(creators: [creator])
        JobBuilder(type: type)
                .addTag(tag: tag)
                .schedule(manager: manager)

        runInBackgroundAfter(0.1) {
            manager.cancelOperations(tag: tag)
        }

        job.await()

        XCTAssertEqual(job.onRunJobCalled, 1)
        XCTAssertEqual(job.onCompleteCalled, 0)
        XCTAssertEqual(job.onRetryCalled, 0)
        XCTAssertEqual(job.onCancelCalled, 1)
    }
}
