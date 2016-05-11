module Util
  def self.table_rows_to_records(tbl_rows, *keys)
    records = tbl_rows.map do |row|
      values = row.search('td').map { |col| col.text.delete("\n\t\r  ") }
      Hash[keys.zip(values)]
    end

    records.shift
    records
  end
end
