//  SwiftyJSON.swift
//
//  Copyright (c) 2014 Ruoyu Fu, Pinglin Tang
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

// MARK: - Error

///Error domain
public let ErrorDomain: String = "SwiftyJSONErrorDomain"

///Error code
public let ErrorUnsupportedType: Int = 999
public let ErrorIndexOutOfBounds: Int = 900
public let ErrorWrongType: Int = 901
public let ErrorNotExist: Int = 500
public let ErrorInvalidJSON: Int = 490

// MARK: - JSON Type

/**
JSON's type definitions.

See http://www.json.org
*/
public enum Type {
    case number(NSNumber)
    case string(String)
    case bool(Bool)
    case array([Any])
    case dictionary([String : Any])
    case null
    case unknown
}

// MARK: - JSON Base

public struct JSON {

    /**
    Creates a JSON using the data.

    - parameter data:  The NSData used to convert to json.Top level object in data is an NSArray or NSDictionary
    - parameter opt:   The JSON serialization reading options. `.AllowFragments` by default.
    - parameter error: error The NSErrorPointer used to return the error. `nil` by default.

    - returns: The created JSON
    */
    public init(data:Data, options opt: JSONSerialization.ReadingOptions = .allowFragments, error: NSErrorPointer? = nil) {
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: opt)
            self.init(object)
        } catch let aError as NSError {
            if error != nil {
                error??.pointee = aError
            }
            self.init(NSNull())
        }
    }

    /**
     Create a JSON from JSON string
    - parameter string: Normal json string like '{"a":"b"}'

    - returns: The created JSON
    */
    public static func parse(_ string: String) -> JSON {
        return string.data(using: .utf8).flatMap { JSON(data: $0) } ?? JSON(NSNull())
    }

    /**
    Creates a JSON using the object.

    - parameter object:  The object must have the following properties: All objects are NSString/String, NSNumber/Int/Float/Double/Bool, NSArray/Array, NSDictionary/Dictionary, or NSNull; All dictionary keys are NSStrings/String; NSNumbers are not NaN or infinity.

    - returns: The created JSON
    */
    public init(_ object: Any) {
        self.object = object
    }

    /**
    Creates a JSON from a [JSON]

    - parameter jsonArray: A Swift array of JSON objects

    - returns: The created JSON
    */
    public init(_ jsonArray: [JSON]) {
        self.init(jsonArray.map { $0.object })
    }

    /**
    Creates a JSON from a [String: JSON]

    - parameter jsonDictionary: A Swift dictionary of JSON objects

    - returns: The created JSON
    */
    public init(_ jsonDictionary: [String: JSON]) {
        var dictionary = [String: Any](minimumCapacity: jsonDictionary.count)
        for (key, json) in jsonDictionary {
            dictionary[key] = json.object
        }
        self.init(dictionary)
    }

    /// Private type
    fileprivate var _type: Type = .null
    /// prviate error
    fileprivate var _error: NSError? = nil

    /// Object in JSON
    public var object: Any {
        get {
            switch self.type {
            case let .array(rawArray):
                return rawArray as [AnyObject]
            case let .dictionary(rawDictionary):
                return rawDictionary as [String : AnyObject]
            case let .string(rawString):
                return rawString as NSString
            case let .number(rawNumber):
                return rawNumber
            case let .bool(rawBool):
                return rawBool as NSNumber
            default:
                return NSNull()
            }
        }
        set {
            _error = nil
            switch newValue {
            case let number as NSNumber:
                if number.isBool {
                    _type = .bool(number as Bool)
                } else {
                    _type = .number(number)
                }
            case let string as String:
                _type = .string(string)
            case  _ as NSNull:
                _type = .null
            case let array as [Any]:
                _type = .array(array)
            case let dictionary as [String : Any]:
                _type = .dictionary(dictionary)
            default:
                _type = .unknown
                _error = NSError(domain: ErrorDomain, code: ErrorUnsupportedType, userInfo: [NSLocalizedDescriptionKey: "It is a unsupported type"])
            }
        }
    }

    /// json type
    public var type: Type { get { return _type } }

    /// Error in JSON
    public var error: NSError? { get { return self._error } }

    /// The static null json
    @available(*, unavailable, renamed:"null")
    public static var nullJSON: JSON { get { return null } }
    public static var null: JSON { get { return JSON(NSNull()) } }
}

