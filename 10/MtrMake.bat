:: check each assembly file for typical programming and style errors
asm86chk converts.asm					
asm86chk queues.asm 					
asm86chk serial.asm  
asm86chk parser.asm
asm86chk motor.asm
asm86chk eventq.asm		
asm86chk syserror.asm
asm86chk srialstr.asm
asm86chk ntrrpt.asm	
asm86chk initcs.asm
asm86chk initpp.asm
asm86chk timer2m.asm	
asm86chk int2.asm  
asm86chk trigtbl.asm
asm86chk mtrmain.asm
asm86chk mtrfuncs.asm

:: compiles each assembly code (.asm) to machine code (.obj) using x186 instruction
:: set (m1), including debug code (db) and printing errors (ep)
asm86 converts.asm m1 db ep				
asm86 queues.asm m1 db ep		
asm86 serial.asm m1 db ep    
asm86 parser.asm m1 db ep    
asm86 motor.asm m1 db ep      
asm86 eventq.asm m1 db ep
asm86 syserror.asm m1 db ep
asm86 srialstr.asm m1 db ep
asm86 ntrrpt.asm m1 db ep			
asm86 initcs.asm m1 db ep	
asm86 initpp.asm m1 db ep
asm86 timer2m.asm m1 db ep			
asm86 int2.asm m1 db ep   
asm86 trigtbl.asm m1 db ep       
asm86 mtrmain.asm m1 db ep
asm86 mtrfuncs.asm m1 db ep

:: links maching code (.obj) files together into one lnk (.lnk) file. Generates
:: (.mp1) file containing a link map and error message list along with the link 
:: file
link86 converts.obj, queues.obj, serial.obj, parser.obj, motor.obj, eventq.obj, syserror.obj, srialstr.obj
link86 ntrrpt.obj, initcs.obj, initpp.obj, timer2m.obj, int2.obj, trigtbl.obj, mtrmain.obj, mtrfuncs.obj
link86 converts.lnk, ntrrpt.lnk to hw10file.lnk



:: locates the file and writes the located file to the output file (no extension).
:: Generates (.mp2) file containing symbol name, memory map, and error message 
:: list. Does not generate initialization code (NOIC). Goes to the maximum 
:: capacity of SRAM (64K). Interrupt vector is located [0, 3FF]. Data usually goes
:: and takes less space than code. Can choose places for other segments somewhat
:: arbitrarily, as long as they don't overlap.
loc86 hw10file.lnk to hw10 NOIC AD(SM(CODE(4000H), DATA(400H), STACK(7000H)))