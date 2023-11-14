//
//  PrivacySettingVC.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 12.11.2023.
//

import UIKit

class PrivacySettingVC: UIViewController {
    
    private let tableView: UITableView = {
        let tv = UITableView()
        return tv
    }()
    
    var cells = [PrivacyViewModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Privacy"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        
        let customButton = UIBarButtonItem(customView: backButton)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        navigationItem.leftBarButtonItem = customButton
        
        tableViewConfigure()
        cellsArrayAppend()
        tableView.tableHeaderView = createTableHeader()
    }
    
    private func tableViewConfigure() {
        view.addSubview(tableView)
        tableView.register(PrivacyTableViewCell.self, forCellReuseIdentifier: PrivacyTableViewCell.identifier)
        tableView.backgroundColor = UIColor(#colorLiteral(red: 0.9638196826, green: 0.9687927365, blue: 1, alpha: 1))
        tableView.separatorStyle = .none
        tableView.rowHeight = 64
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func cellsArrayAppend() {
        
        cells.append(PrivacyViewModel(title: "Last seen", isSwitchOn: true, handler: {
            
        }))
        
        cells.append(PrivacyViewModel(title: "Online", isSwitchOn: true, handler: {
            
        }))
        
        cells.append(PrivacyViewModel(title: "Profile photo", isSwitchOn: true, handler: {
            
        }))
        
        cells.append(PrivacyViewModel(title: "Read receipt", isSwitchOn: true, handler: {
            
        }))

        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func createTableHeader() -> UIView? {
        let viewingLabel = UILabel(text: "Who can see my personal information?", font: .boldSystemFont(ofSize: 14), textAlignment: .left)
        
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .black
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 42))
        
        viewingLabel.frame = CGRect(x: 15, y: 5, width: self.view.width, height: 25)
        lineView.frame = CGRect(x: 0, y: 34, width: self.view.width, height: 0.33)
        headerView.addSubview(lineView)
        headerView.addSubview(viewingLabel)
        return headerView
        
    }
    
    private func animateCellSelection(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        UIView.animate(withDuration: 0.2, animations: {
            cell.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            cell.backgroundColor = .white
            cell.contentView.backgroundColor = .white
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
                cell.backgroundColor = .clear
                cell.contentView.backgroundColor = .clear
                
            } completion: { _ in
                self.cells[indexPath.row].handler?()
            }
        }
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        guard let cell = sender.superview as? PrivacyTableViewCell,
              let indexPath = tableView.indexPath(for: cell) else { return }

        cells[indexPath.row].isSwitchOn = sender.isOn
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    
    @objc fileprivate func handleBack() {
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.popViewController(animated: true)
    }
}

extension PrivacySettingVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vm = cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: PrivacyTableViewCell.identifier, for: indexPath) as! PrivacyTableViewCell
        
        cell.clipsToBounds = true
        cell.viewModel = vm
        cell.switchButton.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        //cell.heightAnchor.constraint(equalToConstant: 64).isActive = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Hücre seçiminden sonra vurgulamayı kaldır
        // Animasyonu uygula
        UIView.animate(withDuration: 0.2) {
            self.cells[indexPath.row].isSwitchOn.toggle()
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        animateCellSelection(at: indexPath)
        
        // switch değerini değiştir
        // tableView'i güncelle
       // cells[indexPath.row].handler?()
   }
    
    
    
}
