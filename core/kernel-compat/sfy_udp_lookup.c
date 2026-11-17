// SPDX-License-Identifier: GPL-2.0-only
/*
 * UDP netfilter lookup wrappers omitted by the stock RutOS kernel config.
 * Implementations derived from net/ipv4/udp.c and net/ipv6/udp.c in the
 * official Teltonika 7.26.2 SDK, Linux 6.6.137.
 * Only exported kernel APIs are used. No patching or symbol-address lookup.
 */
#include <linux/module.h>
#include <linux/refcount.h>
#include <net/sock.h>
#include <net/udp.h>
#include <net/ipv6.h>

struct sock *udp4_lib_lookup(struct net *net, __be32 saddr, __be16 sport,
                            __be32 daddr, __be16 dport, int dif)
{
    struct sock *sk;

    sk = __udp4_lib_lookup(net, saddr, sport, daddr, dport,
                          dif, 0, net->ipv4.udp_table, NULL);
    if (sk && !refcount_inc_not_zero(&sk->sk_refcnt))
        sk = NULL;
    return sk;
}
EXPORT_SYMBOL_GPL(udp4_lib_lookup);

struct sock *udp6_lib_lookup(struct net *net, const struct in6_addr *saddr,
                            __be16 sport, const struct in6_addr *daddr,
                            __be16 dport, int dif)
{
    struct sock *sk;

    sk = __udp6_lib_lookup(net, saddr, sport, daddr, dport,
                          dif, 0, net->ipv4.udp_table, NULL);
    if (sk && !refcount_inc_not_zero(&sk->sk_refcnt))
        sk = NULL;
    return sk;
}
EXPORT_SYMBOL_GPL(udp6_lib_lookup);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("RutOS 7.26.2 UDP lookup compatibility wrappers for netfilter");
MODULE_AUTHOR("Speedify RutOS port contributors; derived from Linux UDP code");
