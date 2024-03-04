module avalon_accel(
  input  clk,
  input  reset_n,
  // target interface
  input         avs_write,
  input  [31:0] avs_writedata,
  output [31:0] avs_readdata,
  input  [4:0]  avs_address,
  // initiator interface
  output        avm_write,
  output        avm_read,
  input         avm_waitrequest,
  output [31:0] avm_writedata,
  input  [31:0] avm_readdata,
  output [31:0] avm_address,
  // interrupt
  output  irq
);

/*******************************
* Registers
  R0  -> K0
  R1  -> K1
  R2  -> K2
  R3  -> K3
  R4  -> src
  R5  -> dest
  R6  -> num
  R7  -> ctrl/status
*******************************/
logic[31:0] R[0:7];

// Aliases
wire[3:0][31:0] key_reg  = {R[3],R[2],R[1],R[0]};
wire[31:0]      src_addr_reg = R[4];
wire[31:0]     dest_addr_reg = R[5];
wire[31:0]       num_blk_reg = R[6];
wire[31:0]          ctrl_reg = R[7];

/* verilator lint_off WIDTH */
wire start_dma = ctrl_reg; 

// Avalon Target interface to update the registers
always_ff@(posedge clk or negedge reset_n)
  if(!reset_n)
    for(int i=0; i<8;i++)
      R[i] <= '0;
  else if(avs_write)
      R[avs_address[4:2]] <= avs_writedata;

assign avs_readdata = R[avs_address[4:2]];


/*
*
* Cipher Algorithm Present
*
*/

logic start;
logic eoc;
logic [63:0] plaintext;
logic [63:0] ciphertext;

present present_inst (
          .clk(clk),
          .nrst(reset_n),
          .start(start),
          .eoc(eoc),
          .plaintext(plaintext),
          .key(key_reg),
          .ciphertext(ciphertext)
);
   
/*

Finite State Machine

I   , R1   , R2   , C     , W1    , W2    , E
IDLE, READ1, READ2, CIPHER, WRITE1, WRITE2, END
000 , 001  , 010  , 011   , 100   , 101   , 110
 
*/
enum logic[2:0] { I, R1, R2, C, W1, W2, E } state;

// Variable for counting the number of blocks encrypted
logic[31:0] count;

// Variable for going through the memory
logic[31:0] src_addr;
logic[31:0] dest_addr;


always_ff@(posedge clk or negedge reset_n)
if(!reset_n)
begin
  state <= I;
  count <= 0;
  start <= 0;
  src_addr <= 0;
  dest_addr <= 0;
  plaintext <= 0;
end
else
  case (state)
  I:  if (start_dma == 1)
      begin
        count <= 0;
        state <= R1;
        src_addr <= src_addr_reg;
        dest_addr <= dest_addr_reg;
      end
      else
        state <= I;
  R1: if (!avm_waitrequest)
      begin
        plaintext[31:0] <= avm_readdata;
        state <= R2;

        // Increment the address for the next read
        src_addr <= src_addr + 4;

        // Increment the counter of blocks encrypted
        count <= count + 1;
      end
      else
        state <= R1;
  R2: if (!avm_waitrequest)
      begin
        plaintext[63:32] <= avm_readdata; 
        state <= C;
        start <= 1;

        // Increment the address for the next read
        src_addr <= src_addr + 4;
      end
      else
        begin
        state <= R2;
        end
  C:  begin
      // Implementation for cipher     
      if (start)
        start <= 0;
     
      if (eoc)
      begin
        state <= W1;
      end
      else
        state <= C;
      end
  W1: if (!avm_waitrequest)
      begin
        state <= W2;
        // Increment the address for the next write
        dest_addr <= dest_addr + 4;
      end
      else
        state <= W1;
  W2: if (!avm_waitrequest)
      begin
        if (count == num_blk_reg) // NEW TRY
          state <= E;
        else
          state <= R1;
        // Increment the address for the next write
        dest_addr <= dest_addr + 4;
      end
      else
        state <= W2;
  E:  if (ctrl_reg == 0)
        state <= I;
      else
        state <= E;
  default:
      state <= I;
  endcase


assign irq = (state == E) ? 1 : 0;
assign avm_read = ((state == R1) || (state == R2)) ? 1 : 0;
assign avm_address = ((state == R1) || (state == R2)) ? src_addr : dest_addr;
assign avm_write = ((state == W1) || (state == W2)) ? 1 : 0;
assign avm_writedata = (state == W1)? ciphertext[31:0] : ciphertext[63:32]; // reuse of plaintext for saving ciphertext


endmodule
