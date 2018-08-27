asm86 converts.asm m1 db ep
asm86 hw2test.asm m1 db ep
link86 converts.obj, hw2test.obj to set1.lnk
loc86 set1.lnk to set2 NOIC AD(SM(CODE(1000H), DATA(400H), STACK(7000H)))
pcdebug -b8