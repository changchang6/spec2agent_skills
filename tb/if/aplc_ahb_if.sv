`ifndef APLC_AHB_IF_SV
`define APLC_AHB_IF_SV

interface aplc_ahb_if(input hclk);

  logic        hresetn;
  logic        hsel;
  logic [31:0] haddr;
  logic        hwrite;
  logic [2:0]  hburst;
  logic [2:0]  hsize;
  logic [1:0]  htrans;
  logic [31:0] hwdata;
  logic [31:0] hrdata;
  logic        hready_out;
  logic        hresp;

  clocking slave_cb @(posedge hclk);
    input   hsel, haddr, hwrite, hburst, hsize, htrans, hwdata;
    output  hrdata, hready_out, hresp;
  endclocking

  modport slave(clocking slave_cb);

endinterface : aplc_ahb_if

`endif // APLC_AHB_IF_SV
