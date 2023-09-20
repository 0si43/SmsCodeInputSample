//
//  ViewController.swift

import UIKit

final class TextField: UITextField {
    public var deletionDelegate: ((TextField) -> Void)?
    override public func deleteBackward() {
        super.deleteBackward()
        deletionDelegate?(self)
    }
}

final class ViewController: UIViewController, UITextFieldDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SMS"
        addStackView()
        addTitleLabel()
        addHorizontalStackView()
        addTextFields()
        addSendButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textFields.first?.becomeFirstResponder()
    }
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fill
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()
    
    private func addStackView() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.text = "SMSコードを入力してください"
        return label
    }()
    
    private func addTitleLabel() {
        stackView.addArrangedSubview(titleLabel)
    }
    
    private lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        stackView.spacing = 8
        return stackView
    }()
    
    private func addHorizontalStackView() {
        stackView.addArrangedSubview(horizontalStackView)
    }
    
    private lazy var textFields: [TextField] = (0 ..< 6).map { _ in
        let textField = TextField()
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.keyboardType = .numberPad
        textField.autocapitalizationType = .none
        textField.returnKeyType = .done
        textField.textAlignment = .center
        textField.delegate = self
        textField.deletionDelegate = deleteAction
        return textField
    }
    
    // 1つ前の入力欄に移動
    private func deleteAction(_ textField: TextField) {
        guard let index = textFields.firstIndex(of: textField) else { return }
        if index > 0 {
            textFields[index - 1].becomeFirstResponder()
        }
    }
    
    private func addTextFields() {
        textFields.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            horizontalStackView.addArrangedSubview(view)
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: 48),
                view.heightAnchor.constraint(equalToConstant: 48)
            ])
        }
    }
    
    lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setTitle("送信", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 8
        button.layer.borderColor = UIColor.black.cgColor
        button.addTarget(self, action: #selector(verify(sender:)), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()
    
    @objc private func verify(sender _: UIButton) {
        verify()
    }
    
    private func verify() {
        guard let code = verificationCode else { return }
        // TODO: - send code
        print("Sent: \(code)")
    }
    
    private func addSendButton() {
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(sendButton)
        NSLayoutConstraint.activate([
            sendButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: sendButton.trailingAnchor)
        ])
    }
    
    private var verificationCode: String? {
        let code = textFields.compactMap(\.text).joined()
        guard code.count == 6 else { return nil }
        return code
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn _: NSRange, replacementString string: String) -> Bool {
        guard !string.isEmpty else { return true }
        guard let textField = textField as? TextField, let index = textFields.firstIndex(of: textField) else { return false }
        // 入力された文字列の先頭6文字が数字だったらSMSコード送信
        if let numbers = firstSixNumbers(string) {
            setSixNumbers(numbers: numbers)
            view.endEditing(true)
            verify()
        } else if let number = firstNumber(string) {
            // 1つ次の入力欄に移動
            if index < textFields.count - 1 {
                textField.text = String(number)
                textFields[index + 1].becomeFirstResponder()
            // 6文字目だったらSMSコード送信
            } else {
                textField.text = String(number)
                view.endEditing(true)
                verify()
            }
        }
        return false
    }
    
    private func firstSixNumbers(_ input: String) -> String? {
        let numbers = input.filter { "0123456789".contains($0) }
        guard numbers.count >= 6 else { return nil }
        let sixNumbers = numbers.prefix(6)
        return String(sixNumbers)
    }
    
    public func firstNumber(_ input: String) -> Character? {
        input.filter { "0123456789".contains($0) }.first
    }
    
    private func setSixNumbers(numbers: String) {
        guard numbers.count == 6 else { return }
        numbers.enumerated().forEach {
            textFields[$0.offset].text = String($0.element)
        }
    }
    
    func textFieldDidChangeSelection(_: UITextField) {
        sendButton.isEnabled = verificationCode != nil
    }
}
