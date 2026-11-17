/* SPDX-License-Identifier: MIT
 * Daemon-only presentation adapter for RutOS QMI raw-IP interfaces.
 * This never changes the kernel interface, routes or packet framing.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdarg.h>
static const char *typepath(const char *s) {
 const char prefix[]="/sys/class/net/"; unsigned i;
 if(!s) return s;
 for(i=0;i<sizeof(prefix)-1;i++) if(s[i]!=prefix[i]) return s;
 const char *name=s+i; const char q[]="qmimux";
 for(unsigned k=0;k<6;k++) if(name[k]!=q[k]) return s;
 i+=6; unsigned first=i;
 while(s[i]>='0' && s[i]<='9') i++;
 if(i==first) return s;
 const char end[]="/type";
 for(unsigned k=0;k<sizeof(end);k++) if(s[i+k]!=end[k]) return s;
 return "/usr/local/speedify-native/rawip-type";
}
int open64(const char *path,int flags,...) {
 int (*real)(const char *,int,...)=dlsym(RTLD_NEXT,"open64");
 unsigned mode=0;
 if(flags & (0100|020000000)) {va_list ap;va_start(ap,flags);mode=va_arg(ap,unsigned);va_end(ap);}
 return real((flags&3)==0?typepath(path):path,flags,mode);
}
void *fopen64(const char *path,const char *mode) {
 void *(*real)(const char *,const char *)=dlsym(RTLD_NEXT,"fopen64");
 return real(mode && mode[0]=='r' && mode[1]==0?typepath(path):path,mode);
}
