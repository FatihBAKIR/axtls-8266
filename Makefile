TOOLCHAIN_PREFIX := xtensa-lx106-elf-
CC := $(TOOLCHAIN_PREFIX)gcc
AR := $(TOOLCHAIN_PREFIX)ar
LD := $(TOOLCHAIN_PREFIX)gcc
OBJCOPY := $(TOOLCHAIN_PREFIX)objcopy

XTENSA_LIBS ?= $(shell $(CC) -print-sysroot)

TOOLCHAIN_DIR=$(shell cd $(XTENSA_LIBS)/../../; pwd)
SDK_DIR=$(shell cd ../; pwd)

$(info $(SDK_DIR))

OBJ_FILES := \
	crypto/aes.o \
	crypto/bigint.o \
	crypto/hmac.o \
	crypto/md5.o \
	crypto/rc4.o \
	crypto/rsa.o \
	crypto/sha1.o \
	crypto/sha256.o \
	crypto/sha384.o \
	crypto/sha512.o \
	ssl/asn1.o \
	ssl/gen_cert.o \
	ssl/loader.o \
	ssl/os_port.o \
	ssl/p12.o \
	ssl/tls1.o \
	ssl/tls1_clnt.o \
	ssl/tls1_svr.o \
	ssl/x509.o \
	crypto/crypto_misc.o


CPPFLAGS += -I$(XTENSA_LIBS)/include \
		-Icrypto \
		-Issl \
		-I.

LDFLAGS  += 	-L$(XTENSA_LIBS)/lib \
		-L$(XTENSA_LIBS)/arch/lib \

CFLAGS += -I$(SDK_DIR)/esp-lwip/src/include \
		  -I$(SDK_DIR)/sdk/include \
		  -I$(SDK_DIR)/esp-lwip/config \
		  -I$(SDK_DIR)/esp-lwip/espressif/include

CFLAGS += -std=c99 -DESP8266

CFLAGS += -ffreestanding -Wall -Os -g -O2 -Wpointer-arith -Wl,-EL -nostdlib -mlongcalls -mtext-section-literals  -D__ets__ -DICACHE_FLASH -DLWIP_RAW -DESP8266

CFLAGS += -ffunction-sections -fdata-sections

CFLAGS += -fdebug-prefix-map=$(PWD)= -fdebug-prefix-map=$(TOOLCHAIN_DIR)=xtensa-lx106-elf -gno-record-gcc-switches

MFORCE32 := $(shell $(CC) --help=target | grep mforce-l32)
ifneq ($(MFORCE32),)
    # If the compiler supports the -mforce-l32 flag, the compiler will generate correct code for loading
    # 16- and 8-bit constants from program memory. So in the code we can directly access the arrays
    # placed into program memory.
    CFLAGS +=  -mforce-l32
else
	# Otherwise we need to use a helper function to load 16- and 8-bit constants from program memory.
    CFLAGS += -DWITH_PGM_READ_HELPER
endif

BIN_DIR := bin
AXTLS_AR := $(BIN_DIR)/libaxtls.a

all: $(AXTLS_AR)

$(AXTLS_AR): | $(BIN_DIR)

$(AXTLS_AR): $(OBJ_FILES)
	$(AR) cru $@ $^
	$(OBJCOPY) --rename-section .text=.irom0.text --rename-section .literal=.irom0.literal $@ 

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

install: $(AXTLS_AR)
	cp $(AXTLS_AR) $(PREFIX)/xtensa-lx106-elf/sysroot/usr/lib/

clean:
	rm -rf $(OBJ_FILES) $(AXTLS_AR)


.PHONY: all clean
