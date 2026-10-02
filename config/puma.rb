# frozen_string_literal: true

# Port 80 is redirected to 3000 by nftables (deploy/photobox.nft), so the app does not need root.
port ENV.fetch('PORT', 3000)

# Pi 3 B has 1 GB RAM: one process (no forked workers) with a fixed thread pool.
workers 0
threads 3, 3

# Run Solid Queue inside Puma: one systemd service for web and jobs.
# async: supervisor, worker and dispatcher are threads, not 3 forked processes.
# The job time is spent in gphoto2 and magick child processes, so the GVL does not matter.
if ENV['SOLID_QUEUE_IN_PUMA']
  plugin :solid_queue # defines solid_queue_mode
  solid_queue_mode :async
end
