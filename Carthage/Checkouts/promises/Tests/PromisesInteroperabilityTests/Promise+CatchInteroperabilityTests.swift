// Copyright 2018 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import FBLPromisesTestHelpers
import PromisesTestHelpers
import XCTest
@testable import Promises

class PromiseCatchInteroperabilityTests: XCTestCase {
  func testPromiseRejectNSError() {
    // Act.
    let promise = Promise(
      FBLPromisesTestInteroperabilityObjC<AnyObject>.reject(Test.Error.code42, delay: 0.1)
    )
    promise.catch { error in
      XCTAssertTrue(error == Test.Error.code42)
    }

    // Assert.
    XCTAssert(waitForPromises(timeout: 10))
    XCTAssertTrue(promise.isRejected)
    XCTAssertTrue(promise.error == Test.Error.code42)
    XCTAssertNil(promise.value)
  }
}
