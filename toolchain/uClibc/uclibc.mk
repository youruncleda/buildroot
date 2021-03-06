#############################################################
#
# uClibc (the C library)
#
#############################################################

ifeq ($(BR2_TOOLCHAIN_SOURCE),y)

UCLIBC_SITE:=http://www.uclibc.org/downloads
ifeq ($(BR2_TOOLCHAIN_EXTERNAL_SOURCE),y)
UCLIBC_SITE:=$(VENDOR_SITE)
endif

# specifying UCLIBC_CONFIG_FILE on the command-line overrides the .config
# setting.
ifndef UCLIBC_CONFIG_FILE
UCLIBC_CONFIG_FILE=$(subst ",, $(BR2_UCLIBC_CONFIG))
#")
endif

UCLIBC_VER:=$(subst ",,$(BR2_UCLIBC_VERSION_STRING))
#")
ifeq ($(BR2_UCLIBC_VERSION_SNAPSHOT),y)
UCLIBC_DIR:=$(TOOL_BUILD_DIR)/uClibc
UCLIBC_SOURCE:=uClibc-$(UCLIBC_VER).tar.bz2
UCLIBC_SITE:=http://www.uclibc.org/downloads/snapshots
UCLIBC_PATCH_DIR:=toolchain/uClibc/
endif

UCLIBC_OFFICIAL_VERSION:=$(UCLIBC_VER)$(VENDOR_SUFFIX)$(VENDOR_UCLIBC_RELEASE)

ifeq ($(BR2_TOOLCHAIN_BUILDROOT),y)
UCLIBC_PATCH_DIR:=toolchain/uClibc/
else
UCLIBC_PATCH_DIR:=$(VENDOR_PATCH_DIR)/uClibc-$(UCLIBC_OFFICIAL_VERSION)
endif

ifneq ($(BR2_UCLIBC_VERSION_SNAPSHOT),y)
UCLIBC_DIR:=$(TOOL_BUILD_DIR)/uClibc-$(UCLIBC_OFFICIAL_VERSION)
endif

UCLIBC_SOURCE:=uClibc-$(UCLIBC_OFFICIAL_VERSION).tar.bz2
UCLIBC_CAT:=$(BZCAT)

UCLIBC_TARGET_ARCH:=$(shell $(SHELL) -c "echo $(ARCH) | sed \
		-e 's/-.*//' \
		-e 's/i.86/i386/' \
		-e 's/sparc.*/sparc/' \
		-e 's/arm.*/arm/g' \
		-e 's/bfin.*/bfin/g' \
		-e 's/m68k.*/m68k/' \
		-e 's/ppc/powerpc/g' \
		-e 's/v850.*/v850/g' \
		-e 's/sh[234].*/sh/' \
		-e 's/mips.*/mips/' \
		-e 's/mipsel.*/mips/' \
		-e 's/cris.*/cris/' \
		-e 's/nios2.*/nios2/' \
")
# just handle the ones that can be big or little
UCLIBC_TARGET_ENDIAN:=$(shell $(SHELL) -c "echo $(ARCH) | sed \
		-e 's/armeb/BIG/' \
		-e 's/arm/LITTLE/' \
		-e 's/mipsel/LITTLE/' \
		-e 's/mips/BIG/' \
		-e 's/sh[234].*eb/BIG/' \
		-e 's/sh[234]/LITTLE/' \
		-e 's/sparc.*/BIG/' \
")

ifneq ($(UCLIBC_TARGET_ENDIAN),LITTLE)
ifneq ($(UCLIBC_TARGET_ENDIAN),BIG)
UCLIBC_TARGET_ENDIAN:=
endif
endif
ifeq ($(UCLIBC_TARGET_ENDIAN),LITTLE)
UCLIBC_NOT_TARGET_ENDIAN:=BIG
else
UCLIBC_NOT_TARGET_ENDIAN:=LITTLE
endif

UCLIBC_ARM_TYPE:=CONFIG_$(subst ",, $(BR2_ARM_TYPE))
#")
UCLIBC_SPARC_TYPE:=CONFIG_SPARC_$(subst ",, $(BR2_SPARC_TYPE))
#")

ifeq ($(BR2_GCC_USE_INTERWORKING),y)
__UCLIBC_EXTRA_TARGET_CFLAGS+=-mthumb-interwork
endif

$(DL_DIR)/$(UCLIBC_SOURCE):
	$(WGET) -P $(DL_DIR) $(UCLIBC_SITE)/$(UCLIBC_SOURCE)

ifeq ($(BR2_ENABLE_LOCALE_PREGENERATED),y)
UCLIBC_SITE_LOCALE:=http://www.uclibc.org/downloads
UCLIBC_SOURCE_LOCALE:=uClibc-locale-030818.tgz

$(DL_DIR)/$(UCLIBC_SOURCE_LOCALE):
	$(WGET) -P $(DL_DIR) $(UCLIBC_SITE_LOCALE)/$(UCLIBC_SOURCE_LOCALE)

UCLIBC_LOCALE_DATA:=$(DL_DIR)/$(UCLIBC_SOURCE_LOCALE)
else
UCLIBC_LOCALE_DATA=
endif

$(UCLIBC_DIR)/.unpacked: $(DL_DIR)/$(UCLIBC_SOURCE) $(UCLIBC_LOCALE_DATA)
	mkdir -p $(TOOL_BUILD_DIR)
	rm -rf $(UCLIBC_DIR)
	$(UCLIBC_CAT) $(DL_DIR)/$(UCLIBC_SOURCE) | tar -C $(TOOL_BUILD_DIR) $(TAR_OPTIONS) -
ifneq ($(BR2_UCLIBC_VERSION_SNAPSHOT),y)
	toolchain/patch-kernel.sh $(UCLIBC_DIR) $(UCLIBC_PATCH_DIR) uClibc-$(UCLIBC_OFFICIAL_VERSION)-\*.patch
else
	toolchain/patch-kernel.sh $(UCLIBC_DIR) $(UCLIBC_PATCH_DIR) uClibc.\*.patch
endif
ifeq ($(BR2_ENABLE_LOCALE_PREGENERATED),y)
	cp -dpf $(DL_DIR)/$(UCLIBC_SOURCE_LOCALE) $(UCLIBC_DIR)/extra/locale/
endif
	touch $@

UCLIBC_CONFIGURED_PREREQ:=$(wildcard $(BR2_DEPENDS_DIR)/br2/arch.h*) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/endian.h*) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/$(UCLIBC_TARGET_ARCH).h*) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/pthreads.h*) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/$(UCLIBC_TARGET_ARCH)/*.h) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/pthread*/*.h) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/enable/*locale*.h) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/enable/*locale*.h) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/use/*wchar*.h) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/use/*updates*.h) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/uclibc/*.h) \
$(wildcard $(BR2_DEPENDS_DIR)/br2/uclibc/*/*.h)

