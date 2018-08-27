asm86 main.asm m1 db ep
asm86 converts.asm m1 db ep
asm86 segtable.asm m1 db ep
asm86 timer2dk.asm m1 db ep
asm86 initcs.asm m1 db ep
asm86 ntrrpt.asm m1 db ep
asm86 display.asm m1 db ep
asm86 keypad.asm m1 db ep
asm86chk main.asm
asm86chk converts.asm 
asm86chk segtable.asm 
asm86chk timer2dk.asm 
asm86chk initcs.asm 
asm86chk ntrrpt.asm 
asm86chk display.asm 
asm86chk keypad.asm 

link86 main.obj, converts.obj, segtable.obj, timer2dk.obj, initcs.obj, ntrrpt.obj, display.obj, hw54test.obj, keypad.obj
loc86 main.lnk to set2 NOIC AD(SM(CODE(4000H), DATA(400H), STACK(7000H)))
