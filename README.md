# Enhanced MIPS32 Pipeline Implementation

This project implements a sophisticated MIPS32 pipeline processor with advanced features for high-performance computing. The implementation is modular and includes several modern processor features that enhance performance, reliability, and security.

## Project Structure

```
verilog_project/
├── src/
│   ├── modules/
│   │   ├── hazard_detection_unit.v
│   │   ├── forwarding_unit.v
│   │   ├── branch_prediction_unit.v
│   │   ├── cache_interface.v
│   │   ├── performance_monitor.v
│   │   ├── exception_handler.v
│   │   ├── memory_protection_unit.v
│   │   └── power_management_unit.v
│   ├── pipeline.v
│   └── test_bench.v
└── README.md
```

## Key Features

### 1. Pipeline Stages
- Instruction Fetch (IF)
- Instruction Decode (ID)
- Execute (EX)
- Memory Access (MEM)
- Write Back (WB)

### 2. Advanced Features

#### Hazard Detection Unit (`hazard_detection_unit.v`)
- Data Hazards: Detects RAW, WAR, and WAW hazards
- Control Hazards: Handles branch and jump instructions
- Structural Hazards: Manages resource conflicts
- Real-time hazard detection and reporting

#### Forwarding Unit (`forwarding_unit.v`)
- Implements data forwarding to resolve data hazards
- Supports forwarding from EX and MEM stages
- Reduces pipeline stalls
- Optimizes instruction throughput

#### Branch Prediction (`branch_prediction_unit.v`)
- 2-bit saturating counter predictor
- Branch Target Buffer (BTB) for target address prediction
- Branch history register for pattern recognition
- Improves branch prediction accuracy

#### Cache Interface (`cache_interface.v`)
- 256-entry direct-mapped cache
- 32-bit data width
- Write-through policy
- Cache hit/miss monitoring
- Efficient memory access

#### Performance Monitoring (`performance_monitor.v`)
- Cycle count tracking
- Instruction count
- Branch misprediction statistics
- Cache performance metrics
- Real-time performance analysis

#### Exception Handling (`exception_handler.v`)
- System call support
- Break instruction handling
- Trap instruction support
- Exception vector table
- Pipeline flush control
- Memory protection violation handling

#### Memory Protection Unit (`memory_protection_unit.v`)
- **Region-Based Memory Protection**
  - 8 configurable memory regions
  - Flexible region size and base address configuration
  - Granular access control per region
  - Support for overlapping regions

- **Access Control**
  - Read/Write/Execute permissions
  - Privilege level enforcement (User/Supervisor/Machine)
  - Permission combinations (Read-Only, Read-Write, Execute-Only)
  - Supervisor-only regions

- **Memory Regions**
  - Code Region (Read/Execute): 0x00000000 - 0x0000FFFF
  - Data Region (Read/Write): 0x00010000 - 0x0001FFFF
  - Stack Region (Read/Write): 0x7FFFFFFF - 0x7FFFFFFF+FFFF
  - I/O Region (Supervisor): 0x80000000 - 0x8000FFFF
  - 4 Additional Configurable Regions

- **Security Features**
  - Access violation detection
  - Detailed violation reporting
  - Privilege level checking
  - Region boundary enforcement

- **Integration with Exception Handler**
  - Memory access violation exceptions
  - Privilege violation handling
  - Pipeline flush on violations
  - Exception vector support

#### Power Management Unit (`power_management_unit.v`)
- **Power States**
  - Active: Full performance mode
  - Idle: Reduced power consumption
  - Sleep: Minimal power usage
  - Deep Sleep: Ultra-low power mode

- **Power Management Features**
  - Dynamic power state transitions
  - Clock gating control
  - Activity monitoring
  - Power consumption statistics
  - Automatic power state management

- **Power Optimization**
  - Idle detection and management
  - Cache miss power impact tracking
  - Branch misprediction power cost
  - Instruction-based power profiling
  - Real-time power consumption monitoring

- **Integration**
  - Pipeline activity monitoring
  - Cache interface coordination
  - Branch prediction feedback
  - Exception handling integration
  - Performance monitoring interface

## Implementation Details

### Pipeline Control
- Two-phase clock system
- Pipeline stall and flush control
- Hazard detection and resolution
- Forwarding path implementation