public enum JSONIndex:Comparable {
    case array(Int)
    case dictionary(DictionaryIndex<String, JSON>)
    case null
}

public func ==(lhs: JSONIndex, rhs: JSONIndex) -> Bool {
    switch (lhs, rhs) {
    case (.array(let left), .array(let right)):
        return left == right
    case (.dictionary(let left), .dictionary(let right)):
        return left == right
    default:
        return false
    }
}

public func <(lhs: JSONIndex, rhs: JSONIndex) -> Bool {
    switch (lhs, rhs) {
    case (.array(let left), .array(let right)):
        return left < right
    case (.dictionary(let left), .dictionary(let right)):
        return left < right
    default:
        return false
    }
}


extension JSON: Collection{

    public typealias Index = JSONIndex

    public var startIndex: Index{
        switch type {
        case let .array(rawArray):
            return .array(rawArray.startIndex)
        case .dictionary:
            return .dictionary(dictionaryValue.startIndex)
        default:
            return .null
        }
    }

    public var endIndex: Index{
        switch type {
        case let .array(rawArray):
            return .array(rawArray.endIndex)
        case .dictionary:
            return .dictionary(dictionaryValue.endIndex)
        default:
            return .null
        }
    }

    public func index(after i: Index) -> Index {
        switch i {
        case .array(let idx):
            guard case let .array(rawArray) = _type else { return .null }
            return .array(rawArray.index(after: idx))
        case .dictionary(let idx):
            return .dictionary(dictionaryValue.index(after: idx))
        default:
            return .null
        }

    }

    public subscript (position: Index) -> (String, JSON) {
        switch position {
        case .array(let idx):
            guard case let .array(rawArray) = _type else { return ("", JSON.null) }
            return (String(idx), JSON(rawArray[idx]))
        case .dictionary(let idx):
            return dictionaryValue[idx]
        default:
            return ("", JSON.null)
        }
    }


}

// MARK: - Subscript

/**
*  To mark both String and Int can be used in subscript.
*/
public enum JSONKey {
    case index(Int)
    case key(String)
}

public protocol JSONSubscriptType {
    var jsonKey:JSONKey { get }
}

extension Int: JSONSubscriptType {
    public var jsonKey:JSONKey {
        return JSONKey.index(self)
    }
}

extension String: JSONSubscriptType {
    public var jsonKey:JSONKey {
        return JSONKey.key(self)
    }
}

extension JSON {

    /// If `type` is `.Array`, return json whose object is `array[index]`, otherwise return null json with error.
    private subscript(index index: Int) -> JSON {
        get {
            guard case let .array(rawArray) = self.type else {
                var r = JSON.null
                r._error = self._error ?? NSError(domain: ErrorDomain, code: ErrorWrongType, userInfo: [NSLocalizedDescriptionKey: "Array[\(index)] failure, It is not an array"])
                return r
            }
            
            if index >= 0 && index < rawArray.count {
                return JSON(rawArray[index])
            } else {
                var r = JSON.null
                r._error = NSError(domain: ErrorDomain, code:ErrorIndexOutOfBounds , userInfo: [NSLocalizedDescriptionKey: "Array[\(index)] is out of bounds"])
                return r
            }
        }
        set {
            if case let .array(rawArray) = self.type, rawArray.count > index && newValue.error == nil {
                var newArray = rawArray
                newArray[index] = newValue.object
                _type = .array(newArray)
            }
        }
    }

