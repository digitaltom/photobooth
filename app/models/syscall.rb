require 'open3'

class Syscall

  def self.execute(cmd, dir: Rails.root)
    output = ''
    Rails.logger.debug("Executing: #{cmd}")
    cmd = "export LC_ALL=C; #{cmd}"
    Open3.popen2e(cmd, chdir: dir) do |_, stderr, wait_thr|
      output = stderr.read
      Rails.logger.debug("Stderr: #{output}")
      exit_status = wait_thr.value
      raise "Command '#{cmd}' failed (#{exit_status.to_i}): #{output}" unless exit_status.success?
    end
    output
  end

end