### Memory Hierarchy
- Register file (32 registers)
- Cache memory (256 entries)
- Main memory (1024 words)
- Memory Protection Unit with 8 regions:
  - Code region (Read/Execute)
  - Data region (Read/Write)
  - Stack region (Read/Write)
  - I/O region (Supervisor only)
  - 4 additional configurable regions
  - Region-based access control
  - Privilege level enforcement

### Instruction Set
- Arithmetic: ADD, SUB, AND, OR, SLT, MUL
- Immediate: ADDI, SUBI, SLTI
- Memory: LW, SW
- Branch: BNEQZ, BEQZ
- System: SYSCALL, BREAK, TRAP

### Power Management
- Four power states (Active, Idle, Sleep, Deep Sleep)
- Dynamic power state transitions
- Clock gating implementation
- Power consumption tracking
- Activity-based power management

## Testing

The test bench (`test_bench.v`) includes comprehensive tests for:
1. Basic ALU operations with forwarding
2. Load-Use hazard detection
3. Branch prediction accuracy
4. Cache hit/miss scenarios
5. Exception handling
6. Memory protection violations:
   - Read access violations
   - Write access violations
   - Execute access violations
   - Privilege level violations
   - Region boundary violations
   - Permission combination tests
7. Power management features:
   - Power state transitions
   - Clock gating functionality
   - Power consumption tracking
   - Activity monitoring
   - Power optimization effectiveness

## Performance Metrics

The implementation tracks:
- Total execution cycles
- Instructions per cycle (IPC)
- Branch prediction accuracy
- Cache hit rate
- Pipeline efficiency
- Memory protection violations:
  - Access violation counts by type
  - Privilege violation statistics
  - Region access patterns
  - Security event logging
- Power management statistics:
  - Power state distribution
  - Power consumption patterns
  - Clock gating efficiency
  - Power optimization impact
  - Energy efficiency metrics

## Usage

1. Clone the repository:
```bash
git clone https://github.com/samagyasharma/verilog_project.git
cd verilog_project
```

2. Compile the Verilog files:
```bash
iverilog -o pipeline src/modules/*.v src/pipeline.v src/test_bench.v
```

3. Run the simulation:
```bash
vvp pipeline
```

4. View the results:
- Performance metrics are displayed at the end of simulation
- Register values are shown for verification
- Exception events are logged during execution
- Memory protection violations are reported
- Security event statistics are displayed

## Module Descriptions

### Hazard Detection Unit
- Detects data hazards between pipeline stages
- Identifies control hazards from branches
- Manages structural hazards for resource conflicts
- Provides hazard type information for pipeline control

### Forwarding Unit
- Implements data forwarding paths
- Resolves data hazards without stalling
- Supports multiple forwarding sources
- Optimizes pipeline throughput

### Branch Prediction Unit
- Implements 2-bit saturating counter
- Maintains branch history
- Predicts branch outcomes
- Reduces branch penalty

### Cache Interface
- Direct-mapped cache implementation
- Write-through policy
- Cache hit/miss detection
- Performance monitoring

### Performance Monitor
- Tracks execution statistics
- Monitors pipeline efficiency
- Reports performance metrics
- Helps in optimization

### Exception Handler
- System call processing
- Break instruction handling
- Trap instruction support
- Pipeline control during exceptions

### Memory Protection Unit
- **Region Management**
  - Configurable memory regions
  - Region size and base address control
  - Permission bit configuration
  - Region overlap handling

- **Access Control**
  - Permission checking (Read/Write/Execute)
  - Privilege level verification
  - Access violation detection
  - Detailed violation reporting

- **Security Features**
  - Memory access protection
  - Privilege level enforcement
  - Region boundary checking
  - Security event logging

- **Integration**
  - Exception handler interface
  - Pipeline control signals
  - Cache interface coordination
  - Performance monitoring

### Power Management Unit
- Dynamic power state management
- Clock gating control
- Power consumption monitoring
- Activity-based optimization
- Energy efficiency tracking

## Future Improvements

1. Out-of-order execution
2. Register renaming
3. Speculative execution
4. Multi-level cache hierarchy
5. Superscalar implementation
6. Advanced branch prediction
7. Power optimization
8. Area optimization
9. Enhanced memory protection:
   - Virtual memory support
   - Page-level protection
   - Memory encryption
   - Secure boot support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Author

Samagya Sharma



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
– Content	of	a	register	is	added	to	a	"base"	value	to	get	the	operand	address.  	
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


• **Basic	requirements**	for	pipelining	the	MIPS32	data	path:  	
– We	should	be	able	tostart	a	new	instruction	every	clock	cycle.  	
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

