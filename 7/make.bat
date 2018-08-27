asm86 main.asm m1 db ep
asm86 serial.asm m1 db ep
asm86 initcs.asm m1 db ep
asm86 int2.asm m1 db ep
asm86 ntrrpt.asm m1 db ep
asm86 queues.asm m1 db ep
asm86chk main.asm
asm86chk serial.asm
asm86chk initcs.asm 
asm86chk int2.asm 
asm86chk ntrrpt.asm 
asm86chk queues.asm 

link86 main.obj, serial.obj, initcs.obj, int2.obj, ntrrpt.obj, queues.obj, hw7test.obj
loc86 main.lnk to hw7 NOIC AD(SM(CODE(4000H), DATA(400H), STACK(7000H)))