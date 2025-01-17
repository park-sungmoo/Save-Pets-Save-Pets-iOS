//
//  OwnerProfileViewController.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/04.
//

import UIKit

class OwnerProfileViewController: UIViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var ownerNameView: UIView!
    @IBOutlet weak var ownerNameTextField: UITextField!
    @IBOutlet weak var ownerPhoneNumberView: UIView!
    @IBOutlet weak var ownerPhoneNumberTextField: UITextField!
    @IBOutlet weak var ownerEmailView: UIView!
    @IBOutlet weak var ownerEmailTextField: UITextField!
    @IBOutlet weak var enrollmentButton: UIButton!
    
    // MARK: - Variables
    
    var enrollment: Enrollment?
    private var ownerName: String?
    private var ownerPhoneNumber: String?
    private var ownerEmail: String?
    private weak var enrollmentLoadingViewController: EnrollmentLoadingViewController?
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeOwnerProfileViewController()
        self.initializeTextFieldView()
    }
    
    // MARK: - Functions
    
    private func initializeOwnerProfileViewController() {
        self.enrollmentButton.roundUp(radius: 12)
        self.ownerNameView.roundUp(radius: 12)
        self.ownerPhoneNumberView.roundUp(radius: 12)
        self.ownerEmailView.roundUp(radius: 12)
        
        self.disableEnrollmentButton()
        self.ownerNameView.setBorder(color: UIColor.systemGray4.cgColor, width: 0.3)
        self.ownerPhoneNumberView.setBorder(color: UIColor.systemGray4.cgColor, width: 0.3)
        self.ownerEmailView.setBorder(color: UIColor.systemGray4.cgColor, width: 0.3)
    }
    
    private func initializeTextFieldView() {
        self.ownerNameTextField.delegate = self
        self.ownerPhoneNumberTextField.delegate = self
        self.ownerEmailTextField.delegate = self
    }
    
    private func enableEnrollmentButton() {
        self.enrollmentButton.isEnabled = true
        self.enrollmentButton.backgroundColor = UIColor.systemOrange
    }
    
    private func disableEnrollmentButton() {
        self.enrollmentButton.isEnabled = false
        self.enrollmentButton.backgroundColor = UIColor.lightGray
    }
        
    private func presentEnrollmentLoadingViewController() {
        let mainStoryboard = UIStoryboard(name: AppConstants.Name.mainStoryboard, bundle: nil)
        guard let enrollmentLoadingViewController = mainStoryboard.instantiateViewController(identifier: AppConstants.Identifier.enrollmentLoadingViewController) as? EnrollmentLoadingViewController else {
            return
        }
        
        self.enrollmentLoadingViewController = enrollmentLoadingViewController
        enrollmentLoadingViewController.dogName = self.enrollment?.dog?.name
        enrollmentLoadingViewController.modalPresentationStyle = .fullScreen
        
        present(enrollmentLoadingViewController, animated: true, completion: nil)
    }
    
    private func pushToEnrollmentResultViewController(enrollmentResult: EnrollmentResult) {
        let mainStoryboard = UIStoryboard(name: AppConstants.Name.mainStoryboard, bundle: nil)
        guard let enrollmentResultViewController = mainStoryboard.instantiateViewController(identifier: AppConstants.Identifier.enrollmentResultViewController) as? EnrollmentResultViewController else {
            return
        }
        
        enrollmentResultViewController.enrollmentResult = enrollmentResult
        
        self.navigationController?.pushViewController(enrollmentResultViewController, animated: true)
    }
    
    private func verifyProperty(_ name: String?) -> Bool {
        guard let unwrappedName = name else { return false }
        return !unwrappedName.isEmpty
    }
    
    private func verify() -> Bool {
        return self.verifyProperty(self.ownerName) && self.verifyProperty(self.ownerPhoneNumber) && self.verifyProperty(self.ownerEmail)
    }
    
    private func updateEnrollmentButton() {
        let isVerified = self.verify()
        isVerified ? self.enableEnrollmentButton() : self.disableEnrollmentButton()
    }

    @IBAction func enrollmentButtonTouchUp(_ sender: UIButton) {
        
        guard let name = self.ownerName, let phoneNumber = self.ownerPhoneNumber, let email = self.ownerEmail else { return }
        
        self.enrollment = Enrollment(
            owner: Owner(name: name, phoneNumber: phoneNumber, email: email),
            dog: self.enrollment?.dog,
            firstImage: self.enrollment?.firstImage,
            secondImage: self.enrollment?.secondImage,
            thirdImage: self.enrollment?.thirdImage,
            firthImage: self.enrollment?.firthImage,
            fifthImage: self.enrollment?.fifthImage
        )
        
        // 로딩화면 띄우기
        self.presentEnrollmentLoadingViewController()
        
        // 서버로 등록 API 요청 보내기
        DispatchQueue.global().async {
            self.postEnrollmentWithAPI(enrollment: self.enrollment) { result in
                self.enrollmentLoadingViewController?.dismiss(animated: true, completion: nil)
                self.pushToEnrollmentResultViewController(enrollmentResult: result)
            }
        }
    }
}

