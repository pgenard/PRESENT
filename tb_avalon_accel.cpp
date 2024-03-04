#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vavalon_accel.h"

#define MAX_SIM_TIME 110

vluint64_t sim_time = 0;

int main(int argc, char** argv, char** env) {
  Verilated::commandArgs(argc, argv);
  
  Vavalon_accel *dut = new Vavalon_accel;
  
  Verilated::traceEverOn(true);
  
  VerilatedVcdC *m_trace = new VerilatedVcdC;
  
  dut->trace(m_trace, 5);
  m_trace->open("waveform.vcd");

  while (sim_time < MAX_SIM_TIME) {
    // Reset
    if (sim_time == 1) {
      dut->reset_n = 0;
    }

    // Écrire la clé de chiffrement
    if (sim_time == 3) {
      dut->reset_n = 1;
      dut->avs_write = 1;
      dut->avs_writedata = 0x0; // 0xdeadbeef;
      dut->avs_address = 0;
      dut->avm_waitrequest = 0;
    }

    if (sim_time == 5) {
      dut->avs_write = 1;
      dut->avs_writedata = 0x0; // 0xc01dcafe;
      dut->avs_address = 0x04;
      dut->avm_waitrequest = 0;
    }

    if (sim_time == 7) {
      dut->avs_write = 1;
      dut->avs_writedata = 0x0; // 0xbadec0de;
      dut->avs_address = 0x08;
      dut->avm_waitrequest = 0;
    }

    if (sim_time == 9) {
      dut->avs_write = 1;
      dut->avs_writedata = 0x0; // 0x8badf00d;
      dut->avs_address = 0xc;
      dut->avm_waitrequest = 0;
    }

    // Écrire l’adresse de base de la zone mémoire source
    if (sim_time == 11) {
      dut->avs_write = 1;
      dut->avs_writedata = 0x200;
      dut->avs_address = 0x10;
    }

    // Écrire l’adresse de base de la zone mémoire destination
    if (sim_time == 13) {
      dut->avs_write = 1;
      dut->avs_writedata = 0x100;
      dut->avs_address = 0x14;
    }

    // Écrire la taille de la zone mémoire à chiffrer
    if (sim_time == 15) {
      dut->avs_write = 1;
      dut->avs_writedata = 2;
      dut->avs_address = 0x18;
    }

    // Écrire dans le registre de commande/démarrer le chiffrement
    if (sim_time == 17) {
      dut->avs_write = 1;
      dut->avs_writedata = 1;
      dut->avs_address = 0x1c;
    }

    if (sim_time > 17) {
      if (dut->irq) {
	
      }
    }
    
    dut->clk ^= 1;
    dut->eval();
    m_trace->dump(sim_time);
    sim_time++;
  }
  
  m_trace->close();
  
  delete dut;
  
  exit(EXIT_SUCCESS);
}
