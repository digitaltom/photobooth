# frozen_string_literal: true

require 'open3'

class Syscall

  # yields each output line while the command runs, when a block is given
  def self.execute(cmd, timing: false, dir: Rails.root)
    output = +''
    Rails.logger.debug { "Executing: #{cmd}" }
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    # set locale on process start, so the shell's own messages are in English too
    Open3.popen2e({ 'LC_ALL' => 'C' }, '/bin/sh', '-c', cmd, chdir: dir) do |_, stderr, wait_thr|
      stderr.each_line do |line|
        output << line
        yield line if block_given?
      end
      Rails.logger.debug { "Stderr: #{output}" }
      exit_status = wait_thr.value
      raise "Command '#{cmd}' failed (#{exit_status.to_i}): #{output}" unless exit_status.success?
    end
    Rails.logger.info { "#{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(2)}s: #{cmd}" } if timing
    output
  end

end
