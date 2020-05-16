require 'shellwords'
require 'yaml'

def run_autoclop                   # TODO: several methods with similar names
  config = ENV['AUTOCLOP_CONFIG'] # TODO: global variable config
  os = File.read('/etc/issue')    # TODO: global variable $config and ENV
  user = ENV['USER']
  autoclop(os, config, user)
end

def autoclop(os, config, user)   # TODO: multiple responsibilities; configuration and invocation
  cmd =
    if config.nil? || config.empty?  # TODO: nil check; TODO: order dependencies; TODO: anonymous boolean logic
      Kernel.puts 'WARNING: No file specified in $AUTOCLOP_CONFIG. Assuming the default configuration.'
      clop_cmd(py_version(os, {}), 'O2', "-L/home/#{esc user}/.cbiscuit/lib")
    else
      cfg = YAML.safe_load(File.read(config))  # TODO: coupling to both format (yaml) and data source
      if cfg.nil? # TODO: nil check
        Kernel.puts "WARNING: Invalid YAML in #{config}. Assuming the default configuration."
        clop_cmd(py_version(os, {}), 'O2', "-L/home/#{esc user}/.cbiscuit/lib")
      else
        libargs =
          if cfg['libs']
            cfg['libs'].map { |lib| "-l#{esc lib}" }.join(' ')
          elsif cfg['libdir']
            "-L#{esc cfg['libdir']}"
          elsif cfg['libdirs']
            cfg['libdirs'].map { |ld| "-L#{esc ld}" }.join(' ')
          else
            "-L/home/#{esc user}/.cbiscuit/lib"
          end
        clop_cmd(py_version(os, cfg), cfg['opt'] || 'O2', libargs)
      end
    end

  ok = Kernel.system cmd
  if !ok
    raise 'clop failed. Please inspect the output above to determine what went wrong.'
  end
end

def py_version(os, config)
  default_python_version = 2
  if os =~ /Red Hat 8/ # Red Hat has deprecated Python 2
    3
  elsif config['python-version']
    config['python-version']
  else
    default_python_version
  end
end

def clop_cmd(python_version, optimization, libargs)
  "clop configure --python #{esc python_version} -#{esc optimization}#{libargs.empty? ? '' : ' '+libargs}"
end

def esc arg # TODO: middleman
  Shellwords.escape arg
end