# Some targets may wish to provide their own UCLIBC_CONFIG_FILE...
$(UCLIBC_DIR)/.oldconfig: $(UCLIBC_DIR)/.unpacked $(UCLIBC_CONFIG_FILE) $(UCLIBC_CONFIGURED_PREREQ)
ifeq ($(BR2_USE_UPDATES),y)
	(cd $(@D) && $(SVN_UP))
endif
	cp -f $(UCLIBC_CONFIG_FILE) $(UCLIBC_DIR)/.oldconfig
	$(SED) 's,^CROSS_COMPILER_PREFIX=.*,CROSS_COMPILER_PREFIX="$(TARGET_CROSS)",g' \
		-e 's,# TARGET_$(UCLIBC_TARGET_ARCH) is not set,TARGET_$(UCLIBC_TARGET_ARCH)=y,g' \
		-e 's,^TARGET_ARCH=".*",TARGET_ARCH=\"$(UCLIBC_TARGET_ARCH)\",g' \
		-e 's,^KERNEL_SOURCE=.*,KERNEL_SOURCE=\"$(LINUX_HEADERS_DIR)\",g' \
		-e 's,^KERNEL_HEADERS=.*,KERNEL_HEADERS=\"$(LINUX_HEADERS_DIR)/include\",g' \
		-e 's,^RUNTIME_PREFIX=.*,RUNTIME_PREFIX=\"/\",g' \
		-e 's,^DEVEL_PREFIX=.*,DEVEL_PREFIX=\"/usr/\",g' \
		-e 's,^SHARED_LIB_LOADER_PREFIX=.*,SHARED_LIB_LOADER_PREFIX=\"/lib\",g' \
		$(UCLIBC_DIR)/.oldconfig
ifeq ($(UCLIBC_TARGET_ARCH),arm)
	$(SED) 's/^\(CONFIG_[^_]*[_]*ARM[^=]*\)=.*/# \1 is not set/g' \
		 $(UCLIBC_DIR)/.oldconfig
	$(SED) 's/^.*$(UCLIBC_ARM_TYPE).*/$(UCLIBC_ARM_TYPE)=y/g' $(UCLIBC_DIR)/.oldconfig
	$(SED) '/CONFIG_ARM_.ABI/d' $(UCLIBC_DIR)/.oldconfig
ifeq ($(BR2_ARM_EABI),y)
	/bin/echo "# CONFIG_ARM_OABI is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "CONFIG_ARM_EABI=y" >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_ARM_OABI),y)
	/bin/echo "CONFIG_ARM_OABI=y" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_ARM_EABI is not set" >> $(UCLIBC_DIR)/.oldconfig
endif
endif
ifeq ($(UCLIBC_TARGET_ARCH),mips)
	$(SED) '/CONFIG_MIPS_[NO].._ABI/d' $(UCLIBC_DIR)/.oldconfig
	$(SED) '/CONFIG_MIPS_ISA_.*/d' $(UCLIBC_DIR)/.oldconfig
	(/bin/echo "# CONFIG_MIPS_O32_ABI is not set"; \
	 /bin/echo "# CONFIG_MIPS_N32_ABI is not set"; \
	 /bin/echo "# CONFIG_MIPS_N64_ABI is not set"; \
	 /bin/echo "# CONFIG_MIPS_ISA_1 is not set"; \
	 /bin/echo "# CONFIG_MIPS_ISA_2 is not set"; \
	 /bin/echo "# CONFIG_MIPS_ISA_3 is not set"; \
	 /bin/echo "# CONFIG_MIPS_ISA_4 is not set"; \
	 /bin/echo "# CONFIG_MIPS_ISA_MIPS32 is not set"; \
	 /bin/echo "# CONFIG_MIPS_ISA_MIPS64 is not set"; \
	) >> $(UCLIBC_DIR)/.oldconfig
ifeq ($(BR2_MIPS_OABI32),y)
	$(SED) 's/.*\(CONFIG_MIPS_O32_ABI\).*/\1=y/' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(findstring y,$(BR2_MIPS_EABI)$(BR2_MIPS_ABI32)),y)
	$(SED) 's/.*\(CONFIG_MIPS_N32_ABI\).*/\1=y/' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(findstring y,$(BR2_MIPS_ABI64)$(BR2_MIPS_OABI64)),y)
	$(SED) 's/.*\(CONFIG_MIPS_N64_ABI\).*/\1=y/' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_mips_1),y)
	$(SED) 's/.*\(CONFIG_MIPS_ISA_1\).*/\1=y/' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_mips_2),y)
	$(SED) 's/.*\(CONFIG_MIPS_ISA_2\).*/\1=y/' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_mips_3),y)
	$(SED) 's/.*\(CONFIG_MIPS_ISA_3\).*/\1=y/' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_mips_4),y)
	$(SED) 's/.*\(CONFIG_MIPS_ISA_4\).*/\1=y/' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_mips_32),y)
	$(SED) 's/.*\(CONFIG_MIPS_ISA_MIPS32\).*/\1=y/' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_mips_32r2),y)
	$(SED) 's/.*\(CONFIG_MIPS_ISA_MIPS32\).*/\1=y/' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_mips_64),y)
	$(SED) 's/.*\(CONFIG_MIPS_ISA_MIPS64\).*/\1=y/' $(UCLIBC_DIR)/.oldconfig
