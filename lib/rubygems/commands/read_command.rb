# ReadCommand will open a gem's rdoc
class Gem::Commands::ReadCommand < Gem::Command
  include OpenGem::CommonOptions
  include Gem::VersionOption
  
  def initialize
    super 'read', "Opens the gem's documentation", 
      :command => nil, 
      :version=>  Gem::Requirement.default,
      :latest=>   false
    
    add_command_option "Application to read rdoc with"
    add_latest_version_option
    add_version_option
    add_exact_match_option
  end
  
  def arguments # :nodoc:
    "GEMNAME       gem to read"
  end

  def execute
    name = get_one_gem_name
    spec = get_spec(name){|s| s.has_rdoc? }
    if spec && path = get_path(spec)
      if File.exists? path
        read_gem path
      elsif ask_yes_no "The rdoc seems to be missing, would you like to generate one?", true
        generate_rdoc spec
        read_gem path
      end
    end
  end
  
  def get_path(spec)
    File.join(spec.installation_path, "doc", spec.full_name, 'rdoc','index.html')
  end
  
  def generate_rdoc spec
    Gem::DocManager.new(spec).generate_rdoc
  end
  
  def rdoc_reader
    options[:command] || case RUBY_PLATFORM.downcase
      when /darwin/ then 'open'
      when /mswin/  then 'explorer'
      when /linux/  then 'firefox'
      else               'firefox' # Come on, if you write ruby, you probably have firefox installed ;)
    end
  end
  
  def read_gem(path)
    command_parts = Shellwords.shellwords(rdoc_reader)
    command_parts << path
    success = system(*command_parts)
    if !success 
      raise Gem::CommandLineError, "Could not run '#{rdoc_reader} #{path}', exit code: #{$?.exitstatus}"
    end
  end
  
end