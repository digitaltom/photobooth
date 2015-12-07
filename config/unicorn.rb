worker_processes 3
timeout 60
preload_app true
listen "0.0.0.0:3000", :tcp_nopush => true
