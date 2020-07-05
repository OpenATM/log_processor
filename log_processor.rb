#@707290451@qq.com
#TODO:add command args to set line_regex 
# config line_regex,title in coinfig.properties first.
# class for process log file data to csv.
# for programming usage:e.g.
#     log = LogProcessor.new
#     log.line_regex = /: var1=(.*), var2=(.*), var3=(.*)/
#     log.title = ["var1", "var2", "var3"]
#     log.processFile('.\testfiles\test.log', '.\testfiles\out.csv')
require 'optparse'
require 'set'
require File.dirname(__FILE__) + "/property_parser.rb"
require File.dirname(__FILE__) + "/config.rb" if File.exist? File.dirname(__FILE__) + "/config.rb"
require 'pathname'
module CommonExcelMethod

  def dBm2lin(dbmNum)
    (10**(dbmNum.to_f/10)).round(2)
  end

  def lin2dBm(linNum)
    ((Math.log linNum,10) * 10).round(2)
  end

  def to_numeric(str)
    str = str.to_s
    ret = nil
    if str.to_i.to_s == str
      ret = str.to_i
    elsif str.to_f.to_s == str
      ret = str.to_f
    else
      throw "Error: unrecognized str:#{str.inspect} to number..."
    end
    ret
  end

  MAX_16_SIGNED = "7FFF".hex
  MAX_16_UNSIGNED = "FFFF".hex
  def getComplement(str)
    value = str.hex
    if value > MAX_16_SIGNED
      value = - (MAX_16_UNSIGNED - value + 1)
    end
    value
  end

  def sort_by_index(table, colIndex, desc = false)
    table.sort! do |x, y|
      assert(colIndex < x.size, "colIndex:#{colIndex} exceeds size of #{x.inspect}")
      ret = 0
      if desc
        ret = y[colIndex] <=>  x[colIndex]
      else
        ret = x[colIndex] <=>  y[colIndex]
      end
      ret
    end
  end

  def get_column_values_by_index(table, colIndex)
    set = Set.new
    table.each do |row|
      assert(colIndex < row.size, "colIndex:#{colIndex} exceeds size of #{row.inspect}")
      set << row[colIndex].strip
    end
    set.to_a.sort!
  end

  def average_by_index(table, colIndex, replaceHash={}, sumOnly = false)
    # colIndex = title.index(colName)
    sum = 0
    rowNum = 0
    return if table == nil
    table.each_with_index do |row, index|
      skip = false
      valueStr = row[colIndex]
      if replaceHash.has_key? valueStr
        valueStr = replaceHash[valueStr]
        if valueStr.nil?
          next
        end
      end
      begin
        value = to_numeric(valueStr)
      rescue Exception => e
        value, skip = (yield value, row) if block_given?
        if not skip
          raise "Row:#{index},column:#{colIndex} cannot convert #{valueStr.inspect} to number,#{e.to_s}..."
        else
          #puts "Error,Row:#{index},column:#{colIndex} cannot convert #{valueStr.inspect} to number,#{e.to_s}..."
          next # skip the exception value
        end
      end
      value, skip = (yield value, row) if block_given? 
      next if skip

      sum += value
      rowNum += 1
      #debug trace
      #if (rowNum > 245)
        #puts "value#{value.inspect}, sum:#{sum}, rowNum:#{rowNum}"
      #end
    end
    return sum if sumOnly
    if rowNum == 0
      puts "WARNING:No row select to do average for column:#{colIndex}..."
      return 0
    end
    throw "No row select to do average..." if rowNum == 0
    return (sum.to_f/rowNum).round(2)
  end

  #depracated, use average_by_index instead
  def average(colName, title, table, replaceHash={}, sumOnly = false)
    colIndex = title.index(colName)
    sum = 0
    rowNum = 0
    return if table == nil
    table.each_with_index do |row, index|
      valueStr = row[colIndex]
      if replaceHash.has_key? valueStr
        valueStr = replaceHash[valueStr]
        if valueStr.nil?
          next
        end
      end
      begin
        value = to_numeric(valueStr)  
        value, skip = (yield value, row) if block_given? 
        next if skip
      rescue Exception => e
        raise "Row:#{index+1} cannot convert #{valueStr.inspect} to number,#{e.to_s}..."
      end
      sum += value
      rowNum += 1
      #debug trace
      if (rowNum > 245)
        puts "value#{value.inspect}, sum:#{sum}, rowNum:#{rowNum}"
      end
    end
    return sum if sumOnly
    return (sum.to_f/rowNum).round(2)
  end

#　common method
  #Process one single line
  def processLine(line, regex = nil)
    ret = []
    regex = line_regex if regex == nil
    # matchData = regex.match line
    # if matchData != nil
    #   ret = matchData.to_a[1..-1]
    # end
    # return ret
    ret = line.scan(regex)
    ret = (ret.size == 0 ? [] : ret[0])
    return ret
  end

  def assert(expr, comment = nil)
    throw "Assert!,#{comment}..." if not expr
  end
end

