require "logger"
#TODO: 
# => 1.ignore comment[DONE]
# => 2.support array
# => 3.nice print if attibute does not exist,method_miss?, optional, mandantory attr
#    attribute becomes optional(error, instance.title.optional=true), default instance.title.default=[]
# => 4.key can inclue space[DONE]
class PropertyParser
	def initialize
		@properies = {}
		@logger = Logger.new(STDOUT)
    #@logger.level = Logger::DEBUG
    @logger.level = Logger::WARN
	end

	protected
	def getObject(key)
		@logger.debug "-key:#{key}"
		ret = nil
		value = @properies[key]
		assert(key.split(".").size <= 2, "Too much for key:#{key}...") # can not has too much like, a.b.c
		return ret if value == nil or key.nil? or value.strip == ""

		typeKey = "#{key}.type"
		type = @properies[typeKey]
		type = type.downcase if not type.nil?

		@logger.debug "#{typeKey}=>#{type}"
		case type
		when "string"
			ret = value
		when "strings"
			ret = value.split(",").map { |v| v.strip }
		when nil 
			ret = value
		when "regexp"
			check = (value[0] == value[-1]) and value[0] == "/"
			assert(check, "Please config Regexp with /xxx/...")
			ret = Regexp.new value[1..-2]
		when "class"
		  attributes = []
			values = []

			@properies.keys.each do |key1|
				if key1.start_with? ("#{value}.") and not key1 =~ /.type$/ #end_with? type
					attribute = key1.gsub("#{value}.", "")
					if attribute != key1
						attributes << attribute.to_sym  #symbol as const to Struct
						values << getObject(key1)
					end
				end
			end
			className = key.split(".")[-1]
			className = className.split('_').collect(&:capitalize).join
			assert(attributes.size != 0, "Class :#{value} does not have attribute...")
			klass = Object.const_set className, Struct.new(*attributes)
			ret = klass.new(*values)
		else 
			throw "unsupported type:#{type}..."	
		end
		@logger.debug "#{ret.inspect}\n"
		ret
	end

  def assert(expr, comment = nil)
  	throw "Assert!,#{comment}..." if not expr
  end

	def loadProperties(propertyPath)
		properies = {}
		regexComment = Regexp.new('^(\s*)#')
		File.open(propertyPath, "r") do |file|
			file.each_line do |line|
				line = line.strip
				if line =~ regexComment or line == "" #skip comment and empty line
					next
				end
				#puts line.inspect
				# kv = line.split('=').map{|kv| kv.strip}
				#support a = b = c
				kv = []
				kv[0] = line.split('=')[0].strip
				invalidKeys = kv[0].split(".").select{|key| key =~ /\W+/ }
				assert(invalidKeys.size == 0, "Line:#{line} has invalid char...")

				kv[1] = line.split('=')[1..-1].join("=").strip
				check = (kv.size == 2) and (kv[0].to_s != "") and (kv[1].to_s != "")
				assert(check, "Line:#{line} has worng configuration...")
				properies[kv[0]] = kv[1]
			end
		end
		@logger.debug properies.inspect
		@properies = properies
	end

	public
  def get(key)
		ret = getObject(key)
		@logger.info "Load Object=>" + ret.inspect
		ret
	end

	def parse(propertyPath)
    loadProperties(propertyPath)
	end
end