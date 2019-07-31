//
//  WotabagService.swift
//  wotabag-remote
//
//  Created by Peter Rowlands on 2019/08/19.
//  Copyright © 2019 Peter Rowlands. All rights reserved.
//

import Foundation
import JSONRPCKit

struct CastError<ExpectedType>: Error {
    let actualValue: Any
    let expectedType: ExpectedType.Type
}

struct GetStatus: JSONRPCKit.Request {
    typealias Response = [String: Any]

    var method: String {
        return "wotabag.get_status"
    }

    var parameters: Any? {
        return []
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}

struct SetVolume: JSONRPCKit.Request {
    typealias Response = Int

    let volume: Int

    var method: String {
        return "wotabag.set_volume"
    }

    var parameters: Any? {
        return [volume]
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}

struct TestPattern: JSONRPCKit.Request {
    typealias Response = Int

    var method: String {
        return "wotabag.test_pattern"
    }

    var parameters: Any? {
        return []
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}

struct PowerOff: JSONRPCKit.Request {
    typealias Response = Int

    var method: String {
        return "wotabag.power_off"
    }

    var parameters: Any? {
        return []
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}

struct GetPlaylist: JSONRPCKit.Request {
    typealias Response = [String]

    var method: String {
        return "wotabag.get_playlist"
    }

    var parameters: Any? {
        return []
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}

struct GetColors: JSONRPCKit.Request {
    typealias Response = [String]

    var method: String {
        return "wotabag.get_colors"
    }

    var parameters: Any? {
        return []
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}

struct SetColor: JSONRPCKit.Request {
    typealias Response = Int

    let color: String

    var method: String {
        return "wotabag.set_color"
    }

    var parameters: Any? {
        return [color]
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}

struct Play: JSONRPCKit.Request {
    typealias Response = Int

    var method: String {
        return "wotabag.play"
    }

    var parameters: Any? {
        return []
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}

struct Stop: JSONRPCKit.Request {
    typealias Response = Int

    var method: String {
        return "wotabag.stop"
    }

    var parameters: Any? {
        return []
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}

struct PlayIndex: JSONRPCKit.Request {
    typealias Response = Int

    let index: Int

    var method: String {
        return "wotabag.play_index"
    }

    var parameters: Any? {
        return [index]
    }

    func response(from resultObject: Any) throws -> Response {
        if let response = resultObject as? Response {
            return response
        } else {
            throw CastError(actualValue: resultObject, expectedType: Response.self)
        }
    }
}
