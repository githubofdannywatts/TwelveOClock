@echo off

nasm -f bin "Boot Sector.asm" -o "Boot Sector.sys"

nasm -f bin Kernel.asm -o Kernel.sys

fat_imgen -f "Twelve O'Clock.img" -c

fat_imgen -f "Twelve O'Clock.img" -m -s "Boot Sector.sys"

fat_imgen -f "Twelve O'Clock.img" -m -i Kernel.sys