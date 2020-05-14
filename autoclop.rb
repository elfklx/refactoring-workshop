require 'shellwords'
require 'yaml'

def run_autoclop                   # TODO: several methods with similar names
  $config = ENV['AUTOCLOP_CONFIG'] # TODO: global variable config
  $os = File.read('/etc/issue')    # TODO: global variable $config and ENV
  autoclop
end

def autoclop   # TODO: multiple responsibilities; configuration and invocation
  return invoke_clop_default if $config.nil? || $config.empty?  # TODO: early return; TODO: nil check; TODO: order dependencies; TODO: anonymous boolean logic
  cfg = YAML.safe_load(File.read($config))  # TODO: coupling to both format (yaml) and data source
  return invoke_clop_default :invalid_yaml if cfg.nil?  # TODO: early return; TODO: nil check
  python_version = get_py_version($os, cfg) # TODO: reassigned of python version
  optimization = cfg['opt']

  if cfg['libs']                          # TODO: coupling to structure of cfg hash
    libargs = cfg['libs'].map{ |lib| "-l#{esc lib}"}.join(' ')
  elsif cfg['libdir']
    libargs = "-L#{esc cfg['libdir']}"    # TODO: duplication of line 36
  elsif cfg['libdirs']
    libargs = cfg['libdirs'].map{ |ld| "-L#{esc ld}"}.join(' ')
  end
  libargs ||= "-L/home/#{esc ENV['USER']}/.cbiscuit/lib"

  invoke_clop(python_version, optimization || 'O2', libargs || '')
end

def get_py_version(os, config)
  default_python_version = 2
  python_version =
  if os =~ /Red Hat 8/ # Red Hat has deprecated Python 2
    3
  elsif config['python-version']
    config['python-version']
  else
    default_python_version
  end
end

def invoke_clop_default(message_type=nil)
  py = get_py_version($os, {})
  if message_type == :invalid_yaml        # TODO: multiple responsibilities
    Kernel.puts "WARNING: Invalid YAML in #{$config}. Assuming the default configuration."
  else
    Kernel.puts "WARNING: No file specified in $AUTOCLOP_CONFIG. Assuming the default configuration."
  end
  invoke_clop(py, 'O2', "-L/home/#{esc ENV['USER']}/.cbiscuit/lib")   # TODO: deep call stack
end

def invoke_clop(python_version, optimization, libargs)
  ok = Kernel.system "clop configure --python #{esc python_version} -#{esc optimization} #{libargs}" #TODO: no esc call on libargs
  if !ok
    raise "clop failed. Please inspect the output above to determine what went wrong."
  end
end

def esc arg # TODO: middleman
  Shellwords.escape arg
end
