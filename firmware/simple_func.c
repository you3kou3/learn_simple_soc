
//__attribute__((section(".text.startup")))
void _start() {
    *(volatile unsigned int *)0x80000000 = 1;
    while (1);
}
