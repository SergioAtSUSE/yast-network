# Copyright (c) [2019] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "y2network/hostname_reader"

module Y2Network
  # DNS configuration (hostname, nameservers, etc.).
  class DNS
    # @return [String] Hostname (local part)
    attr_accessor :hostname

    # @return [Boolean] Controls if the hostname should be written or not
    attr_accessor :save_hostname

    # @return [Array<IPAddr>] List of nameservers
    attr_accessor :nameservers

    # @return [Array<String>] List of search domains
    attr_accessor :searchlist

    # @return [String] resolv.conf update policy
    attr_accessor :resolv_conf_policy

    # @return [String,Symbol] Whether to take the hostname from DHCP.
    #   It can be an interface name (String), :any for any interface or :none from no taking
    #   the hostname from DHCP.
    attr_accessor :dhcp_hostname

    # @todo receive an array instead all these arguments
    #
    # @param opts [Hash] DNS configuration options
    # @option opts [String] :hostname
    # @option opts [Array<String>] :nameservers
    # @option opts [Array<String>] :searchlist
    # @option opts [ResolvConfPolicy] :resolv_conf_policy
    # @option opts [Boolean] :dhcp_hostname
    def initialize(opts = {})
      @hostname = opts[:hostname]
      @save_hostname = opts.fetch(:save_hostname, true)
      @nameservers = opts[:nameservers] || []
      @searchlist = opts[:searchlist] || []
      @resolv_conf_policy = opts[:resolv_conf_policy]
      @dhcp_hostname = opts[:dhcp_hostname]
    end

    # @return [Array<Symbol>] Methods to check when comparing two instances
    ATTRS = [
      :hostname, :nameservers, :searchlist, :resolv_conf_policy, :dhcp_hostname
    ].freeze
    private_constant :ATTRS

    # Determines whether two set of DNS settings are equal
    #
    # @param other [DNS] DNS settings to compare with
    # @return [Boolean]
    def ==(other)
      ATTRS.all? { |a| public_send(a) == other.public_send(a) }
    end
  end
end
