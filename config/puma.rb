# frozen_string_literal: true

# Port 80 is redirected to 3000 by nftables (deploy/photobox.nft), so the app does not need root.
port ENV.fetch('PORT', 3000)

# Run the Solid Queue supervisor inside Puma: one systemd service for web and jobs.
plugin :solid_queue if ENV['SOLID_QUEUE_IN_PUMA']
