# APLC-Lite Testbench File List

# Include directories
+incdir+../tb/if
+incdir+../tb/uvc/spi_agent
+incdir+../tb/uvc/csr_agent
+incdir+../tb/env

# Interface files
../tb/if/spi_if.sv
../tb/if/csr_if.sv
../tb/if/if_harness.sv

# SPI VIP (package includes all agent files)
../tb/uvc/spi_agent/spi_agent_pkg.sv

# CSR VIP (package includes all agent files)
../tb/uvc/csr_agent/csr_agent_pkg.sv

# Environment
../tb/env/test1_env_defines.sv
../tb/env/test1_rm.sv
../tb/env/test1_scoreboard.sv
../tb/env/test1_env.sv

# Testbench top
../tb/tb_top.sv

# Test cases
../tc/base_test.sv
