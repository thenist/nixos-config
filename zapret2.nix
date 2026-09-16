# Zapret2 DPI bypass for outgoing HTTP, TLS and QUIC traffic.
#
# The profiles are the upstream client defaults from zapret2's config.default
# (fake + split strategies), and the firewall passes only the ports those
# profiles handle, so nothing else pays the nfqueue round trip. The firewall
# rules are installed for every interface because the WAN interface name
# differs per host; tunnel transport (wireguard, tailscale) isn't matched by
# the port filter and RFC 1918/CGNAT destinations are excluded by the module.

{ ... }:

{
  services.zapret2 = {
    enable = true;

    profiles = {
      http.parameters = [
        "--filter-tcp=80"
        "--filter-l7=http"
        "--payload=http_req"
        "--lua-desync=fake:blob=fake_default_http:tcp_md5"
        "--lua-desync=multisplit:pos=method+2"
      ];

      tls.parameters = [
        "--filter-tcp=443"
        "--filter-l7=tls"
        "--payload=tls_client_hello"
        "--lua-desync=fake:blob=fake_default_tls:tcp_md5:tcp_seq=-10000"
        "--lua-desync=multidisorder:pos=1,midsld"
      ];

      quic.parameters = [
        "--filter-udp=443"
        "--filter-l7=quic"
        "--payload=quic_initial"
        "--lua-desync=fake:blob=fake_default_quic:repeats=6"
      ];
    };

    firewall = {
      tcpPorts = [ 80 443 ];
      udpPorts = [ 443 ];
    };
  };
}
