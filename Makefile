APP_NAME = Wipe
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS
RESOURCES = $(CONTENTS)/Resources

.PHONY: build bundle install clean run

build:
	swift build -c release

bundle: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(MACOS) $(RESOURCES)
	cp $(BUILD_DIR)/$(APP_NAME) $(MACOS)/
	cp Info.plist $(CONTENTS)/
	@if [ -f Resources/AppIcon.icns ]; then cp Resources/AppIcon.icns $(RESOURCES)/; fi
	codesign --force --sign - --entitlements Wipe.entitlements $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

install: bundle
	cp -R $(APP_BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP_BUNDLE)"

clean:
	rm -rf $(APP_BUNDLE) .build

run: bundle
	open $(APP_BUNDLE)
