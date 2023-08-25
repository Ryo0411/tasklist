import UIKit
import RealmSwift
import UserNotifications


class InputViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextView: UITextField!
    
    let realm = try! Realm()
    var task: Task!
    
    var categories: [String] = []
    let pickerView = UIPickerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Getting unique categories from Task objects
        let allTasks = realm.objects(Task.self)
        var categoriesSet = Set<String>()
        for task in allTasks {
            categoriesSet.insert(task.category)
        }
        categories = Array(categoriesSet)
        
        titleTextField.backgroundColor = UIColor(white: 0.95, alpha: 1)
        contentsTextView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        categoryTextView.backgroundColor = UIColor(white: 0.95, alpha: 1)
//        pickerView.backgroundColor = UIColor.white
        
        
        // UIPickerViewの設定
        pickerView.delegate = self
        pickerView.dataSource = self

        // UITextFieldのinputViewとしてUIPickerViewを設定
        categoryTextView.inputView = pickerView

        // UITextFieldのdelegate設定
        categoryTextView.delegate = self

        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)

        titleTextField.text = task.title
        contentsTextView.text = task.contents
        categoryTextView.text = task.category
        datePicker.date = task.date
    }

    override func viewWillDisappear(_ animated: Bool) {
        try! realm.write {
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.category = self.categoryTextView.text!
            self.task.date = self.datePicker.date
            self.realm.add(self.task, update: .modified)
        }

        setNotification(task: task)   // 追加

        super.viewWillDisappear(animated)
    }
    
    // MARK: UIPickerView DataSource and Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryTextView.text = categories[row]
        view.endEditing(true)
    }

    // UITextField Delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if categoryTextView.text == "" {
            categoryTextView.text = categories[0]
        }
    }

    // タスクのローカル通知を登録する --- ここから ---
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になるので「(xxなし)」を表示する)
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }
        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }
        content.sound = UNNotificationSound.default

        // ローカル通知が発動するtrigger（日付マッチ）を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id.stringValue), content: content, trigger: trigger)

        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print(error ?? "ローカル通知登録 OK")  // error が nil ならローカル通知の登録に成功したと表示します。errorが存在すればerrorを表示します。
        }

        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
        }
    } // --- ここまで追加 ---

    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }
}
