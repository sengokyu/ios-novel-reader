import XCTest

func novelTopHTML(file: StaticString = #file) throws -> String {
    try loadFixture("novel_top", file: file)
}

func episodeHTML(file: StaticString = #file) throws -> String {
    try loadFixture("episode", file: file)
}

private func loadFixture(_ name: String, file: StaticString) throws -> String {
    let bundle = Bundle(for: FixtureBundleLocator.self)
    guard let url = bundle.url(forResource: name, withExtension: "html", subdirectory: "Fixtures") else {
        XCTFail("Fixture not found: \(name).html", file: file)
        throw CocoaError(.fileNoSuchFile)
    }
    return try String(contentsOf: url, encoding: .utf8)
}

final class FixtureBundleLocator {}
