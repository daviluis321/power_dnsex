defmodule PowerDNSex.Managers.ZonesManagerTest do

  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias PowerDNSex.Managers.ZonesManager
  alias PowerDNSex.Models.{Zone, Record}
  alias PowerDNSex.Models.ResourceRecordSet, as: RRSet
  alias PowerDNSex.FakeConfig, as: Config

  @invalid_not_canonical %Zone{name: "not-canonical-domain.tst"}
  @unknown_name "it-will-never-exist.on.the.art."

  @valid_zone_test %Zone{name: "my-domain.art.",
                         serial: 2016060601,
                         comments: ["Test comment"] }

  @expected_rrset [
    %RRSet{
      name: "my-domain.art.",
      ttl: 3600,
      type: "SOA",
      records: [
        %Record{content: "a.misconfigured.powerdns.server. " <>
                         "hostmaster.my-domain.art. " <>
                         "2016060601 10800 3600 604800 3600",
                disabled: false}
      ]
    }
  ]

  @expected_zone %Zone{name: "my-domain.art.",
                       id: "my-domain.art.",
                       account: "",
                       serial: 2016060601,
                       url: "api/v1/servers/localhost/zones/my-domain.art.",
                       rrsets: @expected_rrset}

  setup do
    Config.set_url
    Config.set_token

    ExVCR.Config.cassette_library_dir("test/support/cassettes",
                                      "test/support/custom_cassettes")
    HTTPoison.start
  end

  describe "ZoneManager.create/2" do
    @tag :zones_manager_create
    test "return given correct parameters" do
      use_cassette "zones_manager/create/success" do
        zone = ZonesManager.create(@valid_zone_test)
        assert zone.__struct__ == PowerDNSex.Models.Zone
        assert zone.name == @valid_zone_test.name
      end
    end

    @tag :zones_manager_create
    test "return error given invalid name" do
      use_cassette "zones_manager/create/invalid_not_canonical" do
        error_msg = "DNS Name 'not-canonical-domain.tst' is not canonical"
        response = ZonesManager.create(@invalid_not_canonical)
        assert response.__struct__ == PowerDNSex.Models.Error
        assert response.error == error_msg
      end
    end
  end

  describe "ZonesManager.show/2" do
    @tag :zones_manager_show
    test "type of return given a correct zone name" do
      use_cassette "zones_manager/show/success" do
        zone = ZonesManager.show(@valid_zone_test.name)
        assert zone.__struct__ == PowerDNSex.Models.Zone
      end
    end

    @tag :zones_manager_show
    test "values in return given a correct zone name" do
      use_cassette "zones_manager/show/success" do
        zone = ZonesManager.show(@valid_zone_test.name)
        assert zone == @expected_zone
      end
    end

    @tag :zones_manager_show
    test "values in return given a unknown zone name" do
      use_cassette "zones_manager/show/not_found" do
        error_msg = "Could not find domain 'it-will-never-exist.on.the.art.'"
        response = ZonesManager.show(@unknown_name)
        assert response.__struct__ == PowerDNSex.Models.Error
        assert response.error == error_msg
      end
    end
  end

  describe "ZonesManager.delete/2" do
    @tag :zones_manager_delete
    test "return given correct params" do
      use_cassette "zones_manager/delete/success" do
        assert ZonesManager.delete(@valid_zone_test.name) == :ok
      end
    end

    @tag :zones_manager_delete
    test "return error when zone don't exists" do
      use_cassette "zones_manager/delete/not_found" do
        response = ZonesManager.delete(@unknown_name)
        assert response.error == "Could not find domain '#{@unknown_name}'"
      end
    end
  end
end