#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
extern uint64 cas(volatile void *addr , int expected , int newval);

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S
//added
struct list zombies;
struct list unuseds;
struct list sleepings;

// void
// printList(struct list *lst)
// {
//     char* name = lst->name == 0? "RUNNABLES": lst->name;
//     int size = 0;
//     printf("%s: ",name);
//     int i = lst->head;
//     if(i == -1){
//       return;
//     }
//     printf("\n");
//     struct proc *p;
//     while(i!=-1){
//       p = &proc[i];
//       printf("[%d] ",p->pid);
//       i = p->next;
//       size++;
//     }
//     printf("\nsize: [%d]\n----------------------\n",size);  
// }

// void printAllLists()
// {
//   printList(&cpus[0].runnables);
//   printList(&unuseds);
//   printList(&sleepings);
//   printList(&zombies);
// }

void
incrementCounter(struct cpu *c)
{
  uint64 old;
  do{
    old = c->counter;
  }while(cas(&c->counter,old,old+1));
  // for(int i=0; i< CPUS; i++){
  //   printf("CPU-%d counter: [%d]\n",i, cpus[i].counter);
  // }
}

int
get_min_cpu()
{
  uint64 min_counter = cpus[0].counter;
  int res = 0;
  for(int i = 1; i< CPUS;i++){
   if(cpus[i].counter < min_counter){
     min_counter = cpus[i].counter;
     res = i;
   }
 } 
 return res;
}


void
initLists()
{
  unuseds.name = "UNUSED";
  unuseds.head = -1;
  unuseds.tail = -1;
  unuseds.lst_lock.name = "unused list lock";
  zombies.name = "ZOMBIES";
  zombies.head = -1;
  zombies.tail = -1;
  zombies.lst_lock.name = "zombies list lock";
  sleepings.name = "SLEEPING";
  sleepings.head = -1;
  sleepings.tail = -1;
  sleepings.lst_lock.name = "sleepings list lock";
  struct cpu *c;
  for(int i =0; i< CPUS; i++)
  {
    c = &cpus[i];
    c->runnables.head = -1;
    c->runnables.tail = -1;
    c->runnables.name = "RUNNABLE";
    c->runnables.lst_lock.name = "runnable list lock";
    c->counter = 0;
  }
}

int
addToList(struct list *lst, int index)
{
  if(lst->head == -1){
    lst->head = index;
    lst->tail = index;
    struct proc *head = &proc[index];
    head->next = -1;
    head->prev = -1;
  }
  else{
    struct proc *to_add = &proc[index];
    struct proc *last = &proc[lst->tail];
    acquire(&last->lock);
    last->next = index;
    release(&last->lock);
    to_add->prev = lst->tail;
    lst->tail = index;
    
  }
  return 0;
}

