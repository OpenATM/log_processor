TEST = true
require 'fileutils'
require File.join(File.dirname(__FILE__), "../property_parser.rb")
require 'rspec'

#test class wrap for testing protected method processLine

describe "Property Parser class" do
	before do
		@testDir = File.dirname(__FILE__)
		@properties = @testDir + "/../config.properties"
		FileUtils.cp @testDir + "/propertes_basic.properties", @properties
		@propertyParser = PropertyParser.new
	end
	after do 
		FileUtils.rm_rf @properties
	end

	it "Parse property file" do
		@propertyParser.parse @properties
		puts ">>>>--------------"
		student = @propertyParser.get('student')
		studentRef ='#<struct Student name="zhangshang", num="1323332", teacher=#<struct Teacher name="\"gaoyuliang1\"", age="50">, books="[sg,hlm]">'
		expect(student.to_s).to eq studentRef

		teacherRef = "#<struct Teacher name=\"\\\"gaoyuliang1\\\"\", age=\"50\">"
		expect(student.teacher.to_s).to eq teacherRef
		teacher = @propertyParser.get('zhangshang.teacher')
		expect(teacher.to_s).to eq teacherRef
		#property_parser.rb:52: warning: already initialized constant Teacher

		ip = @propertyParser.get('ip')
		expect(ip).to eq "132.322.22.2"

		ip_nil = @propertyParser.get('ip1')
		expect(ip_nil).to eq nil

		lineRegexp = @propertyParser.get('line_regexp')
		lineRegexpRef = "#<struct LineRegexp regexp=/a.*b.=c/, title=[\"t1\", \"t2\", \"t3\"]>"
		expect(lineRegexp.to_s).to eq lineRegexpRef
	end
end