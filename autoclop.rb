require 'shellwords'
require 'yaml'

def run_autoclop                   # TODO: several methods with similar names
  os = File.read('/etc/issue')    # TODO: global variable $config and ENV
  autoclop(os, ENV)
end

def autoclop(os, env)
  warning, cfg = ConfigFactory.build(env)
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
  def self.build(env)
    path = env['AUTOCLOP_CONFIG']
    user = env['USER']
    if path.nil? || path.empty?
      ['WARNING: No file specified in $AUTOCLOP_CONFIG. Assuming the default configuration.',
       DefaultConfig.new(user)]
    elsif (c = from_yaml(path, user)).invalid?
      ["WARNING: Invalid YAML in #{path}. Assuming the default configuration.",
       DefaultConfig.new(user)]
    else
      ['', c]
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
    @cfg['python-version'] || DefaultConfig.new(nil).py_version(os)
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
    @user = user
  end

  def py_version(os)
    default_python_version = 2
    # Red Hat has deprecated Python 2
    os =~ /Red Hat 8/ ? 3 : default_python_version
  end

  def opt
    'O2'
  end

  def libargs
    ["-L/home/#{@user}/.cbiscuit/lib"]
  end
end

