# frozen_string_literal: true

# Devices in the hotspot WLAN, for the admin menu
class Network

  LEASES = '/var/lib/NetworkManager/dnsmasq-wlan0.leases'

  class << self

    # the neighbour table has the devices, unreachable entries have no lladdr
    def devices
      names = lease_names
      Syscall.execute('ip neigh show dev wlan0').lines.filter_map do |line|
        ip, _, mac, state = line.split
        { ip: ip, mac: mac, name: names[mac], state: state } if line.include?(' lladdr ')
      end
    rescue RuntimeError => e
      Rails.logger.warn "No network devices: #{e.message}"
      []
    end

    # the NetworkManager connection from photobox-network, the state is empty when it is down
    def hotspot?
      Syscall.execute('nmcli -g GENERAL.STATE con show photobox').strip == 'activated'
    rescue RuntimeError => e
      Rails.logger.warn "No hotspot: #{e.message}"
      false
    end

    # IPv4 address of a device, nil when it is down or missing
    def ip(device)
      Syscall.execute("ip -4 -o addr show dev #{device}")[/inet ([\d.]+)/, 1]
    rescue RuntimeError
      nil
    end

    private

    # dnsmasq lease lines: expiry mac ip hostname client-id, '*' for an unknown hostname
    def lease_names
      return {} unless File.exist?(LEASES)

      File.readlines(LEASES).to_h { |line| line.split.values_at(1, 3) }.transform_values { |name| name unless name == '*' }
    end

  end

end