    /// If `type` is `.Dictionary`, return json whose object is `dictionary[key]`, otherwise return null json with error.
    private subscript(key key: String) -> JSON {
        get {
            guard case let .dictionary(rawDictionary) = self.type else {
                var r = JSON.null
                r._error = self._error ?? NSError(domain: ErrorDomain, code: ErrorWrongType, userInfo: [NSLocalizedDescriptionKey: "Dictionary[\"\(key)\"] failure, It is not an dictionary"])
                return r
            }
            
            if let o = rawDictionary[key] {
                return JSON(o)
            } else {
                var r = JSON.null
                r._error = NSError(domain: ErrorDomain, code: ErrorNotExist, userInfo: [NSLocalizedDescriptionKey: "Dictionary[\"\(key)\"] does not exist"])
                return r
            }
        }
        set {
            if case let .dictionary(rawDictionary) = self.type, newValue.error == nil {
                var newDictionary = rawDictionary
                newDictionary[key] = newValue.object
                _type = .dictionary(newDictionary)
            }
        }
    }

    /// If `sub` is `Int`, return `subscript(index:)`; If `sub` is `String`,  return `subscript(key:)`.
    private subscript(sub sub: JSONSubscriptType) -> JSON {
        get {
            switch sub.jsonKey {
            case .index(let index): return self[index: index]
            case .key(let key): return self[key: key]
            }
        }
        set {
            switch sub.jsonKey {
            case .index(let index): self[index: index] = newValue
            case .key(let key): self[key: key] = newValue
            }
        }
    }

    /**
    Find a json in the complex data structuresby using the Int/String's array.

    - parameter path: The target json's path. Example:

    let json = JSON[data]
    let path = [9,"list","person","name"]
    let name = json[path]

    The same as: let name = json[9]["list"]["person"]["name"]

    - returns: Return a json found by the path or a null json with error
    */
    public subscript(path: [JSONSubscriptType]) -> JSON {
        get {
            return path.reduce(self) { $0[sub: $1] }
        }
        set {
            switch path.count {
            case 0:
                return
            case 1:
                self[sub:path[0]].object = newValue.object
            default:
                var aPath = path; aPath.remove(at: 0)
                var nextJSON = self[sub: path[0]]
                nextJSON[aPath] = newValue
                self[sub: path[0]] = nextJSON
            }
        }
    }

    /**
    Find a json in the complex data structures by using the Int/String's array.

    - parameter path: The target json's path. Example:

    let name = json[9,"list","person","name"]

    The same as: let name = json[9]["list"]["person"]["name"]

    - returns: Return a json found by the path or a null json with error
    */
    public subscript(path: JSONSubscriptType...) -> JSON {
        get {
            return self[path]
        }
        set {
            self[path] = newValue
        }
    }
}

// MARK: - LiteralConvertible

extension JSON: ExpressibleByStringLiteral {

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }

    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }
}

extension JSON: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension JSON: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
}

extension JSON: ExpressibleByFloatLiteral {

    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

extension JSON: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, Any)...) {
        self.init(elements.reduce([String : Any](minimumCapacity: elements.count)){(dictionary: [String : Any], element: (String, Any)) -> [String : Any] in
            var d = dictionary
            d[element.0] = element.1
            return d
            })
    }
}

extension JSON: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
}

extension JSON: ExpressibleByNilLiteral {

    public init(nilLiteral: ()) {
        self.init(NSNull())
    }
}

// MARK: - Raw

extension JSON: RawRepresentable {

    public init?(rawValue: Any) {
        if case .unknown = JSON(rawValue).type {
            return nil
        } else {
            self.init(rawValue)
        }
    }

    public var rawValue: Any {
        return self.object
    }

    public func rawData(options opt: JSONSerialization.WritingOptions = []) throws -> Data {
        guard JSONSerialization.isValidJSONObject(self.object) else {
            throw NSError(domain: ErrorDomain, code: ErrorInvalidJSON, userInfo: [NSLocalizedDescriptionKey: "JSON is invalid"])
        }

        return try JSONSerialization.data(withJSONObject: self.object, options: opt)
    }

