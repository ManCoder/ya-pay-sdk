import Foundation

struct RegexValidator: Validator {

    let expression: NSRegularExpression

    init?(pattern: String) {
        do {
            self.expression = try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            return nil
        }
    }

    func validate(text: String) -> Bool {
        let matches = expression.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        return matches.isEmpty == false
    }
}
