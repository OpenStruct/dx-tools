import XCTest
@testable import DX_Tools

final class ErrorTrackerServiceTests: XCTestCase {
    func testParseJavaScript() {
        let log = """
        TypeError: Cannot read property 'name' of undefined
            at Object.<anonymous> (/app/index.js:42:15)
            at Module._compile (internal/modules/cjs/loader.js:999:30)
        """
        let errors = ErrorTrackerService.parseJavaScript(log)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0].type, "TypeError")
        XCTAssertTrue(errors[0].message.contains("name"))
        XCTAssertFalse(errors[0].stackTrace.isEmpty)
    }

    func testParsePython() {
        let log = """
        Traceback (most recent call last):
          File "app.py", line 42, in handler
            result = process(data)
        ValueError: invalid literal for int()
        """
        let errors = ErrorTrackerService.parsePython(log)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0].type, "ValueError")
        XCTAssertEqual(errors[0].source, .python)
    }

    func testParseSwift() {
        let log = "Fatal error: Unexpectedly found nil while unwrapping an Optional value: file MyApp/ViewModel.swift, line 42"
        let errors = ErrorTrackerService.parseSwift(log)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0].type, "Fatal error")
        XCTAssertEqual(errors[0].level, .fatal)
    }

    func testParseJava() {
        let log = """
        java.lang.NullPointerException: null
            at com.example.MyClass.doWork(MyClass.java:42)
            at com.example.Main.main(Main.java:10)
        """
        let errors = ErrorTrackerService.parseJava(log)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors[0].type.contains("NullPointerException"))
        XCTAssertEqual(errors[0].source, .java)
    }

    func testParseGo() {
        let log = """
        panic: runtime error: index out of range [3] with length 3

        goroutine 1 [running]:
        main.process(...)
            /app/main.go:42 +0x1a8
        """
        let errors = ErrorTrackerService.parseGo(log)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0].type, "panic")
        XCTAssertEqual(errors[0].source, .go)
    }

    func testParseGeneric() {
        let log = "2024-01-01 ERROR Something went wrong\n2024-01-01 WARN Low disk space"
        let errors = ErrorTrackerService.parseGeneric(log)
        XCTAssertEqual(errors.count, 2)
    }

    func testDetectSourceJS() {
        let text = "TypeError: x\n    at Object.<anonymous> (/app/index.js:1:1)"
        XCTAssertEqual(ErrorTrackerService.detectSource(text), .javascript)
    }

    func testDetectSourcePython() {
        let text = "Traceback (most recent call last):"
        XCTAssertEqual(ErrorTrackerService.detectSource(text), .python)
    }

    func testGrouping() {
        let e1 = ErrorTrackerService.ParsedError(type: "TypeError", message: "x", stackTrace: [], source: .javascript, level: .error, raw: "", fingerprint: "abc")
        let e2 = ErrorTrackerService.ParsedError(type: "TypeError", message: "x", stackTrace: [], source: .javascript, level: .error, raw: "", fingerprint: "abc")
        let groups = ErrorTrackerService.group([e1, e2])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].count, 2)
    }

    func testFingerprint() {
        let fp1 = ErrorTrackerService.computeFingerprint(type: "Error", message: "test", topFrame: nil)
        let fp2 = ErrorTrackerService.computeFingerprint(type: "Error", message: "test", topFrame: nil)
        XCTAssertEqual(fp1, fp2)
    }

    func testDifferentFingerprint() {
        let fp1 = ErrorTrackerService.computeFingerprint(type: "TypeError", message: "x", topFrame: nil)
        let fp2 = ErrorTrackerService.computeFingerprint(type: "ValueError", message: "y", topFrame: nil)
        XCTAssertNotEqual(fp1, fp2)
    }

    func testEmptyInput() {
        let errors = ErrorTrackerService.parse("")
        XCTAssertTrue(errors.isEmpty)
    }
}