#
class LogProcessor
    #*line_regex is the regex expression to parse log file
    #*title is the name for each column
  include PostProcess if File.exist? File.dirname(__FILE__) + "/config.rb"
  include CommonExcelMethod
  attr_accessor :line_regex, :title

  def initialize(console=false)
    @line_regex = nil
    @title = []
    @name = nil
    @console = console #console output?
    @outPath = nil #this can be used in config.rb
  end

  protected

  # Write matrix to outPath file
  def formatMatrix2File(matrix, outPath = "out.csv")
    return if matrix.size == 0
    # if @title.size == 0 or @title.nil?
    #   for i in 1..matrix[0].size
    #     @title << "column" + "#{i}"
    #   end
    # end
    File.open(outPath, "w") do |file|
      file.puts @title.join(",")
      matrix.each do |lineArr|
        next if lineArr.size == 0
        throw Exception.new("@title size:#{@title.size} not equal data row size #{lineArr.size}:#{lineArr.join(',')}...") if @title.size != lineArr.size
        file.puts lineArr.join(",")
      end
    end
  end

  public
  def loadCSVFile(filePath)
    table = []
    File.open(filePath, "r") do |file|
      file.each_line do |line|
        line = line.strip
        row = line.split(",") 
        if line[-1] == ","
          row << ""
        end 
        table << row
      end
    end
    table
  end

  def loadRegexpConfig(configPath = nil)
    title = []
    lineRegex = nil
    name = nil
    if(configPath == nil)
      configPath = File.dirname(__FILE__) + "/config.properties"
    end
    propertyParser = PropertyParser.new
    propertyParser.parse(configPath)
    lineRegex = propertyParser.get("line_regex")
    if lineRegex != nil
      title = lineRegex.title.nil? ? [] : lineRegex.title
      line_regex = lineRegex.regexp
      name = lineRegex.name
    end
    [name, title, line_regex]
  end
  # 1. load config.properties
  # 2. load log file
  # 3. post process specified by config.rb
  # 4. write to csv file
  def processFile(filePath, outPath = nil)
    #1
    if @line_regex.nil?
      #loadConfig
      @name, @title, @line_regex = loadRegexpConfig
    end
    @outPath = outPath
    @outPath =  File.join File.dirname(filePath), File.basename(filePath, File.extname(filePath)) \
      + "#{@name.nil? ? "" : "_"+@name}.csv" if @outPath.nil?
    retMatrix = []

    #2
    if File.extname(filePath) == ".csv"
      puts "Load csv file:#{filePath}"
      retMatrix = loadCSVFile(filePath)
    else
      throw Exception.new("@line_regex must be specified for parsing...") if line_regex == nil
      #TODO:merge below conditions
      if @line_regex.inspect.include? '\n' # multi line matches
        content = IO.read(filePath) 
        retMatrix = content.scan(@line_regex)
      else #single line matches
        File.open(filePath, "r") do |file|
          # puts file
          file.each_line do |line|
            # puts line + ";"
            lineData = processLine(line) 
            if(lineData.size != 0)
              retMatrix << lineData
            end
          end
        end
      end
    end 
    retMatrix = (yield retMatrix) if block_given?
    if retMatrix.size == 0
      puts "No content filtered from #{filePath}..."
      return
    end
    #fill the title if it is not configured.
    if @title.size == 0 or @title.nil?
      for i in 1..retMatrix[0].size
        @title << "column" + "#{i}"
      end
    end
    #3.post process,reading post_method from config.rb
    if not @name.nil?
      post_method = @name + "_process"
      if self.respond_to? post_method
        puts "Post method #{post_method} in config.rb is called..."
        @title, retMatrix = self.send(post_method, @title, retMatrix)
      end
    end
    #post process end
    #4
    if retMatrix.size == 0
      puts "No data extracted from file #{filePath}" 
    elsif @console
      retMatrix.each do |lineArr|
        puts lineArr.join " "
      end
    else
      input_path = Pathname.new(filePath).realpath.to_s
      throw Exception.new("It seems that outfile name is identical with input file, please debug...") if (File.join @outPath) == input_path
      puts "Total #{retMatrix.size} rows * #{@title.size} columns, output to file #{@outPath}."
      formatMatrix2File(retMatrix, @outPath)
    end
  end
end

if (defined? TEST).nil? #ifndef
  options = {}
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: log_processor.rb [options]"

    opts.on("-fNAME", "--file Name", "The file to parse") do |v|
      options[:file] = v
    end
    opts.on("-r", "--regex Regexp", Regexp, "The regex for parsing") do |v|
      options[:regex] = v
    end
    options[:console] = false
    opts.on("-c", "--console", "Console output") do |v|
      options[:console] = v
    end

  end.parse!

  if not options[:file].nil?
    log = LogProcessor.new options[:console]
    if not options[:regex].nil?
      log.line_regex = options[:regex]
    end
    log.processFile(options[:file])
  else
  #puts "Usage: log_processor /path/to/log_file or /path/to/csv_file"
   puts "Use -h get the usage..."
  end
end
