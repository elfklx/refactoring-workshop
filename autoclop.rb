require 'shellwords'
require 'yaml'

def run_autoclop
  autoclop(File.read('/etc/issue'), ENV)
end

def autoclop(os, env)
  cfg, warning = ConfigFactory.build(os, env)
  Kernel.puts warning
  return if Kernel.system clop_cmd(cfg.py_version, cfg.opt, cfg.libargs)

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
  def self.build(os, env)
    path = env['AUTOCLOP_CONFIG']
    user = env['USER']
    if path.nil? || path.empty?
      [DefaultConfig.new(os, user),
       'WARNING: No file specified in $AUTOCLOP_CONFIG. Assuming the default configuration.']
    elsif (c = from_yaml(os, path, user)).invalid?
      [DefaultConfig.new(os, user),
       "WARNING: Invalid YAML in #{path}. Assuming the default configuration."]
    else
      [c, '']
    end
  end

  def self.from_yaml(os, path, user)
    Config.new os, YAML.safe_load(File.read(path)), user
  end
end

class Config
  def initialize(os, cfg, user)
    @os = os
    @cfg = cfg
    @user = user
  end

  RepeatedFlags = Struct.new(:flag, :args) do
    def to_a
      args.map { |a| flag + a }
    end
  end

  def libargs
    args =
      if (libs = @cfg['libs'])
        ['-l', libs]
      elsif (libdir = @cfg['libdir'])
        ['-L', [libdir]]
      elsif (libdirs = @cfg['libdirs'])
        ['-L', libdirs]
      else
        ['-L', [DefaultConfig.new(nil, @user).lib]]
      end
    RepeatedFlags.new(*args).to_a
  end

  def py_version
    @cfg['python-version'] || DefaultConfig.new(@os, nil).py_version
  end

  def opt
    @cfg['opt'] || 'O2'
  end

  def invalid?
    @cfg.nil?
  end
end

class DefaultConfig
  def initialize(os, user)
    @os = os
    @user = user
  end

  def py_version
    default_python_version = 2
    # Red Hat has deprecated Python 2
    @os =~ /Red Hat 8/ ? 3 : default_python_version
  end

  def opt
    'O2'
  end

  def libargs
    ['-L' + lib]
  end

  def lib
    "/home/#{@user}/.cbiscuit/lib"
  end
end

