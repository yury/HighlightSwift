import OSLog
import JavaScriptCore

public class Highlight {
    private var hljs: JSValue
    private static let shared = Highlight()
  
    init() {
      let context = JSContext()!
      let highlightFilePath = Bundle.module.path(forResource: "highlight.min", ofType: "js")!
      let highlightScript = try! String(contentsOfFile: highlightFilePath)
      context.evaluateScript(highlightScript)
      self.hljs = context.objectForKeyedSubscript("hljs")!
    }
    
    /// Attempts to syntax highlight the specified text.
    /// - Parameters:
    ///   - text: The plain text code to highlight.
    ///   - language: The language to use (default: automatic).
    ///   - style: The highlight color style to use (default: .xcode/.light).
    /// - Throws: Either a HighlightError or an Error.
    /// - Returns: The result of the syntax highlight.
    public static func text(_ text: String,
                            language: String? = nil,
                            style: HighlightStyle = .dark(.xcode)) throws -> HighlightResult {
        try shared.text(
            text,
            language: language,
            style: style
        )
    }
    
    private func text(_ text: String,
                      language: String?,
                      style: HighlightStyle) throws -> HighlightResult {
        let highlightResult: JSValue
        if let language {
            highlightResult = hljs.invokeMethod("highlight", withArguments: [text, ["language": language]])
        } else {
            highlightResult = hljs.invokeMethod("highlightAuto", withArguments: [text])
        }
        let illegal = highlightResult.objectForKeyedSubscript("illegal").toBool()
        let relevance = Int(highlightResult.objectForKeyedSubscript("relevance").toInt32())
        guard
            let value = highlightResult.objectForKeyedSubscript("value").toString(),
            let language = highlightResult.objectForKeyedSubscript("language").toString()
        else {
            throw HighlightError.valueNotFound
        }
        let data = try data(value, selectors: style.selectorsText)
        let attributed = try attributed(data)
//#if os(macOS)
//        let attributedText = try AttributedString(attributed, including: \.appKit)
//#else
//        let attributedText = try AttributedString(attributed, including: \.uiKit)
//#endif
        return HighlightResult(
            text: attributed,
            illegal: illegal,
            language: language,
            relevance: relevance,
            background: style.backgroundHex
        )
    }
    
    
    
    private func data(_ value: String, selectors: String) throws -> Data {
        let data = "<style>"
            .appending(selectors)
            .appending("</style>")
            .appending("<pre><code class=\"hljs\">")
            .appending(value.trimmingCharacters(in: .whitespacesAndNewlines))
            .appending("</code></pre>")
            .data(using: .utf8)
        guard let data else {
            throw HighlightError.dataEncoding
        }
        return data
    }
    
    private func attributed(_ data: Data) throws -> NSMutableAttributedString {
        let nsAttributedString = try NSMutableAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        let range = NSMakeRange(0, nsAttributedString.length)
        nsAttributedString.removeAttribute(.font, range: range)
        return nsAttributedString
    }
}
