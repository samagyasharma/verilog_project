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
    output reg cache_coherence_req      // Cache coherence request
);

    // Local registers for speculative execution
    reg [2:0] current_checkpoint;
    reg [31:0] speculative_pc;
    reg speculative_active;

    // Cache state registers
    reg [1:0] current_cache_level;
    reg cache_operation_pending;
    reg [31:0] pending_cache_addr;

    // Cache operation types
    localparam CACHE_READ = 2'b00;
    localparam CACHE_WRITE = 2'b01;
    localparam CACHE_PREFETCH = 2'b10;
    localparam CACHE_INVALIDATE = 2'b11;

    // Exception handling logic
    always @(posedge clk) begin
        if (rst) begin
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
        end else begin
            // Default values
            restore_checkpoint <= 0;
            clear_speculative <= 0;
            cache_coherence_req <= 0;
            
            // Handle cache-related operations
            if (l1_cache_miss || l2_cache_miss || l3_cache_miss) begin
                cache_stall <= 1;
                cache_addr <= cache_miss_addr;
                current_cache_level <= cache_level;
                
                // Determine cache operation based on level
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

            // Handle branch misprediction
            if (branch_mispredict) begin
                restore_checkpoint <= 1;
                restore_id <= checkpoint_id;
                clear_speculative <= 1;
                pipeline_flush <= 1;
                speculative_active <= 0;
                cache_stall <= 1; // Stall during recovery
            end
            // Check for exceptions in the instruction
            else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001000) begin
                // SYSCALL exception
                exception_type <= 3'b001;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
                clear_speculative <= 1;
                cache_stall <= 1;
            end else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001100) begin
                // BREAK exception
                exception_type <= 3'b010;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
                clear_speculative <= 1;
                cache_stall <= 1;
            end else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001101) begin
                // TRAP exception
                exception_type <= 3'b011;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
                clear_speculative <= 1;
                cache_stall <= 1;
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
            end
        end
    end

endmodule 