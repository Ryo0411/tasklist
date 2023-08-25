import RealmSwift

class Task: Object {
    // 管理用 ID。プライマリーキー
    @Persisted(primaryKey: true) var id: ObjectId

    // タイトル
    @Persisted var title = ""

    // 内容
    @Persisted var contents = ""
    
    // カテゴリー
    @Persisted var category = ""

    // 日時
    @Persisted var date = Date()

}
