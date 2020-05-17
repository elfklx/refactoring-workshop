require 'shellwords'
require 'yaml'

def run_autoclop                   # TODO: several methods with similar names
  config_path = ENV['AUTOCLOP_CONFIG'] # TODO: global variable config
  os = File.read('/etc/issue')    # TODO: global variable $config and ENV
  user = ENV['USER']
  autoclop(os, config_path, user)
end

class Config
  def initialize(cfg, user)
    @cfg = cfg
    @user = user
  end

  def self.load(path, user)
    new YAML.safe_load(File.read(path)), user
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

class NullConfig
  def initialize(user)
    @user=user
  end

  def self.load(user)
    new user
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

def construct_config(os, config_path, user)
  if config_path.nil? || config_path.empty? # TODO: nil check; TODO: order dependencies; TODO: anonymous boolean logic
    Kernel.puts 'WARNING: No file specified in $AUTOCLOP_CONFIG. Assuming the default configuration.'
    NullConfig.load(user)
  elsif Config.load(config_path, user).invalid?
    Kernel.puts "WARNING: Invalid YAML in #{config_path}. Assuming the default configuration."
    NullConfig.load(user)
  else
    Config.load(config_path, user)
  end
end

def autoclop(os, config_path, user)
  cfg = construct_config(os, config_path, user)
  ok = Kernel.system clop_cmd(cfg.py_version(os), cfg.opt, cfg.libargs)
  if !ok
    raise 'clop failed. Please inspect the output above to determine what went wrong.'
  end
end

def clop_cmd(python_version, optimization, libargs)
  "clop configure --python #{esc python_version} -#{esc optimization}#{libargs.empty? ? '' : ' '+libargs.map{ |a| esc a }.join(' ')}"
end

def esc arg # TODO: middleman
  Shellwords.escape arg
end
