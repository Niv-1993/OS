#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"


#define O_RDONLY  0x000
#define O_WRONLY  0x001
#define O_RDWR    0x002
#define O_CREATE  0x200
#define O_TRUNC   0x400
#define O_DONTREF 0x004

char*
fmtname(char *path)
{
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
    ;
  p++;

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}

char*
toname(char *path)
{
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
    ;
  p++;

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
    return p;
  memmove(buf, p, strlen(p));
  // memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}

void
ls(char *path)
{
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;
  fd = (strcmp(path,".") == 0 || strcmp(path,"..") == 0) ? open(path,O_RDONLY):open(path,O_RDONLY | O_DONTREF);
  if(fd < 0){
    fprintf(2, "ls: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
    fprintf(2, "ls: cannot stat %s\n", path);
    close(fd);
    return;
  }
  char b[128];
  switch(st.type){
  case T_SYMLINK:
    readlink(path,b,128);
    char* pa = toname(path);
    int len = strlen(b)+strlen(pa)+2;
    if(len < DIRSIZ)
      memset(b+strlen(b), ' ', DIRSIZ-len);
    printf("%s->%s %d %d %l\n",pa,b,st.type, st.ino, st.size);
    memset(b,0,128);
    break;
  case T_FILE:
    printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
    break;

  case T_DIR:
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
      printf("ls: path too long\n");
      break;
    }
    strcpy(buf, path);
    p = buf+strlen(buf);
    *p++ = '/';
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
      if(de.inum == 0)
        continue;
      memmove(p, de.name, DIRSIZ);
      p[DIRSIZ] = 0;
      if(stat(buf, &st) < 0){
        printf("ls: cannot stat %s\n", buf);
        continue;
      }
      if(st.type == T_SYMLINK){
        char* slinkpath = toname(buf);
        readlink(slinkpath,b,128);
        int len = strlen(b)+strlen(slinkpath)+2;
        if(len < DIRSIZ)
           memset(b+strlen(b), ' ', DIRSIZ-len);
        printf("%s->%s %d %d %d\n", slinkpath,b, st.type, st.ino, st.size);
        memset(slinkpath,0,512);
      }else{
        printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
      }
    }
    break;
  }
  close(fd);
}

int
main(int argc, char *argv[])
{
  int i;

  if(argc < 2){
    ls(".");
    exit(0);
  }
  for(i=1; i<argc; i++)
    ls(argv[i]);
  exit(0);
}
