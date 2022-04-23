#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"



// void pause_system_dem(int interval, int pause_seconds, int loop_size) {
//     int pid = getpid();
//     for (int i = 0; i < loop_size; i++) {
//         if (i % interval == 0 && pid == getpid()) {
//             printf("pause system %d/%d completed.\n", i, loop_size);
//         }
//         if (i == loop_size / 2) {
//             pause_system(pause_seconds);
//         }
//     }
//     printf("\n");
// }

// void kill_system_dem(int interval, int loop_size) {
//     int pid = getpid();
//     for (int i = 0; i < loop_size; i++) {
//         if (i % interval == 0 && pid == getpid()) {
//             printf("kill system %d/%d completed.\n", i, loop_size);
//         }
//         if (i == loop_size / 2) {
//             kill_system();
//         }
//     }
//     printf("\n");
// }

// void example_pause_system(int interval, int pause_seconds, int loop_size) {
//     int n_forks = 2;
//     for (int i = 0; i < n_forks; i++) {
//     	fork();
//     }
//     for (int i = 0; i < loop_size; i++) {
//         if (i % interval == 0) {
//             printf("pause system %d/%d completed.\n", i, loop_size);
//         }
//         if (i == loop_size / 2){
//             pause_system(pause_seconds);
//         }
//     }
//     printf("\n");
// }

// void example_kill_system(int interval, int loop_size) {
//     int n_forks = 2;
//     for (int i = 0; i < n_forks; i++) {
//     	fork();
//     }
//     for (int i = 0; i < loop_size; i++) {
//         if (i % interval == 0) {
//             printf("kill system %d/%d completed.\n", i, loop_size);
//         }
//         if (i == loop_size / 2){
//             kill_system();
//         }
//     }
//     printf("\n");
// }


// // void set_economic_mode_dem(int interval, int loop_size) {
// //     int pid = getpid();
// //     set_economic_mode(1);
// //     for (int i = 0; i < loop_size; i++) {
// //         if (i % interval == 0 && pid == getpid()) {
// //             printf("set economic mode %d/%d completed.\n", i, loop_size);
// //         }
// //         if (i == loop_size / 2) {
// //             set_economic_mode(0);
// //         }
// //     }
// //     printf("\n");
// // }

// int
// main(int argc, char *argv[])
// {
//     example_pause_system(10,10,100);
//     //example_kill_system(10,100);
//     print_stats();
//     // set_economic_mode_dem(10, 100);
//     //pause_system_dem(10, 10, 100);
//     //kill_system_dem(10, 100);
//     exit(0);
// }


void env(int size, int interval, char* env_name) {
    int result = 1;
    int loop_size = (int)(10e6);
    int n_forks = 2;
    int i;
    int pid;
    for ( i = 0; i < n_forks; i++) {
        pid = fork();
    }
    for (i = 0; i < loop_size; i++) {
        if (i % (int)(loop_size / 10e0) == 0) {
        	if (pid == 0) {
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
        	} else {
        		printf(" ");
        	}
        }
        if (i % interval == 0) {
            result = result * size;
        }
    }
    printf("\n");

}

void env_large() {
    sleep(10);
    env(10e6, 10e6, "env_large");
    sleep(10);
    print_stats();
}

void env_freq() {
    sleep(10);
    env(10e1, 10e1, "env_freq");
    sleep(10);
    print_stats();
}

int main (int argc, char ** argv){
    env_large();
    env_freq(); 
    exit(0);
}