// MARK: - TextFieldDelegate

extension OwnerProfileViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField.isEqual(self.ownerNameTextField) {
            self.ownerName = self.ownerNameTextField.text
        } else if textField.isEqual(self.ownerPhoneNumberTextField) {
            self.ownerPhoneNumber = self.ownerPhoneNumberTextField.text
        } else {
            self.ownerEmail = self.ownerEmailTextField.text
        }
        self.updateEnrollmentButton()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isEqual(self.ownerNameTextField) {
            self.ownerName = self.ownerNameTextField.text
            self.ownerPhoneNumberTextField.becomeFirstResponder()
        } else if textField.isEqual(self.ownerPhoneNumberTextField) {
            self.ownerPhoneNumber = self.ownerPhoneNumberTextField.text
            self.ownerEmailTextField.becomeFirstResponder()
        } else {
            self.ownerEmail = self.ownerEmailTextField.text
            self.ownerEmailTextField.resignFirstResponder()
        }
        self.updateEnrollmentButton()
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - API Services

extension OwnerProfileViewController {
    
    private func postEnrollmentWithAPI(
        enrollment: Enrollment?,
        completion: @escaping (EnrollmentResult) -> Void
    ) {
        
        guard let ownerName = self.enrollment?.owner?.name,
              let phoneNumber = self.enrollment?.owner?.phoneNumber,
              let email = self.enrollment?.owner?.email,
              let dogName = self.enrollment?.dog?.name,
              let dogBreed = self.enrollment?.dog?.breed,
              let dogBirthYear = self.enrollment?.dog?.birthYear,
              let dogSex = self.enrollment?.dog?.sex,
              let dogProfileImage = self.enrollment?.dog?.profile,
              let firstImage = self.enrollment?.firstImage,
              let secondImage = self.enrollment?.secondImage,
              let thirdImage = self.enrollment?.thirdImage,
              let firthImage = self.enrollment?.firthImage,
              let fifthImage = self.enrollment?.fifthImage
              else {
            return
        }
        
        EnrollmentService.shared.postEnrollment(
            ownerName: ownerName,
            phoneNumber: phoneNumber,
            email: email,
            dogName: dogName,
            dogBreed: dogBreed,
            dogBirthYear: dogBirthYear,
            dogSex: dogSex,
            dogProfileImage: dogProfileImage,
            firstDogNoseImage: firstImage,
            secondDogNoseImage: secondImage,
            thirdDogNoseImage: thirdImage,
            firthDogNoseImage: firthImage,
            fifthDogNoseImage: fifthImage
        ) { (result) in
            switch result {
            case .success(let data):
                if let enrollmentResult = data as? EnrollmentResult {
                    DispatchQueue.main.async {
                        completion(enrollmentResult)
                    }
                } else {
                    if let enrollmentMessage = data as? String, enrollmentMessage == "fail" {
                        self.enrollmentLoadingViewController?.dismiss(animated: true, completion: nil)
                    }
                }
            case .requestErr:
                print("requestErr")
            case .pathErr:
                print("pathErr")
            case .serverErr:
                print("serverErr")
            case .networkFail:
                print("networkFail")
            }
        }
    }
}