endif
endif
ifeq ($(UCLIBC_TARGET_ARCH),nios2)
	$(SED) '/UCLIBC_FORMAT_/d' $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_FDPIC_ELF is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "UCLIBC_FORMAT_FLAT=y" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_FLAT_SEP_DATA is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_SHARED_FLAT is not set" >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(UCLIBC_TARGET_ARCH),sh)
	/bin/echo "# CONFIG_SH2A is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_SH2 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_SH3 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_SH4 is not set" >> $(UCLIBC_DIR)/.oldconfig
ifeq ($(BR2_sh2a_nofpueb),y)
	$(SED) '/UCLIBC_FORMAT_/d' $(UCLIBC_DIR)/.oldconfig
	$(SED) 's,# CONFIG_SH2A is not set,CONFIG_SH2A=y,g' $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_FDPIC_ELF is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_FLAT is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_FLAT_SEP_DATA is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_SHARED_FLAT is not set" >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_sh2eb),y)
	$(SED) '/UCLIBC_FORMAT_/d' $(UCLIBC_DIR)/.oldconfig
	$(SED) 's,# CONFIG_SH2 is not set,CONFIG_SH2=y,g' $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_FDPIC_ELF is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_FLAT is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_FLAT_SEP_DATA is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_FORMAT_SHARED_FLAT is not set" >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_sh3eb),y)
	$(SED) 's,# CONFIG_SH3 is not set,CONFIG_SH3=y,g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_sh3),y)
	$(SED) 's,# CONFIG_SH3 is not set,CONFIG_SH3=y,g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_sh4eb),y)
	$(SED) 's,# CONFIG_SH4 is not set,CONFIG_SH4=y,g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_sh4),y)
	$(SED) 's,# CONFIG_SH4 is not set,CONFIG_SH4=y,g' $(UCLIBC_DIR)/.oldconfig
endif
endif
ifeq ($(UCLIBC_TARGET_ARCH),sparc)
	$(SED) 's/^\(CONFIG_[^_]*[_]*SPARC[^=]*\)=.*/# \1 is not set/g' \
		 $(UCLIBC_DIR)/.oldconfig
	for i in V7 V8 V9 V9B; do echo "# CONFIG_SPARC_$$i is not set"; done \
		>> $(UCLIBC_DIR)/.oldconfig
	$(SED) 's/^.*$(UCLIBC_SPARC_TYPE).*/$(UCLIBC_SPARC_TYPE)=y/g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(UCLIBC_TARGET_ARCH),bfin)
	$(SED) 's/^\(UCLIBC_FORMAT_[^[:space:]]*\).*/# \1 is not set/g' $(UCLIBC_DIR)/.oldconfig
	$(SED) '/UCLIBC_FORMAT_FDPIC_ELF/d' $(UCLIBC_DIR)/.oldconfig
	echo 'UCLIBC_FORMAT_FDPIC_ELF=y' >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_cris),y)
	$(SED) '/CONFIG_CRIS/d' $(UCLIBC_DIR)/.oldconfig
	echo '# CONFIG_CRIS is not set' >> $(UCLIBC_DIR)/.oldconfig
	echo '# CONFIG_CRISV32 is not set' >> $(UCLIBC_DIR)/.oldconfig
ifeq ($(BR2_cris_cris32),y)
	$(SED) 's,^TARGET_ARCH=".*",TARGET_ARCH=\"crisv32\",g' \
	-e 's,.*\(CONFIG_CRIS\) .*,\1=y,' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_cris_cris),y)
	$(SED) 's,^TARGET_ARCH=".*",TARGET_ARCH=\"cris\",g' \
	-e 's,.*\(CONFIG_CRISV32\) .*,\1=y,' $(UCLIBC_DIR)/.oldconfig
endif
endif
ifneq ($(UCLIBC_TARGET_ENDIAN),)
	$(SED) 's/.*ARCH_\(WANTS_\|\)\(LITTLE\|BIG\)_ENDIAN.*//' \
		$(UCLIBC_DIR)/.oldconfig
	echo '# ARCH_$(UCLIBC_NOT_TARGET_ENDIAN)_ENDIAN is not set' >> $(UCLIBC_DIR)/.oldconfig
	echo '# ARCH_WANTS_$(UCLIBC_NOT_TARGET_ENDIAN)_ENDIAN is not set' >> $(UCLIBC_DIR)/.oldconfig
	echo 'ARCH_WANTS_$(UCLIBC_TARGET_ENDIAN)_ENDIAN=y' >> $(UCLIBC_DIR)/.oldconfig
	echo 'ARCH_$(UCLIBC_TARGET_ENDIAN)_ENDIAN=y' >> $(UCLIBC_DIR)/.oldconfig
endif
	$(SED) '/ARCH_USE_MMU/d' $(UCLIBC_DIR)/.oldconfig
ifeq ($(BR2_USE_MMU),y)
	echo 'ARCH_USE_MMU=y' >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_ENABLE_SHARED),y)
	$(SED) 's/.*\(HAVE_SHARED\).*/\1=y/g' $(UCLIBC_DIR)/.oldconfig
