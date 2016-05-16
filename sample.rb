# coding: utf-8
require 'dotenv'
require 'pp'
require 'io/console'
require './kut_portal'

Dotenv.load

portal = KUTPortal.new
portal.start
portal.restore_session

if portal.need_login?
  print 'ユーザID: '
  username = gets.chop
  print 'パスワード: '
  password = STDIN.noecho(&:gets).chop
  puts

  unless portal.login(username, password)
    puts 'ログイン失敗!'
    exit 1
  end
end

print '科目: '
subject = gets.chop
print '名目: '
summary = KUTPortal::TA_WORK_SUMMARIES[:"#{gets.chop}"]
print '日付: '
date = gets.chop
print '開始: '
started = gets.chop
print '終了: '
finished = gets.chop
print '休憩時間: '
rest_hours = gets.chop

unless portal.add_ta_work_record(subject, summary, date, started, finished, rest_hours)
  puts '勤務記録追加失敗!'
end
