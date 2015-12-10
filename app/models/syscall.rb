require 'open3'

class Syscall

  def self.execute(cmd, dir: Rails.root)
    output = ''
    Rails.logger.debug("Executing: #{cmd}")
    Open3.popen2e(cmd, chdir: dir) do |_, stderr, wait_thr|
      output = stderr.read
      Rails.logger.debug("Stderr: #{output}")
      exit_status = wait_thr.value
      unless exit_status.success?
        fail "Command '#{cmd}' failed (#{exit_status.to_i}): #{output}"
      end
    end
    output
  end

end
