# coding: utf-8
require 'mechanize'
require 'openssl'
require './util'

class KUTPortal
  attr_reader :agent, :ta_subjects
  INDEX_URL = 'https://portal.kochi-tech.ac.jp/'
  TA_SUBJECTS_PATH = '/Portal/StudentApp/TA/WorkSumList.aspx'
  TA_SUBJECTS_TABLE = '#ctl00_phContents_TaWorkSumList1_gvWorkSum'
  TA_WORKS_TABLE = '#ctl00_phContents_TaWorkList1_gvWork'
  TA_WORK_RECORD_ADD_BTN = '#ctl00$phContents$TaWorkList1$btnNew'
  TA_WORK_RECORD_REMOVE_BTN = '#ctl00_phContents_TaWorkList1_gvWork_ctl02_btnDelete'
  TA_WORK_SUMMARIES = {
    support: '①授業補助',
    prepare: '②授業準備',
    material: '③資料作成',
    other: '④その他',
    support_prepare: '①②授業補助と授業準備',
    support_material: '①③授業補助と資料作成'
  }

  def initialize
    @agent = Mechanize.new do |a|
      a.user_agent_alias = 'Windows Mozilla'
#      a.follow_meta_refresh = true
 #     a.keep_alive = false
    end

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

  def ta_subjects(year = nil, month = nil)
    @agent.get(TA_SUBJECTS_PATH)
    form = @agent.page.forms[0]

    if year
      form['ctl00$phContents$TaWorkSumList1$ddlYear'] = year
      form['__EVENTTARGET'] = 'ctl00$phContents$TaWorkSumList1$ddlYear'
      form['__EVENTARGUMENT'] = ''
      form.submit()
    end

    if month
      form['ctl00$phContents$TaWorkSumList1$ctlMonths$ddlMonth'] = month
      form['__EVENTTARGET'] = 'ctl00$phContents$TaWorkSumList1$ctlMonths$ddlMonth'
      form['__EVENTARGUMENT'] = ''
      form.submit()
    end

    tbl_rows = @agent.page.search("#{TA_SUBJECTS_TABLE} tr")
    keys = %i(num term subject_id subject_name teacher pay_unit hours total_hours plan_hours overtime_hours)
    Util.table_rows_to_records(tbl_rows, *keys)
  end

  def ta_works(subject_name, year = nil, month = nil)
    subject = ta_subjects(year, month).find { |s| s[:subject_name].include?(subject_name) }
    tr_query = "#{TA_SUBJECTS_TABLE} tr:nth-of-type(#{subject[:num].to_i + 1})"
    tr = @agent.page.at(tr_query)
    form = @agent.page.forms[0]
    form.click_button(form.button_with(value: /登録/)) # 科目勤務記録一覧に遷移

    tbl_rows = @agent.page.search("#{TA_WORKS_TABLE} tr")
    keys = %i(num date summary started finished rest_hours total_hours)
    Util.table_rows_to_records(tbl_rows, *keys)
  end
  
  def add_ta_work_record(subject_name, summary, date, started, finished, rest_hours)
    ta_works(subject_name)
    works_form = @agent.page.forms[0]
    add_btn = works_form.button_with(value: /新規追加/)
    works_form.click_button(add_btn) # 科目勤務記録登録に遷移

    form = @agent.page.forms[0]

    # 日付
    form['ctl00$phContents$TaWorkEdit1$ctlWorkDate$txtDate'] = date.strftime('%Y/%m/%d')

    # 開始時間
    form['ctl00$phContents$TaWorkEdit1$ctlStartTime$txtHour'] = started.strftime('%H')
    form['ctl00$phContents$TaWorkEdit1$ctlStartTime$txtMinute'] = started.strftime('%M')

    # 終了時間
    form['ctl00$phContents$TaWorkEdit1$ctlEndTime$txtHour'] = finished.strftime('%H')
    form['ctl00$phContents$TaWorkEdit1$ctlEndTime$txtMinute'] = finished.strftime('%M')

    # 休憩時間
    form['ctl00$phContents$TaWorkEdit1$ctlRestTime$txtHour'] = rest_hours.strftime('%H')
    form['ctl00$phContents$TaWorkEdit1$ctlRestTime$txtMinute'] = rest_hours.strftime('%M')

    # 名目
    form['ctl00$phContents$TaWorkEdit1$ctlWorkDetail$ddlWorkDetail'] = TA_WORK_SUMMARIES[summary]

    form.click_button(form.button_with(value: /登録/))

    error_text_ids =
      %w(ctl00_phContents_TaWorkEdit1_ctlWorkDate_lblError
      ctl00_phContents_TaWorkEdit1_ctlWorkDetail_lblError
      ctl00_phContents_TaWorkEdit1_ctlStartTime_lblError
      ctl00_phContents_TaWorkEdit1_ctlEndTime_lblError
      ctl00_phContents_TaWorkEdit1_lblErr)

    !error_text_ids.any? { |id| !!@agent.page.at("##{id}") }
  end

  def remove_ta_work_record(subject_name, date)
    works = ta_works(subject_name)
    works_form = @agent.page.forms[0]
    rm_work = works.find { |w| w[:date].include?(date) }
    tr_query = "#{TA_WORKS_TABLE} tr:nth-of-type(#{rm_work[:num].to_i + 1})"
    tr = @agent.page.at(tr_query)
    remove_btn = works_form.button_with(id: /#{tr.at('input[value=削除]').attribute('id')}/)
    works_form.click_button(remove_btn) # 削除ボタンをクリック
  end
end
