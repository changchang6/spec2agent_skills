// APLC SPI VIP defines and macros
`ifndef APLC_SPI_DEFINES_SV
`define APLC_SPI_DEFINES_SV

`define APLC_SPI_MSG(ID, MSG, VERBOSITY) \
    `uvm_info(ID, MSG, VERBOSITY)

`define APLC_SPI_ERR(ID, MSG) \
    `uvm_error(ID, MSG)

`define APLC_SPI_WARN(ID, MSG) \
    `uvm_warning(ID, MSG)

`endif
