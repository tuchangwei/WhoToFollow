//
//  ViewController.swift
//  WhoToFollow
//
//  Created by Changwei Tu on 08/11/2016.
//  Copyright © 2016 tuchangwei. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher
class HomeViewController: UIViewController {
    @IBOutlet weak var refreshBtn: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    var viewModel:HomeViewModel!
    var disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib.init(nibName: "HomeTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false
        tableView.reloadData()
        setupViewModel()
        
    }
    func setupViewModel() {
        let cell1 = getCell(indexPath: IndexPath(row: 0, section: 0))
        let cell2 = getCell(indexPath: IndexPath(row: 1, section: 0))
        let cell3 = getCell(indexPath: IndexPath(row: 2, section: 0))
        viewModel = HomeViewModel(input: (
            refreshClickStream: refreshBtn.rx.tap.asObservable(),
            close1ClickStream: cell1.cancelBtn.rx.tap.asObservable(),
            close2ClickStream: cell2.cancelBtn.rx.tap.asObservable(),
            close3ClickStream: cell3.cancelBtn.rx.tap.asObservable()
        ))
        addSubscriptor(To: viewModel.suggestion1Stream, renderFor: cell1)
        addSubscriptor(To: viewModel.suggestion2Stream, renderFor: cell2)
        addSubscriptor(To: viewModel.suggestion3Stream, renderFor: cell3)
        
    }
    func getCell(indexPath: IndexPath) -> HomeTableViewCell {
        let cell = tableView.cellForRow(at: indexPath) as! HomeTableViewCell
        return cell
    }
    
    func addSubscriptor(To suggestionStream:Observable<User?>, renderFor cell: HomeTableViewCell) {
        suggestionStream.subscribe { (event) in
            if let element = event.element,
                let user = element {
                cell.isHidden = false
                cell.usernameLabel.text = user.name
                if let urlStr = user.avatar {
                    let url = URL(string: urlStr)
                    cell.avatarImgView.kf.setImage(with: url)
                }
            } else {
                cell.isHidden = true
            }
        }
        .addDisposableTo(disposeBag)
        
    }
}
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! HomeTableViewCell
        return cell
    }
}

