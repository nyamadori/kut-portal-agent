require 'mechanize'
require 'openssl'

class KUTPortal
  attr_reader :agent, :ta_subjects
  INDEX_URL = 'https://portal.kochi-tech.ac.jp/'
  TA_SUBJECTS_PATH = '/Portal/StudentApp/TA/WorkSumList.aspx'
  TA_SUBJECTS_TABLE = '#ctl00_phContents_TaWorkSumList1_gvWorkSum'
  TA_WORKS_TABLE = '#ctl00_phContents_TaWorkList1_gvWork'

  def initialize
    @agent = Mechanize.new { |a| a.user_agent_alias = 'Windows Mozilla' }
    # ポータルの証明書が原因でアクセスに失敗するため、証明書を確認しないようにする
    @agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  def restore_session
    return unless File.exist?('cookie.yml')
    @agent.cookie_jar.load('cookie.yml', session: true)
  end

  def start
    @agent.get INDEX_URL
  end

  def login(username, password)
    form = @agent.page.forms[0]
    form['j_username'] = username
    form['j_password'] = password
    form.click_button # submit

    # ログイン失敗
    return false if @agent.page.at('.form-element.form-error')

    # Mechanize は JavaScript をサポートしないため、ポータルサイトが警告を発するが
    # [Continue] ボタンをクリックして無視する
    @agent.page.forms[0].click_button
    @agent.cookie_jar.save('cookie.yml', session: true)

    true
  end

  def logging_in?
    @agent.get INDEX_URL
    !!@agent.page.at('img[alt=ログアウト]')
  end

  def need_login?
    !logging_in?
  end

  def ta_subjects
    @agent.get(TA_SUBJECTS_PATH)
    table = @agent.page.at(TA_SUBJECTS_TABLE)
    rows = table.search('tr')

    subjects = rows.map do |row|
      values = row.search('td').map do |col|
        col.text.delete("\n\t\r  ")
      end

      keys = %i(num term subject_id subject_name teacher pay_unit hours total_hours plan_hours overtime_hours)
      Hash[keys.zip(values)]
    end

    subjects.shift
    subjects
  end

  def ta_works(subject_name)
    subject = ta_subjects.find { |s| s[:subject_name].include?(subject_name) }
    tr_query = "#{TA_SUBJECTS_TABLE} tr:nth-of-type(#{subject[:num].to_i + 1})"
    tr = @agent.page.at(tr_query)
    form = @agent.page.forms[0]
    new_record_btn = form.button_with(value: /登録/)
    form.click_button(new_record_btn)
    tbl_rows = @agent.page.search("#{TA_WORKS_TABLE} tr")

    works = tbl_rows.map do |row|
      values = row.search('td').map { |col| col.text.delete("\n\t\r  ") }
      keys = %i(date summary started finished rest_hours total_hours)
      Hash[keys.zip(values)]
    end

    works.shift
    works
  end
end
