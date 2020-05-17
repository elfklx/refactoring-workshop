require 'shellwords'
require 'yaml'

def run_autoclop                   # TODO: several methods with similar names
  config_path = ENV['AUTOCLOP_CONFIG'] # TODO: global variable config
  os = File.read('/etc/issue')    # TODO: global variable $config and ENV
  user = ENV['USER']
  autoclop(os, config_path, user)
end

def autoclop(os, config_path, user)
  warning, cfg = ConfigFactory.build(config_path, user)
  Kernel.puts warning
  return if Kernel.system clop_cmd(cfg.py_version(os), cfg.opt, cfg.libargs)

  raise 'clop failed. Please inspect the output above to determine what went wrong.'
end

def clop_cmd(python_version, optimization, libargs)
  libargs =
    if libargs.empty?
      ''
    else
      ' ' + libargs.map { |a| Shellwords.escape a }.join(' ')
    end

  'clop configure ' \
    "--python #{Shellwords.escape python_version} " \
    "-#{Shellwords.escape optimization}" \
    "#{libargs}"
end

class ConfigFactory
  def self.build(path, user)
    if path.nil? || path.empty? # TODO: nil check; TODO: order dependencies; TODO: anonymous boolean logic
      ['WARNING: No file specified in $AUTOCLOP_CONFIG. Assuming the default configuration.',
       DefaultConfig.new(user)]
    elsif from_yaml(path, user).invalid?
      ["WARNING: Invalid YAML in #{path}. Assuming the default configuration.",
      DefaultConfig.new(user)]
    else
      ['', from_yaml(path, user)]
    end
  end

  def self.from_yaml(path, user)
    Config.new YAML.safe_load(File.read(path)), user
  end
end

class Config
  def initialize(cfg, user)
    @cfg = cfg
    @user = user
  end

  def libargs
    if libs
      libs.map { |lib| "-l#{lib}" }
    elsif libdir
      ["-L#{libdir}"]
    elsif libdirs
      libdirs.map { |ld| "-L#{ld}" }
    else
      ["-L/home/#{@user}/.cbiscuit/lib"]
    end
  end

  def py_version(os)
    default_python_version = 2
    @cfg['python-version'] || (
      os =~ /Red Hat 8/ ? 3 : default_python_version # Red Hat has deprecated Python 2
    )
  end

  def opt
    @cfg['opt'] || 'O2'
  end

  def invalid?
    @cfg.nil?
  end

  private

  def libs
    @cfg['libs']
  end

  def libdir
    @cfg['libdir']
  end

  def libdirs
    @cfg['libdirs']
  end

end

class DefaultConfig
  def initialize(user)
    @user=user
  end

  def py_version(os)
    default_python_version = 2
    os =~ /Red Hat 8/ ? 3 : default_python_version # Red Hat has deprecated Python 2
  end

  def opt
    'O2'
  end

  def libargs
    ["-L/home/#{@user}/.cbiscuit/lib"]
  end
end

