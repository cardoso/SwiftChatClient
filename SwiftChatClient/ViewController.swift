//
//  ViewController.swift
//  SwiftChatClient
//
//  Created by Matheus Cardoso on 7/15/18.
//  Copyright © 2018 cardoso. All rights reserved.
//

import UIKit
import SwiftChatCore

class ViewController: UIViewController {
    private let messagesUrl: URL! = URL(string: "http://127.0.0.1:8080/messages")

    private lazy var encoder = { () -> JSONEncoder in
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private lazy var decoder = { () -> JSONDecoder in
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            updateMessages()
        }
    }

    var messages: [Message] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    func updateMessages() {
        URLSession.shared.dataTask(with: messagesUrl) { [weak self] data, _, _ in
            DispatchQueue.main.async { [weak self] in
                guard
                    let data = data,
                    let messages = try? self?.decoder.decode([Message].self, from: data) ?? []
                else {
                    return
                }

                self?.messages = messages
            }
        }.resume()
    }

    func sendMessage() {
        let message = Message(id: nil, text: textField.text ?? "")

        var request = URLRequest(url: messagesUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? encoder.encode(message)

        URLSession.shared.dataTask(with: request) { [weak self] data, reponse, error in
            DispatchQueue.main.async { [weak self] in
                self?.updateMessages()
            }
        }.resume()
    }

    @IBAction func sendButtonPressed(_ sender: UIButton) {
        sendMessage()
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
            fatalError("Could not dequeue cell")
        }

        cell.textLabel?.text = messages[indexPath.row].text
        cell.detailTextLabel?.text = messages[indexPath.row].dateCreated.description

        return cell
    }
}
