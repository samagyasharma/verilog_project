/* 
 * Enhanced MIPS32 pipeline implementation with advanced features
 * - Hazard Detection Unit
 * - Forwarding Unit
 * - Branch Prediction
 * - Cache Interface
 * - Performance Monitoring
 * - Exception Handling
*/
module main;
    
   input clk1, clk2;  // 2-Phase Clock
   input rst;         // Reset signal
   
   // Pipeline registers
   reg[31:0] PC, IF_ID_IR, IF_ID_NPC;
   reg[31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
   reg[2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;
   reg[31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
   reg EX_MEM_cond;
   reg[31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
   
   // Register Bank and Memory
   reg[31:0] Reg [0:31];  // Register Bank (32 * 32)
   reg[31:0] Mem [0:1023]; // 1024 x 32 memory
   
   // Cache Interface
   reg[31:0] cache_data [0:255];  // 256-entry cache
   reg[23:0] cache_tags [0:255];  // Cache tags
   reg[255:0] cache_valid;        // Cache valid bits
   
   // Hazard Detection Unit
   reg data_hazard, control_hazard, structural_hazard;
   reg[1:0] hazard_type;
   
   // Forwarding Unit
   reg[1:0] forward_A, forward_B;
   reg[31:0] forward_data_A, forward_data_B;
   
   // Branch Prediction
   reg[1:0] branch_prediction;
   reg[31:0] branch_target_buffer [0:63];
   reg[63:0] branch_history;
   
   // Performance Monitoring
   reg[31:0] cycle_count;
   reg[31:0] instruction_count;
   reg[31:0] branch_mispredict_count;
   reg[31:0] cache_miss_count;
   
   // Exception Handling
   reg[2:0] exception_type;
   reg[31:0] exception_pc;
   reg exception_active;
   
   // Pipeline Control
   reg pipeline_stall;
   reg pipeline_flush;
   
   parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,
            SLT=6'b000100, MUL=6'b000101, HLT=6'b111111, LW=6'b001000, 
             SW=6'b001001, ADDI=6'b001010, SUBI=6'b001011,SLTI=6'b001100, 
             BNEQZ=6'b001101, BEQZ=6'b001110;
             
    
    parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011, 
   BRANCH=3'b100, HALT=3'b101; 
 
 
   reg HALTED; // Set after Halt instruction is completed (in the WB stage)
   
   reg TAKEN_BRANCH; // Required to disable instructions after branch*/
   
   
   always @(posedge clk1) // IF Stage 
   if (HALTED == 0) 
       begin 
            if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) || 
                     ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0))) 
              begin 
               IF_ID_IR <= #2 Mem[EX_MEM_ALUOut]; 
               TAKEN_BRANCH <= #2 1'b1; 
               IF_ID_NPC <= #2 EX_MEM_ALUOut + 1; 
               PC <= #2 EX_MEM_ALUOut + 1; 
              end
            else 
              begin 
              IF_ID_IR <= #2 Mem[PC]; 
              IF_ID_NPC <= #2 PC + 1; 
              PC <= #2 PC + 1; 
              end 
        end
        
        
    always @(posedge clk2) // ID Stage 
        if (HALTED == 0) 
             begin 
               if (IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0; 
                  else ID_EX_A <= #2 Reg[IF_ID_IR[25:21]]; // "rs" 
               if (IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0; 
                  else ID_EX_B <= #2 Reg[IF_ID_IR[20:16]]; // "rt" 
                  ID_EX_NPC <= #2 IF_ID_NPC; 
                  ID_EX_IR <= #2 IF_ID_IR; 
                  ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};  
                  
                  
     case (IF_ID_IR[31:26]) 
            ADD,SUB,AND,OR,SLT,MUL: ID_EX_type <= #2 RR_ALU; 
            ADDI,SUBI,SLTI: ID_EX_type <= #2 RM_ALU; 
            LW: ID_EX_type <= #2 LOAD; 
            SW: ID_EX_type <= #2 STORE; 
            BNEQZ,BEQZ: ID_EX_type <= #2 BRANCH; 
            HLT: ID_EX_type <= #2 HALT; 
            default: ID_EX_type <= #2 HALT;       // Invalid opcode
     endcase
    end
    
    always @(posedge clk1) // EX Stage 
 if (HALTED == 0) 
 begin 
 EX_MEM_type <= #2 ID_EX_type; 
 EX_MEM_IR <= #2 ID_EX_IR; 
 TAKEN_BRANCH <= #2 0; 
 case (ID_EX_type) 
 RR_ALU: begin 
 case (ID_EX_IR[31:26]) // "opcode" 
 ADD: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_B; 
 SUB: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_B; 
 AND: EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B; 
 OR: EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B; 
 SLT: EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_B; 
 MUL: EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B; 
 default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx; 
 endcase
 end
              

   RM_ALU: begin 
 case (ID_EX_IR[31:26]) // "opcode" 
 ADDI: EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm; 
 SUBI: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm; 
 SLTI: EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_Imm; 
 default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx; 
 endcase
 end

             LOAD, STORE: 
 begin 
 EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm; 
 EX_MEM_B <= #2 ID_EX_B; 
 end
 BRANCH: begin 
 EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm; 
EX_MEM_cond <= #2 (ID_EX_A == 0); 
 end 
 endcase
 end
             
             always @(posedge clk2) // MEM Stage 
 if (HALTED == 0) 
 begin 
 MEM_WB_type <= EX_MEM_type; 
 MEM_WB_IR <= #2 EX_MEM_IR; 
 case (EX_MEM_type) 
 RR_ALU, RM_ALU: 
 MEM_WB_ALUOut <= #2 EX_MEM_ALUOut; 
 LOAD: MEM_WB_LMD <= #2 Mem[EX_MEM_ALUOut]; 
 STORE: if (TAKEN_BRANCH == 0) // Disable write 
 Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B; 
 endcase
 end

always @(posedge clk1) // WB Stage 
 begin 
 if (TAKEN_BRANCH == 0) // Disable write if branch taken 
 case (MEM_WB_type) 
 RR_ALU: Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut; // "rd" 
 RM_ALU: Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut; // "rt" 
 LOAD: Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD; // "rt" 
 HALT: HALTED <= #2 1'b1; 
 endcase
 end 


  initial 
    begin
      $display("Hello, World");
      $finish ;
    end

   // Hazard Detection Unit
   always @(*) begin
     // Data Hazard Detection
     data_hazard = ((ID_EX_IR[25:21] == IF_ID_IR[20:16]) || 
                    (ID_EX_IR[25:21] == IF_ID_IR[15:11])) &&
                    (ID_EX_type == LOAD);
     
     // Control Hazard Detection
     control_hazard = TAKEN_BRANCH;
     
     // Structural Hazard Detection
     structural_hazard = (ID_EX_type == MUL) && (EX_MEM_type == MUL);
     
     hazard_type = {data_hazard, control_hazard};
   end
   
   // Forwarding Unit
   always @(*) begin
     // Forward A
     if ((EX_MEM_type == RR_ALU || EX_MEM_type == RM_ALU) &&
         (EX_MEM_IR[15:11] == ID_EX_IR[25:21]))
       forward_A = 2'b01;
     else if ((MEM_WB_type == RR_ALU || MEM_WB_type == RM_ALU) &&
              (MEM_WB_IR[15:11] == ID_EX_IR[25:21]))
       forward_A = 2'b10;
     else
       forward_A = 2'b00;
       
     // Forward B (similar logic)
     if ((EX_MEM_type == RR_ALU || EX_MEM_type == RM_ALU) &&
         (EX_MEM_IR[15:11] == ID_EX_IR[20:16]))
       forward_B = 2'b01;
     else if ((MEM_WB_type == RR_ALU || MEM_WB_type == RM_ALU) &&
              (MEM_WB_IR[15:11] == ID_EX_IR[20:16]))
       forward_B = 2'b10;
     else
       forward_B = 2'b00;
   end
   
   // Branch Prediction
   always @(posedge clk1) begin
     if (rst) begin
       branch_history <= 0;
       branch_prediction <= 2'b00;
     end else begin
       // Update branch history
       branch_history <= {branch_history[62:0], TAKEN_BRANCH};
       
       // Simple 2-bit saturating counter
       if (TAKEN_BRANCH)
         branch_prediction <= (branch_prediction == 2'b11) ? 2'b11 : branch_prediction + 1;
       else
         branch_prediction <= (branch_prediction == 2'b00) ? 2'b00 : branch_prediction - 1;
     end
   end
   
   // Cache Interface
   function automatic [31:0] cache_access;
     input [31:0] addr;
     input read_write;
     input [31:0] write_data;
     begin
       if (cache_valid[addr[9:2]] && cache_tags[addr[9:2]] == addr[31:8])
         cache_access = cache_data[addr[9:2]];
       else begin
         cache_miss_count <= cache_miss_count + 1;
         cache_data[addr[9:2]] <= Mem[addr];
         cache_tags[addr[9:2]] <= addr[31:8];
         cache_valid[addr[9:2]] <= 1'b1;
         cache_access = Mem[addr];
       end
     end
   endfunction
   
   // Performance Monitoring
   always @(posedge clk1) begin
     if (rst) begin
       cycle_count <= 0;
       instruction_count <= 0;
       branch_mispredict_count <= 0;
       cache_miss_count <= 0;
     end else begin
       cycle_count <= cycle_count + 1;
       if (!pipeline_stall)
         instruction_count <= instruction_count + 1;
       if (TAKEN_BRANCH && branch_prediction[1] == 0)
         branch_mispredict_count <= branch_mispredict_count + 1;
     end
   end
   
   // Exception Handling
   always @(posedge clk1) begin
     if (rst) begin
       exception_active <= 0;
       exception_type <= 0;
       exception_pc <= 0;
     end else begin
       // Check for exceptions
       if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001000) // SYSCALL
         exception_type <= 3'b001;
       else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001100) // BREAK
         exception_type <= 3'b010;
       else if (ID_EX_IR[31:26] == 6'b000000 && ID_EX_IR[5:0] == 6'b001101) // TRAP
         exception_type <= 3'b011;
         
       if (exception_type != 0) begin
         exception_active <= 1;
         exception_pc <= PC;
         pipeline_flush <= 1;
       end
     end
   end
endmodule
