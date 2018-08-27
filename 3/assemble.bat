asm86 queues.asm m1 db ep
asm86 main.asm m1 db ep
link86 queues.obj, hw3test.obj, main.obj to set1.lnk
loc86 set1.lnk to set2 NOIC AD(SM(CODE(1000H), DATA(400H), STACK(7000H)))
pcdebug -b8