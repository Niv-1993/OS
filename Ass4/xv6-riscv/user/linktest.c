#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void
softLinkTest(){
    int fd = open("a.txt", O_CREATE | O_RDWR);
    if(fd == -1){
        printf("didnt open file\n");
        exit(-1);
    }
    if(symlink("a.txt","soft.txt") == -1){
        printf("didnt create soft link 1 file\n");
        exit(-1);
    }
    if(symlink("a.txt","soft.txt") == -1){
        printf("didnt create soft link 2 file\n");
    }else{
        printf("created soft link 2 file -> BAD!\n");
        exit(-1);  
    }
}

void
readlinkTest(){
    int fd = open("a.txt", O_CREATE | O_RDWR);
    if(fd == -1){
        printf("didnt open file\n");
        exit(-1);
    }
    close(fd);
    if(symlink("a.txt","soft.txt") == -1){
        printf("didnt create soft link 1 file\n");
        exit(-1);
    }
    int bufsize = 128;
    char buf[bufsize];
    int res = readlink("soft.txt",buf,bufsize);
    if(res == -1){
        printf("didnt read link\n");
    }
    printf("%s\n",buf);
}
void
open_extendTest()
{
    int fd = open("a.txt", O_CREATE | O_RDWR);
    if(fd == -1){
        printf("didnt open file\n");
        exit(-1);
    }
    close(fd);
    if(symlink("a.txt","soft.txt") == -1){
        printf("didnt create soft link 1 file\n");
        exit(-1);
    }
    fd = open("soft.txt", O_RDWR);
    char buf[4] = "123\n";
    if(write(fd,&buf,4) != 4){
        printf("failed to write\n");
        exit(-1);
    }
    close(fd);
    fd = open("a.txt", O_RDWR);
    char readbuff[4];
    if(read(fd,&readbuff,4) != 4){
        printf("failed to read\n");
        exit(-1); 
    }
    printf("%s",readbuff);
}

int
main(int argc, char *argv[])
{
    //printf("%d\n",O_RDWR & O_DONTREF);
    //printf("%d\n",(O_RDWR | O_DONTREF) & O_DONTREF);
    //softLinkTest();
    //int res = unlink("a.txt");
    //printf("unlinkres %d", res);
    //readlinkTest();
    open_extendTest();
    exit(0);
}
