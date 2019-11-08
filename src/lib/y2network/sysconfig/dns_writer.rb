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
require "yast"
require "yast2/execute"
require "y2network/sysconfig/interface_file"

module Y2Network
  module Sysconfig
    # This class writes DNS configuration settings.
    class DNSWriter
      include Yast::Logger

      # Writes DNS configuration
      #
      # @param dns [Y2Network::DNS] DNS configuration
      # @param old_dns [Y2Network::DNS] Old DNS configuration
      def write(dns, old_dns, netconfig_update: true)
        return if old_dns && dns == old_dns

        update_sysconfig_dhcp(dns, old_dns)
        update_hostname(dns)
        update_mta_config
        update_sysconfig_config(dns, netconfig: netconfig_update)
      end

    private

      # @return [String] Hostname executable
      HOSTNAME_PATH = "/etc/hostname".freeze
      # @return [String] Sendmail update script (included in "sendmail" package)
      SENDMAIL_UPDATE_PATH = "/usr/lib/sendmail.d/update".freeze

      # @param dns [Y2Network::DNS] DNS configuration
      # @param old_dns [Y2Network::DNS] Old DNS configuration
      def update_sysconfig_dhcp(dns, old_dns)
        if old_dns.nil? || old_dns.dhcp_hostname == dns.dhcp_hostname
          log.info("No update for /etc/sysconfig/network/dhcp")
          return
        end

        Yast::SCR.Write(
          Yast::Path.new(".sysconfig.network.dhcp.DHCLIENT_SET_HOSTNAME"),
          (dns.dhcp_hostname == :any) ? "yes" : "no"
        )
        Yast::SCR.Write(Yast::Path.new(".sysconfig.network.dhcp"), nil)

        # Clean-up values from ifcfg-* values
        Y2Network::Sysconfig::InterfaceFile.all.each do |file|
          value = (file.interface == dns.dhcp_hostname) ? "yes" : nil
          file.load
          next if file.dhclient_set_hostname == value

          file.dhclient_set_hostname = value
          file.save
        end
      end

      # Sets the hostname
      #
      # @param dns [Y2Network::DNS] DNS configuration
      def update_hostname(dns)
        Yast::Execute.on_target!("/usr/bin/hostname", dns.hostname.split(".")[0])
        Yast::SCR.Write(Yast::Path.new(".target.string"), HOSTNAME_PATH, "#{dns.hostname}\n")
      end

      # Updates the MTA configuration
      #
      # It executes the Sendmail update script which is included in the `sendmail` package.
      def update_mta_config
        return unless Yast::FileUtils.Exists(SENDMAIL_UPDATE_PATH)

        log.info "Updating sendmail configuration."
        Yast::Execute.on_target!(SENDMAIL_UPDATE_PATH)
      end

      # Updates /etc/sysconfig/network/config
      #
      # @param dns [Y2Network::DNS]
      def update_sysconfig_config(dns, netconfig: true)
        Yast::SCR.Write(
          Yast::Path.new(".sysconfig.network.config.NETCONFIG_DNS_POLICY"),
          dns.resolv_conf_policy
        )
        Yast::SCR.Write(
          Yast::Path.new(".sysconfig.network.config.NETCONFIG_DNS_STATIC_SEARCHLIST"),
          dns.searchlist.join(" ")
        )
        Yast::SCR.Write(
          Yast::Path.new(".sysconfig.network.config.NETCONFIG_DNS_STATIC_SERVERS"),
          dns.nameservers.join(" ")
        )
        Yast::SCR.Write(Yast::Path.new(".sysconfig.network.config"), nil)

        Yast::Execute.on_target!("/sbin/netconfig", "update") if netconfig
      end
    end
  end
end
