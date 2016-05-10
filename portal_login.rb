require 'mechanize'
require 'openssl'

class KUTPortal
  attr_reader :agent
  AUTH_URL = 'https://portal.kochi-tech.ac.jp/'
  TA_SUBJECTS_PATH = '/Portal/StudentApp/TA/WorkSumList.aspx'

  def initialize
    @agent = Mechanize.new { |a| a.user_agent_alias = 'Windows Mozilla' }
    # ポータルの証明書が原因でアクセスに失敗するため、証明書を確認しないようにする
    @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  def login(username, password)
    @agent.get AUTH_URL
    form = @agent.page.forms[0]
    form['j_username'] = username
    form['j_password'] = password
    form.click_button # submit

    # Mechanize は JavaScript をサポートしないため、ポータルサイトが警告を発するが
    # [Continue] ボタンをクリックして無視する
    @agent.page.forms[0].click_button
  end

  def ta
    @agent.get(TA_SUBJECTS_PATH)
  end
end

portal = KUTPortal.new
puts KUTPortal::AUTH_URL
portal.login('id', 'pass')
portal.ta
puts portal.agent.page.body
