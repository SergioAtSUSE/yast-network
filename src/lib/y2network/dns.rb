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

module Y2Network
  # DNS configuration (nameservers, search domains, etc.).
  class DNS
    # @return [Array<IPAddr>] List of nameservers
    attr_accessor :nameservers

    # @return [Array<String>] List of search domains
    attr_accessor :searchlist

    # @return [String] resolv.conf update policy
    attr_accessor :resolv_conf_policy

    # @todo receive an array instead all these arguments
    #
    # @param opts [Hash] DNS configuration options
    # @option opts [Array<String>] :nameservers
    # @option opts [Array<String>] :searchlist
    # @option opts [ResolvConfPolicy] :resolv_conf_policy
    def initialize(opts = {})
      @nameservers = opts[:nameservers] || []
      @searchlist = opts[:searchlist] || []
      @resolv_conf_policy = opts[:resolv_conf_policy]
    end

    # @return [Array<Symbol>] Methods to check when comparing two instances
    ATTRS = [
      :nameservers, :searchlist, :resolv_conf_policy
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
