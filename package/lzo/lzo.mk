#############################################################
#
# lzo
#
# Note: this builds only a static library, it does not provide
# anything to be installed into the target system.
#
#############################################################
ifeq ($(BR2_PACKAGE_LZO_BIG),y)

LZO_VERSION:=1.08
LZO_SOURCE:=lzo_$(LZO_VERSION).orig.tar.gz
LZO_SITE:=$(BR2_DEBIAN_MIRROR)/debian/pool/main/l/lzo
#LZO_SOURCE:=lzo-$(LZO_VERSION).tar.bz2
#LZO_SITE:=http://www.oberhumer.com/opensource/lzo/download
LZO_DIR:=$(BUILD_DIR)/lzo-$(LZO_VERSION)
LZO_CAT:=$(ZCAT)

$(DL_DIR)/$(LZO_SOURCE):
	 $(WGET) -P $(DL_DIR) $(LZO_SITE)/$(LZO_SOURCE)

$(LZO_DIR)/.unpacked: $(DL_DIR)/$(LZO_SOURCE)
	$(LZO_CAT) $(DL_DIR)/$(LZO_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(LZO_DIR) package/lzo/ lzo\*.patch
	$(CONFIG_UPDATE) $(@D)/acconfig
	$(SED) 's,CFLAGS="$$CFLAGS -O[0123456789]",CFLAGS="$$CFLAGS",g' $(LZO_DIR)/configure
	touch $@

LZO_CONFIG_SHARED:=--disable-shared
#LZO_CONFIG_SHARED:=--enable-shared

$(LZO_DIR)/.configured: $(LZO_DIR)/.unpacked
	(cd $(LZO_DIR); rm -rf config.cache; \
		$(AUTO_CONFIGURE_TARGET) \
		--prefix=/usr \
		--includedir=/usr/include \
		--libdir=/usr/lib \
		$(LZO_CONFIG_SHARED) \
	)
	touch $@

$(LZO_DIR)/src/liblzo.la: $(LZO_DIR)/.configured
	$(MAKE) -C $(LZO_DIR)

$(STAGING_DIR)/usr/lib/liblzo.a: $(LZO_DIR)/src/liblzo.la
	$(MAKE) CC="$(TARGET_CC)" DESTDIR=$(STAGING_DIR) -C $(LZO_DIR) install
	$(SED) "s,^libdir=.*,libdir=\'$(STAGING_DIR)/usr/lib\',g" $(STAGING_DIR)/usr/lib/liblzo.la
	touch -c $@

lzo: uclibc $(STAGING_DIR)/usr/lib/liblzo.a

lzo-source: $(DL_DIR)/$(LZO_SOURCE)

lzo-clean:
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(LZO_DIR) uninstall
	-$(MAKE) -C $(LZO_DIR) clean

lzo-dirclean:
	rm -rf $(LZO_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################

TARGETS+=lzo
endif