else
	$(SED) 's/.*\(HAVE_SHARED\).*/# \1 is not set/g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_LARGEFILE),y)
	$(SED) 's,.*UCLIBC_HAS_LFS.*,UCLIBC_HAS_LFS=y,g' $(UCLIBC_DIR)/.oldconfig
else
	$(SED) 's,.*UCLIBC_HAS_LFS.*,UCLIBC_HAS_LFS=n,g' $(UCLIBC_DIR)/.oldconfig
	$(SED) '/.*UCLIBC_HAS_FOPEN_LARGEFILE_MODE.*/d' $(UCLIBC_DIR)/.oldconfig
	echo "# UCLIBC_HAS_FOPEN_LARGEFILE_MODE is not set" >> $(UCLIBC_DIR)/.oldconfig
endif
	$(SED) '/UCLIBC_HAS_IPV6/d' $(UCLIBC_DIR)/.oldconfig
	echo "# UCLIBC_HAS_IPV6 is not set" >> $(UCLIBC_DIR)/.oldconfig
ifeq ($(BR2_INET_IPV6),y)
	$(SED) 's,^.*UCLIBC_HAS_IPV6.*,UCLIBC_HAS_IPV6=y,g' $(UCLIBC_DIR)/.oldconfig
else
	$(SED) 's,^.*UCLIBC_HAS_IPV6.*,UCLIBC_HAS_IPV6=n,g' $(UCLIBC_DIR)/.oldconfig
endif
	$(SED) '/UCLIBC_HAS_RPC/d' $(UCLIBC_DIR)/.oldconfig
	echo "# UCLIBC_HAS_RPC is not set" >> $(UCLIBC_DIR)/.oldconfig
ifeq ($(BR2_INET_RPC),y)
	$(SED) 's,^.*UCLIBC_HAS_RPC.*,UCLIBC_HAS_RPC=y,g' \
		-e 's,^.*UCLIBC_HAS_FULL_RPC.*,UCLIBC_HAS_FULL_RPC=y,g' \
		-e 's,^.*UCLIBC_HAS_REENTRANT_RPC.*,UCLIBC_HAS_REENTRANT_RPC=y,g' \
		$(UCLIBC_DIR)/.oldconfig
else
	$(SED) 's,^.*UCLIBC_HAS_RPC.*,UCLIBC_HAS_RPC=n,g' \
		-e 's,^.*UCLIBC_HAS_FULL_RPC.*,UCLIBC_HAS_FULL_RPC=n,g' \
		-e 's,^.*UCLIBC_HAS_REENTRANT_RPC.*,UCLIBC_HAS_REENTRANT_RPC=n,g' \
		$(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_SOFT_FLOAT),y)
	$(SED) 's,.*UCLIBC_HAS_FPU.*,UCLIBC_HAS_FPU=n,g' \
		-e 's,^[^_]*HAS_FPU.*,HAS_FPU=n,g' \
		-e 's,.*UCLIBC_HAS_FLOATS.*,UCLIBC_HAS_FLOATS=y,g' \
		-e 's,.*DO_C99_MATH.*,DO_C99_MATH=y,g' \
		$(UCLIBC_DIR)/.oldconfig
	#$(SED) 's,.*UCLIBC_HAS_FPU.*,UCLIBC_HAS_FPU=n\nHAS_FPU=n\nUCLIBC_HAS_FLOATS=y\nUCLIBC_HAS_SOFT_FLOAT=y,g' $(UCLIBC_DIR)/.oldconfig
else
	$(SED) '/UCLIBC_HAS_FLOATS/d' \
		-e 's,.*UCLIBC_HAS_FPU.*,UCLIBC_HAS_FPU=y\nHAS_FPU=y\nUCLIBC_HAS_FLOATS=y\n,g' \
		$(UCLIBC_DIR)/.oldconfig
endif
	$(SED) '/UCLIBC_HAS_THREADS/d' \
		-e '/HAS_NO_THREADS/d' \
		-e '/LINUXTHREADS/d' \
		-e '/LINUXTHREADS_OLD/d' \
		-e '/LINUXTHREADS_NEW/d' \
		-e '/PTHREADS_DEBUG_SUPPORT/d' \
		-e '/UCLIBC_HAS_THREADS_NATIVE/d' $(UCLIBC_DIR)/.oldconfig
ifeq ($(BR2_PTHREADS_NONE),y)
	echo "# UCLIBC_HAS_THREADS is not set" >> $(UCLIBC_DIR)/.oldconfig
	echo "HAS_NO_THREADS=y" >> $(UCLIBC_DIR)/.oldconfig
else
	echo "UCLIBC_HAS_THREADS=y" >> $(UCLIBC_DIR)/.oldconfig
	echo "# HAS_NO_THREADS is not set" >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_PTHREADS),y)
	echo "LINUXTHREADS=y" >> $(UCLIBC_DIR)/.oldconfig
else
	echo "# LINUXTHREADS is not set" >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_PTHREADS_OLD),y)
	echo "LINUXTHREADS_OLD=y" >> $(UCLIBC_DIR)/.oldconfig
else
	echo "# LINUXTHREADS_OLD is not set" >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_PTHREADS_NATIVE),y)
	echo "UCLIBC_HAS_THREADS_NATIVE=y" >> $(UCLIBC_DIR)/.oldconfig
else
	echo "# UCLIBC_HAS_THREADS_NATIVE is not set" >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_PTHREAD_DEBUG),y)
	echo "PTHREADS_DEBUG_SUPPORT=y" >> $(UCLIBC_DIR)/.oldconfig
else
	echo "# PTHREADS_DEBUG_SUPPORT is not set" >> $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_ENABLE_LOCALE),y)
