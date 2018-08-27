asm86 main.asm m1 db ep
asm86 trigtbl.asm m1 db ep
asm86 timer2m.asm m1 db ep
asm86 initcs.asm m1 db ep
asm86 initpp.asm m1 db ep
asm86 ntrrpt.asm m1 db ep
asm86 motor.asm m1 db ep
asm86chk main.asm
asm86chk timer2m.asm
asm86chk initcs.asm 
asm86chk initpp.asm 
asm86chk ntrrpt.asm 
asm86chk motor.asm 

link86 main.obj, trigtbl.obj, initcs.obj, initpp.obj, timer2m.obj, ntrrpt.obj, motor.obj, hw6test.obj
loc86 main.lnk to hw6 NOIC AD(SM(CODE(4000H), DATA(400H), STACK(7000H)))