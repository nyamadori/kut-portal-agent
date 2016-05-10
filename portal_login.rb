require 'mechanize'
require 'openssl'
require 'dotenv'

class KUTPortal
  attr_reader :agent
  AUTH_URL = 'https://portal.kochi-tech.ac.jp/'
  TA_SUBJECTS_PATH = '/Portal/StudentApp/TA/WorkSumList.aspx'

  def initialize
    @agent = Mechanize.new { |a| a.user_agent_alias = 'Windows Mozilla' }
    # ポータルの証明書が原因でアクセスに失敗するため、証明書を確認しないようにする
    @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @agent.cookie_jar.load('cookie.yml', session: true)
  end

  def start
    @agent.get AUTH_URL
  end

  def login(username, password)
    form = @agent.page.forms[0]
    form['j_username'] = username
    form['j_password'] = password
    form.click_button # submit

    # Mechanize は JavaScript をサポートしないため、ポータルサイトが警告を発するが
    # [Continue] ボタンをクリックして無視する
    @agent.page.forms[0].click_button
    @agent.cookie_jar.save('cookie.yml', session: true)
  end

  def logging_in?
    @agent.get AUTH_URL
    !!@agent.page.at('img[alt=ログアウト]')
  end

  def ta
    @agent.get(TA_SUBJECTS_PATH)
  end
end

Dotenv.load

portal = KUTPortal.new
portal.start
portal.login(ENV['USERNAME'], ENV['PASSWORD']) unless portal.logging_in?
portal.ta

puts portal.agent.page.body
