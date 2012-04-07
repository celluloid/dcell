require 'rbconfig'

module DCell
  class InfoService
    include Celluloid
    attr_reader :arch, :os, :os_version, :hostname, :platform, :distribution, :ncpus
    attr_reader :ruby_version, :ruby_engine, :ruby_platform

    UPTIME_REGEX = /up ((\d+ days?,)?\s*(\d+:\d+|\d+ \w+)),.*(( \d.\d{2},?){3})/

    def initialize
      @arch = RbConfig::CONFIG['host_cpu']
      @os   = RbConfig::CONFIG['host_os'][/^[A-Za-z]+/]

      uname = `uname -a`.match(/\w+ (\w[\w+\.\-]*) ([\w+\.\-]+)/)
      @hostname, @os_version = uname[1], uname[2]

      @platform     = RUBY_PLATFORM
      @ruby_version = RUBY_VERSION
      @ruby_engine  = RUBY_ENGINE

      case os
      when 'darwin'
        @ncpus = Integer(`sysctl hw.ncpu`[/\d+/])
        os, release, build = `sw_vers`.scan(/:\t(.*)$/).flatten
        @distribution = "#{os} #{release} (#{build})"
      when 'linux'
        cores = File.read("/proc/cpuinfo").scan(/core id\s+: \d+/).uniq.size
        @ncpus = cores > 0 ? cores : 1
        @distribution = `lsb_release -d`[/Description:\s+(.*)\s*$/, 1]
      else
        @ncpus = nil
      end

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

    def platform; RUBY_PLATFORM; end
    def ruby_engine; RUBY_ENGINE; end
    def ruby_version; RUBY_VERSION; end

    def load_averages(uptime_string = `uptime`)
      matches = uptime_string.match(UPTIME_REGEX)
      unless matches
        Logger.warn "Couldn't parse uptime output: #{uptime_string}"
        return
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

    def to_hash
      uptime_string = `uptime`

      {
        :arch          => arch,
        :os            => os,
        :os_version    => os_version,
        :hostname      => hostname,
        :platform      => platform,
        :distribution  => distribution,
        :ncpus         => ncpus,
        :ruby_version  => ruby_version,
        :ruby_engine   => ruby_engine,
        :ruby_platform => ruby_platform,
        :load_averages => load_averages(uptime_string),
        :uptime        => uptime(uptime_string)
      }
    end
  end
end
