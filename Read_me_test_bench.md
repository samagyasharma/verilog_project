Example 1
• Add	three	numbers	10,	20	and	30	stored	in	processor	registers.	
• The	steps:	
– Initialize	register	R1	with	10.	
– Initialize	register	R2	with	20.	
– Initialize	register	R3	with	30.	
– Add	the	three	numbers	and	store	the	sum	in	R4.	



Example	2	
• Load	a	word	stored	in	memory	location	120,	add	45	to	it,	and	store	the	result	
in	memory	location	121.	
• The	steps:	
– Initialize	register	R1	with	the	memory	address	120.	
– Load	the	contents	of	memory	location	120	into	register	R2.	
– Add	45	to	register	R2.	
– Store	the	result	in	memory	location	121.


Example	3	
• Compute	the	factorial	of	a	number	N	stored	in	memory	location	200.	The	
result	will	be	stored	in	memory	location	198.	
• The	steps:	
– Initialize	register	R10	with	the	memory	address	200.	
– Load	the	contents	of	memory	location	200	into	register	R3.	
– Initialize	register	R2	with	the	value	1.	
– In	a	loop,	multiply	R2	and	R3,	and	store	the	product	in	R2.	
– Decrement	R3	by	1;	if	not	zero	repeat	the	loop.	
– Store	the	result	(from	R3)	in	memory	location	198.
