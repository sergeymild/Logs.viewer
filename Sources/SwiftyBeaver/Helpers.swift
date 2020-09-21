//
//  Helpers.swift
//  LogsViewer
//
//  Created by Sergei Golishnikov on 21/09/2020.
//  Copyright © 2020 BiAtoms. All rights reserved.
//

import Foundation

func jsonData(obj: [String: Any]) -> Data {
    let json = try? JSONSerialization.data(withJSONObject: obj, options: [])
    return json ?? Data()
}

func jsonString(obj: [String: Any]) -> String {
    let json = try? JSONSerialization.data(withJSONObject: obj, options: [])
    return String(data: (json ?? Data()), encoding: .utf8)!
}

func dictionaryFromAny(data: Any) -> [String: Any] {
    guard let string = data as? String else {
        return [:]
    }
    
    guard let d = string.data(using: .utf8) else { return [:] }
    
    let dict = (try? JSONSerialization.jsonObject(
        with: d,
        options: .allowFragments
    )) as? [String: String]
    
    return dict ?? [:]
}
