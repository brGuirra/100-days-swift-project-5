//
//  ViewController.swift
//  project-5
//
//  Created by Bruno Guirra on 10/01/22.
//

import UIKit

class ViewController: UITableViewController {
    var gameData = GameData()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a button in navigation bar to add words
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        
        // Create a button in navigation bar to restart the game
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Restart", style: .plain, target: self, action: #selector(startGame))
        
        let defaults = UserDefaults.standard
        
        if let savedData = defaults.object(forKey: "gameData") as? Data {
            let decoder = JSONDecoder()
            
            do {
              gameData = try decoder.decode(GameData.self, from: savedData)
            } catch {
                print("Failed to load game data.")
            }
        } else {
            // Read the start.txt file from bundle and insert its value in an
            // array of Strings
            if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
                if let startWords = try? String(contentsOf: startWordsURL) {
                    var words = startWords.components(separatedBy: "\n")
                    
                    words.shuffle()
                    
                    gameData.allWords = words
                }
            }
            
            if gameData.allWords.isEmpty {
                gameData.allWords = ["silkworm"]
            }
            
            startGame()
        }
    }

    // Get a randow word from allWords array and place it
    // as the initial word for the game
    @objc func startGame() {
        if let randomWord = gameData.allWords.randomElement() {
          title = randomWord
            gameData.currentWord = randomWord
        }
        
        gameData.answers.removeAll(keepingCapacity: true)
        tableView.reloadData()
    }
    
    // Methods to create the cell and row in the TableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gameData.answers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        var content =  cell.defaultContentConfiguration()
        
        content.text = gameData.answers[indexPath.row]
        cell.contentConfiguration = content
        return cell
    }
    
    // Create a prompt where the user can insert a word. Uses a
    // custom closure as the last parameter of UIAlertAction, weak
    // is necessary there to avoid strong references between ac and
    // the View Controller
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        
        ac.addTextField()
       
        let submitAction = UIAlertAction(title: "Submit", style: .default) {
            [weak self, weak ac] _ in
            
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    // Submit the word answered by the user
    // The method make a validation of the word
    // calling helper functions
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        
        guard let currentGameWord = title?.lowercased() else { return }
        
        if isWithinTheRulesOfTheGame(word: lowerAnswer, currentGameWord: currentGameWord) {
            if isPossible(word: lowerAnswer, currentGameWord: currentGameWord) {
                if isOriginal(word: lowerAnswer) {
                    if isReal(word: lowerAnswer) {
                        gameData.answers.insert(lowerAnswer, at: 0)
                        save()
                        
                        let indexPath = IndexPath(row: 0, section: 0)
                        tableView.insertRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        }
    }
    
    // Check if the word has more than 2 letters and
    // if isn't equal to the game's word
    func isWithinTheRulesOfTheGame(word: String, currentGameWord: String) -> Bool {
        if word.count < 3 {
            showErrorMessage(errorTitle: "Too short", errorMessage: "The words must have at least three letters")
            return false
        }
        
        if word == currentGameWord {
            showErrorMessage(errorTitle: "Not allowed", errorMessage: "You can't use the word displayed by the game")
            return false
        }
        
        return true
    }
    
    // Check if the word doesn't exist in the
    // usedWords array
    func isOriginal(word: String) -> Bool {
        if !gameData.answers.contains(word) {
            return true
        } else {
            showErrorMessage(errorTitle: "Word used already", errorMessage: "Be more original!")
            return false
        }
    }
    
    // Check if the word's letters are all present
    // in the current game's word
    func isPossible(word: String, currentGameWord: String) -> Bool {
        var tempWord = currentGameWord
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                if let title = title?.lowercased() {
                    showErrorMessage(errorTitle: "Word not possible", errorMessage: "You can't spell that word from \(title)")
                }
                return false
            }
        }
        
        
        return true
    }
    
    // Check if the word is speled correctly in English
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        
        // NSRange is necessary cus' UITextChecker was create in
        // Objective-c and this language use a different way to
        // count substrings than Swift
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspeledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        if misspeledRange.location == NSNotFound {
            return true
        } else {
            showErrorMessage(errorTitle: "Word not recognised", errorMessage: "You can't just make them up, you know!")
            return false
        }
    }
    
    func showErrorMessage(errorTitle: String, errorMessage: String) {
        let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func save() {
        let encoder = JSONEncoder()
        
        if let savedData = try? encoder.encode(gameData) {
            let defaults = UserDefaults.standard
            
            defaults.set(savedData, forKey: "gameData")
        } else {
            print("Failed to save game data.")
        }
    }
}

