#############################################################
#
# build GNU readline
#
#############################################################
READLINE_VERSION:=5.2
READLINE_VERSION_SMALL=$(subst .,,$(READLINE_VERSION))
READLINE_SITE:=$(BR2_GNU_MIRROR)/readline/
READLINE_SOURCE:=readline-$(READLINE_VERSION).tar.gz
READLINE_DIR:=$(BUILD_DIR)/readline-$(READLINE_VERSION)
READLINE_CAT:=$(ZCAT)
READLINE_BINARY:=libhistory.a
READLINE_SHARED_BINARY:=libhistory.so
READLINE_TARGET_BINARY:=lib/$(READLINE_BINARY)
READLINE_TARGET_SHARED_BINARY:=lib/$(READLINE_SHARED_BINARY)

$(DL_DIR)/$(READLINE_SOURCE):
	$(WGET) -P $(DL_DIR) $(READLINE_SITE)/$(READLINE_SOURCE)

$(READLINE_DIR)/.unpacked: $(DL_DIR)/$(READLINE_SOURCE)
	$(READLINE_CAT) $(DL_DIR)/$(READLINE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(READLINE_DIR) package/readline/ readline$(READLINE_VERSION_SMALL)-???
	$(CONFIG_UPDATE) $(@D)
	$(CONFIG_UPDATE) $(@D)/support
	touch $@

$(READLINE_DIR)/.configured: $(READLINE_DIR)/.unpacked
	(cd $(READLINE_DIR); rm -rf config.cache; \
		bash_cv_func_sigsetjmp=yes \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--exec-prefix=/usr \
		--bindir=/usr/bin \
		--sbindir=/usr/sbin \
		--libdir=/lib \
		--libexecdir=/usr/lib \
		--sysconfdir=/etc \
		--datadir=/usr/share \
		--localstatedir=/var \
		--with-shared \
		--includedir=/usr/include \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
	)
	touch $@

$(READLINE_DIR)/$(READLINE_BINARY): $(READLINE_DIR)/.configured
	$(MAKE) -C $(READLINE_DIR)
	ls $(READLINE_DIR)/$(READLINE_BINARY)
	touch -c $@

$(STAGING_DIR)/$(READLINE_TARGET_BINARY): $(READLINE_DIR)/.configured
	$(MAKE) -C $(READLINE_DIR) install
	touch -c $@

# Install to Staging area
$(STAGING_DIR)/usr/include/readline/readline.h: $(READLINE_DIR)/$(READLINE_BINARY)
	BUILD_CC=$(TARGET_CC) HOSTCC="$(HOSTCC)" CC=$(TARGET_CC) \
	$(MAKE1) DESTDIR=$(STAGING_DIR) -C $(READLINE_DIR) install
	touch -c $@

# Install to Target directory
$(TARGET_DIR)/$(READLINE_TARGET_SHARED_BINARY): $(READLINE_DIR)/$(READLINE_BINARY)
	# make sure we don't end up with lib{readline,history}...old
	$(MAKE1) DESTDIR=$(TARGET_DIR) -C $(READLINE_DIR) uninstall
	BUILD_CC=$(TARGET_CC) HOSTCC="$(HOSTCC)" CC=$(TARGET_CC) \
	$(MAKE1) DESTDIR=$(TARGET_DIR) \
		-C $(READLINE_DIR) install-shared uninstall-doc

readline: ncurses $(STAGING_DIR)/usr/include/readline/readline.h

readline-source: $(DL_DIR)/$(READLINE_SOURCE)

readline-clean:
	$(MAKE) -C $(READLINE_DIR) DESTDIR=$(STAGING_DIR) uninstall
	-$(MAKE) -C $(READLINE_DIR) clean

readline-dirclean:
	rm -rf $(READLINE_DIR)

readline-target: $(TARGET_DIR)/$(READLINE_TARGET_SHARED_BINARY)

readline-target-clean:
	$(MAKE1) DESTDIR=$(TARGET_DIR) -C $(READLINE_DIR) uninstall

ifeq ($(BR2_PACKAGE_READLINE),y)
TARGETS+=readline
endif
ifeq ($(BR2_PACKAGE_READLINE_TARGET),y)
TARGETS+=readline-target
endif
