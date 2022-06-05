
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	cfc78793          	addi	a5,a5,-772 # 80005d60 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ff987ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	f2a78793          	addi	a5,a5,-214 # 80000fd8 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	4aa080e7          	jalr	1194(ra) # 800025d6 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	b9a080e7          	jalr	-1126(ra) # 80000d2e <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	95c080e7          	jalr	-1700(ra) # 80001b20 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	008080e7          	jalr	8(ra) # 800021dc <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	370080e7          	jalr	880(ra) # 80002580 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	bb6080e7          	jalr	-1098(ra) # 80000de2 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	ba0080e7          	jalr	-1120(ra) # 80000de2 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a5a080e7          	jalr	-1446(ra) # 80000d2e <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	33a080e7          	jalr	826(ra) # 8000262c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	ae0080e7          	jalr	-1312(ra) # 80000de2 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f22080e7          	jalr	-222(ra) # 80002368 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	836080e7          	jalr	-1994(ra) # 80000c9e <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00061797          	auipc	a5,0x61
    8000047c:	ea078793          	addi	a5,a5,-352 # 80061318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b8450513          	addi	a0,a0,-1148 # 800080f0 <digits+0xb0>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	72e080e7          	jalr	1838(ra) # 80000d2e <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	67e080e7          	jalr	1662(ra) # 80000de2 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	514080e7          	jalr	1300(ra) # 80000c9e <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	4be080e7          	jalr	1214(ra) # 80000c9e <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	4e6080e7          	jalr	1254(ra) # 80000ce2 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	554080e7          	jalr	1364(ra) # 80000d82 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	ac8080e7          	jalr	-1336(ra) # 80002368 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	44a080e7          	jalr	1098(ra) # 80000d2e <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	8b0080e7          	jalr	-1872(ra) # 800021dc <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	47a080e7          	jalr	1146(ra) # 80000de2 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	35a080e7          	jalr	858(ra) # 80000d2e <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	3fc080e7          	jalr	1020(ra) # 80000de2 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <inc_reference_count>:
  return (void*)r;
}


void
inc_reference_count(uint64 pa){
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
    80000a04:	84aa                	mv	s1,a0
  printf("inc_reference_count\n");
    80000a06:	00007517          	auipc	a0,0x7
    80000a0a:	65a50513          	addi	a0,a0,1626 # 80008060 <digits+0x20>
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	b7a080e7          	jalr	-1158(ra) # 80000588 <printf>
  uint64 old;
  do{
    old = arr_counters[PA2INDX(pa)];
    80000a16:	80000537          	lui	a0,0x80000
    80000a1a:	94aa                	add	s1,s1,a0
    80000a1c:	80b1                	srli	s1,s1,0xc
  }while(cas(&arr_counters[PA2INDX(pa)],old,old+1));
    80000a1e:	00349913          	slli	s2,s1,0x3
    80000a22:	00011797          	auipc	a5,0x11
    80000a26:	87e78793          	addi	a5,a5,-1922 # 800112a0 <arr_counters>
    80000a2a:	993e                	add	s2,s2,a5
    old = arr_counters[PA2INDX(pa)];
    80000a2c:	84ca                	mv	s1,s2
    80000a2e:	608c                	ld	a1,0(s1)
  }while(cas(&arr_counters[PA2INDX(pa)],old,old+1));
    80000a30:	0015861b          	addiw	a2,a1,1
    80000a34:	2581                	sext.w	a1,a1
    80000a36:	854a                	mv	a0,s2
    80000a38:	00006097          	auipc	ra,0x6
    80000a3c:	96e080e7          	jalr	-1682(ra) # 800063a6 <cas>
    80000a40:	f57d                	bnez	a0,80000a2e <inc_reference_count+0x36>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret

0000000080000a4e <dec_reference_count>:

uint64
dec_reference_count(uint64 pa){
    80000a4e:	7179                	addi	sp,sp,-48
    80000a50:	f406                	sd	ra,40(sp)
    80000a52:	f022                	sd	s0,32(sp)
    80000a54:	ec26                	sd	s1,24(sp)
    80000a56:	e84a                	sd	s2,16(sp)
    80000a58:	e44e                	sd	s3,8(sp)
    80000a5a:	1800                	addi	s0,sp,48
  // printf("dec_reference_count\n");
  uint64 old;
  do{
    old = arr_counters[PA2INDX(pa)];
    80000a5c:	80000937          	lui	s2,0x80000
    80000a60:	992a                	add	s2,s2,a0
    80000a62:	00c95913          	srli	s2,s2,0xc
  }while(cas(&arr_counters[PA2INDX(pa)],old,old-1));
    80000a66:	00391993          	slli	s3,s2,0x3
    80000a6a:	00011797          	auipc	a5,0x11
    80000a6e:	83678793          	addi	a5,a5,-1994 # 800112a0 <arr_counters>
    80000a72:	99be                	add	s3,s3,a5
    old = arr_counters[PA2INDX(pa)];
    80000a74:	894e                	mv	s2,s3
    80000a76:	00093483          	ld	s1,0(s2) # ffffffff80000000 <end+0xfffffffefff9a000>
  }while(cas(&arr_counters[PA2INDX(pa)],old,old-1));
    80000a7a:	fff4861b          	addiw	a2,s1,-1
    80000a7e:	0004859b          	sext.w	a1,s1
    80000a82:	854e                	mv	a0,s3
    80000a84:	00006097          	auipc	ra,0x6
    80000a88:	922080e7          	jalr	-1758(ra) # 800063a6 <cas>
    80000a8c:	f56d                	bnez	a0,80000a76 <dec_reference_count+0x28>
  return old-1;
}
    80000a8e:	fff48513          	addi	a0,s1,-1
    80000a92:	70a2                	ld	ra,40(sp)
    80000a94:	7402                	ld	s0,32(sp)
    80000a96:	64e2                	ld	s1,24(sp)
    80000a98:	6942                	ld	s2,16(sp)
    80000a9a:	69a2                	ld	s3,8(sp)
    80000a9c:	6145                	addi	sp,sp,48
    80000a9e:	8082                	ret

0000000080000aa0 <set_refernce_count>:

void
set_refernce_count(uint64 pa, int val){
    80000aa0:	7179                	addi	sp,sp,-48
    80000aa2:	f406                	sd	ra,40(sp)
    80000aa4:	f022                	sd	s0,32(sp)
    80000aa6:	ec26                	sd	s1,24(sp)
    80000aa8:	e84a                	sd	s2,16(sp)
    80000aaa:	e44e                	sd	s3,8(sp)
    80000aac:	1800                	addi	s0,sp,48
    80000aae:	89ae                	mv	s3,a1
  uint64 old;
  do{
    old = arr_counters[PA2INDX(pa)];
    80000ab0:	800004b7          	lui	s1,0x80000
    80000ab4:	94aa                	add	s1,s1,a0
    80000ab6:	80b1                	srli	s1,s1,0xc
  }while(cas(&arr_counters[PA2INDX(pa)],old,val));
    80000ab8:	00349913          	slli	s2,s1,0x3
    80000abc:	00010797          	auipc	a5,0x10
    80000ac0:	7e478793          	addi	a5,a5,2020 # 800112a0 <arr_counters>
    80000ac4:	993e                	add	s2,s2,a5
    old = arr_counters[PA2INDX(pa)];
    80000ac6:	84ca                	mv	s1,s2
  }while(cas(&arr_counters[PA2INDX(pa)],old,val));
    80000ac8:	864e                	mv	a2,s3
    80000aca:	408c                	lw	a1,0(s1)
    80000acc:	854a                	mv	a0,s2
    80000ace:	00006097          	auipc	ra,0x6
    80000ad2:	8d8080e7          	jalr	-1832(ra) # 800063a6 <cas>
    80000ad6:	f96d                	bnez	a0,80000ac8 <set_refernce_count+0x28>
}
    80000ad8:	70a2                	ld	ra,40(sp)
    80000ada:	7402                	ld	s0,32(sp)
    80000adc:	64e2                	ld	s1,24(sp)
    80000ade:	6942                	ld	s2,16(sp)
    80000ae0:	69a2                	ld	s3,8(sp)
    80000ae2:	6145                	addi	sp,sp,48
    80000ae4:	8082                	ret

0000000080000ae6 <kfree>:
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	e04a                	sd	s2,0(sp)
    80000af0:	1000                	addi	s0,sp,32
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000af2:	03451793          	slli	a5,a0,0x34
    80000af6:	e79d                	bnez	a5,80000b24 <kfree+0x3e>
    80000af8:	84aa                	mv	s1,a0
    80000afa:	00065797          	auipc	a5,0x65
    80000afe:	50678793          	addi	a5,a5,1286 # 80066000 <end>
    80000b02:	02f56163          	bltu	a0,a5,80000b24 <kfree+0x3e>
    80000b06:	47c5                	li	a5,17
    80000b08:	07ee                	slli	a5,a5,0x1b
    80000b0a:	00f57d63          	bgeu	a0,a5,80000b24 <kfree+0x3e>
  if(dec_reference_count((uint64)pa) > 0){ //means there are more references - dont free page yet
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	f40080e7          	jalr	-192(ra) # 80000a4e <dec_reference_count>
    80000b16:	cd19                	beqz	a0,80000b34 <kfree+0x4e>
}
    80000b18:	60e2                	ld	ra,24(sp)
    80000b1a:	6442                	ld	s0,16(sp)
    80000b1c:	64a2                	ld	s1,8(sp)
    80000b1e:	6902                	ld	s2,0(sp)
    80000b20:	6105                	addi	sp,sp,32
    80000b22:	8082                	ret
    panic("kfree");
    80000b24:	00007517          	auipc	a0,0x7
    80000b28:	55450513          	addi	a0,a0,1364 # 80008078 <digits+0x38>
    80000b2c:	00000097          	auipc	ra,0x0
    80000b30:	a12080e7          	jalr	-1518(ra) # 8000053e <panic>
  set_refernce_count((uint64)pa,0);
    80000b34:	4581                	li	a1,0
    80000b36:	8526                	mv	a0,s1
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	f68080e7          	jalr	-152(ra) # 80000aa0 <set_refernce_count>
  memset(pa, 1, PGSIZE);
    80000b40:	6605                	lui	a2,0x1
    80000b42:	4585                	li	a1,1
    80000b44:	8526                	mv	a0,s1
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	2e4080e7          	jalr	740(ra) # 80000e2a <memset>
  acquire(&kmem.lock);
    80000b4e:	00010917          	auipc	s2,0x10
    80000b52:	73290913          	addi	s2,s2,1842 # 80011280 <kmem>
    80000b56:	854a                	mv	a0,s2
    80000b58:	00000097          	auipc	ra,0x0
    80000b5c:	1d6080e7          	jalr	470(ra) # 80000d2e <acquire>
  r->next = kmem.freelist;
    80000b60:	01893783          	ld	a5,24(s2)
    80000b64:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b66:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b6a:	854a                	mv	a0,s2
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	276080e7          	jalr	630(ra) # 80000de2 <release>
    80000b74:	b755                	j	80000b18 <kfree+0x32>

0000000080000b76 <freerange>:
{
    80000b76:	7179                	addi	sp,sp,-48
    80000b78:	f406                	sd	ra,40(sp)
    80000b7a:	f022                	sd	s0,32(sp)
    80000b7c:	ec26                	sd	s1,24(sp)
    80000b7e:	e84a                	sd	s2,16(sp)
    80000b80:	e44e                	sd	s3,8(sp)
    80000b82:	e052                	sd	s4,0(sp)
    80000b84:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b86:	6785                	lui	a5,0x1
    80000b88:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b8c:	94aa                	add	s1,s1,a0
    80000b8e:	757d                	lui	a0,0xfffff
    80000b90:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b92:	94be                	add	s1,s1,a5
    80000b94:	0095ee63          	bltu	a1,s1,80000bb0 <freerange+0x3a>
    80000b98:	892e                	mv	s2,a1
    kfree(p);
    80000b9a:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b9c:	6985                	lui	s3,0x1
    kfree(p);
    80000b9e:	01448533          	add	a0,s1,s4
    80000ba2:	00000097          	auipc	ra,0x0
    80000ba6:	f44080e7          	jalr	-188(ra) # 80000ae6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000baa:	94ce                	add	s1,s1,s3
    80000bac:	fe9979e3          	bgeu	s2,s1,80000b9e <freerange+0x28>
}
    80000bb0:	70a2                	ld	ra,40(sp)
    80000bb2:	7402                	ld	s0,32(sp)
    80000bb4:	64e2                	ld	s1,24(sp)
    80000bb6:	6942                	ld	s2,16(sp)
    80000bb8:	69a2                	ld	s3,8(sp)
    80000bba:	6a02                	ld	s4,0(sp)
    80000bbc:	6145                	addi	sp,sp,48
    80000bbe:	8082                	ret

0000000080000bc0 <kinit>:
{
    80000bc0:	1141                	addi	sp,sp,-16
    80000bc2:	e406                	sd	ra,8(sp)
    80000bc4:	e022                	sd	s0,0(sp)
    80000bc6:	0800                	addi	s0,sp,16
  printf("kinit\n");
    80000bc8:	00007517          	auipc	a0,0x7
    80000bcc:	4b850513          	addi	a0,a0,1208 # 80008080 <digits+0x40>
    80000bd0:	00000097          	auipc	ra,0x0
    80000bd4:	9b8080e7          	jalr	-1608(ra) # 80000588 <printf>
  initlock(&kmem.lock, "kmem");
    80000bd8:	00007597          	auipc	a1,0x7
    80000bdc:	4b058593          	addi	a1,a1,1200 # 80008088 <digits+0x48>
    80000be0:	00010517          	auipc	a0,0x10
    80000be4:	6a050513          	addi	a0,a0,1696 # 80011280 <kmem>
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	0b6080e7          	jalr	182(ra) # 80000c9e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000bf0:	45c5                	li	a1,17
    80000bf2:	05ee                	slli	a1,a1,0x1b
    80000bf4:	00065517          	auipc	a0,0x65
    80000bf8:	40c50513          	addi	a0,a0,1036 # 80066000 <end>
    80000bfc:	00000097          	auipc	ra,0x0
    80000c00:	f7a080e7          	jalr	-134(ra) # 80000b76 <freerange>
  memset(arr_counters,0,sizeof(uint)*NUM_PYS_PAGES); //added
    80000c04:	00020637          	lui	a2,0x20
    80000c08:	4581                	li	a1,0
    80000c0a:	00010517          	auipc	a0,0x10
    80000c0e:	69650513          	addi	a0,a0,1686 # 800112a0 <arr_counters>
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	218080e7          	jalr	536(ra) # 80000e2a <memset>
}
    80000c1a:	60a2                	ld	ra,8(sp)
    80000c1c:	6402                	ld	s0,0(sp)
    80000c1e:	0141                	addi	sp,sp,16
    80000c20:	8082                	ret

0000000080000c22 <kalloc>:
{
    80000c22:	1101                	addi	sp,sp,-32
    80000c24:	ec06                	sd	ra,24(sp)
    80000c26:	e822                	sd	s0,16(sp)
    80000c28:	e426                	sd	s1,8(sp)
    80000c2a:	1000                	addi	s0,sp,32
  printf("kalloc\n");
    80000c2c:	00007517          	auipc	a0,0x7
    80000c30:	46450513          	addi	a0,a0,1124 # 80008090 <digits+0x50>
    80000c34:	00000097          	auipc	ra,0x0
    80000c38:	954080e7          	jalr	-1708(ra) # 80000588 <printf>
  acquire(&kmem.lock);
    80000c3c:	00010497          	auipc	s1,0x10
    80000c40:	64448493          	addi	s1,s1,1604 # 80011280 <kmem>
    80000c44:	8526                	mv	a0,s1
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	0e8080e7          	jalr	232(ra) # 80000d2e <acquire>
  r = kmem.freelist;
    80000c4e:	6c84                	ld	s1,24(s1)
  if(r){
    80000c50:	cc95                	beqz	s1,80000c8c <kalloc+0x6a>
    kmem.freelist = r->next;
    80000c52:	609c                	ld	a5,0(s1)
    80000c54:	00010517          	auipc	a0,0x10
    80000c58:	62c50513          	addi	a0,a0,1580 # 80011280 <kmem>
    80000c5c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	184080e7          	jalr	388(ra) # 80000de2 <release>
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c66:	6605                	lui	a2,0x1
    80000c68:	4595                	li	a1,5
    80000c6a:	8526                	mv	a0,s1
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	1be080e7          	jalr	446(ra) # 80000e2a <memset>
    set_refernce_count((uint64)r,1); //add to reference counter
    80000c74:	4585                	li	a1,1
    80000c76:	8526                	mv	a0,s1
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	e28080e7          	jalr	-472(ra) # 80000aa0 <set_refernce_count>
}
    80000c80:	8526                	mv	a0,s1
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	addi	sp,sp,32
    80000c8a:	8082                	ret
  release(&kmem.lock);
    80000c8c:	00010517          	auipc	a0,0x10
    80000c90:	5f450513          	addi	a0,a0,1524 # 80011280 <kmem>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	14e080e7          	jalr	334(ra) # 80000de2 <release>
  if(r){
    80000c9c:	b7d5                	j	80000c80 <kalloc+0x5e>

0000000080000c9e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c9e:	1141                	addi	sp,sp,-16
    80000ca0:	e422                	sd	s0,8(sp)
    80000ca2:	0800                	addi	s0,sp,16
  lk->name = name;
    80000ca4:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000ca6:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000caa:	00053823          	sd	zero,16(a0)
}
    80000cae:	6422                	ld	s0,8(sp)
    80000cb0:	0141                	addi	sp,sp,16
    80000cb2:	8082                	ret

0000000080000cb4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cb4:	411c                	lw	a5,0(a0)
    80000cb6:	e399                	bnez	a5,80000cbc <holding+0x8>
    80000cb8:	4501                	li	a0,0
  return r;
}
    80000cba:	8082                	ret
{
    80000cbc:	1101                	addi	sp,sp,-32
    80000cbe:	ec06                	sd	ra,24(sp)
    80000cc0:	e822                	sd	s0,16(sp)
    80000cc2:	e426                	sd	s1,8(sp)
    80000cc4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cc6:	6904                	ld	s1,16(a0)
    80000cc8:	00001097          	auipc	ra,0x1
    80000ccc:	e3c080e7          	jalr	-452(ra) # 80001b04 <mycpu>
    80000cd0:	40a48533          	sub	a0,s1,a0
    80000cd4:	00153513          	seqz	a0,a0
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret

0000000080000ce2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000ce2:	1101                	addi	sp,sp,-32
    80000ce4:	ec06                	sd	ra,24(sp)
    80000ce6:	e822                	sd	s0,16(sp)
    80000ce8:	e426                	sd	s1,8(sp)
    80000cea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cec:	100024f3          	csrr	s1,sstatus
    80000cf0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cf4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cf6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cfa:	00001097          	auipc	ra,0x1
    80000cfe:	e0a080e7          	jalr	-502(ra) # 80001b04 <mycpu>
    80000d02:	5d3c                	lw	a5,120(a0)
    80000d04:	cf89                	beqz	a5,80000d1e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d06:	00001097          	auipc	ra,0x1
    80000d0a:	dfe080e7          	jalr	-514(ra) # 80001b04 <mycpu>
    80000d0e:	5d3c                	lw	a5,120(a0)
    80000d10:	2785                	addiw	a5,a5,1
    80000d12:	dd3c                	sw	a5,120(a0)
}
    80000d14:	60e2                	ld	ra,24(sp)
    80000d16:	6442                	ld	s0,16(sp)
    80000d18:	64a2                	ld	s1,8(sp)
    80000d1a:	6105                	addi	sp,sp,32
    80000d1c:	8082                	ret
    mycpu()->intena = old;
    80000d1e:	00001097          	auipc	ra,0x1
    80000d22:	de6080e7          	jalr	-538(ra) # 80001b04 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d26:	8085                	srli	s1,s1,0x1
    80000d28:	8885                	andi	s1,s1,1
    80000d2a:	dd64                	sw	s1,124(a0)
    80000d2c:	bfe9                	j	80000d06 <push_off+0x24>

0000000080000d2e <acquire>:
{
    80000d2e:	1101                	addi	sp,sp,-32
    80000d30:	ec06                	sd	ra,24(sp)
    80000d32:	e822                	sd	s0,16(sp)
    80000d34:	e426                	sd	s1,8(sp)
    80000d36:	1000                	addi	s0,sp,32
    80000d38:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d3a:	00000097          	auipc	ra,0x0
    80000d3e:	fa8080e7          	jalr	-88(ra) # 80000ce2 <push_off>
  if(holding(lk))
    80000d42:	8526                	mv	a0,s1
    80000d44:	00000097          	auipc	ra,0x0
    80000d48:	f70080e7          	jalr	-144(ra) # 80000cb4 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d4c:	4705                	li	a4,1
  if(holding(lk))
    80000d4e:	e115                	bnez	a0,80000d72 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d50:	87ba                	mv	a5,a4
    80000d52:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d56:	2781                	sext.w	a5,a5
    80000d58:	ffe5                	bnez	a5,80000d50 <acquire+0x22>
  __sync_synchronize();
    80000d5a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d5e:	00001097          	auipc	ra,0x1
    80000d62:	da6080e7          	jalr	-602(ra) # 80001b04 <mycpu>
    80000d66:	e888                	sd	a0,16(s1)
}
    80000d68:	60e2                	ld	ra,24(sp)
    80000d6a:	6442                	ld	s0,16(sp)
    80000d6c:	64a2                	ld	s1,8(sp)
    80000d6e:	6105                	addi	sp,sp,32
    80000d70:	8082                	ret
    panic("acquire");
    80000d72:	00007517          	auipc	a0,0x7
    80000d76:	32650513          	addi	a0,a0,806 # 80008098 <digits+0x58>
    80000d7a:	fffff097          	auipc	ra,0xfffff
    80000d7e:	7c4080e7          	jalr	1988(ra) # 8000053e <panic>

0000000080000d82 <pop_off>:

void
pop_off(void)
{
    80000d82:	1141                	addi	sp,sp,-16
    80000d84:	e406                	sd	ra,8(sp)
    80000d86:	e022                	sd	s0,0(sp)
    80000d88:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d8a:	00001097          	auipc	ra,0x1
    80000d8e:	d7a080e7          	jalr	-646(ra) # 80001b04 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d92:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d96:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d98:	e78d                	bnez	a5,80000dc2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d9a:	5d3c                	lw	a5,120(a0)
    80000d9c:	02f05b63          	blez	a5,80000dd2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000da0:	37fd                	addiw	a5,a5,-1
    80000da2:	0007871b          	sext.w	a4,a5
    80000da6:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000da8:	eb09                	bnez	a4,80000dba <pop_off+0x38>
    80000daa:	5d7c                	lw	a5,124(a0)
    80000dac:	c799                	beqz	a5,80000dba <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000db2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000db6:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000dba:	60a2                	ld	ra,8(sp)
    80000dbc:	6402                	ld	s0,0(sp)
    80000dbe:	0141                	addi	sp,sp,16
    80000dc0:	8082                	ret
    panic("pop_off - interruptible");
    80000dc2:	00007517          	auipc	a0,0x7
    80000dc6:	2de50513          	addi	a0,a0,734 # 800080a0 <digits+0x60>
    80000dca:	fffff097          	auipc	ra,0xfffff
    80000dce:	774080e7          	jalr	1908(ra) # 8000053e <panic>
    panic("pop_off");
    80000dd2:	00007517          	auipc	a0,0x7
    80000dd6:	2e650513          	addi	a0,a0,742 # 800080b8 <digits+0x78>
    80000dda:	fffff097          	auipc	ra,0xfffff
    80000dde:	764080e7          	jalr	1892(ra) # 8000053e <panic>

0000000080000de2 <release>:
{
    80000de2:	1101                	addi	sp,sp,-32
    80000de4:	ec06                	sd	ra,24(sp)
    80000de6:	e822                	sd	s0,16(sp)
    80000de8:	e426                	sd	s1,8(sp)
    80000dea:	1000                	addi	s0,sp,32
    80000dec:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dee:	00000097          	auipc	ra,0x0
    80000df2:	ec6080e7          	jalr	-314(ra) # 80000cb4 <holding>
    80000df6:	c115                	beqz	a0,80000e1a <release+0x38>
  lk->cpu = 0;
    80000df8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dfc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e00:	0f50000f          	fence	iorw,ow
    80000e04:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e08:	00000097          	auipc	ra,0x0
    80000e0c:	f7a080e7          	jalr	-134(ra) # 80000d82 <pop_off>
}
    80000e10:	60e2                	ld	ra,24(sp)
    80000e12:	6442                	ld	s0,16(sp)
    80000e14:	64a2                	ld	s1,8(sp)
    80000e16:	6105                	addi	sp,sp,32
    80000e18:	8082                	ret
    panic("release");
    80000e1a:	00007517          	auipc	a0,0x7
    80000e1e:	2a650513          	addi	a0,a0,678 # 800080c0 <digits+0x80>
    80000e22:	fffff097          	auipc	ra,0xfffff
    80000e26:	71c080e7          	jalr	1820(ra) # 8000053e <panic>

0000000080000e2a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e2a:	1141                	addi	sp,sp,-16
    80000e2c:	e422                	sd	s0,8(sp)
    80000e2e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e30:	ce09                	beqz	a2,80000e4a <memset+0x20>
    80000e32:	87aa                	mv	a5,a0
    80000e34:	fff6071b          	addiw	a4,a2,-1
    80000e38:	1702                	slli	a4,a4,0x20
    80000e3a:	9301                	srli	a4,a4,0x20
    80000e3c:	0705                	addi	a4,a4,1
    80000e3e:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000e40:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fee79de3          	bne	a5,a4,80000e40 <memset+0x16>
  }
  return dst;
}
    80000e4a:	6422                	ld	s0,8(sp)
    80000e4c:	0141                	addi	sp,sp,16
    80000e4e:	8082                	ret

0000000080000e50 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e50:	1141                	addi	sp,sp,-16
    80000e52:	e422                	sd	s0,8(sp)
    80000e54:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e56:	ca05                	beqz	a2,80000e86 <memcmp+0x36>
    80000e58:	fff6069b          	addiw	a3,a2,-1
    80000e5c:	1682                	slli	a3,a3,0x20
    80000e5e:	9281                	srli	a3,a3,0x20
    80000e60:	0685                	addi	a3,a3,1
    80000e62:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e64:	00054783          	lbu	a5,0(a0)
    80000e68:	0005c703          	lbu	a4,0(a1)
    80000e6c:	00e79863          	bne	a5,a4,80000e7c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e74:	fed518e3          	bne	a0,a3,80000e64 <memcmp+0x14>
  }

  return 0;
    80000e78:	4501                	li	a0,0
    80000e7a:	a019                	j	80000e80 <memcmp+0x30>
      return *s1 - *s2;
    80000e7c:	40e7853b          	subw	a0,a5,a4
}
    80000e80:	6422                	ld	s0,8(sp)
    80000e82:	0141                	addi	sp,sp,16
    80000e84:	8082                	ret
  return 0;
    80000e86:	4501                	li	a0,0
    80000e88:	bfe5                	j	80000e80 <memcmp+0x30>

0000000080000e8a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e8a:	1141                	addi	sp,sp,-16
    80000e8c:	e422                	sd	s0,8(sp)
    80000e8e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e90:	ca0d                	beqz	a2,80000ec2 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e92:	00a5f963          	bgeu	a1,a0,80000ea4 <memmove+0x1a>
    80000e96:	02061693          	slli	a3,a2,0x20
    80000e9a:	9281                	srli	a3,a3,0x20
    80000e9c:	00d58733          	add	a4,a1,a3
    80000ea0:	02e56463          	bltu	a0,a4,80000ec8 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ea4:	fff6079b          	addiw	a5,a2,-1
    80000ea8:	1782                	slli	a5,a5,0x20
    80000eaa:	9381                	srli	a5,a5,0x20
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	97ae                	add	a5,a5,a1
    80000eb0:	872a                	mv	a4,a0
      *d++ = *s++;
    80000eb2:	0585                	addi	a1,a1,1
    80000eb4:	0705                	addi	a4,a4,1
    80000eb6:	fff5c683          	lbu	a3,-1(a1)
    80000eba:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000ebe:	fef59ae3          	bne	a1,a5,80000eb2 <memmove+0x28>

  return dst;
}
    80000ec2:	6422                	ld	s0,8(sp)
    80000ec4:	0141                	addi	sp,sp,16
    80000ec6:	8082                	ret
    d += n;
    80000ec8:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000eca:	fff6079b          	addiw	a5,a2,-1
    80000ece:	1782                	slli	a5,a5,0x20
    80000ed0:	9381                	srli	a5,a5,0x20
    80000ed2:	fff7c793          	not	a5,a5
    80000ed6:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ed8:	177d                	addi	a4,a4,-1
    80000eda:	16fd                	addi	a3,a3,-1
    80000edc:	00074603          	lbu	a2,0(a4)
    80000ee0:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000ee4:	fef71ae3          	bne	a4,a5,80000ed8 <memmove+0x4e>
    80000ee8:	bfe9                	j	80000ec2 <memmove+0x38>

0000000080000eea <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000eea:	1141                	addi	sp,sp,-16
    80000eec:	e406                	sd	ra,8(sp)
    80000eee:	e022                	sd	s0,0(sp)
    80000ef0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ef2:	00000097          	auipc	ra,0x0
    80000ef6:	f98080e7          	jalr	-104(ra) # 80000e8a <memmove>
}
    80000efa:	60a2                	ld	ra,8(sp)
    80000efc:	6402                	ld	s0,0(sp)
    80000efe:	0141                	addi	sp,sp,16
    80000f00:	8082                	ret

0000000080000f02 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f02:	1141                	addi	sp,sp,-16
    80000f04:	e422                	sd	s0,8(sp)
    80000f06:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f08:	ce11                	beqz	a2,80000f24 <strncmp+0x22>
    80000f0a:	00054783          	lbu	a5,0(a0)
    80000f0e:	cf89                	beqz	a5,80000f28 <strncmp+0x26>
    80000f10:	0005c703          	lbu	a4,0(a1)
    80000f14:	00f71a63          	bne	a4,a5,80000f28 <strncmp+0x26>
    n--, p++, q++;
    80000f18:	367d                	addiw	a2,a2,-1
    80000f1a:	0505                	addi	a0,a0,1
    80000f1c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f1e:	f675                	bnez	a2,80000f0a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f20:	4501                	li	a0,0
    80000f22:	a809                	j	80000f34 <strncmp+0x32>
    80000f24:	4501                	li	a0,0
    80000f26:	a039                	j	80000f34 <strncmp+0x32>
  if(n == 0)
    80000f28:	ca09                	beqz	a2,80000f3a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f2a:	00054503          	lbu	a0,0(a0)
    80000f2e:	0005c783          	lbu	a5,0(a1)
    80000f32:	9d1d                	subw	a0,a0,a5
}
    80000f34:	6422                	ld	s0,8(sp)
    80000f36:	0141                	addi	sp,sp,16
    80000f38:	8082                	ret
    return 0;
    80000f3a:	4501                	li	a0,0
    80000f3c:	bfe5                	j	80000f34 <strncmp+0x32>

0000000080000f3e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f3e:	1141                	addi	sp,sp,-16
    80000f40:	e422                	sd	s0,8(sp)
    80000f42:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f44:	872a                	mv	a4,a0
    80000f46:	8832                	mv	a6,a2
    80000f48:	367d                	addiw	a2,a2,-1
    80000f4a:	01005963          	blez	a6,80000f5c <strncpy+0x1e>
    80000f4e:	0705                	addi	a4,a4,1
    80000f50:	0005c783          	lbu	a5,0(a1)
    80000f54:	fef70fa3          	sb	a5,-1(a4)
    80000f58:	0585                	addi	a1,a1,1
    80000f5a:	f7f5                	bnez	a5,80000f46 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f5c:	00c05d63          	blez	a2,80000f76 <strncpy+0x38>
    80000f60:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f62:	0685                	addi	a3,a3,1
    80000f64:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f68:	fff6c793          	not	a5,a3
    80000f6c:	9fb9                	addw	a5,a5,a4
    80000f6e:	010787bb          	addw	a5,a5,a6
    80000f72:	fef048e3          	bgtz	a5,80000f62 <strncpy+0x24>
  return os;
}
    80000f76:	6422                	ld	s0,8(sp)
    80000f78:	0141                	addi	sp,sp,16
    80000f7a:	8082                	ret

0000000080000f7c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f7c:	1141                	addi	sp,sp,-16
    80000f7e:	e422                	sd	s0,8(sp)
    80000f80:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f82:	02c05363          	blez	a2,80000fa8 <safestrcpy+0x2c>
    80000f86:	fff6069b          	addiw	a3,a2,-1
    80000f8a:	1682                	slli	a3,a3,0x20
    80000f8c:	9281                	srli	a3,a3,0x20
    80000f8e:	96ae                	add	a3,a3,a1
    80000f90:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f92:	00d58963          	beq	a1,a3,80000fa4 <safestrcpy+0x28>
    80000f96:	0585                	addi	a1,a1,1
    80000f98:	0785                	addi	a5,a5,1
    80000f9a:	fff5c703          	lbu	a4,-1(a1)
    80000f9e:	fee78fa3          	sb	a4,-1(a5)
    80000fa2:	fb65                	bnez	a4,80000f92 <safestrcpy+0x16>
    ;
  *s = 0;
    80000fa4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fa8:	6422                	ld	s0,8(sp)
    80000faa:	0141                	addi	sp,sp,16
    80000fac:	8082                	ret

0000000080000fae <strlen>:

int
strlen(const char *s)
{
    80000fae:	1141                	addi	sp,sp,-16
    80000fb0:	e422                	sd	s0,8(sp)
    80000fb2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fb4:	00054783          	lbu	a5,0(a0)
    80000fb8:	cf91                	beqz	a5,80000fd4 <strlen+0x26>
    80000fba:	0505                	addi	a0,a0,1
    80000fbc:	87aa                	mv	a5,a0
    80000fbe:	4685                	li	a3,1
    80000fc0:	9e89                	subw	a3,a3,a0
    80000fc2:	00f6853b          	addw	a0,a3,a5
    80000fc6:	0785                	addi	a5,a5,1
    80000fc8:	fff7c703          	lbu	a4,-1(a5)
    80000fcc:	fb7d                	bnez	a4,80000fc2 <strlen+0x14>
    ;
  return n;
}
    80000fce:	6422                	ld	s0,8(sp)
    80000fd0:	0141                	addi	sp,sp,16
    80000fd2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fd4:	4501                	li	a0,0
    80000fd6:	bfe5                	j	80000fce <strlen+0x20>

0000000080000fd8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fd8:	1141                	addi	sp,sp,-16
    80000fda:	e406                	sd	ra,8(sp)
    80000fdc:	e022                	sd	s0,0(sp)
    80000fde:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	b14080e7          	jalr	-1260(ra) # 80001af4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fe8:	00008717          	auipc	a4,0x8
    80000fec:	03070713          	addi	a4,a4,48 # 80009018 <started>
  if(cpuid() == 0){
    80000ff0:	c139                	beqz	a0,80001036 <main+0x5e>
    while(started == 0)
    80000ff2:	431c                	lw	a5,0(a4)
    80000ff4:	2781                	sext.w	a5,a5
    80000ff6:	dff5                	beqz	a5,80000ff2 <main+0x1a>
      ;
    __sync_synchronize();
    80000ff8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ffc:	00001097          	auipc	ra,0x1
    80001000:	af8080e7          	jalr	-1288(ra) # 80001af4 <cpuid>
    80001004:	85aa                	mv	a1,a0
    80001006:	00007517          	auipc	a0,0x7
    8000100a:	0da50513          	addi	a0,a0,218 # 800080e0 <digits+0xa0>
    8000100e:	fffff097          	auipc	ra,0xfffff
    80001012:	57a080e7          	jalr	1402(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80001016:	00000097          	auipc	ra,0x0
    8000101a:	0d8080e7          	jalr	216(ra) # 800010ee <kvminithart>
    trapinithart();   // install kernel trap vector
    8000101e:	00001097          	auipc	ra,0x1
    80001022:	74e080e7          	jalr	1870(ra) # 8000276c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001026:	00005097          	auipc	ra,0x5
    8000102a:	d7a080e7          	jalr	-646(ra) # 80005da0 <plicinithart>
  }

  scheduler();        
    8000102e:	00001097          	auipc	ra,0x1
    80001032:	ffc080e7          	jalr	-4(ra) # 8000202a <scheduler>
    consoleinit();
    80001036:	fffff097          	auipc	ra,0xfffff
    8000103a:	41a080e7          	jalr	1050(ra) # 80000450 <consoleinit>
    printfinit();
    8000103e:	fffff097          	auipc	ra,0xfffff
    80001042:	730080e7          	jalr	1840(ra) # 8000076e <printfinit>
    printf("\n");
    80001046:	00007517          	auipc	a0,0x7
    8000104a:	0aa50513          	addi	a0,a0,170 # 800080f0 <digits+0xb0>
    8000104e:	fffff097          	auipc	ra,0xfffff
    80001052:	53a080e7          	jalr	1338(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80001056:	00007517          	auipc	a0,0x7
    8000105a:	07250513          	addi	a0,a0,114 # 800080c8 <digits+0x88>
    8000105e:	fffff097          	auipc	ra,0xfffff
    80001062:	52a080e7          	jalr	1322(ra) # 80000588 <printf>
    printf("\n");
    80001066:	00007517          	auipc	a0,0x7
    8000106a:	08a50513          	addi	a0,a0,138 # 800080f0 <digits+0xb0>
    8000106e:	fffff097          	auipc	ra,0xfffff
    80001072:	51a080e7          	jalr	1306(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80001076:	00000097          	auipc	ra,0x0
    8000107a:	b4a080e7          	jalr	-1206(ra) # 80000bc0 <kinit>
    kvminit();       // create kernel page table
    8000107e:	00000097          	auipc	ra,0x0
    80001082:	322080e7          	jalr	802(ra) # 800013a0 <kvminit>
    kvminithart();   // turn on paging
    80001086:	00000097          	auipc	ra,0x0
    8000108a:	068080e7          	jalr	104(ra) # 800010ee <kvminithart>
    procinit();      // process table
    8000108e:	00001097          	auipc	ra,0x1
    80001092:	9b6080e7          	jalr	-1610(ra) # 80001a44 <procinit>
    trapinit();      // trap vectors
    80001096:	00001097          	auipc	ra,0x1
    8000109a:	6ae080e7          	jalr	1710(ra) # 80002744 <trapinit>
    trapinithart();  // install kernel trap vector
    8000109e:	00001097          	auipc	ra,0x1
    800010a2:	6ce080e7          	jalr	1742(ra) # 8000276c <trapinithart>
    plicinit();      // set up interrupt controller
    800010a6:	00005097          	auipc	ra,0x5
    800010aa:	ce4080e7          	jalr	-796(ra) # 80005d8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010ae:	00005097          	auipc	ra,0x5
    800010b2:	cf2080e7          	jalr	-782(ra) # 80005da0 <plicinithart>
    binit();         // buffer cache
    800010b6:	00002097          	auipc	ra,0x2
    800010ba:	eca080e7          	jalr	-310(ra) # 80002f80 <binit>
    iinit();         // inode table
    800010be:	00002097          	auipc	ra,0x2
    800010c2:	55a080e7          	jalr	1370(ra) # 80003618 <iinit>
    fileinit();      // file table
    800010c6:	00003097          	auipc	ra,0x3
    800010ca:	504080e7          	jalr	1284(ra) # 800045ca <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010ce:	00005097          	auipc	ra,0x5
    800010d2:	df4080e7          	jalr	-524(ra) # 80005ec2 <virtio_disk_init>
    userinit();      // first user process
    800010d6:	00001097          	auipc	ra,0x1
    800010da:	d22080e7          	jalr	-734(ra) # 80001df8 <userinit>
    __sync_synchronize();
    800010de:	0ff0000f          	fence
    started = 1;
    800010e2:	4785                	li	a5,1
    800010e4:	00008717          	auipc	a4,0x8
    800010e8:	f2f72a23          	sw	a5,-204(a4) # 80009018 <started>
    800010ec:	b789                	j	8000102e <main+0x56>

00000000800010ee <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010ee:	1141                	addi	sp,sp,-16
    800010f0:	e422                	sd	s0,8(sp)
    800010f2:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010f4:	00008797          	auipc	a5,0x8
    800010f8:	f2c7b783          	ld	a5,-212(a5) # 80009020 <kernel_pagetable>
    800010fc:	83b1                	srli	a5,a5,0xc
    800010fe:	577d                	li	a4,-1
    80001100:	177e                	slli	a4,a4,0x3f
    80001102:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001104:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001108:	12000073          	sfence.vma
  sfence_vma();
}
    8000110c:	6422                	ld	s0,8(sp)
    8000110e:	0141                	addi	sp,sp,16
    80001110:	8082                	ret

0000000080001112 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001112:	7139                	addi	sp,sp,-64
    80001114:	fc06                	sd	ra,56(sp)
    80001116:	f822                	sd	s0,48(sp)
    80001118:	f426                	sd	s1,40(sp)
    8000111a:	f04a                	sd	s2,32(sp)
    8000111c:	ec4e                	sd	s3,24(sp)
    8000111e:	e852                	sd	s4,16(sp)
    80001120:	e456                	sd	s5,8(sp)
    80001122:	e05a                	sd	s6,0(sp)
    80001124:	0080                	addi	s0,sp,64
    80001126:	84aa                	mv	s1,a0
    80001128:	89ae                	mv	s3,a1
    8000112a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000112c:	57fd                	li	a5,-1
    8000112e:	83e9                	srli	a5,a5,0x1a
    80001130:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001132:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001134:	04b7f263          	bgeu	a5,a1,80001178 <walk+0x66>
    panic("walk");
    80001138:	00007517          	auipc	a0,0x7
    8000113c:	fc050513          	addi	a0,a0,-64 # 800080f8 <digits+0xb8>
    80001140:	fffff097          	auipc	ra,0xfffff
    80001144:	3fe080e7          	jalr	1022(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001148:	060a8663          	beqz	s5,800011b4 <walk+0xa2>
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	ad6080e7          	jalr	-1322(ra) # 80000c22 <kalloc>
    80001154:	84aa                	mv	s1,a0
    80001156:	c529                	beqz	a0,800011a0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001158:	6605                	lui	a2,0x1
    8000115a:	4581                	li	a1,0
    8000115c:	00000097          	auipc	ra,0x0
    80001160:	cce080e7          	jalr	-818(ra) # 80000e2a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001164:	00c4d793          	srli	a5,s1,0xc
    80001168:	07aa                	slli	a5,a5,0xa
    8000116a:	0017e793          	ori	a5,a5,1
    8000116e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001172:	3a5d                	addiw	s4,s4,-9
    80001174:	036a0063          	beq	s4,s6,80001194 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001178:	0149d933          	srl	s2,s3,s4
    8000117c:	1ff97913          	andi	s2,s2,511
    80001180:	090e                	slli	s2,s2,0x3
    80001182:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001184:	00093483          	ld	s1,0(s2)
    80001188:	0014f793          	andi	a5,s1,1
    8000118c:	dfd5                	beqz	a5,80001148 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000118e:	80a9                	srli	s1,s1,0xa
    80001190:	04b2                	slli	s1,s1,0xc
    80001192:	b7c5                	j	80001172 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001194:	00c9d513          	srli	a0,s3,0xc
    80001198:	1ff57513          	andi	a0,a0,511
    8000119c:	050e                	slli	a0,a0,0x3
    8000119e:	9526                	add	a0,a0,s1
}
    800011a0:	70e2                	ld	ra,56(sp)
    800011a2:	7442                	ld	s0,48(sp)
    800011a4:	74a2                	ld	s1,40(sp)
    800011a6:	7902                	ld	s2,32(sp)
    800011a8:	69e2                	ld	s3,24(sp)
    800011aa:	6a42                	ld	s4,16(sp)
    800011ac:	6aa2                	ld	s5,8(sp)
    800011ae:	6b02                	ld	s6,0(sp)
    800011b0:	6121                	addi	sp,sp,64
    800011b2:	8082                	ret
        return 0;
    800011b4:	4501                	li	a0,0
    800011b6:	b7ed                	j	800011a0 <walk+0x8e>

00000000800011b8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011b8:	57fd                	li	a5,-1
    800011ba:	83e9                	srli	a5,a5,0x1a
    800011bc:	00b7f463          	bgeu	a5,a1,800011c4 <walkaddr+0xc>
    return 0;
    800011c0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011c2:	8082                	ret
{
    800011c4:	1141                	addi	sp,sp,-16
    800011c6:	e406                	sd	ra,8(sp)
    800011c8:	e022                	sd	s0,0(sp)
    800011ca:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011cc:	4601                	li	a2,0
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f44080e7          	jalr	-188(ra) # 80001112 <walk>
  if(pte == 0)
    800011d6:	c105                	beqz	a0,800011f6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011d8:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011da:	0117f693          	andi	a3,a5,17
    800011de:	4745                	li	a4,17
    return 0;
    800011e0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011e2:	00e68663          	beq	a3,a4,800011ee <walkaddr+0x36>
}
    800011e6:	60a2                	ld	ra,8(sp)
    800011e8:	6402                	ld	s0,0(sp)
    800011ea:	0141                	addi	sp,sp,16
    800011ec:	8082                	ret
  pa = PTE2PA(*pte);
    800011ee:	00a7d513          	srli	a0,a5,0xa
    800011f2:	0532                	slli	a0,a0,0xc
  return pa;
    800011f4:	bfcd                	j	800011e6 <walkaddr+0x2e>
    return 0;
    800011f6:	4501                	li	a0,0
    800011f8:	b7fd                	j	800011e6 <walkaddr+0x2e>

00000000800011fa <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011fa:	715d                	addi	sp,sp,-80
    800011fc:	e486                	sd	ra,72(sp)
    800011fe:	e0a2                	sd	s0,64(sp)
    80001200:	fc26                	sd	s1,56(sp)
    80001202:	f84a                	sd	s2,48(sp)
    80001204:	f44e                	sd	s3,40(sp)
    80001206:	f052                	sd	s4,32(sp)
    80001208:	ec56                	sd	s5,24(sp)
    8000120a:	e85a                	sd	s6,16(sp)
    8000120c:	e45e                	sd	s7,8(sp)
    8000120e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001210:	c205                	beqz	a2,80001230 <mappages+0x36>
    80001212:	8aaa                	mv	s5,a0
    80001214:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001216:	77fd                	lui	a5,0xfffff
    80001218:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000121c:	15fd                	addi	a1,a1,-1
    8000121e:	00c589b3          	add	s3,a1,a2
    80001222:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001226:	8952                	mv	s2,s4
    80001228:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000122c:	6b85                	lui	s7,0x1
    8000122e:	a015                	j	80001252 <mappages+0x58>
    panic("mappages: size");
    80001230:	00007517          	auipc	a0,0x7
    80001234:	ed050513          	addi	a0,a0,-304 # 80008100 <digits+0xc0>
    80001238:	fffff097          	auipc	ra,0xfffff
    8000123c:	306080e7          	jalr	774(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001240:	00007517          	auipc	a0,0x7
    80001244:	ed050513          	addi	a0,a0,-304 # 80008110 <digits+0xd0>
    80001248:	fffff097          	auipc	ra,0xfffff
    8000124c:	2f6080e7          	jalr	758(ra) # 8000053e <panic>
    a += PGSIZE;
    80001250:	995e                	add	s2,s2,s7
  for(;;){
    80001252:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001256:	4605                	li	a2,1
    80001258:	85ca                	mv	a1,s2
    8000125a:	8556                	mv	a0,s5
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	eb6080e7          	jalr	-330(ra) # 80001112 <walk>
    80001264:	cd19                	beqz	a0,80001282 <mappages+0x88>
    if(*pte & PTE_V)
    80001266:	611c                	ld	a5,0(a0)
    80001268:	8b85                	andi	a5,a5,1
    8000126a:	fbf9                	bnez	a5,80001240 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000126c:	80b1                	srli	s1,s1,0xc
    8000126e:	04aa                	slli	s1,s1,0xa
    80001270:	0164e4b3          	or	s1,s1,s6
    80001274:	0014e493          	ori	s1,s1,1
    80001278:	e104                	sd	s1,0(a0)
    if(a == last)
    8000127a:	fd391be3          	bne	s2,s3,80001250 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000127e:	4501                	li	a0,0
    80001280:	a011                	j	80001284 <mappages+0x8a>
      return -1;
    80001282:	557d                	li	a0,-1
}
    80001284:	60a6                	ld	ra,72(sp)
    80001286:	6406                	ld	s0,64(sp)
    80001288:	74e2                	ld	s1,56(sp)
    8000128a:	7942                	ld	s2,48(sp)
    8000128c:	79a2                	ld	s3,40(sp)
    8000128e:	7a02                	ld	s4,32(sp)
    80001290:	6ae2                	ld	s5,24(sp)
    80001292:	6b42                	ld	s6,16(sp)
    80001294:	6ba2                	ld	s7,8(sp)
    80001296:	6161                	addi	sp,sp,80
    80001298:	8082                	ret

000000008000129a <kvmmap>:
{
    8000129a:	1141                	addi	sp,sp,-16
    8000129c:	e406                	sd	ra,8(sp)
    8000129e:	e022                	sd	s0,0(sp)
    800012a0:	0800                	addi	s0,sp,16
    800012a2:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012a4:	86b2                	mv	a3,a2
    800012a6:	863e                	mv	a2,a5
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f52080e7          	jalr	-174(ra) # 800011fa <mappages>
    800012b0:	e509                	bnez	a0,800012ba <kvmmap+0x20>
}
    800012b2:	60a2                	ld	ra,8(sp)
    800012b4:	6402                	ld	s0,0(sp)
    800012b6:	0141                	addi	sp,sp,16
    800012b8:	8082                	ret
    panic("kvmmap");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e6650513          	addi	a0,a0,-410 # 80008120 <digits+0xe0>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>

00000000800012ca <kvmmake>:
{
    800012ca:	1101                	addi	sp,sp,-32
    800012cc:	ec06                	sd	ra,24(sp)
    800012ce:	e822                	sd	s0,16(sp)
    800012d0:	e426                	sd	s1,8(sp)
    800012d2:	e04a                	sd	s2,0(sp)
    800012d4:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012d6:	00000097          	auipc	ra,0x0
    800012da:	94c080e7          	jalr	-1716(ra) # 80000c22 <kalloc>
    800012de:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012e0:	6605                	lui	a2,0x1
    800012e2:	4581                	li	a1,0
    800012e4:	00000097          	auipc	ra,0x0
    800012e8:	b46080e7          	jalr	-1210(ra) # 80000e2a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012ec:	4719                	li	a4,6
    800012ee:	6685                	lui	a3,0x1
    800012f0:	10000637          	lui	a2,0x10000
    800012f4:	100005b7          	lui	a1,0x10000
    800012f8:	8526                	mv	a0,s1
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	fa0080e7          	jalr	-96(ra) # 8000129a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001302:	4719                	li	a4,6
    80001304:	6685                	lui	a3,0x1
    80001306:	10001637          	lui	a2,0x10001
    8000130a:	100015b7          	lui	a1,0x10001
    8000130e:	8526                	mv	a0,s1
    80001310:	00000097          	auipc	ra,0x0
    80001314:	f8a080e7          	jalr	-118(ra) # 8000129a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001318:	4719                	li	a4,6
    8000131a:	004006b7          	lui	a3,0x400
    8000131e:	0c000637          	lui	a2,0xc000
    80001322:	0c0005b7          	lui	a1,0xc000
    80001326:	8526                	mv	a0,s1
    80001328:	00000097          	auipc	ra,0x0
    8000132c:	f72080e7          	jalr	-142(ra) # 8000129a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001330:	00007917          	auipc	s2,0x7
    80001334:	cd090913          	addi	s2,s2,-816 # 80008000 <etext>
    80001338:	4729                	li	a4,10
    8000133a:	80007697          	auipc	a3,0x80007
    8000133e:	cc668693          	addi	a3,a3,-826 # 8000 <_entry-0x7fff8000>
    80001342:	4605                	li	a2,1
    80001344:	067e                	slli	a2,a2,0x1f
    80001346:	85b2                	mv	a1,a2
    80001348:	8526                	mv	a0,s1
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	f50080e7          	jalr	-176(ra) # 8000129a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001352:	4719                	li	a4,6
    80001354:	46c5                	li	a3,17
    80001356:	06ee                	slli	a3,a3,0x1b
    80001358:	412686b3          	sub	a3,a3,s2
    8000135c:	864a                	mv	a2,s2
    8000135e:	85ca                	mv	a1,s2
    80001360:	8526                	mv	a0,s1
    80001362:	00000097          	auipc	ra,0x0
    80001366:	f38080e7          	jalr	-200(ra) # 8000129a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000136a:	4729                	li	a4,10
    8000136c:	6685                	lui	a3,0x1
    8000136e:	00006617          	auipc	a2,0x6
    80001372:	c9260613          	addi	a2,a2,-878 # 80007000 <_trampoline>
    80001376:	040005b7          	lui	a1,0x4000
    8000137a:	15fd                	addi	a1,a1,-1
    8000137c:	05b2                	slli	a1,a1,0xc
    8000137e:	8526                	mv	a0,s1
    80001380:	00000097          	auipc	ra,0x0
    80001384:	f1a080e7          	jalr	-230(ra) # 8000129a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001388:	8526                	mv	a0,s1
    8000138a:	00000097          	auipc	ra,0x0
    8000138e:	624080e7          	jalr	1572(ra) # 800019ae <proc_mapstacks>
}
    80001392:	8526                	mv	a0,s1
    80001394:	60e2                	ld	ra,24(sp)
    80001396:	6442                	ld	s0,16(sp)
    80001398:	64a2                	ld	s1,8(sp)
    8000139a:	6902                	ld	s2,0(sp)
    8000139c:	6105                	addi	sp,sp,32
    8000139e:	8082                	ret

00000000800013a0 <kvminit>:
{
    800013a0:	1141                	addi	sp,sp,-16
    800013a2:	e406                	sd	ra,8(sp)
    800013a4:	e022                	sd	s0,0(sp)
    800013a6:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	f22080e7          	jalr	-222(ra) # 800012ca <kvmmake>
    800013b0:	00008797          	auipc	a5,0x8
    800013b4:	c6a7b823          	sd	a0,-912(a5) # 80009020 <kernel_pagetable>
}
    800013b8:	60a2                	ld	ra,8(sp)
    800013ba:	6402                	ld	s0,0(sp)
    800013bc:	0141                	addi	sp,sp,16
    800013be:	8082                	ret

00000000800013c0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013c0:	715d                	addi	sp,sp,-80
    800013c2:	e486                	sd	ra,72(sp)
    800013c4:	e0a2                	sd	s0,64(sp)
    800013c6:	fc26                	sd	s1,56(sp)
    800013c8:	f84a                	sd	s2,48(sp)
    800013ca:	f44e                	sd	s3,40(sp)
    800013cc:	f052                	sd	s4,32(sp)
    800013ce:	ec56                	sd	s5,24(sp)
    800013d0:	e85a                	sd	s6,16(sp)
    800013d2:	e45e                	sd	s7,8(sp)
    800013d4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013d6:	03459793          	slli	a5,a1,0x34
    800013da:	e795                	bnez	a5,80001406 <uvmunmap+0x46>
    800013dc:	8a2a                	mv	s4,a0
    800013de:	892e                	mv	s2,a1
    800013e0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013e2:	0632                	slli	a2,a2,0xc
    800013e4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013e8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013ea:	6b05                	lui	s6,0x1
    800013ec:	0735e863          	bltu	a1,s3,8000145c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013f0:	60a6                	ld	ra,72(sp)
    800013f2:	6406                	ld	s0,64(sp)
    800013f4:	74e2                	ld	s1,56(sp)
    800013f6:	7942                	ld	s2,48(sp)
    800013f8:	79a2                	ld	s3,40(sp)
    800013fa:	7a02                	ld	s4,32(sp)
    800013fc:	6ae2                	ld	s5,24(sp)
    800013fe:	6b42                	ld	s6,16(sp)
    80001400:	6ba2                	ld	s7,8(sp)
    80001402:	6161                	addi	sp,sp,80
    80001404:	8082                	ret
    panic("uvmunmap: not aligned");
    80001406:	00007517          	auipc	a0,0x7
    8000140a:	d2250513          	addi	a0,a0,-734 # 80008128 <digits+0xe8>
    8000140e:	fffff097          	auipc	ra,0xfffff
    80001412:	130080e7          	jalr	304(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    80001416:	00007517          	auipc	a0,0x7
    8000141a:	d2a50513          	addi	a0,a0,-726 # 80008140 <digits+0x100>
    8000141e:	fffff097          	auipc	ra,0xfffff
    80001422:	120080e7          	jalr	288(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001426:	00007517          	auipc	a0,0x7
    8000142a:	d2a50513          	addi	a0,a0,-726 # 80008150 <digits+0x110>
    8000142e:	fffff097          	auipc	ra,0xfffff
    80001432:	110080e7          	jalr	272(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001436:	00007517          	auipc	a0,0x7
    8000143a:	d3250513          	addi	a0,a0,-718 # 80008168 <digits+0x128>
    8000143e:	fffff097          	auipc	ra,0xfffff
    80001442:	100080e7          	jalr	256(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001446:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001448:	0532                	slli	a0,a0,0xc
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	69c080e7          	jalr	1692(ra) # 80000ae6 <kfree>
    *pte = 0;
    80001452:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001456:	995a                	add	s2,s2,s6
    80001458:	f9397ce3          	bgeu	s2,s3,800013f0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000145c:	4601                	li	a2,0
    8000145e:	85ca                	mv	a1,s2
    80001460:	8552                	mv	a0,s4
    80001462:	00000097          	auipc	ra,0x0
    80001466:	cb0080e7          	jalr	-848(ra) # 80001112 <walk>
    8000146a:	84aa                	mv	s1,a0
    8000146c:	d54d                	beqz	a0,80001416 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000146e:	6108                	ld	a0,0(a0)
    80001470:	00157793          	andi	a5,a0,1
    80001474:	dbcd                	beqz	a5,80001426 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001476:	3ff57793          	andi	a5,a0,1023
    8000147a:	fb778ee3          	beq	a5,s7,80001436 <uvmunmap+0x76>
    if(do_free){
    8000147e:	fc0a8ae3          	beqz	s5,80001452 <uvmunmap+0x92>
    80001482:	b7d1                	j	80001446 <uvmunmap+0x86>

0000000080001484 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001484:	1101                	addi	sp,sp,-32
    80001486:	ec06                	sd	ra,24(sp)
    80001488:	e822                	sd	s0,16(sp)
    8000148a:	e426                	sd	s1,8(sp)
    8000148c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	794080e7          	jalr	1940(ra) # 80000c22 <kalloc>
    80001496:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001498:	c519                	beqz	a0,800014a6 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000149a:	6605                	lui	a2,0x1
    8000149c:	4581                	li	a1,0
    8000149e:	00000097          	auipc	ra,0x0
    800014a2:	98c080e7          	jalr	-1652(ra) # 80000e2a <memset>
  return pagetable;
}
    800014a6:	8526                	mv	a0,s1
    800014a8:	60e2                	ld	ra,24(sp)
    800014aa:	6442                	ld	s0,16(sp)
    800014ac:	64a2                	ld	s1,8(sp)
    800014ae:	6105                	addi	sp,sp,32
    800014b0:	8082                	ret

00000000800014b2 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800014b2:	7179                	addi	sp,sp,-48
    800014b4:	f406                	sd	ra,40(sp)
    800014b6:	f022                	sd	s0,32(sp)
    800014b8:	ec26                	sd	s1,24(sp)
    800014ba:	e84a                	sd	s2,16(sp)
    800014bc:	e44e                	sd	s3,8(sp)
    800014be:	e052                	sd	s4,0(sp)
    800014c0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014c2:	6785                	lui	a5,0x1
    800014c4:	04f67863          	bgeu	a2,a5,80001514 <uvminit+0x62>
    800014c8:	8a2a                	mv	s4,a0
    800014ca:	89ae                	mv	s3,a1
    800014cc:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	754080e7          	jalr	1876(ra) # 80000c22 <kalloc>
    800014d6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014d8:	6605                	lui	a2,0x1
    800014da:	4581                	li	a1,0
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	94e080e7          	jalr	-1714(ra) # 80000e2a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014e4:	4779                	li	a4,30
    800014e6:	86ca                	mv	a3,s2
    800014e8:	6605                	lui	a2,0x1
    800014ea:	4581                	li	a1,0
    800014ec:	8552                	mv	a0,s4
    800014ee:	00000097          	auipc	ra,0x0
    800014f2:	d0c080e7          	jalr	-756(ra) # 800011fa <mappages>
  memmove(mem, src, sz);
    800014f6:	8626                	mv	a2,s1
    800014f8:	85ce                	mv	a1,s3
    800014fa:	854a                	mv	a0,s2
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	98e080e7          	jalr	-1650(ra) # 80000e8a <memmove>
}
    80001504:	70a2                	ld	ra,40(sp)
    80001506:	7402                	ld	s0,32(sp)
    80001508:	64e2                	ld	s1,24(sp)
    8000150a:	6942                	ld	s2,16(sp)
    8000150c:	69a2                	ld	s3,8(sp)
    8000150e:	6a02                	ld	s4,0(sp)
    80001510:	6145                	addi	sp,sp,48
    80001512:	8082                	ret
    panic("inituvm: more than a page");
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6c50513          	addi	a0,a0,-916 # 80008180 <digits+0x140>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>

0000000080001524 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001524:	1101                	addi	sp,sp,-32
    80001526:	ec06                	sd	ra,24(sp)
    80001528:	e822                	sd	s0,16(sp)
    8000152a:	e426                	sd	s1,8(sp)
    8000152c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000152e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001530:	00b67d63          	bgeu	a2,a1,8000154a <uvmdealloc+0x26>
    80001534:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001536:	6785                	lui	a5,0x1
    80001538:	17fd                	addi	a5,a5,-1
    8000153a:	00f60733          	add	a4,a2,a5
    8000153e:	767d                	lui	a2,0xfffff
    80001540:	8f71                	and	a4,a4,a2
    80001542:	97ae                	add	a5,a5,a1
    80001544:	8ff1                	and	a5,a5,a2
    80001546:	00f76863          	bltu	a4,a5,80001556 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000154a:	8526                	mv	a0,s1
    8000154c:	60e2                	ld	ra,24(sp)
    8000154e:	6442                	ld	s0,16(sp)
    80001550:	64a2                	ld	s1,8(sp)
    80001552:	6105                	addi	sp,sp,32
    80001554:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001556:	8f99                	sub	a5,a5,a4
    80001558:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000155a:	4685                	li	a3,1
    8000155c:	0007861b          	sext.w	a2,a5
    80001560:	85ba                	mv	a1,a4
    80001562:	00000097          	auipc	ra,0x0
    80001566:	e5e080e7          	jalr	-418(ra) # 800013c0 <uvmunmap>
    8000156a:	b7c5                	j	8000154a <uvmdealloc+0x26>

000000008000156c <uvmalloc>:
  if(newsz < oldsz)
    8000156c:	0ab66163          	bltu	a2,a1,8000160e <uvmalloc+0xa2>
{
    80001570:	7139                	addi	sp,sp,-64
    80001572:	fc06                	sd	ra,56(sp)
    80001574:	f822                	sd	s0,48(sp)
    80001576:	f426                	sd	s1,40(sp)
    80001578:	f04a                	sd	s2,32(sp)
    8000157a:	ec4e                	sd	s3,24(sp)
    8000157c:	e852                	sd	s4,16(sp)
    8000157e:	e456                	sd	s5,8(sp)
    80001580:	0080                	addi	s0,sp,64
    80001582:	8aaa                	mv	s5,a0
    80001584:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001586:	6985                	lui	s3,0x1
    80001588:	19fd                	addi	s3,s3,-1
    8000158a:	95ce                	add	a1,a1,s3
    8000158c:	79fd                	lui	s3,0xfffff
    8000158e:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001592:	08c9f063          	bgeu	s3,a2,80001612 <uvmalloc+0xa6>
    80001596:	894e                	mv	s2,s3
    mem = kalloc();
    80001598:	fffff097          	auipc	ra,0xfffff
    8000159c:	68a080e7          	jalr	1674(ra) # 80000c22 <kalloc>
    800015a0:	84aa                	mv	s1,a0
    if(mem == 0){
    800015a2:	c51d                	beqz	a0,800015d0 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015a4:	6605                	lui	a2,0x1
    800015a6:	4581                	li	a1,0
    800015a8:	00000097          	auipc	ra,0x0
    800015ac:	882080e7          	jalr	-1918(ra) # 80000e2a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800015b0:	4779                	li	a4,30
    800015b2:	86a6                	mv	a3,s1
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85ca                	mv	a1,s2
    800015b8:	8556                	mv	a0,s5
    800015ba:	00000097          	auipc	ra,0x0
    800015be:	c40080e7          	jalr	-960(ra) # 800011fa <mappages>
    800015c2:	e905                	bnez	a0,800015f2 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015c4:	6785                	lui	a5,0x1
    800015c6:	993e                	add	s2,s2,a5
    800015c8:	fd4968e3          	bltu	s2,s4,80001598 <uvmalloc+0x2c>
  return newsz;
    800015cc:	8552                	mv	a0,s4
    800015ce:	a809                	j	800015e0 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015d0:	864e                	mv	a2,s3
    800015d2:	85ca                	mv	a1,s2
    800015d4:	8556                	mv	a0,s5
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	f4e080e7          	jalr	-178(ra) # 80001524 <uvmdealloc>
      return 0;
    800015de:	4501                	li	a0,0
}
    800015e0:	70e2                	ld	ra,56(sp)
    800015e2:	7442                	ld	s0,48(sp)
    800015e4:	74a2                	ld	s1,40(sp)
    800015e6:	7902                	ld	s2,32(sp)
    800015e8:	69e2                	ld	s3,24(sp)
    800015ea:	6a42                	ld	s4,16(sp)
    800015ec:	6aa2                	ld	s5,8(sp)
    800015ee:	6121                	addi	sp,sp,64
    800015f0:	8082                	ret
      kfree(mem);
    800015f2:	8526                	mv	a0,s1
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	4f2080e7          	jalr	1266(ra) # 80000ae6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015fc:	864e                	mv	a2,s3
    800015fe:	85ca                	mv	a1,s2
    80001600:	8556                	mv	a0,s5
    80001602:	00000097          	auipc	ra,0x0
    80001606:	f22080e7          	jalr	-222(ra) # 80001524 <uvmdealloc>
      return 0;
    8000160a:	4501                	li	a0,0
    8000160c:	bfd1                	j	800015e0 <uvmalloc+0x74>
    return oldsz;
    8000160e:	852e                	mv	a0,a1
}
    80001610:	8082                	ret
  return newsz;
    80001612:	8532                	mv	a0,a2
    80001614:	b7f1                	j	800015e0 <uvmalloc+0x74>

0000000080001616 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001616:	7179                	addi	sp,sp,-48
    80001618:	f406                	sd	ra,40(sp)
    8000161a:	f022                	sd	s0,32(sp)
    8000161c:	ec26                	sd	s1,24(sp)
    8000161e:	e84a                	sd	s2,16(sp)
    80001620:	e44e                	sd	s3,8(sp)
    80001622:	e052                	sd	s4,0(sp)
    80001624:	1800                	addi	s0,sp,48
    80001626:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001628:	84aa                	mv	s1,a0
    8000162a:	6905                	lui	s2,0x1
    8000162c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000162e:	4985                	li	s3,1
    80001630:	a821                	j	80001648 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001632:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001634:	0532                	slli	a0,a0,0xc
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	fe0080e7          	jalr	-32(ra) # 80001616 <freewalk>
      pagetable[i] = 0;
    8000163e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001642:	04a1                	addi	s1,s1,8
    80001644:	03248163          	beq	s1,s2,80001666 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001648:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000164a:	00f57793          	andi	a5,a0,15
    8000164e:	ff3782e3          	beq	a5,s3,80001632 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001652:	8905                	andi	a0,a0,1
    80001654:	d57d                	beqz	a0,80001642 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001656:	00007517          	auipc	a0,0x7
    8000165a:	b4a50513          	addi	a0,a0,-1206 # 800081a0 <digits+0x160>
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001666:	8552                	mv	a0,s4
    80001668:	fffff097          	auipc	ra,0xfffff
    8000166c:	47e080e7          	jalr	1150(ra) # 80000ae6 <kfree>
}
    80001670:	70a2                	ld	ra,40(sp)
    80001672:	7402                	ld	s0,32(sp)
    80001674:	64e2                	ld	s1,24(sp)
    80001676:	6942                	ld	s2,16(sp)
    80001678:	69a2                	ld	s3,8(sp)
    8000167a:	6a02                	ld	s4,0(sp)
    8000167c:	6145                	addi	sp,sp,48
    8000167e:	8082                	ret

0000000080001680 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001680:	1101                	addi	sp,sp,-32
    80001682:	ec06                	sd	ra,24(sp)
    80001684:	e822                	sd	s0,16(sp)
    80001686:	e426                	sd	s1,8(sp)
    80001688:	1000                	addi	s0,sp,32
    8000168a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000168c:	e999                	bnez	a1,800016a2 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000168e:	8526                	mv	a0,s1
    80001690:	00000097          	auipc	ra,0x0
    80001694:	f86080e7          	jalr	-122(ra) # 80001616 <freewalk>
}
    80001698:	60e2                	ld	ra,24(sp)
    8000169a:	6442                	ld	s0,16(sp)
    8000169c:	64a2                	ld	s1,8(sp)
    8000169e:	6105                	addi	sp,sp,32
    800016a0:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016a2:	6605                	lui	a2,0x1
    800016a4:	167d                	addi	a2,a2,-1
    800016a6:	962e                	add	a2,a2,a1
    800016a8:	4685                	li	a3,1
    800016aa:	8231                	srli	a2,a2,0xc
    800016ac:	4581                	li	a1,0
    800016ae:	00000097          	auipc	ra,0x0
    800016b2:	d12080e7          	jalr	-750(ra) # 800013c0 <uvmunmap>
    800016b6:	bfe1                	j	8000168e <uvmfree+0xe>

00000000800016b8 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    800016b8:	7139                	addi	sp,sp,-64
    800016ba:	fc06                	sd	ra,56(sp)
    800016bc:	f822                	sd	s0,48(sp)
    800016be:	f426                	sd	s1,40(sp)
    800016c0:	f04a                	sd	s2,32(sp)
    800016c2:	ec4e                	sd	s3,24(sp)
    800016c4:	e852                	sd	s4,16(sp)
    800016c6:	e456                	sd	s5,8(sp)
    800016c8:	e05a                	sd	s6,0(sp)
    800016ca:	0080                	addi	s0,sp,64
    800016cc:	8aaa                	mv	s5,a0
    800016ce:	8a2e                	mv	s4,a1
    800016d0:	89b2                	mv	s3,a2
  pte_t *pte;
  uint64 pa, i;
  printf("uvmcopy\n");
    800016d2:	00007517          	auipc	a0,0x7
    800016d6:	ade50513          	addi	a0,a0,-1314 # 800081b0 <digits+0x170>
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	eae080e7          	jalr	-338(ra) # 80000588 <printf>
  for(i = 0; i < sz; i += PGSIZE){
    800016e2:	0a098263          	beqz	s3,80001786 <uvmcopy+0xce>
    800016e6:	4481                	li	s1,0
    if((pte = walk(old, i, 0)) == 0)
    800016e8:	4601                	li	a2,0
    800016ea:	85a6                	mv	a1,s1
    800016ec:	8556                	mv	a0,s5
    800016ee:	00000097          	auipc	ra,0x0
    800016f2:	a24080e7          	jalr	-1500(ra) # 80001112 <walk>
    800016f6:	c139                	beqz	a0,8000173c <uvmcopy+0x84>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016f8:	6118                	ld	a4,0(a0)
    800016fa:	00177793          	andi	a5,a4,1
    800016fe:	c7b9                	beqz	a5,8000174c <uvmcopy+0x94>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001700:	00a75913          	srli	s2,a4,0xa
    80001704:	0932                	slli	s2,s2,0xc

    *pte = ((*pte) & (~PTE_W)) | PTE_COW;// -Write + COW for parent's page
    80001706:	dfb77713          	andi	a4,a4,-517
    8000170a:	20076713          	ori	a4,a4,512
    8000170e:	e118                	sd	a4,0(a0)
    // same flag for child's page
    if(mappages(new, i, PGSIZE, pa,(uint)PTE_FLAGS(*pte)) != 0){
    80001710:	3fb77713          	andi	a4,a4,1019
    80001714:	86ca                	mv	a3,s2
    80001716:	6605                	lui	a2,0x1
    80001718:	85a6                	mv	a1,s1
    8000171a:	8552                	mv	a0,s4
    8000171c:	00000097          	auipc	ra,0x0
    80001720:	ade080e7          	jalr	-1314(ra) # 800011fa <mappages>
    80001724:	8b2a                	mv	s6,a0
    80001726:	e91d                	bnez	a0,8000175c <uvmcopy+0xa4>
      goto err;
    }
    inc_reference_count(pa);
    80001728:	854a                	mv	a0,s2
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	2ce080e7          	jalr	718(ra) # 800009f8 <inc_reference_count>
  for(i = 0; i < sz; i += PGSIZE){
    80001732:	6785                	lui	a5,0x1
    80001734:	94be                	add	s1,s1,a5
    80001736:	fb34e9e3          	bltu	s1,s3,800016e8 <uvmcopy+0x30>
    8000173a:	a81d                	j	80001770 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000173c:	00007517          	auipc	a0,0x7
    80001740:	a8450513          	addi	a0,a0,-1404 # 800081c0 <digits+0x180>
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	dfa080e7          	jalr	-518(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000174c:	00007517          	auipc	a0,0x7
    80001750:	a9450513          	addi	a0,a0,-1388 # 800081e0 <digits+0x1a0>
    80001754:	fffff097          	auipc	ra,0xfffff
    80001758:	dea080e7          	jalr	-534(ra) # 8000053e <panic>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000175c:	4685                	li	a3,1
    8000175e:	00c4d613          	srli	a2,s1,0xc
    80001762:	4581                	li	a1,0
    80001764:	8552                	mv	a0,s4
    80001766:	00000097          	auipc	ra,0x0
    8000176a:	c5a080e7          	jalr	-934(ra) # 800013c0 <uvmunmap>
  return -1;
    8000176e:	5b7d                	li	s6,-1
}
    80001770:	855a                	mv	a0,s6
    80001772:	70e2                	ld	ra,56(sp)
    80001774:	7442                	ld	s0,48(sp)
    80001776:	74a2                	ld	s1,40(sp)
    80001778:	7902                	ld	s2,32(sp)
    8000177a:	69e2                	ld	s3,24(sp)
    8000177c:	6a42                	ld	s4,16(sp)
    8000177e:	6aa2                	ld	s5,8(sp)
    80001780:	6b02                	ld	s6,0(sp)
    80001782:	6121                	addi	sp,sp,64
    80001784:	8082                	ret
  return 0;
    80001786:	4b01                	li	s6,0
    80001788:	b7e5                	j	80001770 <uvmcopy+0xb8>

000000008000178a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000178a:	1141                	addi	sp,sp,-16
    8000178c:	e406                	sd	ra,8(sp)
    8000178e:	e022                	sd	s0,0(sp)
    80001790:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001792:	4601                	li	a2,0
    80001794:	00000097          	auipc	ra,0x0
    80001798:	97e080e7          	jalr	-1666(ra) # 80001112 <walk>
  if(pte == 0)
    8000179c:	c901                	beqz	a0,800017ac <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000179e:	611c                	ld	a5,0(a0)
    800017a0:	9bbd                	andi	a5,a5,-17
    800017a2:	e11c                	sd	a5,0(a0)
}
    800017a4:	60a2                	ld	ra,8(sp)
    800017a6:	6402                	ld	s0,0(sp)
    800017a8:	0141                	addi	sp,sp,16
    800017aa:	8082                	ret
    panic("uvmclear");
    800017ac:	00007517          	auipc	a0,0x7
    800017b0:	a5450513          	addi	a0,a0,-1452 # 80008200 <digits+0x1c0>
    800017b4:	fffff097          	auipc	ra,0xfffff
    800017b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>

00000000800017bc <copyout>:
// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
    800017bc:	715d                	addi	sp,sp,-80
    800017be:	e486                	sd	ra,72(sp)
    800017c0:	e0a2                	sd	s0,64(sp)
    800017c2:	fc26                	sd	s1,56(sp)
    800017c4:	f84a                	sd	s2,48(sp)
    800017c6:	f44e                	sd	s3,40(sp)
    800017c8:	f052                	sd	s4,32(sp)
    800017ca:	ec56                	sd	s5,24(sp)
    800017cc:	e85a                	sd	s6,16(sp)
    800017ce:	e45e                	sd	s7,8(sp)
    800017d0:	e062                	sd	s8,0(sp)
    800017d2:	0880                	addi	s0,sp,80
    800017d4:	8b2a                	mv	s6,a0
    800017d6:	892e                	mv	s2,a1
    800017d8:	8ab2                	mv	s5,a2
    800017da:	8a36                	mv	s4,a3
  uint64 n, va0, pa0;
  printf("copyout\n");
    800017dc:	00007517          	auipc	a0,0x7
    800017e0:	a3450513          	addi	a0,a0,-1484 # 80008210 <digits+0x1d0>
    800017e4:	fffff097          	auipc	ra,0xfffff
    800017e8:	da4080e7          	jalr	-604(ra) # 80000588 <printf>
  while(len > 0){
    800017ec:	060a0063          	beqz	s4,8000184c <copyout+0x90>
    va0 = PGROUNDDOWN(dstva);
    800017f0:	7c7d                	lui	s8,0xfffff
      return -1;
    }
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017f2:	6b85                	lui	s7,0x1
    800017f4:	a015                	j	80001818 <copyout+0x5c>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017f6:	41390933          	sub	s2,s2,s3
    800017fa:	0004861b          	sext.w	a2,s1
    800017fe:	85d6                	mv	a1,s5
    80001800:	954a                	add	a0,a0,s2
    80001802:	fffff097          	auipc	ra,0xfffff
    80001806:	688080e7          	jalr	1672(ra) # 80000e8a <memmove>

    len -= n;
    8000180a:	409a0a33          	sub	s4,s4,s1
    src += n;
    8000180e:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    80001810:	01798933          	add	s2,s3,s7
  while(len > 0){
    80001814:	020a0a63          	beqz	s4,80001848 <copyout+0x8c>
    va0 = PGROUNDDOWN(dstva);
    80001818:	018979b3          	and	s3,s2,s8
    if(cow_handle(pagetable,va0) < 0){
    8000181c:	85ce                	mv	a1,s3
    8000181e:	855a                	mv	a0,s6
    80001820:	00001097          	auipc	ra,0x1
    80001824:	1b6080e7          	jalr	438(ra) # 800029d6 <cow_handle>
    80001828:	02054463          	bltz	a0,80001850 <copyout+0x94>
    pa0 = walkaddr(pagetable, va0);
    8000182c:	85ce                	mv	a1,s3
    8000182e:	855a                	mv	a0,s6
    80001830:	00000097          	auipc	ra,0x0
    80001834:	988080e7          	jalr	-1656(ra) # 800011b8 <walkaddr>
    if(pa0 == 0)
    80001838:	c90d                	beqz	a0,8000186a <copyout+0xae>
    n = PGSIZE - (dstva - va0);
    8000183a:	412984b3          	sub	s1,s3,s2
    8000183e:	94de                	add	s1,s1,s7
    if(n > len)
    80001840:	fa9a7be3          	bgeu	s4,s1,800017f6 <copyout+0x3a>
    80001844:	84d2                	mv	s1,s4
    80001846:	bf45                	j	800017f6 <copyout+0x3a>
  }
  return 0;
    80001848:	4501                	li	a0,0
    8000184a:	a021                	j	80001852 <copyout+0x96>
    8000184c:	4501                	li	a0,0
    8000184e:	a011                	j	80001852 <copyout+0x96>
      return -1;
    80001850:	557d                	li	a0,-1
}
    80001852:	60a6                	ld	ra,72(sp)
    80001854:	6406                	ld	s0,64(sp)
    80001856:	74e2                	ld	s1,56(sp)
    80001858:	7942                	ld	s2,48(sp)
    8000185a:	79a2                	ld	s3,40(sp)
    8000185c:	7a02                	ld	s4,32(sp)
    8000185e:	6ae2                	ld	s5,24(sp)
    80001860:	6b42                	ld	s6,16(sp)
    80001862:	6ba2                	ld	s7,8(sp)
    80001864:	6c02                	ld	s8,0(sp)
    80001866:	6161                	addi	sp,sp,80
    80001868:	8082                	ret
      return -1;
    8000186a:	557d                	li	a0,-1
    8000186c:	b7dd                	j	80001852 <copyout+0x96>

000000008000186e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000186e:	c6bd                	beqz	a3,800018dc <copyin+0x6e>
{
    80001870:	715d                	addi	sp,sp,-80
    80001872:	e486                	sd	ra,72(sp)
    80001874:	e0a2                	sd	s0,64(sp)
    80001876:	fc26                	sd	s1,56(sp)
    80001878:	f84a                	sd	s2,48(sp)
    8000187a:	f44e                	sd	s3,40(sp)
    8000187c:	f052                	sd	s4,32(sp)
    8000187e:	ec56                	sd	s5,24(sp)
    80001880:	e85a                	sd	s6,16(sp)
    80001882:	e45e                	sd	s7,8(sp)
    80001884:	e062                	sd	s8,0(sp)
    80001886:	0880                	addi	s0,sp,80
    80001888:	8b2a                	mv	s6,a0
    8000188a:	8a2e                	mv	s4,a1
    8000188c:	8c32                	mv	s8,a2
    8000188e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001890:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001892:	6a85                	lui	s5,0x1
    80001894:	a015                	j	800018b8 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001896:	9562                	add	a0,a0,s8
    80001898:	0004861b          	sext.w	a2,s1
    8000189c:	412505b3          	sub	a1,a0,s2
    800018a0:	8552                	mv	a0,s4
    800018a2:	fffff097          	auipc	ra,0xfffff
    800018a6:	5e8080e7          	jalr	1512(ra) # 80000e8a <memmove>

    len -= n;
    800018aa:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018ae:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018b0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018b4:	02098263          	beqz	s3,800018d8 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800018b8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018bc:	85ca                	mv	a1,s2
    800018be:	855a                	mv	a0,s6
    800018c0:	00000097          	auipc	ra,0x0
    800018c4:	8f8080e7          	jalr	-1800(ra) # 800011b8 <walkaddr>
    if(pa0 == 0)
    800018c8:	cd01                	beqz	a0,800018e0 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800018ca:	418904b3          	sub	s1,s2,s8
    800018ce:	94d6                	add	s1,s1,s5
    if(n > len)
    800018d0:	fc99f3e3          	bgeu	s3,s1,80001896 <copyin+0x28>
    800018d4:	84ce                	mv	s1,s3
    800018d6:	b7c1                	j	80001896 <copyin+0x28>
  }
  return 0;
    800018d8:	4501                	li	a0,0
    800018da:	a021                	j	800018e2 <copyin+0x74>
    800018dc:	4501                	li	a0,0
}
    800018de:	8082                	ret
      return -1;
    800018e0:	557d                	li	a0,-1
}
    800018e2:	60a6                	ld	ra,72(sp)
    800018e4:	6406                	ld	s0,64(sp)
    800018e6:	74e2                	ld	s1,56(sp)
    800018e8:	7942                	ld	s2,48(sp)
    800018ea:	79a2                	ld	s3,40(sp)
    800018ec:	7a02                	ld	s4,32(sp)
    800018ee:	6ae2                	ld	s5,24(sp)
    800018f0:	6b42                	ld	s6,16(sp)
    800018f2:	6ba2                	ld	s7,8(sp)
    800018f4:	6c02                	ld	s8,0(sp)
    800018f6:	6161                	addi	sp,sp,80
    800018f8:	8082                	ret

00000000800018fa <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018fa:	c6c5                	beqz	a3,800019a2 <copyinstr+0xa8>
{
    800018fc:	715d                	addi	sp,sp,-80
    800018fe:	e486                	sd	ra,72(sp)
    80001900:	e0a2                	sd	s0,64(sp)
    80001902:	fc26                	sd	s1,56(sp)
    80001904:	f84a                	sd	s2,48(sp)
    80001906:	f44e                	sd	s3,40(sp)
    80001908:	f052                	sd	s4,32(sp)
    8000190a:	ec56                	sd	s5,24(sp)
    8000190c:	e85a                	sd	s6,16(sp)
    8000190e:	e45e                	sd	s7,8(sp)
    80001910:	0880                	addi	s0,sp,80
    80001912:	8a2a                	mv	s4,a0
    80001914:	8b2e                	mv	s6,a1
    80001916:	8bb2                	mv	s7,a2
    80001918:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000191a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000191c:	6985                	lui	s3,0x1
    8000191e:	a035                	j	8000194a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001920:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001924:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001926:	0017b793          	seqz	a5,a5
    8000192a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000192e:	60a6                	ld	ra,72(sp)
    80001930:	6406                	ld	s0,64(sp)
    80001932:	74e2                	ld	s1,56(sp)
    80001934:	7942                	ld	s2,48(sp)
    80001936:	79a2                	ld	s3,40(sp)
    80001938:	7a02                	ld	s4,32(sp)
    8000193a:	6ae2                	ld	s5,24(sp)
    8000193c:	6b42                	ld	s6,16(sp)
    8000193e:	6ba2                	ld	s7,8(sp)
    80001940:	6161                	addi	sp,sp,80
    80001942:	8082                	ret
    srcva = va0 + PGSIZE;
    80001944:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001948:	c8a9                	beqz	s1,8000199a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000194a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000194e:	85ca                	mv	a1,s2
    80001950:	8552                	mv	a0,s4
    80001952:	00000097          	auipc	ra,0x0
    80001956:	866080e7          	jalr	-1946(ra) # 800011b8 <walkaddr>
    if(pa0 == 0)
    8000195a:	c131                	beqz	a0,8000199e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000195c:	41790833          	sub	a6,s2,s7
    80001960:	984e                	add	a6,a6,s3
    if(n > max)
    80001962:	0104f363          	bgeu	s1,a6,80001968 <copyinstr+0x6e>
    80001966:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001968:	955e                	add	a0,a0,s7
    8000196a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000196e:	fc080be3          	beqz	a6,80001944 <copyinstr+0x4a>
    80001972:	985a                	add	a6,a6,s6
    80001974:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001976:	41650633          	sub	a2,a0,s6
    8000197a:	14fd                	addi	s1,s1,-1
    8000197c:	9b26                	add	s6,s6,s1
    8000197e:	00f60733          	add	a4,a2,a5
    80001982:	00074703          	lbu	a4,0(a4)
    80001986:	df49                	beqz	a4,80001920 <copyinstr+0x26>
        *dst = *p;
    80001988:	00e78023          	sb	a4,0(a5)
      --max;
    8000198c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001990:	0785                	addi	a5,a5,1
    while(n > 0){
    80001992:	ff0796e3          	bne	a5,a6,8000197e <copyinstr+0x84>
      dst++;
    80001996:	8b42                	mv	s6,a6
    80001998:	b775                	j	80001944 <copyinstr+0x4a>
    8000199a:	4781                	li	a5,0
    8000199c:	b769                	j	80001926 <copyinstr+0x2c>
      return -1;
    8000199e:	557d                	li	a0,-1
    800019a0:	b779                	j	8000192e <copyinstr+0x34>
  int got_null = 0;
    800019a2:	4781                	li	a5,0
  if(got_null){
    800019a4:	0017b793          	seqz	a5,a5
    800019a8:	40f00533          	neg	a0,a5
}
    800019ac:	8082                	ret

00000000800019ae <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800019ae:	7139                	addi	sp,sp,-64
    800019b0:	fc06                	sd	ra,56(sp)
    800019b2:	f822                	sd	s0,48(sp)
    800019b4:	f426                	sd	s1,40(sp)
    800019b6:	f04a                	sd	s2,32(sp)
    800019b8:	ec4e                	sd	s3,24(sp)
    800019ba:	e852                	sd	s4,16(sp)
    800019bc:	e456                	sd	s5,8(sp)
    800019be:	e05a                	sd	s6,0(sp)
    800019c0:	0080                	addi	s0,sp,64
    800019c2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c4:	00050497          	auipc	s1,0x50
    800019c8:	d0c48493          	addi	s1,s1,-756 # 800516d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019cc:	8b26                	mv	s6,s1
    800019ce:	00006a97          	auipc	s5,0x6
    800019d2:	632a8a93          	addi	s5,s5,1586 # 80008000 <etext>
    800019d6:	04000937          	lui	s2,0x4000
    800019da:	197d                	addi	s2,s2,-1
    800019dc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019de:	00055a17          	auipc	s4,0x55
    800019e2:	6f2a0a13          	addi	s4,s4,1778 # 800570d0 <tickslock>
    char *pa = kalloc();
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	23c080e7          	jalr	572(ra) # 80000c22 <kalloc>
    800019ee:	862a                	mv	a2,a0
    if(pa == 0)
    800019f0:	c131                	beqz	a0,80001a34 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019f2:	416485b3          	sub	a1,s1,s6
    800019f6:	858d                	srai	a1,a1,0x3
    800019f8:	000ab783          	ld	a5,0(s5)
    800019fc:	02f585b3          	mul	a1,a1,a5
    80001a00:	2585                	addiw	a1,a1,1
    80001a02:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a06:	4719                	li	a4,6
    80001a08:	6685                	lui	a3,0x1
    80001a0a:	40b905b3          	sub	a1,s2,a1
    80001a0e:	854e                	mv	a0,s3
    80001a10:	00000097          	auipc	ra,0x0
    80001a14:	88a080e7          	jalr	-1910(ra) # 8000129a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a18:	16848493          	addi	s1,s1,360
    80001a1c:	fd4495e3          	bne	s1,s4,800019e6 <proc_mapstacks+0x38>
  }
}
    80001a20:	70e2                	ld	ra,56(sp)
    80001a22:	7442                	ld	s0,48(sp)
    80001a24:	74a2                	ld	s1,40(sp)
    80001a26:	7902                	ld	s2,32(sp)
    80001a28:	69e2                	ld	s3,24(sp)
    80001a2a:	6a42                	ld	s4,16(sp)
    80001a2c:	6aa2                	ld	s5,8(sp)
    80001a2e:	6b02                	ld	s6,0(sp)
    80001a30:	6121                	addi	sp,sp,64
    80001a32:	8082                	ret
      panic("kalloc");
    80001a34:	00006517          	auipc	a0,0x6
    80001a38:	7ec50513          	addi	a0,a0,2028 # 80008220 <digits+0x1e0>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	b02080e7          	jalr	-1278(ra) # 8000053e <panic>

0000000080001a44 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001a44:	7139                	addi	sp,sp,-64
    80001a46:	fc06                	sd	ra,56(sp)
    80001a48:	f822                	sd	s0,48(sp)
    80001a4a:	f426                	sd	s1,40(sp)
    80001a4c:	f04a                	sd	s2,32(sp)
    80001a4e:	ec4e                	sd	s3,24(sp)
    80001a50:	e852                	sd	s4,16(sp)
    80001a52:	e456                	sd	s5,8(sp)
    80001a54:	e05a                	sd	s6,0(sp)
    80001a56:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a58:	00006597          	auipc	a1,0x6
    80001a5c:	7d058593          	addi	a1,a1,2000 # 80008228 <digits+0x1e8>
    80001a60:	00050517          	auipc	a0,0x50
    80001a64:	84050513          	addi	a0,a0,-1984 # 800512a0 <pid_lock>
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	236080e7          	jalr	566(ra) # 80000c9e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a70:	00006597          	auipc	a1,0x6
    80001a74:	7c058593          	addi	a1,a1,1984 # 80008230 <digits+0x1f0>
    80001a78:	00050517          	auipc	a0,0x50
    80001a7c:	84050513          	addi	a0,a0,-1984 # 800512b8 <wait_lock>
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	21e080e7          	jalr	542(ra) # 80000c9e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a88:	00050497          	auipc	s1,0x50
    80001a8c:	c4848493          	addi	s1,s1,-952 # 800516d0 <proc>
      initlock(&p->lock, "proc");
    80001a90:	00006b17          	auipc	s6,0x6
    80001a94:	7b0b0b13          	addi	s6,s6,1968 # 80008240 <digits+0x200>
      p->kstack = KSTACK((int) (p - proc));
    80001a98:	8aa6                	mv	s5,s1
    80001a9a:	00006a17          	auipc	s4,0x6
    80001a9e:	566a0a13          	addi	s4,s4,1382 # 80008000 <etext>
    80001aa2:	04000937          	lui	s2,0x4000
    80001aa6:	197d                	addi	s2,s2,-1
    80001aa8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aaa:	00055997          	auipc	s3,0x55
    80001aae:	62698993          	addi	s3,s3,1574 # 800570d0 <tickslock>
      initlock(&p->lock, "proc");
    80001ab2:	85da                	mv	a1,s6
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	1e8080e7          	jalr	488(ra) # 80000c9e <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001abe:	415487b3          	sub	a5,s1,s5
    80001ac2:	878d                	srai	a5,a5,0x3
    80001ac4:	000a3703          	ld	a4,0(s4)
    80001ac8:	02e787b3          	mul	a5,a5,a4
    80001acc:	2785                	addiw	a5,a5,1
    80001ace:	00d7979b          	slliw	a5,a5,0xd
    80001ad2:	40f907b3          	sub	a5,s2,a5
    80001ad6:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad8:	16848493          	addi	s1,s1,360
    80001adc:	fd349be3          	bne	s1,s3,80001ab2 <procinit+0x6e>
  }
}
    80001ae0:	70e2                	ld	ra,56(sp)
    80001ae2:	7442                	ld	s0,48(sp)
    80001ae4:	74a2                	ld	s1,40(sp)
    80001ae6:	7902                	ld	s2,32(sp)
    80001ae8:	69e2                	ld	s3,24(sp)
    80001aea:	6a42                	ld	s4,16(sp)
    80001aec:	6aa2                	ld	s5,8(sp)
    80001aee:	6b02                	ld	s6,0(sp)
    80001af0:	6121                	addi	sp,sp,64
    80001af2:	8082                	ret

0000000080001af4 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001af4:	1141                	addi	sp,sp,-16
    80001af6:	e422                	sd	s0,8(sp)
    80001af8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001afa:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001afc:	2501                	sext.w	a0,a0
    80001afe:	6422                	ld	s0,8(sp)
    80001b00:	0141                	addi	sp,sp,16
    80001b02:	8082                	ret

0000000080001b04 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001b04:	1141                	addi	sp,sp,-16
    80001b06:	e422                	sd	s0,8(sp)
    80001b08:	0800                	addi	s0,sp,16
    80001b0a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b0c:	2781                	sext.w	a5,a5
    80001b0e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b10:	0004f517          	auipc	a0,0x4f
    80001b14:	7c050513          	addi	a0,a0,1984 # 800512d0 <cpus>
    80001b18:	953e                	add	a0,a0,a5
    80001b1a:	6422                	ld	s0,8(sp)
    80001b1c:	0141                	addi	sp,sp,16
    80001b1e:	8082                	ret

0000000080001b20 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001b20:	1101                	addi	sp,sp,-32
    80001b22:	ec06                	sd	ra,24(sp)
    80001b24:	e822                	sd	s0,16(sp)
    80001b26:	e426                	sd	s1,8(sp)
    80001b28:	1000                	addi	s0,sp,32
  push_off();
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	1b8080e7          	jalr	440(ra) # 80000ce2 <push_off>
    80001b32:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b34:	2781                	sext.w	a5,a5
    80001b36:	079e                	slli	a5,a5,0x7
    80001b38:	0004f717          	auipc	a4,0x4f
    80001b3c:	76870713          	addi	a4,a4,1896 # 800512a0 <pid_lock>
    80001b40:	97ba                	add	a5,a5,a4
    80001b42:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	23e080e7          	jalr	574(ra) # 80000d82 <pop_off>
  return p;
}
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	60e2                	ld	ra,24(sp)
    80001b50:	6442                	ld	s0,16(sp)
    80001b52:	64a2                	ld	s1,8(sp)
    80001b54:	6105                	addi	sp,sp,32
    80001b56:	8082                	ret

0000000080001b58 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b58:	1141                	addi	sp,sp,-16
    80001b5a:	e406                	sd	ra,8(sp)
    80001b5c:	e022                	sd	s0,0(sp)
    80001b5e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b60:	00000097          	auipc	ra,0x0
    80001b64:	fc0080e7          	jalr	-64(ra) # 80001b20 <myproc>
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	27a080e7          	jalr	634(ra) # 80000de2 <release>

  if (first) {
    80001b70:	00007797          	auipc	a5,0x7
    80001b74:	d007a783          	lw	a5,-768(a5) # 80008870 <first.1683>
    80001b78:	eb89                	bnez	a5,80001b8a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b7a:	00001097          	auipc	ra,0x1
    80001b7e:	c0a080e7          	jalr	-1014(ra) # 80002784 <usertrapret>
}
    80001b82:	60a2                	ld	ra,8(sp)
    80001b84:	6402                	ld	s0,0(sp)
    80001b86:	0141                	addi	sp,sp,16
    80001b88:	8082                	ret
    first = 0;
    80001b8a:	00007797          	auipc	a5,0x7
    80001b8e:	ce07a323          	sw	zero,-794(a5) # 80008870 <first.1683>
    fsinit(ROOTDEV);
    80001b92:	4505                	li	a0,1
    80001b94:	00002097          	auipc	ra,0x2
    80001b98:	a04080e7          	jalr	-1532(ra) # 80003598 <fsinit>
    80001b9c:	bff9                	j	80001b7a <forkret+0x22>

0000000080001b9e <allocpid>:
allocpid() {
    80001b9e:	1101                	addi	sp,sp,-32
    80001ba0:	ec06                	sd	ra,24(sp)
    80001ba2:	e822                	sd	s0,16(sp)
    80001ba4:	e426                	sd	s1,8(sp)
    80001ba6:	e04a                	sd	s2,0(sp)
    80001ba8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001baa:	0004f917          	auipc	s2,0x4f
    80001bae:	6f690913          	addi	s2,s2,1782 # 800512a0 <pid_lock>
    80001bb2:	854a                	mv	a0,s2
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	17a080e7          	jalr	378(ra) # 80000d2e <acquire>
  pid = nextpid;
    80001bbc:	00007797          	auipc	a5,0x7
    80001bc0:	cb878793          	addi	a5,a5,-840 # 80008874 <nextpid>
    80001bc4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bc6:	0014871b          	addiw	a4,s1,1
    80001bca:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bcc:	854a                	mv	a0,s2
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	214080e7          	jalr	532(ra) # 80000de2 <release>
}
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	60e2                	ld	ra,24(sp)
    80001bda:	6442                	ld	s0,16(sp)
    80001bdc:	64a2                	ld	s1,8(sp)
    80001bde:	6902                	ld	s2,0(sp)
    80001be0:	6105                	addi	sp,sp,32
    80001be2:	8082                	ret

0000000080001be4 <proc_pagetable>:
{
    80001be4:	1101                	addi	sp,sp,-32
    80001be6:	ec06                	sd	ra,24(sp)
    80001be8:	e822                	sd	s0,16(sp)
    80001bea:	e426                	sd	s1,8(sp)
    80001bec:	e04a                	sd	s2,0(sp)
    80001bee:	1000                	addi	s0,sp,32
    80001bf0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bf2:	00000097          	auipc	ra,0x0
    80001bf6:	892080e7          	jalr	-1902(ra) # 80001484 <uvmcreate>
    80001bfa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bfc:	c121                	beqz	a0,80001c3c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bfe:	4729                	li	a4,10
    80001c00:	00005697          	auipc	a3,0x5
    80001c04:	40068693          	addi	a3,a3,1024 # 80007000 <_trampoline>
    80001c08:	6605                	lui	a2,0x1
    80001c0a:	040005b7          	lui	a1,0x4000
    80001c0e:	15fd                	addi	a1,a1,-1
    80001c10:	05b2                	slli	a1,a1,0xc
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	5e8080e7          	jalr	1512(ra) # 800011fa <mappages>
    80001c1a:	02054863          	bltz	a0,80001c4a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c1e:	4719                	li	a4,6
    80001c20:	05893683          	ld	a3,88(s2)
    80001c24:	6605                	lui	a2,0x1
    80001c26:	020005b7          	lui	a1,0x2000
    80001c2a:	15fd                	addi	a1,a1,-1
    80001c2c:	05b6                	slli	a1,a1,0xd
    80001c2e:	8526                	mv	a0,s1
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	5ca080e7          	jalr	1482(ra) # 800011fa <mappages>
    80001c38:	02054163          	bltz	a0,80001c5a <proc_pagetable+0x76>
}
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	60e2                	ld	ra,24(sp)
    80001c40:	6442                	ld	s0,16(sp)
    80001c42:	64a2                	ld	s1,8(sp)
    80001c44:	6902                	ld	s2,0(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret
    uvmfree(pagetable, 0);
    80001c4a:	4581                	li	a1,0
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	a32080e7          	jalr	-1486(ra) # 80001680 <uvmfree>
    return 0;
    80001c56:	4481                	li	s1,0
    80001c58:	b7d5                	j	80001c3c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c5a:	4681                	li	a3,0
    80001c5c:	4605                	li	a2,1
    80001c5e:	040005b7          	lui	a1,0x4000
    80001c62:	15fd                	addi	a1,a1,-1
    80001c64:	05b2                	slli	a1,a1,0xc
    80001c66:	8526                	mv	a0,s1
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	758080e7          	jalr	1880(ra) # 800013c0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c70:	4581                	li	a1,0
    80001c72:	8526                	mv	a0,s1
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	a0c080e7          	jalr	-1524(ra) # 80001680 <uvmfree>
    return 0;
    80001c7c:	4481                	li	s1,0
    80001c7e:	bf7d                	j	80001c3c <proc_pagetable+0x58>

0000000080001c80 <proc_freepagetable>:
{
    80001c80:	1101                	addi	sp,sp,-32
    80001c82:	ec06                	sd	ra,24(sp)
    80001c84:	e822                	sd	s0,16(sp)
    80001c86:	e426                	sd	s1,8(sp)
    80001c88:	e04a                	sd	s2,0(sp)
    80001c8a:	1000                	addi	s0,sp,32
    80001c8c:	84aa                	mv	s1,a0
    80001c8e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c90:	4681                	li	a3,0
    80001c92:	4605                	li	a2,1
    80001c94:	040005b7          	lui	a1,0x4000
    80001c98:	15fd                	addi	a1,a1,-1
    80001c9a:	05b2                	slli	a1,a1,0xc
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	724080e7          	jalr	1828(ra) # 800013c0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ca4:	4681                	li	a3,0
    80001ca6:	4605                	li	a2,1
    80001ca8:	020005b7          	lui	a1,0x2000
    80001cac:	15fd                	addi	a1,a1,-1
    80001cae:	05b6                	slli	a1,a1,0xd
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	70e080e7          	jalr	1806(ra) # 800013c0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cba:	85ca                	mv	a1,s2
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	9c2080e7          	jalr	-1598(ra) # 80001680 <uvmfree>
}
    80001cc6:	60e2                	ld	ra,24(sp)
    80001cc8:	6442                	ld	s0,16(sp)
    80001cca:	64a2                	ld	s1,8(sp)
    80001ccc:	6902                	ld	s2,0(sp)
    80001cce:	6105                	addi	sp,sp,32
    80001cd0:	8082                	ret

0000000080001cd2 <freeproc>:
{
    80001cd2:	1101                	addi	sp,sp,-32
    80001cd4:	ec06                	sd	ra,24(sp)
    80001cd6:	e822                	sd	s0,16(sp)
    80001cd8:	e426                	sd	s1,8(sp)
    80001cda:	1000                	addi	s0,sp,32
    80001cdc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cde:	6d28                	ld	a0,88(a0)
    80001ce0:	c509                	beqz	a0,80001cea <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	e04080e7          	jalr	-508(ra) # 80000ae6 <kfree>
  p->trapframe = 0;
    80001cea:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cee:	68a8                	ld	a0,80(s1)
    80001cf0:	c511                	beqz	a0,80001cfc <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cf2:	64ac                	ld	a1,72(s1)
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	f8c080e7          	jalr	-116(ra) # 80001c80 <proc_freepagetable>
  p->pagetable = 0;
    80001cfc:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d00:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d04:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d08:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d0c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d10:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d14:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d18:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d1c:	0004ac23          	sw	zero,24(s1)
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6105                	addi	sp,sp,32
    80001d28:	8082                	ret

0000000080001d2a <allocproc>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	e04a                	sd	s2,0(sp)
    80001d34:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d36:	00050497          	auipc	s1,0x50
    80001d3a:	99a48493          	addi	s1,s1,-1638 # 800516d0 <proc>
    80001d3e:	00055917          	auipc	s2,0x55
    80001d42:	39290913          	addi	s2,s2,914 # 800570d0 <tickslock>
    acquire(&p->lock);
    80001d46:	8526                	mv	a0,s1
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	fe6080e7          	jalr	-26(ra) # 80000d2e <acquire>
    if(p->state == UNUSED) {
    80001d50:	4c9c                	lw	a5,24(s1)
    80001d52:	cf81                	beqz	a5,80001d6a <allocproc+0x40>
      release(&p->lock);
    80001d54:	8526                	mv	a0,s1
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	08c080e7          	jalr	140(ra) # 80000de2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d5e:	16848493          	addi	s1,s1,360
    80001d62:	ff2492e3          	bne	s1,s2,80001d46 <allocproc+0x1c>
  return 0;
    80001d66:	4481                	li	s1,0
    80001d68:	a889                	j	80001dba <allocproc+0x90>
  p->pid = allocpid();
    80001d6a:	00000097          	auipc	ra,0x0
    80001d6e:	e34080e7          	jalr	-460(ra) # 80001b9e <allocpid>
    80001d72:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d74:	4785                	li	a5,1
    80001d76:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	eaa080e7          	jalr	-342(ra) # 80000c22 <kalloc>
    80001d80:	892a                	mv	s2,a0
    80001d82:	eca8                	sd	a0,88(s1)
    80001d84:	c131                	beqz	a0,80001dc8 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d86:	8526                	mv	a0,s1
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	e5c080e7          	jalr	-420(ra) # 80001be4 <proc_pagetable>
    80001d90:	892a                	mv	s2,a0
    80001d92:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d94:	c531                	beqz	a0,80001de0 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d96:	07000613          	li	a2,112
    80001d9a:	4581                	li	a1,0
    80001d9c:	06048513          	addi	a0,s1,96
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	08a080e7          	jalr	138(ra) # 80000e2a <memset>
  p->context.ra = (uint64)forkret;
    80001da8:	00000797          	auipc	a5,0x0
    80001dac:	db078793          	addi	a5,a5,-592 # 80001b58 <forkret>
    80001db0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001db2:	60bc                	ld	a5,64(s1)
    80001db4:	6705                	lui	a4,0x1
    80001db6:	97ba                	add	a5,a5,a4
    80001db8:	f4bc                	sd	a5,104(s1)
}
    80001dba:	8526                	mv	a0,s1
    80001dbc:	60e2                	ld	ra,24(sp)
    80001dbe:	6442                	ld	s0,16(sp)
    80001dc0:	64a2                	ld	s1,8(sp)
    80001dc2:	6902                	ld	s2,0(sp)
    80001dc4:	6105                	addi	sp,sp,32
    80001dc6:	8082                	ret
    freeproc(p);
    80001dc8:	8526                	mv	a0,s1
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	f08080e7          	jalr	-248(ra) # 80001cd2 <freeproc>
    release(&p->lock);
    80001dd2:	8526                	mv	a0,s1
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	00e080e7          	jalr	14(ra) # 80000de2 <release>
    return 0;
    80001ddc:	84ca                	mv	s1,s2
    80001dde:	bff1                	j	80001dba <allocproc+0x90>
    freeproc(p);
    80001de0:	8526                	mv	a0,s1
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	ef0080e7          	jalr	-272(ra) # 80001cd2 <freeproc>
    release(&p->lock);
    80001dea:	8526                	mv	a0,s1
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	ff6080e7          	jalr	-10(ra) # 80000de2 <release>
    return 0;
    80001df4:	84ca                	mv	s1,s2
    80001df6:	b7d1                	j	80001dba <allocproc+0x90>

0000000080001df8 <userinit>:
{
    80001df8:	1101                	addi	sp,sp,-32
    80001dfa:	ec06                	sd	ra,24(sp)
    80001dfc:	e822                	sd	s0,16(sp)
    80001dfe:	e426                	sd	s1,8(sp)
    80001e00:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e02:	00000097          	auipc	ra,0x0
    80001e06:	f28080e7          	jalr	-216(ra) # 80001d2a <allocproc>
    80001e0a:	84aa                	mv	s1,a0
  initproc = p;
    80001e0c:	00007797          	auipc	a5,0x7
    80001e10:	20a7be23          	sd	a0,540(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e14:	03400613          	li	a2,52
    80001e18:	00007597          	auipc	a1,0x7
    80001e1c:	a6858593          	addi	a1,a1,-1432 # 80008880 <initcode>
    80001e20:	6928                	ld	a0,80(a0)
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	690080e7          	jalr	1680(ra) # 800014b2 <uvminit>
  p->sz = PGSIZE;
    80001e2a:	6785                	lui	a5,0x1
    80001e2c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e2e:	6cb8                	ld	a4,88(s1)
    80001e30:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e34:	6cb8                	ld	a4,88(s1)
    80001e36:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e38:	4641                	li	a2,16
    80001e3a:	00006597          	auipc	a1,0x6
    80001e3e:	40e58593          	addi	a1,a1,1038 # 80008248 <digits+0x208>
    80001e42:	15848513          	addi	a0,s1,344
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	136080e7          	jalr	310(ra) # 80000f7c <safestrcpy>
  p->cwd = namei("/");
    80001e4e:	00006517          	auipc	a0,0x6
    80001e52:	40a50513          	addi	a0,a0,1034 # 80008258 <digits+0x218>
    80001e56:	00002097          	auipc	ra,0x2
    80001e5a:	170080e7          	jalr	368(ra) # 80003fc6 <namei>
    80001e5e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e62:	478d                	li	a5,3
    80001e64:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	f7a080e7          	jalr	-134(ra) # 80000de2 <release>
}
    80001e70:	60e2                	ld	ra,24(sp)
    80001e72:	6442                	ld	s0,16(sp)
    80001e74:	64a2                	ld	s1,8(sp)
    80001e76:	6105                	addi	sp,sp,32
    80001e78:	8082                	ret

0000000080001e7a <growproc>:
{
    80001e7a:	1101                	addi	sp,sp,-32
    80001e7c:	ec06                	sd	ra,24(sp)
    80001e7e:	e822                	sd	s0,16(sp)
    80001e80:	e426                	sd	s1,8(sp)
    80001e82:	e04a                	sd	s2,0(sp)
    80001e84:	1000                	addi	s0,sp,32
    80001e86:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e88:	00000097          	auipc	ra,0x0
    80001e8c:	c98080e7          	jalr	-872(ra) # 80001b20 <myproc>
    80001e90:	892a                	mv	s2,a0
  sz = p->sz;
    80001e92:	652c                	ld	a1,72(a0)
    80001e94:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e98:	00904f63          	bgtz	s1,80001eb6 <growproc+0x3c>
  } else if(n < 0){
    80001e9c:	0204cc63          	bltz	s1,80001ed4 <growproc+0x5a>
  p->sz = sz;
    80001ea0:	1602                	slli	a2,a2,0x20
    80001ea2:	9201                	srli	a2,a2,0x20
    80001ea4:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ea8:	4501                	li	a0,0
}
    80001eaa:	60e2                	ld	ra,24(sp)
    80001eac:	6442                	ld	s0,16(sp)
    80001eae:	64a2                	ld	s1,8(sp)
    80001eb0:	6902                	ld	s2,0(sp)
    80001eb2:	6105                	addi	sp,sp,32
    80001eb4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001eb6:	9e25                	addw	a2,a2,s1
    80001eb8:	1602                	slli	a2,a2,0x20
    80001eba:	9201                	srli	a2,a2,0x20
    80001ebc:	1582                	slli	a1,a1,0x20
    80001ebe:	9181                	srli	a1,a1,0x20
    80001ec0:	6928                	ld	a0,80(a0)
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	6aa080e7          	jalr	1706(ra) # 8000156c <uvmalloc>
    80001eca:	0005061b          	sext.w	a2,a0
    80001ece:	fa69                	bnez	a2,80001ea0 <growproc+0x26>
      return -1;
    80001ed0:	557d                	li	a0,-1
    80001ed2:	bfe1                	j	80001eaa <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ed4:	9e25                	addw	a2,a2,s1
    80001ed6:	1602                	slli	a2,a2,0x20
    80001ed8:	9201                	srli	a2,a2,0x20
    80001eda:	1582                	slli	a1,a1,0x20
    80001edc:	9181                	srli	a1,a1,0x20
    80001ede:	6928                	ld	a0,80(a0)
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	644080e7          	jalr	1604(ra) # 80001524 <uvmdealloc>
    80001ee8:	0005061b          	sext.w	a2,a0
    80001eec:	bf55                	j	80001ea0 <growproc+0x26>

0000000080001eee <fork>:
{
    80001eee:	7179                	addi	sp,sp,-48
    80001ef0:	f406                	sd	ra,40(sp)
    80001ef2:	f022                	sd	s0,32(sp)
    80001ef4:	ec26                	sd	s1,24(sp)
    80001ef6:	e84a                	sd	s2,16(sp)
    80001ef8:	e44e                	sd	s3,8(sp)
    80001efa:	e052                	sd	s4,0(sp)
    80001efc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	c22080e7          	jalr	-990(ra) # 80001b20 <myproc>
    80001f06:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	e22080e7          	jalr	-478(ra) # 80001d2a <allocproc>
    80001f10:	10050b63          	beqz	a0,80002026 <fork+0x138>
    80001f14:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f16:	04893603          	ld	a2,72(s2)
    80001f1a:	692c                	ld	a1,80(a0)
    80001f1c:	05093503          	ld	a0,80(s2)
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	798080e7          	jalr	1944(ra) # 800016b8 <uvmcopy>
    80001f28:	04054663          	bltz	a0,80001f74 <fork+0x86>
  np->sz = p->sz;
    80001f2c:	04893783          	ld	a5,72(s2)
    80001f30:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f34:	05893683          	ld	a3,88(s2)
    80001f38:	87b6                	mv	a5,a3
    80001f3a:	0589b703          	ld	a4,88(s3)
    80001f3e:	12068693          	addi	a3,a3,288
    80001f42:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f46:	6788                	ld	a0,8(a5)
    80001f48:	6b8c                	ld	a1,16(a5)
    80001f4a:	6f90                	ld	a2,24(a5)
    80001f4c:	01073023          	sd	a6,0(a4)
    80001f50:	e708                	sd	a0,8(a4)
    80001f52:	eb0c                	sd	a1,16(a4)
    80001f54:	ef10                	sd	a2,24(a4)
    80001f56:	02078793          	addi	a5,a5,32
    80001f5a:	02070713          	addi	a4,a4,32
    80001f5e:	fed792e3          	bne	a5,a3,80001f42 <fork+0x54>
  np->trapframe->a0 = 0;
    80001f62:	0589b783          	ld	a5,88(s3)
    80001f66:	0607b823          	sd	zero,112(a5)
    80001f6a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f6e:	15000a13          	li	s4,336
    80001f72:	a03d                	j	80001fa0 <fork+0xb2>
    freeproc(np);
    80001f74:	854e                	mv	a0,s3
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	d5c080e7          	jalr	-676(ra) # 80001cd2 <freeproc>
    release(&np->lock);
    80001f7e:	854e                	mv	a0,s3
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	e62080e7          	jalr	-414(ra) # 80000de2 <release>
    return -1;
    80001f88:	5a7d                	li	s4,-1
    80001f8a:	a069                	j	80002014 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f8c:	00002097          	auipc	ra,0x2
    80001f90:	6d0080e7          	jalr	1744(ra) # 8000465c <filedup>
    80001f94:	009987b3          	add	a5,s3,s1
    80001f98:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f9a:	04a1                	addi	s1,s1,8
    80001f9c:	01448763          	beq	s1,s4,80001faa <fork+0xbc>
    if(p->ofile[i])
    80001fa0:	009907b3          	add	a5,s2,s1
    80001fa4:	6388                	ld	a0,0(a5)
    80001fa6:	f17d                	bnez	a0,80001f8c <fork+0x9e>
    80001fa8:	bfcd                	j	80001f9a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001faa:	15093503          	ld	a0,336(s2)
    80001fae:	00002097          	auipc	ra,0x2
    80001fb2:	824080e7          	jalr	-2012(ra) # 800037d2 <idup>
    80001fb6:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fba:	4641                	li	a2,16
    80001fbc:	15890593          	addi	a1,s2,344
    80001fc0:	15898513          	addi	a0,s3,344
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	fb8080e7          	jalr	-72(ra) # 80000f7c <safestrcpy>
  pid = np->pid;
    80001fcc:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001fd0:	854e                	mv	a0,s3
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	e10080e7          	jalr	-496(ra) # 80000de2 <release>
  acquire(&wait_lock);
    80001fda:	0004f497          	auipc	s1,0x4f
    80001fde:	2de48493          	addi	s1,s1,734 # 800512b8 <wait_lock>
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	d4a080e7          	jalr	-694(ra) # 80000d2e <acquire>
  np->parent = p;
    80001fec:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ff0:	8526                	mv	a0,s1
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	df0080e7          	jalr	-528(ra) # 80000de2 <release>
  acquire(&np->lock);
    80001ffa:	854e                	mv	a0,s3
    80001ffc:	fffff097          	auipc	ra,0xfffff
    80002000:	d32080e7          	jalr	-718(ra) # 80000d2e <acquire>
  np->state = RUNNABLE;
    80002004:	478d                	li	a5,3
    80002006:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000200a:	854e                	mv	a0,s3
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	dd6080e7          	jalr	-554(ra) # 80000de2 <release>
}
    80002014:	8552                	mv	a0,s4
    80002016:	70a2                	ld	ra,40(sp)
    80002018:	7402                	ld	s0,32(sp)
    8000201a:	64e2                	ld	s1,24(sp)
    8000201c:	6942                	ld	s2,16(sp)
    8000201e:	69a2                	ld	s3,8(sp)
    80002020:	6a02                	ld	s4,0(sp)
    80002022:	6145                	addi	sp,sp,48
    80002024:	8082                	ret
    return -1;
    80002026:	5a7d                	li	s4,-1
    80002028:	b7f5                	j	80002014 <fork+0x126>

000000008000202a <scheduler>:
{
    8000202a:	7139                	addi	sp,sp,-64
    8000202c:	fc06                	sd	ra,56(sp)
    8000202e:	f822                	sd	s0,48(sp)
    80002030:	f426                	sd	s1,40(sp)
    80002032:	f04a                	sd	s2,32(sp)
    80002034:	ec4e                	sd	s3,24(sp)
    80002036:	e852                	sd	s4,16(sp)
    80002038:	e456                	sd	s5,8(sp)
    8000203a:	e05a                	sd	s6,0(sp)
    8000203c:	0080                	addi	s0,sp,64
    8000203e:	8792                	mv	a5,tp
  int id = r_tp();
    80002040:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002042:	00779a93          	slli	s5,a5,0x7
    80002046:	0004f717          	auipc	a4,0x4f
    8000204a:	25a70713          	addi	a4,a4,602 # 800512a0 <pid_lock>
    8000204e:	9756                	add	a4,a4,s5
    80002050:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002054:	0004f717          	auipc	a4,0x4f
    80002058:	28470713          	addi	a4,a4,644 # 800512d8 <cpus+0x8>
    8000205c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000205e:	498d                	li	s3,3
        p->state = RUNNING;
    80002060:	4b11                	li	s6,4
        c->proc = p;
    80002062:	079e                	slli	a5,a5,0x7
    80002064:	0004fa17          	auipc	s4,0x4f
    80002068:	23ca0a13          	addi	s4,s4,572 # 800512a0 <pid_lock>
    8000206c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000206e:	00055917          	auipc	s2,0x55
    80002072:	06290913          	addi	s2,s2,98 # 800570d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002076:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000207a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000207e:	10079073          	csrw	sstatus,a5
    80002082:	0004f497          	auipc	s1,0x4f
    80002086:	64e48493          	addi	s1,s1,1614 # 800516d0 <proc>
    8000208a:	a03d                	j	800020b8 <scheduler+0x8e>
        p->state = RUNNING;
    8000208c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002090:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002094:	06048593          	addi	a1,s1,96
    80002098:	8556                	mv	a0,s5
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	640080e7          	jalr	1600(ra) # 800026da <swtch>
        c->proc = 0;
    800020a2:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    800020a6:	8526                	mv	a0,s1
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	d3a080e7          	jalr	-710(ra) # 80000de2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020b0:	16848493          	addi	s1,s1,360
    800020b4:	fd2481e3          	beq	s1,s2,80002076 <scheduler+0x4c>
      acquire(&p->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	c74080e7          	jalr	-908(ra) # 80000d2e <acquire>
      if(p->state == RUNNABLE) {
    800020c2:	4c9c                	lw	a5,24(s1)
    800020c4:	ff3791e3          	bne	a5,s3,800020a6 <scheduler+0x7c>
    800020c8:	b7d1                	j	8000208c <scheduler+0x62>

00000000800020ca <sched>:
{
    800020ca:	7179                	addi	sp,sp,-48
    800020cc:	f406                	sd	ra,40(sp)
    800020ce:	f022                	sd	s0,32(sp)
    800020d0:	ec26                	sd	s1,24(sp)
    800020d2:	e84a                	sd	s2,16(sp)
    800020d4:	e44e                	sd	s3,8(sp)
    800020d6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	a48080e7          	jalr	-1464(ra) # 80001b20 <myproc>
    800020e0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	bd2080e7          	jalr	-1070(ra) # 80000cb4 <holding>
    800020ea:	c93d                	beqz	a0,80002160 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ec:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020ee:	2781                	sext.w	a5,a5
    800020f0:	079e                	slli	a5,a5,0x7
    800020f2:	0004f717          	auipc	a4,0x4f
    800020f6:	1ae70713          	addi	a4,a4,430 # 800512a0 <pid_lock>
    800020fa:	97ba                	add	a5,a5,a4
    800020fc:	0a87a703          	lw	a4,168(a5)
    80002100:	4785                	li	a5,1
    80002102:	06f71763          	bne	a4,a5,80002170 <sched+0xa6>
  if(p->state == RUNNING)
    80002106:	4c98                	lw	a4,24(s1)
    80002108:	4791                	li	a5,4
    8000210a:	06f70b63          	beq	a4,a5,80002180 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000210e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002112:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002114:	efb5                	bnez	a5,80002190 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002116:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002118:	0004f917          	auipc	s2,0x4f
    8000211c:	18890913          	addi	s2,s2,392 # 800512a0 <pid_lock>
    80002120:	2781                	sext.w	a5,a5
    80002122:	079e                	slli	a5,a5,0x7
    80002124:	97ca                	add	a5,a5,s2
    80002126:	0ac7a983          	lw	s3,172(a5)
    8000212a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000212c:	2781                	sext.w	a5,a5
    8000212e:	079e                	slli	a5,a5,0x7
    80002130:	0004f597          	auipc	a1,0x4f
    80002134:	1a858593          	addi	a1,a1,424 # 800512d8 <cpus+0x8>
    80002138:	95be                	add	a1,a1,a5
    8000213a:	06048513          	addi	a0,s1,96
    8000213e:	00000097          	auipc	ra,0x0
    80002142:	59c080e7          	jalr	1436(ra) # 800026da <swtch>
    80002146:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002148:	2781                	sext.w	a5,a5
    8000214a:	079e                	slli	a5,a5,0x7
    8000214c:	97ca                	add	a5,a5,s2
    8000214e:	0b37a623          	sw	s3,172(a5)
}
    80002152:	70a2                	ld	ra,40(sp)
    80002154:	7402                	ld	s0,32(sp)
    80002156:	64e2                	ld	s1,24(sp)
    80002158:	6942                	ld	s2,16(sp)
    8000215a:	69a2                	ld	s3,8(sp)
    8000215c:	6145                	addi	sp,sp,48
    8000215e:	8082                	ret
    panic("sched p->lock");
    80002160:	00006517          	auipc	a0,0x6
    80002164:	10050513          	addi	a0,a0,256 # 80008260 <digits+0x220>
    80002168:	ffffe097          	auipc	ra,0xffffe
    8000216c:	3d6080e7          	jalr	982(ra) # 8000053e <panic>
    panic("sched locks");
    80002170:	00006517          	auipc	a0,0x6
    80002174:	10050513          	addi	a0,a0,256 # 80008270 <digits+0x230>
    80002178:	ffffe097          	auipc	ra,0xffffe
    8000217c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>
    panic("sched running");
    80002180:	00006517          	auipc	a0,0x6
    80002184:	10050513          	addi	a0,a0,256 # 80008280 <digits+0x240>
    80002188:	ffffe097          	auipc	ra,0xffffe
    8000218c:	3b6080e7          	jalr	950(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002190:	00006517          	auipc	a0,0x6
    80002194:	10050513          	addi	a0,a0,256 # 80008290 <digits+0x250>
    80002198:	ffffe097          	auipc	ra,0xffffe
    8000219c:	3a6080e7          	jalr	934(ra) # 8000053e <panic>

00000000800021a0 <yield>:
{
    800021a0:	1101                	addi	sp,sp,-32
    800021a2:	ec06                	sd	ra,24(sp)
    800021a4:	e822                	sd	s0,16(sp)
    800021a6:	e426                	sd	s1,8(sp)
    800021a8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021aa:	00000097          	auipc	ra,0x0
    800021ae:	976080e7          	jalr	-1674(ra) # 80001b20 <myproc>
    800021b2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	b7a080e7          	jalr	-1158(ra) # 80000d2e <acquire>
  p->state = RUNNABLE;
    800021bc:	478d                	li	a5,3
    800021be:	cc9c                	sw	a5,24(s1)
  sched();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	f0a080e7          	jalr	-246(ra) # 800020ca <sched>
  release(&p->lock);
    800021c8:	8526                	mv	a0,s1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	c18080e7          	jalr	-1000(ra) # 80000de2 <release>
}
    800021d2:	60e2                	ld	ra,24(sp)
    800021d4:	6442                	ld	s0,16(sp)
    800021d6:	64a2                	ld	s1,8(sp)
    800021d8:	6105                	addi	sp,sp,32
    800021da:	8082                	ret

00000000800021dc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800021dc:	7179                	addi	sp,sp,-48
    800021de:	f406                	sd	ra,40(sp)
    800021e0:	f022                	sd	s0,32(sp)
    800021e2:	ec26                	sd	s1,24(sp)
    800021e4:	e84a                	sd	s2,16(sp)
    800021e6:	e44e                	sd	s3,8(sp)
    800021e8:	1800                	addi	s0,sp,48
    800021ea:	89aa                	mv	s3,a0
    800021ec:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021ee:	00000097          	auipc	ra,0x0
    800021f2:	932080e7          	jalr	-1742(ra) # 80001b20 <myproc>
    800021f6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	b36080e7          	jalr	-1226(ra) # 80000d2e <acquire>
  release(lk);
    80002200:	854a                	mv	a0,s2
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	be0080e7          	jalr	-1056(ra) # 80000de2 <release>

  // Go to sleep.
  p->chan = chan;
    8000220a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000220e:	4789                	li	a5,2
    80002210:	cc9c                	sw	a5,24(s1)

  sched();
    80002212:	00000097          	auipc	ra,0x0
    80002216:	eb8080e7          	jalr	-328(ra) # 800020ca <sched>

  // Tidy up.
  p->chan = 0;
    8000221a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000221e:	8526                	mv	a0,s1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	bc2080e7          	jalr	-1086(ra) # 80000de2 <release>
  acquire(lk);
    80002228:	854a                	mv	a0,s2
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	b04080e7          	jalr	-1276(ra) # 80000d2e <acquire>
}
    80002232:	70a2                	ld	ra,40(sp)
    80002234:	7402                	ld	s0,32(sp)
    80002236:	64e2                	ld	s1,24(sp)
    80002238:	6942                	ld	s2,16(sp)
    8000223a:	69a2                	ld	s3,8(sp)
    8000223c:	6145                	addi	sp,sp,48
    8000223e:	8082                	ret

0000000080002240 <wait>:
{
    80002240:	715d                	addi	sp,sp,-80
    80002242:	e486                	sd	ra,72(sp)
    80002244:	e0a2                	sd	s0,64(sp)
    80002246:	fc26                	sd	s1,56(sp)
    80002248:	f84a                	sd	s2,48(sp)
    8000224a:	f44e                	sd	s3,40(sp)
    8000224c:	f052                	sd	s4,32(sp)
    8000224e:	ec56                	sd	s5,24(sp)
    80002250:	e85a                	sd	s6,16(sp)
    80002252:	e45e                	sd	s7,8(sp)
    80002254:	e062                	sd	s8,0(sp)
    80002256:	0880                	addi	s0,sp,80
    80002258:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000225a:	00000097          	auipc	ra,0x0
    8000225e:	8c6080e7          	jalr	-1850(ra) # 80001b20 <myproc>
    80002262:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002264:	0004f517          	auipc	a0,0x4f
    80002268:	05450513          	addi	a0,a0,84 # 800512b8 <wait_lock>
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	ac2080e7          	jalr	-1342(ra) # 80000d2e <acquire>
    havekids = 0;
    80002274:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002276:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002278:	00055997          	auipc	s3,0x55
    8000227c:	e5898993          	addi	s3,s3,-424 # 800570d0 <tickslock>
        havekids = 1;
    80002280:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002282:	0004fc17          	auipc	s8,0x4f
    80002286:	036c0c13          	addi	s8,s8,54 # 800512b8 <wait_lock>
    havekids = 0;
    8000228a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000228c:	0004f497          	auipc	s1,0x4f
    80002290:	44448493          	addi	s1,s1,1092 # 800516d0 <proc>
    80002294:	a0bd                	j	80002302 <wait+0xc2>
          pid = np->pid;
    80002296:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000229a:	000b0e63          	beqz	s6,800022b6 <wait+0x76>
    8000229e:	4691                	li	a3,4
    800022a0:	02c48613          	addi	a2,s1,44
    800022a4:	85da                	mv	a1,s6
    800022a6:	05093503          	ld	a0,80(s2)
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	512080e7          	jalr	1298(ra) # 800017bc <copyout>
    800022b2:	02054563          	bltz	a0,800022dc <wait+0x9c>
          freeproc(np);
    800022b6:	8526                	mv	a0,s1
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	a1a080e7          	jalr	-1510(ra) # 80001cd2 <freeproc>
          release(&np->lock);
    800022c0:	8526                	mv	a0,s1
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	b20080e7          	jalr	-1248(ra) # 80000de2 <release>
          release(&wait_lock);
    800022ca:	0004f517          	auipc	a0,0x4f
    800022ce:	fee50513          	addi	a0,a0,-18 # 800512b8 <wait_lock>
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	b10080e7          	jalr	-1264(ra) # 80000de2 <release>
          return pid;
    800022da:	a09d                	j	80002340 <wait+0x100>
            release(&np->lock);
    800022dc:	8526                	mv	a0,s1
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	b04080e7          	jalr	-1276(ra) # 80000de2 <release>
            release(&wait_lock);
    800022e6:	0004f517          	auipc	a0,0x4f
    800022ea:	fd250513          	addi	a0,a0,-46 # 800512b8 <wait_lock>
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	af4080e7          	jalr	-1292(ra) # 80000de2 <release>
            return -1;
    800022f6:	59fd                	li	s3,-1
    800022f8:	a0a1                	j	80002340 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800022fa:	16848493          	addi	s1,s1,360
    800022fe:	03348463          	beq	s1,s3,80002326 <wait+0xe6>
      if(np->parent == p){
    80002302:	7c9c                	ld	a5,56(s1)
    80002304:	ff279be3          	bne	a5,s2,800022fa <wait+0xba>
        acquire(&np->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	a24080e7          	jalr	-1500(ra) # 80000d2e <acquire>
        if(np->state == ZOMBIE){
    80002312:	4c9c                	lw	a5,24(s1)
    80002314:	f94781e3          	beq	a5,s4,80002296 <wait+0x56>
        release(&np->lock);
    80002318:	8526                	mv	a0,s1
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	ac8080e7          	jalr	-1336(ra) # 80000de2 <release>
        havekids = 1;
    80002322:	8756                	mv	a4,s5
    80002324:	bfd9                	j	800022fa <wait+0xba>
    if(!havekids || p->killed){
    80002326:	c701                	beqz	a4,8000232e <wait+0xee>
    80002328:	02892783          	lw	a5,40(s2)
    8000232c:	c79d                	beqz	a5,8000235a <wait+0x11a>
      release(&wait_lock);
    8000232e:	0004f517          	auipc	a0,0x4f
    80002332:	f8a50513          	addi	a0,a0,-118 # 800512b8 <wait_lock>
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	aac080e7          	jalr	-1364(ra) # 80000de2 <release>
      return -1;
    8000233e:	59fd                	li	s3,-1
}
    80002340:	854e                	mv	a0,s3
    80002342:	60a6                	ld	ra,72(sp)
    80002344:	6406                	ld	s0,64(sp)
    80002346:	74e2                	ld	s1,56(sp)
    80002348:	7942                	ld	s2,48(sp)
    8000234a:	79a2                	ld	s3,40(sp)
    8000234c:	7a02                	ld	s4,32(sp)
    8000234e:	6ae2                	ld	s5,24(sp)
    80002350:	6b42                	ld	s6,16(sp)
    80002352:	6ba2                	ld	s7,8(sp)
    80002354:	6c02                	ld	s8,0(sp)
    80002356:	6161                	addi	sp,sp,80
    80002358:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000235a:	85e2                	mv	a1,s8
    8000235c:	854a                	mv	a0,s2
    8000235e:	00000097          	auipc	ra,0x0
    80002362:	e7e080e7          	jalr	-386(ra) # 800021dc <sleep>
    havekids = 0;
    80002366:	b715                	j	8000228a <wait+0x4a>

0000000080002368 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002368:	7139                	addi	sp,sp,-64
    8000236a:	fc06                	sd	ra,56(sp)
    8000236c:	f822                	sd	s0,48(sp)
    8000236e:	f426                	sd	s1,40(sp)
    80002370:	f04a                	sd	s2,32(sp)
    80002372:	ec4e                	sd	s3,24(sp)
    80002374:	e852                	sd	s4,16(sp)
    80002376:	e456                	sd	s5,8(sp)
    80002378:	0080                	addi	s0,sp,64
    8000237a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000237c:	0004f497          	auipc	s1,0x4f
    80002380:	35448493          	addi	s1,s1,852 # 800516d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002384:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002386:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002388:	00055917          	auipc	s2,0x55
    8000238c:	d4890913          	addi	s2,s2,-696 # 800570d0 <tickslock>
    80002390:	a821                	j	800023a8 <wakeup+0x40>
        p->state = RUNNABLE;
    80002392:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	a4a080e7          	jalr	-1462(ra) # 80000de2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023a0:	16848493          	addi	s1,s1,360
    800023a4:	03248463          	beq	s1,s2,800023cc <wakeup+0x64>
    if(p != myproc()){
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	778080e7          	jalr	1912(ra) # 80001b20 <myproc>
    800023b0:	fea488e3          	beq	s1,a0,800023a0 <wakeup+0x38>
      acquire(&p->lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	978080e7          	jalr	-1672(ra) # 80000d2e <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023be:	4c9c                	lw	a5,24(s1)
    800023c0:	fd379be3          	bne	a5,s3,80002396 <wakeup+0x2e>
    800023c4:	709c                	ld	a5,32(s1)
    800023c6:	fd4798e3          	bne	a5,s4,80002396 <wakeup+0x2e>
    800023ca:	b7e1                	j	80002392 <wakeup+0x2a>
    }
  }
}
    800023cc:	70e2                	ld	ra,56(sp)
    800023ce:	7442                	ld	s0,48(sp)
    800023d0:	74a2                	ld	s1,40(sp)
    800023d2:	7902                	ld	s2,32(sp)
    800023d4:	69e2                	ld	s3,24(sp)
    800023d6:	6a42                	ld	s4,16(sp)
    800023d8:	6aa2                	ld	s5,8(sp)
    800023da:	6121                	addi	sp,sp,64
    800023dc:	8082                	ret

00000000800023de <reparent>:
{
    800023de:	7179                	addi	sp,sp,-48
    800023e0:	f406                	sd	ra,40(sp)
    800023e2:	f022                	sd	s0,32(sp)
    800023e4:	ec26                	sd	s1,24(sp)
    800023e6:	e84a                	sd	s2,16(sp)
    800023e8:	e44e                	sd	s3,8(sp)
    800023ea:	e052                	sd	s4,0(sp)
    800023ec:	1800                	addi	s0,sp,48
    800023ee:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023f0:	0004f497          	auipc	s1,0x4f
    800023f4:	2e048493          	addi	s1,s1,736 # 800516d0 <proc>
      pp->parent = initproc;
    800023f8:	00007a17          	auipc	s4,0x7
    800023fc:	c30a0a13          	addi	s4,s4,-976 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002400:	00055997          	auipc	s3,0x55
    80002404:	cd098993          	addi	s3,s3,-816 # 800570d0 <tickslock>
    80002408:	a029                	j	80002412 <reparent+0x34>
    8000240a:	16848493          	addi	s1,s1,360
    8000240e:	01348d63          	beq	s1,s3,80002428 <reparent+0x4a>
    if(pp->parent == p){
    80002412:	7c9c                	ld	a5,56(s1)
    80002414:	ff279be3          	bne	a5,s2,8000240a <reparent+0x2c>
      pp->parent = initproc;
    80002418:	000a3503          	ld	a0,0(s4)
    8000241c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000241e:	00000097          	auipc	ra,0x0
    80002422:	f4a080e7          	jalr	-182(ra) # 80002368 <wakeup>
    80002426:	b7d5                	j	8000240a <reparent+0x2c>
}
    80002428:	70a2                	ld	ra,40(sp)
    8000242a:	7402                	ld	s0,32(sp)
    8000242c:	64e2                	ld	s1,24(sp)
    8000242e:	6942                	ld	s2,16(sp)
    80002430:	69a2                	ld	s3,8(sp)
    80002432:	6a02                	ld	s4,0(sp)
    80002434:	6145                	addi	sp,sp,48
    80002436:	8082                	ret

0000000080002438 <exit>:
{
    80002438:	7179                	addi	sp,sp,-48
    8000243a:	f406                	sd	ra,40(sp)
    8000243c:	f022                	sd	s0,32(sp)
    8000243e:	ec26                	sd	s1,24(sp)
    80002440:	e84a                	sd	s2,16(sp)
    80002442:	e44e                	sd	s3,8(sp)
    80002444:	e052                	sd	s4,0(sp)
    80002446:	1800                	addi	s0,sp,48
    80002448:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	6d6080e7          	jalr	1750(ra) # 80001b20 <myproc>
    80002452:	89aa                	mv	s3,a0
  if(p == initproc)
    80002454:	00007797          	auipc	a5,0x7
    80002458:	bd47b783          	ld	a5,-1068(a5) # 80009028 <initproc>
    8000245c:	0d050493          	addi	s1,a0,208
    80002460:	15050913          	addi	s2,a0,336
    80002464:	02a79363          	bne	a5,a0,8000248a <exit+0x52>
    panic("init exiting");
    80002468:	00006517          	auipc	a0,0x6
    8000246c:	e4050513          	addi	a0,a0,-448 # 800082a8 <digits+0x268>
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	0ce080e7          	jalr	206(ra) # 8000053e <panic>
      fileclose(f);
    80002478:	00002097          	auipc	ra,0x2
    8000247c:	236080e7          	jalr	566(ra) # 800046ae <fileclose>
      p->ofile[fd] = 0;
    80002480:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002484:	04a1                	addi	s1,s1,8
    80002486:	01248563          	beq	s1,s2,80002490 <exit+0x58>
    if(p->ofile[fd]){
    8000248a:	6088                	ld	a0,0(s1)
    8000248c:	f575                	bnez	a0,80002478 <exit+0x40>
    8000248e:	bfdd                	j	80002484 <exit+0x4c>
  begin_op();
    80002490:	00002097          	auipc	ra,0x2
    80002494:	d52080e7          	jalr	-686(ra) # 800041e2 <begin_op>
  iput(p->cwd);
    80002498:	1509b503          	ld	a0,336(s3)
    8000249c:	00001097          	auipc	ra,0x1
    800024a0:	52e080e7          	jalr	1326(ra) # 800039ca <iput>
  end_op();
    800024a4:	00002097          	auipc	ra,0x2
    800024a8:	dbe080e7          	jalr	-578(ra) # 80004262 <end_op>
  p->cwd = 0;
    800024ac:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024b0:	0004f497          	auipc	s1,0x4f
    800024b4:	e0848493          	addi	s1,s1,-504 # 800512b8 <wait_lock>
    800024b8:	8526                	mv	a0,s1
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	874080e7          	jalr	-1932(ra) # 80000d2e <acquire>
  reparent(p);
    800024c2:	854e                	mv	a0,s3
    800024c4:	00000097          	auipc	ra,0x0
    800024c8:	f1a080e7          	jalr	-230(ra) # 800023de <reparent>
  wakeup(p->parent);
    800024cc:	0389b503          	ld	a0,56(s3)
    800024d0:	00000097          	auipc	ra,0x0
    800024d4:	e98080e7          	jalr	-360(ra) # 80002368 <wakeup>
  acquire(&p->lock);
    800024d8:	854e                	mv	a0,s3
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	854080e7          	jalr	-1964(ra) # 80000d2e <acquire>
  p->xstate = status;
    800024e2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800024e6:	4795                	li	a5,5
    800024e8:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	8f4080e7          	jalr	-1804(ra) # 80000de2 <release>
  sched();
    800024f6:	00000097          	auipc	ra,0x0
    800024fa:	bd4080e7          	jalr	-1068(ra) # 800020ca <sched>
  panic("zombie exit");
    800024fe:	00006517          	auipc	a0,0x6
    80002502:	dba50513          	addi	a0,a0,-582 # 800082b8 <digits+0x278>
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	038080e7          	jalr	56(ra) # 8000053e <panic>

000000008000250e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000250e:	7179                	addi	sp,sp,-48
    80002510:	f406                	sd	ra,40(sp)
    80002512:	f022                	sd	s0,32(sp)
    80002514:	ec26                	sd	s1,24(sp)
    80002516:	e84a                	sd	s2,16(sp)
    80002518:	e44e                	sd	s3,8(sp)
    8000251a:	1800                	addi	s0,sp,48
    8000251c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000251e:	0004f497          	auipc	s1,0x4f
    80002522:	1b248493          	addi	s1,s1,434 # 800516d0 <proc>
    80002526:	00055997          	auipc	s3,0x55
    8000252a:	baa98993          	addi	s3,s3,-1110 # 800570d0 <tickslock>
    acquire(&p->lock);
    8000252e:	8526                	mv	a0,s1
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	7fe080e7          	jalr	2046(ra) # 80000d2e <acquire>
    if(p->pid == pid){
    80002538:	589c                	lw	a5,48(s1)
    8000253a:	01278d63          	beq	a5,s2,80002554 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000253e:	8526                	mv	a0,s1
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	8a2080e7          	jalr	-1886(ra) # 80000de2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002548:	16848493          	addi	s1,s1,360
    8000254c:	ff3491e3          	bne	s1,s3,8000252e <kill+0x20>
  }
  return -1;
    80002550:	557d                	li	a0,-1
    80002552:	a829                	j	8000256c <kill+0x5e>
      p->killed = 1;
    80002554:	4785                	li	a5,1
    80002556:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002558:	4c98                	lw	a4,24(s1)
    8000255a:	4789                	li	a5,2
    8000255c:	00f70f63          	beq	a4,a5,8000257a <kill+0x6c>
      release(&p->lock);
    80002560:	8526                	mv	a0,s1
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	880080e7          	jalr	-1920(ra) # 80000de2 <release>
      return 0;
    8000256a:	4501                	li	a0,0
}
    8000256c:	70a2                	ld	ra,40(sp)
    8000256e:	7402                	ld	s0,32(sp)
    80002570:	64e2                	ld	s1,24(sp)
    80002572:	6942                	ld	s2,16(sp)
    80002574:	69a2                	ld	s3,8(sp)
    80002576:	6145                	addi	sp,sp,48
    80002578:	8082                	ret
        p->state = RUNNABLE;
    8000257a:	478d                	li	a5,3
    8000257c:	cc9c                	sw	a5,24(s1)
    8000257e:	b7cd                	j	80002560 <kill+0x52>

0000000080002580 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002580:	7179                	addi	sp,sp,-48
    80002582:	f406                	sd	ra,40(sp)
    80002584:	f022                	sd	s0,32(sp)
    80002586:	ec26                	sd	s1,24(sp)
    80002588:	e84a                	sd	s2,16(sp)
    8000258a:	e44e                	sd	s3,8(sp)
    8000258c:	e052                	sd	s4,0(sp)
    8000258e:	1800                	addi	s0,sp,48
    80002590:	84aa                	mv	s1,a0
    80002592:	892e                	mv	s2,a1
    80002594:	89b2                	mv	s3,a2
    80002596:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	588080e7          	jalr	1416(ra) # 80001b20 <myproc>
  if(user_dst){
    800025a0:	c08d                	beqz	s1,800025c2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025a2:	86d2                	mv	a3,s4
    800025a4:	864e                	mv	a2,s3
    800025a6:	85ca                	mv	a1,s2
    800025a8:	6928                	ld	a0,80(a0)
    800025aa:	fffff097          	auipc	ra,0xfffff
    800025ae:	212080e7          	jalr	530(ra) # 800017bc <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025b2:	70a2                	ld	ra,40(sp)
    800025b4:	7402                	ld	s0,32(sp)
    800025b6:	64e2                	ld	s1,24(sp)
    800025b8:	6942                	ld	s2,16(sp)
    800025ba:	69a2                	ld	s3,8(sp)
    800025bc:	6a02                	ld	s4,0(sp)
    800025be:	6145                	addi	sp,sp,48
    800025c0:	8082                	ret
    memmove((char *)dst, src, len);
    800025c2:	000a061b          	sext.w	a2,s4
    800025c6:	85ce                	mv	a1,s3
    800025c8:	854a                	mv	a0,s2
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	8c0080e7          	jalr	-1856(ra) # 80000e8a <memmove>
    return 0;
    800025d2:	8526                	mv	a0,s1
    800025d4:	bff9                	j	800025b2 <either_copyout+0x32>

00000000800025d6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025d6:	7179                	addi	sp,sp,-48
    800025d8:	f406                	sd	ra,40(sp)
    800025da:	f022                	sd	s0,32(sp)
    800025dc:	ec26                	sd	s1,24(sp)
    800025de:	e84a                	sd	s2,16(sp)
    800025e0:	e44e                	sd	s3,8(sp)
    800025e2:	e052                	sd	s4,0(sp)
    800025e4:	1800                	addi	s0,sp,48
    800025e6:	892a                	mv	s2,a0
    800025e8:	84ae                	mv	s1,a1
    800025ea:	89b2                	mv	s3,a2
    800025ec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	532080e7          	jalr	1330(ra) # 80001b20 <myproc>
  if(user_src){
    800025f6:	c08d                	beqz	s1,80002618 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025f8:	86d2                	mv	a3,s4
    800025fa:	864e                	mv	a2,s3
    800025fc:	85ca                	mv	a1,s2
    800025fe:	6928                	ld	a0,80(a0)
    80002600:	fffff097          	auipc	ra,0xfffff
    80002604:	26e080e7          	jalr	622(ra) # 8000186e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002608:	70a2                	ld	ra,40(sp)
    8000260a:	7402                	ld	s0,32(sp)
    8000260c:	64e2                	ld	s1,24(sp)
    8000260e:	6942                	ld	s2,16(sp)
    80002610:	69a2                	ld	s3,8(sp)
    80002612:	6a02                	ld	s4,0(sp)
    80002614:	6145                	addi	sp,sp,48
    80002616:	8082                	ret
    memmove(dst, (char*)src, len);
    80002618:	000a061b          	sext.w	a2,s4
    8000261c:	85ce                	mv	a1,s3
    8000261e:	854a                	mv	a0,s2
    80002620:	fffff097          	auipc	ra,0xfffff
    80002624:	86a080e7          	jalr	-1942(ra) # 80000e8a <memmove>
    return 0;
    80002628:	8526                	mv	a0,s1
    8000262a:	bff9                	j	80002608 <either_copyin+0x32>

000000008000262c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000262c:	715d                	addi	sp,sp,-80
    8000262e:	e486                	sd	ra,72(sp)
    80002630:	e0a2                	sd	s0,64(sp)
    80002632:	fc26                	sd	s1,56(sp)
    80002634:	f84a                	sd	s2,48(sp)
    80002636:	f44e                	sd	s3,40(sp)
    80002638:	f052                	sd	s4,32(sp)
    8000263a:	ec56                	sd	s5,24(sp)
    8000263c:	e85a                	sd	s6,16(sp)
    8000263e:	e45e                	sd	s7,8(sp)
    80002640:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002642:	00006517          	auipc	a0,0x6
    80002646:	aae50513          	addi	a0,a0,-1362 # 800080f0 <digits+0xb0>
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	f3e080e7          	jalr	-194(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002652:	0004f497          	auipc	s1,0x4f
    80002656:	1d648493          	addi	s1,s1,470 # 80051828 <proc+0x158>
    8000265a:	00055917          	auipc	s2,0x55
    8000265e:	bce90913          	addi	s2,s2,-1074 # 80057228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002662:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002664:	00006997          	auipc	s3,0x6
    80002668:	c6498993          	addi	s3,s3,-924 # 800082c8 <digits+0x288>
    printf("%d %s %s", p->pid, state, p->name);
    8000266c:	00006a97          	auipc	s5,0x6
    80002670:	c64a8a93          	addi	s5,s5,-924 # 800082d0 <digits+0x290>
    printf("\n");
    80002674:	00006a17          	auipc	s4,0x6
    80002678:	a7ca0a13          	addi	s4,s4,-1412 # 800080f0 <digits+0xb0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000267c:	00006b97          	auipc	s7,0x6
    80002680:	c8cb8b93          	addi	s7,s7,-884 # 80008308 <states.1720>
    80002684:	a00d                	j	800026a6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002686:	ed86a583          	lw	a1,-296(a3)
    8000268a:	8556                	mv	a0,s5
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	efc080e7          	jalr	-260(ra) # 80000588 <printf>
    printf("\n");
    80002694:	8552                	mv	a0,s4
    80002696:	ffffe097          	auipc	ra,0xffffe
    8000269a:	ef2080e7          	jalr	-270(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000269e:	16848493          	addi	s1,s1,360
    800026a2:	03248163          	beq	s1,s2,800026c4 <procdump+0x98>
    if(p->state == UNUSED)
    800026a6:	86a6                	mv	a3,s1
    800026a8:	ec04a783          	lw	a5,-320(s1)
    800026ac:	dbed                	beqz	a5,8000269e <procdump+0x72>
      state = "???";
    800026ae:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026b0:	fcfb6be3          	bltu	s6,a5,80002686 <procdump+0x5a>
    800026b4:	1782                	slli	a5,a5,0x20
    800026b6:	9381                	srli	a5,a5,0x20
    800026b8:	078e                	slli	a5,a5,0x3
    800026ba:	97de                	add	a5,a5,s7
    800026bc:	6390                	ld	a2,0(a5)
    800026be:	f661                	bnez	a2,80002686 <procdump+0x5a>
      state = "???";
    800026c0:	864e                	mv	a2,s3
    800026c2:	b7d1                	j	80002686 <procdump+0x5a>
  }
}
    800026c4:	60a6                	ld	ra,72(sp)
    800026c6:	6406                	ld	s0,64(sp)
    800026c8:	74e2                	ld	s1,56(sp)
    800026ca:	7942                	ld	s2,48(sp)
    800026cc:	79a2                	ld	s3,40(sp)
    800026ce:	7a02                	ld	s4,32(sp)
    800026d0:	6ae2                	ld	s5,24(sp)
    800026d2:	6b42                	ld	s6,16(sp)
    800026d4:	6ba2                	ld	s7,8(sp)
    800026d6:	6161                	addi	sp,sp,80
    800026d8:	8082                	ret

00000000800026da <swtch>:
    800026da:	00153023          	sd	ra,0(a0)
    800026de:	00253423          	sd	sp,8(a0)
    800026e2:	e900                	sd	s0,16(a0)
    800026e4:	ed04                	sd	s1,24(a0)
    800026e6:	03253023          	sd	s2,32(a0)
    800026ea:	03353423          	sd	s3,40(a0)
    800026ee:	03453823          	sd	s4,48(a0)
    800026f2:	03553c23          	sd	s5,56(a0)
    800026f6:	05653023          	sd	s6,64(a0)
    800026fa:	05753423          	sd	s7,72(a0)
    800026fe:	05853823          	sd	s8,80(a0)
    80002702:	05953c23          	sd	s9,88(a0)
    80002706:	07a53023          	sd	s10,96(a0)
    8000270a:	07b53423          	sd	s11,104(a0)
    8000270e:	0005b083          	ld	ra,0(a1)
    80002712:	0085b103          	ld	sp,8(a1)
    80002716:	6980                	ld	s0,16(a1)
    80002718:	6d84                	ld	s1,24(a1)
    8000271a:	0205b903          	ld	s2,32(a1)
    8000271e:	0285b983          	ld	s3,40(a1)
    80002722:	0305ba03          	ld	s4,48(a1)
    80002726:	0385ba83          	ld	s5,56(a1)
    8000272a:	0405bb03          	ld	s6,64(a1)
    8000272e:	0485bb83          	ld	s7,72(a1)
    80002732:	0505bc03          	ld	s8,80(a1)
    80002736:	0585bc83          	ld	s9,88(a1)
    8000273a:	0605bd03          	ld	s10,96(a1)
    8000273e:	0685bd83          	ld	s11,104(a1)
    80002742:	8082                	ret

0000000080002744 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002744:	1141                	addi	sp,sp,-16
    80002746:	e406                	sd	ra,8(sp)
    80002748:	e022                	sd	s0,0(sp)
    8000274a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000274c:	00006597          	auipc	a1,0x6
    80002750:	bec58593          	addi	a1,a1,-1044 # 80008338 <states.1720+0x30>
    80002754:	00055517          	auipc	a0,0x55
    80002758:	97c50513          	addi	a0,a0,-1668 # 800570d0 <tickslock>
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	542080e7          	jalr	1346(ra) # 80000c9e <initlock>
}
    80002764:	60a2                	ld	ra,8(sp)
    80002766:	6402                	ld	s0,0(sp)
    80002768:	0141                	addi	sp,sp,16
    8000276a:	8082                	ret

000000008000276c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000276c:	1141                	addi	sp,sp,-16
    8000276e:	e422                	sd	s0,8(sp)
    80002770:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002772:	00003797          	auipc	a5,0x3
    80002776:	55e78793          	addi	a5,a5,1374 # 80005cd0 <kernelvec>
    8000277a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000277e:	6422                	ld	s0,8(sp)
    80002780:	0141                	addi	sp,sp,16
    80002782:	8082                	ret

0000000080002784 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002784:	1141                	addi	sp,sp,-16
    80002786:	e406                	sd	ra,8(sp)
    80002788:	e022                	sd	s0,0(sp)
    8000278a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	394080e7          	jalr	916(ra) # 80001b20 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002794:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002798:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000279e:	00005617          	auipc	a2,0x5
    800027a2:	86260613          	addi	a2,a2,-1950 # 80007000 <_trampoline>
    800027a6:	00005697          	auipc	a3,0x5
    800027aa:	85a68693          	addi	a3,a3,-1958 # 80007000 <_trampoline>
    800027ae:	8e91                	sub	a3,a3,a2
    800027b0:	040007b7          	lui	a5,0x4000
    800027b4:	17fd                	addi	a5,a5,-1
    800027b6:	07b2                	slli	a5,a5,0xc
    800027b8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027ba:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027be:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027c0:	180026f3          	csrr	a3,satp
    800027c4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027c6:	6d38                	ld	a4,88(a0)
    800027c8:	6134                	ld	a3,64(a0)
    800027ca:	6585                	lui	a1,0x1
    800027cc:	96ae                	add	a3,a3,a1
    800027ce:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027d0:	6d38                	ld	a4,88(a0)
    800027d2:	00000697          	auipc	a3,0x0
    800027d6:	29c68693          	addi	a3,a3,668 # 80002a6e <usertrap>
    800027da:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027dc:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027de:	8692                	mv	a3,tp
    800027e0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027e6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027ea:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ee:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027f2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027f4:	6f18                	ld	a4,24(a4)
    800027f6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027fa:	692c                	ld	a1,80(a0)
    800027fc:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027fe:	00005717          	auipc	a4,0x5
    80002802:	89270713          	addi	a4,a4,-1902 # 80007090 <userret>
    80002806:	8f11                	sub	a4,a4,a2
    80002808:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000280a:	577d                	li	a4,-1
    8000280c:	177e                	slli	a4,a4,0x3f
    8000280e:	8dd9                	or	a1,a1,a4
    80002810:	02000537          	lui	a0,0x2000
    80002814:	157d                	addi	a0,a0,-1
    80002816:	0536                	slli	a0,a0,0xd
    80002818:	9782                	jalr	a5
}
    8000281a:	60a2                	ld	ra,8(sp)
    8000281c:	6402                	ld	s0,0(sp)
    8000281e:	0141                	addi	sp,sp,16
    80002820:	8082                	ret

0000000080002822 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002822:	1101                	addi	sp,sp,-32
    80002824:	ec06                	sd	ra,24(sp)
    80002826:	e822                	sd	s0,16(sp)
    80002828:	e426                	sd	s1,8(sp)
    8000282a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000282c:	00055497          	auipc	s1,0x55
    80002830:	8a448493          	addi	s1,s1,-1884 # 800570d0 <tickslock>
    80002834:	8526                	mv	a0,s1
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	4f8080e7          	jalr	1272(ra) # 80000d2e <acquire>
  ticks++;
    8000283e:	00006517          	auipc	a0,0x6
    80002842:	7f250513          	addi	a0,a0,2034 # 80009030 <ticks>
    80002846:	411c                	lw	a5,0(a0)
    80002848:	2785                	addiw	a5,a5,1
    8000284a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000284c:	00000097          	auipc	ra,0x0
    80002850:	b1c080e7          	jalr	-1252(ra) # 80002368 <wakeup>
  release(&tickslock);
    80002854:	8526                	mv	a0,s1
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	58c080e7          	jalr	1420(ra) # 80000de2 <release>
}
    8000285e:	60e2                	ld	ra,24(sp)
    80002860:	6442                	ld	s0,16(sp)
    80002862:	64a2                	ld	s1,8(sp)
    80002864:	6105                	addi	sp,sp,32
    80002866:	8082                	ret

0000000080002868 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002868:	1101                	addi	sp,sp,-32
    8000286a:	ec06                	sd	ra,24(sp)
    8000286c:	e822                	sd	s0,16(sp)
    8000286e:	e426                	sd	s1,8(sp)
    80002870:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002872:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002876:	00074d63          	bltz	a4,80002890 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000287a:	57fd                	li	a5,-1
    8000287c:	17fe                	slli	a5,a5,0x3f
    8000287e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002880:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002882:	06f70363          	beq	a4,a5,800028e8 <devintr+0x80>
  }
}
    80002886:	60e2                	ld	ra,24(sp)
    80002888:	6442                	ld	s0,16(sp)
    8000288a:	64a2                	ld	s1,8(sp)
    8000288c:	6105                	addi	sp,sp,32
    8000288e:	8082                	ret
     (scause & 0xff) == 9){
    80002890:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002894:	46a5                	li	a3,9
    80002896:	fed792e3          	bne	a5,a3,8000287a <devintr+0x12>
    int irq = plic_claim();
    8000289a:	00003097          	auipc	ra,0x3
    8000289e:	53e080e7          	jalr	1342(ra) # 80005dd8 <plic_claim>
    800028a2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028a4:	47a9                	li	a5,10
    800028a6:	02f50763          	beq	a0,a5,800028d4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028aa:	4785                	li	a5,1
    800028ac:	02f50963          	beq	a0,a5,800028de <devintr+0x76>
    return 1;
    800028b0:	4505                	li	a0,1
    } else if(irq){
    800028b2:	d8f1                	beqz	s1,80002886 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028b4:	85a6                	mv	a1,s1
    800028b6:	00006517          	auipc	a0,0x6
    800028ba:	a8a50513          	addi	a0,a0,-1398 # 80008340 <states.1720+0x38>
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	cca080e7          	jalr	-822(ra) # 80000588 <printf>
      plic_complete(irq);
    800028c6:	8526                	mv	a0,s1
    800028c8:	00003097          	auipc	ra,0x3
    800028cc:	534080e7          	jalr	1332(ra) # 80005dfc <plic_complete>
    return 1;
    800028d0:	4505                	li	a0,1
    800028d2:	bf55                	j	80002886 <devintr+0x1e>
      uartintr();
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	0d4080e7          	jalr	212(ra) # 800009a8 <uartintr>
    800028dc:	b7ed                	j	800028c6 <devintr+0x5e>
      virtio_disk_intr();
    800028de:	00004097          	auipc	ra,0x4
    800028e2:	9fe080e7          	jalr	-1538(ra) # 800062dc <virtio_disk_intr>
    800028e6:	b7c5                	j	800028c6 <devintr+0x5e>
    if(cpuid() == 0){
    800028e8:	fffff097          	auipc	ra,0xfffff
    800028ec:	20c080e7          	jalr	524(ra) # 80001af4 <cpuid>
    800028f0:	c901                	beqz	a0,80002900 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028f2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028f6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028f8:	14479073          	csrw	sip,a5
    return 2;
    800028fc:	4509                	li	a0,2
    800028fe:	b761                	j	80002886 <devintr+0x1e>
      clockintr();
    80002900:	00000097          	auipc	ra,0x0
    80002904:	f22080e7          	jalr	-222(ra) # 80002822 <clockintr>
    80002908:	b7ed                	j	800028f2 <devintr+0x8a>

000000008000290a <kerneltrap>:
{
    8000290a:	7179                	addi	sp,sp,-48
    8000290c:	f406                	sd	ra,40(sp)
    8000290e:	f022                	sd	s0,32(sp)
    80002910:	ec26                	sd	s1,24(sp)
    80002912:	e84a                	sd	s2,16(sp)
    80002914:	e44e                	sd	s3,8(sp)
    80002916:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002918:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002920:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002924:	1004f793          	andi	a5,s1,256
    80002928:	cb85                	beqz	a5,80002958 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000292e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002930:	ef85                	bnez	a5,80002968 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002932:	00000097          	auipc	ra,0x0
    80002936:	f36080e7          	jalr	-202(ra) # 80002868 <devintr>
    8000293a:	cd1d                	beqz	a0,80002978 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000293c:	4789                	li	a5,2
    8000293e:	06f50a63          	beq	a0,a5,800029b2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002942:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002946:	10049073          	csrw	sstatus,s1
}
    8000294a:	70a2                	ld	ra,40(sp)
    8000294c:	7402                	ld	s0,32(sp)
    8000294e:	64e2                	ld	s1,24(sp)
    80002950:	6942                	ld	s2,16(sp)
    80002952:	69a2                	ld	s3,8(sp)
    80002954:	6145                	addi	sp,sp,48
    80002956:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	a0850513          	addi	a0,a0,-1528 # 80008360 <states.1720+0x58>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	bde080e7          	jalr	-1058(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	a2050513          	addi	a0,a0,-1504 # 80008388 <states.1720+0x80>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002978:	85ce                	mv	a1,s3
    8000297a:	00006517          	auipc	a0,0x6
    8000297e:	a2e50513          	addi	a0,a0,-1490 # 800083a8 <states.1720+0xa0>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	c06080e7          	jalr	-1018(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000298e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002992:	00006517          	auipc	a0,0x6
    80002996:	a2650513          	addi	a0,a0,-1498 # 800083b8 <states.1720+0xb0>
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	bee080e7          	jalr	-1042(ra) # 80000588 <printf>
    panic("kerneltrap");
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	a2e50513          	addi	a0,a0,-1490 # 800083d0 <states.1720+0xc8>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	b94080e7          	jalr	-1132(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b2:	fffff097          	auipc	ra,0xfffff
    800029b6:	16e080e7          	jalr	366(ra) # 80001b20 <myproc>
    800029ba:	d541                	beqz	a0,80002942 <kerneltrap+0x38>
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	164080e7          	jalr	356(ra) # 80001b20 <myproc>
    800029c4:	4d18                	lw	a4,24(a0)
    800029c6:	4791                	li	a5,4
    800029c8:	f6f71de3          	bne	a4,a5,80002942 <kerneltrap+0x38>
    yield();
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	7d4080e7          	jalr	2004(ra) # 800021a0 <yield>
    800029d4:	b7bd                	j	80002942 <kerneltrap+0x38>

00000000800029d6 <cow_handle>:

//added
int
cow_handle(pagetable_t page_table, uint64 va)
{
  va = PGROUNDDOWN(va);
    800029d6:	77fd                	lui	a5,0xfffff
    800029d8:	8dfd                	and	a1,a1,a5
  if(va >= MAXVA) //if not in scope of mem
    800029da:	57fd                	li	a5,-1
    800029dc:	83e9                	srli	a5,a5,0x1a
    800029de:	08b7e063          	bltu	a5,a1,80002a5e <cow_handle+0x88>
{
    800029e2:	7179                	addi	sp,sp,-48
    800029e4:	f406                	sd	ra,40(sp)
    800029e6:	f022                	sd	s0,32(sp)
    800029e8:	ec26                	sd	s1,24(sp)
    800029ea:	e84a                	sd	s2,16(sp)
    800029ec:	e44e                	sd	s3,8(sp)
    800029ee:	1800                	addi	s0,sp,48
    return -1;
  pte_t *pte;
  if((pte = walk(page_table,va,0)) == 0){//if not valid va
    800029f0:	4601                	li	a2,0
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	720080e7          	jalr	1824(ra) # 80001112 <walk>
    800029fa:	892a                	mv	s2,a0
    800029fc:	c13d                	beqz	a0,80002a62 <cow_handle+0x8c>
    return -1;
  }
  if(((*pte & PTE_V) == 0) || ((*pte & PTE_COW) == 0)){
    800029fe:	611c                	ld	a5,0(a0)
    80002a00:	2017f793          	andi	a5,a5,513
    80002a04:	20100713          	li	a4,513
    80002a08:	04e79f63          	bne	a5,a4,80002a66 <cow_handle+0x90>
    return -1;
  }
  char* mem;
  if((mem = kalloc()) != 0){
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	216080e7          	jalr	534(ra) # 80000c22 <kalloc>
    80002a14:	84aa                	mv	s1,a0
    80002a16:	c931                	beqz	a0,80002a6a <cow_handle+0x94>
    uint64 pa = PTE2PA(*pte);
    80002a18:	00093983          	ld	s3,0(s2)
    80002a1c:	00a9d993          	srli	s3,s3,0xa
    80002a20:	09b2                	slli	s3,s3,0xc
    memmove(mem,(char*)pa,PGSIZE);
    80002a22:	6605                	lui	a2,0x1
    80002a24:	85ce                	mv	a1,s3
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	464080e7          	jalr	1124(ra) # 80000e8a <memmove>
    *pte = PA2PTE(mem) | ((PTE_FLAGS(*pte) & ~PTE_COW) | PTE_W);
    80002a2e:	80b1                	srli	s1,s1,0xc
    80002a30:	04aa                	slli	s1,s1,0xa
    80002a32:	00093783          	ld	a5,0(s2)
    80002a36:	1fb7f793          	andi	a5,a5,507
    80002a3a:	8cdd                	or	s1,s1,a5
    80002a3c:	0044e493          	ori	s1,s1,4
    80002a40:	00993023          	sd	s1,0(s2)
    //inorder to decrease the ref counter.
    kfree((void*)pa);
    80002a44:	854e                	mv	a0,s3
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	0a0080e7          	jalr	160(ra) # 80000ae6 <kfree>
    return 0;
    80002a4e:	4501                	li	a0,0
  }
  else{
    return -1;
  }
}
    80002a50:	70a2                	ld	ra,40(sp)
    80002a52:	7402                	ld	s0,32(sp)
    80002a54:	64e2                	ld	s1,24(sp)
    80002a56:	6942                	ld	s2,16(sp)
    80002a58:	69a2                	ld	s3,8(sp)
    80002a5a:	6145                	addi	sp,sp,48
    80002a5c:	8082                	ret
    return -1;
    80002a5e:	557d                	li	a0,-1
}
    80002a60:	8082                	ret
    return -1;
    80002a62:	557d                	li	a0,-1
    80002a64:	b7f5                	j	80002a50 <cow_handle+0x7a>
    return -1;
    80002a66:	557d                	li	a0,-1
    80002a68:	b7e5                	j	80002a50 <cow_handle+0x7a>
    return -1;
    80002a6a:	557d                	li	a0,-1
    80002a6c:	b7d5                	j	80002a50 <cow_handle+0x7a>

0000000080002a6e <usertrap>:
{
    80002a6e:	1101                	addi	sp,sp,-32
    80002a70:	ec06                	sd	ra,24(sp)
    80002a72:	e822                	sd	s0,16(sp)
    80002a74:	e426                	sd	s1,8(sp)
    80002a76:	e04a                	sd	s2,0(sp)
    80002a78:	1000                	addi	s0,sp,32
  printf("usertrap\n");
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	96650513          	addi	a0,a0,-1690 # 800083e0 <states.1720+0xd8>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	b06080e7          	jalr	-1274(ra) # 80000588 <printf>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a8a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a8e:	1007f793          	andi	a5,a5,256
    80002a92:	e7a5                	bnez	a5,80002afa <usertrap+0x8c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a94:	00003797          	auipc	a5,0x3
    80002a98:	23c78793          	addi	a5,a5,572 # 80005cd0 <kernelvec>
    80002a9c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002aa0:	fffff097          	auipc	ra,0xfffff
    80002aa4:	080080e7          	jalr	128(ra) # 80001b20 <myproc>
    80002aa8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002aaa:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aac:	14102773          	csrr	a4,sepc
    80002ab0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ab2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ab6:	47a1                	li	a5,8
    80002ab8:	04f70963          	beq	a4,a5,80002b0a <usertrap+0x9c>
    80002abc:	14202773          	csrr	a4,scause
  }else if(r_scause() == 15){
    80002ac0:	47bd                	li	a5,15
    80002ac2:	08f71563          	bne	a4,a5,80002b4c <usertrap+0xde>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ac6:	143025f3          	csrr	a1,stval
    if(va >= p->sz || cow_handle(p->pagetable,va) != 0)
    80002aca:	653c                	ld	a5,72(a0)
    80002acc:	06f5e963          	bltu	a1,a5,80002b3e <usertrap+0xd0>
      p->killed = 1;
    80002ad0:	4785                	li	a5,1
    80002ad2:	d49c                	sw	a5,40(s1)
{
    80002ad4:	4901                	li	s2,0
    exit(-1);
    80002ad6:	557d                	li	a0,-1
    80002ad8:	00000097          	auipc	ra,0x0
    80002adc:	960080e7          	jalr	-1696(ra) # 80002438 <exit>
  if(which_dev == 2)
    80002ae0:	4789                	li	a5,2
    80002ae2:	0af90863          	beq	s2,a5,80002b92 <usertrap+0x124>
  usertrapret();
    80002ae6:	00000097          	auipc	ra,0x0
    80002aea:	c9e080e7          	jalr	-866(ra) # 80002784 <usertrapret>
}
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6902                	ld	s2,0(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret
    panic("usertrap: not from user mode");
    80002afa:	00006517          	auipc	a0,0x6
    80002afe:	8f650513          	addi	a0,a0,-1802 # 800083f0 <states.1720+0xe8>
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	a3c080e7          	jalr	-1476(ra) # 8000053e <panic>
    if(p->killed)
    80002b0a:	551c                	lw	a5,40(a0)
    80002b0c:	e39d                	bnez	a5,80002b32 <usertrap+0xc4>
    p->trapframe->epc += 4;
    80002b0e:	6cb8                	ld	a4,88(s1)
    80002b10:	6f1c                	ld	a5,24(a4)
    80002b12:	0791                	addi	a5,a5,4
    80002b14:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b16:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b1a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b1e:	10079073          	csrw	sstatus,a5
    syscall();
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	1f0080e7          	jalr	496(ra) # 80002d12 <syscall>
  if(p->killed)
    80002b2a:	549c                	lw	a5,40(s1)
    80002b2c:	dfcd                	beqz	a5,80002ae6 <usertrap+0x78>
    80002b2e:	4901                	li	s2,0
    80002b30:	b75d                	j	80002ad6 <usertrap+0x68>
      exit(-1);
    80002b32:	557d                	li	a0,-1
    80002b34:	00000097          	auipc	ra,0x0
    80002b38:	904080e7          	jalr	-1788(ra) # 80002438 <exit>
    80002b3c:	bfc9                	j	80002b0e <usertrap+0xa0>
    if(va >= p->sz || cow_handle(p->pagetable,va) != 0)
    80002b3e:	6928                	ld	a0,80(a0)
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	e96080e7          	jalr	-362(ra) # 800029d6 <cow_handle>
    80002b48:	d16d                	beqz	a0,80002b2a <usertrap+0xbc>
    80002b4a:	b759                	j	80002ad0 <usertrap+0x62>
  }else if((which_dev = devintr()) != 0){
    80002b4c:	00000097          	auipc	ra,0x0
    80002b50:	d1c080e7          	jalr	-740(ra) # 80002868 <devintr>
    80002b54:	892a                	mv	s2,a0
    80002b56:	c501                	beqz	a0,80002b5e <usertrap+0xf0>
  if(p->killed)
    80002b58:	549c                	lw	a5,40(s1)
    80002b5a:	d3d9                	beqz	a5,80002ae0 <usertrap+0x72>
    80002b5c:	bfad                	j	80002ad6 <usertrap+0x68>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b62:	5890                	lw	a2,48(s1)
    80002b64:	00006517          	auipc	a0,0x6
    80002b68:	8ac50513          	addi	a0,a0,-1876 # 80008410 <states.1720+0x108>
    80002b6c:	ffffe097          	auipc	ra,0xffffe
    80002b70:	a1c080e7          	jalr	-1508(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b74:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b78:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b7c:	00006517          	auipc	a0,0x6
    80002b80:	8c450513          	addi	a0,a0,-1852 # 80008440 <states.1720+0x138>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	a04080e7          	jalr	-1532(ra) # 80000588 <printf>
    p->killed = 1;
    80002b8c:	4785                	li	a5,1
    80002b8e:	d49c                	sw	a5,40(s1)
    80002b90:	b791                	j	80002ad4 <usertrap+0x66>
    yield();
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	60e080e7          	jalr	1550(ra) # 800021a0 <yield>
    80002b9a:	b7b1                	j	80002ae6 <usertrap+0x78>

0000000080002b9c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b9c:	1101                	addi	sp,sp,-32
    80002b9e:	ec06                	sd	ra,24(sp)
    80002ba0:	e822                	sd	s0,16(sp)
    80002ba2:	e426                	sd	s1,8(sp)
    80002ba4:	1000                	addi	s0,sp,32
    80002ba6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	f78080e7          	jalr	-136(ra) # 80001b20 <myproc>
  switch (n) {
    80002bb0:	4795                	li	a5,5
    80002bb2:	0497e163          	bltu	a5,s1,80002bf4 <argraw+0x58>
    80002bb6:	048a                	slli	s1,s1,0x2
    80002bb8:	00006717          	auipc	a4,0x6
    80002bbc:	8d070713          	addi	a4,a4,-1840 # 80008488 <states.1720+0x180>
    80002bc0:	94ba                	add	s1,s1,a4
    80002bc2:	409c                	lw	a5,0(s1)
    80002bc4:	97ba                	add	a5,a5,a4
    80002bc6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bc8:	6d3c                	ld	a5,88(a0)
    80002bca:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bcc:	60e2                	ld	ra,24(sp)
    80002bce:	6442                	ld	s0,16(sp)
    80002bd0:	64a2                	ld	s1,8(sp)
    80002bd2:	6105                	addi	sp,sp,32
    80002bd4:	8082                	ret
    return p->trapframe->a1;
    80002bd6:	6d3c                	ld	a5,88(a0)
    80002bd8:	7fa8                	ld	a0,120(a5)
    80002bda:	bfcd                	j	80002bcc <argraw+0x30>
    return p->trapframe->a2;
    80002bdc:	6d3c                	ld	a5,88(a0)
    80002bde:	63c8                	ld	a0,128(a5)
    80002be0:	b7f5                	j	80002bcc <argraw+0x30>
    return p->trapframe->a3;
    80002be2:	6d3c                	ld	a5,88(a0)
    80002be4:	67c8                	ld	a0,136(a5)
    80002be6:	b7dd                	j	80002bcc <argraw+0x30>
    return p->trapframe->a4;
    80002be8:	6d3c                	ld	a5,88(a0)
    80002bea:	6bc8                	ld	a0,144(a5)
    80002bec:	b7c5                	j	80002bcc <argraw+0x30>
    return p->trapframe->a5;
    80002bee:	6d3c                	ld	a5,88(a0)
    80002bf0:	6fc8                	ld	a0,152(a5)
    80002bf2:	bfe9                	j	80002bcc <argraw+0x30>
  panic("argraw");
    80002bf4:	00006517          	auipc	a0,0x6
    80002bf8:	86c50513          	addi	a0,a0,-1940 # 80008460 <states.1720+0x158>
    80002bfc:	ffffe097          	auipc	ra,0xffffe
    80002c00:	942080e7          	jalr	-1726(ra) # 8000053e <panic>

0000000080002c04 <fetchaddr>:
{
    80002c04:	1101                	addi	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	e426                	sd	s1,8(sp)
    80002c0c:	e04a                	sd	s2,0(sp)
    80002c0e:	1000                	addi	s0,sp,32
    80002c10:	84aa                	mv	s1,a0
    80002c12:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c14:	fffff097          	auipc	ra,0xfffff
    80002c18:	f0c080e7          	jalr	-244(ra) # 80001b20 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c1c:	653c                	ld	a5,72(a0)
    80002c1e:	02f4f863          	bgeu	s1,a5,80002c4e <fetchaddr+0x4a>
    80002c22:	00848713          	addi	a4,s1,8
    80002c26:	02e7e663          	bltu	a5,a4,80002c52 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c2a:	46a1                	li	a3,8
    80002c2c:	8626                	mv	a2,s1
    80002c2e:	85ca                	mv	a1,s2
    80002c30:	6928                	ld	a0,80(a0)
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	c3c080e7          	jalr	-964(ra) # 8000186e <copyin>
    80002c3a:	00a03533          	snez	a0,a0
    80002c3e:	40a00533          	neg	a0,a0
}
    80002c42:	60e2                	ld	ra,24(sp)
    80002c44:	6442                	ld	s0,16(sp)
    80002c46:	64a2                	ld	s1,8(sp)
    80002c48:	6902                	ld	s2,0(sp)
    80002c4a:	6105                	addi	sp,sp,32
    80002c4c:	8082                	ret
    return -1;
    80002c4e:	557d                	li	a0,-1
    80002c50:	bfcd                	j	80002c42 <fetchaddr+0x3e>
    80002c52:	557d                	li	a0,-1
    80002c54:	b7fd                	j	80002c42 <fetchaddr+0x3e>

0000000080002c56 <fetchstr>:
{
    80002c56:	7179                	addi	sp,sp,-48
    80002c58:	f406                	sd	ra,40(sp)
    80002c5a:	f022                	sd	s0,32(sp)
    80002c5c:	ec26                	sd	s1,24(sp)
    80002c5e:	e84a                	sd	s2,16(sp)
    80002c60:	e44e                	sd	s3,8(sp)
    80002c62:	1800                	addi	s0,sp,48
    80002c64:	892a                	mv	s2,a0
    80002c66:	84ae                	mv	s1,a1
    80002c68:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	eb6080e7          	jalr	-330(ra) # 80001b20 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c72:	86ce                	mv	a3,s3
    80002c74:	864a                	mv	a2,s2
    80002c76:	85a6                	mv	a1,s1
    80002c78:	6928                	ld	a0,80(a0)
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	c80080e7          	jalr	-896(ra) # 800018fa <copyinstr>
  if(err < 0)
    80002c82:	00054763          	bltz	a0,80002c90 <fetchstr+0x3a>
  return strlen(buf);
    80002c86:	8526                	mv	a0,s1
    80002c88:	ffffe097          	auipc	ra,0xffffe
    80002c8c:	326080e7          	jalr	806(ra) # 80000fae <strlen>
}
    80002c90:	70a2                	ld	ra,40(sp)
    80002c92:	7402                	ld	s0,32(sp)
    80002c94:	64e2                	ld	s1,24(sp)
    80002c96:	6942                	ld	s2,16(sp)
    80002c98:	69a2                	ld	s3,8(sp)
    80002c9a:	6145                	addi	sp,sp,48
    80002c9c:	8082                	ret

0000000080002c9e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c9e:	1101                	addi	sp,sp,-32
    80002ca0:	ec06                	sd	ra,24(sp)
    80002ca2:	e822                	sd	s0,16(sp)
    80002ca4:	e426                	sd	s1,8(sp)
    80002ca6:	1000                	addi	s0,sp,32
    80002ca8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002caa:	00000097          	auipc	ra,0x0
    80002cae:	ef2080e7          	jalr	-270(ra) # 80002b9c <argraw>
    80002cb2:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cb4:	4501                	li	a0,0
    80002cb6:	60e2                	ld	ra,24(sp)
    80002cb8:	6442                	ld	s0,16(sp)
    80002cba:	64a2                	ld	s1,8(sp)
    80002cbc:	6105                	addi	sp,sp,32
    80002cbe:	8082                	ret

0000000080002cc0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	e426                	sd	s1,8(sp)
    80002cc8:	1000                	addi	s0,sp,32
    80002cca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	ed0080e7          	jalr	-304(ra) # 80002b9c <argraw>
    80002cd4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cd6:	4501                	li	a0,0
    80002cd8:	60e2                	ld	ra,24(sp)
    80002cda:	6442                	ld	s0,16(sp)
    80002cdc:	64a2                	ld	s1,8(sp)
    80002cde:	6105                	addi	sp,sp,32
    80002ce0:	8082                	ret

0000000080002ce2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ce2:	1101                	addi	sp,sp,-32
    80002ce4:	ec06                	sd	ra,24(sp)
    80002ce6:	e822                	sd	s0,16(sp)
    80002ce8:	e426                	sd	s1,8(sp)
    80002cea:	e04a                	sd	s2,0(sp)
    80002cec:	1000                	addi	s0,sp,32
    80002cee:	84ae                	mv	s1,a1
    80002cf0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cf2:	00000097          	auipc	ra,0x0
    80002cf6:	eaa080e7          	jalr	-342(ra) # 80002b9c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cfa:	864a                	mv	a2,s2
    80002cfc:	85a6                	mv	a1,s1
    80002cfe:	00000097          	auipc	ra,0x0
    80002d02:	f58080e7          	jalr	-168(ra) # 80002c56 <fetchstr>
}
    80002d06:	60e2                	ld	ra,24(sp)
    80002d08:	6442                	ld	s0,16(sp)
    80002d0a:	64a2                	ld	s1,8(sp)
    80002d0c:	6902                	ld	s2,0(sp)
    80002d0e:	6105                	addi	sp,sp,32
    80002d10:	8082                	ret

0000000080002d12 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d12:	1101                	addi	sp,sp,-32
    80002d14:	ec06                	sd	ra,24(sp)
    80002d16:	e822                	sd	s0,16(sp)
    80002d18:	e426                	sd	s1,8(sp)
    80002d1a:	e04a                	sd	s2,0(sp)
    80002d1c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	e02080e7          	jalr	-510(ra) # 80001b20 <myproc>
    80002d26:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d28:	05853903          	ld	s2,88(a0)
    80002d2c:	0a893783          	ld	a5,168(s2)
    80002d30:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d34:	37fd                	addiw	a5,a5,-1
    80002d36:	4751                	li	a4,20
    80002d38:	00f76f63          	bltu	a4,a5,80002d56 <syscall+0x44>
    80002d3c:	00369713          	slli	a4,a3,0x3
    80002d40:	00005797          	auipc	a5,0x5
    80002d44:	76078793          	addi	a5,a5,1888 # 800084a0 <syscalls>
    80002d48:	97ba                	add	a5,a5,a4
    80002d4a:	639c                	ld	a5,0(a5)
    80002d4c:	c789                	beqz	a5,80002d56 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d4e:	9782                	jalr	a5
    80002d50:	06a93823          	sd	a0,112(s2)
    80002d54:	a839                	j	80002d72 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d56:	15848613          	addi	a2,s1,344
    80002d5a:	588c                	lw	a1,48(s1)
    80002d5c:	00005517          	auipc	a0,0x5
    80002d60:	70c50513          	addi	a0,a0,1804 # 80008468 <states.1720+0x160>
    80002d64:	ffffe097          	auipc	ra,0xffffe
    80002d68:	824080e7          	jalr	-2012(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d6c:	6cbc                	ld	a5,88(s1)
    80002d6e:	577d                	li	a4,-1
    80002d70:	fbb8                	sd	a4,112(a5)
  }
}
    80002d72:	60e2                	ld	ra,24(sp)
    80002d74:	6442                	ld	s0,16(sp)
    80002d76:	64a2                	ld	s1,8(sp)
    80002d78:	6902                	ld	s2,0(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret

0000000080002d7e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d7e:	1101                	addi	sp,sp,-32
    80002d80:	ec06                	sd	ra,24(sp)
    80002d82:	e822                	sd	s0,16(sp)
    80002d84:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d86:	fec40593          	addi	a1,s0,-20
    80002d8a:	4501                	li	a0,0
    80002d8c:	00000097          	auipc	ra,0x0
    80002d90:	f12080e7          	jalr	-238(ra) # 80002c9e <argint>
    return -1;
    80002d94:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d96:	00054963          	bltz	a0,80002da8 <sys_exit+0x2a>
  exit(n);
    80002d9a:	fec42503          	lw	a0,-20(s0)
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	69a080e7          	jalr	1690(ra) # 80002438 <exit>
  return 0;  // not reached
    80002da6:	4781                	li	a5,0
}
    80002da8:	853e                	mv	a0,a5
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	6105                	addi	sp,sp,32
    80002db0:	8082                	ret

0000000080002db2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002db2:	1141                	addi	sp,sp,-16
    80002db4:	e406                	sd	ra,8(sp)
    80002db6:	e022                	sd	s0,0(sp)
    80002db8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	d66080e7          	jalr	-666(ra) # 80001b20 <myproc>
}
    80002dc2:	5908                	lw	a0,48(a0)
    80002dc4:	60a2                	ld	ra,8(sp)
    80002dc6:	6402                	ld	s0,0(sp)
    80002dc8:	0141                	addi	sp,sp,16
    80002dca:	8082                	ret

0000000080002dcc <sys_fork>:

uint64
sys_fork(void)
{
    80002dcc:	1141                	addi	sp,sp,-16
    80002dce:	e406                	sd	ra,8(sp)
    80002dd0:	e022                	sd	s0,0(sp)
    80002dd2:	0800                	addi	s0,sp,16
  return fork();
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	11a080e7          	jalr	282(ra) # 80001eee <fork>
}
    80002ddc:	60a2                	ld	ra,8(sp)
    80002dde:	6402                	ld	s0,0(sp)
    80002de0:	0141                	addi	sp,sp,16
    80002de2:	8082                	ret

0000000080002de4 <sys_wait>:

uint64
sys_wait(void)
{
    80002de4:	1101                	addi	sp,sp,-32
    80002de6:	ec06                	sd	ra,24(sp)
    80002de8:	e822                	sd	s0,16(sp)
    80002dea:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dec:	fe840593          	addi	a1,s0,-24
    80002df0:	4501                	li	a0,0
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	ece080e7          	jalr	-306(ra) # 80002cc0 <argaddr>
    80002dfa:	87aa                	mv	a5,a0
    return -1;
    80002dfc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dfe:	0007c863          	bltz	a5,80002e0e <sys_wait+0x2a>
  return wait(p);
    80002e02:	fe843503          	ld	a0,-24(s0)
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	43a080e7          	jalr	1082(ra) # 80002240 <wait>
}
    80002e0e:	60e2                	ld	ra,24(sp)
    80002e10:	6442                	ld	s0,16(sp)
    80002e12:	6105                	addi	sp,sp,32
    80002e14:	8082                	ret

0000000080002e16 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e16:	7179                	addi	sp,sp,-48
    80002e18:	f406                	sd	ra,40(sp)
    80002e1a:	f022                	sd	s0,32(sp)
    80002e1c:	ec26                	sd	s1,24(sp)
    80002e1e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e20:	fdc40593          	addi	a1,s0,-36
    80002e24:	4501                	li	a0,0
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	e78080e7          	jalr	-392(ra) # 80002c9e <argint>
    80002e2e:	87aa                	mv	a5,a0
    return -1;
    80002e30:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e32:	0207c063          	bltz	a5,80002e52 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	cea080e7          	jalr	-790(ra) # 80001b20 <myproc>
    80002e3e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e40:	fdc42503          	lw	a0,-36(s0)
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	036080e7          	jalr	54(ra) # 80001e7a <growproc>
    80002e4c:	00054863          	bltz	a0,80002e5c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e50:	8526                	mv	a0,s1
}
    80002e52:	70a2                	ld	ra,40(sp)
    80002e54:	7402                	ld	s0,32(sp)
    80002e56:	64e2                	ld	s1,24(sp)
    80002e58:	6145                	addi	sp,sp,48
    80002e5a:	8082                	ret
    return -1;
    80002e5c:	557d                	li	a0,-1
    80002e5e:	bfd5                	j	80002e52 <sys_sbrk+0x3c>

0000000080002e60 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e60:	7139                	addi	sp,sp,-64
    80002e62:	fc06                	sd	ra,56(sp)
    80002e64:	f822                	sd	s0,48(sp)
    80002e66:	f426                	sd	s1,40(sp)
    80002e68:	f04a                	sd	s2,32(sp)
    80002e6a:	ec4e                	sd	s3,24(sp)
    80002e6c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e6e:	fcc40593          	addi	a1,s0,-52
    80002e72:	4501                	li	a0,0
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	e2a080e7          	jalr	-470(ra) # 80002c9e <argint>
    return -1;
    80002e7c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e7e:	06054563          	bltz	a0,80002ee8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e82:	00054517          	auipc	a0,0x54
    80002e86:	24e50513          	addi	a0,a0,590 # 800570d0 <tickslock>
    80002e8a:	ffffe097          	auipc	ra,0xffffe
    80002e8e:	ea4080e7          	jalr	-348(ra) # 80000d2e <acquire>
  ticks0 = ticks;
    80002e92:	00006917          	auipc	s2,0x6
    80002e96:	19e92903          	lw	s2,414(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e9a:	fcc42783          	lw	a5,-52(s0)
    80002e9e:	cf85                	beqz	a5,80002ed6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ea0:	00054997          	auipc	s3,0x54
    80002ea4:	23098993          	addi	s3,s3,560 # 800570d0 <tickslock>
    80002ea8:	00006497          	auipc	s1,0x6
    80002eac:	18848493          	addi	s1,s1,392 # 80009030 <ticks>
    if(myproc()->killed){
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	c70080e7          	jalr	-912(ra) # 80001b20 <myproc>
    80002eb8:	551c                	lw	a5,40(a0)
    80002eba:	ef9d                	bnez	a5,80002ef8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ebc:	85ce                	mv	a1,s3
    80002ebe:	8526                	mv	a0,s1
    80002ec0:	fffff097          	auipc	ra,0xfffff
    80002ec4:	31c080e7          	jalr	796(ra) # 800021dc <sleep>
  while(ticks - ticks0 < n){
    80002ec8:	409c                	lw	a5,0(s1)
    80002eca:	412787bb          	subw	a5,a5,s2
    80002ece:	fcc42703          	lw	a4,-52(s0)
    80002ed2:	fce7efe3          	bltu	a5,a4,80002eb0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ed6:	00054517          	auipc	a0,0x54
    80002eda:	1fa50513          	addi	a0,a0,506 # 800570d0 <tickslock>
    80002ede:	ffffe097          	auipc	ra,0xffffe
    80002ee2:	f04080e7          	jalr	-252(ra) # 80000de2 <release>
  return 0;
    80002ee6:	4781                	li	a5,0
}
    80002ee8:	853e                	mv	a0,a5
    80002eea:	70e2                	ld	ra,56(sp)
    80002eec:	7442                	ld	s0,48(sp)
    80002eee:	74a2                	ld	s1,40(sp)
    80002ef0:	7902                	ld	s2,32(sp)
    80002ef2:	69e2                	ld	s3,24(sp)
    80002ef4:	6121                	addi	sp,sp,64
    80002ef6:	8082                	ret
      release(&tickslock);
    80002ef8:	00054517          	auipc	a0,0x54
    80002efc:	1d850513          	addi	a0,a0,472 # 800570d0 <tickslock>
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	ee2080e7          	jalr	-286(ra) # 80000de2 <release>
      return -1;
    80002f08:	57fd                	li	a5,-1
    80002f0a:	bff9                	j	80002ee8 <sys_sleep+0x88>

0000000080002f0c <sys_kill>:

uint64
sys_kill(void)
{
    80002f0c:	1101                	addi	sp,sp,-32
    80002f0e:	ec06                	sd	ra,24(sp)
    80002f10:	e822                	sd	s0,16(sp)
    80002f12:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f14:	fec40593          	addi	a1,s0,-20
    80002f18:	4501                	li	a0,0
    80002f1a:	00000097          	auipc	ra,0x0
    80002f1e:	d84080e7          	jalr	-636(ra) # 80002c9e <argint>
    80002f22:	87aa                	mv	a5,a0
    return -1;
    80002f24:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f26:	0007c863          	bltz	a5,80002f36 <sys_kill+0x2a>
  return kill(pid);
    80002f2a:	fec42503          	lw	a0,-20(s0)
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	5e0080e7          	jalr	1504(ra) # 8000250e <kill>
}
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret

0000000080002f3e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	e426                	sd	s1,8(sp)
    80002f46:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f48:	00054517          	auipc	a0,0x54
    80002f4c:	18850513          	addi	a0,a0,392 # 800570d0 <tickslock>
    80002f50:	ffffe097          	auipc	ra,0xffffe
    80002f54:	dde080e7          	jalr	-546(ra) # 80000d2e <acquire>
  xticks = ticks;
    80002f58:	00006497          	auipc	s1,0x6
    80002f5c:	0d84a483          	lw	s1,216(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f60:	00054517          	auipc	a0,0x54
    80002f64:	17050513          	addi	a0,a0,368 # 800570d0 <tickslock>
    80002f68:	ffffe097          	auipc	ra,0xffffe
    80002f6c:	e7a080e7          	jalr	-390(ra) # 80000de2 <release>
  return xticks;
}
    80002f70:	02049513          	slli	a0,s1,0x20
    80002f74:	9101                	srli	a0,a0,0x20
    80002f76:	60e2                	ld	ra,24(sp)
    80002f78:	6442                	ld	s0,16(sp)
    80002f7a:	64a2                	ld	s1,8(sp)
    80002f7c:	6105                	addi	sp,sp,32
    80002f7e:	8082                	ret

0000000080002f80 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f80:	7179                	addi	sp,sp,-48
    80002f82:	f406                	sd	ra,40(sp)
    80002f84:	f022                	sd	s0,32(sp)
    80002f86:	ec26                	sd	s1,24(sp)
    80002f88:	e84a                	sd	s2,16(sp)
    80002f8a:	e44e                	sd	s3,8(sp)
    80002f8c:	e052                	sd	s4,0(sp)
    80002f8e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f90:	00005597          	auipc	a1,0x5
    80002f94:	5c058593          	addi	a1,a1,1472 # 80008550 <syscalls+0xb0>
    80002f98:	00054517          	auipc	a0,0x54
    80002f9c:	15050513          	addi	a0,a0,336 # 800570e8 <bcache>
    80002fa0:	ffffe097          	auipc	ra,0xffffe
    80002fa4:	cfe080e7          	jalr	-770(ra) # 80000c9e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fa8:	0005c797          	auipc	a5,0x5c
    80002fac:	14078793          	addi	a5,a5,320 # 8005f0e8 <bcache+0x8000>
    80002fb0:	0005c717          	auipc	a4,0x5c
    80002fb4:	3a070713          	addi	a4,a4,928 # 8005f350 <bcache+0x8268>
    80002fb8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fbc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fc0:	00054497          	auipc	s1,0x54
    80002fc4:	14048493          	addi	s1,s1,320 # 80057100 <bcache+0x18>
    b->next = bcache.head.next;
    80002fc8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fca:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fcc:	00005a17          	auipc	s4,0x5
    80002fd0:	58ca0a13          	addi	s4,s4,1420 # 80008558 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002fd4:	2b893783          	ld	a5,696(s2)
    80002fd8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fda:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fde:	85d2                	mv	a1,s4
    80002fe0:	01048513          	addi	a0,s1,16
    80002fe4:	00001097          	auipc	ra,0x1
    80002fe8:	4bc080e7          	jalr	1212(ra) # 800044a0 <initsleeplock>
    bcache.head.next->prev = b;
    80002fec:	2b893783          	ld	a5,696(s2)
    80002ff0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ff2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ff6:	45848493          	addi	s1,s1,1112
    80002ffa:	fd349de3          	bne	s1,s3,80002fd4 <binit+0x54>
  }
}
    80002ffe:	70a2                	ld	ra,40(sp)
    80003000:	7402                	ld	s0,32(sp)
    80003002:	64e2                	ld	s1,24(sp)
    80003004:	6942                	ld	s2,16(sp)
    80003006:	69a2                	ld	s3,8(sp)
    80003008:	6a02                	ld	s4,0(sp)
    8000300a:	6145                	addi	sp,sp,48
    8000300c:	8082                	ret

000000008000300e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000300e:	7179                	addi	sp,sp,-48
    80003010:	f406                	sd	ra,40(sp)
    80003012:	f022                	sd	s0,32(sp)
    80003014:	ec26                	sd	s1,24(sp)
    80003016:	e84a                	sd	s2,16(sp)
    80003018:	e44e                	sd	s3,8(sp)
    8000301a:	1800                	addi	s0,sp,48
    8000301c:	89aa                	mv	s3,a0
    8000301e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003020:	00054517          	auipc	a0,0x54
    80003024:	0c850513          	addi	a0,a0,200 # 800570e8 <bcache>
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	d06080e7          	jalr	-762(ra) # 80000d2e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003030:	0005c497          	auipc	s1,0x5c
    80003034:	3704b483          	ld	s1,880(s1) # 8005f3a0 <bcache+0x82b8>
    80003038:	0005c797          	auipc	a5,0x5c
    8000303c:	31878793          	addi	a5,a5,792 # 8005f350 <bcache+0x8268>
    80003040:	02f48f63          	beq	s1,a5,8000307e <bread+0x70>
    80003044:	873e                	mv	a4,a5
    80003046:	a021                	j	8000304e <bread+0x40>
    80003048:	68a4                	ld	s1,80(s1)
    8000304a:	02e48a63          	beq	s1,a4,8000307e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000304e:	449c                	lw	a5,8(s1)
    80003050:	ff379ce3          	bne	a5,s3,80003048 <bread+0x3a>
    80003054:	44dc                	lw	a5,12(s1)
    80003056:	ff2799e3          	bne	a5,s2,80003048 <bread+0x3a>
      b->refcnt++;
    8000305a:	40bc                	lw	a5,64(s1)
    8000305c:	2785                	addiw	a5,a5,1
    8000305e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003060:	00054517          	auipc	a0,0x54
    80003064:	08850513          	addi	a0,a0,136 # 800570e8 <bcache>
    80003068:	ffffe097          	auipc	ra,0xffffe
    8000306c:	d7a080e7          	jalr	-646(ra) # 80000de2 <release>
      acquiresleep(&b->lock);
    80003070:	01048513          	addi	a0,s1,16
    80003074:	00001097          	auipc	ra,0x1
    80003078:	466080e7          	jalr	1126(ra) # 800044da <acquiresleep>
      return b;
    8000307c:	a8b9                	j	800030da <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000307e:	0005c497          	auipc	s1,0x5c
    80003082:	31a4b483          	ld	s1,794(s1) # 8005f398 <bcache+0x82b0>
    80003086:	0005c797          	auipc	a5,0x5c
    8000308a:	2ca78793          	addi	a5,a5,714 # 8005f350 <bcache+0x8268>
    8000308e:	00f48863          	beq	s1,a5,8000309e <bread+0x90>
    80003092:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003094:	40bc                	lw	a5,64(s1)
    80003096:	cf81                	beqz	a5,800030ae <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003098:	64a4                	ld	s1,72(s1)
    8000309a:	fee49de3          	bne	s1,a4,80003094 <bread+0x86>
  panic("bget: no buffers");
    8000309e:	00005517          	auipc	a0,0x5
    800030a2:	4c250513          	addi	a0,a0,1218 # 80008560 <syscalls+0xc0>
    800030a6:	ffffd097          	auipc	ra,0xffffd
    800030aa:	498080e7          	jalr	1176(ra) # 8000053e <panic>
      b->dev = dev;
    800030ae:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030b2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030b6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030ba:	4785                	li	a5,1
    800030bc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030be:	00054517          	auipc	a0,0x54
    800030c2:	02a50513          	addi	a0,a0,42 # 800570e8 <bcache>
    800030c6:	ffffe097          	auipc	ra,0xffffe
    800030ca:	d1c080e7          	jalr	-740(ra) # 80000de2 <release>
      acquiresleep(&b->lock);
    800030ce:	01048513          	addi	a0,s1,16
    800030d2:	00001097          	auipc	ra,0x1
    800030d6:	408080e7          	jalr	1032(ra) # 800044da <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030da:	409c                	lw	a5,0(s1)
    800030dc:	cb89                	beqz	a5,800030ee <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030de:	8526                	mv	a0,s1
    800030e0:	70a2                	ld	ra,40(sp)
    800030e2:	7402                	ld	s0,32(sp)
    800030e4:	64e2                	ld	s1,24(sp)
    800030e6:	6942                	ld	s2,16(sp)
    800030e8:	69a2                	ld	s3,8(sp)
    800030ea:	6145                	addi	sp,sp,48
    800030ec:	8082                	ret
    virtio_disk_rw(b, 0);
    800030ee:	4581                	li	a1,0
    800030f0:	8526                	mv	a0,s1
    800030f2:	00003097          	auipc	ra,0x3
    800030f6:	f14080e7          	jalr	-236(ra) # 80006006 <virtio_disk_rw>
    b->valid = 1;
    800030fa:	4785                	li	a5,1
    800030fc:	c09c                	sw	a5,0(s1)
  return b;
    800030fe:	b7c5                	j	800030de <bread+0xd0>

0000000080003100 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003100:	1101                	addi	sp,sp,-32
    80003102:	ec06                	sd	ra,24(sp)
    80003104:	e822                	sd	s0,16(sp)
    80003106:	e426                	sd	s1,8(sp)
    80003108:	1000                	addi	s0,sp,32
    8000310a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000310c:	0541                	addi	a0,a0,16
    8000310e:	00001097          	auipc	ra,0x1
    80003112:	466080e7          	jalr	1126(ra) # 80004574 <holdingsleep>
    80003116:	cd01                	beqz	a0,8000312e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003118:	4585                	li	a1,1
    8000311a:	8526                	mv	a0,s1
    8000311c:	00003097          	auipc	ra,0x3
    80003120:	eea080e7          	jalr	-278(ra) # 80006006 <virtio_disk_rw>
}
    80003124:	60e2                	ld	ra,24(sp)
    80003126:	6442                	ld	s0,16(sp)
    80003128:	64a2                	ld	s1,8(sp)
    8000312a:	6105                	addi	sp,sp,32
    8000312c:	8082                	ret
    panic("bwrite");
    8000312e:	00005517          	auipc	a0,0x5
    80003132:	44a50513          	addi	a0,a0,1098 # 80008578 <syscalls+0xd8>
    80003136:	ffffd097          	auipc	ra,0xffffd
    8000313a:	408080e7          	jalr	1032(ra) # 8000053e <panic>

000000008000313e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000313e:	1101                	addi	sp,sp,-32
    80003140:	ec06                	sd	ra,24(sp)
    80003142:	e822                	sd	s0,16(sp)
    80003144:	e426                	sd	s1,8(sp)
    80003146:	e04a                	sd	s2,0(sp)
    80003148:	1000                	addi	s0,sp,32
    8000314a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000314c:	01050913          	addi	s2,a0,16
    80003150:	854a                	mv	a0,s2
    80003152:	00001097          	auipc	ra,0x1
    80003156:	422080e7          	jalr	1058(ra) # 80004574 <holdingsleep>
    8000315a:	c92d                	beqz	a0,800031cc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000315c:	854a                	mv	a0,s2
    8000315e:	00001097          	auipc	ra,0x1
    80003162:	3d2080e7          	jalr	978(ra) # 80004530 <releasesleep>

  acquire(&bcache.lock);
    80003166:	00054517          	auipc	a0,0x54
    8000316a:	f8250513          	addi	a0,a0,-126 # 800570e8 <bcache>
    8000316e:	ffffe097          	auipc	ra,0xffffe
    80003172:	bc0080e7          	jalr	-1088(ra) # 80000d2e <acquire>
  b->refcnt--;
    80003176:	40bc                	lw	a5,64(s1)
    80003178:	37fd                	addiw	a5,a5,-1
    8000317a:	0007871b          	sext.w	a4,a5
    8000317e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003180:	eb05                	bnez	a4,800031b0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003182:	68bc                	ld	a5,80(s1)
    80003184:	64b8                	ld	a4,72(s1)
    80003186:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003188:	64bc                	ld	a5,72(s1)
    8000318a:	68b8                	ld	a4,80(s1)
    8000318c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000318e:	0005c797          	auipc	a5,0x5c
    80003192:	f5a78793          	addi	a5,a5,-166 # 8005f0e8 <bcache+0x8000>
    80003196:	2b87b703          	ld	a4,696(a5)
    8000319a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000319c:	0005c717          	auipc	a4,0x5c
    800031a0:	1b470713          	addi	a4,a4,436 # 8005f350 <bcache+0x8268>
    800031a4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031a6:	2b87b703          	ld	a4,696(a5)
    800031aa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031ac:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031b0:	00054517          	auipc	a0,0x54
    800031b4:	f3850513          	addi	a0,a0,-200 # 800570e8 <bcache>
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	c2a080e7          	jalr	-982(ra) # 80000de2 <release>
}
    800031c0:	60e2                	ld	ra,24(sp)
    800031c2:	6442                	ld	s0,16(sp)
    800031c4:	64a2                	ld	s1,8(sp)
    800031c6:	6902                	ld	s2,0(sp)
    800031c8:	6105                	addi	sp,sp,32
    800031ca:	8082                	ret
    panic("brelse");
    800031cc:	00005517          	auipc	a0,0x5
    800031d0:	3b450513          	addi	a0,a0,948 # 80008580 <syscalls+0xe0>
    800031d4:	ffffd097          	auipc	ra,0xffffd
    800031d8:	36a080e7          	jalr	874(ra) # 8000053e <panic>

00000000800031dc <bpin>:

void
bpin(struct buf *b) {
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	1000                	addi	s0,sp,32
    800031e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031e8:	00054517          	auipc	a0,0x54
    800031ec:	f0050513          	addi	a0,a0,-256 # 800570e8 <bcache>
    800031f0:	ffffe097          	auipc	ra,0xffffe
    800031f4:	b3e080e7          	jalr	-1218(ra) # 80000d2e <acquire>
  b->refcnt++;
    800031f8:	40bc                	lw	a5,64(s1)
    800031fa:	2785                	addiw	a5,a5,1
    800031fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031fe:	00054517          	auipc	a0,0x54
    80003202:	eea50513          	addi	a0,a0,-278 # 800570e8 <bcache>
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	bdc080e7          	jalr	-1060(ra) # 80000de2 <release>
}
    8000320e:	60e2                	ld	ra,24(sp)
    80003210:	6442                	ld	s0,16(sp)
    80003212:	64a2                	ld	s1,8(sp)
    80003214:	6105                	addi	sp,sp,32
    80003216:	8082                	ret

0000000080003218 <bunpin>:

void
bunpin(struct buf *b) {
    80003218:	1101                	addi	sp,sp,-32
    8000321a:	ec06                	sd	ra,24(sp)
    8000321c:	e822                	sd	s0,16(sp)
    8000321e:	e426                	sd	s1,8(sp)
    80003220:	1000                	addi	s0,sp,32
    80003222:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003224:	00054517          	auipc	a0,0x54
    80003228:	ec450513          	addi	a0,a0,-316 # 800570e8 <bcache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	b02080e7          	jalr	-1278(ra) # 80000d2e <acquire>
  b->refcnt--;
    80003234:	40bc                	lw	a5,64(s1)
    80003236:	37fd                	addiw	a5,a5,-1
    80003238:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000323a:	00054517          	auipc	a0,0x54
    8000323e:	eae50513          	addi	a0,a0,-338 # 800570e8 <bcache>
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	ba0080e7          	jalr	-1120(ra) # 80000de2 <release>
}
    8000324a:	60e2                	ld	ra,24(sp)
    8000324c:	6442                	ld	s0,16(sp)
    8000324e:	64a2                	ld	s1,8(sp)
    80003250:	6105                	addi	sp,sp,32
    80003252:	8082                	ret

0000000080003254 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003254:	1101                	addi	sp,sp,-32
    80003256:	ec06                	sd	ra,24(sp)
    80003258:	e822                	sd	s0,16(sp)
    8000325a:	e426                	sd	s1,8(sp)
    8000325c:	e04a                	sd	s2,0(sp)
    8000325e:	1000                	addi	s0,sp,32
    80003260:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003262:	00d5d59b          	srliw	a1,a1,0xd
    80003266:	0005c797          	auipc	a5,0x5c
    8000326a:	55e7a783          	lw	a5,1374(a5) # 8005f7c4 <sb+0x1c>
    8000326e:	9dbd                	addw	a1,a1,a5
    80003270:	00000097          	auipc	ra,0x0
    80003274:	d9e080e7          	jalr	-610(ra) # 8000300e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003278:	0074f713          	andi	a4,s1,7
    8000327c:	4785                	li	a5,1
    8000327e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003282:	14ce                	slli	s1,s1,0x33
    80003284:	90d9                	srli	s1,s1,0x36
    80003286:	00950733          	add	a4,a0,s1
    8000328a:	05874703          	lbu	a4,88(a4)
    8000328e:	00e7f6b3          	and	a3,a5,a4
    80003292:	c69d                	beqz	a3,800032c0 <bfree+0x6c>
    80003294:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003296:	94aa                	add	s1,s1,a0
    80003298:	fff7c793          	not	a5,a5
    8000329c:	8ff9                	and	a5,a5,a4
    8000329e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032a2:	00001097          	auipc	ra,0x1
    800032a6:	118080e7          	jalr	280(ra) # 800043ba <log_write>
  brelse(bp);
    800032aa:	854a                	mv	a0,s2
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	e92080e7          	jalr	-366(ra) # 8000313e <brelse>
}
    800032b4:	60e2                	ld	ra,24(sp)
    800032b6:	6442                	ld	s0,16(sp)
    800032b8:	64a2                	ld	s1,8(sp)
    800032ba:	6902                	ld	s2,0(sp)
    800032bc:	6105                	addi	sp,sp,32
    800032be:	8082                	ret
    panic("freeing free block");
    800032c0:	00005517          	auipc	a0,0x5
    800032c4:	2c850513          	addi	a0,a0,712 # 80008588 <syscalls+0xe8>
    800032c8:	ffffd097          	auipc	ra,0xffffd
    800032cc:	276080e7          	jalr	630(ra) # 8000053e <panic>

00000000800032d0 <balloc>:
{
    800032d0:	711d                	addi	sp,sp,-96
    800032d2:	ec86                	sd	ra,88(sp)
    800032d4:	e8a2                	sd	s0,80(sp)
    800032d6:	e4a6                	sd	s1,72(sp)
    800032d8:	e0ca                	sd	s2,64(sp)
    800032da:	fc4e                	sd	s3,56(sp)
    800032dc:	f852                	sd	s4,48(sp)
    800032de:	f456                	sd	s5,40(sp)
    800032e0:	f05a                	sd	s6,32(sp)
    800032e2:	ec5e                	sd	s7,24(sp)
    800032e4:	e862                	sd	s8,16(sp)
    800032e6:	e466                	sd	s9,8(sp)
    800032e8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032ea:	0005c797          	auipc	a5,0x5c
    800032ee:	4c27a783          	lw	a5,1218(a5) # 8005f7ac <sb+0x4>
    800032f2:	cbd1                	beqz	a5,80003386 <balloc+0xb6>
    800032f4:	8baa                	mv	s7,a0
    800032f6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032f8:	0005cb17          	auipc	s6,0x5c
    800032fc:	4b0b0b13          	addi	s6,s6,1200 # 8005f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003300:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003302:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003304:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003306:	6c89                	lui	s9,0x2
    80003308:	a831                	j	80003324 <balloc+0x54>
    brelse(bp);
    8000330a:	854a                	mv	a0,s2
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	e32080e7          	jalr	-462(ra) # 8000313e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003314:	015c87bb          	addw	a5,s9,s5
    80003318:	00078a9b          	sext.w	s5,a5
    8000331c:	004b2703          	lw	a4,4(s6)
    80003320:	06eaf363          	bgeu	s5,a4,80003386 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003324:	41fad79b          	sraiw	a5,s5,0x1f
    80003328:	0137d79b          	srliw	a5,a5,0x13
    8000332c:	015787bb          	addw	a5,a5,s5
    80003330:	40d7d79b          	sraiw	a5,a5,0xd
    80003334:	01cb2583          	lw	a1,28(s6)
    80003338:	9dbd                	addw	a1,a1,a5
    8000333a:	855e                	mv	a0,s7
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	cd2080e7          	jalr	-814(ra) # 8000300e <bread>
    80003344:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003346:	004b2503          	lw	a0,4(s6)
    8000334a:	000a849b          	sext.w	s1,s5
    8000334e:	8662                	mv	a2,s8
    80003350:	faa4fde3          	bgeu	s1,a0,8000330a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003354:	41f6579b          	sraiw	a5,a2,0x1f
    80003358:	01d7d69b          	srliw	a3,a5,0x1d
    8000335c:	00c6873b          	addw	a4,a3,a2
    80003360:	00777793          	andi	a5,a4,7
    80003364:	9f95                	subw	a5,a5,a3
    80003366:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000336a:	4037571b          	sraiw	a4,a4,0x3
    8000336e:	00e906b3          	add	a3,s2,a4
    80003372:	0586c683          	lbu	a3,88(a3)
    80003376:	00d7f5b3          	and	a1,a5,a3
    8000337a:	cd91                	beqz	a1,80003396 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000337c:	2605                	addiw	a2,a2,1
    8000337e:	2485                	addiw	s1,s1,1
    80003380:	fd4618e3          	bne	a2,s4,80003350 <balloc+0x80>
    80003384:	b759                	j	8000330a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003386:	00005517          	auipc	a0,0x5
    8000338a:	21a50513          	addi	a0,a0,538 # 800085a0 <syscalls+0x100>
    8000338e:	ffffd097          	auipc	ra,0xffffd
    80003392:	1b0080e7          	jalr	432(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003396:	974a                	add	a4,a4,s2
    80003398:	8fd5                	or	a5,a5,a3
    8000339a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000339e:	854a                	mv	a0,s2
    800033a0:	00001097          	auipc	ra,0x1
    800033a4:	01a080e7          	jalr	26(ra) # 800043ba <log_write>
        brelse(bp);
    800033a8:	854a                	mv	a0,s2
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	d94080e7          	jalr	-620(ra) # 8000313e <brelse>
  bp = bread(dev, bno);
    800033b2:	85a6                	mv	a1,s1
    800033b4:	855e                	mv	a0,s7
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	c58080e7          	jalr	-936(ra) # 8000300e <bread>
    800033be:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033c0:	40000613          	li	a2,1024
    800033c4:	4581                	li	a1,0
    800033c6:	05850513          	addi	a0,a0,88
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	a60080e7          	jalr	-1440(ra) # 80000e2a <memset>
  log_write(bp);
    800033d2:	854a                	mv	a0,s2
    800033d4:	00001097          	auipc	ra,0x1
    800033d8:	fe6080e7          	jalr	-26(ra) # 800043ba <log_write>
  brelse(bp);
    800033dc:	854a                	mv	a0,s2
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	d60080e7          	jalr	-672(ra) # 8000313e <brelse>
}
    800033e6:	8526                	mv	a0,s1
    800033e8:	60e6                	ld	ra,88(sp)
    800033ea:	6446                	ld	s0,80(sp)
    800033ec:	64a6                	ld	s1,72(sp)
    800033ee:	6906                	ld	s2,64(sp)
    800033f0:	79e2                	ld	s3,56(sp)
    800033f2:	7a42                	ld	s4,48(sp)
    800033f4:	7aa2                	ld	s5,40(sp)
    800033f6:	7b02                	ld	s6,32(sp)
    800033f8:	6be2                	ld	s7,24(sp)
    800033fa:	6c42                	ld	s8,16(sp)
    800033fc:	6ca2                	ld	s9,8(sp)
    800033fe:	6125                	addi	sp,sp,96
    80003400:	8082                	ret

0000000080003402 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003402:	7179                	addi	sp,sp,-48
    80003404:	f406                	sd	ra,40(sp)
    80003406:	f022                	sd	s0,32(sp)
    80003408:	ec26                	sd	s1,24(sp)
    8000340a:	e84a                	sd	s2,16(sp)
    8000340c:	e44e                	sd	s3,8(sp)
    8000340e:	e052                	sd	s4,0(sp)
    80003410:	1800                	addi	s0,sp,48
    80003412:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003414:	47ad                	li	a5,11
    80003416:	04b7fe63          	bgeu	a5,a1,80003472 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000341a:	ff45849b          	addiw	s1,a1,-12
    8000341e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003422:	0ff00793          	li	a5,255
    80003426:	0ae7e363          	bltu	a5,a4,800034cc <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000342a:	08052583          	lw	a1,128(a0)
    8000342e:	c5ad                	beqz	a1,80003498 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003430:	00092503          	lw	a0,0(s2)
    80003434:	00000097          	auipc	ra,0x0
    80003438:	bda080e7          	jalr	-1062(ra) # 8000300e <bread>
    8000343c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000343e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003442:	02049593          	slli	a1,s1,0x20
    80003446:	9181                	srli	a1,a1,0x20
    80003448:	058a                	slli	a1,a1,0x2
    8000344a:	00b784b3          	add	s1,a5,a1
    8000344e:	0004a983          	lw	s3,0(s1)
    80003452:	04098d63          	beqz	s3,800034ac <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003456:	8552                	mv	a0,s4
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	ce6080e7          	jalr	-794(ra) # 8000313e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003460:	854e                	mv	a0,s3
    80003462:	70a2                	ld	ra,40(sp)
    80003464:	7402                	ld	s0,32(sp)
    80003466:	64e2                	ld	s1,24(sp)
    80003468:	6942                	ld	s2,16(sp)
    8000346a:	69a2                	ld	s3,8(sp)
    8000346c:	6a02                	ld	s4,0(sp)
    8000346e:	6145                	addi	sp,sp,48
    80003470:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003472:	02059493          	slli	s1,a1,0x20
    80003476:	9081                	srli	s1,s1,0x20
    80003478:	048a                	slli	s1,s1,0x2
    8000347a:	94aa                	add	s1,s1,a0
    8000347c:	0504a983          	lw	s3,80(s1)
    80003480:	fe0990e3          	bnez	s3,80003460 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003484:	4108                	lw	a0,0(a0)
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	e4a080e7          	jalr	-438(ra) # 800032d0 <balloc>
    8000348e:	0005099b          	sext.w	s3,a0
    80003492:	0534a823          	sw	s3,80(s1)
    80003496:	b7e9                	j	80003460 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003498:	4108                	lw	a0,0(a0)
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	e36080e7          	jalr	-458(ra) # 800032d0 <balloc>
    800034a2:	0005059b          	sext.w	a1,a0
    800034a6:	08b92023          	sw	a1,128(s2)
    800034aa:	b759                	j	80003430 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034ac:	00092503          	lw	a0,0(s2)
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	e20080e7          	jalr	-480(ra) # 800032d0 <balloc>
    800034b8:	0005099b          	sext.w	s3,a0
    800034bc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034c0:	8552                	mv	a0,s4
    800034c2:	00001097          	auipc	ra,0x1
    800034c6:	ef8080e7          	jalr	-264(ra) # 800043ba <log_write>
    800034ca:	b771                	j	80003456 <bmap+0x54>
  panic("bmap: out of range");
    800034cc:	00005517          	auipc	a0,0x5
    800034d0:	0ec50513          	addi	a0,a0,236 # 800085b8 <syscalls+0x118>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	06a080e7          	jalr	106(ra) # 8000053e <panic>

00000000800034dc <iget>:
{
    800034dc:	7179                	addi	sp,sp,-48
    800034de:	f406                	sd	ra,40(sp)
    800034e0:	f022                	sd	s0,32(sp)
    800034e2:	ec26                	sd	s1,24(sp)
    800034e4:	e84a                	sd	s2,16(sp)
    800034e6:	e44e                	sd	s3,8(sp)
    800034e8:	e052                	sd	s4,0(sp)
    800034ea:	1800                	addi	s0,sp,48
    800034ec:	89aa                	mv	s3,a0
    800034ee:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034f0:	0005c517          	auipc	a0,0x5c
    800034f4:	2d850513          	addi	a0,a0,728 # 8005f7c8 <itable>
    800034f8:	ffffe097          	auipc	ra,0xffffe
    800034fc:	836080e7          	jalr	-1994(ra) # 80000d2e <acquire>
  empty = 0;
    80003500:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003502:	0005c497          	auipc	s1,0x5c
    80003506:	2de48493          	addi	s1,s1,734 # 8005f7e0 <itable+0x18>
    8000350a:	0005e697          	auipc	a3,0x5e
    8000350e:	d6668693          	addi	a3,a3,-666 # 80061270 <log>
    80003512:	a039                	j	80003520 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003514:	02090b63          	beqz	s2,8000354a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003518:	08848493          	addi	s1,s1,136
    8000351c:	02d48a63          	beq	s1,a3,80003550 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003520:	449c                	lw	a5,8(s1)
    80003522:	fef059e3          	blez	a5,80003514 <iget+0x38>
    80003526:	4098                	lw	a4,0(s1)
    80003528:	ff3716e3          	bne	a4,s3,80003514 <iget+0x38>
    8000352c:	40d8                	lw	a4,4(s1)
    8000352e:	ff4713e3          	bne	a4,s4,80003514 <iget+0x38>
      ip->ref++;
    80003532:	2785                	addiw	a5,a5,1
    80003534:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003536:	0005c517          	auipc	a0,0x5c
    8000353a:	29250513          	addi	a0,a0,658 # 8005f7c8 <itable>
    8000353e:	ffffe097          	auipc	ra,0xffffe
    80003542:	8a4080e7          	jalr	-1884(ra) # 80000de2 <release>
      return ip;
    80003546:	8926                	mv	s2,s1
    80003548:	a03d                	j	80003576 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000354a:	f7f9                	bnez	a5,80003518 <iget+0x3c>
    8000354c:	8926                	mv	s2,s1
    8000354e:	b7e9                	j	80003518 <iget+0x3c>
  if(empty == 0)
    80003550:	02090c63          	beqz	s2,80003588 <iget+0xac>
  ip->dev = dev;
    80003554:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003558:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000355c:	4785                	li	a5,1
    8000355e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003562:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003566:	0005c517          	auipc	a0,0x5c
    8000356a:	26250513          	addi	a0,a0,610 # 8005f7c8 <itable>
    8000356e:	ffffe097          	auipc	ra,0xffffe
    80003572:	874080e7          	jalr	-1932(ra) # 80000de2 <release>
}
    80003576:	854a                	mv	a0,s2
    80003578:	70a2                	ld	ra,40(sp)
    8000357a:	7402                	ld	s0,32(sp)
    8000357c:	64e2                	ld	s1,24(sp)
    8000357e:	6942                	ld	s2,16(sp)
    80003580:	69a2                	ld	s3,8(sp)
    80003582:	6a02                	ld	s4,0(sp)
    80003584:	6145                	addi	sp,sp,48
    80003586:	8082                	ret
    panic("iget: no inodes");
    80003588:	00005517          	auipc	a0,0x5
    8000358c:	04850513          	addi	a0,a0,72 # 800085d0 <syscalls+0x130>
    80003590:	ffffd097          	auipc	ra,0xffffd
    80003594:	fae080e7          	jalr	-82(ra) # 8000053e <panic>

0000000080003598 <fsinit>:
fsinit(int dev) {
    80003598:	7179                	addi	sp,sp,-48
    8000359a:	f406                	sd	ra,40(sp)
    8000359c:	f022                	sd	s0,32(sp)
    8000359e:	ec26                	sd	s1,24(sp)
    800035a0:	e84a                	sd	s2,16(sp)
    800035a2:	e44e                	sd	s3,8(sp)
    800035a4:	1800                	addi	s0,sp,48
    800035a6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035a8:	4585                	li	a1,1
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	a64080e7          	jalr	-1436(ra) # 8000300e <bread>
    800035b2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035b4:	0005c997          	auipc	s3,0x5c
    800035b8:	1f498993          	addi	s3,s3,500 # 8005f7a8 <sb>
    800035bc:	02000613          	li	a2,32
    800035c0:	05850593          	addi	a1,a0,88
    800035c4:	854e                	mv	a0,s3
    800035c6:	ffffe097          	auipc	ra,0xffffe
    800035ca:	8c4080e7          	jalr	-1852(ra) # 80000e8a <memmove>
  brelse(bp);
    800035ce:	8526                	mv	a0,s1
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	b6e080e7          	jalr	-1170(ra) # 8000313e <brelse>
  if(sb.magic != FSMAGIC)
    800035d8:	0009a703          	lw	a4,0(s3)
    800035dc:	102037b7          	lui	a5,0x10203
    800035e0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035e4:	02f71263          	bne	a4,a5,80003608 <fsinit+0x70>
  initlog(dev, &sb);
    800035e8:	0005c597          	auipc	a1,0x5c
    800035ec:	1c058593          	addi	a1,a1,448 # 8005f7a8 <sb>
    800035f0:	854a                	mv	a0,s2
    800035f2:	00001097          	auipc	ra,0x1
    800035f6:	b4c080e7          	jalr	-1204(ra) # 8000413e <initlog>
}
    800035fa:	70a2                	ld	ra,40(sp)
    800035fc:	7402                	ld	s0,32(sp)
    800035fe:	64e2                	ld	s1,24(sp)
    80003600:	6942                	ld	s2,16(sp)
    80003602:	69a2                	ld	s3,8(sp)
    80003604:	6145                	addi	sp,sp,48
    80003606:	8082                	ret
    panic("invalid file system");
    80003608:	00005517          	auipc	a0,0x5
    8000360c:	fd850513          	addi	a0,a0,-40 # 800085e0 <syscalls+0x140>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	f2e080e7          	jalr	-210(ra) # 8000053e <panic>

0000000080003618 <iinit>:
{
    80003618:	7179                	addi	sp,sp,-48
    8000361a:	f406                	sd	ra,40(sp)
    8000361c:	f022                	sd	s0,32(sp)
    8000361e:	ec26                	sd	s1,24(sp)
    80003620:	e84a                	sd	s2,16(sp)
    80003622:	e44e                	sd	s3,8(sp)
    80003624:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003626:	00005597          	auipc	a1,0x5
    8000362a:	fd258593          	addi	a1,a1,-46 # 800085f8 <syscalls+0x158>
    8000362e:	0005c517          	auipc	a0,0x5c
    80003632:	19a50513          	addi	a0,a0,410 # 8005f7c8 <itable>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	668080e7          	jalr	1640(ra) # 80000c9e <initlock>
  for(i = 0; i < NINODE; i++) {
    8000363e:	0005c497          	auipc	s1,0x5c
    80003642:	1b248493          	addi	s1,s1,434 # 8005f7f0 <itable+0x28>
    80003646:	0005e997          	auipc	s3,0x5e
    8000364a:	c3a98993          	addi	s3,s3,-966 # 80061280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000364e:	00005917          	auipc	s2,0x5
    80003652:	fb290913          	addi	s2,s2,-78 # 80008600 <syscalls+0x160>
    80003656:	85ca                	mv	a1,s2
    80003658:	8526                	mv	a0,s1
    8000365a:	00001097          	auipc	ra,0x1
    8000365e:	e46080e7          	jalr	-442(ra) # 800044a0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003662:	08848493          	addi	s1,s1,136
    80003666:	ff3498e3          	bne	s1,s3,80003656 <iinit+0x3e>
}
    8000366a:	70a2                	ld	ra,40(sp)
    8000366c:	7402                	ld	s0,32(sp)
    8000366e:	64e2                	ld	s1,24(sp)
    80003670:	6942                	ld	s2,16(sp)
    80003672:	69a2                	ld	s3,8(sp)
    80003674:	6145                	addi	sp,sp,48
    80003676:	8082                	ret

0000000080003678 <ialloc>:
{
    80003678:	715d                	addi	sp,sp,-80
    8000367a:	e486                	sd	ra,72(sp)
    8000367c:	e0a2                	sd	s0,64(sp)
    8000367e:	fc26                	sd	s1,56(sp)
    80003680:	f84a                	sd	s2,48(sp)
    80003682:	f44e                	sd	s3,40(sp)
    80003684:	f052                	sd	s4,32(sp)
    80003686:	ec56                	sd	s5,24(sp)
    80003688:	e85a                	sd	s6,16(sp)
    8000368a:	e45e                	sd	s7,8(sp)
    8000368c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000368e:	0005c717          	auipc	a4,0x5c
    80003692:	12672703          	lw	a4,294(a4) # 8005f7b4 <sb+0xc>
    80003696:	4785                	li	a5,1
    80003698:	04e7fa63          	bgeu	a5,a4,800036ec <ialloc+0x74>
    8000369c:	8aaa                	mv	s5,a0
    8000369e:	8bae                	mv	s7,a1
    800036a0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036a2:	0005ca17          	auipc	s4,0x5c
    800036a6:	106a0a13          	addi	s4,s4,262 # 8005f7a8 <sb>
    800036aa:	00048b1b          	sext.w	s6,s1
    800036ae:	0044d593          	srli	a1,s1,0x4
    800036b2:	018a2783          	lw	a5,24(s4)
    800036b6:	9dbd                	addw	a1,a1,a5
    800036b8:	8556                	mv	a0,s5
    800036ba:	00000097          	auipc	ra,0x0
    800036be:	954080e7          	jalr	-1708(ra) # 8000300e <bread>
    800036c2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036c4:	05850993          	addi	s3,a0,88
    800036c8:	00f4f793          	andi	a5,s1,15
    800036cc:	079a                	slli	a5,a5,0x6
    800036ce:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036d0:	00099783          	lh	a5,0(s3)
    800036d4:	c785                	beqz	a5,800036fc <ialloc+0x84>
    brelse(bp);
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	a68080e7          	jalr	-1432(ra) # 8000313e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036de:	0485                	addi	s1,s1,1
    800036e0:	00ca2703          	lw	a4,12(s4)
    800036e4:	0004879b          	sext.w	a5,s1
    800036e8:	fce7e1e3          	bltu	a5,a4,800036aa <ialloc+0x32>
  panic("ialloc: no inodes");
    800036ec:	00005517          	auipc	a0,0x5
    800036f0:	f1c50513          	addi	a0,a0,-228 # 80008608 <syscalls+0x168>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	e4a080e7          	jalr	-438(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800036fc:	04000613          	li	a2,64
    80003700:	4581                	li	a1,0
    80003702:	854e                	mv	a0,s3
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	726080e7          	jalr	1830(ra) # 80000e2a <memset>
      dip->type = type;
    8000370c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003710:	854a                	mv	a0,s2
    80003712:	00001097          	auipc	ra,0x1
    80003716:	ca8080e7          	jalr	-856(ra) # 800043ba <log_write>
      brelse(bp);
    8000371a:	854a                	mv	a0,s2
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	a22080e7          	jalr	-1502(ra) # 8000313e <brelse>
      return iget(dev, inum);
    80003724:	85da                	mv	a1,s6
    80003726:	8556                	mv	a0,s5
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	db4080e7          	jalr	-588(ra) # 800034dc <iget>
}
    80003730:	60a6                	ld	ra,72(sp)
    80003732:	6406                	ld	s0,64(sp)
    80003734:	74e2                	ld	s1,56(sp)
    80003736:	7942                	ld	s2,48(sp)
    80003738:	79a2                	ld	s3,40(sp)
    8000373a:	7a02                	ld	s4,32(sp)
    8000373c:	6ae2                	ld	s5,24(sp)
    8000373e:	6b42                	ld	s6,16(sp)
    80003740:	6ba2                	ld	s7,8(sp)
    80003742:	6161                	addi	sp,sp,80
    80003744:	8082                	ret

0000000080003746 <iupdate>:
{
    80003746:	1101                	addi	sp,sp,-32
    80003748:	ec06                	sd	ra,24(sp)
    8000374a:	e822                	sd	s0,16(sp)
    8000374c:	e426                	sd	s1,8(sp)
    8000374e:	e04a                	sd	s2,0(sp)
    80003750:	1000                	addi	s0,sp,32
    80003752:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003754:	415c                	lw	a5,4(a0)
    80003756:	0047d79b          	srliw	a5,a5,0x4
    8000375a:	0005c597          	auipc	a1,0x5c
    8000375e:	0665a583          	lw	a1,102(a1) # 8005f7c0 <sb+0x18>
    80003762:	9dbd                	addw	a1,a1,a5
    80003764:	4108                	lw	a0,0(a0)
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	8a8080e7          	jalr	-1880(ra) # 8000300e <bread>
    8000376e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003770:	05850793          	addi	a5,a0,88
    80003774:	40c8                	lw	a0,4(s1)
    80003776:	893d                	andi	a0,a0,15
    80003778:	051a                	slli	a0,a0,0x6
    8000377a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000377c:	04449703          	lh	a4,68(s1)
    80003780:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003784:	04649703          	lh	a4,70(s1)
    80003788:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000378c:	04849703          	lh	a4,72(s1)
    80003790:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003794:	04a49703          	lh	a4,74(s1)
    80003798:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000379c:	44f8                	lw	a4,76(s1)
    8000379e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037a0:	03400613          	li	a2,52
    800037a4:	05048593          	addi	a1,s1,80
    800037a8:	0531                	addi	a0,a0,12
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	6e0080e7          	jalr	1760(ra) # 80000e8a <memmove>
  log_write(bp);
    800037b2:	854a                	mv	a0,s2
    800037b4:	00001097          	auipc	ra,0x1
    800037b8:	c06080e7          	jalr	-1018(ra) # 800043ba <log_write>
  brelse(bp);
    800037bc:	854a                	mv	a0,s2
    800037be:	00000097          	auipc	ra,0x0
    800037c2:	980080e7          	jalr	-1664(ra) # 8000313e <brelse>
}
    800037c6:	60e2                	ld	ra,24(sp)
    800037c8:	6442                	ld	s0,16(sp)
    800037ca:	64a2                	ld	s1,8(sp)
    800037cc:	6902                	ld	s2,0(sp)
    800037ce:	6105                	addi	sp,sp,32
    800037d0:	8082                	ret

00000000800037d2 <idup>:
{
    800037d2:	1101                	addi	sp,sp,-32
    800037d4:	ec06                	sd	ra,24(sp)
    800037d6:	e822                	sd	s0,16(sp)
    800037d8:	e426                	sd	s1,8(sp)
    800037da:	1000                	addi	s0,sp,32
    800037dc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037de:	0005c517          	auipc	a0,0x5c
    800037e2:	fea50513          	addi	a0,a0,-22 # 8005f7c8 <itable>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	548080e7          	jalr	1352(ra) # 80000d2e <acquire>
  ip->ref++;
    800037ee:	449c                	lw	a5,8(s1)
    800037f0:	2785                	addiw	a5,a5,1
    800037f2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037f4:	0005c517          	auipc	a0,0x5c
    800037f8:	fd450513          	addi	a0,a0,-44 # 8005f7c8 <itable>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	5e6080e7          	jalr	1510(ra) # 80000de2 <release>
}
    80003804:	8526                	mv	a0,s1
    80003806:	60e2                	ld	ra,24(sp)
    80003808:	6442                	ld	s0,16(sp)
    8000380a:	64a2                	ld	s1,8(sp)
    8000380c:	6105                	addi	sp,sp,32
    8000380e:	8082                	ret

0000000080003810 <ilock>:
{
    80003810:	1101                	addi	sp,sp,-32
    80003812:	ec06                	sd	ra,24(sp)
    80003814:	e822                	sd	s0,16(sp)
    80003816:	e426                	sd	s1,8(sp)
    80003818:	e04a                	sd	s2,0(sp)
    8000381a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000381c:	c115                	beqz	a0,80003840 <ilock+0x30>
    8000381e:	84aa                	mv	s1,a0
    80003820:	451c                	lw	a5,8(a0)
    80003822:	00f05f63          	blez	a5,80003840 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003826:	0541                	addi	a0,a0,16
    80003828:	00001097          	auipc	ra,0x1
    8000382c:	cb2080e7          	jalr	-846(ra) # 800044da <acquiresleep>
  if(ip->valid == 0){
    80003830:	40bc                	lw	a5,64(s1)
    80003832:	cf99                	beqz	a5,80003850 <ilock+0x40>
}
    80003834:	60e2                	ld	ra,24(sp)
    80003836:	6442                	ld	s0,16(sp)
    80003838:	64a2                	ld	s1,8(sp)
    8000383a:	6902                	ld	s2,0(sp)
    8000383c:	6105                	addi	sp,sp,32
    8000383e:	8082                	ret
    panic("ilock");
    80003840:	00005517          	auipc	a0,0x5
    80003844:	de050513          	addi	a0,a0,-544 # 80008620 <syscalls+0x180>
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	cf6080e7          	jalr	-778(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003850:	40dc                	lw	a5,4(s1)
    80003852:	0047d79b          	srliw	a5,a5,0x4
    80003856:	0005c597          	auipc	a1,0x5c
    8000385a:	f6a5a583          	lw	a1,-150(a1) # 8005f7c0 <sb+0x18>
    8000385e:	9dbd                	addw	a1,a1,a5
    80003860:	4088                	lw	a0,0(s1)
    80003862:	fffff097          	auipc	ra,0xfffff
    80003866:	7ac080e7          	jalr	1964(ra) # 8000300e <bread>
    8000386a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000386c:	05850593          	addi	a1,a0,88
    80003870:	40dc                	lw	a5,4(s1)
    80003872:	8bbd                	andi	a5,a5,15
    80003874:	079a                	slli	a5,a5,0x6
    80003876:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003878:	00059783          	lh	a5,0(a1)
    8000387c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003880:	00259783          	lh	a5,2(a1)
    80003884:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003888:	00459783          	lh	a5,4(a1)
    8000388c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003890:	00659783          	lh	a5,6(a1)
    80003894:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003898:	459c                	lw	a5,8(a1)
    8000389a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000389c:	03400613          	li	a2,52
    800038a0:	05b1                	addi	a1,a1,12
    800038a2:	05048513          	addi	a0,s1,80
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	5e4080e7          	jalr	1508(ra) # 80000e8a <memmove>
    brelse(bp);
    800038ae:	854a                	mv	a0,s2
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	88e080e7          	jalr	-1906(ra) # 8000313e <brelse>
    ip->valid = 1;
    800038b8:	4785                	li	a5,1
    800038ba:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038bc:	04449783          	lh	a5,68(s1)
    800038c0:	fbb5                	bnez	a5,80003834 <ilock+0x24>
      panic("ilock: no type");
    800038c2:	00005517          	auipc	a0,0x5
    800038c6:	d6650513          	addi	a0,a0,-666 # 80008628 <syscalls+0x188>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	c74080e7          	jalr	-908(ra) # 8000053e <panic>

00000000800038d2 <iunlock>:
{
    800038d2:	1101                	addi	sp,sp,-32
    800038d4:	ec06                	sd	ra,24(sp)
    800038d6:	e822                	sd	s0,16(sp)
    800038d8:	e426                	sd	s1,8(sp)
    800038da:	e04a                	sd	s2,0(sp)
    800038dc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038de:	c905                	beqz	a0,8000390e <iunlock+0x3c>
    800038e0:	84aa                	mv	s1,a0
    800038e2:	01050913          	addi	s2,a0,16
    800038e6:	854a                	mv	a0,s2
    800038e8:	00001097          	auipc	ra,0x1
    800038ec:	c8c080e7          	jalr	-884(ra) # 80004574 <holdingsleep>
    800038f0:	cd19                	beqz	a0,8000390e <iunlock+0x3c>
    800038f2:	449c                	lw	a5,8(s1)
    800038f4:	00f05d63          	blez	a5,8000390e <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038f8:	854a                	mv	a0,s2
    800038fa:	00001097          	auipc	ra,0x1
    800038fe:	c36080e7          	jalr	-970(ra) # 80004530 <releasesleep>
}
    80003902:	60e2                	ld	ra,24(sp)
    80003904:	6442                	ld	s0,16(sp)
    80003906:	64a2                	ld	s1,8(sp)
    80003908:	6902                	ld	s2,0(sp)
    8000390a:	6105                	addi	sp,sp,32
    8000390c:	8082                	ret
    panic("iunlock");
    8000390e:	00005517          	auipc	a0,0x5
    80003912:	d2a50513          	addi	a0,a0,-726 # 80008638 <syscalls+0x198>
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	c28080e7          	jalr	-984(ra) # 8000053e <panic>

000000008000391e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000391e:	7179                	addi	sp,sp,-48
    80003920:	f406                	sd	ra,40(sp)
    80003922:	f022                	sd	s0,32(sp)
    80003924:	ec26                	sd	s1,24(sp)
    80003926:	e84a                	sd	s2,16(sp)
    80003928:	e44e                	sd	s3,8(sp)
    8000392a:	e052                	sd	s4,0(sp)
    8000392c:	1800                	addi	s0,sp,48
    8000392e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003930:	05050493          	addi	s1,a0,80
    80003934:	08050913          	addi	s2,a0,128
    80003938:	a021                	j	80003940 <itrunc+0x22>
    8000393a:	0491                	addi	s1,s1,4
    8000393c:	01248d63          	beq	s1,s2,80003956 <itrunc+0x38>
    if(ip->addrs[i]){
    80003940:	408c                	lw	a1,0(s1)
    80003942:	dde5                	beqz	a1,8000393a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003944:	0009a503          	lw	a0,0(s3)
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	90c080e7          	jalr	-1780(ra) # 80003254 <bfree>
      ip->addrs[i] = 0;
    80003950:	0004a023          	sw	zero,0(s1)
    80003954:	b7dd                	j	8000393a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003956:	0809a583          	lw	a1,128(s3)
    8000395a:	e185                	bnez	a1,8000397a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000395c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003960:	854e                	mv	a0,s3
    80003962:	00000097          	auipc	ra,0x0
    80003966:	de4080e7          	jalr	-540(ra) # 80003746 <iupdate>
}
    8000396a:	70a2                	ld	ra,40(sp)
    8000396c:	7402                	ld	s0,32(sp)
    8000396e:	64e2                	ld	s1,24(sp)
    80003970:	6942                	ld	s2,16(sp)
    80003972:	69a2                	ld	s3,8(sp)
    80003974:	6a02                	ld	s4,0(sp)
    80003976:	6145                	addi	sp,sp,48
    80003978:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000397a:	0009a503          	lw	a0,0(s3)
    8000397e:	fffff097          	auipc	ra,0xfffff
    80003982:	690080e7          	jalr	1680(ra) # 8000300e <bread>
    80003986:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003988:	05850493          	addi	s1,a0,88
    8000398c:	45850913          	addi	s2,a0,1112
    80003990:	a811                	j	800039a4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003992:	0009a503          	lw	a0,0(s3)
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	8be080e7          	jalr	-1858(ra) # 80003254 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000399e:	0491                	addi	s1,s1,4
    800039a0:	01248563          	beq	s1,s2,800039aa <itrunc+0x8c>
      if(a[j])
    800039a4:	408c                	lw	a1,0(s1)
    800039a6:	dde5                	beqz	a1,8000399e <itrunc+0x80>
    800039a8:	b7ed                	j	80003992 <itrunc+0x74>
    brelse(bp);
    800039aa:	8552                	mv	a0,s4
    800039ac:	fffff097          	auipc	ra,0xfffff
    800039b0:	792080e7          	jalr	1938(ra) # 8000313e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039b4:	0809a583          	lw	a1,128(s3)
    800039b8:	0009a503          	lw	a0,0(s3)
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	898080e7          	jalr	-1896(ra) # 80003254 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039c4:	0809a023          	sw	zero,128(s3)
    800039c8:	bf51                	j	8000395c <itrunc+0x3e>

00000000800039ca <iput>:
{
    800039ca:	1101                	addi	sp,sp,-32
    800039cc:	ec06                	sd	ra,24(sp)
    800039ce:	e822                	sd	s0,16(sp)
    800039d0:	e426                	sd	s1,8(sp)
    800039d2:	e04a                	sd	s2,0(sp)
    800039d4:	1000                	addi	s0,sp,32
    800039d6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039d8:	0005c517          	auipc	a0,0x5c
    800039dc:	df050513          	addi	a0,a0,-528 # 8005f7c8 <itable>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	34e080e7          	jalr	846(ra) # 80000d2e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039e8:	4498                	lw	a4,8(s1)
    800039ea:	4785                	li	a5,1
    800039ec:	02f70363          	beq	a4,a5,80003a12 <iput+0x48>
  ip->ref--;
    800039f0:	449c                	lw	a5,8(s1)
    800039f2:	37fd                	addiw	a5,a5,-1
    800039f4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039f6:	0005c517          	auipc	a0,0x5c
    800039fa:	dd250513          	addi	a0,a0,-558 # 8005f7c8 <itable>
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	3e4080e7          	jalr	996(ra) # 80000de2 <release>
}
    80003a06:	60e2                	ld	ra,24(sp)
    80003a08:	6442                	ld	s0,16(sp)
    80003a0a:	64a2                	ld	s1,8(sp)
    80003a0c:	6902                	ld	s2,0(sp)
    80003a0e:	6105                	addi	sp,sp,32
    80003a10:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a12:	40bc                	lw	a5,64(s1)
    80003a14:	dff1                	beqz	a5,800039f0 <iput+0x26>
    80003a16:	04a49783          	lh	a5,74(s1)
    80003a1a:	fbf9                	bnez	a5,800039f0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a1c:	01048913          	addi	s2,s1,16
    80003a20:	854a                	mv	a0,s2
    80003a22:	00001097          	auipc	ra,0x1
    80003a26:	ab8080e7          	jalr	-1352(ra) # 800044da <acquiresleep>
    release(&itable.lock);
    80003a2a:	0005c517          	auipc	a0,0x5c
    80003a2e:	d9e50513          	addi	a0,a0,-610 # 8005f7c8 <itable>
    80003a32:	ffffd097          	auipc	ra,0xffffd
    80003a36:	3b0080e7          	jalr	944(ra) # 80000de2 <release>
    itrunc(ip);
    80003a3a:	8526                	mv	a0,s1
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	ee2080e7          	jalr	-286(ra) # 8000391e <itrunc>
    ip->type = 0;
    80003a44:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a48:	8526                	mv	a0,s1
    80003a4a:	00000097          	auipc	ra,0x0
    80003a4e:	cfc080e7          	jalr	-772(ra) # 80003746 <iupdate>
    ip->valid = 0;
    80003a52:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a56:	854a                	mv	a0,s2
    80003a58:	00001097          	auipc	ra,0x1
    80003a5c:	ad8080e7          	jalr	-1320(ra) # 80004530 <releasesleep>
    acquire(&itable.lock);
    80003a60:	0005c517          	auipc	a0,0x5c
    80003a64:	d6850513          	addi	a0,a0,-664 # 8005f7c8 <itable>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	2c6080e7          	jalr	710(ra) # 80000d2e <acquire>
    80003a70:	b741                	j	800039f0 <iput+0x26>

0000000080003a72 <iunlockput>:
{
    80003a72:	1101                	addi	sp,sp,-32
    80003a74:	ec06                	sd	ra,24(sp)
    80003a76:	e822                	sd	s0,16(sp)
    80003a78:	e426                	sd	s1,8(sp)
    80003a7a:	1000                	addi	s0,sp,32
    80003a7c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	e54080e7          	jalr	-428(ra) # 800038d2 <iunlock>
  iput(ip);
    80003a86:	8526                	mv	a0,s1
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	f42080e7          	jalr	-190(ra) # 800039ca <iput>
}
    80003a90:	60e2                	ld	ra,24(sp)
    80003a92:	6442                	ld	s0,16(sp)
    80003a94:	64a2                	ld	s1,8(sp)
    80003a96:	6105                	addi	sp,sp,32
    80003a98:	8082                	ret

0000000080003a9a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a9a:	1141                	addi	sp,sp,-16
    80003a9c:	e422                	sd	s0,8(sp)
    80003a9e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003aa0:	411c                	lw	a5,0(a0)
    80003aa2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003aa4:	415c                	lw	a5,4(a0)
    80003aa6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003aa8:	04451783          	lh	a5,68(a0)
    80003aac:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ab0:	04a51783          	lh	a5,74(a0)
    80003ab4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ab8:	04c56783          	lwu	a5,76(a0)
    80003abc:	e99c                	sd	a5,16(a1)
}
    80003abe:	6422                	ld	s0,8(sp)
    80003ac0:	0141                	addi	sp,sp,16
    80003ac2:	8082                	ret

0000000080003ac4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ac4:	457c                	lw	a5,76(a0)
    80003ac6:	0ed7e963          	bltu	a5,a3,80003bb8 <readi+0xf4>
{
    80003aca:	7159                	addi	sp,sp,-112
    80003acc:	f486                	sd	ra,104(sp)
    80003ace:	f0a2                	sd	s0,96(sp)
    80003ad0:	eca6                	sd	s1,88(sp)
    80003ad2:	e8ca                	sd	s2,80(sp)
    80003ad4:	e4ce                	sd	s3,72(sp)
    80003ad6:	e0d2                	sd	s4,64(sp)
    80003ad8:	fc56                	sd	s5,56(sp)
    80003ada:	f85a                	sd	s6,48(sp)
    80003adc:	f45e                	sd	s7,40(sp)
    80003ade:	f062                	sd	s8,32(sp)
    80003ae0:	ec66                	sd	s9,24(sp)
    80003ae2:	e86a                	sd	s10,16(sp)
    80003ae4:	e46e                	sd	s11,8(sp)
    80003ae6:	1880                	addi	s0,sp,112
    80003ae8:	8baa                	mv	s7,a0
    80003aea:	8c2e                	mv	s8,a1
    80003aec:	8ab2                	mv	s5,a2
    80003aee:	84b6                	mv	s1,a3
    80003af0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003af2:	9f35                	addw	a4,a4,a3
    return 0;
    80003af4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003af6:	0ad76063          	bltu	a4,a3,80003b96 <readi+0xd2>
  if(off + n > ip->size)
    80003afa:	00e7f463          	bgeu	a5,a4,80003b02 <readi+0x3e>
    n = ip->size - off;
    80003afe:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b02:	0a0b0963          	beqz	s6,80003bb4 <readi+0xf0>
    80003b06:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b08:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b0c:	5cfd                	li	s9,-1
    80003b0e:	a82d                	j	80003b48 <readi+0x84>
    80003b10:	020a1d93          	slli	s11,s4,0x20
    80003b14:	020ddd93          	srli	s11,s11,0x20
    80003b18:	05890613          	addi	a2,s2,88
    80003b1c:	86ee                	mv	a3,s11
    80003b1e:	963a                	add	a2,a2,a4
    80003b20:	85d6                	mv	a1,s5
    80003b22:	8562                	mv	a0,s8
    80003b24:	fffff097          	auipc	ra,0xfffff
    80003b28:	a5c080e7          	jalr	-1444(ra) # 80002580 <either_copyout>
    80003b2c:	05950d63          	beq	a0,s9,80003b86 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b30:	854a                	mv	a0,s2
    80003b32:	fffff097          	auipc	ra,0xfffff
    80003b36:	60c080e7          	jalr	1548(ra) # 8000313e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b3a:	013a09bb          	addw	s3,s4,s3
    80003b3e:	009a04bb          	addw	s1,s4,s1
    80003b42:	9aee                	add	s5,s5,s11
    80003b44:	0569f763          	bgeu	s3,s6,80003b92 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b48:	000ba903          	lw	s2,0(s7)
    80003b4c:	00a4d59b          	srliw	a1,s1,0xa
    80003b50:	855e                	mv	a0,s7
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	8b0080e7          	jalr	-1872(ra) # 80003402 <bmap>
    80003b5a:	0005059b          	sext.w	a1,a0
    80003b5e:	854a                	mv	a0,s2
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	4ae080e7          	jalr	1198(ra) # 8000300e <bread>
    80003b68:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b6a:	3ff4f713          	andi	a4,s1,1023
    80003b6e:	40ed07bb          	subw	a5,s10,a4
    80003b72:	413b06bb          	subw	a3,s6,s3
    80003b76:	8a3e                	mv	s4,a5
    80003b78:	2781                	sext.w	a5,a5
    80003b7a:	0006861b          	sext.w	a2,a3
    80003b7e:	f8f679e3          	bgeu	a2,a5,80003b10 <readi+0x4c>
    80003b82:	8a36                	mv	s4,a3
    80003b84:	b771                	j	80003b10 <readi+0x4c>
      brelse(bp);
    80003b86:	854a                	mv	a0,s2
    80003b88:	fffff097          	auipc	ra,0xfffff
    80003b8c:	5b6080e7          	jalr	1462(ra) # 8000313e <brelse>
      tot = -1;
    80003b90:	59fd                	li	s3,-1
  }
  return tot;
    80003b92:	0009851b          	sext.w	a0,s3
}
    80003b96:	70a6                	ld	ra,104(sp)
    80003b98:	7406                	ld	s0,96(sp)
    80003b9a:	64e6                	ld	s1,88(sp)
    80003b9c:	6946                	ld	s2,80(sp)
    80003b9e:	69a6                	ld	s3,72(sp)
    80003ba0:	6a06                	ld	s4,64(sp)
    80003ba2:	7ae2                	ld	s5,56(sp)
    80003ba4:	7b42                	ld	s6,48(sp)
    80003ba6:	7ba2                	ld	s7,40(sp)
    80003ba8:	7c02                	ld	s8,32(sp)
    80003baa:	6ce2                	ld	s9,24(sp)
    80003bac:	6d42                	ld	s10,16(sp)
    80003bae:	6da2                	ld	s11,8(sp)
    80003bb0:	6165                	addi	sp,sp,112
    80003bb2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bb4:	89da                	mv	s3,s6
    80003bb6:	bff1                	j	80003b92 <readi+0xce>
    return 0;
    80003bb8:	4501                	li	a0,0
}
    80003bba:	8082                	ret

0000000080003bbc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bbc:	457c                	lw	a5,76(a0)
    80003bbe:	10d7e863          	bltu	a5,a3,80003cce <writei+0x112>
{
    80003bc2:	7159                	addi	sp,sp,-112
    80003bc4:	f486                	sd	ra,104(sp)
    80003bc6:	f0a2                	sd	s0,96(sp)
    80003bc8:	eca6                	sd	s1,88(sp)
    80003bca:	e8ca                	sd	s2,80(sp)
    80003bcc:	e4ce                	sd	s3,72(sp)
    80003bce:	e0d2                	sd	s4,64(sp)
    80003bd0:	fc56                	sd	s5,56(sp)
    80003bd2:	f85a                	sd	s6,48(sp)
    80003bd4:	f45e                	sd	s7,40(sp)
    80003bd6:	f062                	sd	s8,32(sp)
    80003bd8:	ec66                	sd	s9,24(sp)
    80003bda:	e86a                	sd	s10,16(sp)
    80003bdc:	e46e                	sd	s11,8(sp)
    80003bde:	1880                	addi	s0,sp,112
    80003be0:	8b2a                	mv	s6,a0
    80003be2:	8c2e                	mv	s8,a1
    80003be4:	8ab2                	mv	s5,a2
    80003be6:	8936                	mv	s2,a3
    80003be8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003bea:	00e687bb          	addw	a5,a3,a4
    80003bee:	0ed7e263          	bltu	a5,a3,80003cd2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bf2:	00043737          	lui	a4,0x43
    80003bf6:	0ef76063          	bltu	a4,a5,80003cd6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bfa:	0c0b8863          	beqz	s7,80003cca <writei+0x10e>
    80003bfe:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c00:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c04:	5cfd                	li	s9,-1
    80003c06:	a091                	j	80003c4a <writei+0x8e>
    80003c08:	02099d93          	slli	s11,s3,0x20
    80003c0c:	020ddd93          	srli	s11,s11,0x20
    80003c10:	05848513          	addi	a0,s1,88
    80003c14:	86ee                	mv	a3,s11
    80003c16:	8656                	mv	a2,s5
    80003c18:	85e2                	mv	a1,s8
    80003c1a:	953a                	add	a0,a0,a4
    80003c1c:	fffff097          	auipc	ra,0xfffff
    80003c20:	9ba080e7          	jalr	-1606(ra) # 800025d6 <either_copyin>
    80003c24:	07950263          	beq	a0,s9,80003c88 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c28:	8526                	mv	a0,s1
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	790080e7          	jalr	1936(ra) # 800043ba <log_write>
    brelse(bp);
    80003c32:	8526                	mv	a0,s1
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	50a080e7          	jalr	1290(ra) # 8000313e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c3c:	01498a3b          	addw	s4,s3,s4
    80003c40:	0129893b          	addw	s2,s3,s2
    80003c44:	9aee                	add	s5,s5,s11
    80003c46:	057a7663          	bgeu	s4,s7,80003c92 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c4a:	000b2483          	lw	s1,0(s6)
    80003c4e:	00a9559b          	srliw	a1,s2,0xa
    80003c52:	855a                	mv	a0,s6
    80003c54:	fffff097          	auipc	ra,0xfffff
    80003c58:	7ae080e7          	jalr	1966(ra) # 80003402 <bmap>
    80003c5c:	0005059b          	sext.w	a1,a0
    80003c60:	8526                	mv	a0,s1
    80003c62:	fffff097          	auipc	ra,0xfffff
    80003c66:	3ac080e7          	jalr	940(ra) # 8000300e <bread>
    80003c6a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c6c:	3ff97713          	andi	a4,s2,1023
    80003c70:	40ed07bb          	subw	a5,s10,a4
    80003c74:	414b86bb          	subw	a3,s7,s4
    80003c78:	89be                	mv	s3,a5
    80003c7a:	2781                	sext.w	a5,a5
    80003c7c:	0006861b          	sext.w	a2,a3
    80003c80:	f8f674e3          	bgeu	a2,a5,80003c08 <writei+0x4c>
    80003c84:	89b6                	mv	s3,a3
    80003c86:	b749                	j	80003c08 <writei+0x4c>
      brelse(bp);
    80003c88:	8526                	mv	a0,s1
    80003c8a:	fffff097          	auipc	ra,0xfffff
    80003c8e:	4b4080e7          	jalr	1204(ra) # 8000313e <brelse>
  }

  if(off > ip->size)
    80003c92:	04cb2783          	lw	a5,76(s6)
    80003c96:	0127f463          	bgeu	a5,s2,80003c9e <writei+0xe2>
    ip->size = off;
    80003c9a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c9e:	855a                	mv	a0,s6
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	aa6080e7          	jalr	-1370(ra) # 80003746 <iupdate>

  return tot;
    80003ca8:	000a051b          	sext.w	a0,s4
}
    80003cac:	70a6                	ld	ra,104(sp)
    80003cae:	7406                	ld	s0,96(sp)
    80003cb0:	64e6                	ld	s1,88(sp)
    80003cb2:	6946                	ld	s2,80(sp)
    80003cb4:	69a6                	ld	s3,72(sp)
    80003cb6:	6a06                	ld	s4,64(sp)
    80003cb8:	7ae2                	ld	s5,56(sp)
    80003cba:	7b42                	ld	s6,48(sp)
    80003cbc:	7ba2                	ld	s7,40(sp)
    80003cbe:	7c02                	ld	s8,32(sp)
    80003cc0:	6ce2                	ld	s9,24(sp)
    80003cc2:	6d42                	ld	s10,16(sp)
    80003cc4:	6da2                	ld	s11,8(sp)
    80003cc6:	6165                	addi	sp,sp,112
    80003cc8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cca:	8a5e                	mv	s4,s7
    80003ccc:	bfc9                	j	80003c9e <writei+0xe2>
    return -1;
    80003cce:	557d                	li	a0,-1
}
    80003cd0:	8082                	ret
    return -1;
    80003cd2:	557d                	li	a0,-1
    80003cd4:	bfe1                	j	80003cac <writei+0xf0>
    return -1;
    80003cd6:	557d                	li	a0,-1
    80003cd8:	bfd1                	j	80003cac <writei+0xf0>

0000000080003cda <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cda:	1141                	addi	sp,sp,-16
    80003cdc:	e406                	sd	ra,8(sp)
    80003cde:	e022                	sd	s0,0(sp)
    80003ce0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ce2:	4639                	li	a2,14
    80003ce4:	ffffd097          	auipc	ra,0xffffd
    80003ce8:	21e080e7          	jalr	542(ra) # 80000f02 <strncmp>
}
    80003cec:	60a2                	ld	ra,8(sp)
    80003cee:	6402                	ld	s0,0(sp)
    80003cf0:	0141                	addi	sp,sp,16
    80003cf2:	8082                	ret

0000000080003cf4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cf4:	7139                	addi	sp,sp,-64
    80003cf6:	fc06                	sd	ra,56(sp)
    80003cf8:	f822                	sd	s0,48(sp)
    80003cfa:	f426                	sd	s1,40(sp)
    80003cfc:	f04a                	sd	s2,32(sp)
    80003cfe:	ec4e                	sd	s3,24(sp)
    80003d00:	e852                	sd	s4,16(sp)
    80003d02:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d04:	04451703          	lh	a4,68(a0)
    80003d08:	4785                	li	a5,1
    80003d0a:	00f71a63          	bne	a4,a5,80003d1e <dirlookup+0x2a>
    80003d0e:	892a                	mv	s2,a0
    80003d10:	89ae                	mv	s3,a1
    80003d12:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d14:	457c                	lw	a5,76(a0)
    80003d16:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d18:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d1a:	e79d                	bnez	a5,80003d48 <dirlookup+0x54>
    80003d1c:	a8a5                	j	80003d94 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d1e:	00005517          	auipc	a0,0x5
    80003d22:	92250513          	addi	a0,a0,-1758 # 80008640 <syscalls+0x1a0>
    80003d26:	ffffd097          	auipc	ra,0xffffd
    80003d2a:	818080e7          	jalr	-2024(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d2e:	00005517          	auipc	a0,0x5
    80003d32:	92a50513          	addi	a0,a0,-1750 # 80008658 <syscalls+0x1b8>
    80003d36:	ffffd097          	auipc	ra,0xffffd
    80003d3a:	808080e7          	jalr	-2040(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d3e:	24c1                	addiw	s1,s1,16
    80003d40:	04c92783          	lw	a5,76(s2)
    80003d44:	04f4f763          	bgeu	s1,a5,80003d92 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d48:	4741                	li	a4,16
    80003d4a:	86a6                	mv	a3,s1
    80003d4c:	fc040613          	addi	a2,s0,-64
    80003d50:	4581                	li	a1,0
    80003d52:	854a                	mv	a0,s2
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	d70080e7          	jalr	-656(ra) # 80003ac4 <readi>
    80003d5c:	47c1                	li	a5,16
    80003d5e:	fcf518e3          	bne	a0,a5,80003d2e <dirlookup+0x3a>
    if(de.inum == 0)
    80003d62:	fc045783          	lhu	a5,-64(s0)
    80003d66:	dfe1                	beqz	a5,80003d3e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d68:	fc240593          	addi	a1,s0,-62
    80003d6c:	854e                	mv	a0,s3
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	f6c080e7          	jalr	-148(ra) # 80003cda <namecmp>
    80003d76:	f561                	bnez	a0,80003d3e <dirlookup+0x4a>
      if(poff)
    80003d78:	000a0463          	beqz	s4,80003d80 <dirlookup+0x8c>
        *poff = off;
    80003d7c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d80:	fc045583          	lhu	a1,-64(s0)
    80003d84:	00092503          	lw	a0,0(s2)
    80003d88:	fffff097          	auipc	ra,0xfffff
    80003d8c:	754080e7          	jalr	1876(ra) # 800034dc <iget>
    80003d90:	a011                	j	80003d94 <dirlookup+0xa0>
  return 0;
    80003d92:	4501                	li	a0,0
}
    80003d94:	70e2                	ld	ra,56(sp)
    80003d96:	7442                	ld	s0,48(sp)
    80003d98:	74a2                	ld	s1,40(sp)
    80003d9a:	7902                	ld	s2,32(sp)
    80003d9c:	69e2                	ld	s3,24(sp)
    80003d9e:	6a42                	ld	s4,16(sp)
    80003da0:	6121                	addi	sp,sp,64
    80003da2:	8082                	ret

0000000080003da4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003da4:	711d                	addi	sp,sp,-96
    80003da6:	ec86                	sd	ra,88(sp)
    80003da8:	e8a2                	sd	s0,80(sp)
    80003daa:	e4a6                	sd	s1,72(sp)
    80003dac:	e0ca                	sd	s2,64(sp)
    80003dae:	fc4e                	sd	s3,56(sp)
    80003db0:	f852                	sd	s4,48(sp)
    80003db2:	f456                	sd	s5,40(sp)
    80003db4:	f05a                	sd	s6,32(sp)
    80003db6:	ec5e                	sd	s7,24(sp)
    80003db8:	e862                	sd	s8,16(sp)
    80003dba:	e466                	sd	s9,8(sp)
    80003dbc:	1080                	addi	s0,sp,96
    80003dbe:	84aa                	mv	s1,a0
    80003dc0:	8b2e                	mv	s6,a1
    80003dc2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dc4:	00054703          	lbu	a4,0(a0)
    80003dc8:	02f00793          	li	a5,47
    80003dcc:	02f70363          	beq	a4,a5,80003df2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dd0:	ffffe097          	auipc	ra,0xffffe
    80003dd4:	d50080e7          	jalr	-688(ra) # 80001b20 <myproc>
    80003dd8:	15053503          	ld	a0,336(a0)
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	9f6080e7          	jalr	-1546(ra) # 800037d2 <idup>
    80003de4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003de6:	02f00913          	li	s2,47
  len = path - s;
    80003dea:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003dec:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dee:	4c05                	li	s8,1
    80003df0:	a865                	j	80003ea8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003df2:	4585                	li	a1,1
    80003df4:	4505                	li	a0,1
    80003df6:	fffff097          	auipc	ra,0xfffff
    80003dfa:	6e6080e7          	jalr	1766(ra) # 800034dc <iget>
    80003dfe:	89aa                	mv	s3,a0
    80003e00:	b7dd                	j	80003de6 <namex+0x42>
      iunlockput(ip);
    80003e02:	854e                	mv	a0,s3
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	c6e080e7          	jalr	-914(ra) # 80003a72 <iunlockput>
      return 0;
    80003e0c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e0e:	854e                	mv	a0,s3
    80003e10:	60e6                	ld	ra,88(sp)
    80003e12:	6446                	ld	s0,80(sp)
    80003e14:	64a6                	ld	s1,72(sp)
    80003e16:	6906                	ld	s2,64(sp)
    80003e18:	79e2                	ld	s3,56(sp)
    80003e1a:	7a42                	ld	s4,48(sp)
    80003e1c:	7aa2                	ld	s5,40(sp)
    80003e1e:	7b02                	ld	s6,32(sp)
    80003e20:	6be2                	ld	s7,24(sp)
    80003e22:	6c42                	ld	s8,16(sp)
    80003e24:	6ca2                	ld	s9,8(sp)
    80003e26:	6125                	addi	sp,sp,96
    80003e28:	8082                	ret
      iunlock(ip);
    80003e2a:	854e                	mv	a0,s3
    80003e2c:	00000097          	auipc	ra,0x0
    80003e30:	aa6080e7          	jalr	-1370(ra) # 800038d2 <iunlock>
      return ip;
    80003e34:	bfe9                	j	80003e0e <namex+0x6a>
      iunlockput(ip);
    80003e36:	854e                	mv	a0,s3
    80003e38:	00000097          	auipc	ra,0x0
    80003e3c:	c3a080e7          	jalr	-966(ra) # 80003a72 <iunlockput>
      return 0;
    80003e40:	89d2                	mv	s3,s4
    80003e42:	b7f1                	j	80003e0e <namex+0x6a>
  len = path - s;
    80003e44:	40b48633          	sub	a2,s1,a1
    80003e48:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e4c:	094cd463          	bge	s9,s4,80003ed4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e50:	4639                	li	a2,14
    80003e52:	8556                	mv	a0,s5
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	036080e7          	jalr	54(ra) # 80000e8a <memmove>
  while(*path == '/')
    80003e5c:	0004c783          	lbu	a5,0(s1)
    80003e60:	01279763          	bne	a5,s2,80003e6e <namex+0xca>
    path++;
    80003e64:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e66:	0004c783          	lbu	a5,0(s1)
    80003e6a:	ff278de3          	beq	a5,s2,80003e64 <namex+0xc0>
    ilock(ip);
    80003e6e:	854e                	mv	a0,s3
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	9a0080e7          	jalr	-1632(ra) # 80003810 <ilock>
    if(ip->type != T_DIR){
    80003e78:	04499783          	lh	a5,68(s3)
    80003e7c:	f98793e3          	bne	a5,s8,80003e02 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e80:	000b0563          	beqz	s6,80003e8a <namex+0xe6>
    80003e84:	0004c783          	lbu	a5,0(s1)
    80003e88:	d3cd                	beqz	a5,80003e2a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e8a:	865e                	mv	a2,s7
    80003e8c:	85d6                	mv	a1,s5
    80003e8e:	854e                	mv	a0,s3
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	e64080e7          	jalr	-412(ra) # 80003cf4 <dirlookup>
    80003e98:	8a2a                	mv	s4,a0
    80003e9a:	dd51                	beqz	a0,80003e36 <namex+0x92>
    iunlockput(ip);
    80003e9c:	854e                	mv	a0,s3
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	bd4080e7          	jalr	-1068(ra) # 80003a72 <iunlockput>
    ip = next;
    80003ea6:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ea8:	0004c783          	lbu	a5,0(s1)
    80003eac:	05279763          	bne	a5,s2,80003efa <namex+0x156>
    path++;
    80003eb0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eb2:	0004c783          	lbu	a5,0(s1)
    80003eb6:	ff278de3          	beq	a5,s2,80003eb0 <namex+0x10c>
  if(*path == 0)
    80003eba:	c79d                	beqz	a5,80003ee8 <namex+0x144>
    path++;
    80003ebc:	85a6                	mv	a1,s1
  len = path - s;
    80003ebe:	8a5e                	mv	s4,s7
    80003ec0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ec2:	01278963          	beq	a5,s2,80003ed4 <namex+0x130>
    80003ec6:	dfbd                	beqz	a5,80003e44 <namex+0xa0>
    path++;
    80003ec8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003eca:	0004c783          	lbu	a5,0(s1)
    80003ece:	ff279ce3          	bne	a5,s2,80003ec6 <namex+0x122>
    80003ed2:	bf8d                	j	80003e44 <namex+0xa0>
    memmove(name, s, len);
    80003ed4:	2601                	sext.w	a2,a2
    80003ed6:	8556                	mv	a0,s5
    80003ed8:	ffffd097          	auipc	ra,0xffffd
    80003edc:	fb2080e7          	jalr	-78(ra) # 80000e8a <memmove>
    name[len] = 0;
    80003ee0:	9a56                	add	s4,s4,s5
    80003ee2:	000a0023          	sb	zero,0(s4)
    80003ee6:	bf9d                	j	80003e5c <namex+0xb8>
  if(nameiparent){
    80003ee8:	f20b03e3          	beqz	s6,80003e0e <namex+0x6a>
    iput(ip);
    80003eec:	854e                	mv	a0,s3
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	adc080e7          	jalr	-1316(ra) # 800039ca <iput>
    return 0;
    80003ef6:	4981                	li	s3,0
    80003ef8:	bf19                	j	80003e0e <namex+0x6a>
  if(*path == 0)
    80003efa:	d7fd                	beqz	a5,80003ee8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003efc:	0004c783          	lbu	a5,0(s1)
    80003f00:	85a6                	mv	a1,s1
    80003f02:	b7d1                	j	80003ec6 <namex+0x122>

0000000080003f04 <dirlink>:
{
    80003f04:	7139                	addi	sp,sp,-64
    80003f06:	fc06                	sd	ra,56(sp)
    80003f08:	f822                	sd	s0,48(sp)
    80003f0a:	f426                	sd	s1,40(sp)
    80003f0c:	f04a                	sd	s2,32(sp)
    80003f0e:	ec4e                	sd	s3,24(sp)
    80003f10:	e852                	sd	s4,16(sp)
    80003f12:	0080                	addi	s0,sp,64
    80003f14:	892a                	mv	s2,a0
    80003f16:	8a2e                	mv	s4,a1
    80003f18:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f1a:	4601                	li	a2,0
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	dd8080e7          	jalr	-552(ra) # 80003cf4 <dirlookup>
    80003f24:	e93d                	bnez	a0,80003f9a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f26:	04c92483          	lw	s1,76(s2)
    80003f2a:	c49d                	beqz	s1,80003f58 <dirlink+0x54>
    80003f2c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f2e:	4741                	li	a4,16
    80003f30:	86a6                	mv	a3,s1
    80003f32:	fc040613          	addi	a2,s0,-64
    80003f36:	4581                	li	a1,0
    80003f38:	854a                	mv	a0,s2
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	b8a080e7          	jalr	-1142(ra) # 80003ac4 <readi>
    80003f42:	47c1                	li	a5,16
    80003f44:	06f51163          	bne	a0,a5,80003fa6 <dirlink+0xa2>
    if(de.inum == 0)
    80003f48:	fc045783          	lhu	a5,-64(s0)
    80003f4c:	c791                	beqz	a5,80003f58 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f4e:	24c1                	addiw	s1,s1,16
    80003f50:	04c92783          	lw	a5,76(s2)
    80003f54:	fcf4ede3          	bltu	s1,a5,80003f2e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f58:	4639                	li	a2,14
    80003f5a:	85d2                	mv	a1,s4
    80003f5c:	fc240513          	addi	a0,s0,-62
    80003f60:	ffffd097          	auipc	ra,0xffffd
    80003f64:	fde080e7          	jalr	-34(ra) # 80000f3e <strncpy>
  de.inum = inum;
    80003f68:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f6c:	4741                	li	a4,16
    80003f6e:	86a6                	mv	a3,s1
    80003f70:	fc040613          	addi	a2,s0,-64
    80003f74:	4581                	li	a1,0
    80003f76:	854a                	mv	a0,s2
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	c44080e7          	jalr	-956(ra) # 80003bbc <writei>
    80003f80:	872a                	mv	a4,a0
    80003f82:	47c1                	li	a5,16
  return 0;
    80003f84:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f86:	02f71863          	bne	a4,a5,80003fb6 <dirlink+0xb2>
}
    80003f8a:	70e2                	ld	ra,56(sp)
    80003f8c:	7442                	ld	s0,48(sp)
    80003f8e:	74a2                	ld	s1,40(sp)
    80003f90:	7902                	ld	s2,32(sp)
    80003f92:	69e2                	ld	s3,24(sp)
    80003f94:	6a42                	ld	s4,16(sp)
    80003f96:	6121                	addi	sp,sp,64
    80003f98:	8082                	ret
    iput(ip);
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	a30080e7          	jalr	-1488(ra) # 800039ca <iput>
    return -1;
    80003fa2:	557d                	li	a0,-1
    80003fa4:	b7dd                	j	80003f8a <dirlink+0x86>
      panic("dirlink read");
    80003fa6:	00004517          	auipc	a0,0x4
    80003faa:	6c250513          	addi	a0,a0,1730 # 80008668 <syscalls+0x1c8>
    80003fae:	ffffc097          	auipc	ra,0xffffc
    80003fb2:	590080e7          	jalr	1424(ra) # 8000053e <panic>
    panic("dirlink");
    80003fb6:	00004517          	auipc	a0,0x4
    80003fba:	7c250513          	addi	a0,a0,1986 # 80008778 <syscalls+0x2d8>
    80003fbe:	ffffc097          	auipc	ra,0xffffc
    80003fc2:	580080e7          	jalr	1408(ra) # 8000053e <panic>

0000000080003fc6 <namei>:

struct inode*
namei(char *path)
{
    80003fc6:	1101                	addi	sp,sp,-32
    80003fc8:	ec06                	sd	ra,24(sp)
    80003fca:	e822                	sd	s0,16(sp)
    80003fcc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fce:	fe040613          	addi	a2,s0,-32
    80003fd2:	4581                	li	a1,0
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	dd0080e7          	jalr	-560(ra) # 80003da4 <namex>
}
    80003fdc:	60e2                	ld	ra,24(sp)
    80003fde:	6442                	ld	s0,16(sp)
    80003fe0:	6105                	addi	sp,sp,32
    80003fe2:	8082                	ret

0000000080003fe4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fe4:	1141                	addi	sp,sp,-16
    80003fe6:	e406                	sd	ra,8(sp)
    80003fe8:	e022                	sd	s0,0(sp)
    80003fea:	0800                	addi	s0,sp,16
    80003fec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fee:	4585                	li	a1,1
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	db4080e7          	jalr	-588(ra) # 80003da4 <namex>
}
    80003ff8:	60a2                	ld	ra,8(sp)
    80003ffa:	6402                	ld	s0,0(sp)
    80003ffc:	0141                	addi	sp,sp,16
    80003ffe:	8082                	ret

0000000080004000 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004000:	1101                	addi	sp,sp,-32
    80004002:	ec06                	sd	ra,24(sp)
    80004004:	e822                	sd	s0,16(sp)
    80004006:	e426                	sd	s1,8(sp)
    80004008:	e04a                	sd	s2,0(sp)
    8000400a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000400c:	0005d917          	auipc	s2,0x5d
    80004010:	26490913          	addi	s2,s2,612 # 80061270 <log>
    80004014:	01892583          	lw	a1,24(s2)
    80004018:	02892503          	lw	a0,40(s2)
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	ff2080e7          	jalr	-14(ra) # 8000300e <bread>
    80004024:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004026:	02c92683          	lw	a3,44(s2)
    8000402a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000402c:	02d05763          	blez	a3,8000405a <write_head+0x5a>
    80004030:	0005d797          	auipc	a5,0x5d
    80004034:	27078793          	addi	a5,a5,624 # 800612a0 <log+0x30>
    80004038:	05c50713          	addi	a4,a0,92
    8000403c:	36fd                	addiw	a3,a3,-1
    8000403e:	1682                	slli	a3,a3,0x20
    80004040:	9281                	srli	a3,a3,0x20
    80004042:	068a                	slli	a3,a3,0x2
    80004044:	0005d617          	auipc	a2,0x5d
    80004048:	26060613          	addi	a2,a2,608 # 800612a4 <log+0x34>
    8000404c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000404e:	4390                	lw	a2,0(a5)
    80004050:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004052:	0791                	addi	a5,a5,4
    80004054:	0711                	addi	a4,a4,4
    80004056:	fed79ce3          	bne	a5,a3,8000404e <write_head+0x4e>
  }
  bwrite(buf);
    8000405a:	8526                	mv	a0,s1
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	0a4080e7          	jalr	164(ra) # 80003100 <bwrite>
  brelse(buf);
    80004064:	8526                	mv	a0,s1
    80004066:	fffff097          	auipc	ra,0xfffff
    8000406a:	0d8080e7          	jalr	216(ra) # 8000313e <brelse>
}
    8000406e:	60e2                	ld	ra,24(sp)
    80004070:	6442                	ld	s0,16(sp)
    80004072:	64a2                	ld	s1,8(sp)
    80004074:	6902                	ld	s2,0(sp)
    80004076:	6105                	addi	sp,sp,32
    80004078:	8082                	ret

000000008000407a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000407a:	0005d797          	auipc	a5,0x5d
    8000407e:	2227a783          	lw	a5,546(a5) # 8006129c <log+0x2c>
    80004082:	0af05d63          	blez	a5,8000413c <install_trans+0xc2>
{
    80004086:	7139                	addi	sp,sp,-64
    80004088:	fc06                	sd	ra,56(sp)
    8000408a:	f822                	sd	s0,48(sp)
    8000408c:	f426                	sd	s1,40(sp)
    8000408e:	f04a                	sd	s2,32(sp)
    80004090:	ec4e                	sd	s3,24(sp)
    80004092:	e852                	sd	s4,16(sp)
    80004094:	e456                	sd	s5,8(sp)
    80004096:	e05a                	sd	s6,0(sp)
    80004098:	0080                	addi	s0,sp,64
    8000409a:	8b2a                	mv	s6,a0
    8000409c:	0005da97          	auipc	s5,0x5d
    800040a0:	204a8a93          	addi	s5,s5,516 # 800612a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040a4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040a6:	0005d997          	auipc	s3,0x5d
    800040aa:	1ca98993          	addi	s3,s3,458 # 80061270 <log>
    800040ae:	a035                	j	800040da <install_trans+0x60>
      bunpin(dbuf);
    800040b0:	8526                	mv	a0,s1
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	166080e7          	jalr	358(ra) # 80003218 <bunpin>
    brelse(lbuf);
    800040ba:	854a                	mv	a0,s2
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	082080e7          	jalr	130(ra) # 8000313e <brelse>
    brelse(dbuf);
    800040c4:	8526                	mv	a0,s1
    800040c6:	fffff097          	auipc	ra,0xfffff
    800040ca:	078080e7          	jalr	120(ra) # 8000313e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ce:	2a05                	addiw	s4,s4,1
    800040d0:	0a91                	addi	s5,s5,4
    800040d2:	02c9a783          	lw	a5,44(s3)
    800040d6:	04fa5963          	bge	s4,a5,80004128 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040da:	0189a583          	lw	a1,24(s3)
    800040de:	014585bb          	addw	a1,a1,s4
    800040e2:	2585                	addiw	a1,a1,1
    800040e4:	0289a503          	lw	a0,40(s3)
    800040e8:	fffff097          	auipc	ra,0xfffff
    800040ec:	f26080e7          	jalr	-218(ra) # 8000300e <bread>
    800040f0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040f2:	000aa583          	lw	a1,0(s5)
    800040f6:	0289a503          	lw	a0,40(s3)
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	f14080e7          	jalr	-236(ra) # 8000300e <bread>
    80004102:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004104:	40000613          	li	a2,1024
    80004108:	05890593          	addi	a1,s2,88
    8000410c:	05850513          	addi	a0,a0,88
    80004110:	ffffd097          	auipc	ra,0xffffd
    80004114:	d7a080e7          	jalr	-646(ra) # 80000e8a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004118:	8526                	mv	a0,s1
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	fe6080e7          	jalr	-26(ra) # 80003100 <bwrite>
    if(recovering == 0)
    80004122:	f80b1ce3          	bnez	s6,800040ba <install_trans+0x40>
    80004126:	b769                	j	800040b0 <install_trans+0x36>
}
    80004128:	70e2                	ld	ra,56(sp)
    8000412a:	7442                	ld	s0,48(sp)
    8000412c:	74a2                	ld	s1,40(sp)
    8000412e:	7902                	ld	s2,32(sp)
    80004130:	69e2                	ld	s3,24(sp)
    80004132:	6a42                	ld	s4,16(sp)
    80004134:	6aa2                	ld	s5,8(sp)
    80004136:	6b02                	ld	s6,0(sp)
    80004138:	6121                	addi	sp,sp,64
    8000413a:	8082                	ret
    8000413c:	8082                	ret

000000008000413e <initlog>:
{
    8000413e:	7179                	addi	sp,sp,-48
    80004140:	f406                	sd	ra,40(sp)
    80004142:	f022                	sd	s0,32(sp)
    80004144:	ec26                	sd	s1,24(sp)
    80004146:	e84a                	sd	s2,16(sp)
    80004148:	e44e                	sd	s3,8(sp)
    8000414a:	1800                	addi	s0,sp,48
    8000414c:	892a                	mv	s2,a0
    8000414e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004150:	0005d497          	auipc	s1,0x5d
    80004154:	12048493          	addi	s1,s1,288 # 80061270 <log>
    80004158:	00004597          	auipc	a1,0x4
    8000415c:	52058593          	addi	a1,a1,1312 # 80008678 <syscalls+0x1d8>
    80004160:	8526                	mv	a0,s1
    80004162:	ffffd097          	auipc	ra,0xffffd
    80004166:	b3c080e7          	jalr	-1220(ra) # 80000c9e <initlock>
  log.start = sb->logstart;
    8000416a:	0149a583          	lw	a1,20(s3)
    8000416e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004170:	0109a783          	lw	a5,16(s3)
    80004174:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004176:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000417a:	854a                	mv	a0,s2
    8000417c:	fffff097          	auipc	ra,0xfffff
    80004180:	e92080e7          	jalr	-366(ra) # 8000300e <bread>
  log.lh.n = lh->n;
    80004184:	4d3c                	lw	a5,88(a0)
    80004186:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004188:	02f05563          	blez	a5,800041b2 <initlog+0x74>
    8000418c:	05c50713          	addi	a4,a0,92
    80004190:	0005d697          	auipc	a3,0x5d
    80004194:	11068693          	addi	a3,a3,272 # 800612a0 <log+0x30>
    80004198:	37fd                	addiw	a5,a5,-1
    8000419a:	1782                	slli	a5,a5,0x20
    8000419c:	9381                	srli	a5,a5,0x20
    8000419e:	078a                	slli	a5,a5,0x2
    800041a0:	06050613          	addi	a2,a0,96
    800041a4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041a6:	4310                	lw	a2,0(a4)
    800041a8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041aa:	0711                	addi	a4,a4,4
    800041ac:	0691                	addi	a3,a3,4
    800041ae:	fef71ce3          	bne	a4,a5,800041a6 <initlog+0x68>
  brelse(buf);
    800041b2:	fffff097          	auipc	ra,0xfffff
    800041b6:	f8c080e7          	jalr	-116(ra) # 8000313e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041ba:	4505                	li	a0,1
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	ebe080e7          	jalr	-322(ra) # 8000407a <install_trans>
  log.lh.n = 0;
    800041c4:	0005d797          	auipc	a5,0x5d
    800041c8:	0c07ac23          	sw	zero,216(a5) # 8006129c <log+0x2c>
  write_head(); // clear the log
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	e34080e7          	jalr	-460(ra) # 80004000 <write_head>
}
    800041d4:	70a2                	ld	ra,40(sp)
    800041d6:	7402                	ld	s0,32(sp)
    800041d8:	64e2                	ld	s1,24(sp)
    800041da:	6942                	ld	s2,16(sp)
    800041dc:	69a2                	ld	s3,8(sp)
    800041de:	6145                	addi	sp,sp,48
    800041e0:	8082                	ret

00000000800041e2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041e2:	1101                	addi	sp,sp,-32
    800041e4:	ec06                	sd	ra,24(sp)
    800041e6:	e822                	sd	s0,16(sp)
    800041e8:	e426                	sd	s1,8(sp)
    800041ea:	e04a                	sd	s2,0(sp)
    800041ec:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041ee:	0005d517          	auipc	a0,0x5d
    800041f2:	08250513          	addi	a0,a0,130 # 80061270 <log>
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	b38080e7          	jalr	-1224(ra) # 80000d2e <acquire>
  while(1){
    if(log.committing){
    800041fe:	0005d497          	auipc	s1,0x5d
    80004202:	07248493          	addi	s1,s1,114 # 80061270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004206:	4979                	li	s2,30
    80004208:	a039                	j	80004216 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000420a:	85a6                	mv	a1,s1
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffe097          	auipc	ra,0xffffe
    80004212:	fce080e7          	jalr	-50(ra) # 800021dc <sleep>
    if(log.committing){
    80004216:	50dc                	lw	a5,36(s1)
    80004218:	fbed                	bnez	a5,8000420a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000421a:	509c                	lw	a5,32(s1)
    8000421c:	0017871b          	addiw	a4,a5,1
    80004220:	0007069b          	sext.w	a3,a4
    80004224:	0027179b          	slliw	a5,a4,0x2
    80004228:	9fb9                	addw	a5,a5,a4
    8000422a:	0017979b          	slliw	a5,a5,0x1
    8000422e:	54d8                	lw	a4,44(s1)
    80004230:	9fb9                	addw	a5,a5,a4
    80004232:	00f95963          	bge	s2,a5,80004244 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004236:	85a6                	mv	a1,s1
    80004238:	8526                	mv	a0,s1
    8000423a:	ffffe097          	auipc	ra,0xffffe
    8000423e:	fa2080e7          	jalr	-94(ra) # 800021dc <sleep>
    80004242:	bfd1                	j	80004216 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004244:	0005d517          	auipc	a0,0x5d
    80004248:	02c50513          	addi	a0,a0,44 # 80061270 <log>
    8000424c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000424e:	ffffd097          	auipc	ra,0xffffd
    80004252:	b94080e7          	jalr	-1132(ra) # 80000de2 <release>
      break;
    }
  }
}
    80004256:	60e2                	ld	ra,24(sp)
    80004258:	6442                	ld	s0,16(sp)
    8000425a:	64a2                	ld	s1,8(sp)
    8000425c:	6902                	ld	s2,0(sp)
    8000425e:	6105                	addi	sp,sp,32
    80004260:	8082                	ret

0000000080004262 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004262:	7139                	addi	sp,sp,-64
    80004264:	fc06                	sd	ra,56(sp)
    80004266:	f822                	sd	s0,48(sp)
    80004268:	f426                	sd	s1,40(sp)
    8000426a:	f04a                	sd	s2,32(sp)
    8000426c:	ec4e                	sd	s3,24(sp)
    8000426e:	e852                	sd	s4,16(sp)
    80004270:	e456                	sd	s5,8(sp)
    80004272:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004274:	0005d497          	auipc	s1,0x5d
    80004278:	ffc48493          	addi	s1,s1,-4 # 80061270 <log>
    8000427c:	8526                	mv	a0,s1
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	ab0080e7          	jalr	-1360(ra) # 80000d2e <acquire>
  log.outstanding -= 1;
    80004286:	509c                	lw	a5,32(s1)
    80004288:	37fd                	addiw	a5,a5,-1
    8000428a:	0007891b          	sext.w	s2,a5
    8000428e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004290:	50dc                	lw	a5,36(s1)
    80004292:	efb9                	bnez	a5,800042f0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004294:	06091663          	bnez	s2,80004300 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004298:	0005d497          	auipc	s1,0x5d
    8000429c:	fd848493          	addi	s1,s1,-40 # 80061270 <log>
    800042a0:	4785                	li	a5,1
    800042a2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042a4:	8526                	mv	a0,s1
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	b3c080e7          	jalr	-1220(ra) # 80000de2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042ae:	54dc                	lw	a5,44(s1)
    800042b0:	06f04763          	bgtz	a5,8000431e <end_op+0xbc>
    acquire(&log.lock);
    800042b4:	0005d497          	auipc	s1,0x5d
    800042b8:	fbc48493          	addi	s1,s1,-68 # 80061270 <log>
    800042bc:	8526                	mv	a0,s1
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	a70080e7          	jalr	-1424(ra) # 80000d2e <acquire>
    log.committing = 0;
    800042c6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffe097          	auipc	ra,0xffffe
    800042d0:	09c080e7          	jalr	156(ra) # 80002368 <wakeup>
    release(&log.lock);
    800042d4:	8526                	mv	a0,s1
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	b0c080e7          	jalr	-1268(ra) # 80000de2 <release>
}
    800042de:	70e2                	ld	ra,56(sp)
    800042e0:	7442                	ld	s0,48(sp)
    800042e2:	74a2                	ld	s1,40(sp)
    800042e4:	7902                	ld	s2,32(sp)
    800042e6:	69e2                	ld	s3,24(sp)
    800042e8:	6a42                	ld	s4,16(sp)
    800042ea:	6aa2                	ld	s5,8(sp)
    800042ec:	6121                	addi	sp,sp,64
    800042ee:	8082                	ret
    panic("log.committing");
    800042f0:	00004517          	auipc	a0,0x4
    800042f4:	39050513          	addi	a0,a0,912 # 80008680 <syscalls+0x1e0>
    800042f8:	ffffc097          	auipc	ra,0xffffc
    800042fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
    wakeup(&log);
    80004300:	0005d497          	auipc	s1,0x5d
    80004304:	f7048493          	addi	s1,s1,-144 # 80061270 <log>
    80004308:	8526                	mv	a0,s1
    8000430a:	ffffe097          	auipc	ra,0xffffe
    8000430e:	05e080e7          	jalr	94(ra) # 80002368 <wakeup>
  release(&log.lock);
    80004312:	8526                	mv	a0,s1
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	ace080e7          	jalr	-1330(ra) # 80000de2 <release>
  if(do_commit){
    8000431c:	b7c9                	j	800042de <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431e:	0005da97          	auipc	s5,0x5d
    80004322:	f82a8a93          	addi	s5,s5,-126 # 800612a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004326:	0005da17          	auipc	s4,0x5d
    8000432a:	f4aa0a13          	addi	s4,s4,-182 # 80061270 <log>
    8000432e:	018a2583          	lw	a1,24(s4)
    80004332:	012585bb          	addw	a1,a1,s2
    80004336:	2585                	addiw	a1,a1,1
    80004338:	028a2503          	lw	a0,40(s4)
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	cd2080e7          	jalr	-814(ra) # 8000300e <bread>
    80004344:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004346:	000aa583          	lw	a1,0(s5)
    8000434a:	028a2503          	lw	a0,40(s4)
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	cc0080e7          	jalr	-832(ra) # 8000300e <bread>
    80004356:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004358:	40000613          	li	a2,1024
    8000435c:	05850593          	addi	a1,a0,88
    80004360:	05848513          	addi	a0,s1,88
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	b26080e7          	jalr	-1242(ra) # 80000e8a <memmove>
    bwrite(to);  // write the log
    8000436c:	8526                	mv	a0,s1
    8000436e:	fffff097          	auipc	ra,0xfffff
    80004372:	d92080e7          	jalr	-622(ra) # 80003100 <bwrite>
    brelse(from);
    80004376:	854e                	mv	a0,s3
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	dc6080e7          	jalr	-570(ra) # 8000313e <brelse>
    brelse(to);
    80004380:	8526                	mv	a0,s1
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	dbc080e7          	jalr	-580(ra) # 8000313e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000438a:	2905                	addiw	s2,s2,1
    8000438c:	0a91                	addi	s5,s5,4
    8000438e:	02ca2783          	lw	a5,44(s4)
    80004392:	f8f94ee3          	blt	s2,a5,8000432e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	c6a080e7          	jalr	-918(ra) # 80004000 <write_head>
    install_trans(0); // Now install writes to home locations
    8000439e:	4501                	li	a0,0
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	cda080e7          	jalr	-806(ra) # 8000407a <install_trans>
    log.lh.n = 0;
    800043a8:	0005d797          	auipc	a5,0x5d
    800043ac:	ee07aa23          	sw	zero,-268(a5) # 8006129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043b0:	00000097          	auipc	ra,0x0
    800043b4:	c50080e7          	jalr	-944(ra) # 80004000 <write_head>
    800043b8:	bdf5                	j	800042b4 <end_op+0x52>

00000000800043ba <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043ba:	1101                	addi	sp,sp,-32
    800043bc:	ec06                	sd	ra,24(sp)
    800043be:	e822                	sd	s0,16(sp)
    800043c0:	e426                	sd	s1,8(sp)
    800043c2:	e04a                	sd	s2,0(sp)
    800043c4:	1000                	addi	s0,sp,32
    800043c6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043c8:	0005d917          	auipc	s2,0x5d
    800043cc:	ea890913          	addi	s2,s2,-344 # 80061270 <log>
    800043d0:	854a                	mv	a0,s2
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	95c080e7          	jalr	-1700(ra) # 80000d2e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043da:	02c92603          	lw	a2,44(s2)
    800043de:	47f5                	li	a5,29
    800043e0:	06c7c563          	blt	a5,a2,8000444a <log_write+0x90>
    800043e4:	0005d797          	auipc	a5,0x5d
    800043e8:	ea87a783          	lw	a5,-344(a5) # 8006128c <log+0x1c>
    800043ec:	37fd                	addiw	a5,a5,-1
    800043ee:	04f65e63          	bge	a2,a5,8000444a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043f2:	0005d797          	auipc	a5,0x5d
    800043f6:	e9e7a783          	lw	a5,-354(a5) # 80061290 <log+0x20>
    800043fa:	06f05063          	blez	a5,8000445a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043fe:	4781                	li	a5,0
    80004400:	06c05563          	blez	a2,8000446a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004404:	44cc                	lw	a1,12(s1)
    80004406:	0005d717          	auipc	a4,0x5d
    8000440a:	e9a70713          	addi	a4,a4,-358 # 800612a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000440e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004410:	4314                	lw	a3,0(a4)
    80004412:	04b68c63          	beq	a3,a1,8000446a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004416:	2785                	addiw	a5,a5,1
    80004418:	0711                	addi	a4,a4,4
    8000441a:	fef61be3          	bne	a2,a5,80004410 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000441e:	0621                	addi	a2,a2,8
    80004420:	060a                	slli	a2,a2,0x2
    80004422:	0005d797          	auipc	a5,0x5d
    80004426:	e4e78793          	addi	a5,a5,-434 # 80061270 <log>
    8000442a:	963e                	add	a2,a2,a5
    8000442c:	44dc                	lw	a5,12(s1)
    8000442e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004430:	8526                	mv	a0,s1
    80004432:	fffff097          	auipc	ra,0xfffff
    80004436:	daa080e7          	jalr	-598(ra) # 800031dc <bpin>
    log.lh.n++;
    8000443a:	0005d717          	auipc	a4,0x5d
    8000443e:	e3670713          	addi	a4,a4,-458 # 80061270 <log>
    80004442:	575c                	lw	a5,44(a4)
    80004444:	2785                	addiw	a5,a5,1
    80004446:	d75c                	sw	a5,44(a4)
    80004448:	a835                	j	80004484 <log_write+0xca>
    panic("too big a transaction");
    8000444a:	00004517          	auipc	a0,0x4
    8000444e:	24650513          	addi	a0,a0,582 # 80008690 <syscalls+0x1f0>
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	0ec080e7          	jalr	236(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000445a:	00004517          	auipc	a0,0x4
    8000445e:	24e50513          	addi	a0,a0,590 # 800086a8 <syscalls+0x208>
    80004462:	ffffc097          	auipc	ra,0xffffc
    80004466:	0dc080e7          	jalr	220(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000446a:	00878713          	addi	a4,a5,8
    8000446e:	00271693          	slli	a3,a4,0x2
    80004472:	0005d717          	auipc	a4,0x5d
    80004476:	dfe70713          	addi	a4,a4,-514 # 80061270 <log>
    8000447a:	9736                	add	a4,a4,a3
    8000447c:	44d4                	lw	a3,12(s1)
    8000447e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004480:	faf608e3          	beq	a2,a5,80004430 <log_write+0x76>
  }
  release(&log.lock);
    80004484:	0005d517          	auipc	a0,0x5d
    80004488:	dec50513          	addi	a0,a0,-532 # 80061270 <log>
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	956080e7          	jalr	-1706(ra) # 80000de2 <release>
}
    80004494:	60e2                	ld	ra,24(sp)
    80004496:	6442                	ld	s0,16(sp)
    80004498:	64a2                	ld	s1,8(sp)
    8000449a:	6902                	ld	s2,0(sp)
    8000449c:	6105                	addi	sp,sp,32
    8000449e:	8082                	ret

00000000800044a0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044a0:	1101                	addi	sp,sp,-32
    800044a2:	ec06                	sd	ra,24(sp)
    800044a4:	e822                	sd	s0,16(sp)
    800044a6:	e426                	sd	s1,8(sp)
    800044a8:	e04a                	sd	s2,0(sp)
    800044aa:	1000                	addi	s0,sp,32
    800044ac:	84aa                	mv	s1,a0
    800044ae:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044b0:	00004597          	auipc	a1,0x4
    800044b4:	21858593          	addi	a1,a1,536 # 800086c8 <syscalls+0x228>
    800044b8:	0521                	addi	a0,a0,8
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	7e4080e7          	jalr	2020(ra) # 80000c9e <initlock>
  lk->name = name;
    800044c2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ca:	0204a423          	sw	zero,40(s1)
}
    800044ce:	60e2                	ld	ra,24(sp)
    800044d0:	6442                	ld	s0,16(sp)
    800044d2:	64a2                	ld	s1,8(sp)
    800044d4:	6902                	ld	s2,0(sp)
    800044d6:	6105                	addi	sp,sp,32
    800044d8:	8082                	ret

00000000800044da <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044da:	1101                	addi	sp,sp,-32
    800044dc:	ec06                	sd	ra,24(sp)
    800044de:	e822                	sd	s0,16(sp)
    800044e0:	e426                	sd	s1,8(sp)
    800044e2:	e04a                	sd	s2,0(sp)
    800044e4:	1000                	addi	s0,sp,32
    800044e6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e8:	00850913          	addi	s2,a0,8
    800044ec:	854a                	mv	a0,s2
    800044ee:	ffffd097          	auipc	ra,0xffffd
    800044f2:	840080e7          	jalr	-1984(ra) # 80000d2e <acquire>
  while (lk->locked) {
    800044f6:	409c                	lw	a5,0(s1)
    800044f8:	cb89                	beqz	a5,8000450a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044fa:	85ca                	mv	a1,s2
    800044fc:	8526                	mv	a0,s1
    800044fe:	ffffe097          	auipc	ra,0xffffe
    80004502:	cde080e7          	jalr	-802(ra) # 800021dc <sleep>
  while (lk->locked) {
    80004506:	409c                	lw	a5,0(s1)
    80004508:	fbed                	bnez	a5,800044fa <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000450a:	4785                	li	a5,1
    8000450c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000450e:	ffffd097          	auipc	ra,0xffffd
    80004512:	612080e7          	jalr	1554(ra) # 80001b20 <myproc>
    80004516:	591c                	lw	a5,48(a0)
    80004518:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000451a:	854a                	mv	a0,s2
    8000451c:	ffffd097          	auipc	ra,0xffffd
    80004520:	8c6080e7          	jalr	-1850(ra) # 80000de2 <release>
}
    80004524:	60e2                	ld	ra,24(sp)
    80004526:	6442                	ld	s0,16(sp)
    80004528:	64a2                	ld	s1,8(sp)
    8000452a:	6902                	ld	s2,0(sp)
    8000452c:	6105                	addi	sp,sp,32
    8000452e:	8082                	ret

0000000080004530 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004530:	1101                	addi	sp,sp,-32
    80004532:	ec06                	sd	ra,24(sp)
    80004534:	e822                	sd	s0,16(sp)
    80004536:	e426                	sd	s1,8(sp)
    80004538:	e04a                	sd	s2,0(sp)
    8000453a:	1000                	addi	s0,sp,32
    8000453c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000453e:	00850913          	addi	s2,a0,8
    80004542:	854a                	mv	a0,s2
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	7ea080e7          	jalr	2026(ra) # 80000d2e <acquire>
  lk->locked = 0;
    8000454c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004550:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004554:	8526                	mv	a0,s1
    80004556:	ffffe097          	auipc	ra,0xffffe
    8000455a:	e12080e7          	jalr	-494(ra) # 80002368 <wakeup>
  release(&lk->lk);
    8000455e:	854a                	mv	a0,s2
    80004560:	ffffd097          	auipc	ra,0xffffd
    80004564:	882080e7          	jalr	-1918(ra) # 80000de2 <release>
}
    80004568:	60e2                	ld	ra,24(sp)
    8000456a:	6442                	ld	s0,16(sp)
    8000456c:	64a2                	ld	s1,8(sp)
    8000456e:	6902                	ld	s2,0(sp)
    80004570:	6105                	addi	sp,sp,32
    80004572:	8082                	ret

0000000080004574 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004574:	7179                	addi	sp,sp,-48
    80004576:	f406                	sd	ra,40(sp)
    80004578:	f022                	sd	s0,32(sp)
    8000457a:	ec26                	sd	s1,24(sp)
    8000457c:	e84a                	sd	s2,16(sp)
    8000457e:	e44e                	sd	s3,8(sp)
    80004580:	1800                	addi	s0,sp,48
    80004582:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004584:	00850913          	addi	s2,a0,8
    80004588:	854a                	mv	a0,s2
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	7a4080e7          	jalr	1956(ra) # 80000d2e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004592:	409c                	lw	a5,0(s1)
    80004594:	ef99                	bnez	a5,800045b2 <holdingsleep+0x3e>
    80004596:	4481                	li	s1,0
  release(&lk->lk);
    80004598:	854a                	mv	a0,s2
    8000459a:	ffffd097          	auipc	ra,0xffffd
    8000459e:	848080e7          	jalr	-1976(ra) # 80000de2 <release>
  return r;
}
    800045a2:	8526                	mv	a0,s1
    800045a4:	70a2                	ld	ra,40(sp)
    800045a6:	7402                	ld	s0,32(sp)
    800045a8:	64e2                	ld	s1,24(sp)
    800045aa:	6942                	ld	s2,16(sp)
    800045ac:	69a2                	ld	s3,8(sp)
    800045ae:	6145                	addi	sp,sp,48
    800045b0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045b2:	0284a983          	lw	s3,40(s1)
    800045b6:	ffffd097          	auipc	ra,0xffffd
    800045ba:	56a080e7          	jalr	1386(ra) # 80001b20 <myproc>
    800045be:	5904                	lw	s1,48(a0)
    800045c0:	413484b3          	sub	s1,s1,s3
    800045c4:	0014b493          	seqz	s1,s1
    800045c8:	bfc1                	j	80004598 <holdingsleep+0x24>

00000000800045ca <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045ca:	1141                	addi	sp,sp,-16
    800045cc:	e406                	sd	ra,8(sp)
    800045ce:	e022                	sd	s0,0(sp)
    800045d0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045d2:	00004597          	auipc	a1,0x4
    800045d6:	10658593          	addi	a1,a1,262 # 800086d8 <syscalls+0x238>
    800045da:	0005d517          	auipc	a0,0x5d
    800045de:	dde50513          	addi	a0,a0,-546 # 800613b8 <ftable>
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	6bc080e7          	jalr	1724(ra) # 80000c9e <initlock>
}
    800045ea:	60a2                	ld	ra,8(sp)
    800045ec:	6402                	ld	s0,0(sp)
    800045ee:	0141                	addi	sp,sp,16
    800045f0:	8082                	ret

00000000800045f2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045f2:	1101                	addi	sp,sp,-32
    800045f4:	ec06                	sd	ra,24(sp)
    800045f6:	e822                	sd	s0,16(sp)
    800045f8:	e426                	sd	s1,8(sp)
    800045fa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045fc:	0005d517          	auipc	a0,0x5d
    80004600:	dbc50513          	addi	a0,a0,-580 # 800613b8 <ftable>
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	72a080e7          	jalr	1834(ra) # 80000d2e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000460c:	0005d497          	auipc	s1,0x5d
    80004610:	dc448493          	addi	s1,s1,-572 # 800613d0 <ftable+0x18>
    80004614:	0005e717          	auipc	a4,0x5e
    80004618:	d5c70713          	addi	a4,a4,-676 # 80062370 <ftable+0xfb8>
    if(f->ref == 0){
    8000461c:	40dc                	lw	a5,4(s1)
    8000461e:	cf99                	beqz	a5,8000463c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004620:	02848493          	addi	s1,s1,40
    80004624:	fee49ce3          	bne	s1,a4,8000461c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004628:	0005d517          	auipc	a0,0x5d
    8000462c:	d9050513          	addi	a0,a0,-624 # 800613b8 <ftable>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	7b2080e7          	jalr	1970(ra) # 80000de2 <release>
  return 0;
    80004638:	4481                	li	s1,0
    8000463a:	a819                	j	80004650 <filealloc+0x5e>
      f->ref = 1;
    8000463c:	4785                	li	a5,1
    8000463e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004640:	0005d517          	auipc	a0,0x5d
    80004644:	d7850513          	addi	a0,a0,-648 # 800613b8 <ftable>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	79a080e7          	jalr	1946(ra) # 80000de2 <release>
}
    80004650:	8526                	mv	a0,s1
    80004652:	60e2                	ld	ra,24(sp)
    80004654:	6442                	ld	s0,16(sp)
    80004656:	64a2                	ld	s1,8(sp)
    80004658:	6105                	addi	sp,sp,32
    8000465a:	8082                	ret

000000008000465c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000465c:	1101                	addi	sp,sp,-32
    8000465e:	ec06                	sd	ra,24(sp)
    80004660:	e822                	sd	s0,16(sp)
    80004662:	e426                	sd	s1,8(sp)
    80004664:	1000                	addi	s0,sp,32
    80004666:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004668:	0005d517          	auipc	a0,0x5d
    8000466c:	d5050513          	addi	a0,a0,-688 # 800613b8 <ftable>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	6be080e7          	jalr	1726(ra) # 80000d2e <acquire>
  if(f->ref < 1)
    80004678:	40dc                	lw	a5,4(s1)
    8000467a:	02f05263          	blez	a5,8000469e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000467e:	2785                	addiw	a5,a5,1
    80004680:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004682:	0005d517          	auipc	a0,0x5d
    80004686:	d3650513          	addi	a0,a0,-714 # 800613b8 <ftable>
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	758080e7          	jalr	1880(ra) # 80000de2 <release>
  return f;
}
    80004692:	8526                	mv	a0,s1
    80004694:	60e2                	ld	ra,24(sp)
    80004696:	6442                	ld	s0,16(sp)
    80004698:	64a2                	ld	s1,8(sp)
    8000469a:	6105                	addi	sp,sp,32
    8000469c:	8082                	ret
    panic("filedup");
    8000469e:	00004517          	auipc	a0,0x4
    800046a2:	04250513          	addi	a0,a0,66 # 800086e0 <syscalls+0x240>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	e98080e7          	jalr	-360(ra) # 8000053e <panic>

00000000800046ae <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046ae:	7139                	addi	sp,sp,-64
    800046b0:	fc06                	sd	ra,56(sp)
    800046b2:	f822                	sd	s0,48(sp)
    800046b4:	f426                	sd	s1,40(sp)
    800046b6:	f04a                	sd	s2,32(sp)
    800046b8:	ec4e                	sd	s3,24(sp)
    800046ba:	e852                	sd	s4,16(sp)
    800046bc:	e456                	sd	s5,8(sp)
    800046be:	0080                	addi	s0,sp,64
    800046c0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046c2:	0005d517          	auipc	a0,0x5d
    800046c6:	cf650513          	addi	a0,a0,-778 # 800613b8 <ftable>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	664080e7          	jalr	1636(ra) # 80000d2e <acquire>
  if(f->ref < 1)
    800046d2:	40dc                	lw	a5,4(s1)
    800046d4:	06f05163          	blez	a5,80004736 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046d8:	37fd                	addiw	a5,a5,-1
    800046da:	0007871b          	sext.w	a4,a5
    800046de:	c0dc                	sw	a5,4(s1)
    800046e0:	06e04363          	bgtz	a4,80004746 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046e4:	0004a903          	lw	s2,0(s1)
    800046e8:	0094ca83          	lbu	s5,9(s1)
    800046ec:	0104ba03          	ld	s4,16(s1)
    800046f0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046f4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046f8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046fc:	0005d517          	auipc	a0,0x5d
    80004700:	cbc50513          	addi	a0,a0,-836 # 800613b8 <ftable>
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	6de080e7          	jalr	1758(ra) # 80000de2 <release>

  if(ff.type == FD_PIPE){
    8000470c:	4785                	li	a5,1
    8000470e:	04f90d63          	beq	s2,a5,80004768 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004712:	3979                	addiw	s2,s2,-2
    80004714:	4785                	li	a5,1
    80004716:	0527e063          	bltu	a5,s2,80004756 <fileclose+0xa8>
    begin_op();
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	ac8080e7          	jalr	-1336(ra) # 800041e2 <begin_op>
    iput(ff.ip);
    80004722:	854e                	mv	a0,s3
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	2a6080e7          	jalr	678(ra) # 800039ca <iput>
    end_op();
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	b36080e7          	jalr	-1226(ra) # 80004262 <end_op>
    80004734:	a00d                	j	80004756 <fileclose+0xa8>
    panic("fileclose");
    80004736:	00004517          	auipc	a0,0x4
    8000473a:	fb250513          	addi	a0,a0,-78 # 800086e8 <syscalls+0x248>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	e00080e7          	jalr	-512(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004746:	0005d517          	auipc	a0,0x5d
    8000474a:	c7250513          	addi	a0,a0,-910 # 800613b8 <ftable>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	694080e7          	jalr	1684(ra) # 80000de2 <release>
  }
}
    80004756:	70e2                	ld	ra,56(sp)
    80004758:	7442                	ld	s0,48(sp)
    8000475a:	74a2                	ld	s1,40(sp)
    8000475c:	7902                	ld	s2,32(sp)
    8000475e:	69e2                	ld	s3,24(sp)
    80004760:	6a42                	ld	s4,16(sp)
    80004762:	6aa2                	ld	s5,8(sp)
    80004764:	6121                	addi	sp,sp,64
    80004766:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004768:	85d6                	mv	a1,s5
    8000476a:	8552                	mv	a0,s4
    8000476c:	00000097          	auipc	ra,0x0
    80004770:	34c080e7          	jalr	844(ra) # 80004ab8 <pipeclose>
    80004774:	b7cd                	j	80004756 <fileclose+0xa8>

0000000080004776 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004776:	715d                	addi	sp,sp,-80
    80004778:	e486                	sd	ra,72(sp)
    8000477a:	e0a2                	sd	s0,64(sp)
    8000477c:	fc26                	sd	s1,56(sp)
    8000477e:	f84a                	sd	s2,48(sp)
    80004780:	f44e                	sd	s3,40(sp)
    80004782:	0880                	addi	s0,sp,80
    80004784:	84aa                	mv	s1,a0
    80004786:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004788:	ffffd097          	auipc	ra,0xffffd
    8000478c:	398080e7          	jalr	920(ra) # 80001b20 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004790:	409c                	lw	a5,0(s1)
    80004792:	37f9                	addiw	a5,a5,-2
    80004794:	4705                	li	a4,1
    80004796:	04f76763          	bltu	a4,a5,800047e4 <filestat+0x6e>
    8000479a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000479c:	6c88                	ld	a0,24(s1)
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	072080e7          	jalr	114(ra) # 80003810 <ilock>
    stati(f->ip, &st);
    800047a6:	fb840593          	addi	a1,s0,-72
    800047aa:	6c88                	ld	a0,24(s1)
    800047ac:	fffff097          	auipc	ra,0xfffff
    800047b0:	2ee080e7          	jalr	750(ra) # 80003a9a <stati>
    iunlock(f->ip);
    800047b4:	6c88                	ld	a0,24(s1)
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	11c080e7          	jalr	284(ra) # 800038d2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047be:	46e1                	li	a3,24
    800047c0:	fb840613          	addi	a2,s0,-72
    800047c4:	85ce                	mv	a1,s3
    800047c6:	05093503          	ld	a0,80(s2)
    800047ca:	ffffd097          	auipc	ra,0xffffd
    800047ce:	ff2080e7          	jalr	-14(ra) # 800017bc <copyout>
    800047d2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047d6:	60a6                	ld	ra,72(sp)
    800047d8:	6406                	ld	s0,64(sp)
    800047da:	74e2                	ld	s1,56(sp)
    800047dc:	7942                	ld	s2,48(sp)
    800047de:	79a2                	ld	s3,40(sp)
    800047e0:	6161                	addi	sp,sp,80
    800047e2:	8082                	ret
  return -1;
    800047e4:	557d                	li	a0,-1
    800047e6:	bfc5                	j	800047d6 <filestat+0x60>

00000000800047e8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047e8:	7179                	addi	sp,sp,-48
    800047ea:	f406                	sd	ra,40(sp)
    800047ec:	f022                	sd	s0,32(sp)
    800047ee:	ec26                	sd	s1,24(sp)
    800047f0:	e84a                	sd	s2,16(sp)
    800047f2:	e44e                	sd	s3,8(sp)
    800047f4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047f6:	00854783          	lbu	a5,8(a0)
    800047fa:	c3d5                	beqz	a5,8000489e <fileread+0xb6>
    800047fc:	84aa                	mv	s1,a0
    800047fe:	89ae                	mv	s3,a1
    80004800:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004802:	411c                	lw	a5,0(a0)
    80004804:	4705                	li	a4,1
    80004806:	04e78963          	beq	a5,a4,80004858 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000480a:	470d                	li	a4,3
    8000480c:	04e78d63          	beq	a5,a4,80004866 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004810:	4709                	li	a4,2
    80004812:	06e79e63          	bne	a5,a4,8000488e <fileread+0xa6>
    ilock(f->ip);
    80004816:	6d08                	ld	a0,24(a0)
    80004818:	fffff097          	auipc	ra,0xfffff
    8000481c:	ff8080e7          	jalr	-8(ra) # 80003810 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004820:	874a                	mv	a4,s2
    80004822:	5094                	lw	a3,32(s1)
    80004824:	864e                	mv	a2,s3
    80004826:	4585                	li	a1,1
    80004828:	6c88                	ld	a0,24(s1)
    8000482a:	fffff097          	auipc	ra,0xfffff
    8000482e:	29a080e7          	jalr	666(ra) # 80003ac4 <readi>
    80004832:	892a                	mv	s2,a0
    80004834:	00a05563          	blez	a0,8000483e <fileread+0x56>
      f->off += r;
    80004838:	509c                	lw	a5,32(s1)
    8000483a:	9fa9                	addw	a5,a5,a0
    8000483c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000483e:	6c88                	ld	a0,24(s1)
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	092080e7          	jalr	146(ra) # 800038d2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004848:	854a                	mv	a0,s2
    8000484a:	70a2                	ld	ra,40(sp)
    8000484c:	7402                	ld	s0,32(sp)
    8000484e:	64e2                	ld	s1,24(sp)
    80004850:	6942                	ld	s2,16(sp)
    80004852:	69a2                	ld	s3,8(sp)
    80004854:	6145                	addi	sp,sp,48
    80004856:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004858:	6908                	ld	a0,16(a0)
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	3c8080e7          	jalr	968(ra) # 80004c22 <piperead>
    80004862:	892a                	mv	s2,a0
    80004864:	b7d5                	j	80004848 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004866:	02451783          	lh	a5,36(a0)
    8000486a:	03079693          	slli	a3,a5,0x30
    8000486e:	92c1                	srli	a3,a3,0x30
    80004870:	4725                	li	a4,9
    80004872:	02d76863          	bltu	a4,a3,800048a2 <fileread+0xba>
    80004876:	0792                	slli	a5,a5,0x4
    80004878:	0005d717          	auipc	a4,0x5d
    8000487c:	aa070713          	addi	a4,a4,-1376 # 80061318 <devsw>
    80004880:	97ba                	add	a5,a5,a4
    80004882:	639c                	ld	a5,0(a5)
    80004884:	c38d                	beqz	a5,800048a6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004886:	4505                	li	a0,1
    80004888:	9782                	jalr	a5
    8000488a:	892a                	mv	s2,a0
    8000488c:	bf75                	j	80004848 <fileread+0x60>
    panic("fileread");
    8000488e:	00004517          	auipc	a0,0x4
    80004892:	e6a50513          	addi	a0,a0,-406 # 800086f8 <syscalls+0x258>
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	ca8080e7          	jalr	-856(ra) # 8000053e <panic>
    return -1;
    8000489e:	597d                	li	s2,-1
    800048a0:	b765                	j	80004848 <fileread+0x60>
      return -1;
    800048a2:	597d                	li	s2,-1
    800048a4:	b755                	j	80004848 <fileread+0x60>
    800048a6:	597d                	li	s2,-1
    800048a8:	b745                	j	80004848 <fileread+0x60>

00000000800048aa <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048aa:	715d                	addi	sp,sp,-80
    800048ac:	e486                	sd	ra,72(sp)
    800048ae:	e0a2                	sd	s0,64(sp)
    800048b0:	fc26                	sd	s1,56(sp)
    800048b2:	f84a                	sd	s2,48(sp)
    800048b4:	f44e                	sd	s3,40(sp)
    800048b6:	f052                	sd	s4,32(sp)
    800048b8:	ec56                	sd	s5,24(sp)
    800048ba:	e85a                	sd	s6,16(sp)
    800048bc:	e45e                	sd	s7,8(sp)
    800048be:	e062                	sd	s8,0(sp)
    800048c0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048c2:	00954783          	lbu	a5,9(a0)
    800048c6:	10078663          	beqz	a5,800049d2 <filewrite+0x128>
    800048ca:	892a                	mv	s2,a0
    800048cc:	8aae                	mv	s5,a1
    800048ce:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048d0:	411c                	lw	a5,0(a0)
    800048d2:	4705                	li	a4,1
    800048d4:	02e78263          	beq	a5,a4,800048f8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048d8:	470d                	li	a4,3
    800048da:	02e78663          	beq	a5,a4,80004906 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048de:	4709                	li	a4,2
    800048e0:	0ee79163          	bne	a5,a4,800049c2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048e4:	0ac05d63          	blez	a2,8000499e <filewrite+0xf4>
    int i = 0;
    800048e8:	4981                	li	s3,0
    800048ea:	6b05                	lui	s6,0x1
    800048ec:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048f0:	6b85                	lui	s7,0x1
    800048f2:	c00b8b9b          	addiw	s7,s7,-1024
    800048f6:	a861                	j	8000498e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048f8:	6908                	ld	a0,16(a0)
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	22e080e7          	jalr	558(ra) # 80004b28 <pipewrite>
    80004902:	8a2a                	mv	s4,a0
    80004904:	a045                	j	800049a4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004906:	02451783          	lh	a5,36(a0)
    8000490a:	03079693          	slli	a3,a5,0x30
    8000490e:	92c1                	srli	a3,a3,0x30
    80004910:	4725                	li	a4,9
    80004912:	0cd76263          	bltu	a4,a3,800049d6 <filewrite+0x12c>
    80004916:	0792                	slli	a5,a5,0x4
    80004918:	0005d717          	auipc	a4,0x5d
    8000491c:	a0070713          	addi	a4,a4,-1536 # 80061318 <devsw>
    80004920:	97ba                	add	a5,a5,a4
    80004922:	679c                	ld	a5,8(a5)
    80004924:	cbdd                	beqz	a5,800049da <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004926:	4505                	li	a0,1
    80004928:	9782                	jalr	a5
    8000492a:	8a2a                	mv	s4,a0
    8000492c:	a8a5                	j	800049a4 <filewrite+0xfa>
    8000492e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004932:	00000097          	auipc	ra,0x0
    80004936:	8b0080e7          	jalr	-1872(ra) # 800041e2 <begin_op>
      ilock(f->ip);
    8000493a:	01893503          	ld	a0,24(s2)
    8000493e:	fffff097          	auipc	ra,0xfffff
    80004942:	ed2080e7          	jalr	-302(ra) # 80003810 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004946:	8762                	mv	a4,s8
    80004948:	02092683          	lw	a3,32(s2)
    8000494c:	01598633          	add	a2,s3,s5
    80004950:	4585                	li	a1,1
    80004952:	01893503          	ld	a0,24(s2)
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	266080e7          	jalr	614(ra) # 80003bbc <writei>
    8000495e:	84aa                	mv	s1,a0
    80004960:	00a05763          	blez	a0,8000496e <filewrite+0xc4>
        f->off += r;
    80004964:	02092783          	lw	a5,32(s2)
    80004968:	9fa9                	addw	a5,a5,a0
    8000496a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000496e:	01893503          	ld	a0,24(s2)
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	f60080e7          	jalr	-160(ra) # 800038d2 <iunlock>
      end_op();
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	8e8080e7          	jalr	-1816(ra) # 80004262 <end_op>

      if(r != n1){
    80004982:	009c1f63          	bne	s8,s1,800049a0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004986:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000498a:	0149db63          	bge	s3,s4,800049a0 <filewrite+0xf6>
      int n1 = n - i;
    8000498e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004992:	84be                	mv	s1,a5
    80004994:	2781                	sext.w	a5,a5
    80004996:	f8fb5ce3          	bge	s6,a5,8000492e <filewrite+0x84>
    8000499a:	84de                	mv	s1,s7
    8000499c:	bf49                	j	8000492e <filewrite+0x84>
    int i = 0;
    8000499e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049a0:	013a1f63          	bne	s4,s3,800049be <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049a4:	8552                	mv	a0,s4
    800049a6:	60a6                	ld	ra,72(sp)
    800049a8:	6406                	ld	s0,64(sp)
    800049aa:	74e2                	ld	s1,56(sp)
    800049ac:	7942                	ld	s2,48(sp)
    800049ae:	79a2                	ld	s3,40(sp)
    800049b0:	7a02                	ld	s4,32(sp)
    800049b2:	6ae2                	ld	s5,24(sp)
    800049b4:	6b42                	ld	s6,16(sp)
    800049b6:	6ba2                	ld	s7,8(sp)
    800049b8:	6c02                	ld	s8,0(sp)
    800049ba:	6161                	addi	sp,sp,80
    800049bc:	8082                	ret
    ret = (i == n ? n : -1);
    800049be:	5a7d                	li	s4,-1
    800049c0:	b7d5                	j	800049a4 <filewrite+0xfa>
    panic("filewrite");
    800049c2:	00004517          	auipc	a0,0x4
    800049c6:	d4650513          	addi	a0,a0,-698 # 80008708 <syscalls+0x268>
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	b74080e7          	jalr	-1164(ra) # 8000053e <panic>
    return -1;
    800049d2:	5a7d                	li	s4,-1
    800049d4:	bfc1                	j	800049a4 <filewrite+0xfa>
      return -1;
    800049d6:	5a7d                	li	s4,-1
    800049d8:	b7f1                	j	800049a4 <filewrite+0xfa>
    800049da:	5a7d                	li	s4,-1
    800049dc:	b7e1                	j	800049a4 <filewrite+0xfa>

00000000800049de <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049de:	7179                	addi	sp,sp,-48
    800049e0:	f406                	sd	ra,40(sp)
    800049e2:	f022                	sd	s0,32(sp)
    800049e4:	ec26                	sd	s1,24(sp)
    800049e6:	e84a                	sd	s2,16(sp)
    800049e8:	e44e                	sd	s3,8(sp)
    800049ea:	e052                	sd	s4,0(sp)
    800049ec:	1800                	addi	s0,sp,48
    800049ee:	84aa                	mv	s1,a0
    800049f0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049f2:	0005b023          	sd	zero,0(a1)
    800049f6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049fa:	00000097          	auipc	ra,0x0
    800049fe:	bf8080e7          	jalr	-1032(ra) # 800045f2 <filealloc>
    80004a02:	e088                	sd	a0,0(s1)
    80004a04:	c551                	beqz	a0,80004a90 <pipealloc+0xb2>
    80004a06:	00000097          	auipc	ra,0x0
    80004a0a:	bec080e7          	jalr	-1044(ra) # 800045f2 <filealloc>
    80004a0e:	00aa3023          	sd	a0,0(s4)
    80004a12:	c92d                	beqz	a0,80004a84 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	20e080e7          	jalr	526(ra) # 80000c22 <kalloc>
    80004a1c:	892a                	mv	s2,a0
    80004a1e:	c125                	beqz	a0,80004a7e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a20:	4985                	li	s3,1
    80004a22:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a26:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a2a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a2e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a32:	00004597          	auipc	a1,0x4
    80004a36:	ce658593          	addi	a1,a1,-794 # 80008718 <syscalls+0x278>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	264080e7          	jalr	612(ra) # 80000c9e <initlock>
  (*f0)->type = FD_PIPE;
    80004a42:	609c                	ld	a5,0(s1)
    80004a44:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a48:	609c                	ld	a5,0(s1)
    80004a4a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a4e:	609c                	ld	a5,0(s1)
    80004a50:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a54:	609c                	ld	a5,0(s1)
    80004a56:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a5a:	000a3783          	ld	a5,0(s4)
    80004a5e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a62:	000a3783          	ld	a5,0(s4)
    80004a66:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a6a:	000a3783          	ld	a5,0(s4)
    80004a6e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a72:	000a3783          	ld	a5,0(s4)
    80004a76:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a7a:	4501                	li	a0,0
    80004a7c:	a025                	j	80004aa4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a7e:	6088                	ld	a0,0(s1)
    80004a80:	e501                	bnez	a0,80004a88 <pipealloc+0xaa>
    80004a82:	a039                	j	80004a90 <pipealloc+0xb2>
    80004a84:	6088                	ld	a0,0(s1)
    80004a86:	c51d                	beqz	a0,80004ab4 <pipealloc+0xd6>
    fileclose(*f0);
    80004a88:	00000097          	auipc	ra,0x0
    80004a8c:	c26080e7          	jalr	-986(ra) # 800046ae <fileclose>
  if(*f1)
    80004a90:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a94:	557d                	li	a0,-1
  if(*f1)
    80004a96:	c799                	beqz	a5,80004aa4 <pipealloc+0xc6>
    fileclose(*f1);
    80004a98:	853e                	mv	a0,a5
    80004a9a:	00000097          	auipc	ra,0x0
    80004a9e:	c14080e7          	jalr	-1004(ra) # 800046ae <fileclose>
  return -1;
    80004aa2:	557d                	li	a0,-1
}
    80004aa4:	70a2                	ld	ra,40(sp)
    80004aa6:	7402                	ld	s0,32(sp)
    80004aa8:	64e2                	ld	s1,24(sp)
    80004aaa:	6942                	ld	s2,16(sp)
    80004aac:	69a2                	ld	s3,8(sp)
    80004aae:	6a02                	ld	s4,0(sp)
    80004ab0:	6145                	addi	sp,sp,48
    80004ab2:	8082                	ret
  return -1;
    80004ab4:	557d                	li	a0,-1
    80004ab6:	b7fd                	j	80004aa4 <pipealloc+0xc6>

0000000080004ab8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ab8:	1101                	addi	sp,sp,-32
    80004aba:	ec06                	sd	ra,24(sp)
    80004abc:	e822                	sd	s0,16(sp)
    80004abe:	e426                	sd	s1,8(sp)
    80004ac0:	e04a                	sd	s2,0(sp)
    80004ac2:	1000                	addi	s0,sp,32
    80004ac4:	84aa                	mv	s1,a0
    80004ac6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	266080e7          	jalr	614(ra) # 80000d2e <acquire>
  if(writable){
    80004ad0:	02090d63          	beqz	s2,80004b0a <pipeclose+0x52>
    pi->writeopen = 0;
    80004ad4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ad8:	21848513          	addi	a0,s1,536
    80004adc:	ffffe097          	auipc	ra,0xffffe
    80004ae0:	88c080e7          	jalr	-1908(ra) # 80002368 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ae4:	2204b783          	ld	a5,544(s1)
    80004ae8:	eb95                	bnez	a5,80004b1c <pipeclose+0x64>
    release(&pi->lock);
    80004aea:	8526                	mv	a0,s1
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	2f6080e7          	jalr	758(ra) # 80000de2 <release>
    kfree((char*)pi);
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	ff0080e7          	jalr	-16(ra) # 80000ae6 <kfree>
  } else
    release(&pi->lock);
}
    80004afe:	60e2                	ld	ra,24(sp)
    80004b00:	6442                	ld	s0,16(sp)
    80004b02:	64a2                	ld	s1,8(sp)
    80004b04:	6902                	ld	s2,0(sp)
    80004b06:	6105                	addi	sp,sp,32
    80004b08:	8082                	ret
    pi->readopen = 0;
    80004b0a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b0e:	21c48513          	addi	a0,s1,540
    80004b12:	ffffe097          	auipc	ra,0xffffe
    80004b16:	856080e7          	jalr	-1962(ra) # 80002368 <wakeup>
    80004b1a:	b7e9                	j	80004ae4 <pipeclose+0x2c>
    release(&pi->lock);
    80004b1c:	8526                	mv	a0,s1
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	2c4080e7          	jalr	708(ra) # 80000de2 <release>
}
    80004b26:	bfe1                	j	80004afe <pipeclose+0x46>

0000000080004b28 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b28:	7159                	addi	sp,sp,-112
    80004b2a:	f486                	sd	ra,104(sp)
    80004b2c:	f0a2                	sd	s0,96(sp)
    80004b2e:	eca6                	sd	s1,88(sp)
    80004b30:	e8ca                	sd	s2,80(sp)
    80004b32:	e4ce                	sd	s3,72(sp)
    80004b34:	e0d2                	sd	s4,64(sp)
    80004b36:	fc56                	sd	s5,56(sp)
    80004b38:	f85a                	sd	s6,48(sp)
    80004b3a:	f45e                	sd	s7,40(sp)
    80004b3c:	f062                	sd	s8,32(sp)
    80004b3e:	ec66                	sd	s9,24(sp)
    80004b40:	1880                	addi	s0,sp,112
    80004b42:	84aa                	mv	s1,a0
    80004b44:	8aae                	mv	s5,a1
    80004b46:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	fd8080e7          	jalr	-40(ra) # 80001b20 <myproc>
    80004b50:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b52:	8526                	mv	a0,s1
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	1da080e7          	jalr	474(ra) # 80000d2e <acquire>
  while(i < n){
    80004b5c:	0d405163          	blez	s4,80004c1e <pipewrite+0xf6>
    80004b60:	8ba6                	mv	s7,s1
  int i = 0;
    80004b62:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b64:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b66:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b6a:	21c48c13          	addi	s8,s1,540
    80004b6e:	a08d                	j	80004bd0 <pipewrite+0xa8>
      release(&pi->lock);
    80004b70:	8526                	mv	a0,s1
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	270080e7          	jalr	624(ra) # 80000de2 <release>
      return -1;
    80004b7a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b7c:	854a                	mv	a0,s2
    80004b7e:	70a6                	ld	ra,104(sp)
    80004b80:	7406                	ld	s0,96(sp)
    80004b82:	64e6                	ld	s1,88(sp)
    80004b84:	6946                	ld	s2,80(sp)
    80004b86:	69a6                	ld	s3,72(sp)
    80004b88:	6a06                	ld	s4,64(sp)
    80004b8a:	7ae2                	ld	s5,56(sp)
    80004b8c:	7b42                	ld	s6,48(sp)
    80004b8e:	7ba2                	ld	s7,40(sp)
    80004b90:	7c02                	ld	s8,32(sp)
    80004b92:	6ce2                	ld	s9,24(sp)
    80004b94:	6165                	addi	sp,sp,112
    80004b96:	8082                	ret
      wakeup(&pi->nread);
    80004b98:	8566                	mv	a0,s9
    80004b9a:	ffffd097          	auipc	ra,0xffffd
    80004b9e:	7ce080e7          	jalr	1998(ra) # 80002368 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ba2:	85de                	mv	a1,s7
    80004ba4:	8562                	mv	a0,s8
    80004ba6:	ffffd097          	auipc	ra,0xffffd
    80004baa:	636080e7          	jalr	1590(ra) # 800021dc <sleep>
    80004bae:	a839                	j	80004bcc <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bb0:	21c4a783          	lw	a5,540(s1)
    80004bb4:	0017871b          	addiw	a4,a5,1
    80004bb8:	20e4ae23          	sw	a4,540(s1)
    80004bbc:	1ff7f793          	andi	a5,a5,511
    80004bc0:	97a6                	add	a5,a5,s1
    80004bc2:	f9f44703          	lbu	a4,-97(s0)
    80004bc6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bca:	2905                	addiw	s2,s2,1
  while(i < n){
    80004bcc:	03495d63          	bge	s2,s4,80004c06 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004bd0:	2204a783          	lw	a5,544(s1)
    80004bd4:	dfd1                	beqz	a5,80004b70 <pipewrite+0x48>
    80004bd6:	0289a783          	lw	a5,40(s3)
    80004bda:	fbd9                	bnez	a5,80004b70 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bdc:	2184a783          	lw	a5,536(s1)
    80004be0:	21c4a703          	lw	a4,540(s1)
    80004be4:	2007879b          	addiw	a5,a5,512
    80004be8:	faf708e3          	beq	a4,a5,80004b98 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bec:	4685                	li	a3,1
    80004bee:	01590633          	add	a2,s2,s5
    80004bf2:	f9f40593          	addi	a1,s0,-97
    80004bf6:	0509b503          	ld	a0,80(s3)
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	c74080e7          	jalr	-908(ra) # 8000186e <copyin>
    80004c02:	fb6517e3          	bne	a0,s6,80004bb0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c06:	21848513          	addi	a0,s1,536
    80004c0a:	ffffd097          	auipc	ra,0xffffd
    80004c0e:	75e080e7          	jalr	1886(ra) # 80002368 <wakeup>
  release(&pi->lock);
    80004c12:	8526                	mv	a0,s1
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	1ce080e7          	jalr	462(ra) # 80000de2 <release>
  return i;
    80004c1c:	b785                	j	80004b7c <pipewrite+0x54>
  int i = 0;
    80004c1e:	4901                	li	s2,0
    80004c20:	b7dd                	j	80004c06 <pipewrite+0xde>

0000000080004c22 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c22:	715d                	addi	sp,sp,-80
    80004c24:	e486                	sd	ra,72(sp)
    80004c26:	e0a2                	sd	s0,64(sp)
    80004c28:	fc26                	sd	s1,56(sp)
    80004c2a:	f84a                	sd	s2,48(sp)
    80004c2c:	f44e                	sd	s3,40(sp)
    80004c2e:	f052                	sd	s4,32(sp)
    80004c30:	ec56                	sd	s5,24(sp)
    80004c32:	e85a                	sd	s6,16(sp)
    80004c34:	0880                	addi	s0,sp,80
    80004c36:	84aa                	mv	s1,a0
    80004c38:	892e                	mv	s2,a1
    80004c3a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	ee4080e7          	jalr	-284(ra) # 80001b20 <myproc>
    80004c44:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c46:	8b26                	mv	s6,s1
    80004c48:	8526                	mv	a0,s1
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	0e4080e7          	jalr	228(ra) # 80000d2e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c52:	2184a703          	lw	a4,536(s1)
    80004c56:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c5a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c5e:	02f71463          	bne	a4,a5,80004c86 <piperead+0x64>
    80004c62:	2244a783          	lw	a5,548(s1)
    80004c66:	c385                	beqz	a5,80004c86 <piperead+0x64>
    if(pr->killed){
    80004c68:	028a2783          	lw	a5,40(s4)
    80004c6c:	ebc1                	bnez	a5,80004cfc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c6e:	85da                	mv	a1,s6
    80004c70:	854e                	mv	a0,s3
    80004c72:	ffffd097          	auipc	ra,0xffffd
    80004c76:	56a080e7          	jalr	1386(ra) # 800021dc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c7a:	2184a703          	lw	a4,536(s1)
    80004c7e:	21c4a783          	lw	a5,540(s1)
    80004c82:	fef700e3          	beq	a4,a5,80004c62 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c86:	09505263          	blez	s5,80004d0a <piperead+0xe8>
    80004c8a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c8c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c8e:	2184a783          	lw	a5,536(s1)
    80004c92:	21c4a703          	lw	a4,540(s1)
    80004c96:	02f70d63          	beq	a4,a5,80004cd0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c9a:	0017871b          	addiw	a4,a5,1
    80004c9e:	20e4ac23          	sw	a4,536(s1)
    80004ca2:	1ff7f793          	andi	a5,a5,511
    80004ca6:	97a6                	add	a5,a5,s1
    80004ca8:	0187c783          	lbu	a5,24(a5)
    80004cac:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cb0:	4685                	li	a3,1
    80004cb2:	fbf40613          	addi	a2,s0,-65
    80004cb6:	85ca                	mv	a1,s2
    80004cb8:	050a3503          	ld	a0,80(s4)
    80004cbc:	ffffd097          	auipc	ra,0xffffd
    80004cc0:	b00080e7          	jalr	-1280(ra) # 800017bc <copyout>
    80004cc4:	01650663          	beq	a0,s6,80004cd0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc8:	2985                	addiw	s3,s3,1
    80004cca:	0905                	addi	s2,s2,1
    80004ccc:	fd3a91e3          	bne	s5,s3,80004c8e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cd0:	21c48513          	addi	a0,s1,540
    80004cd4:	ffffd097          	auipc	ra,0xffffd
    80004cd8:	694080e7          	jalr	1684(ra) # 80002368 <wakeup>
  release(&pi->lock);
    80004cdc:	8526                	mv	a0,s1
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	104080e7          	jalr	260(ra) # 80000de2 <release>
  return i;
}
    80004ce6:	854e                	mv	a0,s3
    80004ce8:	60a6                	ld	ra,72(sp)
    80004cea:	6406                	ld	s0,64(sp)
    80004cec:	74e2                	ld	s1,56(sp)
    80004cee:	7942                	ld	s2,48(sp)
    80004cf0:	79a2                	ld	s3,40(sp)
    80004cf2:	7a02                	ld	s4,32(sp)
    80004cf4:	6ae2                	ld	s5,24(sp)
    80004cf6:	6b42                	ld	s6,16(sp)
    80004cf8:	6161                	addi	sp,sp,80
    80004cfa:	8082                	ret
      release(&pi->lock);
    80004cfc:	8526                	mv	a0,s1
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	0e4080e7          	jalr	228(ra) # 80000de2 <release>
      return -1;
    80004d06:	59fd                	li	s3,-1
    80004d08:	bff9                	j	80004ce6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d0a:	4981                	li	s3,0
    80004d0c:	b7d1                	j	80004cd0 <piperead+0xae>

0000000080004d0e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d0e:	df010113          	addi	sp,sp,-528
    80004d12:	20113423          	sd	ra,520(sp)
    80004d16:	20813023          	sd	s0,512(sp)
    80004d1a:	ffa6                	sd	s1,504(sp)
    80004d1c:	fbca                	sd	s2,496(sp)
    80004d1e:	f7ce                	sd	s3,488(sp)
    80004d20:	f3d2                	sd	s4,480(sp)
    80004d22:	efd6                	sd	s5,472(sp)
    80004d24:	ebda                	sd	s6,464(sp)
    80004d26:	e7de                	sd	s7,456(sp)
    80004d28:	e3e2                	sd	s8,448(sp)
    80004d2a:	ff66                	sd	s9,440(sp)
    80004d2c:	fb6a                	sd	s10,432(sp)
    80004d2e:	f76e                	sd	s11,424(sp)
    80004d30:	0c00                	addi	s0,sp,528
    80004d32:	84aa                	mv	s1,a0
    80004d34:	dea43c23          	sd	a0,-520(s0)
    80004d38:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	de4080e7          	jalr	-540(ra) # 80001b20 <myproc>
    80004d44:	892a                	mv	s2,a0

  begin_op();
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	49c080e7          	jalr	1180(ra) # 800041e2 <begin_op>

  if((ip = namei(path)) == 0){
    80004d4e:	8526                	mv	a0,s1
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	276080e7          	jalr	630(ra) # 80003fc6 <namei>
    80004d58:	c92d                	beqz	a0,80004dca <exec+0xbc>
    80004d5a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	ab4080e7          	jalr	-1356(ra) # 80003810 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d64:	04000713          	li	a4,64
    80004d68:	4681                	li	a3,0
    80004d6a:	e5040613          	addi	a2,s0,-432
    80004d6e:	4581                	li	a1,0
    80004d70:	8526                	mv	a0,s1
    80004d72:	fffff097          	auipc	ra,0xfffff
    80004d76:	d52080e7          	jalr	-686(ra) # 80003ac4 <readi>
    80004d7a:	04000793          	li	a5,64
    80004d7e:	00f51a63          	bne	a0,a5,80004d92 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d82:	e5042703          	lw	a4,-432(s0)
    80004d86:	464c47b7          	lui	a5,0x464c4
    80004d8a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d8e:	04f70463          	beq	a4,a5,80004dd6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d92:	8526                	mv	a0,s1
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	cde080e7          	jalr	-802(ra) # 80003a72 <iunlockput>
    end_op();
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	4c6080e7          	jalr	1222(ra) # 80004262 <end_op>
  }
  return -1;
    80004da4:	557d                	li	a0,-1
}
    80004da6:	20813083          	ld	ra,520(sp)
    80004daa:	20013403          	ld	s0,512(sp)
    80004dae:	74fe                	ld	s1,504(sp)
    80004db0:	795e                	ld	s2,496(sp)
    80004db2:	79be                	ld	s3,488(sp)
    80004db4:	7a1e                	ld	s4,480(sp)
    80004db6:	6afe                	ld	s5,472(sp)
    80004db8:	6b5e                	ld	s6,464(sp)
    80004dba:	6bbe                	ld	s7,456(sp)
    80004dbc:	6c1e                	ld	s8,448(sp)
    80004dbe:	7cfa                	ld	s9,440(sp)
    80004dc0:	7d5a                	ld	s10,432(sp)
    80004dc2:	7dba                	ld	s11,424(sp)
    80004dc4:	21010113          	addi	sp,sp,528
    80004dc8:	8082                	ret
    end_op();
    80004dca:	fffff097          	auipc	ra,0xfffff
    80004dce:	498080e7          	jalr	1176(ra) # 80004262 <end_op>
    return -1;
    80004dd2:	557d                	li	a0,-1
    80004dd4:	bfc9                	j	80004da6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dd6:	854a                	mv	a0,s2
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	e0c080e7          	jalr	-500(ra) # 80001be4 <proc_pagetable>
    80004de0:	8baa                	mv	s7,a0
    80004de2:	d945                	beqz	a0,80004d92 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de4:	e7042983          	lw	s3,-400(s0)
    80004de8:	e8845783          	lhu	a5,-376(s0)
    80004dec:	c7ad                	beqz	a5,80004e56 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dee:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004df0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004df2:	6c85                	lui	s9,0x1
    80004df4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004df8:	def43823          	sd	a5,-528(s0)
    80004dfc:	a42d                	j	80005026 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dfe:	00004517          	auipc	a0,0x4
    80004e02:	92250513          	addi	a0,a0,-1758 # 80008720 <syscalls+0x280>
    80004e06:	ffffb097          	auipc	ra,0xffffb
    80004e0a:	738080e7          	jalr	1848(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e0e:	8756                	mv	a4,s5
    80004e10:	012d86bb          	addw	a3,s11,s2
    80004e14:	4581                	li	a1,0
    80004e16:	8526                	mv	a0,s1
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	cac080e7          	jalr	-852(ra) # 80003ac4 <readi>
    80004e20:	2501                	sext.w	a0,a0
    80004e22:	1aaa9963          	bne	s5,a0,80004fd4 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e26:	6785                	lui	a5,0x1
    80004e28:	0127893b          	addw	s2,a5,s2
    80004e2c:	77fd                	lui	a5,0xfffff
    80004e2e:	01478a3b          	addw	s4,a5,s4
    80004e32:	1f897163          	bgeu	s2,s8,80005014 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e36:	02091593          	slli	a1,s2,0x20
    80004e3a:	9181                	srli	a1,a1,0x20
    80004e3c:	95ea                	add	a1,a1,s10
    80004e3e:	855e                	mv	a0,s7
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	378080e7          	jalr	888(ra) # 800011b8 <walkaddr>
    80004e48:	862a                	mv	a2,a0
    if(pa == 0)
    80004e4a:	d955                	beqz	a0,80004dfe <exec+0xf0>
      n = PGSIZE;
    80004e4c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e4e:	fd9a70e3          	bgeu	s4,s9,80004e0e <exec+0x100>
      n = sz - i;
    80004e52:	8ad2                	mv	s5,s4
    80004e54:	bf6d                	j	80004e0e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e56:	4901                	li	s2,0
  iunlockput(ip);
    80004e58:	8526                	mv	a0,s1
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	c18080e7          	jalr	-1000(ra) # 80003a72 <iunlockput>
  end_op();
    80004e62:	fffff097          	auipc	ra,0xfffff
    80004e66:	400080e7          	jalr	1024(ra) # 80004262 <end_op>
  p = myproc();
    80004e6a:	ffffd097          	auipc	ra,0xffffd
    80004e6e:	cb6080e7          	jalr	-842(ra) # 80001b20 <myproc>
    80004e72:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e74:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e78:	6785                	lui	a5,0x1
    80004e7a:	17fd                	addi	a5,a5,-1
    80004e7c:	993e                	add	s2,s2,a5
    80004e7e:	757d                	lui	a0,0xfffff
    80004e80:	00a977b3          	and	a5,s2,a0
    80004e84:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e88:	6609                	lui	a2,0x2
    80004e8a:	963e                	add	a2,a2,a5
    80004e8c:	85be                	mv	a1,a5
    80004e8e:	855e                	mv	a0,s7
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	6dc080e7          	jalr	1756(ra) # 8000156c <uvmalloc>
    80004e98:	8b2a                	mv	s6,a0
  ip = 0;
    80004e9a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e9c:	12050c63          	beqz	a0,80004fd4 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ea0:	75f9                	lui	a1,0xffffe
    80004ea2:	95aa                	add	a1,a1,a0
    80004ea4:	855e                	mv	a0,s7
    80004ea6:	ffffd097          	auipc	ra,0xffffd
    80004eaa:	8e4080e7          	jalr	-1820(ra) # 8000178a <uvmclear>
  stackbase = sp - PGSIZE;
    80004eae:	7c7d                	lui	s8,0xfffff
    80004eb0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eb2:	e0043783          	ld	a5,-512(s0)
    80004eb6:	6388                	ld	a0,0(a5)
    80004eb8:	c535                	beqz	a0,80004f24 <exec+0x216>
    80004eba:	e9040993          	addi	s3,s0,-368
    80004ebe:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004ec2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	0ea080e7          	jalr	234(ra) # 80000fae <strlen>
    80004ecc:	2505                	addiw	a0,a0,1
    80004ece:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ed2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ed6:	13896363          	bltu	s2,s8,80004ffc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eda:	e0043d83          	ld	s11,-512(s0)
    80004ede:	000dba03          	ld	s4,0(s11)
    80004ee2:	8552                	mv	a0,s4
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	0ca080e7          	jalr	202(ra) # 80000fae <strlen>
    80004eec:	0015069b          	addiw	a3,a0,1
    80004ef0:	8652                	mv	a2,s4
    80004ef2:	85ca                	mv	a1,s2
    80004ef4:	855e                	mv	a0,s7
    80004ef6:	ffffd097          	auipc	ra,0xffffd
    80004efa:	8c6080e7          	jalr	-1850(ra) # 800017bc <copyout>
    80004efe:	10054363          	bltz	a0,80005004 <exec+0x2f6>
    ustack[argc] = sp;
    80004f02:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f06:	0485                	addi	s1,s1,1
    80004f08:	008d8793          	addi	a5,s11,8
    80004f0c:	e0f43023          	sd	a5,-512(s0)
    80004f10:	008db503          	ld	a0,8(s11)
    80004f14:	c911                	beqz	a0,80004f28 <exec+0x21a>
    if(argc >= MAXARG)
    80004f16:	09a1                	addi	s3,s3,8
    80004f18:	fb3c96e3          	bne	s9,s3,80004ec4 <exec+0x1b6>
  sz = sz1;
    80004f1c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f20:	4481                	li	s1,0
    80004f22:	a84d                	j	80004fd4 <exec+0x2c6>
  sp = sz;
    80004f24:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f26:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f28:	00349793          	slli	a5,s1,0x3
    80004f2c:	f9040713          	addi	a4,s0,-112
    80004f30:	97ba                	add	a5,a5,a4
    80004f32:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f36:	00148693          	addi	a3,s1,1
    80004f3a:	068e                	slli	a3,a3,0x3
    80004f3c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f40:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f44:	01897663          	bgeu	s2,s8,80004f50 <exec+0x242>
  sz = sz1;
    80004f48:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f4c:	4481                	li	s1,0
    80004f4e:	a059                	j	80004fd4 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f50:	e9040613          	addi	a2,s0,-368
    80004f54:	85ca                	mv	a1,s2
    80004f56:	855e                	mv	a0,s7
    80004f58:	ffffd097          	auipc	ra,0xffffd
    80004f5c:	864080e7          	jalr	-1948(ra) # 800017bc <copyout>
    80004f60:	0a054663          	bltz	a0,8000500c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f64:	058ab783          	ld	a5,88(s5)
    80004f68:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f6c:	df843783          	ld	a5,-520(s0)
    80004f70:	0007c703          	lbu	a4,0(a5)
    80004f74:	cf11                	beqz	a4,80004f90 <exec+0x282>
    80004f76:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f78:	02f00693          	li	a3,47
    80004f7c:	a039                	j	80004f8a <exec+0x27c>
      last = s+1;
    80004f7e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f82:	0785                	addi	a5,a5,1
    80004f84:	fff7c703          	lbu	a4,-1(a5)
    80004f88:	c701                	beqz	a4,80004f90 <exec+0x282>
    if(*s == '/')
    80004f8a:	fed71ce3          	bne	a4,a3,80004f82 <exec+0x274>
    80004f8e:	bfc5                	j	80004f7e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f90:	4641                	li	a2,16
    80004f92:	df843583          	ld	a1,-520(s0)
    80004f96:	158a8513          	addi	a0,s5,344
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	fe2080e7          	jalr	-30(ra) # 80000f7c <safestrcpy>
  oldpagetable = p->pagetable;
    80004fa2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fa6:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004faa:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fae:	058ab783          	ld	a5,88(s5)
    80004fb2:	e6843703          	ld	a4,-408(s0)
    80004fb6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fb8:	058ab783          	ld	a5,88(s5)
    80004fbc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fc0:	85ea                	mv	a1,s10
    80004fc2:	ffffd097          	auipc	ra,0xffffd
    80004fc6:	cbe080e7          	jalr	-834(ra) # 80001c80 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fca:	0004851b          	sext.w	a0,s1
    80004fce:	bbe1                	j	80004da6 <exec+0x98>
    80004fd0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fd4:	e0843583          	ld	a1,-504(s0)
    80004fd8:	855e                	mv	a0,s7
    80004fda:	ffffd097          	auipc	ra,0xffffd
    80004fde:	ca6080e7          	jalr	-858(ra) # 80001c80 <proc_freepagetable>
  if(ip){
    80004fe2:	da0498e3          	bnez	s1,80004d92 <exec+0x84>
  return -1;
    80004fe6:	557d                	li	a0,-1
    80004fe8:	bb7d                	j	80004da6 <exec+0x98>
    80004fea:	e1243423          	sd	s2,-504(s0)
    80004fee:	b7dd                	j	80004fd4 <exec+0x2c6>
    80004ff0:	e1243423          	sd	s2,-504(s0)
    80004ff4:	b7c5                	j	80004fd4 <exec+0x2c6>
    80004ff6:	e1243423          	sd	s2,-504(s0)
    80004ffa:	bfe9                	j	80004fd4 <exec+0x2c6>
  sz = sz1;
    80004ffc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005000:	4481                	li	s1,0
    80005002:	bfc9                	j	80004fd4 <exec+0x2c6>
  sz = sz1;
    80005004:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005008:	4481                	li	s1,0
    8000500a:	b7e9                	j	80004fd4 <exec+0x2c6>
  sz = sz1;
    8000500c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005010:	4481                	li	s1,0
    80005012:	b7c9                	j	80004fd4 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005014:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005018:	2b05                	addiw	s6,s6,1
    8000501a:	0389899b          	addiw	s3,s3,56
    8000501e:	e8845783          	lhu	a5,-376(s0)
    80005022:	e2fb5be3          	bge	s6,a5,80004e58 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005026:	2981                	sext.w	s3,s3
    80005028:	03800713          	li	a4,56
    8000502c:	86ce                	mv	a3,s3
    8000502e:	e1840613          	addi	a2,s0,-488
    80005032:	4581                	li	a1,0
    80005034:	8526                	mv	a0,s1
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	a8e080e7          	jalr	-1394(ra) # 80003ac4 <readi>
    8000503e:	03800793          	li	a5,56
    80005042:	f8f517e3          	bne	a0,a5,80004fd0 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005046:	e1842783          	lw	a5,-488(s0)
    8000504a:	4705                	li	a4,1
    8000504c:	fce796e3          	bne	a5,a4,80005018 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005050:	e4043603          	ld	a2,-448(s0)
    80005054:	e3843783          	ld	a5,-456(s0)
    80005058:	f8f669e3          	bltu	a2,a5,80004fea <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000505c:	e2843783          	ld	a5,-472(s0)
    80005060:	963e                	add	a2,a2,a5
    80005062:	f8f667e3          	bltu	a2,a5,80004ff0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005066:	85ca                	mv	a1,s2
    80005068:	855e                	mv	a0,s7
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	502080e7          	jalr	1282(ra) # 8000156c <uvmalloc>
    80005072:	e0a43423          	sd	a0,-504(s0)
    80005076:	d141                	beqz	a0,80004ff6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005078:	e2843d03          	ld	s10,-472(s0)
    8000507c:	df043783          	ld	a5,-528(s0)
    80005080:	00fd77b3          	and	a5,s10,a5
    80005084:	fba1                	bnez	a5,80004fd4 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005086:	e2042d83          	lw	s11,-480(s0)
    8000508a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000508e:	f80c03e3          	beqz	s8,80005014 <exec+0x306>
    80005092:	8a62                	mv	s4,s8
    80005094:	4901                	li	s2,0
    80005096:	b345                	j	80004e36 <exec+0x128>

0000000080005098 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005098:	7179                	addi	sp,sp,-48
    8000509a:	f406                	sd	ra,40(sp)
    8000509c:	f022                	sd	s0,32(sp)
    8000509e:	ec26                	sd	s1,24(sp)
    800050a0:	e84a                	sd	s2,16(sp)
    800050a2:	1800                	addi	s0,sp,48
    800050a4:	892e                	mv	s2,a1
    800050a6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050a8:	fdc40593          	addi	a1,s0,-36
    800050ac:	ffffe097          	auipc	ra,0xffffe
    800050b0:	bf2080e7          	jalr	-1038(ra) # 80002c9e <argint>
    800050b4:	04054063          	bltz	a0,800050f4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050b8:	fdc42703          	lw	a4,-36(s0)
    800050bc:	47bd                	li	a5,15
    800050be:	02e7ed63          	bltu	a5,a4,800050f8 <argfd+0x60>
    800050c2:	ffffd097          	auipc	ra,0xffffd
    800050c6:	a5e080e7          	jalr	-1442(ra) # 80001b20 <myproc>
    800050ca:	fdc42703          	lw	a4,-36(s0)
    800050ce:	01a70793          	addi	a5,a4,26
    800050d2:	078e                	slli	a5,a5,0x3
    800050d4:	953e                	add	a0,a0,a5
    800050d6:	611c                	ld	a5,0(a0)
    800050d8:	c395                	beqz	a5,800050fc <argfd+0x64>
    return -1;
  if(pfd)
    800050da:	00090463          	beqz	s2,800050e2 <argfd+0x4a>
    *pfd = fd;
    800050de:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050e2:	4501                	li	a0,0
  if(pf)
    800050e4:	c091                	beqz	s1,800050e8 <argfd+0x50>
    *pf = f;
    800050e6:	e09c                	sd	a5,0(s1)
}
    800050e8:	70a2                	ld	ra,40(sp)
    800050ea:	7402                	ld	s0,32(sp)
    800050ec:	64e2                	ld	s1,24(sp)
    800050ee:	6942                	ld	s2,16(sp)
    800050f0:	6145                	addi	sp,sp,48
    800050f2:	8082                	ret
    return -1;
    800050f4:	557d                	li	a0,-1
    800050f6:	bfcd                	j	800050e8 <argfd+0x50>
    return -1;
    800050f8:	557d                	li	a0,-1
    800050fa:	b7fd                	j	800050e8 <argfd+0x50>
    800050fc:	557d                	li	a0,-1
    800050fe:	b7ed                	j	800050e8 <argfd+0x50>

0000000080005100 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005100:	1101                	addi	sp,sp,-32
    80005102:	ec06                	sd	ra,24(sp)
    80005104:	e822                	sd	s0,16(sp)
    80005106:	e426                	sd	s1,8(sp)
    80005108:	1000                	addi	s0,sp,32
    8000510a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000510c:	ffffd097          	auipc	ra,0xffffd
    80005110:	a14080e7          	jalr	-1516(ra) # 80001b20 <myproc>
    80005114:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005116:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ff990d0>
    8000511a:	4501                	li	a0,0
    8000511c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000511e:	6398                	ld	a4,0(a5)
    80005120:	cb19                	beqz	a4,80005136 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005122:	2505                	addiw	a0,a0,1
    80005124:	07a1                	addi	a5,a5,8
    80005126:	fed51ce3          	bne	a0,a3,8000511e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000512a:	557d                	li	a0,-1
}
    8000512c:	60e2                	ld	ra,24(sp)
    8000512e:	6442                	ld	s0,16(sp)
    80005130:	64a2                	ld	s1,8(sp)
    80005132:	6105                	addi	sp,sp,32
    80005134:	8082                	ret
      p->ofile[fd] = f;
    80005136:	01a50793          	addi	a5,a0,26
    8000513a:	078e                	slli	a5,a5,0x3
    8000513c:	963e                	add	a2,a2,a5
    8000513e:	e204                	sd	s1,0(a2)
      return fd;
    80005140:	b7f5                	j	8000512c <fdalloc+0x2c>

0000000080005142 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005142:	715d                	addi	sp,sp,-80
    80005144:	e486                	sd	ra,72(sp)
    80005146:	e0a2                	sd	s0,64(sp)
    80005148:	fc26                	sd	s1,56(sp)
    8000514a:	f84a                	sd	s2,48(sp)
    8000514c:	f44e                	sd	s3,40(sp)
    8000514e:	f052                	sd	s4,32(sp)
    80005150:	ec56                	sd	s5,24(sp)
    80005152:	0880                	addi	s0,sp,80
    80005154:	89ae                	mv	s3,a1
    80005156:	8ab2                	mv	s5,a2
    80005158:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000515a:	fb040593          	addi	a1,s0,-80
    8000515e:	fffff097          	auipc	ra,0xfffff
    80005162:	e86080e7          	jalr	-378(ra) # 80003fe4 <nameiparent>
    80005166:	892a                	mv	s2,a0
    80005168:	12050f63          	beqz	a0,800052a6 <create+0x164>
    return 0;

  ilock(dp);
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	6a4080e7          	jalr	1700(ra) # 80003810 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005174:	4601                	li	a2,0
    80005176:	fb040593          	addi	a1,s0,-80
    8000517a:	854a                	mv	a0,s2
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	b78080e7          	jalr	-1160(ra) # 80003cf4 <dirlookup>
    80005184:	84aa                	mv	s1,a0
    80005186:	c921                	beqz	a0,800051d6 <create+0x94>
    iunlockput(dp);
    80005188:	854a                	mv	a0,s2
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	8e8080e7          	jalr	-1816(ra) # 80003a72 <iunlockput>
    ilock(ip);
    80005192:	8526                	mv	a0,s1
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	67c080e7          	jalr	1660(ra) # 80003810 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000519c:	2981                	sext.w	s3,s3
    8000519e:	4789                	li	a5,2
    800051a0:	02f99463          	bne	s3,a5,800051c8 <create+0x86>
    800051a4:	0444d783          	lhu	a5,68(s1)
    800051a8:	37f9                	addiw	a5,a5,-2
    800051aa:	17c2                	slli	a5,a5,0x30
    800051ac:	93c1                	srli	a5,a5,0x30
    800051ae:	4705                	li	a4,1
    800051b0:	00f76c63          	bltu	a4,a5,800051c8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051b4:	8526                	mv	a0,s1
    800051b6:	60a6                	ld	ra,72(sp)
    800051b8:	6406                	ld	s0,64(sp)
    800051ba:	74e2                	ld	s1,56(sp)
    800051bc:	7942                	ld	s2,48(sp)
    800051be:	79a2                	ld	s3,40(sp)
    800051c0:	7a02                	ld	s4,32(sp)
    800051c2:	6ae2                	ld	s5,24(sp)
    800051c4:	6161                	addi	sp,sp,80
    800051c6:	8082                	ret
    iunlockput(ip);
    800051c8:	8526                	mv	a0,s1
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	8a8080e7          	jalr	-1880(ra) # 80003a72 <iunlockput>
    return 0;
    800051d2:	4481                	li	s1,0
    800051d4:	b7c5                	j	800051b4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051d6:	85ce                	mv	a1,s3
    800051d8:	00092503          	lw	a0,0(s2)
    800051dc:	ffffe097          	auipc	ra,0xffffe
    800051e0:	49c080e7          	jalr	1180(ra) # 80003678 <ialloc>
    800051e4:	84aa                	mv	s1,a0
    800051e6:	c529                	beqz	a0,80005230 <create+0xee>
  ilock(ip);
    800051e8:	ffffe097          	auipc	ra,0xffffe
    800051ec:	628080e7          	jalr	1576(ra) # 80003810 <ilock>
  ip->major = major;
    800051f0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051f4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051f8:	4785                	li	a5,1
    800051fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051fe:	8526                	mv	a0,s1
    80005200:	ffffe097          	auipc	ra,0xffffe
    80005204:	546080e7          	jalr	1350(ra) # 80003746 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005208:	2981                	sext.w	s3,s3
    8000520a:	4785                	li	a5,1
    8000520c:	02f98a63          	beq	s3,a5,80005240 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005210:	40d0                	lw	a2,4(s1)
    80005212:	fb040593          	addi	a1,s0,-80
    80005216:	854a                	mv	a0,s2
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	cec080e7          	jalr	-788(ra) # 80003f04 <dirlink>
    80005220:	06054b63          	bltz	a0,80005296 <create+0x154>
  iunlockput(dp);
    80005224:	854a                	mv	a0,s2
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	84c080e7          	jalr	-1972(ra) # 80003a72 <iunlockput>
  return ip;
    8000522e:	b759                	j	800051b4 <create+0x72>
    panic("create: ialloc");
    80005230:	00003517          	auipc	a0,0x3
    80005234:	51050513          	addi	a0,a0,1296 # 80008740 <syscalls+0x2a0>
    80005238:	ffffb097          	auipc	ra,0xffffb
    8000523c:	306080e7          	jalr	774(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005240:	04a95783          	lhu	a5,74(s2)
    80005244:	2785                	addiw	a5,a5,1
    80005246:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000524a:	854a                	mv	a0,s2
    8000524c:	ffffe097          	auipc	ra,0xffffe
    80005250:	4fa080e7          	jalr	1274(ra) # 80003746 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005254:	40d0                	lw	a2,4(s1)
    80005256:	00003597          	auipc	a1,0x3
    8000525a:	4fa58593          	addi	a1,a1,1274 # 80008750 <syscalls+0x2b0>
    8000525e:	8526                	mv	a0,s1
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	ca4080e7          	jalr	-860(ra) # 80003f04 <dirlink>
    80005268:	00054f63          	bltz	a0,80005286 <create+0x144>
    8000526c:	00492603          	lw	a2,4(s2)
    80005270:	00003597          	auipc	a1,0x3
    80005274:	4e858593          	addi	a1,a1,1256 # 80008758 <syscalls+0x2b8>
    80005278:	8526                	mv	a0,s1
    8000527a:	fffff097          	auipc	ra,0xfffff
    8000527e:	c8a080e7          	jalr	-886(ra) # 80003f04 <dirlink>
    80005282:	f80557e3          	bgez	a0,80005210 <create+0xce>
      panic("create dots");
    80005286:	00003517          	auipc	a0,0x3
    8000528a:	4da50513          	addi	a0,a0,1242 # 80008760 <syscalls+0x2c0>
    8000528e:	ffffb097          	auipc	ra,0xffffb
    80005292:	2b0080e7          	jalr	688(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005296:	00003517          	auipc	a0,0x3
    8000529a:	4da50513          	addi	a0,a0,1242 # 80008770 <syscalls+0x2d0>
    8000529e:	ffffb097          	auipc	ra,0xffffb
    800052a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>
    return 0;
    800052a6:	84aa                	mv	s1,a0
    800052a8:	b731                	j	800051b4 <create+0x72>

00000000800052aa <sys_dup>:
{
    800052aa:	7179                	addi	sp,sp,-48
    800052ac:	f406                	sd	ra,40(sp)
    800052ae:	f022                	sd	s0,32(sp)
    800052b0:	ec26                	sd	s1,24(sp)
    800052b2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052b4:	fd840613          	addi	a2,s0,-40
    800052b8:	4581                	li	a1,0
    800052ba:	4501                	li	a0,0
    800052bc:	00000097          	auipc	ra,0x0
    800052c0:	ddc080e7          	jalr	-548(ra) # 80005098 <argfd>
    return -1;
    800052c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052c6:	02054363          	bltz	a0,800052ec <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052ca:	fd843503          	ld	a0,-40(s0)
    800052ce:	00000097          	auipc	ra,0x0
    800052d2:	e32080e7          	jalr	-462(ra) # 80005100 <fdalloc>
    800052d6:	84aa                	mv	s1,a0
    return -1;
    800052d8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052da:	00054963          	bltz	a0,800052ec <sys_dup+0x42>
  filedup(f);
    800052de:	fd843503          	ld	a0,-40(s0)
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	37a080e7          	jalr	890(ra) # 8000465c <filedup>
  return fd;
    800052ea:	87a6                	mv	a5,s1
}
    800052ec:	853e                	mv	a0,a5
    800052ee:	70a2                	ld	ra,40(sp)
    800052f0:	7402                	ld	s0,32(sp)
    800052f2:	64e2                	ld	s1,24(sp)
    800052f4:	6145                	addi	sp,sp,48
    800052f6:	8082                	ret

00000000800052f8 <sys_read>:
{
    800052f8:	7179                	addi	sp,sp,-48
    800052fa:	f406                	sd	ra,40(sp)
    800052fc:	f022                	sd	s0,32(sp)
    800052fe:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005300:	fe840613          	addi	a2,s0,-24
    80005304:	4581                	li	a1,0
    80005306:	4501                	li	a0,0
    80005308:	00000097          	auipc	ra,0x0
    8000530c:	d90080e7          	jalr	-624(ra) # 80005098 <argfd>
    return -1;
    80005310:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005312:	04054163          	bltz	a0,80005354 <sys_read+0x5c>
    80005316:	fe440593          	addi	a1,s0,-28
    8000531a:	4509                	li	a0,2
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	982080e7          	jalr	-1662(ra) # 80002c9e <argint>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005326:	02054763          	bltz	a0,80005354 <sys_read+0x5c>
    8000532a:	fd840593          	addi	a1,s0,-40
    8000532e:	4505                	li	a0,1
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	990080e7          	jalr	-1648(ra) # 80002cc0 <argaddr>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533a:	00054d63          	bltz	a0,80005354 <sys_read+0x5c>
  return fileread(f, p, n);
    8000533e:	fe442603          	lw	a2,-28(s0)
    80005342:	fd843583          	ld	a1,-40(s0)
    80005346:	fe843503          	ld	a0,-24(s0)
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	49e080e7          	jalr	1182(ra) # 800047e8 <fileread>
    80005352:	87aa                	mv	a5,a0
}
    80005354:	853e                	mv	a0,a5
    80005356:	70a2                	ld	ra,40(sp)
    80005358:	7402                	ld	s0,32(sp)
    8000535a:	6145                	addi	sp,sp,48
    8000535c:	8082                	ret

000000008000535e <sys_write>:
{
    8000535e:	7179                	addi	sp,sp,-48
    80005360:	f406                	sd	ra,40(sp)
    80005362:	f022                	sd	s0,32(sp)
    80005364:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005366:	fe840613          	addi	a2,s0,-24
    8000536a:	4581                	li	a1,0
    8000536c:	4501                	li	a0,0
    8000536e:	00000097          	auipc	ra,0x0
    80005372:	d2a080e7          	jalr	-726(ra) # 80005098 <argfd>
    return -1;
    80005376:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005378:	04054163          	bltz	a0,800053ba <sys_write+0x5c>
    8000537c:	fe440593          	addi	a1,s0,-28
    80005380:	4509                	li	a0,2
    80005382:	ffffe097          	auipc	ra,0xffffe
    80005386:	91c080e7          	jalr	-1764(ra) # 80002c9e <argint>
    return -1;
    8000538a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000538c:	02054763          	bltz	a0,800053ba <sys_write+0x5c>
    80005390:	fd840593          	addi	a1,s0,-40
    80005394:	4505                	li	a0,1
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	92a080e7          	jalr	-1750(ra) # 80002cc0 <argaddr>
    return -1;
    8000539e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a0:	00054d63          	bltz	a0,800053ba <sys_write+0x5c>
  return filewrite(f, p, n);
    800053a4:	fe442603          	lw	a2,-28(s0)
    800053a8:	fd843583          	ld	a1,-40(s0)
    800053ac:	fe843503          	ld	a0,-24(s0)
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	4fa080e7          	jalr	1274(ra) # 800048aa <filewrite>
    800053b8:	87aa                	mv	a5,a0
}
    800053ba:	853e                	mv	a0,a5
    800053bc:	70a2                	ld	ra,40(sp)
    800053be:	7402                	ld	s0,32(sp)
    800053c0:	6145                	addi	sp,sp,48
    800053c2:	8082                	ret

00000000800053c4 <sys_close>:
{
    800053c4:	1101                	addi	sp,sp,-32
    800053c6:	ec06                	sd	ra,24(sp)
    800053c8:	e822                	sd	s0,16(sp)
    800053ca:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053cc:	fe040613          	addi	a2,s0,-32
    800053d0:	fec40593          	addi	a1,s0,-20
    800053d4:	4501                	li	a0,0
    800053d6:	00000097          	auipc	ra,0x0
    800053da:	cc2080e7          	jalr	-830(ra) # 80005098 <argfd>
    return -1;
    800053de:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053e0:	02054463          	bltz	a0,80005408 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053e4:	ffffc097          	auipc	ra,0xffffc
    800053e8:	73c080e7          	jalr	1852(ra) # 80001b20 <myproc>
    800053ec:	fec42783          	lw	a5,-20(s0)
    800053f0:	07e9                	addi	a5,a5,26
    800053f2:	078e                	slli	a5,a5,0x3
    800053f4:	97aa                	add	a5,a5,a0
    800053f6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053fa:	fe043503          	ld	a0,-32(s0)
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	2b0080e7          	jalr	688(ra) # 800046ae <fileclose>
  return 0;
    80005406:	4781                	li	a5,0
}
    80005408:	853e                	mv	a0,a5
    8000540a:	60e2                	ld	ra,24(sp)
    8000540c:	6442                	ld	s0,16(sp)
    8000540e:	6105                	addi	sp,sp,32
    80005410:	8082                	ret

0000000080005412 <sys_fstat>:
{
    80005412:	1101                	addi	sp,sp,-32
    80005414:	ec06                	sd	ra,24(sp)
    80005416:	e822                	sd	s0,16(sp)
    80005418:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000541a:	fe840613          	addi	a2,s0,-24
    8000541e:	4581                	li	a1,0
    80005420:	4501                	li	a0,0
    80005422:	00000097          	auipc	ra,0x0
    80005426:	c76080e7          	jalr	-906(ra) # 80005098 <argfd>
    return -1;
    8000542a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000542c:	02054563          	bltz	a0,80005456 <sys_fstat+0x44>
    80005430:	fe040593          	addi	a1,s0,-32
    80005434:	4505                	li	a0,1
    80005436:	ffffe097          	auipc	ra,0xffffe
    8000543a:	88a080e7          	jalr	-1910(ra) # 80002cc0 <argaddr>
    return -1;
    8000543e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005440:	00054b63          	bltz	a0,80005456 <sys_fstat+0x44>
  return filestat(f, st);
    80005444:	fe043583          	ld	a1,-32(s0)
    80005448:	fe843503          	ld	a0,-24(s0)
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	32a080e7          	jalr	810(ra) # 80004776 <filestat>
    80005454:	87aa                	mv	a5,a0
}
    80005456:	853e                	mv	a0,a5
    80005458:	60e2                	ld	ra,24(sp)
    8000545a:	6442                	ld	s0,16(sp)
    8000545c:	6105                	addi	sp,sp,32
    8000545e:	8082                	ret

0000000080005460 <sys_link>:
{
    80005460:	7169                	addi	sp,sp,-304
    80005462:	f606                	sd	ra,296(sp)
    80005464:	f222                	sd	s0,288(sp)
    80005466:	ee26                	sd	s1,280(sp)
    80005468:	ea4a                	sd	s2,272(sp)
    8000546a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000546c:	08000613          	li	a2,128
    80005470:	ed040593          	addi	a1,s0,-304
    80005474:	4501                	li	a0,0
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	86c080e7          	jalr	-1940(ra) # 80002ce2 <argstr>
    return -1;
    8000547e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005480:	10054e63          	bltz	a0,8000559c <sys_link+0x13c>
    80005484:	08000613          	li	a2,128
    80005488:	f5040593          	addi	a1,s0,-176
    8000548c:	4505                	li	a0,1
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	854080e7          	jalr	-1964(ra) # 80002ce2 <argstr>
    return -1;
    80005496:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005498:	10054263          	bltz	a0,8000559c <sys_link+0x13c>
  begin_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	d46080e7          	jalr	-698(ra) # 800041e2 <begin_op>
  if((ip = namei(old)) == 0){
    800054a4:	ed040513          	addi	a0,s0,-304
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	b1e080e7          	jalr	-1250(ra) # 80003fc6 <namei>
    800054b0:	84aa                	mv	s1,a0
    800054b2:	c551                	beqz	a0,8000553e <sys_link+0xde>
  ilock(ip);
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	35c080e7          	jalr	860(ra) # 80003810 <ilock>
  if(ip->type == T_DIR){
    800054bc:	04449703          	lh	a4,68(s1)
    800054c0:	4785                	li	a5,1
    800054c2:	08f70463          	beq	a4,a5,8000554a <sys_link+0xea>
  ip->nlink++;
    800054c6:	04a4d783          	lhu	a5,74(s1)
    800054ca:	2785                	addiw	a5,a5,1
    800054cc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	274080e7          	jalr	628(ra) # 80003746 <iupdate>
  iunlock(ip);
    800054da:	8526                	mv	a0,s1
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	3f6080e7          	jalr	1014(ra) # 800038d2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054e4:	fd040593          	addi	a1,s0,-48
    800054e8:	f5040513          	addi	a0,s0,-176
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	af8080e7          	jalr	-1288(ra) # 80003fe4 <nameiparent>
    800054f4:	892a                	mv	s2,a0
    800054f6:	c935                	beqz	a0,8000556a <sys_link+0x10a>
  ilock(dp);
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	318080e7          	jalr	792(ra) # 80003810 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005500:	00092703          	lw	a4,0(s2)
    80005504:	409c                	lw	a5,0(s1)
    80005506:	04f71d63          	bne	a4,a5,80005560 <sys_link+0x100>
    8000550a:	40d0                	lw	a2,4(s1)
    8000550c:	fd040593          	addi	a1,s0,-48
    80005510:	854a                	mv	a0,s2
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	9f2080e7          	jalr	-1550(ra) # 80003f04 <dirlink>
    8000551a:	04054363          	bltz	a0,80005560 <sys_link+0x100>
  iunlockput(dp);
    8000551e:	854a                	mv	a0,s2
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	552080e7          	jalr	1362(ra) # 80003a72 <iunlockput>
  iput(ip);
    80005528:	8526                	mv	a0,s1
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	4a0080e7          	jalr	1184(ra) # 800039ca <iput>
  end_op();
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	d30080e7          	jalr	-720(ra) # 80004262 <end_op>
  return 0;
    8000553a:	4781                	li	a5,0
    8000553c:	a085                	j	8000559c <sys_link+0x13c>
    end_op();
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	d24080e7          	jalr	-732(ra) # 80004262 <end_op>
    return -1;
    80005546:	57fd                	li	a5,-1
    80005548:	a891                	j	8000559c <sys_link+0x13c>
    iunlockput(ip);
    8000554a:	8526                	mv	a0,s1
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	526080e7          	jalr	1318(ra) # 80003a72 <iunlockput>
    end_op();
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	d0e080e7          	jalr	-754(ra) # 80004262 <end_op>
    return -1;
    8000555c:	57fd                	li	a5,-1
    8000555e:	a83d                	j	8000559c <sys_link+0x13c>
    iunlockput(dp);
    80005560:	854a                	mv	a0,s2
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	510080e7          	jalr	1296(ra) # 80003a72 <iunlockput>
  ilock(ip);
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	2a4080e7          	jalr	676(ra) # 80003810 <ilock>
  ip->nlink--;
    80005574:	04a4d783          	lhu	a5,74(s1)
    80005578:	37fd                	addiw	a5,a5,-1
    8000557a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000557e:	8526                	mv	a0,s1
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	1c6080e7          	jalr	454(ra) # 80003746 <iupdate>
  iunlockput(ip);
    80005588:	8526                	mv	a0,s1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	4e8080e7          	jalr	1256(ra) # 80003a72 <iunlockput>
  end_op();
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	cd0080e7          	jalr	-816(ra) # 80004262 <end_op>
  return -1;
    8000559a:	57fd                	li	a5,-1
}
    8000559c:	853e                	mv	a0,a5
    8000559e:	70b2                	ld	ra,296(sp)
    800055a0:	7412                	ld	s0,288(sp)
    800055a2:	64f2                	ld	s1,280(sp)
    800055a4:	6952                	ld	s2,272(sp)
    800055a6:	6155                	addi	sp,sp,304
    800055a8:	8082                	ret

00000000800055aa <sys_unlink>:
{
    800055aa:	7151                	addi	sp,sp,-240
    800055ac:	f586                	sd	ra,232(sp)
    800055ae:	f1a2                	sd	s0,224(sp)
    800055b0:	eda6                	sd	s1,216(sp)
    800055b2:	e9ca                	sd	s2,208(sp)
    800055b4:	e5ce                	sd	s3,200(sp)
    800055b6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055b8:	08000613          	li	a2,128
    800055bc:	f3040593          	addi	a1,s0,-208
    800055c0:	4501                	li	a0,0
    800055c2:	ffffd097          	auipc	ra,0xffffd
    800055c6:	720080e7          	jalr	1824(ra) # 80002ce2 <argstr>
    800055ca:	18054163          	bltz	a0,8000574c <sys_unlink+0x1a2>
  begin_op();
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	c14080e7          	jalr	-1004(ra) # 800041e2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055d6:	fb040593          	addi	a1,s0,-80
    800055da:	f3040513          	addi	a0,s0,-208
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	a06080e7          	jalr	-1530(ra) # 80003fe4 <nameiparent>
    800055e6:	84aa                	mv	s1,a0
    800055e8:	c979                	beqz	a0,800056be <sys_unlink+0x114>
  ilock(dp);
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	226080e7          	jalr	550(ra) # 80003810 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055f2:	00003597          	auipc	a1,0x3
    800055f6:	15e58593          	addi	a1,a1,350 # 80008750 <syscalls+0x2b0>
    800055fa:	fb040513          	addi	a0,s0,-80
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	6dc080e7          	jalr	1756(ra) # 80003cda <namecmp>
    80005606:	14050a63          	beqz	a0,8000575a <sys_unlink+0x1b0>
    8000560a:	00003597          	auipc	a1,0x3
    8000560e:	14e58593          	addi	a1,a1,334 # 80008758 <syscalls+0x2b8>
    80005612:	fb040513          	addi	a0,s0,-80
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	6c4080e7          	jalr	1732(ra) # 80003cda <namecmp>
    8000561e:	12050e63          	beqz	a0,8000575a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005622:	f2c40613          	addi	a2,s0,-212
    80005626:	fb040593          	addi	a1,s0,-80
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	6c8080e7          	jalr	1736(ra) # 80003cf4 <dirlookup>
    80005634:	892a                	mv	s2,a0
    80005636:	12050263          	beqz	a0,8000575a <sys_unlink+0x1b0>
  ilock(ip);
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	1d6080e7          	jalr	470(ra) # 80003810 <ilock>
  if(ip->nlink < 1)
    80005642:	04a91783          	lh	a5,74(s2)
    80005646:	08f05263          	blez	a5,800056ca <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000564a:	04491703          	lh	a4,68(s2)
    8000564e:	4785                	li	a5,1
    80005650:	08f70563          	beq	a4,a5,800056da <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005654:	4641                	li	a2,16
    80005656:	4581                	li	a1,0
    80005658:	fc040513          	addi	a0,s0,-64
    8000565c:	ffffb097          	auipc	ra,0xffffb
    80005660:	7ce080e7          	jalr	1998(ra) # 80000e2a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005664:	4741                	li	a4,16
    80005666:	f2c42683          	lw	a3,-212(s0)
    8000566a:	fc040613          	addi	a2,s0,-64
    8000566e:	4581                	li	a1,0
    80005670:	8526                	mv	a0,s1
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	54a080e7          	jalr	1354(ra) # 80003bbc <writei>
    8000567a:	47c1                	li	a5,16
    8000567c:	0af51563          	bne	a0,a5,80005726 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005680:	04491703          	lh	a4,68(s2)
    80005684:	4785                	li	a5,1
    80005686:	0af70863          	beq	a4,a5,80005736 <sys_unlink+0x18c>
  iunlockput(dp);
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	3e6080e7          	jalr	998(ra) # 80003a72 <iunlockput>
  ip->nlink--;
    80005694:	04a95783          	lhu	a5,74(s2)
    80005698:	37fd                	addiw	a5,a5,-1
    8000569a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000569e:	854a                	mv	a0,s2
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	0a6080e7          	jalr	166(ra) # 80003746 <iupdate>
  iunlockput(ip);
    800056a8:	854a                	mv	a0,s2
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	3c8080e7          	jalr	968(ra) # 80003a72 <iunlockput>
  end_op();
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	bb0080e7          	jalr	-1104(ra) # 80004262 <end_op>
  return 0;
    800056ba:	4501                	li	a0,0
    800056bc:	a84d                	j	8000576e <sys_unlink+0x1c4>
    end_op();
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	ba4080e7          	jalr	-1116(ra) # 80004262 <end_op>
    return -1;
    800056c6:	557d                	li	a0,-1
    800056c8:	a05d                	j	8000576e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056ca:	00003517          	auipc	a0,0x3
    800056ce:	0b650513          	addi	a0,a0,182 # 80008780 <syscalls+0x2e0>
    800056d2:	ffffb097          	auipc	ra,0xffffb
    800056d6:	e6c080e7          	jalr	-404(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056da:	04c92703          	lw	a4,76(s2)
    800056de:	02000793          	li	a5,32
    800056e2:	f6e7f9e3          	bgeu	a5,a4,80005654 <sys_unlink+0xaa>
    800056e6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ea:	4741                	li	a4,16
    800056ec:	86ce                	mv	a3,s3
    800056ee:	f1840613          	addi	a2,s0,-232
    800056f2:	4581                	li	a1,0
    800056f4:	854a                	mv	a0,s2
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	3ce080e7          	jalr	974(ra) # 80003ac4 <readi>
    800056fe:	47c1                	li	a5,16
    80005700:	00f51b63          	bne	a0,a5,80005716 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005704:	f1845783          	lhu	a5,-232(s0)
    80005708:	e7a1                	bnez	a5,80005750 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000570a:	29c1                	addiw	s3,s3,16
    8000570c:	04c92783          	lw	a5,76(s2)
    80005710:	fcf9ede3          	bltu	s3,a5,800056ea <sys_unlink+0x140>
    80005714:	b781                	j	80005654 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005716:	00003517          	auipc	a0,0x3
    8000571a:	08250513          	addi	a0,a0,130 # 80008798 <syscalls+0x2f8>
    8000571e:	ffffb097          	auipc	ra,0xffffb
    80005722:	e20080e7          	jalr	-480(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005726:	00003517          	auipc	a0,0x3
    8000572a:	08a50513          	addi	a0,a0,138 # 800087b0 <syscalls+0x310>
    8000572e:	ffffb097          	auipc	ra,0xffffb
    80005732:	e10080e7          	jalr	-496(ra) # 8000053e <panic>
    dp->nlink--;
    80005736:	04a4d783          	lhu	a5,74(s1)
    8000573a:	37fd                	addiw	a5,a5,-1
    8000573c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005740:	8526                	mv	a0,s1
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	004080e7          	jalr	4(ra) # 80003746 <iupdate>
    8000574a:	b781                	j	8000568a <sys_unlink+0xe0>
    return -1;
    8000574c:	557d                	li	a0,-1
    8000574e:	a005                	j	8000576e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005750:	854a                	mv	a0,s2
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	320080e7          	jalr	800(ra) # 80003a72 <iunlockput>
  iunlockput(dp);
    8000575a:	8526                	mv	a0,s1
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	316080e7          	jalr	790(ra) # 80003a72 <iunlockput>
  end_op();
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	afe080e7          	jalr	-1282(ra) # 80004262 <end_op>
  return -1;
    8000576c:	557d                	li	a0,-1
}
    8000576e:	70ae                	ld	ra,232(sp)
    80005770:	740e                	ld	s0,224(sp)
    80005772:	64ee                	ld	s1,216(sp)
    80005774:	694e                	ld	s2,208(sp)
    80005776:	69ae                	ld	s3,200(sp)
    80005778:	616d                	addi	sp,sp,240
    8000577a:	8082                	ret

000000008000577c <sys_open>:

uint64
sys_open(void)
{
    8000577c:	7131                	addi	sp,sp,-192
    8000577e:	fd06                	sd	ra,184(sp)
    80005780:	f922                	sd	s0,176(sp)
    80005782:	f526                	sd	s1,168(sp)
    80005784:	f14a                	sd	s2,160(sp)
    80005786:	ed4e                	sd	s3,152(sp)
    80005788:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000578a:	08000613          	li	a2,128
    8000578e:	f5040593          	addi	a1,s0,-176
    80005792:	4501                	li	a0,0
    80005794:	ffffd097          	auipc	ra,0xffffd
    80005798:	54e080e7          	jalr	1358(ra) # 80002ce2 <argstr>
    return -1;
    8000579c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000579e:	0c054163          	bltz	a0,80005860 <sys_open+0xe4>
    800057a2:	f4c40593          	addi	a1,s0,-180
    800057a6:	4505                	li	a0,1
    800057a8:	ffffd097          	auipc	ra,0xffffd
    800057ac:	4f6080e7          	jalr	1270(ra) # 80002c9e <argint>
    800057b0:	0a054863          	bltz	a0,80005860 <sys_open+0xe4>

  begin_op();
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	a2e080e7          	jalr	-1490(ra) # 800041e2 <begin_op>

  if(omode & O_CREATE){
    800057bc:	f4c42783          	lw	a5,-180(s0)
    800057c0:	2007f793          	andi	a5,a5,512
    800057c4:	cbdd                	beqz	a5,8000587a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057c6:	4681                	li	a3,0
    800057c8:	4601                	li	a2,0
    800057ca:	4589                	li	a1,2
    800057cc:	f5040513          	addi	a0,s0,-176
    800057d0:	00000097          	auipc	ra,0x0
    800057d4:	972080e7          	jalr	-1678(ra) # 80005142 <create>
    800057d8:	892a                	mv	s2,a0
    if(ip == 0){
    800057da:	c959                	beqz	a0,80005870 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057dc:	04491703          	lh	a4,68(s2)
    800057e0:	478d                	li	a5,3
    800057e2:	00f71763          	bne	a4,a5,800057f0 <sys_open+0x74>
    800057e6:	04695703          	lhu	a4,70(s2)
    800057ea:	47a5                	li	a5,9
    800057ec:	0ce7ec63          	bltu	a5,a4,800058c4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	e02080e7          	jalr	-510(ra) # 800045f2 <filealloc>
    800057f8:	89aa                	mv	s3,a0
    800057fa:	10050263          	beqz	a0,800058fe <sys_open+0x182>
    800057fe:	00000097          	auipc	ra,0x0
    80005802:	902080e7          	jalr	-1790(ra) # 80005100 <fdalloc>
    80005806:	84aa                	mv	s1,a0
    80005808:	0e054663          	bltz	a0,800058f4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000580c:	04491703          	lh	a4,68(s2)
    80005810:	478d                	li	a5,3
    80005812:	0cf70463          	beq	a4,a5,800058da <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005816:	4789                	li	a5,2
    80005818:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000581c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005820:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005824:	f4c42783          	lw	a5,-180(s0)
    80005828:	0017c713          	xori	a4,a5,1
    8000582c:	8b05                	andi	a4,a4,1
    8000582e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005832:	0037f713          	andi	a4,a5,3
    80005836:	00e03733          	snez	a4,a4
    8000583a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000583e:	4007f793          	andi	a5,a5,1024
    80005842:	c791                	beqz	a5,8000584e <sys_open+0xd2>
    80005844:	04491703          	lh	a4,68(s2)
    80005848:	4789                	li	a5,2
    8000584a:	08f70f63          	beq	a4,a5,800058e8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000584e:	854a                	mv	a0,s2
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	082080e7          	jalr	130(ra) # 800038d2 <iunlock>
  end_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	a0a080e7          	jalr	-1526(ra) # 80004262 <end_op>

  return fd;
}
    80005860:	8526                	mv	a0,s1
    80005862:	70ea                	ld	ra,184(sp)
    80005864:	744a                	ld	s0,176(sp)
    80005866:	74aa                	ld	s1,168(sp)
    80005868:	790a                	ld	s2,160(sp)
    8000586a:	69ea                	ld	s3,152(sp)
    8000586c:	6129                	addi	sp,sp,192
    8000586e:	8082                	ret
      end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	9f2080e7          	jalr	-1550(ra) # 80004262 <end_op>
      return -1;
    80005878:	b7e5                	j	80005860 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000587a:	f5040513          	addi	a0,s0,-176
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	748080e7          	jalr	1864(ra) # 80003fc6 <namei>
    80005886:	892a                	mv	s2,a0
    80005888:	c905                	beqz	a0,800058b8 <sys_open+0x13c>
    ilock(ip);
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	f86080e7          	jalr	-122(ra) # 80003810 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005892:	04491703          	lh	a4,68(s2)
    80005896:	4785                	li	a5,1
    80005898:	f4f712e3          	bne	a4,a5,800057dc <sys_open+0x60>
    8000589c:	f4c42783          	lw	a5,-180(s0)
    800058a0:	dba1                	beqz	a5,800057f0 <sys_open+0x74>
      iunlockput(ip);
    800058a2:	854a                	mv	a0,s2
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	1ce080e7          	jalr	462(ra) # 80003a72 <iunlockput>
      end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	9b6080e7          	jalr	-1610(ra) # 80004262 <end_op>
      return -1;
    800058b4:	54fd                	li	s1,-1
    800058b6:	b76d                	j	80005860 <sys_open+0xe4>
      end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	9aa080e7          	jalr	-1622(ra) # 80004262 <end_op>
      return -1;
    800058c0:	54fd                	li	s1,-1
    800058c2:	bf79                	j	80005860 <sys_open+0xe4>
    iunlockput(ip);
    800058c4:	854a                	mv	a0,s2
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	1ac080e7          	jalr	428(ra) # 80003a72 <iunlockput>
    end_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	994080e7          	jalr	-1644(ra) # 80004262 <end_op>
    return -1;
    800058d6:	54fd                	li	s1,-1
    800058d8:	b761                	j	80005860 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058da:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058de:	04691783          	lh	a5,70(s2)
    800058e2:	02f99223          	sh	a5,36(s3)
    800058e6:	bf2d                	j	80005820 <sys_open+0xa4>
    itrunc(ip);
    800058e8:	854a                	mv	a0,s2
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	034080e7          	jalr	52(ra) # 8000391e <itrunc>
    800058f2:	bfb1                	j	8000584e <sys_open+0xd2>
      fileclose(f);
    800058f4:	854e                	mv	a0,s3
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	db8080e7          	jalr	-584(ra) # 800046ae <fileclose>
    iunlockput(ip);
    800058fe:	854a                	mv	a0,s2
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	172080e7          	jalr	370(ra) # 80003a72 <iunlockput>
    end_op();
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	95a080e7          	jalr	-1702(ra) # 80004262 <end_op>
    return -1;
    80005910:	54fd                	li	s1,-1
    80005912:	b7b9                	j	80005860 <sys_open+0xe4>

0000000080005914 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005914:	7175                	addi	sp,sp,-144
    80005916:	e506                	sd	ra,136(sp)
    80005918:	e122                	sd	s0,128(sp)
    8000591a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	8c6080e7          	jalr	-1850(ra) # 800041e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005924:	08000613          	li	a2,128
    80005928:	f7040593          	addi	a1,s0,-144
    8000592c:	4501                	li	a0,0
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	3b4080e7          	jalr	948(ra) # 80002ce2 <argstr>
    80005936:	02054963          	bltz	a0,80005968 <sys_mkdir+0x54>
    8000593a:	4681                	li	a3,0
    8000593c:	4601                	li	a2,0
    8000593e:	4585                	li	a1,1
    80005940:	f7040513          	addi	a0,s0,-144
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	7fe080e7          	jalr	2046(ra) # 80005142 <create>
    8000594c:	cd11                	beqz	a0,80005968 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	124080e7          	jalr	292(ra) # 80003a72 <iunlockput>
  end_op();
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	90c080e7          	jalr	-1780(ra) # 80004262 <end_op>
  return 0;
    8000595e:	4501                	li	a0,0
}
    80005960:	60aa                	ld	ra,136(sp)
    80005962:	640a                	ld	s0,128(sp)
    80005964:	6149                	addi	sp,sp,144
    80005966:	8082                	ret
    end_op();
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	8fa080e7          	jalr	-1798(ra) # 80004262 <end_op>
    return -1;
    80005970:	557d                	li	a0,-1
    80005972:	b7fd                	j	80005960 <sys_mkdir+0x4c>

0000000080005974 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005974:	7135                	addi	sp,sp,-160
    80005976:	ed06                	sd	ra,152(sp)
    80005978:	e922                	sd	s0,144(sp)
    8000597a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	866080e7          	jalr	-1946(ra) # 800041e2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005984:	08000613          	li	a2,128
    80005988:	f7040593          	addi	a1,s0,-144
    8000598c:	4501                	li	a0,0
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	354080e7          	jalr	852(ra) # 80002ce2 <argstr>
    80005996:	04054a63          	bltz	a0,800059ea <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000599a:	f6c40593          	addi	a1,s0,-148
    8000599e:	4505                	li	a0,1
    800059a0:	ffffd097          	auipc	ra,0xffffd
    800059a4:	2fe080e7          	jalr	766(ra) # 80002c9e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a8:	04054163          	bltz	a0,800059ea <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059ac:	f6840593          	addi	a1,s0,-152
    800059b0:	4509                	li	a0,2
    800059b2:	ffffd097          	auipc	ra,0xffffd
    800059b6:	2ec080e7          	jalr	748(ra) # 80002c9e <argint>
     argint(1, &major) < 0 ||
    800059ba:	02054863          	bltz	a0,800059ea <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059be:	f6841683          	lh	a3,-152(s0)
    800059c2:	f6c41603          	lh	a2,-148(s0)
    800059c6:	458d                	li	a1,3
    800059c8:	f7040513          	addi	a0,s0,-144
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	776080e7          	jalr	1910(ra) # 80005142 <create>
     argint(2, &minor) < 0 ||
    800059d4:	c919                	beqz	a0,800059ea <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	09c080e7          	jalr	156(ra) # 80003a72 <iunlockput>
  end_op();
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	884080e7          	jalr	-1916(ra) # 80004262 <end_op>
  return 0;
    800059e6:	4501                	li	a0,0
    800059e8:	a031                	j	800059f4 <sys_mknod+0x80>
    end_op();
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	878080e7          	jalr	-1928(ra) # 80004262 <end_op>
    return -1;
    800059f2:	557d                	li	a0,-1
}
    800059f4:	60ea                	ld	ra,152(sp)
    800059f6:	644a                	ld	s0,144(sp)
    800059f8:	610d                	addi	sp,sp,160
    800059fa:	8082                	ret

00000000800059fc <sys_chdir>:

uint64
sys_chdir(void)
{
    800059fc:	7135                	addi	sp,sp,-160
    800059fe:	ed06                	sd	ra,152(sp)
    80005a00:	e922                	sd	s0,144(sp)
    80005a02:	e526                	sd	s1,136(sp)
    80005a04:	e14a                	sd	s2,128(sp)
    80005a06:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a08:	ffffc097          	auipc	ra,0xffffc
    80005a0c:	118080e7          	jalr	280(ra) # 80001b20 <myproc>
    80005a10:	892a                	mv	s2,a0
  
  begin_op();
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	7d0080e7          	jalr	2000(ra) # 800041e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a1a:	08000613          	li	a2,128
    80005a1e:	f6040593          	addi	a1,s0,-160
    80005a22:	4501                	li	a0,0
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	2be080e7          	jalr	702(ra) # 80002ce2 <argstr>
    80005a2c:	04054b63          	bltz	a0,80005a82 <sys_chdir+0x86>
    80005a30:	f6040513          	addi	a0,s0,-160
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	592080e7          	jalr	1426(ra) # 80003fc6 <namei>
    80005a3c:	84aa                	mv	s1,a0
    80005a3e:	c131                	beqz	a0,80005a82 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	dd0080e7          	jalr	-560(ra) # 80003810 <ilock>
  if(ip->type != T_DIR){
    80005a48:	04449703          	lh	a4,68(s1)
    80005a4c:	4785                	li	a5,1
    80005a4e:	04f71063          	bne	a4,a5,80005a8e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	e7e080e7          	jalr	-386(ra) # 800038d2 <iunlock>
  iput(p->cwd);
    80005a5c:	15093503          	ld	a0,336(s2)
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	f6a080e7          	jalr	-150(ra) # 800039ca <iput>
  end_op();
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	7fa080e7          	jalr	2042(ra) # 80004262 <end_op>
  p->cwd = ip;
    80005a70:	14993823          	sd	s1,336(s2)
  return 0;
    80005a74:	4501                	li	a0,0
}
    80005a76:	60ea                	ld	ra,152(sp)
    80005a78:	644a                	ld	s0,144(sp)
    80005a7a:	64aa                	ld	s1,136(sp)
    80005a7c:	690a                	ld	s2,128(sp)
    80005a7e:	610d                	addi	sp,sp,160
    80005a80:	8082                	ret
    end_op();
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	7e0080e7          	jalr	2016(ra) # 80004262 <end_op>
    return -1;
    80005a8a:	557d                	li	a0,-1
    80005a8c:	b7ed                	j	80005a76 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a8e:	8526                	mv	a0,s1
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	fe2080e7          	jalr	-30(ra) # 80003a72 <iunlockput>
    end_op();
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	7ca080e7          	jalr	1994(ra) # 80004262 <end_op>
    return -1;
    80005aa0:	557d                	li	a0,-1
    80005aa2:	bfd1                	j	80005a76 <sys_chdir+0x7a>

0000000080005aa4 <sys_exec>:

uint64
sys_exec(void)
{
    80005aa4:	7145                	addi	sp,sp,-464
    80005aa6:	e786                	sd	ra,456(sp)
    80005aa8:	e3a2                	sd	s0,448(sp)
    80005aaa:	ff26                	sd	s1,440(sp)
    80005aac:	fb4a                	sd	s2,432(sp)
    80005aae:	f74e                	sd	s3,424(sp)
    80005ab0:	f352                	sd	s4,416(sp)
    80005ab2:	ef56                	sd	s5,408(sp)
    80005ab4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ab6:	08000613          	li	a2,128
    80005aba:	f4040593          	addi	a1,s0,-192
    80005abe:	4501                	li	a0,0
    80005ac0:	ffffd097          	auipc	ra,0xffffd
    80005ac4:	222080e7          	jalr	546(ra) # 80002ce2 <argstr>
    return -1;
    80005ac8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005aca:	0c054a63          	bltz	a0,80005b9e <sys_exec+0xfa>
    80005ace:	e3840593          	addi	a1,s0,-456
    80005ad2:	4505                	li	a0,1
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	1ec080e7          	jalr	492(ra) # 80002cc0 <argaddr>
    80005adc:	0c054163          	bltz	a0,80005b9e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ae0:	10000613          	li	a2,256
    80005ae4:	4581                	li	a1,0
    80005ae6:	e4040513          	addi	a0,s0,-448
    80005aea:	ffffb097          	auipc	ra,0xffffb
    80005aee:	340080e7          	jalr	832(ra) # 80000e2a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005af2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005af6:	89a6                	mv	s3,s1
    80005af8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005afa:	02000a13          	li	s4,32
    80005afe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b02:	00391513          	slli	a0,s2,0x3
    80005b06:	e3040593          	addi	a1,s0,-464
    80005b0a:	e3843783          	ld	a5,-456(s0)
    80005b0e:	953e                	add	a0,a0,a5
    80005b10:	ffffd097          	auipc	ra,0xffffd
    80005b14:	0f4080e7          	jalr	244(ra) # 80002c04 <fetchaddr>
    80005b18:	02054a63          	bltz	a0,80005b4c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b1c:	e3043783          	ld	a5,-464(s0)
    80005b20:	c3b9                	beqz	a5,80005b66 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b22:	ffffb097          	auipc	ra,0xffffb
    80005b26:	100080e7          	jalr	256(ra) # 80000c22 <kalloc>
    80005b2a:	85aa                	mv	a1,a0
    80005b2c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b30:	cd11                	beqz	a0,80005b4c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b32:	6605                	lui	a2,0x1
    80005b34:	e3043503          	ld	a0,-464(s0)
    80005b38:	ffffd097          	auipc	ra,0xffffd
    80005b3c:	11e080e7          	jalr	286(ra) # 80002c56 <fetchstr>
    80005b40:	00054663          	bltz	a0,80005b4c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b44:	0905                	addi	s2,s2,1
    80005b46:	09a1                	addi	s3,s3,8
    80005b48:	fb491be3          	bne	s2,s4,80005afe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b4c:	10048913          	addi	s2,s1,256
    80005b50:	6088                	ld	a0,0(s1)
    80005b52:	c529                	beqz	a0,80005b9c <sys_exec+0xf8>
    kfree(argv[i]);
    80005b54:	ffffb097          	auipc	ra,0xffffb
    80005b58:	f92080e7          	jalr	-110(ra) # 80000ae6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b5c:	04a1                	addi	s1,s1,8
    80005b5e:	ff2499e3          	bne	s1,s2,80005b50 <sys_exec+0xac>
  return -1;
    80005b62:	597d                	li	s2,-1
    80005b64:	a82d                	j	80005b9e <sys_exec+0xfa>
      argv[i] = 0;
    80005b66:	0a8e                	slli	s5,s5,0x3
    80005b68:	fc040793          	addi	a5,s0,-64
    80005b6c:	9abe                	add	s5,s5,a5
    80005b6e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b72:	e4040593          	addi	a1,s0,-448
    80005b76:	f4040513          	addi	a0,s0,-192
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	194080e7          	jalr	404(ra) # 80004d0e <exec>
    80005b82:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b84:	10048993          	addi	s3,s1,256
    80005b88:	6088                	ld	a0,0(s1)
    80005b8a:	c911                	beqz	a0,80005b9e <sys_exec+0xfa>
    kfree(argv[i]);
    80005b8c:	ffffb097          	auipc	ra,0xffffb
    80005b90:	f5a080e7          	jalr	-166(ra) # 80000ae6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b94:	04a1                	addi	s1,s1,8
    80005b96:	ff3499e3          	bne	s1,s3,80005b88 <sys_exec+0xe4>
    80005b9a:	a011                	j	80005b9e <sys_exec+0xfa>
  return -1;
    80005b9c:	597d                	li	s2,-1
}
    80005b9e:	854a                	mv	a0,s2
    80005ba0:	60be                	ld	ra,456(sp)
    80005ba2:	641e                	ld	s0,448(sp)
    80005ba4:	74fa                	ld	s1,440(sp)
    80005ba6:	795a                	ld	s2,432(sp)
    80005ba8:	79ba                	ld	s3,424(sp)
    80005baa:	7a1a                	ld	s4,416(sp)
    80005bac:	6afa                	ld	s5,408(sp)
    80005bae:	6179                	addi	sp,sp,464
    80005bb0:	8082                	ret

0000000080005bb2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bb2:	7139                	addi	sp,sp,-64
    80005bb4:	fc06                	sd	ra,56(sp)
    80005bb6:	f822                	sd	s0,48(sp)
    80005bb8:	f426                	sd	s1,40(sp)
    80005bba:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bbc:	ffffc097          	auipc	ra,0xffffc
    80005bc0:	f64080e7          	jalr	-156(ra) # 80001b20 <myproc>
    80005bc4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bc6:	fd840593          	addi	a1,s0,-40
    80005bca:	4501                	li	a0,0
    80005bcc:	ffffd097          	auipc	ra,0xffffd
    80005bd0:	0f4080e7          	jalr	244(ra) # 80002cc0 <argaddr>
    return -1;
    80005bd4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bd6:	0e054063          	bltz	a0,80005cb6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bda:	fc840593          	addi	a1,s0,-56
    80005bde:	fd040513          	addi	a0,s0,-48
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	dfc080e7          	jalr	-516(ra) # 800049de <pipealloc>
    return -1;
    80005bea:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bec:	0c054563          	bltz	a0,80005cb6 <sys_pipe+0x104>
  fd0 = -1;
    80005bf0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bf4:	fd043503          	ld	a0,-48(s0)
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	508080e7          	jalr	1288(ra) # 80005100 <fdalloc>
    80005c00:	fca42223          	sw	a0,-60(s0)
    80005c04:	08054c63          	bltz	a0,80005c9c <sys_pipe+0xea>
    80005c08:	fc843503          	ld	a0,-56(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	4f4080e7          	jalr	1268(ra) # 80005100 <fdalloc>
    80005c14:	fca42023          	sw	a0,-64(s0)
    80005c18:	06054863          	bltz	a0,80005c88 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c1c:	4691                	li	a3,4
    80005c1e:	fc440613          	addi	a2,s0,-60
    80005c22:	fd843583          	ld	a1,-40(s0)
    80005c26:	68a8                	ld	a0,80(s1)
    80005c28:	ffffc097          	auipc	ra,0xffffc
    80005c2c:	b94080e7          	jalr	-1132(ra) # 800017bc <copyout>
    80005c30:	02054063          	bltz	a0,80005c50 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c34:	4691                	li	a3,4
    80005c36:	fc040613          	addi	a2,s0,-64
    80005c3a:	fd843583          	ld	a1,-40(s0)
    80005c3e:	0591                	addi	a1,a1,4
    80005c40:	68a8                	ld	a0,80(s1)
    80005c42:	ffffc097          	auipc	ra,0xffffc
    80005c46:	b7a080e7          	jalr	-1158(ra) # 800017bc <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c4a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c4c:	06055563          	bgez	a0,80005cb6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c50:	fc442783          	lw	a5,-60(s0)
    80005c54:	07e9                	addi	a5,a5,26
    80005c56:	078e                	slli	a5,a5,0x3
    80005c58:	97a6                	add	a5,a5,s1
    80005c5a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c5e:	fc042503          	lw	a0,-64(s0)
    80005c62:	0569                	addi	a0,a0,26
    80005c64:	050e                	slli	a0,a0,0x3
    80005c66:	9526                	add	a0,a0,s1
    80005c68:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c6c:	fd043503          	ld	a0,-48(s0)
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	a3e080e7          	jalr	-1474(ra) # 800046ae <fileclose>
    fileclose(wf);
    80005c78:	fc843503          	ld	a0,-56(s0)
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	a32080e7          	jalr	-1486(ra) # 800046ae <fileclose>
    return -1;
    80005c84:	57fd                	li	a5,-1
    80005c86:	a805                	j	80005cb6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c88:	fc442783          	lw	a5,-60(s0)
    80005c8c:	0007c863          	bltz	a5,80005c9c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c90:	01a78513          	addi	a0,a5,26
    80005c94:	050e                	slli	a0,a0,0x3
    80005c96:	9526                	add	a0,a0,s1
    80005c98:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c9c:	fd043503          	ld	a0,-48(s0)
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	a0e080e7          	jalr	-1522(ra) # 800046ae <fileclose>
    fileclose(wf);
    80005ca8:	fc843503          	ld	a0,-56(s0)
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	a02080e7          	jalr	-1534(ra) # 800046ae <fileclose>
    return -1;
    80005cb4:	57fd                	li	a5,-1
}
    80005cb6:	853e                	mv	a0,a5
    80005cb8:	70e2                	ld	ra,56(sp)
    80005cba:	7442                	ld	s0,48(sp)
    80005cbc:	74a2                	ld	s1,40(sp)
    80005cbe:	6121                	addi	sp,sp,64
    80005cc0:	8082                	ret
	...

0000000080005cd0 <kernelvec>:
    80005cd0:	7111                	addi	sp,sp,-256
    80005cd2:	e006                	sd	ra,0(sp)
    80005cd4:	e40a                	sd	sp,8(sp)
    80005cd6:	e80e                	sd	gp,16(sp)
    80005cd8:	ec12                	sd	tp,24(sp)
    80005cda:	f016                	sd	t0,32(sp)
    80005cdc:	f41a                	sd	t1,40(sp)
    80005cde:	f81e                	sd	t2,48(sp)
    80005ce0:	fc22                	sd	s0,56(sp)
    80005ce2:	e0a6                	sd	s1,64(sp)
    80005ce4:	e4aa                	sd	a0,72(sp)
    80005ce6:	e8ae                	sd	a1,80(sp)
    80005ce8:	ecb2                	sd	a2,88(sp)
    80005cea:	f0b6                	sd	a3,96(sp)
    80005cec:	f4ba                	sd	a4,104(sp)
    80005cee:	f8be                	sd	a5,112(sp)
    80005cf0:	fcc2                	sd	a6,120(sp)
    80005cf2:	e146                	sd	a7,128(sp)
    80005cf4:	e54a                	sd	s2,136(sp)
    80005cf6:	e94e                	sd	s3,144(sp)
    80005cf8:	ed52                	sd	s4,152(sp)
    80005cfa:	f156                	sd	s5,160(sp)
    80005cfc:	f55a                	sd	s6,168(sp)
    80005cfe:	f95e                	sd	s7,176(sp)
    80005d00:	fd62                	sd	s8,184(sp)
    80005d02:	e1e6                	sd	s9,192(sp)
    80005d04:	e5ea                	sd	s10,200(sp)
    80005d06:	e9ee                	sd	s11,208(sp)
    80005d08:	edf2                	sd	t3,216(sp)
    80005d0a:	f1f6                	sd	t4,224(sp)
    80005d0c:	f5fa                	sd	t5,232(sp)
    80005d0e:	f9fe                	sd	t6,240(sp)
    80005d10:	bfbfc0ef          	jal	ra,8000290a <kerneltrap>
    80005d14:	6082                	ld	ra,0(sp)
    80005d16:	6122                	ld	sp,8(sp)
    80005d18:	61c2                	ld	gp,16(sp)
    80005d1a:	7282                	ld	t0,32(sp)
    80005d1c:	7322                	ld	t1,40(sp)
    80005d1e:	73c2                	ld	t2,48(sp)
    80005d20:	7462                	ld	s0,56(sp)
    80005d22:	6486                	ld	s1,64(sp)
    80005d24:	6526                	ld	a0,72(sp)
    80005d26:	65c6                	ld	a1,80(sp)
    80005d28:	6666                	ld	a2,88(sp)
    80005d2a:	7686                	ld	a3,96(sp)
    80005d2c:	7726                	ld	a4,104(sp)
    80005d2e:	77c6                	ld	a5,112(sp)
    80005d30:	7866                	ld	a6,120(sp)
    80005d32:	688a                	ld	a7,128(sp)
    80005d34:	692a                	ld	s2,136(sp)
    80005d36:	69ca                	ld	s3,144(sp)
    80005d38:	6a6a                	ld	s4,152(sp)
    80005d3a:	7a8a                	ld	s5,160(sp)
    80005d3c:	7b2a                	ld	s6,168(sp)
    80005d3e:	7bca                	ld	s7,176(sp)
    80005d40:	7c6a                	ld	s8,184(sp)
    80005d42:	6c8e                	ld	s9,192(sp)
    80005d44:	6d2e                	ld	s10,200(sp)
    80005d46:	6dce                	ld	s11,208(sp)
    80005d48:	6e6e                	ld	t3,216(sp)
    80005d4a:	7e8e                	ld	t4,224(sp)
    80005d4c:	7f2e                	ld	t5,232(sp)
    80005d4e:	7fce                	ld	t6,240(sp)
    80005d50:	6111                	addi	sp,sp,256
    80005d52:	10200073          	sret
    80005d56:	00000013          	nop
    80005d5a:	00000013          	nop
    80005d5e:	0001                	nop

0000000080005d60 <timervec>:
    80005d60:	34051573          	csrrw	a0,mscratch,a0
    80005d64:	e10c                	sd	a1,0(a0)
    80005d66:	e510                	sd	a2,8(a0)
    80005d68:	e914                	sd	a3,16(a0)
    80005d6a:	6d0c                	ld	a1,24(a0)
    80005d6c:	7110                	ld	a2,32(a0)
    80005d6e:	6194                	ld	a3,0(a1)
    80005d70:	96b2                	add	a3,a3,a2
    80005d72:	e194                	sd	a3,0(a1)
    80005d74:	4589                	li	a1,2
    80005d76:	14459073          	csrw	sip,a1
    80005d7a:	6914                	ld	a3,16(a0)
    80005d7c:	6510                	ld	a2,8(a0)
    80005d7e:	610c                	ld	a1,0(a0)
    80005d80:	34051573          	csrrw	a0,mscratch,a0
    80005d84:	30200073          	mret
	...

0000000080005d8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d8a:	1141                	addi	sp,sp,-16
    80005d8c:	e422                	sd	s0,8(sp)
    80005d8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d90:	0c0007b7          	lui	a5,0xc000
    80005d94:	4705                	li	a4,1
    80005d96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d98:	c3d8                	sw	a4,4(a5)
}
    80005d9a:	6422                	ld	s0,8(sp)
    80005d9c:	0141                	addi	sp,sp,16
    80005d9e:	8082                	ret

0000000080005da0 <plicinithart>:

void
plicinithart(void)
{
    80005da0:	1141                	addi	sp,sp,-16
    80005da2:	e406                	sd	ra,8(sp)
    80005da4:	e022                	sd	s0,0(sp)
    80005da6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	d4c080e7          	jalr	-692(ra) # 80001af4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005db0:	0085171b          	slliw	a4,a0,0x8
    80005db4:	0c0027b7          	lui	a5,0xc002
    80005db8:	97ba                	add	a5,a5,a4
    80005dba:	40200713          	li	a4,1026
    80005dbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005dc2:	00d5151b          	slliw	a0,a0,0xd
    80005dc6:	0c2017b7          	lui	a5,0xc201
    80005dca:	953e                	add	a0,a0,a5
    80005dcc:	00052023          	sw	zero,0(a0)
}
    80005dd0:	60a2                	ld	ra,8(sp)
    80005dd2:	6402                	ld	s0,0(sp)
    80005dd4:	0141                	addi	sp,sp,16
    80005dd6:	8082                	ret

0000000080005dd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dd8:	1141                	addi	sp,sp,-16
    80005dda:	e406                	sd	ra,8(sp)
    80005ddc:	e022                	sd	s0,0(sp)
    80005dde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005de0:	ffffc097          	auipc	ra,0xffffc
    80005de4:	d14080e7          	jalr	-748(ra) # 80001af4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005de8:	00d5179b          	slliw	a5,a0,0xd
    80005dec:	0c201537          	lui	a0,0xc201
    80005df0:	953e                	add	a0,a0,a5
  return irq;
}
    80005df2:	4148                	lw	a0,4(a0)
    80005df4:	60a2                	ld	ra,8(sp)
    80005df6:	6402                	ld	s0,0(sp)
    80005df8:	0141                	addi	sp,sp,16
    80005dfa:	8082                	ret

0000000080005dfc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dfc:	1101                	addi	sp,sp,-32
    80005dfe:	ec06                	sd	ra,24(sp)
    80005e00:	e822                	sd	s0,16(sp)
    80005e02:	e426                	sd	s1,8(sp)
    80005e04:	1000                	addi	s0,sp,32
    80005e06:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	cec080e7          	jalr	-788(ra) # 80001af4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e10:	00d5151b          	slliw	a0,a0,0xd
    80005e14:	0c2017b7          	lui	a5,0xc201
    80005e18:	97aa                	add	a5,a5,a0
    80005e1a:	c3c4                	sw	s1,4(a5)
}
    80005e1c:	60e2                	ld	ra,24(sp)
    80005e1e:	6442                	ld	s0,16(sp)
    80005e20:	64a2                	ld	s1,8(sp)
    80005e22:	6105                	addi	sp,sp,32
    80005e24:	8082                	ret

0000000080005e26 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e26:	1141                	addi	sp,sp,-16
    80005e28:	e406                	sd	ra,8(sp)
    80005e2a:	e022                	sd	s0,0(sp)
    80005e2c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e2e:	479d                	li	a5,7
    80005e30:	06a7c963          	blt	a5,a0,80005ea2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e34:	0005d797          	auipc	a5,0x5d
    80005e38:	1cc78793          	addi	a5,a5,460 # 80063000 <disk>
    80005e3c:	00a78733          	add	a4,a5,a0
    80005e40:	6789                	lui	a5,0x2
    80005e42:	97ba                	add	a5,a5,a4
    80005e44:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e48:	e7ad                	bnez	a5,80005eb2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e4a:	00451793          	slli	a5,a0,0x4
    80005e4e:	0005f717          	auipc	a4,0x5f
    80005e52:	1b270713          	addi	a4,a4,434 # 80065000 <disk+0x2000>
    80005e56:	6314                	ld	a3,0(a4)
    80005e58:	96be                	add	a3,a3,a5
    80005e5a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e5e:	6314                	ld	a3,0(a4)
    80005e60:	96be                	add	a3,a3,a5
    80005e62:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e66:	6314                	ld	a3,0(a4)
    80005e68:	96be                	add	a3,a3,a5
    80005e6a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e6e:	6318                	ld	a4,0(a4)
    80005e70:	97ba                	add	a5,a5,a4
    80005e72:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e76:	0005d797          	auipc	a5,0x5d
    80005e7a:	18a78793          	addi	a5,a5,394 # 80063000 <disk>
    80005e7e:	97aa                	add	a5,a5,a0
    80005e80:	6509                	lui	a0,0x2
    80005e82:	953e                	add	a0,a0,a5
    80005e84:	4785                	li	a5,1
    80005e86:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e8a:	0005f517          	auipc	a0,0x5f
    80005e8e:	18e50513          	addi	a0,a0,398 # 80065018 <disk+0x2018>
    80005e92:	ffffc097          	auipc	ra,0xffffc
    80005e96:	4d6080e7          	jalr	1238(ra) # 80002368 <wakeup>
}
    80005e9a:	60a2                	ld	ra,8(sp)
    80005e9c:	6402                	ld	s0,0(sp)
    80005e9e:	0141                	addi	sp,sp,16
    80005ea0:	8082                	ret
    panic("free_desc 1");
    80005ea2:	00003517          	auipc	a0,0x3
    80005ea6:	91e50513          	addi	a0,a0,-1762 # 800087c0 <syscalls+0x320>
    80005eaa:	ffffa097          	auipc	ra,0xffffa
    80005eae:	694080e7          	jalr	1684(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005eb2:	00003517          	auipc	a0,0x3
    80005eb6:	91e50513          	addi	a0,a0,-1762 # 800087d0 <syscalls+0x330>
    80005eba:	ffffa097          	auipc	ra,0xffffa
    80005ebe:	684080e7          	jalr	1668(ra) # 8000053e <panic>

0000000080005ec2 <virtio_disk_init>:
{
    80005ec2:	1101                	addi	sp,sp,-32
    80005ec4:	ec06                	sd	ra,24(sp)
    80005ec6:	e822                	sd	s0,16(sp)
    80005ec8:	e426                	sd	s1,8(sp)
    80005eca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ecc:	00003597          	auipc	a1,0x3
    80005ed0:	91458593          	addi	a1,a1,-1772 # 800087e0 <syscalls+0x340>
    80005ed4:	0005f517          	auipc	a0,0x5f
    80005ed8:	25450513          	addi	a0,a0,596 # 80065128 <disk+0x2128>
    80005edc:	ffffb097          	auipc	ra,0xffffb
    80005ee0:	dc2080e7          	jalr	-574(ra) # 80000c9e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ee4:	100017b7          	lui	a5,0x10001
    80005ee8:	4398                	lw	a4,0(a5)
    80005eea:	2701                	sext.w	a4,a4
    80005eec:	747277b7          	lui	a5,0x74727
    80005ef0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ef4:	0ef71163          	bne	a4,a5,80005fd6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ef8:	100017b7          	lui	a5,0x10001
    80005efc:	43dc                	lw	a5,4(a5)
    80005efe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f00:	4705                	li	a4,1
    80005f02:	0ce79a63          	bne	a5,a4,80005fd6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f06:	100017b7          	lui	a5,0x10001
    80005f0a:	479c                	lw	a5,8(a5)
    80005f0c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f0e:	4709                	li	a4,2
    80005f10:	0ce79363          	bne	a5,a4,80005fd6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f14:	100017b7          	lui	a5,0x10001
    80005f18:	47d8                	lw	a4,12(a5)
    80005f1a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f1c:	554d47b7          	lui	a5,0x554d4
    80005f20:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f24:	0af71963          	bne	a4,a5,80005fd6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f28:	100017b7          	lui	a5,0x10001
    80005f2c:	4705                	li	a4,1
    80005f2e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f30:	470d                	li	a4,3
    80005f32:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f34:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f36:	c7ffe737          	lui	a4,0xc7ffe
    80005f3a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47f9875f>
    80005f3e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f40:	2701                	sext.w	a4,a4
    80005f42:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f44:	472d                	li	a4,11
    80005f46:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f48:	473d                	li	a4,15
    80005f4a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f4c:	6705                	lui	a4,0x1
    80005f4e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f50:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f54:	5bdc                	lw	a5,52(a5)
    80005f56:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f58:	c7d9                	beqz	a5,80005fe6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f5a:	471d                	li	a4,7
    80005f5c:	08f77d63          	bgeu	a4,a5,80005ff6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f60:	100014b7          	lui	s1,0x10001
    80005f64:	47a1                	li	a5,8
    80005f66:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f68:	6609                	lui	a2,0x2
    80005f6a:	4581                	li	a1,0
    80005f6c:	0005d517          	auipc	a0,0x5d
    80005f70:	09450513          	addi	a0,a0,148 # 80063000 <disk>
    80005f74:	ffffb097          	auipc	ra,0xffffb
    80005f78:	eb6080e7          	jalr	-330(ra) # 80000e2a <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f7c:	0005d717          	auipc	a4,0x5d
    80005f80:	08470713          	addi	a4,a4,132 # 80063000 <disk>
    80005f84:	00c75793          	srli	a5,a4,0xc
    80005f88:	2781                	sext.w	a5,a5
    80005f8a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f8c:	0005f797          	auipc	a5,0x5f
    80005f90:	07478793          	addi	a5,a5,116 # 80065000 <disk+0x2000>
    80005f94:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f96:	0005d717          	auipc	a4,0x5d
    80005f9a:	0ea70713          	addi	a4,a4,234 # 80063080 <disk+0x80>
    80005f9e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fa0:	0005e717          	auipc	a4,0x5e
    80005fa4:	06070713          	addi	a4,a4,96 # 80064000 <disk+0x1000>
    80005fa8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005faa:	4705                	li	a4,1
    80005fac:	00e78c23          	sb	a4,24(a5)
    80005fb0:	00e78ca3          	sb	a4,25(a5)
    80005fb4:	00e78d23          	sb	a4,26(a5)
    80005fb8:	00e78da3          	sb	a4,27(a5)
    80005fbc:	00e78e23          	sb	a4,28(a5)
    80005fc0:	00e78ea3          	sb	a4,29(a5)
    80005fc4:	00e78f23          	sb	a4,30(a5)
    80005fc8:	00e78fa3          	sb	a4,31(a5)
}
    80005fcc:	60e2                	ld	ra,24(sp)
    80005fce:	6442                	ld	s0,16(sp)
    80005fd0:	64a2                	ld	s1,8(sp)
    80005fd2:	6105                	addi	sp,sp,32
    80005fd4:	8082                	ret
    panic("could not find virtio disk");
    80005fd6:	00003517          	auipc	a0,0x3
    80005fda:	81a50513          	addi	a0,a0,-2022 # 800087f0 <syscalls+0x350>
    80005fde:	ffffa097          	auipc	ra,0xffffa
    80005fe2:	560080e7          	jalr	1376(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005fe6:	00003517          	auipc	a0,0x3
    80005fea:	82a50513          	addi	a0,a0,-2006 # 80008810 <syscalls+0x370>
    80005fee:	ffffa097          	auipc	ra,0xffffa
    80005ff2:	550080e7          	jalr	1360(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005ff6:	00003517          	auipc	a0,0x3
    80005ffa:	83a50513          	addi	a0,a0,-1990 # 80008830 <syscalls+0x390>
    80005ffe:	ffffa097          	auipc	ra,0xffffa
    80006002:	540080e7          	jalr	1344(ra) # 8000053e <panic>

0000000080006006 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006006:	7159                	addi	sp,sp,-112
    80006008:	f486                	sd	ra,104(sp)
    8000600a:	f0a2                	sd	s0,96(sp)
    8000600c:	eca6                	sd	s1,88(sp)
    8000600e:	e8ca                	sd	s2,80(sp)
    80006010:	e4ce                	sd	s3,72(sp)
    80006012:	e0d2                	sd	s4,64(sp)
    80006014:	fc56                	sd	s5,56(sp)
    80006016:	f85a                	sd	s6,48(sp)
    80006018:	f45e                	sd	s7,40(sp)
    8000601a:	f062                	sd	s8,32(sp)
    8000601c:	ec66                	sd	s9,24(sp)
    8000601e:	e86a                	sd	s10,16(sp)
    80006020:	1880                	addi	s0,sp,112
    80006022:	892a                	mv	s2,a0
    80006024:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006026:	00c52c83          	lw	s9,12(a0)
    8000602a:	001c9c9b          	slliw	s9,s9,0x1
    8000602e:	1c82                	slli	s9,s9,0x20
    80006030:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006034:	0005f517          	auipc	a0,0x5f
    80006038:	0f450513          	addi	a0,a0,244 # 80065128 <disk+0x2128>
    8000603c:	ffffb097          	auipc	ra,0xffffb
    80006040:	cf2080e7          	jalr	-782(ra) # 80000d2e <acquire>
  for(int i = 0; i < 3; i++){
    80006044:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006046:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006048:	0005db97          	auipc	s7,0x5d
    8000604c:	fb8b8b93          	addi	s7,s7,-72 # 80063000 <disk>
    80006050:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006052:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006054:	8a4e                	mv	s4,s3
    80006056:	a051                	j	800060da <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006058:	00fb86b3          	add	a3,s7,a5
    8000605c:	96da                	add	a3,a3,s6
    8000605e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006062:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006064:	0207c563          	bltz	a5,8000608e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006068:	2485                	addiw	s1,s1,1
    8000606a:	0711                	addi	a4,a4,4
    8000606c:	25548063          	beq	s1,s5,800062ac <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006070:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006072:	0005f697          	auipc	a3,0x5f
    80006076:	fa668693          	addi	a3,a3,-90 # 80065018 <disk+0x2018>
    8000607a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000607c:	0006c583          	lbu	a1,0(a3)
    80006080:	fde1                	bnez	a1,80006058 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006082:	2785                	addiw	a5,a5,1
    80006084:	0685                	addi	a3,a3,1
    80006086:	ff879be3          	bne	a5,s8,8000607c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000608a:	57fd                	li	a5,-1
    8000608c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000608e:	02905a63          	blez	s1,800060c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006092:	f9042503          	lw	a0,-112(s0)
    80006096:	00000097          	auipc	ra,0x0
    8000609a:	d90080e7          	jalr	-624(ra) # 80005e26 <free_desc>
      for(int j = 0; j < i; j++)
    8000609e:	4785                	li	a5,1
    800060a0:	0297d163          	bge	a5,s1,800060c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060a4:	f9442503          	lw	a0,-108(s0)
    800060a8:	00000097          	auipc	ra,0x0
    800060ac:	d7e080e7          	jalr	-642(ra) # 80005e26 <free_desc>
      for(int j = 0; j < i; j++)
    800060b0:	4789                	li	a5,2
    800060b2:	0097d863          	bge	a5,s1,800060c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060b6:	f9842503          	lw	a0,-104(s0)
    800060ba:	00000097          	auipc	ra,0x0
    800060be:	d6c080e7          	jalr	-660(ra) # 80005e26 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060c2:	0005f597          	auipc	a1,0x5f
    800060c6:	06658593          	addi	a1,a1,102 # 80065128 <disk+0x2128>
    800060ca:	0005f517          	auipc	a0,0x5f
    800060ce:	f4e50513          	addi	a0,a0,-178 # 80065018 <disk+0x2018>
    800060d2:	ffffc097          	auipc	ra,0xffffc
    800060d6:	10a080e7          	jalr	266(ra) # 800021dc <sleep>
  for(int i = 0; i < 3; i++){
    800060da:	f9040713          	addi	a4,s0,-112
    800060de:	84ce                	mv	s1,s3
    800060e0:	bf41                	j	80006070 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800060e2:	20058713          	addi	a4,a1,512
    800060e6:	00471693          	slli	a3,a4,0x4
    800060ea:	0005d717          	auipc	a4,0x5d
    800060ee:	f1670713          	addi	a4,a4,-234 # 80063000 <disk>
    800060f2:	9736                	add	a4,a4,a3
    800060f4:	4685                	li	a3,1
    800060f6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060fa:	20058713          	addi	a4,a1,512
    800060fe:	00471693          	slli	a3,a4,0x4
    80006102:	0005d717          	auipc	a4,0x5d
    80006106:	efe70713          	addi	a4,a4,-258 # 80063000 <disk>
    8000610a:	9736                	add	a4,a4,a3
    8000610c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006110:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006114:	7679                	lui	a2,0xffffe
    80006116:	963e                	add	a2,a2,a5
    80006118:	0005f697          	auipc	a3,0x5f
    8000611c:	ee868693          	addi	a3,a3,-280 # 80065000 <disk+0x2000>
    80006120:	6298                	ld	a4,0(a3)
    80006122:	9732                	add	a4,a4,a2
    80006124:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006126:	6298                	ld	a4,0(a3)
    80006128:	9732                	add	a4,a4,a2
    8000612a:	4541                	li	a0,16
    8000612c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000612e:	6298                	ld	a4,0(a3)
    80006130:	9732                	add	a4,a4,a2
    80006132:	4505                	li	a0,1
    80006134:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006138:	f9442703          	lw	a4,-108(s0)
    8000613c:	6288                	ld	a0,0(a3)
    8000613e:	962a                	add	a2,a2,a0
    80006140:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ff9800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006144:	0712                	slli	a4,a4,0x4
    80006146:	6290                	ld	a2,0(a3)
    80006148:	963a                	add	a2,a2,a4
    8000614a:	05890513          	addi	a0,s2,88
    8000614e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006150:	6294                	ld	a3,0(a3)
    80006152:	96ba                	add	a3,a3,a4
    80006154:	40000613          	li	a2,1024
    80006158:	c690                	sw	a2,8(a3)
  if(write)
    8000615a:	140d0063          	beqz	s10,8000629a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000615e:	0005f697          	auipc	a3,0x5f
    80006162:	ea26b683          	ld	a3,-350(a3) # 80065000 <disk+0x2000>
    80006166:	96ba                	add	a3,a3,a4
    80006168:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000616c:	0005d817          	auipc	a6,0x5d
    80006170:	e9480813          	addi	a6,a6,-364 # 80063000 <disk>
    80006174:	0005f517          	auipc	a0,0x5f
    80006178:	e8c50513          	addi	a0,a0,-372 # 80065000 <disk+0x2000>
    8000617c:	6114                	ld	a3,0(a0)
    8000617e:	96ba                	add	a3,a3,a4
    80006180:	00c6d603          	lhu	a2,12(a3)
    80006184:	00166613          	ori	a2,a2,1
    80006188:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000618c:	f9842683          	lw	a3,-104(s0)
    80006190:	6110                	ld	a2,0(a0)
    80006192:	9732                	add	a4,a4,a2
    80006194:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006198:	20058613          	addi	a2,a1,512
    8000619c:	0612                	slli	a2,a2,0x4
    8000619e:	9642                	add	a2,a2,a6
    800061a0:	577d                	li	a4,-1
    800061a2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061a6:	00469713          	slli	a4,a3,0x4
    800061aa:	6114                	ld	a3,0(a0)
    800061ac:	96ba                	add	a3,a3,a4
    800061ae:	03078793          	addi	a5,a5,48
    800061b2:	97c2                	add	a5,a5,a6
    800061b4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800061b6:	611c                	ld	a5,0(a0)
    800061b8:	97ba                	add	a5,a5,a4
    800061ba:	4685                	li	a3,1
    800061bc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061be:	611c                	ld	a5,0(a0)
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	4809                	li	a6,2
    800061c4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061c8:	611c                	ld	a5,0(a0)
    800061ca:	973e                	add	a4,a4,a5
    800061cc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061d0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800061d4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061d8:	6518                	ld	a4,8(a0)
    800061da:	00275783          	lhu	a5,2(a4)
    800061de:	8b9d                	andi	a5,a5,7
    800061e0:	0786                	slli	a5,a5,0x1
    800061e2:	97ba                	add	a5,a5,a4
    800061e4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800061e8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061ec:	6518                	ld	a4,8(a0)
    800061ee:	00275783          	lhu	a5,2(a4)
    800061f2:	2785                	addiw	a5,a5,1
    800061f4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061f8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061fc:	100017b7          	lui	a5,0x10001
    80006200:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006204:	00492703          	lw	a4,4(s2)
    80006208:	4785                	li	a5,1
    8000620a:	02f71163          	bne	a4,a5,8000622c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000620e:	0005f997          	auipc	s3,0x5f
    80006212:	f1a98993          	addi	s3,s3,-230 # 80065128 <disk+0x2128>
  while(b->disk == 1) {
    80006216:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006218:	85ce                	mv	a1,s3
    8000621a:	854a                	mv	a0,s2
    8000621c:	ffffc097          	auipc	ra,0xffffc
    80006220:	fc0080e7          	jalr	-64(ra) # 800021dc <sleep>
  while(b->disk == 1) {
    80006224:	00492783          	lw	a5,4(s2)
    80006228:	fe9788e3          	beq	a5,s1,80006218 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000622c:	f9042903          	lw	s2,-112(s0)
    80006230:	20090793          	addi	a5,s2,512
    80006234:	00479713          	slli	a4,a5,0x4
    80006238:	0005d797          	auipc	a5,0x5d
    8000623c:	dc878793          	addi	a5,a5,-568 # 80063000 <disk>
    80006240:	97ba                	add	a5,a5,a4
    80006242:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006246:	0005f997          	auipc	s3,0x5f
    8000624a:	dba98993          	addi	s3,s3,-582 # 80065000 <disk+0x2000>
    8000624e:	00491713          	slli	a4,s2,0x4
    80006252:	0009b783          	ld	a5,0(s3)
    80006256:	97ba                	add	a5,a5,a4
    80006258:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000625c:	854a                	mv	a0,s2
    8000625e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006262:	00000097          	auipc	ra,0x0
    80006266:	bc4080e7          	jalr	-1084(ra) # 80005e26 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000626a:	8885                	andi	s1,s1,1
    8000626c:	f0ed                	bnez	s1,8000624e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000626e:	0005f517          	auipc	a0,0x5f
    80006272:	eba50513          	addi	a0,a0,-326 # 80065128 <disk+0x2128>
    80006276:	ffffb097          	auipc	ra,0xffffb
    8000627a:	b6c080e7          	jalr	-1172(ra) # 80000de2 <release>
}
    8000627e:	70a6                	ld	ra,104(sp)
    80006280:	7406                	ld	s0,96(sp)
    80006282:	64e6                	ld	s1,88(sp)
    80006284:	6946                	ld	s2,80(sp)
    80006286:	69a6                	ld	s3,72(sp)
    80006288:	6a06                	ld	s4,64(sp)
    8000628a:	7ae2                	ld	s5,56(sp)
    8000628c:	7b42                	ld	s6,48(sp)
    8000628e:	7ba2                	ld	s7,40(sp)
    80006290:	7c02                	ld	s8,32(sp)
    80006292:	6ce2                	ld	s9,24(sp)
    80006294:	6d42                	ld	s10,16(sp)
    80006296:	6165                	addi	sp,sp,112
    80006298:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000629a:	0005f697          	auipc	a3,0x5f
    8000629e:	d666b683          	ld	a3,-666(a3) # 80065000 <disk+0x2000>
    800062a2:	96ba                	add	a3,a3,a4
    800062a4:	4609                	li	a2,2
    800062a6:	00c69623          	sh	a2,12(a3)
    800062aa:	b5c9                	j	8000616c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062ac:	f9042583          	lw	a1,-112(s0)
    800062b0:	20058793          	addi	a5,a1,512
    800062b4:	0792                	slli	a5,a5,0x4
    800062b6:	0005d517          	auipc	a0,0x5d
    800062ba:	df250513          	addi	a0,a0,-526 # 800630a8 <disk+0xa8>
    800062be:	953e                	add	a0,a0,a5
  if(write)
    800062c0:	e20d11e3          	bnez	s10,800060e2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062c4:	20058713          	addi	a4,a1,512
    800062c8:	00471693          	slli	a3,a4,0x4
    800062cc:	0005d717          	auipc	a4,0x5d
    800062d0:	d3470713          	addi	a4,a4,-716 # 80063000 <disk>
    800062d4:	9736                	add	a4,a4,a3
    800062d6:	0a072423          	sw	zero,168(a4)
    800062da:	b505                	j	800060fa <virtio_disk_rw+0xf4>

00000000800062dc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062dc:	1101                	addi	sp,sp,-32
    800062de:	ec06                	sd	ra,24(sp)
    800062e0:	e822                	sd	s0,16(sp)
    800062e2:	e426                	sd	s1,8(sp)
    800062e4:	e04a                	sd	s2,0(sp)
    800062e6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062e8:	0005f517          	auipc	a0,0x5f
    800062ec:	e4050513          	addi	a0,a0,-448 # 80065128 <disk+0x2128>
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	a3e080e7          	jalr	-1474(ra) # 80000d2e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062f8:	10001737          	lui	a4,0x10001
    800062fc:	533c                	lw	a5,96(a4)
    800062fe:	8b8d                	andi	a5,a5,3
    80006300:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006302:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006306:	0005f797          	auipc	a5,0x5f
    8000630a:	cfa78793          	addi	a5,a5,-774 # 80065000 <disk+0x2000>
    8000630e:	6b94                	ld	a3,16(a5)
    80006310:	0207d703          	lhu	a4,32(a5)
    80006314:	0026d783          	lhu	a5,2(a3)
    80006318:	06f70163          	beq	a4,a5,8000637a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000631c:	0005d917          	auipc	s2,0x5d
    80006320:	ce490913          	addi	s2,s2,-796 # 80063000 <disk>
    80006324:	0005f497          	auipc	s1,0x5f
    80006328:	cdc48493          	addi	s1,s1,-804 # 80065000 <disk+0x2000>
    __sync_synchronize();
    8000632c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006330:	6898                	ld	a4,16(s1)
    80006332:	0204d783          	lhu	a5,32(s1)
    80006336:	8b9d                	andi	a5,a5,7
    80006338:	078e                	slli	a5,a5,0x3
    8000633a:	97ba                	add	a5,a5,a4
    8000633c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000633e:	20078713          	addi	a4,a5,512
    80006342:	0712                	slli	a4,a4,0x4
    80006344:	974a                	add	a4,a4,s2
    80006346:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000634a:	e731                	bnez	a4,80006396 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000634c:	20078793          	addi	a5,a5,512
    80006350:	0792                	slli	a5,a5,0x4
    80006352:	97ca                	add	a5,a5,s2
    80006354:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006356:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000635a:	ffffc097          	auipc	ra,0xffffc
    8000635e:	00e080e7          	jalr	14(ra) # 80002368 <wakeup>

    disk.used_idx += 1;
    80006362:	0204d783          	lhu	a5,32(s1)
    80006366:	2785                	addiw	a5,a5,1
    80006368:	17c2                	slli	a5,a5,0x30
    8000636a:	93c1                	srli	a5,a5,0x30
    8000636c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006370:	6898                	ld	a4,16(s1)
    80006372:	00275703          	lhu	a4,2(a4)
    80006376:	faf71be3          	bne	a4,a5,8000632c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000637a:	0005f517          	auipc	a0,0x5f
    8000637e:	dae50513          	addi	a0,a0,-594 # 80065128 <disk+0x2128>
    80006382:	ffffb097          	auipc	ra,0xffffb
    80006386:	a60080e7          	jalr	-1440(ra) # 80000de2 <release>
}
    8000638a:	60e2                	ld	ra,24(sp)
    8000638c:	6442                	ld	s0,16(sp)
    8000638e:	64a2                	ld	s1,8(sp)
    80006390:	6902                	ld	s2,0(sp)
    80006392:	6105                	addi	sp,sp,32
    80006394:	8082                	ret
      panic("virtio_disk_intr status");
    80006396:	00002517          	auipc	a0,0x2
    8000639a:	4ba50513          	addi	a0,a0,1210 # 80008850 <syscalls+0x3b0>
    8000639e:	ffffa097          	auipc	ra,0xffffa
    800063a2:	1a0080e7          	jalr	416(ra) # 8000053e <panic>

00000000800063a6 <cas>:
    800063a6:	100522af          	lr.w	t0,(a0)
    800063aa:	00b29563          	bne	t0,a1,800063b4 <fail>
    800063ae:	18c5252f          	sc.w	a0,a2,(a0)
    800063b2:	8082                	ret

00000000800063b4 <fail>:
    800063b4:	4505                	li	a0,1
    800063b6:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
