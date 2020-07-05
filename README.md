# log_processor
A common tool to extract data from large log file, and generate result into excel.
 ## 1. Cmd usage
```
G:\Work\src\log_processor>ruby log_processor.rb -h
Usage: log_processor.rb [options\]
    -f, --file Name                  The file to parse
    -r, --regex Regexp               The regex for parsing
    -c, --console                    Console output
```
-f is mandatory for specifying log path, and it will generate csv for extracted data.<br>

 ## 2. Create config.properties in "log_processor" folder.
 Specify the regular expression to filter data. Or use "-r" instead of config.properties.
 ```
  line_regex = mytest_re
  line_regex.type = class
  mytest_re.title = title1,title2, title3 
  mytest_re.title.type = strings
  # regular expression to filter data, 3 columns data can be got
  mytest_re.regexp = /: var1=(.*), var2=(.*), var3=(.*)/
  mytest_re.regexp.type = regexp
  mytest_re.name = mytest_re
  ```
  
  ## 3. [optional] Create config.rb to config post method to process extracted data. e.g.
``` ruby
	def mytest_re_process(title, table)
		title << "sum"
		table.each do |row|
			row << row.join("")
		end
		table << ["average", average("title2", title, table, {""=>0}), "", ""]
		[title,table]
	end
```
	Please refer more detail in log_test/config.rb.
  ## 4. [development] run unit test case before commit
  ```
  change to the related Dir,
  rspec property_verif.rb
  rspec log_processor_verif.rb
  ```
     <br>config.properties is parsed by class PropertyParser. The idea of PropertyParser is to convert all properties to objects. e.g. config.properties<br>
  ```
student=zhangshang
student.type=class
# properties for student
zhangshang.name=zhangshang
zhangshang.name.type=String
zhangshang.num=1323332
#below is for teacher, class
zhangshang.teacher= LiSi
zhangshang.teacher.type =class
LiSi.name="gaoyuliang1"
LiSi.age=50
  ```
  then we can get the configuration by,
  ``` ruby
  @propertyParser = PropertyParser.new
  @propertyParser.parse config.properties
  student = @propertyParser.get('student') #'#<struct Student name="zhangshang", num="1323332", teacher=#<struct Teacher name="\"gaoyuliang1\"", age="50">, books="[sg,hlm]">'
  teacher = @propertyParser.get('zhangshang.teacher') #"#<struct Teacher name=\"\\\"gaoyuliang1\\\"\", age=\"50\">"

  
  ```

	Any sugestion can contact me by 707290451@qq.com.
