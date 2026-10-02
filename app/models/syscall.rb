# frozen_string_literal: true

require 'open3'

class Syscall

  def self.execute(cmd, timing: false, dir: Rails.root)
    output = ''
    Rails.logger.debug { "Executing: #{cmd}" }
    cmd = "#{'time ' if timing}#{cmd}"
    # set locale on process start, so the shell's own messages are in English too
    Open3.popen2e({ 'LC_ALL' => 'C' }, '/bin/sh', '-c', cmd, chdir: dir) do |_, stderr, wait_thr|
      output = stderr.read
      Rails.logger.debug { "Stderr: #{output}" }
      exit_status = wait_thr.value
      raise "Command '#{cmd}' failed (#{exit_status.to_i}): #{output}" unless exit_status.success?
    end
    output
  end

end
