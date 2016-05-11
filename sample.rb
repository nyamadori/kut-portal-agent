require 'dotenv'
require 'pp'
require './kut_portal'

Dotenv.load

portal = KUTPortal.new
portal.start
portal.restore_session

if portal.need_login?
  unless portal.login(ENV['USERNAME'], ENV['PASSWORD'])
    puts 'ログイン失敗!'
    exit 1
  end
end

pp portal.ta_subjects
pp portal.ta_works('コンピュータリテラシ')
# portal.record_ta_work('コンピュータリテラシ', '2016/05/12', '8:50', '10:20')
