//
//  DownloadsManagerTests.swift
//  DuckDuckGo
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
import WebKit

@testable import DuckDuckGo
import WidgetKit

class DownloadsManagerTests: XCTestCase {
    var mockDependencyProvider: MockDependencyProvider!
    
    override func setUp() {
    }
    
    override func tearDown() {
        DownloadTestsHelper.deleteAllFiles()
    }
    
    func testTemporaryPKPassDownload() {
        let notificationCenter = NotificationCenter()
        let downloadsManager = DownloadsManager(notificationCenter)
        
        let sessionSetup = MockSessionSetup(mimeType: "application/vnd.apple.pkpass", downloadsManager: downloadsManager)
        
        let download = downloadsManager.setupDownload(sessionSetup.response, downloadSession: sessionSetup.session)!
        XCTAssertTrue(download.temporary, "Download should be temporary")
        
        let expectation = expectation(description: "Download finish")
        
        notificationCenter.addObserver(forName: .downloadFinished, object: nil, queue: nil) { notification in
          
            if DownloadTestsHelper.downloadForNotification(notification) == download {
                let (tmpPath, finalPath) = DownloadTestsHelper.temporaryAndFinalPathForDownload(download)

                XCTAssertTrue(DownloadTestsHelper.checkIfFileExists(tmpPath), "File should exist")
                XCTAssertFalse(DownloadTestsHelper.checkIfFileExists(finalPath), "File should not exist")
                expectation.fulfill()
            }
        }
        
        downloadsManager.startDownload(download)
        wait(for: [expectation], timeout: 1)
    }
    
    func testTemporaryRealityDownload() {
        
        let notificationCenter = NotificationCenter()
        let downloadsManager = DownloadsManager(notificationCenter)

        let sessionSetup = MockSessionSetup(mimeType: "model/vnd.reality", downloadsManager: downloadsManager)
        
        let download = downloadsManager.setupDownload(sessionSetup.response, downloadSession: sessionSetup.session)!
        XCTAssertTrue(download.temporary, "Download should be temporary")
        
        let expectation = expectation(description: "Download finish")
        
        notificationCenter.addObserver(forName: .downloadFinished, object: nil, queue: nil) { notification in
           
            if DownloadTestsHelper.downloadForNotification(notification) == download {
                let (tmpPath, finalPath) = DownloadTestsHelper.temporaryAndFinalPathForDownload(download)

                XCTAssertTrue(DownloadTestsHelper.checkIfFileExists(tmpPath), "File should exist")
                XCTAssertFalse(DownloadTestsHelper.checkIfFileExists(finalPath), "File should not exist")
                expectation.fulfill()
            }
        }
        
        downloadsManager.startDownload(download)
        wait(for: [expectation], timeout: 1)
        
    }
    
    func testTemporaryUSDZDownload() {
        let notificationCenter = NotificationCenter()
        let downloadsManager = DownloadsManager(notificationCenter)

        let sessionSetup = MockSessionSetup(mimeType: "model/vnd.usdz+zip", downloadsManager: downloadsManager)
        
        let download = downloadsManager.setupDownload(sessionSetup.response, downloadSession: sessionSetup.session)!
        XCTAssertTrue(download.temporary, "Download should be temporary")
        
        let expectation = expectation(description: "Download finish")
        
        notificationCenter.addObserver(forName: .downloadFinished, object: nil, queue: nil) { notification in
            
            if DownloadTestsHelper.downloadForNotification(notification) == download {
                let (tmpPath, finalPath) = DownloadTestsHelper.temporaryAndFinalPathForDownload(download)

                XCTAssertTrue(DownloadTestsHelper.checkIfFileExists(tmpPath), "File should exist")
                XCTAssertFalse(DownloadTestsHelper.checkIfFileExists(finalPath), "File should not exist")
                expectation.fulfill()
            }
        }
        
        downloadsManager.startDownload(download)
        wait(for: [expectation], timeout: 1)
    }
    
    func testPermanentBinaryDownload() {
        let notificationCenter = NotificationCenter()
        let downloadsManager = DownloadsManager(notificationCenter)

        let sessionSetup = MockSessionSetup(mimeType: "application/octet-stream", downloadsManager: downloadsManager)
        
        let download = downloadsManager.setupDownload(sessionSetup.response, downloadSession: sessionSetup.session)!
        XCTAssertFalse(download.temporary, "download should not be temporary")
        
        let expectation = expectation(description: "Download finish")
        
        notificationCenter.addObserver(forName: .downloadFinished, object: nil, queue: nil) { notification in
           
            if DownloadTestsHelper.downloadForNotification(notification) == download {
                let (tmpPath, finalPath) = DownloadTestsHelper.temporaryAndFinalPathForDownload(download)

                XCTAssertFalse(DownloadTestsHelper.checkIfFileExists(tmpPath), "File should not exist")
                XCTAssertTrue(DownloadTestsHelper.checkIfFileExists(finalPath), "File should exist")
                expectation.fulfill()
            }
        }
        
        downloadsManager.startDownload(download)
        wait(for: [expectation], timeout: 1)
    }
    
    func testIfFinishedDownloadIsRemovedFromList() {
        let notificationCenter = NotificationCenter()
        let downloadsManager = DownloadsManager(notificationCenter)

        let sessionSetup = MockSessionSetup(mimeType: "application/octet-stream", downloadsManager: downloadsManager, completionDelay: 1)
        let download = downloadsManager.setupDownload(sessionSetup.response, downloadSession: sessionSetup.session)!
        let expectation = expectation(description: "Download finish")
        
        notificationCenter.addObserver(forName: .downloadFinished, object: nil, queue: nil) { notification in
           
            if DownloadTestsHelper.downloadForNotification(notification) == download {
                XCTAssertEqual(downloadsManager.downloadList.count, 0)
                expectation.fulfill()
            }
        }
        
        downloadsManager.startDownload(download)
        XCTAssertEqual(downloadsManager.downloadList.count, 1)

        wait(for: [expectation], timeout: 2)
    }
    
    func downloadForNotification(_ notification: Notification) -> Download {
        if let download = notification.userInfo?[DownloadsManager.UserInfoKeys.download] as? Download {
            return download
        }
        fatalError("Should only be used to test valid downloads")
    }
    
    func testRTLSanitizing() {
        let spoofedName = "test.‮gpj‬" // U+202E + U+202C character
        let expectedName = "test.gpj"
        let notificationCenter = NotificationCenter()
        let downloadsManager = DownloadsManager(notificationCenter)

        let sessionSetup = MockSessionSetup(mimeType: "application/octet-stream", downloadsManager: downloadsManager, filename: spoofedName)
        
        let download = downloadsManager.setupDownload(sessionSetup.response, downloadSession: sessionSetup.session)!
        
        let expectation = expectation(description: "Download finish")
        
        notificationCenter.addObserver(forName: .downloadFinished, object: nil, queue: nil) { notification in
           
            if DownloadTestsHelper.downloadForNotification(notification) == download {
                let (tmpPath, finalPath) = DownloadTestsHelper.temporaryAndFinalPathForDownload(download)
                
                XCTAssertFalse(DownloadTestsHelper.checkIfFileExists(tmpPath), "File should not exist")
                XCTAssertTrue(DownloadTestsHelper.checkIfFileExists(finalPath), "File should exist")
                XCTAssertEqual(expectedName, download.filename, "Names should be equal")
                expectation.fulfill()
            }
        }
        
        downloadsManager.startDownload(download)
        wait(for: [expectation], timeout: 1)
    }
}
