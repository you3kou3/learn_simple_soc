@echo off
setlocal

echo step1 : compile c file
riscv-none-elf-gcc -c -mabi=ilp32 -march=rv32im -o ./simple_func.o ./simple_func.c
if errorlevel 1 goto error

echo step2 : make elf file
riscv-none-elf-gcc -mabi=ilp32 -march=rv32im -ffreestanding -nostdlib ^
  -T ./sections.lds ^
  -o ./simple_func.elf ./simple_func.o ^
  -Wl,--build-id=none,--strip-debug
if errorlevel 1 goto error

echo step3 : convert elf to bin
riscv-none-elf-objcopy -O binary ./simple_func.elf ./simple_func.bin
if errorlevel 1 goto error

echo step4 : convert bin to hex
python ./makehex.py ./simple_func.bin 32768 > ./simple_func.hex
if errorlevel 1 goto error

echo Build successful!
goto end

:error
echo.
echo Error occurred. Stop process.
exit /b 1

:end
endlocal