int
removeFromList(struct list *lst,int index)
{
  if(lst->head == -1){
    panic("removed from empty list");
  }
  if(lst->head == index && lst->tail == index){ //list has 1 proc only
    lst->head = -1;
    lst->tail = -1;
  }
  else if(lst->head == index){  //at least 2 procesess & need to remove the proc at head
    struct proc *to_remove = &proc[index];
    lst->head = to_remove->next;
    to_remove->next = -1;
    struct proc *new_head = &proc[lst->head];
    acquire(&new_head->lock);
    new_head->prev = -1;
    release(&new_head->lock);
  }
  else if(lst->tail == index){ //at least 2 processes & need to remove the tail
    struct proc *old_tail = &proc[index];
    lst->tail = old_tail->prev;
    old_tail->prev = -1;
    struct proc *new_tail = &proc[lst->tail];
    acquire(&new_tail->lock);
    new_tail->next = -1;
    release(&new_tail->lock);

  }
  else{  //at least 3 procesess & delete from middle
    struct proc *me = &proc[index];
    struct proc *left = &proc[me->prev];
    acquire(&left->lock);
    left->next = me->next;
    release(&left->lock);

    struct proc *right = &proc[me->next];
    acquire(&right->lock);
    right->prev = me->prev;
    release(&right->lock);
    me->next = -1;
    me->prev = -1;
  }
  return 0;
}

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table at boot time.
void
procinit(void)
{
  //added
  initLists();
  //---
  struct proc *p;
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  int i = 0;
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
      p->kstack = KSTACK((int) (p - proc));
      //added
      p->next = -1;
      p->prev = -1;
      p->my_proc_index = i++;
      acquire(&unuseds.lst_lock);
      addToList(&unuseds,p->my_proc_index);
      release(&unuseds.lst_lock);
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid() {
  int pid;
  do{
    pid = nextpid;
  }while(cas(&nextpid,pid,pid+1));
  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
// unuseds.lst_lock -> must be held
static struct proc*
allocproc(void)
{
  int i = unuseds.head;
  if(i ==-1){
    return 0;
  }
  struct proc *p = &proc[i];
  acquire(&p->lock);
  if(p->state != UNUSED)
  {
    panic("state is not unused!");
  }
  
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
// unused_lst->lock is locked
static void
freeproc(struct proc *p)
{
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;


  acquire(&zombies.lst_lock);
  removeFromList(&zombies,p->my_proc_index);
  release(&zombies.lst_lock);
  
  addToList(&unuseds,p->my_proc_index);
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  struct proc *p;
  acquire(&unuseds.lst_lock);
  p = allocproc();
  initproc = p;

  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  //added
  struct cpu *curr_cpu = &cpus[0];
  initproc->my_cpu_id = 0;

  removeFromList(&unuseds,p->my_proc_index);
  release(&unuseds.lst_lock);

  acquire(&curr_cpu->runnables.lst_lock);
  addToList(&curr_cpu->runnables,p->my_proc_index);
  release(&curr_cpu->runnables.lst_lock);
  #ifdef ON
  incrementCounter(curr_cpu);
  #endif

  release(&p->lock);
  
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();
  // Allocate process.
  acquire(&unuseds.lst_lock);
  if((np = allocproc()) == 0){
    release(&unuseds.lst_lock);//added
    return -1;
  }
  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&unuseds.lst_lock);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  //added
  removeFromList(&unuseds,np->my_proc_index);
  release(&unuseds.lst_lock);
  
  #ifdef ON
  np->my_cpu_id = get_min_cpu();
  #else
  np->my_cpu_id = np->parent->my_cpu_id;
  #endif

  struct cpu *c = &cpus[np->my_cpu_id];
  acquire(&c->runnables.lst_lock);
  addToList(&c->runnables,np->my_proc_index);
  release(&c->runnables.lst_lock);

  #ifdef ON
  incrementCounter(c);
  #endif
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();
  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  acquire(&zombies.lst_lock);
  addToList(&zombies,p->my_proc_index);
  release(&zombies.lst_lock);

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          acquire(&unuseds.lst_lock); //added
          freeproc(np);
          release(&unuseds.lst_lock); //added
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    while(1){
      acquire(&c->runnables.lst_lock);
      if(c->runnables.head == -1){
        release(&c->runnables.lst_lock);
        break;
      }
      p = &proc[c->runnables.head];
      acquire(&p->lock);
      removeFromList(&c->runnables,p->my_proc_index);
      release(&c->runnables.lst_lock);
      // Switch to chosen process.  It is the process's job
      // to release its lock and then reacquire it
      // before jumping back to us.
      p->state = RUNNING;
      c->proc = p;
      swtch(&c->context, &p->context);

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
      release(&p->lock);
    }
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1){
    panic("sched locks");
  }
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  struct cpu *c = &cpus[p->my_cpu_id];
  acquire(&p->lock);
  p->state = RUNNABLE;
  acquire(&c->runnables.lst_lock);
  addToList(&c->runnables,p->my_proc_index); //added
  release(&c->runnables.lst_lock);
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1

  acquire(&sleepings.lst_lock);
  addToList(&sleepings,p->my_proc_index); //added
  release(&sleepings.lst_lock);

  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;


  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  struct proc *p;
  acquire(&sleepings.lst_lock);
  int i = sleepings.head;
  while(i != -1){
    p = &proc[i];
    acquire(&p->lock);
    i = p->next;
    if(p->chan == chan){
      p->state = RUNNABLE;
      removeFromList(&sleepings,p->my_proc_index);
      #ifdef ON
      struct cpu *c = &cpus[get_min_cpu()];
      #else
      struct cpu *c = &cpus[p->my_cpu_id];
      #endif
      acquire(&c->runnables.lst_lock);
      addToList(&c->runnables,p->my_proc_index);
      release(&c->runnables.lst_lock);
      #ifdef ON
      incrementCounter(c);
      #endif
    }
    release(&p->lock);
  }
  release(&sleepings.lst_lock);  
}


// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
        acquire(&sleepings.lst_lock);
        removeFromList(&sleepings,p->my_proc_index);
        release(&sleepings.lst_lock);
        struct cpu *c = &cpus[p->my_cpu_id];
        acquire(&c->runnables.lst_lock);
        addToList(&c->runnables,p->my_proc_index);
        release(&c->runnables.lst_lock);
        #ifdef ON
        incrementCounter(c);
        #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

int
set_cpu(int cpu_num)
{
  if(cpu_num < 0 || cpu_num >= CPUS)
  {
    return -1;
  }
  struct proc *p = myproc();
  acquire(&p->lock);
  p->my_cpu_id = cpu_num;
  release(&p->lock);
  yield();
  return cpu_num;
}

int
get_cpu()
{
  return cpuid();
  // struct proc *p = myproc();
  // acquire(&p->lock);
  // int id = p->my_cpu_id;
  // release(&p->lock);
  //return id;
}

int
cpu_process_count(int cpu_num)
{
  if(cpu_num < 0 || cpu_num >= CPUS)
  {
    return -1;
  }
  return cpus[cpu_num].counter;
}