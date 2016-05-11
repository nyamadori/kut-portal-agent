kut-portal
==========

高知工科大学学生用ポータルシステムのRuby製スクレイピングライブラリ。

使い方
-----

```ruby
require './kut_portal'

portal = KUTPortal.new
portal.start
portal.login('username', 'password')
p portal.ta_subjects # TA担当科目一覧
```

機能一覧
-------

* [x] ログイン
* [x] TA担当科目一覧取得

実装予定
------

### 時間割

* [ ] 時間割取得

### シラバス

* [ ] 科目検索
* [ ] 科目情報取得

### TA (Teaching Assistant)

* [ ] TA出勤記録追加
* [ ] TA出勤記録編集
* [ ] TA出勤記録削除
