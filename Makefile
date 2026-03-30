TARGET := iphone:clang:latest:14.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = YouTube

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Focus

Focus_FILES = CustomFocus.x
Focus_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
