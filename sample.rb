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
