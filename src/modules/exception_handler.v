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
module exception_handler(
    input clk,                    // System clock
    input rst,                    // Active high reset
    input [31:0] ID_EX_IR,        // Instruction register from ID/EX stage
    input [31:0] PC,              // Program Counter value
    input branch_mispredict,      // Indicates branch prediction was wrong
    input [31:0] correct_pc,      // Correct PC after branch resolution
    input [2:0] checkpoint_id,    // ID of the checkpoint to restore
    input checkpoint_valid,       // Indicates if checkpoint is valid
    
    output reg [2:0] exception_type,    // Type of exception detected
    output reg [31:0] exception_pc,     // PC value when exception occurred
    output reg exception_active,        // Indicates if an exception is active
    output reg pipeline_flush,          // Signal to flush pipeline stages and reset rename tables
    output reg restore_checkpoint,      // Signal to restore from checkpoint
    output reg [2:0] restore_id,        // ID of checkpoint to restore
    output reg clear_speculative        // Signal to clear speculative state
);

    // Local registers for speculative execution
    reg [2:0] current_checkpoint;
    reg [31:0] speculative_pc;
    reg speculative_active;

    // Exception handling logic
    always @(posedge clk) begin
        if (rst) begin
            // Reset all exception-related signals
            // This also ensures register renaming tables are cleared
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
        end else begin
            // Default values
            restore_checkpoint <= 0;
            clear_speculative <= 0;
            
            // Handle branch misprediction
            if (branch_mispredict) begin
                // Restore from checkpoint
                restore_checkpoint <= 1;
                restore_id <= checkpoint_id;
                clear_speculative <= 1;
                pipeline_flush <= 1;
                speculative_active <= 0;
            end
            // Check for exceptions in the instruction
            // These checks are performed in the ID/EX stage to ensure
            // exceptions are caught before out-of-order execution proceeds
            // and before register renaming operations are committed
            else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001000) begin
                // SYSCALL exception (system call)
                // Forces pipeline flush to ensure correct execution order
                // and resets register renaming state to maintain architectural consistency
                exception_type <= 3'b001;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
                clear_speculative <= 1;
            end else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001100) begin
                // BREAK exception (breakpoint)
                // Halts execution at the breakpoint
                // Requires register renaming state to be preserved for debugging
                exception_type <= 3'b010;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
                clear_speculative <= 1;
            end else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001101) begin
                // TRAP exception
                // Used for software traps and debugging
                // Similar to breakpoint, preserves register state for analysis
                exception_type <= 3'b011;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
                clear_speculative <= 1;
            end else begin
                // No exception detected
                // Pipeline continues normal operation
                // Register renaming proceeds normally
                exception_active <= 0;
                pipeline_flush <= 0;
                
                // Update speculative execution state
                if (checkpoint_valid) begin
                    current_checkpoint <= checkpoint_id;
                    speculative_pc <= PC;
                    speculative_active <= 1;
                end
            end
        end
    end

endmodule 