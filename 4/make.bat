asm86 main.asm m1 db ep
asm86 converts.asm m1 db ep
asm86 segtable.asm m1 db ep
asm86 timer2d.asm m1 db ep
asm86 initcs.asm m1 db ep
asm86 intrrpt.asm m1 db ep
asm86 display.asm m1 db ep
link86 main.obj, converts.obj, segtable.obj, timer2d.obj, initcs.obj, intrrpt.obj, display.obj, hw4test.obj to set1.lnk
loc86 set1.lnk to set2 NOIC AD(SM(CODE(4000H), DATA(400H), STACK(7000H)))
