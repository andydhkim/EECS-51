asm86 main.asm m1 db ep
asm86 parser.asm m1 db ep
asm86chk main.asm
asm86chk parser.asm


link86 main.obj, parser.obj, hw8test.obj
loc86 main.lnk to hw8 NOIC AD(SM(CODE(4000H), DATA(400H), STACK(7000H)))

