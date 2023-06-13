extension Optional where Wrapped == String {
    func isEmptyOrWhitespace() -> Bool {
        guard let string = self else {
            return true
        }

        return string.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

extension String {
    func isEmptyOrWhitespace() -> Bool {
        return self.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
