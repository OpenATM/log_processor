module PostProcess
  #Help method:
  # replaceHash = {""=>0, "ERROR"=>nil} =>nil will counting this row
  # 1. average(colName, title, table, replaceHash={}) => return average of colName ##depracated, use average_by_index instead
  # 2. average_by_index(table, colIndex, replaceHash={}, sumOnly = false)
  # 3. sort_by_index(table, colIndex, desc = false)
  # 4. dBm2lin(dbmNum)
  # 5. lin2dBm(linNum)
  # 6. to_numeric(str)
  # 7. getComplement(str)
  # 8. get_column_values_by_index(table, colIndex)
  # 9. processLine(line, regex = nil)

	#post process method, defined as "regex_configed_in_poperties" + "_process"
	#it will be invoked automatically
	## title:table column name array
	## table:parsed table
	## return modified [title,table]
	def mytest_re_process(title, table)
		title << "sum"
		table.each do |row|
			row << row.join("")
		end
		table << ["average", average("title2", title, table, {""=>0}), "", ""]
		[title,table]
	end

	def csv_input_process(title, table)
		title = table[0]
		table = table[1..-1]
		sort_by_index(table, 1)
		[title,table]
	end
end