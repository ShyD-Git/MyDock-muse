TARGET := iphone:clang:latest:15.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TeproMock

TeproMock_FILES = Tweak.x
TeproMock_CFLAGS = -fobjc-arc -Wno-error=deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
