#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

#define KB (1L<<10)
#define MB (1L<<20)

void sanityCheckFirstPart(void)
{
    char* buf = malloc(10*MB);
    for(int i = 0; i < 10*MB;i++){
        buf[i] = 'X';
    }

  int fd = open("test", O_CREATE | O_RDWR);

  if (write(fd, buf, 12*KB) != 12*KB)
  {
    printf("error: write to backup file failed\n");
    exit(0);
  }
  else
  {
    printf("Finished writing 12KB (direct)\n");
  }

  if (write(fd, buf, 256*KB) != 256*KB)
  {
    printf("error: write to backup file failed\n");
    exit(0);
  }
  else
  {
    printf("Finished writing 268KB (single indirect)\n");
  }

  if (write(fd, buf, (10*MB)-(268*KB)) != (10*MB)-(268*KB))
  {
    printf("error: write to backup file failed\n");
    exit(0);
  }
  else
  {
    printf("Finished writing 10MB (double indirect)\n");
  }

  close(fd);
  free(buf);
}

int
main(int argc, char *argv[])
{
    sanityCheckFirstPart();
    exit(0);
}
