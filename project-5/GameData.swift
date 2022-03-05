//
//  GameData.swift
//  project-5
//
//  Created by Bruno Guirra on 04/03/22.
//

import Foundation

struct GameData: Codable {
    var allWords = [String]()
    var currentWord = ""
    var answers = [String]()
}
