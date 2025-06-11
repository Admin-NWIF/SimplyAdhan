//
//  CityTrie.swift
//  Athan
//
//  Created by Usman Hasan on 5/27/25.
//

import Foundation

class TrieNode {
    var children: [Character: TrieNode] = [:]
    var cities: [City] = []
    var isEnd: Bool = false
}

class CityTrie {
    private let root = TrieNode()

    func insert(city: City) {
        var node = root
        for char in city.name.lowercased() {
            if node.children[char] == nil {
                node.children[char] = TrieNode()
            }
            node = node.children[char]!
            node.cities.append(city) // Append to each prefix node
        }
        node.isEnd = true
    }

    func search(prefix: String) -> [City] {
        var node = root
        for char in prefix.lowercased() {
            guard let next = node.children[char] else {
                return []
            }
            node = next
        }
        return Array(node.cities.prefix(100))
    }
}
