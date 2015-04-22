module DCell
  class InfoService
    include Celluloid

    attr_reader :os, :os_version, :hostname, :platform, :distribution
    attr_reader :cpu_arch, :cpu_type, :cpu_count
    attr_reader :ruby_version, :ruby_engine, :ruby_platform

    UPTIME_REGEX = /up ((\d+ days?,)?\s*(\d+:\d+|\d+ \w+)),.*(( \d+.\d+,?){3})/

    def initialize
      @hostname = Facter['hostname'].value

      discover_os
      discover_cpu_info
      discover_ruby_platform
    end

    def discover_os
      @os           = Facter['kernel'].value
      @os_version   = Facter['operatingsystemrelease'].value
      @distribution = Facter['operatingsystem'].value
    end

    def discover_cpu_info
      @cpu_arch = Facter['architecture'].value
      @cpu_type = Facter['processors'].value['models'].first
      @cpu_count = Facter['processorcount'].value
    end

    def discover_ruby_platform
      @ruby_version = RUBY_VERSION
      @ruby_engine  = RUBY_ENGINE

      case RUBY_ENGINE
      when 'ruby'
        @ruby_platform = "ruby #{RUBY_VERSION}"
      when 'jruby'
        @ruby_platform = "jruby #{JRUBY_VERSION}"
      when 'rbx'
        @ruby_platform = "rbx #{Rubinius::VERSION}"
      else
        @ruby_platform = RUBY_ENGINE
      end
    end

    def load_average
      uptime = `uptime`
      matches = uptime.match(UPTIME_REGEX)
      return [] unless matches
      averages = matches[4].strip
      averages.split(/,? /).map(&:to_f)
    end

    def uptime
      Integer(Facter['uptime_hours'].value) / 24
    end

    def to_hash
      {
        os:            os,
        os_version:    os_version,
        hostname:      hostname,
        platform:      platform,
        distribution:  distribution,
        ruby_version:  ruby_version,
        ruby_engine:   ruby_engine,
        ruby_platform: ruby_platform,
        load_average: load_average,
        uptime:        uptime,
        cpu: {
          arch:   cpu_arch,
          type:   cpu_type,
          count:  cpu_count,
        },
      }
    end
  end
end
