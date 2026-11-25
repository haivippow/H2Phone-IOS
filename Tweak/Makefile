include $(THEOS)/makefiles/common.mk

TWEAK_NAME = H2ChangerHook
H2ChangerHook_FILES = Tweak.xm H2WebFingerprint.m ../App/H2ConfigManager.m
H2ChangerHook_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I$(THEOS_PROJECT_DIR)/App
H2ChangerHook_FRAMEWORKS = UIKit Foundation WebKit AdSupport CoreLocation CoreTelephony CoreMotion

include $(THEOS_MAKE_PATH)/tweak.mk