ifeq ($(BR2_ENABLE_LOCALE_PREGENERATED),y)
	$(SED) 's,^.*UCLIBC_HAS_LOCALE.*,UCLIBC_HAS_LOCALE=y\nUCLIBC_PREGENERATED_LOCALE_DATA=y\nUCLIBC_DOWNLOAD_PREGENERATED_LOCALE_DATA=y\nUCLIBC_HAS_XLOCALE=y\nUCLIBC_HAS_GLIBC_DIGIT_GROUPING=n\n,g' $(UCLIBC_DIR)/.oldconfig
else
	$(SED) 's,^.*UCLIBC_HAS_LOCALE.*,UCLIBC_HAS_LOCALE=y\nUCLIBC_PREGENERATED_LOCALE_DATA=n\nUCLIBC_DOWNLOAD_PREGENERATED_LOCALE_DATA=n\nUCLIBC_HAS_XLOCALE=y\nUCLIBC_HAS_GLIBC_DIGIT_GROUPING=n\n,g' $(UCLIBC_DIR)/.oldconfig
endif
	$(SED) 's,.*UCLIBC_HAS_WCHAR.*,UCLIBC_HAS_WCHAR=y,g' $(UCLIBC_DIR)/.oldconfig
else
	$(SED) 's,^.*UCLIBC_HAS_LOCALE.*,UCLIBC_HAS_LOCALE=n,g' $(UCLIBC_DIR)/.oldconfig
	$(SED) 's,.*UCLIBC_HAS_WCHAR.*,UCLIBC_HAS_WCHAR=n,g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_USE_WCHAR),y)
	$(SED) 's,^.*UCLIBC_HAS_WCHAR.*,UCLIBC_HAS_WCHAR=y,g' $(UCLIBC_DIR)/.oldconfig
else
	$(SED) 's,^.*UCLIBC_HAS_WCHAR.*,UCLIBC_HAS_WCHAR=n,g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_UCLIBC_PROGRAM_INVOCATION),y)
	$(SED) 's,^.*UCLIBC_HAS_PROGRAM_INVOCATION_NAME.*,UCLIBC_HAS_PROGRAM_INVOCATION_NAME=y,g' $(UCLIBC_DIR)/.oldconfig
else
	$(SED) 's,^.*UCLIBC_HAS_PROGRAM_INVOCATION_NAME.*,UCLIBC_HAS_PROGRAM_INVOCATION_NAME=n,g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ("$(KERNEL_ARCH)","i386")
	$(SED) '/CONFIG_GENERIC_386/d' \
		-e '/CONFIG_[0-9]86/d' \
		-e '/CONFIG_[0-9]86MMX/d' \
		-e '/CONFIG_PENTIUM.*/d' \
		-e '/CONFIG_K[0-9]/d' \
		-e '/CONFIG_ELAN/d' \
		-e '/CONFIG_CRUSOE/d' \
		-e '/CONFIG_WINCHIP*/d' \
		-e '/CONFIG_CYRIX*/d' \
		-e '/CONFIG_NEHEMIAH/d' $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_GENERIC_386 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_386 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_486 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_586 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_586MMX is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_686 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_PENTIUMII is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_PENTIUMIII is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_PENTIUM4 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_K6 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_K7 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_ELAN is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_CRUSOE is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_WINCHIPC6 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_WINCHIP2 is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_CYRIXIII is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# CONFIG_NEHEMIAH is not set" >> $(UCLIBC_DIR)/.oldconfig
ifeq ($(BR2_x86_i386),y)
	$(SED) 's,# CONFIG_386 is not set,CONFIG_386=y,g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_x86_i486),y)
	$(SED) 's,# CONFIG_486 is not set,CONFIG_486=y,g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_x86_i586),y)
	$(SED) 's,# CONFIG_586 is not set,CONFIG_586=y,g' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(BR2_x86_i686),y)
	$(SED) 's,# CONFIG_686 is not set,CONFIG_686=y,g' $(UCLIBC_DIR)/.oldconfig
endif
endif
	$(SED) '/CONFIG_DOSTRIP/d' -e '/DOSTRIP/d' $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# DOSTRIP is not set" >> $(UCLIBC_DIR)/.oldconfig
ifneq ($(BR2_STRIP_none),y)
	$(SED) 's/.*DOSTRIP.*/DOSTRIP=y/' $(UCLIBC_DIR)/.oldconfig
endif
ifeq ($(findstring y,$(BR2_GCC_CROSS_CXX)$(BR2_GCC_SHARED_LIBGCC)),y)
	$(SED) 's/.*CONFIG_UCLIBC_CTOR_DTOR.*/CONFIG_UCLIBC_CTOR_DTOR=y/' $(UCLIBC_DIR)/.oldconfig
endif
	$(SED) '/HAVE_NO_SSP/d' -e '/UCLIBC_HAS_SSP/d' \
		-e '/UCLIBC_HAS_SSP_COMPAT/d' -e '/SSP_QUICK_CANARY/d' \
		-e '/PROPOLICE_BLOCK_/d' -e '/UCLIBC_BUILD_SSP/d' $(UCLIBC_DIR)/.oldconfig
ifeq ($(BR2_ENABLE_SSP),y)
	/bin/echo "# HAVE_NO_SSP is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "UCLIBC_HAS_SSP=y" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_HAS_SSP_COMPAT is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# SSP_QUICK_CANARY is not set" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "PROPOLICE_BLOCK_ABRT=y" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "UCLIBC_BUILD_SSP=y" >> $(UCLIBC_DIR)/.oldconfig
else
	/bin/echo "HAVE_NO_SSP=y" >> $(UCLIBC_DIR)/.oldconfig
	/bin/echo "# UCLIBC_HAS_SSP is not set" >> $(UCLIBC_DIR)/.oldconfig
endif