    public func rawString(_ encoding: String.Encoding = .utf8, options opt: JSONSerialization.WritingOptions = .prettyPrinted) -> String? {
        switch self.type {
        case .array, .dictionary:
            do {
                let data = try self.rawData(options: opt)
                return String(data: data, encoding: encoding)
            } catch _ {
                return nil
            }
        case let .string(rawString):
            return rawString
        case let .number(rawNumber):
            return rawNumber.stringValue
        case let .bool(rawBool):
            return rawBool.description
        case .null:
            return "null"
        default:
            return nil
        }
    }
}

// MARK: - Printable, DebugPrintable

extension JSON: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        if let string = self.rawString(options: .prettyPrinted) {
            return string
        } else {
            return "unknown"
        }
    }

    public var debugDescription: String {
        return description
    }
}

// MARK: - Array

extension JSON {

    //Optional [JSON]
    public var array: [JSON]? {
        get {
            if case let .array(rawArray) = self.type {
                return rawArray.map{ JSON($0) }
            } else {
                return nil
            }
        }
    }

    //Non-optional [JSON]
    public var arrayValue: [JSON] {
        get {
            return self.array ?? []
        }
    }

    //Optional [Any]
    public var arrayObject: [Any]? {
        get {
            switch self.type {
            case let .array(rawArray):
                return rawArray
            default:
                return nil
            }
        }
        set {
            if let array = newValue {
                self.object = array
            } else {
                self.object = NSNull()
            }
        }
    }
}

// MARK: - Dictionary

extension JSON {

    //Optional [String : JSON]
    public var dictionary: [String : JSON]? {
        if case let .dictionary(rawDictionary) = self.type {
            return rawDictionary.reduce([String : JSON]()) { (dictionary: [String : JSON], element: (String, Any)) -> [String : JSON] in
                var d = dictionary
                d[element.0] = JSON(element.1)
                return d
            }
        } else {
            return nil
        }
    }

    //Non-optional [String : JSON]
    public var dictionaryValue: [String : JSON] {
        return self.dictionary ?? [:]
    }

    //Optional [String : Any]
    public var dictionaryObject: [String : Any]? {
        get {
            switch self.type {
            case let .dictionary(rawDictionary):
                return rawDictionary
            default:
                return nil
            }
        }
        set {
            if let v = newValue {
                self.object = v
            } else {
                self.object = NSNull()
            }
        }
    }
}

// MARK: - Bool

extension JSON {

