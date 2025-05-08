// Exception Handler Module
// This module detects and handles various exceptions in the processor pipeline
// It plays a crucial role in maintaining correct execution order and handling
// system calls, breakpoints, and traps that may occur during out-of-order execution
module exception_handler(
    input clk,                    // System clock
    input rst,                    // Active high reset
    input [31:0] ID_EX_IR,        // Instruction register from ID/EX stage
    input [31:0] PC,              // Program Counter value
    
    output reg [2:0] exception_type,    // Type of exception detected
    output reg [31:0] exception_pc,     // PC value when exception occurred
    output reg exception_active,        // Indicates if an exception is active
    output reg pipeline_flush          // Signal to flush pipeline stages
);

    // Exception handling logic
    always @(posedge clk) begin
        if (rst) begin
            // Reset all exception-related signals
            exception_active <= 0;
            exception_type <= 0;
            exception_pc <= 0;
            pipeline_flush <= 0;
        end else begin
            // Check for exceptions in the instruction
            // These checks are performed in the ID/EX stage to ensure
            // exceptions are caught before out-of-order execution proceeds
            
            if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001000) begin
                // SYSCALL exception (system call)
                // Forces pipeline flush to ensure correct execution order
                exception_type <= 3'b001;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
            end else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001100) begin
                // BREAK exception (breakpoint)
                // Halts execution at the breakpoint
                exception_type <= 3'b010;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
            end else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001101) begin
                // TRAP exception
                // Used for software traps and debugging
                exception_type <= 3'b011;
                exception_active <= 1;
                exception_pc <= PC;
                pipeline_flush <= 1;
            end else begin
                // No exception detected
                // Pipeline continues normal operation
                exception_active <= 0;
                pipeline_flush <= 0;
            end
        end
    end

endmodule 