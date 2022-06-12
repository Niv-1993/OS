// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

#define NUM_PYS_PAGES ((PHYSTOP-KERNBASE)/PGSIZE)
#define PA2INDEX(pa) ((pa-KERNBASE)/PGSIZE)
extern uint64 cas(volatile void *addr , int expected , int newval);

uint counter[NUM_PYS_PAGES];

void
set_counter(uint64 pa, int num)
{
  uint old;
  do{
    old = counter[PA2INDEX(pa)];
  }while(cas(&counter[PA2INDEX(pa)],old,num));
}


void
inc_counter(uint64 pa)
{
  uint old;
  do{
    old = counter[PA2INDEX(pa)];
  }while(cas(&counter[PA2INDEX(pa)],old,old+1));
}

uint
dec_counter(uint64 pa)
{
  uint old;
  do{
    old = counter[PA2INDEX(pa)];
  }while(cas(&counter[PA2INDEX(pa)],old,old-1));
  return old-1;
}

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

void
kinit()
{
  //added
  memset(counter, 0, sizeof(int)*NUM_PYS_PAGES);  //init counter array with 0
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    kfree(p);
  }
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");
  if(counter[PA2INDEX((uint64)pa)] > 1){ 
    // there is another refernce to pa;
    dec_counter((uint64)pa);
    return;
  }
  // no more refernces to pa;
  set_counter((uint64)pa,0);
  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;
  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r){
    set_counter((uint64)r,1);  // set counter of r to 1
    memset((char*)r, 5, PGSIZE); // fill with junk
  }
  
  return (void*)r;
}
