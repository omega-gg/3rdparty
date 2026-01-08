import struct
import sys
import os

def patch_elf_16k(filename):
    if not os.path.exists(filename):
        print(f"Error: File '{filename}' not found.")
        return

    with open(filename, 'r+b') as f:
        # Verify ELF Magic
        if f.read(4) != b'\x7fELF':
            print(f"Error: '{filename}' is not an ELF file.")
            return

        # Get Program Header offset (e_phoff)
        f.seek(32)
        ph_offset = struct.unpack('<Q', f.read(8))[0]

        # Get Header entry size (e_phentsize) and count (e_phnum)
        f.seek(54)
        ph_entry_size = struct.unpack('<H', f.read(2))[0]
        ph_num = struct.unpack('<H', f.read(2))[0]

        print(f"Processing {filename}...")
        print(f"Found {ph_num} program headers. Patching...")

        patch_count = 0
        for i in range(ph_num):
            entry_pos = ph_offset + (i * ph_entry_size)
            f.seek(entry_pos)

            p_type = struct.unpack('<I', f.read(4))[0]
            if p_type == 1: # PT_LOAD
                # p_align is at offset 48 for 64-bit ELF
                f.seek(entry_pos + 48)
                current_align = struct.unpack('<Q', f.read(8))[0]

                if current_align < 16384:
                    f.seek(entry_pos + 48)
                    f.write(struct.pack('<Q', 16384))
                    print(f"  [Segment {i}] Fixed alignment: {hex(current_align)} -> 0x4000")
                    patch_count += 1

    if patch_count > 0:
        print(f"Done! Patched {patch_count} segments. Verify with readelf.")
    else:
        print("No segments needed patching (already 16KB aligned or higher).")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python patch-16k.py <path>")
    else:
        patch_elf_16k(sys.argv[1])
