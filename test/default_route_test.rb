#!/usr/bin/env rspec

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

require_relative "test_helper"

require "network/install_inf_convertor"
require "y2network/interface_config_builder"
require "y2network/interfaces_collection"
require "y2network/physical_interface"

Yast.import "Lan"

describe "Yast::LanItemsClass" do
  subject { Yast::LanItems }

  let(:config) { Y2Network::Config.new(interfaces: interfaces, source: :sysconfig) }
  let(:interfaces) { Y2Network::InterfacesCollection.new([eth0]) }
  let(:eth0) { Y2Network::PhysicalInterface.new("eth0") }

  before do
    allow(Yast::Lan).to receive(:yast_config).and_return(config)
  end

  before do
    Yast.import "LanItems"

    @ifcfg_files = SectionKeyValue.new

    # network configs
    allow(Yast::SCR).to receive(:Dir) do |path|
      case path.to_s
      when ".network.section"
        @ifcfg_files.sections
      when /^\.network\.value\."(eth\d+)"$/
        @ifcfg_files.keys(Regexp.last_match(1))
      when ".modules.options", ".etc.install_inf"
        []
      else
        raise "Unexpected Dir #{path}"
      end
    end

    allow(Yast::SCR).to receive(:Read) do |path|
      if path.to_s =~ /^\.network\.value\."(eth\d+)".(.*)/
        next @ifcfg_files.get(Regexp.last_match(1), Regexp.last_match(2))
      end

      raise "Unexpected Read #{path}"
    end

    allow(Yast::SCR).to receive(:Write) do |path, value|
      if path.to_s =~ /^\.network\.value\."(eth\d+)".(.*)/
        @ifcfg_files.set(Regexp.last_match(1), Regexp.last_match(2), value)
      elsif path.to_s == ".network" && value.nil?
        true
      else
        raise "Unexpected Write #{path}, #{value}"
      end
    end

    # stub NetworkInterfaces, apart from the ifcfgs
    allow(Yast::NetworkInterfaces)
      .to receive(:CleanHotplugSymlink)
    allow(Yast::NetworkInterfaces)
      .to receive(:adapt_old_config!)
    allow(Yast::NetworkInterfaces)
      .to receive(:GetTypeFromSysfs)
      .with(/eth\d+/)
      .and_return "eth"
    allow(Yast::NetworkInterfaces)
      .to receive(:GetType)
      .with(/eth\d+/)
      .and_return "eth"
    allow(Yast::NetworkInterfaces)
      .to receive(:GetType)
      .with("")
      .and_return nil
    Yast::NetworkInterfaces.instance_variable_set(:@initialized, false)

    allow(Yast::InstallInfConvertor.instance)
      .to receive(:AllowUdevModify).and_return false

    # These "expect" should be "allow", but then it does not work out,
    # because SCR multiplexes too much and the matchers get confused.

    # Hardware detection
    expect(Yast::SCR)
      .to receive(:Read)
      .with(path(".probe.netcard"))
      .and_return([])

    # miscellaneous uninteresting but hard to avoid stuff

    allow(Yast::Arch).to receive(:architecture).and_return "x86_64"
    allow(Yast::Confirm).to receive(:Detection).and_return true

    expect(Yast::SCR)
      .to receive(:Read)
      .with(path(".etc.install_inf.BrokenModules"))
      .and_return ""
    expect(Yast::SCR)
      .to receive(:Read)
      .with(path(".udev_persistent.net"))
      .and_return({})
    expect(Yast::SCR)
      .to receive(:Read)
      .with(path(".udev_persistent.drivers"))
      .and_return({})
  end

  it "does not modify DHCLIENT_SET_DEFAULT_ROUTE if not explicitly set, when editing an ifcfg" do
    @ifcfg_files.set("eth0", "STARTMODE", "auto")
    @ifcfg_files.set("eth0", "BOOTPROTO", "dhcp4")

    subject.Read
    subject.current = 0

    builder = Y2Network::InterfaceConfigBuilder.for("eth")
    builder.name = subject.GetCurrentName()
    subject.SetItem(builder: builder)

    subject.Commit(builder)
    subject.write

    ifcfg = Yast::NetworkInterfaces.FilterDevices("")["eth"]["eth0"]
    expect(ifcfg["DHCLIENT_SET_DEFAULT_ROUTE"]).to be_nil
  end
end
