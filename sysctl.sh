/etc/sysctl.d/local.conf

### Hetzner Online AG installimage
# sysctl config
#net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=1
# ignore echo broadcast requests to prevent being part of smurf attacks
net.ipv4.icmp_echo_ignore_broadcasts=1
# Uncomment the next line to enable TCP/IP SYN cookies
# See http://lwn.net/Articles/277146/
# Note: This may impact IPv6 TCP sessions too
net.ipv4.tcp_syncookies = 1

# ipv6 settings (no autoconfiguration)
net.ipv6.conf.default.autoconf=0
net.ipv6.conf.default.accept_dad=0
net.ipv6.conf.default.accept_ra=0
net.ipv6.conf.default.accept_ra_defrtr=0
net.ipv6.conf.default.accept_ra_rtr_pref=0
net.ipv6.conf.default.accept_ra_pinfo=0
net.ipv6.conf.default.accept_source_route=0
net.ipv6.conf.default.accept_redirects=0
net.ipv6.conf.default.forwarding=0
net.ipv6.conf.all.autoconf=0
net.ipv6.conf.all.accept_dad=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.all.accept_ra_defrtr=0
net.ipv6.conf.all.accept_ra_rtr_pref=0
net.ipv6.conf.all.accept_ra_pinfo=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.all.forwarding=0

