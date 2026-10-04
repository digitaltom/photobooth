# frozen_string_literal: true

# Port 80 is redirected to 3000 by nftables (deploy/photobox.nft), so the app does not need root.
port ENV.fetch('PORT', 3000)

# Pi 3 B has 1 GB RAM: one process (no forked workers) with a fixed thread pool.
workers 0
threads 3, 3