    //Optional bool
    public var bool: Bool? {
        get {
            switch self.type {
            case let .bool(rawBool):
                return rawBool
            default:
                return nil
            }
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }

    //Non-optional bool
    public var boolValue: Bool {
        get {
            switch self.type {
            case let .bool(rawBool):
                return rawBool
            case let .number(rawNumber):
                return rawNumber.boolValue
            case let .string(rawString):
                return Bool(rawString) ?? false
            default:
                return false
            }
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }
}

// MARK: - String

extension JSON {

    //Optional string
    public var string: String? {
        get {
            switch self.type {
            case let .string(rawString):
                return rawString
            default:
                return nil
            }
        }
        set {
            if let newValue = newValue {
                self.object = newValue
            } else {
                self.object = NSNull()
            }
        }
    }

    //Non-optional string
    public var stringValue: String {
        get {
            switch self.type {
            case let .string(rawString):
                return rawString
            case let .number(rawNumber):
                return rawNumber.stringValue
            case let .bool(rawBool):
                return String(rawBool)
            default:
                return ""
            }
        }
        set {
            self.object = newValue
        }
    }
}

// MARK: - Number
extension JSON {

    //Optional number
    public var number: NSNumber? {
        get {
            switch self.type {
            case let .number(rawNumber):
                return rawNumber as NSNumber
            case let .bool(rawBool):
                return rawBool as NSNumber
            default:
                return nil
            }
        }
        set {
            self.object = newValue ?? NSNull()
        }
    }

    //Non-optional number
    public var numberValue: NSNumber {
        get {
            switch self.type {
            case let .string(rawString):
                let decimal = NSDecimalNumber(string: rawString)
                if decimal == NSDecimalNumber.notANumber {  // indicates parse error
                    return NSDecimalNumber.zero
                }
                return decimal
            case let .number(rawNumber):
                return rawNumber as NSNumber
            case let .bool(rawBool):
                return rawBool as NSNumber
            default:
                return NSNumber(value: 0.0)
            }
        }
        set {
            self.object = newValue
        }
    }
}

//MARK: - Null
extension JSON {

    public var null: NSNull? {
        get {
            switch self.type {
            case .null:
                return NSNull()
            default:
                return nil
            }
        }
        set {
            self.object = NSNull()
        }
    }
    
    public var isNull: Bool {
        if case .null = self.type {
            return true
        } else {
            return false
        }
    }
    
    public func exists() -> Bool {
        if let errorValue = error, errorValue.code == ErrorNotExist {
            return false
        }
        return true
    }
}

//MARK: - URL
extension JSON {

    //Optional URL
    public var url: URL? {
        get {
            switch self.type {
            case let .string(rawString):
                if let encodedString = rawString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    return URL(string: encodedString)
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
        set {
            self.object = newValue?.absoluteString ?? NSNull()
        }
    }
}

// MARK: - Int, Double, Float, Int8, Int16, Int32, Int64

extension JSON {

    public var double: Double? {
        get {
            return self.number?.doubleValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }

    public var doubleValue: Double {
        get {
            return self.numberValue.doubleValue
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var float: Float? {
        get {
            return self.number?.floatValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }

    public var floatValue: Float {
        get {
            return self.numberValue.floatValue
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var int: Int? {
        get {
            return self.number?.intValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }

    public var intValue: Int {
        get {
            return self.numberValue.intValue
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var uInt: UInt? {
        get {
            return self.number?.uintValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }

    public var uIntValue: UInt {
        get {
            return self.numberValue.uintValue
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var int8: Int8? {
        get {
            return self.number?.int8Value
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }

    public var int8Value: Int8 {
        get {
            return self.numberValue.int8Value
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var uInt8: UInt8? {
        get {
            return self.number?.uint8Value
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }

    public var uInt8Value: UInt8 {
        get {
            return self.numberValue.uint8Value
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var int16: Int16? {
        get {
            return self.number?.int16Value
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }

    public var int16Value: Int16 {
        get {
            return self.numberValue.int16Value
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var uInt16: UInt16? {
        get {
            return self.number?.uint16Value
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }

    public var uInt16Value: UInt16 {
        get {
            return self.numberValue.uint16Value
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var int32: Int32? {
        get {
            return self.number?.int32Value
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }

    public var int32Value: Int32 {
        get {
            return self.numberValue.int32Value
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var uInt32: UInt32? {
        get {
            return self.number?.uint32Value
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }

    public var uInt32Value: UInt32 {
        get {
            return self.numberValue.uint32Value
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var int64: Int64? {
        get {
            return self.number?.int64Value
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }

    public var int64Value: Int64 {
        get {
            return self.numberValue.int64Value
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }

    public var uInt64: UInt64? {
        get {
            return self.number?.uint64Value
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(value: newValue)
            } else {
                self.object =  NSNull()
            }
        }
    }

    public var uInt64Value: UInt64 {
        get {
            return self.numberValue.uint64Value
        }
        set {
            self.object = NSNumber(value: newValue)
        }
    }
}

//MARK: - Comparable
extension JSON : Comparable {}

public func ==(lhs: JSON, rhs: JSON) -> Bool {

    switch (lhs.type, rhs.type) {
    case let (.number(lhs), .number(rhs)):
        return lhs == rhs
    case let (.string(lhs), .string(rhs)):
        return lhs == rhs
    case let (.bool(lhs), .bool(rhs)):
        return lhs == rhs
    case let (.array(lhs), .array(rhs)):
        return lhs as NSArray == rhs as NSArray
    case let (.dictionary(lhs), .dictionary(rhs)):
        return lhs as [String : AnyObject] as NSDictionary == rhs as [String : AnyObject] as NSDictionary
    case (.null, .null):
        return true
    default:
        return false
    }
}

public func <=(lhs: JSON, rhs: JSON) -> Bool {

    switch (lhs.type, rhs.type) {
    case let (.number(lhs), .number(rhs)):
        return lhs <= rhs
    case let (.string(lhs), .string(rhs)):
        return lhs <= rhs
    case let (.bool(lhs), .bool(rhs)):
        return lhs == rhs
    case let (.array(lhs), .array(rhs)):
        return lhs as NSArray == rhs as NSArray
    case let (.dictionary(lhs), .dictionary(rhs)):
        return lhs as [String : AnyObject] as NSDictionary == rhs as [String : AnyObject] as NSDictionary
    case (.null, .null):
        return true
    default:
        return false
    }
}

public func >=(lhs: JSON, rhs: JSON) -> Bool {

    switch (lhs.type, rhs.type) {
    case let (.number(lhs), .number(rhs)):
        return lhs >= rhs
    case let (.string(lhs), .string(rhs)):
        return lhs >= rhs
    case let (.bool(lhs), .bool(rhs)):
        return lhs == rhs
    case let (.array(lhs), .array(rhs)):
        return lhs as NSArray == rhs as NSArray
    case let (.dictionary(lhs), .dictionary(rhs)):
        return lhs as [String : AnyObject] as NSDictionary == rhs as [String : AnyObject] as NSDictionary
    case (.null, .null):
        return true
    default:
        return false
    }
}

public func >(lhs: JSON, rhs: JSON) -> Bool {

    switch (lhs.type, rhs.type) {
    case let (.number(lhs), .number(rhs)):
        return lhs > rhs
    case let (.string(lhs), .string(rhs)):
        return lhs > rhs
    default:
        return false
    }
}

public func <(lhs: JSON, rhs: JSON) -> Bool {

    switch (lhs.type, rhs.type) {
    case let (.number(lhs), .number(rhs)):
        return lhs < rhs
    case let (.string(lhs), .string(rhs)):
        return lhs < rhs
    default:
        return false
    }
}

private let trueNumber = NSNumber(value: true)
private let falseNumber = NSNumber(value: false)
private let trueObjCType = String(cString: trueNumber.objCType)
private let falseObjCType = String(cString: falseNumber.objCType)

//A C++ bool or a C99 _Bool
private let cppBoolType = "B"

// MARK: - NSNumber: Comparable

extension NSNumber {
    var isBool: Bool {
        get {
            let objCType = String(cString: self.objCType)
            switch objCType {
            case trueObjCType where self.compare(trueNumber) == .orderedSame,
                 falseObjCType where self.compare(falseNumber) == .orderedSame,
                 cppBoolType:
                return true
            default:
                return false
            }
        }
    }
}

func ==(lhs: NSNumber, rhs: NSNumber) -> Bool {
    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == .orderedSame
    }
}

func !=(lhs: NSNumber, rhs: NSNumber) -> Bool {
    return !(lhs == rhs)
}

func <(lhs: NSNumber, rhs: NSNumber) -> Bool {

    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == .orderedAscending
    }
}

func >(lhs: NSNumber, rhs: NSNumber) -> Bool {

    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) == .orderedDescending
    }
}

func <=(lhs: NSNumber, rhs: NSNumber) -> Bool {

    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) != .orderedDescending
    }
}

func >=(lhs: NSNumber, rhs: NSNumber) -> Bool {

    switch (lhs.isBool, rhs.isBool) {
    case (false, true):
        return false
    case (true, false):
        return false
    default:
        return lhs.compare(rhs) != .orderedAscending
    }
}
