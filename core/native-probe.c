/* SPDX-License-Identifier: MIT
 * Run ONLY in the isolated smoke-test namespace with its loopback TPROXY rules.
 */
#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

static void fail(const char *what) { perror(what); exit(1); }

static void udp_probe(int family)
{
    int one=1, receiver=socket(family,SOCK_DGRAM,0), sender=socket(family,SOCK_DGRAM,0);
    const char payload[]="rutos-tproxy-probe";
    char response[64];
    if(receiver<0 || sender<0) fail("socket");
    if(setsockopt(receiver,family==AF_INET?SOL_IP:SOL_IPV6,
                  family==AF_INET?IP_TRANSPARENT:IPV6_TRANSPARENT,&one,sizeof(one))) fail("transparent socket");
    if(family==AF_INET) {
        struct sockaddr_in listen_addr={.sin_family=AF_INET,.sin_port=htons(19001)};
        struct sockaddr_in target={.sin_family=AF_INET,.sin_port=htons(19002)};
        inet_pton(AF_INET,"127.0.0.1",&listen_addr.sin_addr);
        inet_pton(AF_INET,"127.0.0.2",&target.sin_addr);
        if(bind(receiver,(void*)&listen_addr,sizeof(listen_addr))) fail("bind IPv4");
        if(sendto(sender,payload,sizeof(payload),0,(void*)&target,sizeof(target))<0) fail("send IPv4");
    } else {
        struct sockaddr_in6 listen_addr={.sin6_family=AF_INET6,.sin6_port=htons(19001)};
        struct sockaddr_in6 target={.sin6_family=AF_INET6,.sin6_port=htons(19002)};
        inet_pton(AF_INET6,"::1",&listen_addr.sin6_addr);
        inet_pton(AF_INET6,"::2",&target.sin6_addr);
        if(bind(receiver,(void*)&listen_addr,sizeof(listen_addr))) fail("bind IPv6");
        if(sendto(sender,payload,sizeof(payload),0,(void*)&target,sizeof(target))<0) fail("send IPv6");
    }
    struct pollfd p={.fd=receiver,.events=POLLIN};
    if(poll(&p,1,3000)!=1) { fprintf(stderr,"IPv%d UDP TPROXY receive timed out\n",family==AF_INET?4:6); exit(1); }
    ssize_t n=recv(receiver,response,sizeof(response),0);
    if(n!=(ssize_t)sizeof(payload) || memcmp(response,payload,sizeof(payload))) {
        fprintf(stderr,"TPROXY payload mismatch\n"); exit(1);
    }
    close(sender); close(receiver);
    printf("IPv%d UDP transparent proxy packet test passed.\n",family==AF_INET?4:6);
}

int main(void)
{
    int fd=socket(AF_INET,SOCK_STREAM,0);
    if(fd<0) fail("TCP socket");
    if(setsockopt(fd,SOL_TCP,TCP_CONGESTION,"bbr",3)) fail("TCP_CONGESTION bbr");
    close(fd);
    puts("BBR per-socket selection passed.");
    udp_probe(AF_INET);
    udp_probe(AF_INET6);
    return 0;
}
