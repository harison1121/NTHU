module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    output  wire                     awready,  //no signal   ok
    output  wire                     wready,   //no signal   ok
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    output  wire                     arready,   //no signal ok
    input   wire                     rready,
    input   wire                     arvalid,  
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     rvalid,    //no signal ok 
    output  wire [(pDATA_WIDTH-1):0] rdata,     //no signal  no idea
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata,  //no signal 
    input   wire                     ss_tlast,  //no signal
    output  wire                     ss_tready, //no signal
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, //no signal
    output  wire [(pDATA_WIDTH-1):0] sm_tdata,  //no signal
    output  wire                     sm_tlast,  //no signal
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE, //no signal
    output  wire                     tap_EN, //no signal ok
    output  wire [(pDATA_WIDTH-1):0] tap_Di, //no signal
    output  wire [(pADDR_WIDTH-1):0] tap_A, //no signal
    input   wire [(pDATA_WIDTH-1):0] tap_Do, //no signal

    // bram for data RAM
    output  wire [3:0]               data_WE,  //no signal
    output  wire                     data_EN,  //no signal ok 
    output  wire [(pDATA_WIDTH-1):0] data_Di,  //no signal
    output  wire [(pADDR_WIDTH-1):0] data_A,   //no signal
    input   wire [(pDATA_WIDTH-1):0] data_Do,  //no signal

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);
 //fir
   reg                     awready;  
   reg                     wready;  
   wire                     awvalid;
   wire [(pADDR_WIDTH-1):0] awaddr;
   wire                     wvalid;
   wire [(pDATA_WIDTH-1):0] wdata;
   reg                   arready;  
   wire                     rready;
   wire                     arvalid;
   wire [(pADDR_WIDTH-1):0] araddr;
   reg                      rvalid;    
   reg[(pDATA_WIDTH-1):0]   rdata;     
   wire                     ss_tvalid; 
   wire [(pDATA_WIDTH-1):0] ss_tdata;  
   wire                     ss_tlast;  
   reg                     ss_tready; 
   wire                    sm_tready; 
   reg                     sm_tvalid; 
   reg [(pDATA_WIDTH-1):0] sm_tdata;  
   reg                     sm_tlast;  
   // bram for tap RAM
   reg[3:0]               tap_WE; 
   reg                    tap_EN; 
   reg[(pDATA_WIDTH-1):0] tap_Di;
   reg[(pADDR_WIDTH-1):0] tap_A; 
   wire [(pDATA_WIDTH-1):0] tap_Do; 

    // bram for data RAM
   reg [3:0]               data_WE;  
   reg                     data_EN;  
   reg [(pDATA_WIDTH-1):0] data_Di;  
   reg [(pADDR_WIDTH-1):0] data_A;   
   wire [(pDATA_WIDTH-1):0] data_Do; 
  
 
 //produce signal awready( ensure that when awvalid =1 then awready=1)
always@(posedge axis_clk)begin
 if(axis_rst_n == 1'b0)begin
    awready<=1'b0;
  end else begin
        if(~awready && awvalid)begin
           awready<=1'b1;
        end else begin
           awready<=1'b0;
             end
        end
 end
 
//produce signal wready (control wready inside wvalid with awready)
always@(posedge axis_clk)begin
 if(axis_rst_n == 1'b0)begin
         wready<=1'b0;
  end else begin
        if(~wready && wvalid && awready)begin
            wready<=1'b1;
        end else begin
            wready<=1'b0;
             end
        end
 end
 
//produce arready (ensure that when arvalid is high then arready) 
 always@(posedge axis_clk)begin
  if(axis_rst_n == 1'b0)begin
       arready = 1'b0;
   end else begin
        if(~arready && arvalid )begin
            arready<=1'b1; 
       end else begin
            arready<=1'b0;
             end
        end
 end
 
//produce rvalid (1.ensure rvalid is after arready ; 
//                 2.when both rvalid &rready are high ,rvalid moves to low in the next cycle )
 always@(posedge axis_clk)begin
  if(axis_rst_n == 1'b0)begin
       rvalid = 1'b0;
   end else begin
        if(arready)begin
           rvalid =1'b1; 
       end else begin
             if(rvalid && rready )begin
                rvalid =1'b0;
             end
           end 
        end
 end
 
//produce tap_EN (when sm_tready && ss_tvalid ==1, tap_EN =1)
//Produce data_en (conditions are the same as tap_EN)
always@(posedge axis_clk)begin
     if(axis_rst_n == 1'b0)begin
       tap_EN =1'b0;
       data_EN=1'b0;
     end else begin
              if( sm_tready && ss_tvalid)begin
                 tap_EN = 1'b1;
                 data_EN =1'b1;
              end else begin
                   if( sm_tready && ss_tvalid ==0)begin
                       tap_EN = 1'b0;
                       data_EN =1'b0;
                   end
                   end
           end
end

//produce sm_tlast (when slave finish the work & produce ss_tlast , master should react with sm__tlast)
always@(posedge axis_clk)begin
     if(axis_rst_n == 1'b0)begin
        sm_tlast <=1'b0;
     end else begin
          if(axis_rst_n == 1'b1)begin
           sm_tlast <= ss_tlast;
         end
     end
end
 
 // rdata(undone : datalength?)
  reg ap_ctrl[3:0]
always@(posedge axis_clk)begin
  if(axis_rst_n == 1'b0)begin
      ap_ctrl[0] =1'b0 ; //ap_start
      ap_ctrl [1] = 1'b0 ; // ap_done
      ap_ctrl [2] = 1'b1 ; // ap_idle
  end else begin
     if(rvalid && rready)begin
       case(araddr)
         12'h0: begin
                rdata[0] = ap_ctrl[0]
                rdata[1] = ap_ctrl[1]
                rdata[2] = ap_ctrl[2]
                end
         12'h10:
                r_data <= datalength;
         default:
                 r_data <= tap_Do            ;
               
          endcase      
         end
      end
 end
 
 
 
 
 
 
 
 
 endmodule