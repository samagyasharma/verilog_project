# verilog_project

We	shall	first	look	at	the	instruc>on	set	architecture	of	a	popular	Reduced	
Instruc,on	Set	Architecture	(RISC)	processor,	viz.	MIPS32.	
– It	is	a	32-bit	processor,	i.e.	can	operate	on	32	bits	of	data	at	a	>me.	
• We	shall	look	at	the	instruc>on	types,	and	how	instruc>ons	are	encoded.	
• Then	we	can	understand	the	process	of	instruc>on	execu>on,	and	the	steps	
involved.	
• We	shall	discuss	the	pipeline	implementa>on	of	the	processor.	
– Only	for	a	small	subset	of	the	instruc>ons	(and	some	simplifying	assumptions).



A	Quick	Look	at	MIPS32	
• MIPS32	registers:	
a) 32,	32-bit	general	purpose	registers	(GPRs),	R0	to	R31.	
• Register	R0	contains	a	constant	0;	cannot	be	wriXen.	
b) A	special-purpose	32-bit	program	counter	(PC).	
• Points	to	the	next	instruc>on	in	memory	to	be	fetched	and	executed.	
• No	flag	registers	(zero,	carry,	sign,	etc.).	
• Very	few	addressing	modes	(register,	immediate,	register	indexed,	etc.)	
– Only	load	and	store	instruc>ons	can	access	memory.	
• We	assume	memory	word	size	is	32	bits	(word	addressable).


The	MIPS32	Instruc)on	Subset	Being	Considered	
• Load	and	Store	Instruc>ons	
LW R2,124(R8) // R2 = Mem[R8+124] 
SW R5,-10(R25) // Mem[R25-10] = R5 
• Arithme>c	and	Logic	Instruc>ons	(only	register	operands)	
ADD R1,R2,R3 // R1 = R2 + R3 
ADD R1,R2,R0 // R1 = R2 + 0 
SUB R12,R10,R8 // R12 = R10 – R8 
AND R20,R1,R5 // R20 = R1 & R5 
OR R11,R5,R6 // R11 = R5 | R6 
MUL R5,R6,R7 // R5 = R6 * R7
• Arithme>c	and	Logic	Instruc>ons	(immediate	operand)	
ADDI R1,R2,25 // R1 = R2 + 25 
SUBI R5,R1,150 // R5 = R1 – 150 
SLTI R2,R10,10 // If R10<10, R2=1; else R2=0 
• Branch	Instruc>ons	
BEQZ R1,Loop // Branch to Loop if R1=0 
BNEQZ R5,Label // Branch to Label if R5!=0 
• Jump	Instruc>on	
J Loop // Branch to Loop unconditionally 
• Miscellaneous	Instruc>on	
HLT // Halt execution


Addressing	Modes	in	MIPS32	
• Register	addressing ADD R1,R2,R3	
• Immediate	addressing ADDI R1,R2,	200	
• Base	addressing LW R5,	150(R7)	
– Content	of	a	register	is	added	to	a	“base”	value	to	get	the	operand	address.	
• PC	rela>ve	addressing BEQZ R3,	Label	
– 16-bit	offset	is	added	to	PC	to	get	the	target	address.	
• Pseudo-direct	addressing J Label	
– 26-bit	offset	is	added	to	PC	to	get	the	target	address.	


MIPS32	Instruc)on	Cycle	
• We	divide	the	instruc>on	execu>on	cycle	into	five	steps:	
a) IF	 :	Instruc>on	Fetch	
b) ID	 :	Instruc>on	Decode	/	Register	Fetch	
c) EX	 :	Execu>on	/	Effec>ve	Address	Calcula>on	
d) MEM	 :	Memory	Access	/	Branch	Comple>on	
e) WB	 :	Register	Write-back	
• We	now	show	the	generic	micro-instruc>ons	carries	out	in	the	
various	steps.


• Basic	requirements	for	pipelining	the	MIPS32	data	path:	
– We	should	be	able	to	start	a	new	instruc>on	every	clock	cycle.	
– Each	of	the	five	steps	men>oned	before	(IF,	ID,	EX,	MEM	and	WB)	
becomes	a	pipeline	stage.	
– Each	stage	must	finish	its	execu>on	within	one	clock	cycle.	



Micro-opera)ons	for	Pipelined	MIPS32	
• Conven>on	used:	
– Most	of	the	temporary	registers	required	in	the	data	path	are	included	as	part	of	
the	inter-stage	latches.	
– IF_ID:	denotes	the	latch	stage	between	the	IF	and	ID	stages.	
– ID_EX:	denotes	the	latch	stage	between	the	ID	and	EX	stages.	
– EX_MEM:	denotes	the	latch	stage	between	the	EX	and	MEM	stages.	
– MEM_WB:	denotes	the	latch	stage	between	the	MEM	and	WB	stages.	
• Example:	
– ID_EX_A	means	register	A	that	is	implemented	as	part	of	the	ID_EX	latch	stage

