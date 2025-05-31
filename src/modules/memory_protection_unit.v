// Memory Protection Unit (MPU)
// This module implements memory protection and access control features
// - Memory region protection
// - Access permission checking
// - Memory access violation detection
// - Region-based memory management
module memory_protection_unit(
    input clk,                    // System clock
    input rst,                    // Active high reset
    input [31:0] access_addr,     // Memory access address
    input [1:0] access_type,      // Access type (00:Read, 01:Write, 10:Execute)
    input [1:0] privilege_level,  // Current privilege level (00:User, 01:Supervisor, 10:Machine)
    input [31:0] region_base [0:7], // Base addresses for 8 memory regions
    input [31:0] region_size [0:7], // Size of each memory region
    input [2:0] region_perm [0:7], // Access permissions for each region
    
    output reg access_violation,  // Access violation detected
    output reg [2:0] violation_type, // Type of violation
    output reg [31:0] violation_addr, // Address where violation occurred
    output reg [1:0] violation_perm // Required permission for access
);

    // Access types
    localparam ACCESS_READ = 2'b00;
    localparam ACCESS_WRITE = 2'b01;
    localparam ACCESS_EXECUTE = 2'b10;
    
    // Privilege levels
    localparam PRIV_USER = 2'b00;
    localparam PRIV_SUPERVISOR = 2'b01;
    localparam PRIV_MACHINE = 2'b10;
    
    // Permission bits
    localparam PERM_NONE = 3'b000;
    localparam PERM_READ = 3'b001;
    localparam PERM_WRITE = 3'b010;
    localparam PERM_EXECUTE = 3'b100;
    localparam PERM_READ_WRITE = 3'b011;
    localparam PERM_READ_EXECUTE = 3'b101;
    localparam PERM_ALL = 3'b111;
    
    // Region matching and permission checking
    always @(*) begin
        access_violation = 0;
        violation_type = 0;
        violation_addr = 0;
        violation_perm = 0;
        
        // Check each region
        for (int i = 0; i < 8; i++) begin
            // Check if address is in region
            if (access_addr >= region_base[i] && 
                access_addr < (region_base[i] + region_size[i])) begin
                
                // Check permissions based on access type and privilege level
                case (access_type)
                    ACCESS_READ: begin
                        if (!(region_perm[i] & PERM_READ)) begin
                            access_violation = 1;
                            violation_type = 3'b001; // Read violation
                            violation_addr = access_addr;
                            violation_perm = region_perm[i];
                        end
                    end
                    
                    ACCESS_WRITE: begin
                        if (!(region_perm[i] & PERM_WRITE)) begin
                            access_violation = 1;
                            violation_type = 3'b010; // Write violation
                            violation_addr = access_addr;
                            violation_perm = region_perm[i];
                        end
                    end
                    
                    ACCESS_EXECUTE: begin
                        if (!(region_perm[i] & PERM_EXECUTE)) begin
                            access_violation = 1;
                            violation_type = 3'b100; // Execute violation
                            violation_addr = access_addr;
                            violation_perm = region_perm[i];
                        end
                    end
                endcase
                
                // Check privilege level requirements
                if (privilege_level < PRIV_MACHINE && 
                    region_perm[i] == PERM_ALL) begin
                    access_violation = 1;
                    violation_type = 3'b011; // Privilege violation
                    violation_addr = access_addr;
                    violation_perm = region_perm[i];
                end
            end
        end
    end

endmodule 