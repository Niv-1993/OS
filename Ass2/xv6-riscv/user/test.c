#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"


int
main(int argc, char *argv[])
{
    int i = get_cpu();
    printf("curr cpu: [%d]\n",i);
    int j = set_cpu(1);
    printf("j: %d\n",j);
    int k = get_cpu();
    printf("last cpu : [%d] curr cpu: [%d]\n",i,k);
    int x = fork();
    if(x == 0){
      printf("child cpu: %d",get_cpu());
    }
    else{
      printf("parent cpu: %d",get_cpu());
    }

    exit(0);

}
void
printCPUS()
{
  printf("---------------------\n");
  printf("CPU-0 counter: [%d]\n", cpu_process_count(0));
  printf("CPU-1 counter: [%d]\n", cpu_process_count(1));
  printf("CPU-2 counter: [%d]\n", cpu_process_count(2));
  printf("---------------------\n");
}

// int
// main(int argc, char *argv[])
// {
//     printCPUS();
//     //int x = fork();
//     //printf("after fork\n");
//     //printCPUS();
//     //if(x == 0){
//       // printf("child cpu: %d",get_cpu());
//     //}
//     //else{
//       // printf("parent cpu: %d",get_cpu());
//     //}

//     exit(0);

// }