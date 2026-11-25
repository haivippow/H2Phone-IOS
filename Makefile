export THEOS_PACKAGE_SCHEME = rootless
export TARGET = iphone:clang:latest:16.0
export ARCHS = arm64
INSTALL_TARGET_PROCESSES = H2Changer DeviceTest
SUBPROJECTS = App DeviceTest Tweak

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
