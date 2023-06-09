//
//  BinaryDisplayConstants.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-08.
//

import Foundation


let placeholderStringArray = [
    "dead", "beef", "babe", "cafe",
    "dead", "beef", "babe", "cafe",
    "dead", "beef", "babe", "cafe",
    "dead", "beef", "babe", "cafe",
    "dead", "beef", "babe", "cafe",
    "dead", "beef", "babe", "cafe",
    "dead", "beef", "babe", "cafe",
    "dead", "beef", "babe", "cafe",
]

func placeholderHashBlock(perGroup: Int = 4, perLine: Int = 8) -> String {
    let placeholderString = placeholderStringArray.joined(separator: "")
    return groupCharacters(string: placeholderString, perGroup: perGroup, perLine: perLine)
}

let easterEggPasswords: Dictionary<String, [String]> = [
    "hunter2": [
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
        "****", "****", "****", "****",
    ],
    "love": [
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
    ],
    "sex": [
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
    ],
    "secret": [
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
    ],
    "god": [
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
        "love", "sexs", "ecre", "tgod",
    ],
    "swordfish": [
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
        "worm", "worm", "worm", "worm",
    ],
    "correct horse battery staple": [
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
        "xkcd", "xkcd", "xkcd", "xkcd",
    ],
    "penis": [
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
        "TOOS", "HORT", "TOOS", "HORT",
    ]
]
