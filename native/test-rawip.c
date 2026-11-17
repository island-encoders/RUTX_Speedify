/* Path matching regression tests; run on a development host, not the router. */
#include <assert.h>
#include <string.h>
#include "rawip-compat.c"
int main(void) {
 const char *target="/usr/local/speedify-native/rawip-type";
 assert(strcmp(typepath("/sys/class/net/qmimux0/type"),target)==0);
 assert(strcmp(typepath("/sys/class/net/qmimux1/type"),target)==0);
 assert(strcmp(typepath("/sys/class/net/qmimux127/type"),target)==0);
 const char *unchanged[]={"", "/sys", "/sys/class/net/lo/type", "/sys/class/net/eth1/type", "/sys/class/net/wwan1/type", "/sys/class/net/qmimux/type", "/sys/class/net/qmimux0/flags", "/sys/class/net/qmimux0/type/", "/sys/class/net/qmimux0/typex", "/sys/class/net/qmimuxX/type"};
 for(unsigned i=0;i<sizeof(unchanged)/sizeof(*unchanged);i++) assert(typepath(unchanged[i])==unchanged[i]);
 assert(typepath(0)==0);
 return 0;
}