$(UCLIBC_DIR)/.config: $(UCLIBC_DIR)/.oldconfig
	cp -dpf $(UCLIBC_DIR)/.oldconfig $(UCLIBC_DIR)/.config
	$(INSTALL) -d $(TOOL_BUILD_DIR)/uClibc_dev/usr/include \
		$(TOOL_BUILD_DIR)/uClibc_dev/usr/lib \
		$(TOOL_BUILD_DIR)/uClibc_dev/lib
	$(MAKE1) -C $(UCLIBC_DIR) \
		PREFIX=$(TOOL_BUILD_DIR)/uClibc_dev/ \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=$(TOOL_BUILD_DIR)/uClibc_dev/ \
		HOSTCC="$(HOSTCC)" \
		BUILD_CFLAGS="$(HOST_CFLAGS)" \
		BUILD_LDFLAGS="$(HOST_LDFLAGS)" \
		oldconfig
	touch -c $@

$(UCLIBC_DIR)/.configured: $(LINUX_HEADERS_DIR)/.configured $(UCLIBC_DIR)/.config
ifeq ($(findstring y,$(BR2_UCLIBC_VERSION_0_9_27)$(BR2_UCLIBC_VERSION_0_9_28_3)$(BR2_UCLIBC_VERSION_0_9_29)),y)
	# older uClibc without the signum.h generation fix
	set -x && $(MAKE1) -C $(UCLIBC_DIR) \
		PREFIX=$(TOOL_BUILD_DIR)/uClibc_dev/ \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=$(TOOL_BUILD_DIR)/uClibc_dev/ \
		HOSTCC="$(HOSTCC)" \
		BUILD_CFLAGS="$(HOST_CFLAGS)" \
		BUILD_LDFLAGS="$(HOST_LDFLAGS)" \
		UCLIBC_EXTRA_LDFLAGS="$(TARGET_LDFLAGS)" \
		UCLIBC_EXTRA_CFLAGS="$(TARGET_CFLAGS) $(__UCLIBC_EXTRA_TARGET_CFLAGS)" \
		pregen install_dev
else
	set -x && $(MAKE1) -C $(UCLIBC_DIR) \
		PREFIX=$(TOOL_BUILD_DIR)/uClibc_dev/ \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=$(TOOL_BUILD_DIR)/uClibc_dev/ \
		HOSTCC="$(HOSTCC)" \
		BUILD_CFLAGS="$(HOST_CFLAGS)" \
		BUILD_LDFLAGS="$(HOST_LDFLAGS)" \
		UCLIBC_EXTRA_LDFLAGS="$(TARGET_LDFLAGS)" \
		UCLIBC_EXTRA_CFLAGS="$(TARGET_CFLAGS) $(__UCLIBC_EXTRA_TARGET_CFLAGS)" \
		install_headers
endif
	# Install the kernel headers to the first stage gcc include dir
