# verilog_project

**MIPS32** is a	popular	**Reduced	Instruction	Set	Architecture**	(RISC)	processor.
– It	is	a	32-bit	processor,	i.e.	can	operate	on	32	bits	of	data	at	a	time.	
I have done the pipeline	implementation	of	the	processor.	
– Only	for	a	small	subset	of	the	instructions	(and	some	simplifying	assumptions).



**A	Quick	Look	at	MIPS32**	
• MIPS32	registers:	
a) 32,	32-bit	general	purpose	registers	(GPRs),	R0	to	R31.	
• Register	R0	contains	a	constant	0;	cannot	be	written.	
b) A	special-purpose	32-bit	program	counter	(PC).	
• Points	to	the	next	instruction	in	memory	to	be	fetched	and	executed.	
• No	flag	registers	(zero,	carry,	sign,	etc.).	
• Very	few	addressing	modes	(register,	immediate,	register	indexed,	etc.)	
– Only	load	and	store	instructions	can	access	memory.	
• We	assume	memory	word	size	is	32	bits	(word	addressable).


**The	MIPS32	Instruction	Subset	Being	Considered** :-
• Load	and	Store	Instructions	
LW R2,124(R8) // R2 = Mem[R8+124] 
SW R5,-10(R25) // Mem[R25-10] = R5 
• Arithmetic	and	Logic	Instructions	(only	register	operands)	
ADD R1,R2,R3 // R1 = R2 + R3 
ADD R1,R2,R0 // R1 = R2 + 0 
SUB R12,R10,R8 // R12 = R10 – R8 
AND R20,R1,R5 // R20 = R1 & R5 
OR R11,R5,R6 // R11 = R5 | R6 
MUL R5,R6,R7 // R5 = R6 * R7
• Arithmetic	and	Logic	Instructions	(immediate	operand)	
ADDI R1,R2,25 // R1 = R2 + 25 
SUBI R5,R1,150 // R5 = R1 – 150 
SLTI R2,R10,10 // If R10<10, R2=1; else R2=0 
• Branch	Instructions	
BEQZ R1,Loop // Branch to Loop if R1=0 
BNEQZ R5,Label // Branch to Label if R5!=0 
• Jump	Instruction	
J Loop // Branch to Loop unconditionally 
• Miscellaneous	Instruction	
HLT // Halt execution


**Addressing	Modes**	in	MIPS32	
• Register	addressing ADD R1,R2,R3	
• Immediate	addressing ADDI R1,R2,	200	
• Base	addressing LW R5,	150(R7)	
– Content	of	a	register	is	added	to	a	“base”	value	to	get	the	operand	address.	
• PC	relative	addressing BEQZ R3,	Label	
– 16-bit	offset	is	added	to	PC	to	get	the	target	address.	
• Pseudo-direct	addressing J Label	
– 26-bit	offset	is	added	to	PC	to	get	the	target	address.	


**MIPS32	Instruction	Cycle**	
• We	divide	the	instruction	execution	cycle	into	five	steps:	
a) IF	 :	Instruction	Fetch	
b) ID	 :	Instruction	Decode	/	Register	Fetch	
c) EX	 :	Execution	/	Effective	Address	Calculation	
d) MEM	 :	Memory	Access	/	Branch	Completion	
e) WB	 :	Register	Write-back	
• We	now	show	the	generic	micro-instructions	carries	out	in	the	
various	steps.


• **Basic	requirements**	for	pipelining	the	MIPS32	data	path:	
– We	should	be	able	to	start	a	new	instruction	every	clock	cycle.	
– Each	of	the	five	steps	mentioned	before	(IF,	ID,	EX,	MEM	and	WB)	
becomes	a	pipeline	stage.	
– Each	stage	must	finish	its	execution	within	one	clock	cycle.	



**Micro-operations**	for	Pipelined	MIPS32	
• **Convention	used**:	
– Most	of	the	temporary	registers	required	in	the	data	path	are	included	as	part	of	
the	inter-stage	latches.	
– IF_ID:	denotes	the	latch	stage	between	the	IF	and	ID	stages.	
– ID_EX:	denotes	the	latch	stage	between	the	ID	and	EX	stages.	
– EX_MEM:	denotes	the	latch	stage	between	the	EX	and	MEM	stages.	
– MEM_WB:	denotes	the	latch	stage	between	the	MEM	and	WB	stages.	
• Example:	
– ID_EX_A	means	register	A	that	is	implemented	as	part	of	the	ID_EX	latch	stage

