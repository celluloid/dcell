module DCell
  class InfoService
    include Celluloid

    attr_reader :os, :os_version, :hostname, :platform, :distribution
    attr_reader :cpu_arch, :cpu_type, :cpu_vendor, :cpu_speed, :cpu_count
    attr_reader :ruby_version, :ruby_engine, :ruby_platform

    UPTIME_REGEX = /up ((\d+ days?,)?\s*(\d+:\d+|\d+ \w+)),.*(( \d+.\d+,?){3})/

    def initialize
      @cpu_arch = RbConfig::CONFIG["host_cpu"]
      @os       = RbConfig::CONFIG["host_os"][/^[A-Za-z]+/]

      @platform     = RUBY_PLATFORM
      @ruby_version = RUBY_VERSION
      @ruby_engine  = RUBY_ENGINE

      discover_uname
      discover_cpu_info
      discover_ruby_platform
    end

    def discover_cpu_info_darwin
      cpu_info = `sysctl -n machdep.cpu.brand_string`.match(/^((\w+).*) @ (\d+.\d+)GHz/)
      if cpu_info
        @cpu_type   = cpu_info[1]
        @cpu_vendor = cpu_info[2].downcase.to_sym
        @cpu_speed  = Float(cpu_info[3])
      end

      @cpu_count = Integer(`sysctl hw.ncpu`[/\d+/])
      os, release, build = `sw_vers`.scan(/:\t(.*)$/).flatten
      @distribution = "#{os} #{release} (#{build})"
    end

    def discover_cpu_info_linux
      cpu_info = File.read("/proc/cpuinfo")

      @cpu_vendor = cpu_info[/vendor_id:\s+\s+(Genuine)?(\w+)/, 2]
      model_name  = cpu_info.match(/model name\s+:\s+((\w+).*) @ (\d+.\d+)GHz/)
      if model_name
        @cpu_type   = model_name[1].gsub(/\s+/, " ")
        @cpu_vendor = model_name[2].downcase.to_sym
        @cpu_speed  = Float(model_name[3])
      end

      cores = cpu_info.scan(/core id\s+: \d+/).uniq.size
      @cpu_count = cores > 0 ? cores : 1
      @distribution = discover_distribution
    end

    def discover_cpu_info
      case os
      when "darwin"
        discover_cpu_info_darwin
      when "linux"
        discover_cpu_info_linux
      else
        @cpu_type = @cpu_vendor = @cpu_speed = @cpu_count = nil
      end
    end

    def discover_uname
      uname = `uname -a`.match(/\w+ (\w[\w+\.\-]*) ([\w+\.\-]+)/)
      @hostname, @os_version = uname[1], uname[2]
    end

    def discover_ruby_platform
      case RUBY_ENGINE
      when "ruby"
        @ruby_platform = "ruby #{RUBY_VERSION}"
      when "jruby"
        @ruby_platform = "jruby #{JRUBY_VERSION}"
      when "rbx"
        @ruby_platform = "rbx #{Rubinius::VERSION}"
      else
        @ruby_platform = RUBY_ENGINE
      end
    end

    def load_averages(uptime_string = `uptime`)
      matches = uptime_string.match(UPTIME_REGEX)
      unless matches
        Logger.warn "Couldn't parse uptime output: #{uptime_string}"
        return [""]
      end

      averages = matches[4].strip
      averages.split(/,? /).map(&:to_f)
    end
    alias_method :load_average, :load_averages

    def uptime(uptime_string = `uptime`)
      matches = uptime_string.match(UPTIME_REGEX)
      unless matches
        Logger.warn "Couldn't parse uptime output: #{uptime_string}"
        return
      end

      uptime = matches[1]
      days_string = uptime[/^(\d+) days/, 1]
      days_string ? Integer(days_string) : 0
    end

    def discover_distribution
      `lsb_release -d`[/Description:\s+(.*)\s*$/, 1]
    rescue Errno::ENOENT
    end

    def to_hash
      uptime_string = `uptime`

      {
        os:            os,
        os_version:    os_version,
        hostname:      hostname,
        platform:      platform,
        distribution:  distribution,
        ruby_version:  ruby_version,
        ruby_engine:   ruby_engine,
        ruby_platform: ruby_platform,
        load_averages: load_averages(uptime_string),
        uptime:        uptime(uptime_string),
        cpu: {
          arch:   cpu_arch,
          type:   cpu_type,
          vendor: cpu_vendor,
          speed:  cpu_speed,
          count:  cpu_count,
        },
      }
    end
  end
end
