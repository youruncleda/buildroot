#############################################################
#
# lockfile-progs
#
#############################################################
LOCKFILE_PROGS_VERSION=0.1.11
LOCKFILE_PROGS_SOURCE:=lockfile-progs_$(LOCKFILE_PROGS_VERSION).tar.gz
LOCKFILE_PROGS_SITE:=$(BR2_DEBIAN_MIRROR)/debian/pool/main/l/lockfile-progs/
LOCKFILE_PROGS_CAT:=$(ZCAT)
LOCKFILE_PROGS_DIR:=$(BUILD_DIR)/lockfile-progs-$(LOCKFILE_PROGS_VERSION)
LOCKFILE_PROGS_BINARY:=usr/bin/lockfile-create

$(DL_DIR)/$(LOCKFILE_PROGS_SOURCE):
	 $(WGET) -P $(DL_DIR) $(LOCKFILE_PROGS_SITE)/$(LOCKFILE_PROGS_SOURCE)

lockfile-progs-source: $(DL_DIR)/$(LOCKFILE_PROGS_SOURCE)

$(LOCKFILE_PROGS_DIR)/.unpacked: $(DL_DIR)/$(LOCKFILE_PROGS_SOURCE)
	$(LOCKFILE_PROGS_CAT) $(DL_DIR)/$(LOCKFILE_PROGS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	# huh?! Somebody funny up there?
	mv -v $(BUILD_DIR)/sid $(@D)
	toolchain/patch-kernel.sh $(LOCKFILE_PROGS_DIR) package/lockfile-progs/ lockfile-progs\*.patch
	touch $@

$(TARGET_DIR)/$(LOCKFILE_PROGS_BINARY): $(LOCKFILE_PROGS_DIR)/.unpacked
	$(MAKE) $(TARGET_CONFIGURE_OPTS) LDFLAGS="$(TARGET_LDFLAGS)" \
		-C $(LOCKFILE_PROGS_DIR)
	mkdir -p $(TARGET_DIR)/usr/bin
	cp -dpf $(LOCKFILE_PROGS_DIR)/bin/lockfile* $(TARGET_DIR)/usr/bin
ifeq ($(BR2_HAVE_MANPAGES),y)
	for i in lockfile-create.1 lockfile-remove.1 mail-lock.1 mail-unlock.1 \
		lockfile-progs.1 lockfile-touch.1 mail-touchlock.1; \
	do \
		$(INSTALL) -D -m 0644 $(LOCKFILE_PROGS_DIR)/man/$$i \
			$(TARGET_DIR)/usr/share/man/man1/$$i; \
	done
endif
	$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/$(LOCKFILE_PROGS_BINARY)

lockfile-progs: uclibc liblockfile $(TARGET_DIR)/$(LOCKFILE_PROGS_BINARY)

lockfile-progs-clean:
	-$(MAKE) -C $(LOCKFILE_PROGS_DIR) clean
	rm -f $(TARGET_DIR)/usr/bin/lockfile-*
	for i in lockfile-create.1 lockfile-remove.1 mail-lock.1 mail-unlock.1 \
		lockfile-progs.1 lockfile-touch.1 mail-touchlock.1; \
	do \
		rm -f $(TARGET_DIR)/usr/share/man/man1/$$i; \
	done

lockfile-progs-dirclean:
	rm -rf $(LOCKFILE_PROGS_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(BR2_PACKAGE_LOCKFILE_PROGS),y)
TARGETS+=lockfile-progs
endif
