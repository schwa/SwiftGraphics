import SwiftUI

@propertyWrapper
struct CodableAppStorage<Value: Codable>: DynamicProperty {
    var key: String

    @State
    var storage: Value

    var wrappedValue: Value {
        get {
            return storage
        }
        nonmutating set {
            storage = newValue
            let data = try! JSONEncoder().encode(newValue)
            let string = String(data: data, encoding: .utf8)!
            UserDefaults.standard.setValue(string, forKey: key)
        }
    }

    init(wrappedValue: Value, _ key: String) {
        self.key = key
        if let string = UserDefaults.standard.string(forKey: key) {
            let data = string.data(using: .utf8)!
            let value = try! JSONDecoder().decode(Value.self, from: data)
            self._storage = .init(initialValue: value)
        }
        else {
            self._storage = .init(initialValue: wrappedValue)
        }
    }


}

extension CodableAppStorage where Value : ExpressibleByNilLiteral {
    init(_ key: String) {
        self.key = key
        if let string = UserDefaults.standard.string(forKey: key) {
            let data = string.data(using: .utf8)!
            let value = try! JSONDecoder().decode(Value.self, from: data)
            self._storage = .init(initialValue: value)
        }
        else {
            self._storage = .init(initialValue: nil)
        }
    }

}
