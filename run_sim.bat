
@echo off

@rem "make library"
if not exist "work" vlib work

@rem "compile designs"
vlog -timescale 1ns/1ps +incdir+.\\rtl\\ -sv -f filelist -l compile.log


@rem "execute simulation"
:: vsim -c work.tb_top -do "do wave.do; run 100ms; quit;"
:: vsim -c work.tb_top -do "do wave.do; run -all; quit;"


