//
//  ViewController.swift
//  Project 6 WhatsApp Atheer Alzahrani
//
//  Created by Eth Os on 23/03/1443 AH.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

struct Conversation{
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage{
    let date: String
    let text: String
    let isRead: Bool
}

class ConversationsViewController: UIViewController{
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    private let tableView: UITableView = {
        let tabel = UITableView()
        tabel.isHidden = true
        tabel.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return tabel
    }()
    
    private let noConversation: UILabel = {
       let label = UILabel()
        label.text = "No Conversation"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose ,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversation)
        setupTableView()
        fetchConversations()
        startListeningForConversation()
    }

    private func startListeningForConversation(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        print("Starting conversation fetch .........")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversation(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else{
                    return
                }
                
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failed to get convos: \(error)")
            }
        })
    }
    
    @objc private func didTapComposeButton(){
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            self?.createNewConveration(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func createNewConveration(result: [String: String]){
        guard let name = result["name"], let email = result["email"] else {
            return
        }
        let vc = ChatViewController(with: email, id: nil)
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil  {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    private func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchConversations(){
        tableView.isHidden = false
    }
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        let model = conversations[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        
        let vc = ChatViewController(with: model.otherUserEmail ,id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
}