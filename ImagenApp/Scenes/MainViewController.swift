import UIKit

class MainViewController: UIViewController {
    // MARK: - Properties
    private let imagenService = ImagenService()
    
    // MARK: - UI Components
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private lazy var promptTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter your image description..."
        textField.borderStyle = .roundedRect
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .none
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        textField.smartInsertDeleteType = .no
        textField.keyboardType = .asciiCapable
        textField.enablesReturnKeyAutomatically = true
        textField.backgroundColor = .secondarySystemBackground
        textField.textColor = .label
        textField.delegate = self
        textField.textContentType = .none
        textField.autocorrectionType = .no
        
        textField.inputAccessoryView = nil
        textField.autocapitalizationType = .none
        return textField
    }()
    
    private lazy var generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Generate Image", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var resultImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        registerForKeyboardNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Imagen"
        
        view.addSubview(containerView)
        containerView.addSubview(promptTextField)
        containerView.addSubview(generateButton)
        containerView.addSubview(resultImageView)
        containerView.addSubview(activityIndicator)
        
        setupConstraints()
        setupKeyboardDismissGesture()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        promptTextField.translatesAutoresizingMaskIntoConstraints = false
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        resultImageView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            promptTextField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            promptTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            promptTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            promptTextField.heightAnchor.constraint(equalToConstant: 44),
            
            generateButton.topAnchor.constraint(equalTo: promptTextField.bottomAnchor, constant: 16),
            generateButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            generateButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            generateButton.heightAnchor.constraint(equalToConstant: 44),
            
            resultImageView.topAnchor.constraint(equalTo: generateButton.bottomAnchor, constant: 20),
            resultImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            resultImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            resultImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            activityIndicator.centerXAnchor.constraint(equalTo: resultImageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: resultImageView.centerYAnchor)
        ])
    }
    
    private func setupKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillShow),
                                             name: UIResponder.keyboardWillShowNotification,
                                             object: nil)
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillHide),
                                             name: UIResponder.keyboardWillHideNotification,
                                             object: nil)
    }
    
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve)) {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: -insets.bottom)
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve)) {
            self.containerView.transform = .identity
        }
    }
    
    @objc private func dismissKeyboard() {
        promptTextField.resignFirstResponder()
    }
    
    // MARK: - Actions
    @objc private func generateButtonTapped() {
        guard let prompt = promptTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !prompt.isEmpty else {
            showAlert(title: "Error", message: "Please enter an image description")
            return
        }
        
        dismissKeyboard()
        activityIndicator.startAnimating()
        generateButton.isEnabled = false
        
        imagenService.generateImage(from: prompt) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.generateButton.isEnabled = true
                
                switch result {
                case .success(let image):
                    self?.resultImageView.image = image
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension MainViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.keyboardType = .asciiCapable
        textField.reloadInputViews()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.inputAccessoryView = nil
        textField.reloadInputViews()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text, !text.isEmpty {
            generateButtonTapped()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            return true
        }
        
        let allowedCharacters = CharacterSet(charactersIn: " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-")
        return string.rangeOfCharacter(from: allowedCharacters.inverted) == nil
    }
}

// Helper extension to check for emoji
extension String {
    var containsEmoji: Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
                 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
                 0x1F680...0x1F6FF, // Transport and Map
                 0x1F1E6...0x1F1FF, // Regional country flags
                 0x2600...0x26FF,   // Misc symbols
                 0x2700...0x27BF,   // Dingbats
                 0xFE00...0xFE0F,   // Variation Selectors
                 0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                 0x1F018...0x1F0FF: // Various asian characters
                return true
            default:
                continue
            }
        }
        return false
    }
} 
