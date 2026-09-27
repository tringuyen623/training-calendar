import CoreText
import Foundation

/// Registers the bundled Open Sans files with CoreText. SwiftUI silently falls back to the
/// system font for a custom font name it can't find, so every font accessor goes through here.
enum FontRegistration {
    static let fileNames = ["OpenSans-Regular", "OpenSans-Bold"]

    static func registerIfNeeded() {
        _ = registered
    }

    private static let registered: Void = {
        for name in fileNames {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing font file \(name).ttf in the WeeklyWorkoutsUI bundle")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let code = error.map { CFErrorGetCode($0.takeRetainedValue()) }
                assert(code == CTFontManagerError.alreadyRegistered.rawValue, "Couldn't register \(name).ttf: \(String(describing: code))")
            }
            assert(isAvailable(name), "\(name) isn't available after registration; SwiftUI would fall back to the system font")
        }
    }()

    private static func isAvailable(_ postScriptName: String) -> Bool {
        let font = CTFontCreateWithName(postScriptName as CFString, 12, nil)
        return CTFontCopyPostScriptName(font) as String == postScriptName
    }
}
