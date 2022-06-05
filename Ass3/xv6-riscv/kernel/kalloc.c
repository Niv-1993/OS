// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"


//added
#define NUM_PYS_PAGES ((PHYSTOP-KERNBASE)/PGSIZE)
#define PA2INDX(pa) (((pa-KERNBASE)/PGSIZE))
extern uint64 cas(volatile void *addr , int expected , int newval);
uint64 arr_counters[NUM_PYS_PAGES];
void inc_reference_count(uint64 pa);
uint64 dec_reference_count(uint64 pa);
void set_refernce_count(uint64 pa, int val);


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
  printf("kinit\n");
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
  memset(arr_counters,0,sizeof(uint)*NUM_PYS_PAGES); //added
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
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
  //added
  if(dec_reference_count((uint64)pa) > 0){ //means there are more references - dont free page yet
    return;
  }
  //else de-alloc page
  set_refernce_count((uint64)pa,0);
  //----
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
  printf("kalloc\n");
  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r){
    kmem.freelist = r->next;
  }
  release(&kmem.lock);

  if(r){
    memset((char*)r, 5, PGSIZE); // fill with junk
    set_refernce_count((uint64)r,1); //add to reference counter
  }
  return (void*)r;
}


void
inc_reference_count(uint64 pa){
  printf("inc_reference_count\n");
  uint64 old;
  do{
    old = arr_counters[PA2INDX(pa)];
  }while(cas(&arr_counters[PA2INDX(pa)],old,old+1));
}

uint64
dec_reference_count(uint64 pa){
  // printf("dec_reference_count\n");
  uint64 old;
  do{
    old = arr_counters[PA2INDX(pa)];
  }while(cas(&arr_counters[PA2INDX(pa)],old,old-1));
  return old-1;
}

void
set_refernce_count(uint64 pa, int val){
  uint64 old;
  do{
    old = arr_counters[PA2INDX(pa)];
  }while(cas(&arr_counters[PA2INDX(pa)],old,val));
}
