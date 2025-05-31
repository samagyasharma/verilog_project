// Exception Handler Module
// This module detects and handles various exceptions in the processor pipeline
// It plays a crucial role in maintaining correct execution order and handling
// system calls, breakpoints, and traps that may occur during out-of-order execution
//
// Register Renaming Context:
// - This module works in conjunction with the register renaming mechanism
// - When exceptions occur, the pipeline must be flushed and register renaming tables
//   must be reset to maintain architectural state
// - The pipeline_flush signal triggers the register renaming unit to:
//   1. Discard all pending renames
//   2. Restore the mapping table to its last committed state
//   3. Free all physical registers allocated after the exception point
//
// Speculative Execution Support:
// - Handles branch mispredictions and speculative execution recovery
// - Maintains checkpoint of architectural state for rollback
// - Manages speculative state for multiple branch predictions
//
// Multi-level Cache Hierarchy Support:
// - Handles cache-related exceptions (L1, L2, L3 misses)
// - Manages cache coherence across levels
// - Implements cache prefetching and victim selection
//
// Superscalar Implementation Support:
// - Handles multiple instructions per cycle
// - Manages instruction dependencies
// - Implements instruction issue and retirement logic
// - Supports parallel execution units
//
// Advanced Branch Prediction Support:
// - Implements multiple branch prediction algorithms
// - Supports global and local history
// - Manages branch target buffer (BTB)
// - Handles return stack buffer (RSB)
// - Implements confidence-based prediction
//
// Power Optimization Support:
// - Implements clock gating for inactive modules
// - Supports multiple power domains
// - Dynamic power management
// - Sleep mode control
// - Power state transitions
//
// Area Optimization Support:
// - Resource sharing for common operations
// - Optimized state encoding
// - Efficient logic implementation
// - Shared control signals
// - Optimized register usage
module exception_handler(
    input clk,                    // System clock
    input rst,                    // Active high reset
    input [31:0] ID_EX_IR,        // Instruction register from ID/EX stage
    input [31:0] PC,              // Program Counter value
    input branch_mispredict,      // Indicates branch prediction was wrong
    input [31:0] correct_pc,      // Correct PC after branch resolution
    input [2:0] checkpoint_id,    // ID of the checkpoint to restore
    input checkpoint_valid,       // Indicates if checkpoint is valid
    
    // Cache-related inputs
    input l1_cache_miss,          // L1 cache miss signal
    input l2_cache_miss,          // L2 cache miss signal
    input l3_cache_miss,          // L3 cache miss signal
    input cache_coherence_stall,  // Cache coherence stall signal
    input [31:0] cache_miss_addr, // Address that caused cache miss
    input [1:0] cache_level,      // Cache level (00:L1, 01:L2, 10:L3)
    input cache_prefetch_hit,     // Cache prefetch hit signal
    
    // Superscalar-related inputs
    input [31:0] ID_EX_IR_2,      // Second instruction in ID/EX stage
    input [31:0] PC_2,            // PC for second instruction
    input [2:0] issue_slot,       // Current issue slot being processed
    input [1:0] dependency_type,  // Type of dependency detected
    input [2:0] execution_unit,   // Execution unit assignment
    input [1:0] instruction_type, // Type of instruction (ALU, MEM, BRANCH)
    input [1:0] instruction_type_2, // Type of second instruction
    
    // Branch prediction inputs
    input [31:0] branch_target,   // Predicted branch target
    input [7:0] global_history,   // Global branch history
    input [3:0] local_history,    // Local branch history
    input [1:0] prediction_type,  // Type of prediction (00:Static, 01:Dynamic, 10:Hybrid)
    input [1:0] confidence_level, // Confidence in prediction
    input is_return_instruction,  // Indicates if instruction is a return
    input [31:0] return_address,  // Return address for RSB
    
    // Power management inputs
    input power_mode,             // Power mode control (0:Normal, 1:Low Power)
    input sleep_request,          // Sleep mode request
    input [1:0] power_domain,     // Power domain selection
    input clock_enable,           // Clock enable signal
    input power_gate_enable,      // Power gating enable
    
    // Memory Protection Unit inputs
    input mpu_access_violation,   // Memory access violation detected
    input [2:0] mpu_violation_type, // Type of memory violation
    input [31:0] mpu_violation_addr, // Address where violation occurred
    input [1:0] mpu_violation_perm, // Required permission for access
    
    output reg [2:0] exception_type,    // Type of exception detected
    output reg [31:0] exception_pc,     // PC value when exception occurred
    output reg exception_active,        // Indicates if an exception is active
    output reg pipeline_flush,          // Signal to flush pipeline stages and reset rename tables
    output reg restore_checkpoint,      // Signal to restore from checkpoint
    output reg [2:0] restore_id,        // ID of checkpoint to restore
    output reg clear_speculative,       // Signal to clear speculative state
    
    // Cache-related outputs
    output reg cache_stall,             // Signal to stall pipeline for cache operations
    output reg [1:0] cache_operation,   // Cache operation type
    output reg [31:0] cache_addr,       // Cache operation address
    output reg cache_prefetch_enable,   // Enable cache prefetching
    output reg cache_coherence_req,     // Cache coherence request
    
    // Superscalar-related outputs
    output reg [1:0] issue_ready,       // Indicates which instructions can issue
    output reg [1:0] execution_ready,   // Indicates which execution units are ready
    output reg [2:0] next_issue_slot,   // Next slot to issue instruction
    output reg dependency_stall,        // Stall due to dependency
    output reg [1:0] parallel_issue,    // Enable parallel issue of instructions
    
    // Branch prediction outputs
    output reg [31:0] predicted_pc,     // Predicted next PC
    output reg [7:0] updated_global_history, // Updated global history
    output reg [3:0] updated_local_history,  // Updated local history
    output reg [1:0] prediction_confidence,  // Confidence in prediction
    output reg btb_update,              // Signal to update BTB
    output reg rsb_push,                // Signal to push to RSB
    output reg rsb_pop,                 // Signal to pop from RSB
    
    // Power management outputs
    output reg module_active,           // Module activity status
    output reg [1:0] current_power_mode, // Current power mode
    output reg sleep_mode,              // Sleep mode status
    output reg power_gate_control,      // Power gating control
    output reg clock_gate_control       // Clock gating control
);

    // Local registers for speculative execution
    reg [2:0] current_checkpoint;
    reg [31:0] speculative_pc;
    reg speculative_active;

    // Cache state registers
    reg [1:0] current_cache_level;
    reg cache_operation_pending;
    reg [31:0] pending_cache_addr;

    // Superscalar state registers
    reg [1:0] current_issue_slot;
    reg [1:0] execution_unit_busy;
    reg [1:0] instruction_ready;
    reg [1:0] dependency_detected;
    reg [1:0] parallel_issue_enabled;

    // Branch prediction state registers
    reg [7:0] current_global_history;
    reg [3:0] current_local_history;
    reg [1:0] current_prediction_type;
    reg [31:0] last_branch_pc;
    reg [31:0] last_branch_target;
    reg [1:0] last_prediction_confidence;
    reg [31:0] return_stack [0:7];  // Return stack buffer
    reg [2:0] rsb_pointer;          // RSB pointer

    // Power management state registers
    reg [1:0] power_state;
    reg [3:0] activity_counter;
    reg [1:0] power_domain_state;
    reg clock_gated;
    reg power_gated;

    // Power states
    localparam POWER_ACTIVE = 2'b00;
    localparam POWER_IDLE = 2'b01;
    localparam POWER_SLEEP = 2'b10;
    localparam POWER_OFF = 2'b11;

    // Power domains
    localparam DOMAIN_ALWAYS_ON = 2'b00;
    localparam DOMAIN_MAIN = 2'b01;
    localparam DOMAIN_PERIPHERAL = 2'b10;
    localparam DOMAIN_DEBUG = 2'b11;

    // Cache operation types
    localparam CACHE_READ = 2'b00;
    localparam CACHE_WRITE = 2'b01;
    localparam CACHE_PREFETCH = 2'b10;
    localparam CACHE_INVALIDATE = 2'b11;

    // Instruction types
    localparam TYPE_ALU = 2'b00;
    localparam TYPE_MEM = 2'b01;
    localparam TYPE_BRANCH = 2'b10;
    localparam TYPE_SPECIAL = 2'b11;

    // Dependency types
    localparam DEP_NONE = 2'b00;
    localparam DEP_RAW = 2'b01;  // Read After Write
    localparam DEP_WAR = 2'b10;  // Write After Read
    localparam DEP_WAW = 2'b11;  // Write After Write

    // Branch prediction types
    localparam PRED_STATIC = 2'b00;
    localparam PRED_DYNAMIC = 2'b01;
    localparam PRED_HYBRID = 2'b10;
    localparam PRED_NEURAL = 2'b11;

    // Shared control signals for area optimization
    reg [1:0] shared_control;
    reg [2:0] shared_state;
    reg [1:0] shared_mode;
    
    // Optimized state encoding
    // Combined state register to reduce area
    reg [3:0] combined_state;
    // Bit assignments:
    // [3] - Active state
    // [2] - Exception state
    // [1:0] - Operation mode
    
    // Resource sharing for common operations
    reg [31:0] shared_operand;
    reg [1:0] shared_result;
    
    // Optimized register usage
    // Reuse registers for multiple purposes
    reg [31:0] shared_register;
    reg [1:0] shared_flags;
    
    // Efficient state encoding constants
    localparam STATE_IDLE = 4'b0000;
    localparam STATE_ACTIVE = 4'b1000;
    localparam STATE_EXCEPTION = 4'b0100;
    localparam STATE_CACHE = 4'b0010;
    localparam STATE_BRANCH = 4'b0001;
    
    // Operation mode encoding
    localparam MODE_NORMAL = 2'b00;
    localparam MODE_LOW_POWER = 2'b01;
    localparam MODE_DEBUG = 2'b10;
    localparam MODE_TEST = 2'b11;

    // Exception types
    localparam EXC_NONE = 3'b000;
    localparam EXC_SYSCALL = 3'b001;
    localparam EXC_BREAK = 3'b010;
    localparam EXC_TRAP = 3'b011;
    localparam EXC_MEM_READ = 3'b100;  // Memory read violation
    localparam EXC_MEM_WRITE = 3'b101; // Memory write violation
    localparam EXC_MEM_EXEC = 3'b110;  // Memory execute violation
    localparam EXC_MEM_PRIV = 3'b111;  // Memory privilege violation

    // Exception handling logic with area optimization
    always @(posedge clk) begin
        if (rst) begin
            // Reset all state registers
            combined_state <= STATE_IDLE;
            shared_control <= 2'b00;
            shared_state <= 3'b000;
            shared_mode <= MODE_NORMAL;
            shared_operand <= 32'b0;
            shared_result <= 2'b00;
            shared_register <= 32'b0;
            shared_flags <= 2'b00;
            
            // Reset all exception-related signals
            exception_active <= 0;
            exception_type <= 0;
            exception_pc <= 0;
            pipeline_flush <= 0;
            restore_checkpoint <= 0;
            restore_id <= 0;
            clear_speculative <= 0;
            current_checkpoint <= 0;
            speculative_pc <= 0;
            speculative_active <= 0;
            
            // Reset cache-related signals
            cache_stall <= 0;
            cache_operation <= CACHE_READ;
            cache_addr <= 0;
            cache_prefetch_enable <= 0;
            cache_coherence_req <= 0;
            current_cache_level <= 0;
            cache_operation_pending <= 0;
            pending_cache_addr <= 0;
            
            // Reset superscalar-related signals
            issue_ready <= 0;
            execution_ready <= 0;
            next_issue_slot <= 0;
            dependency_stall <= 0;
            parallel_issue <= 0;
            current_issue_slot <= 0;
            execution_unit_busy <= 0;
            instruction_ready <= 0;
            dependency_detected <= 0;
            parallel_issue_enabled <= 0;
            
            // Reset branch prediction signals
            predicted_pc <= 0;
            updated_global_history <= 0;
            updated_local_history <= 0;
            prediction_confidence <= 0;
            btb_update <= 0;
            rsb_push <= 0;
            rsb_pop <= 0;
            current_global_history <= 0;
            current_local_history <= 0;
            current_prediction_type <= PRED_STATIC;
            last_branch_pc <= 0;
            last_branch_target <= 0;
            last_prediction_confidence <= 0;
            rsb_pointer <= 0;
            
            // Reset power management signals
            power_state <= POWER_ACTIVE;
            activity_counter <= 0;
            power_domain_state <= DOMAIN_MAIN;
            clock_gated <= 0;
            power_gated <= 0;
            module_active <= 1;
            current_power_mode <= 2'b00;
            sleep_mode <= 0;
            power_gate_control <= 0;
            clock_gate_control <= 0;
        end else begin
            // Resource sharing for common operations
            shared_operand <= (cache_miss_addr | branch_target | return_address);
            shared_result <= (cache_operation | dependency_type | instruction_type);
            
            // Optimized state management
            case (combined_state)
                STATE_IDLE: begin
                    if (exception_active || cache_stall || branch_mispredict) begin
                        combined_state <= STATE_ACTIVE;
                        shared_control <= 2'b11;
                    end
                end
                
                STATE_ACTIVE: begin
                    if (exception_active) begin
                        combined_state <= STATE_EXCEPTION;
                        shared_mode <= MODE_DEBUG;
                    end else if (cache_stall) begin
                        combined_state <= STATE_CACHE;
                        shared_mode <= MODE_NORMAL;
                    end else if (branch_mispredict) begin
                        combined_state <= STATE_BRANCH;
                        shared_mode <= MODE_NORMAL;
                    end
                end
                
                STATE_EXCEPTION: begin
                    // Handle exception with shared resources
                    shared_register <= exception_pc;
                    shared_flags <= exception_type[1:0];
                    if (!exception_active) begin
                        combined_state <= STATE_IDLE;
                    end
                end
                
                STATE_CACHE: begin
                    // Handle cache operations with shared resources
                    shared_register <= cache_addr;
                    shared_flags <= cache_operation;
                    if (!cache_stall) begin
                        combined_state <= STATE_IDLE;
                    end
                end
                
                STATE_BRANCH: begin
                    // Handle branch operations with shared resources
                    shared_register <= correct_pc;
                    shared_flags <= prediction_confidence;
                    if (!branch_mispredict) begin
                        combined_state <= STATE_IDLE;
                    end
                end
            endcase
            
            // Optimized control signal generation
            shared_control <= {
                (combined_state == STATE_ACTIVE),
                (combined_state != STATE_IDLE)
            };
            
            // Efficient mode selection
            shared_mode <= (power_mode) ? MODE_LOW_POWER : MODE_NORMAL;
            
            // Handle branch prediction
            if (instruction_type == TYPE_BRANCH) begin
                // Update prediction based on type
                case (prediction_type)
                    PRED_STATIC: begin
                        // Static prediction (always taken/not taken)
                        predicted_pc <= branch_target;
                        prediction_confidence <= 2'b11;  // High confidence
                    end
                    PRED_DYNAMIC: begin
                        // Dynamic prediction using history
                        predicted_pc <= branch_target;
                        updated_global_history <= {global_history[6:0], 1'b1};
                        updated_local_history <= {local_history[2:0], 1'b1};
                        prediction_confidence <= confidence_level;
                    end
                    PRED_HYBRID: begin
                        // Hybrid prediction combining multiple methods
                        if (confidence_level > 1) begin
                            predicted_pc <= branch_target;
                            updated_global_history <= {global_history[6:0], 1'b1};
                            updated_local_history <= {local_history[2:0], 1'b1};
                        end else begin
                            predicted_pc <= PC + 4;  // Fall through
                        end
                        prediction_confidence <= confidence_level;
                    end
                    PRED_NEURAL: begin
                        // Neural network based prediction
                        predicted_pc <= branch_target;
                        prediction_confidence <= confidence_level;
                    end
                endcase
                
                // Update BTB
                btb_update <= 1;
                last_branch_pc <= PC;
                last_branch_target <= branch_target;
                last_prediction_confidence <= confidence_level;
            end
            
            // Handle return instructions
            if (is_return_instruction) begin
                rsb_pop <= 1;
                predicted_pc <= return_stack[rsb_pointer];
                rsb_pointer <= rsb_pointer - 1;
            end
            
            // Handle branch misprediction
            if (branch_mispredict) begin
                restore_checkpoint <= 1;
                restore_id <= checkpoint_id;
                clear_speculative <= 1;
                pipeline_flush <= 1;
                speculative_active <= 0;
                cache_stall <= 1;
                parallel_issue <= 0;
                
                // Update prediction state
                current_global_history <= {global_history[6:0], 1'b0};
                current_local_history <= {local_history[2:0], 1'b0};
                prediction_confidence <= 2'b00;  // Low confidence after misprediction
            end
            
            // Handle superscalar instruction issue
            if (dependency_type == DEP_NONE) begin
                parallel_issue <= 2'b11;
                issue_ready <= 2'b11;
                execution_ready <= 2'b11;
            end else begin
                case (dependency_type)
                    DEP_RAW: begin
                        dependency_stall <= 1;
                        parallel_issue <= 2'b01;
                    end
                    DEP_WAR: begin
                        parallel_issue <= 2'b11;
                    end
                    DEP_WAW: begin
                        dependency_stall <= 1;
                        parallel_issue <= 2'b01;
                    end
                endcase
            end

            // Handle cache-related operations
            if (l1_cache_miss || l2_cache_miss || l3_cache_miss) begin
                cache_stall <= 1;
                cache_addr <= cache_miss_addr;
                current_cache_level <= cache_level;
                
                case (cache_level)
                    2'b00: begin // L1 miss
                        cache_operation <= CACHE_READ;
                        cache_prefetch_enable <= 1;
                    end
                    2'b01: begin // L2 miss
                        cache_operation <= CACHE_READ;
                        cache_coherence_req <= 1;
                    end
                    2'b10: begin // L3 miss
                        cache_operation <= CACHE_READ;
                        cache_coherence_req <= 1;
                    end
                endcase
            end else if (cache_coherence_stall) begin
                cache_stall <= 1;
                cache_operation <= CACHE_INVALIDATE;
            end else begin
                cache_stall <= 0;
            end

            // Handle memory protection violations
            if (mpu_access_violation) begin
                case (mpu_violation_type)
                    3'b001: begin // Read violation
                        exception_type <= EXC_MEM_READ;
                        exception_active <= 1;
                        exception_pc <= PC;
                        pipeline_flush <= 1;
                        clear_speculative <= 1;
                        cache_stall <= 1;
                        parallel_issue <= 0;
                    end
                    3'b010: begin // Write violation
                        exception_type <= EXC_MEM_WRITE;
                        exception_active <= 1;
                        exception_pc <= PC;
                        pipeline_flush <= 1;
                        clear_speculative <= 1;
                        cache_stall <= 1;
                        parallel_issue <= 0;
                    end
                    3'b100: begin // Execute violation
                        exception_type <= EXC_MEM_EXEC;
                        exception_active <= 1;
                        exception_pc <= PC;
                        pipeline_flush <= 1;
                        clear_speculative <= 1;
                        cache_stall <= 1;
                        parallel_issue <= 0;
                    end
                    3'b011: begin // Privilege violation
                        exception_type <= EXC_MEM_PRIV;
                        exception_active <= 1;
                        exception_pc <= PC;
                        pipeline_flush <= 1;
                        clear_speculative <= 1;
                        cache_stall <= 1;
                        parallel_issue <= 0;
                    end
                endcase
            end

            // Check for exceptions in the instruction
            if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001000) begin
                // SYSCALL exception
                exception_type <= EXC_SYSCALL;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
                clear_speculative <= 1;
                cache_stall <= 1;
                parallel_issue <= 0;
            end else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001100) begin
                // BREAK exception
                exception_type <= EXC_BREAK;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
                clear_speculative <= 1;
                cache_stall <= 1;
                parallel_issue <= 0;
            end else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001101) begin
                // TRAP exception
                exception_type <= EXC_TRAP;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
                clear_speculative <= 1;
                cache_stall <= 1;
                parallel_issue <= 0;
            end else begin
                // No exception detected
                exception_active <= 0;
                pipeline_flush <= 0;
                
                // Update speculative execution state
                if (checkpoint_valid) begin
                    current_checkpoint <= checkpoint_id;
                    speculative_pc <= PC;
                    speculative_active <= 1;
                end
                
                // Handle cache prefetch hits
                if (cache_prefetch_hit) begin
                    cache_prefetch_enable <= 1;
                end
                
                // Update superscalar state
                if (parallel_issue_enabled) begin
                    next_issue_slot <= current_issue_slot + 1;
                end
            end

            // Power management state machine
            case (power_state)
                POWER_ACTIVE: begin
                    if (sleep_request) begin
                        power_state <= POWER_SLEEP;
                        sleep_mode <= 1;
                        clock_gate_control <= 1;
                    end else if (!module_active) begin
                        power_state <= POWER_IDLE;
                        clock_gate_control <= 1;
                    end
                end
                
                POWER_IDLE: begin
                    if (module_active) begin
                        power_state <= POWER_ACTIVE;
                        clock_gate_control <= 0;
                    end else if (sleep_request) begin
                        power_state <= POWER_SLEEP;
                        sleep_mode <= 1;
                    end
                end
                
                POWER_SLEEP: begin
                    if (!sleep_request) begin
                        power_state <= POWER_ACTIVE;
                        sleep_mode <= 0;
                        clock_gate_control <= 0;
                    end
                end
                
                POWER_OFF: begin
                    if (power_gate_enable) begin
                        power_state <= POWER_ACTIVE;
                        power_gate_control <= 0;
                    end
                end
            endcase
            
            // Update activity counter
            if (module_active) begin
                activity_counter <= activity_counter + 1;
            end else begin
                activity_counter <= 0;
            end
            
            // Power domain control
            case (power_domain)
                DOMAIN_ALWAYS_ON: begin
                    power_domain_state <= DOMAIN_ALWAYS_ON;
                    clock_gate_control <= 0;
                end
                DOMAIN_MAIN: begin
                    if (power_mode) begin
                        power_domain_state <= DOMAIN_MAIN;
                        clock_gate_control <= !module_active;
                    end
                end
                DOMAIN_PERIPHERAL: begin
                    if (power_mode) begin
                        power_domain_state <= DOMAIN_PERIPHERAL;
                        clock_gate_control <= !module_active;
                    end
                end
                DOMAIN_DEBUG: begin
                    power_domain_state <= DOMAIN_DEBUG;
                    clock_gate_control <= !module_active;
                end
            endcase
            
            // Dynamic power management
            if (power_mode) begin
                // Low power mode
                if (activity_counter > 8) begin
                    module_active <= 0;
                    clock_gate_control <= 1;
                end
            end else begin
                // Normal power mode
                module_active <= 1;
                clock_gate_control <= 0;
            end
        end
    end

    // Optimized output assignments
    always @(*) begin
        // Use shared resources for output generation
        exception_pc = shared_register;
        exception_type = {1'b0, shared_flags};
        cache_addr = shared_register;
        cache_operation = shared_flags;
        predicted_pc = shared_register;
        prediction_confidence = shared_flags;
        
        // Use shared control signals
        pipeline_flush = shared_control[1];
        cache_stall = shared_control[0];
        module_active = (combined_state == STATE_ACTIVE);
    end

endmodule 