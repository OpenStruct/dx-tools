import XCTest
@testable import DX_Tools

final class UnixPermServiceTests: XCTestCase {
    func testFromNumeric755() {
        let p = UnixPermService.fromNumeric("755")!
        XCTAssertEqual(p.symbolic, "rwxr-xr-x")
        XCTAssertEqual(p.numeric, "755")
        XCTAssertEqual(p.lsFormat, "-rwxr-xr-x")
        XCTAssertEqual(p.command, "chmod 755 <file>")
    }
    func testFromNumeric644() {
        let p = UnixPermService.fromNumeric("644")!
        XCTAssertEqual(p.symbolic, "rw-r--r--")
        XCTAssertEqual(p.ownerDesc, "Read, Write")
        XCTAssertEqual(p.groupDesc, "Read")
    }
    func testFromNumeric000() {
        let p = UnixPermService.fromNumeric("000")!
        XCTAssertEqual(p.symbolic, "---------")
        XCTAssertEqual(p.ownerDesc, "None")
    }
    func testFromNumeric777() {
        let p = UnixPermService.fromNumeric("777")!
        XCTAssertEqual(p.symbolic, "rwxrwxrwx")
    }
    func testFromSymbolic() {
        let p = UnixPermService.fromSymbolic("rwxr-xr-x")!
        XCTAssertEqual(p.numeric, "755")
    }
    func testFromSymbolicWithPrefix() {
        let p = UnixPermService.fromSymbolic("-rw-r--r--")!
        XCTAssertEqual(p.numeric, "644")
    }
    func testFromNumericInvalid() {
        XCTAssertNil(UnixPermService.fromNumeric("999"))
        XCTAssertNil(UnixPermService.fromNumeric("abc"))
        XCTAssertNil(UnixPermService.fromNumeric(""))
    }
    func testSetuid() {
        let p = UnixPermService.fromNumeric("4755")!
        XCTAssertTrue(p.isSetuid)
        XCTAssertTrue(p.owner.contains("s"))
    }
    func testSticky() {
        let p = UnixPermService.fromNumeric("1777")!
        XCTAssertTrue(p.isSticky)
        XCTAssertTrue(p.others.contains("t"))
    }
    func testRoundTrip() {
        let p1 = UnixPermService.fromNumeric("750")!
        let p2 = UnixPermService.fromSymbolic(p1.symbolic)!
        XCTAssertEqual(p2.numeric, "750")
    }
}