ifeq ($(LINUX_HEADERS_IS_KERNEL),y)
	if [ ! -f $(TOOL_BUILD_DIR)/uClibc_dev/usr/include/linux/version.h ]; then \
		cp -pLR $(LINUX_HEADERS_DIR)/include/* \
			$(TOOL_BUILD_DIR)/uClibc_dev/usr/include/; \
	fi
else
	if [ ! -f $(STAGING_DIR)/usr/include/linux/version.h ]; then \
		cp -pLR $(LINUX_HEADERS_DIR)/include/asm \
			$(TOOL_BUILD_DIR)/uClibc_dev/usr/include/; \
		cp -pLR $(LINUX_HEADERS_DIR)/include/linux \
			$(TOOL_BUILD_DIR)/uClibc_dev/usr/include/; \
		if [ -d $(LINUX_HEADERS_DIR)/include/asm-generic ]; then \
			cp -pLR $(LINUX_HEADERS_DIR)/include/asm-generic \
				$(TOOL_BUILD_DIR)/uClibc_dev/usr/include/; \
		fi; \
	fi
endif
	touch $@

$(UCLIBC_DIR)/lib/libc.a: $(UCLIBC_DIR)/.configured $(gcc_initial) $(LIBFLOAT_TARGET)
	$(MAKE) -C $(UCLIBC_DIR) \
		PREFIX= \
		DEVEL_PREFIX=/ \
		RUNTIME_PREFIX=/ \
		HOSTCC="$(HOSTCC)" \
		BUILD_CFLAGS="$(HOST_CFLAGS)" \
		BUILD_LDFLAGS="$(HOST_LDFLAGS)" \
		UCLIBC_EXTRA_LDFLAGS="$(TARGET_LDFLAGS)" \
		UCLIBC_EXTRA_CFLAGS="$(TARGET_CFLAGS) $(__UCLIBC_EXTRA_TARGET_CFLAGS)" \
		all

uclibc-menuconfig: host-sed $(UCLIBC_DIR)/.config
	$(MAKE1) -C $(UCLIBC_DIR) \
		PREFIX=$(TOOL_BUILD_DIR)/uClibc_dev/ \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=$(TOOL_BUILD_DIR)/uClibc_dev/ \
		HOSTCC="$(HOSTCC)" \
		BUILD_CFLAGS="$(HOST_CFLAGS)" \
		BUILD_LDFLAGS="$(HOST_LDFLAGS)" \
		menuconfig && \
	touch -c $(UCLIBC_DIR)/.config

BR2_UCLIBC_CONFIG_FOR_BUILDROOT=$(BASE_DIR)/.buildroot.uclibc_config
$(BR2_UCLIBC_CONFIG_FOR_BUILDROOT): $(dependencies) host-sed $(UCLIBC_DIR)/.config
	# Create BR2__UCLIBC_SYM=val
	cat $(UCLIBC_DIR)/.config > $(BR2_UCLIBC_CONFIG_FOR_BUILDROOT)
	$(SED) '/#/d' -e '/^$$/d' -e 's,\([^=]*\)=\(.*\),BR2__UCLIBC_\1=\2,g' \
		$(BR2_UCLIBC_CONFIG_FOR_BUILDROOT)
	touch -c $@

ifeq ($(BR2__UCLIBC_HAVE_DOT_CONFIG),)
ifeq ($(filter uclibc-menuconfig,$(MAKECMDGOALS)),)
ifneq ($(wildcard $(UCLIBC_CONFIG_FILE)),)
ifeq ($(findstring host-,$(MAKECMDGOALS)),)
include $(BR2_UCLIBC_CONFIG_FOR_BUILDROOT)
endif
endif
endif
endif

$(STAGING_DIR)/usr/lib/libc.a: | $(UCLIBC_DIR)/lib/libc.a
ifneq ($(BR2_TOOLCHAIN_SYSROOT),y)
	$(MAKE1) -C $(UCLIBC_DIR) \
		PREFIX= \
		DEVEL_PREFIX=$(STAGING_DIR)/ \
		RUNTIME_PREFIX=$(STAGING_DIR)/ \
		install_runtime install_dev
else
	$(MAKE1) -C $(UCLIBC_DIR) \
		PREFIX=$(STAGING_DIR) \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=/ \
		HOSTCC="$(HOSTCC)" \
		BUILD_CFLAGS="$(HOST_CFLAGS)" \
		BUILD_LDFLAGS="$(HOST_LDFLAGS)" \
		UCLIBC_EXTRA_LDFLAGS="$(TARGET_LDFLAGS)" \
		UCLIBC_EXTRA_CFLAGS="$(TARGET_CFLAGS) $(__UCLIBC_EXTRA_TARGET_CFLAGS)" \
		install_runtime install_dev
endif
	# Install the kernel headers to the staging dir if necessary
ifeq ($(LINUX_HEADERS_IS_KERNEL),y)
	if [ ! -f $(STAGING_DIR)/usr/include/linux/version.h ]; then \
		cp -pLR $(LINUX_HEADERS_DIR)/include/* \
			$(STAGING_DIR)/usr/include/; \
	fi
else
	if [ ! -f $(STAGING_DIR)/usr/include/linux/version.h ]; then \
		cp -pLR $(LINUX_HEADERS_DIR)/include/asm \
			$(STAGING_DIR)/usr/include/; \
		cp -pLR $(LINUX_HEADERS_DIR)/include/linux \
			$(STAGING_DIR)/usr/include/; \
		if [ -d $(LINUX_HEADERS_DIR)/include/asm-generic ]; then \
			cp -pLR $(LINUX_HEADERS_DIR)/include/asm-generic \
				$(STAGING_DIR)/usr/include/; \
		fi; \
	fi
endif
	# Build the host utils. Need to add an install target...
	$(MAKE1) -C $(UCLIBC_DIR)/utils \
		PREFIX=$(STAGING_DIR) \
		HOSTCC="$(HOSTCC)" \
		hostutils
	# install readelf and eventually other host-utils
	$(INSTALL) -m0755 -D $(UCLIBC_DIR)/utils/readelf.host $(STAGING_DIR)/usr/bin/readelf
	ln -sf readelf $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-readelf
	ln -sf readelf $(STAGING_DIR)/usr/bin/$(GNU_TARGET_NAME)-readelf
ifeq ($(BR2__UCLIBC_HAVE_SHARED),y)
	$(INSTALL) -m0755 -D $(UCLIBC_DIR)/utils/ldd.host $(STAGING_DIR)/usr/bin/ldd
	ln -sf ldd $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-ldd
	ln -sf ldd $(STAGING_DIR)/usr/bin/$(GNU_TARGET_NAME)-ldd
	$(INSTALL) -m0755 -D $(UCLIBC_DIR)/utils/ldconfig.host $(STAGING_DIR)/usr/sbin/ldconfig
	ln -sf ldconfig $(STAGING_DIR)/usr/sbin/$(REAL_GNU_TARGET_NAME)-ldconfig
	ln -sf ldconfig $(STAGING_DIR)/usr/sbin/$(GNU_TARGET_NAME)-ldconfig
endif
ifeq ($(BR2__UCLIBC_UCLIBC_HAS_LOCALE),y)
	if [ -r $(UCLIBC_DIR)/utils/iconv.host ]; then \
	    $(INSTALL) -m0755 -D $(UCLIBC_DIR)/utils/iconv.host $(STAGING_DIR)/usr/bin/iconv; \
	    ln -sf iconv $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-iconv; \
	    ln -sf iconv $(STAGING_DIR)/usr/bin/$(GNU_TARGET_NAME)-iconv; \
	fi
	if [ -r $(UCLIBC_DIR)/utils/locale.host ]; then \
	    $(INSTALL) -m0755 -D $(UCLIBC_DIR)/utils/locale.host $(STAGING_DIR)/usr/bin/locale; \
	    ln -sf locale $(STAGING_DIR)/usr/bin/$(REAL_GNU_TARGET_NAME)-locale; \
	    ln -sf locale $(STAGING_DIR)/usr/bin/$(GNU_TARGET_NAME)-locale; \
	fi
endif
	touch -c $@

# extra paranoia
ifneq ($(TARGET_DIR),)
$(TARGET_DIR)/lib/libc.so.0: | $(STAGING_DIR)/usr/lib/libc.a
	$(MAKE1) -C $(UCLIBC_DIR) \
		PREFIX=$(TARGET_DIR) \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=/ \
		UCLIBC_EXTRA_LDFLAGS="$(TARGET_LDFLAGS)" \
		UCLIBC_EXTRA_CFLAGS="$(TARGET_CFLAGS) $(__UCLIBC_EXTRA_TARGET_CFLAGS)" \
		install_runtime
	touch -c $@

$(TARGET_DIR)/usr/bin/ldd: $(cross_compiler)
	$(MAKE1) -C $(UCLIBC_DIR) CC=$(TARGET_CROSS)gcc \
		CPP=$(TARGET_CROSS)cpp LD=$(TARGET_CROSS)ld \
		UCLIBC_EXTRA_LDFLAGS="$(TARGET_LDFLAGS)" \
		UCLIBC_EXTRA_CFLAGS="$(TARGET_CFLAGS) $(__UCLIBC_EXTRA_TARGET_CFLAGS)" \
		PREFIX=$(TARGET_DIR) utils install_utils
ifeq ($(BR2_CROSS_TOOLCHAIN_TARGET_UTILS),y)
	$(INSTALL) -m0755 -D $(TARGET_DIR)/usr/bin/ldd \
		$(STAGING_DIR)/$(REAL_GNU_TARGET_NAME)/target_utils/ldd
endif
	touch -c $@

endif

uclibc: $(cross_compiler) $(STAGING_DIR)/usr/lib/libc.a

uclibc-source: $(DL_DIR)/$(UCLIBC_SOURCE)

uclibc-unpacked: $(UCLIBC_DIR)/.unpacked

uclibc-config: $(UCLIBC_DIR)/.config

uclibc-oldconfig: $(UCLIBC_DIR)/.oldconfig

uclibc-update: uclibc-config
	cp -f $(UCLIBC_DIR)/.config $(UCLIBC_CONFIG_FILE)

uclibc-configured: kernel-headers $(UCLIBC_DIR)/.configured

uclibc-configured-source: uclibc-source

uclibc-clean:
	-$(MAKE1) -C $(UCLIBC_DIR) clean
	$(patsubst %,rm -f %, $(wildcard $(STAGING_DIR)/usr/bin/*readelf \
		$(STAGING_DIR)/usr/bin/*ldd \
		$(STAGING_DIR)/usr/bin/*ldconfig \
		$(STAGING_DIR)/usr/bin/*iconv \
		$(STAGING_DIR)/usr/bin/*locale \
		$(STAGING_DIR)/usr/sbin/*readelf \
		$(STAGING_DIR)/usr/sbin/*ldd \
		$(STAGING_DIR)/usr/sbin/*ldconfig \
		$(STAGING_DIR)/usr/sbin/*iconv \
		$(STAGING_DIR)/usr/sbin/*locale \
		$(TARGET_DIR)/usr/bin/*readelf \
		$(TARGET_DIR)/usr/bin/*ldd \
		$(TARGET_DIR)/usr/bin/*ldconfig \
		$(TARGET_DIR)/usr/bin/*iconv \
		$(TARGET_DIR)/usr/bin/*locale \
		$(TARGET_DIR)/usr/sbin/*readelf \
		$(TARGET_DIR)/usr/sbin/*ldd \
		$(TARGET_DIR)/usr/sbin/*ldconfig \
		$(TARGET_DIR)/usr/sbin/*iconv \
		$(TARGET_DIR)/usr/sbin/*locale))
	rm -f $(UCLIBC_DIR)/.config $(UCLIBC_DIR)/.configured

uclibc-dirclean:
	rm -rf $(UCLIBC_DIR)

uclibc-target-utils: $(TARGET_DIR)/usr/bin/ldd

uclibc-target-utils-source: $(DL_DIR)/$(UCLIBC_SOURCE)

#############################################################
#
# uClibc for the target
#
#############################################################

$(TARGET_DIR)/usr/lib/libc.a: | $(STAGING_DIR)/usr/lib/libc.a
	$(MAKE1) -C $(UCLIBC_DIR) \
		PREFIX=$(TARGET_DIR) \
		DEVEL_PREFIX=/usr/ \
		RUNTIME_PREFIX=/ \
		install_dev
	# Install the kernel headers to the target dir if necessary
ifeq ($(LINUX_HEADERS_IS_KERNEL),y)
	if [ ! -f $(TARGET_DIR)/usr/include/linux/version.h ]; then \
		cp -pLR $(LINUX_HEADERS_DIR)/include/* \
			$(TARGET_DIR)/usr/include/; \
	fi
else
	if [ ! -f $(TARGET_DIR)/usr/include/linux/version.h ]; then \
		cp -pLR $(LINUX_HEADERS_DIR)/include/asm \
			$(TARGET_DIR)/usr/include/; \
		cp -pLR $(LINUX_HEADERS_DIR)/include/linux \
			$(TARGET_DIR)/usr/include/; \
		if [ -d $(LINUX_HEADERS_DIR)/include/asm-generic ]; then \
			cp -pLR $(LINUX_HEADERS_DIR)/include/asm-generic \
				$(TARGET_DIR)/usr/include/; \
		fi; \
	fi
endif
	touch -c $@

ifeq ($(BR2__UCLIBC_HAVE_SHARED),y)
UCLIBC_TARGETS+=$(TARGET_DIR)/lib/libc.so.0
ifeq ($(BR2_CROSS_TOOLCHAIN_TARGET_UTILS),y)
UCLIBC_TARGETS+=$(TARGET_DIR)/usr/bin/ldd
endif
else
ifeq ($(BR2_HAVE_INCLUDES),y)
UCLIBC_TARGETS+=$(TARGET_DIR)/usr/lib/libc.a
endif
endif

uclibc_target: cross_compiler uclibc $(UCLIBC_TARGETS)
uclibc_target-clean:
	rm -rf $(TARGET_DIR)/usr/include $(UCLIBC_TARGETS) \
		$(TARGET_DIR)/usr/lib/libc.a $(TARGET_DIR)/usr/bin/ldd

uclibc_target-dirclean:
	rm -rf $(TARGET_DIR)/usr/include

endif
