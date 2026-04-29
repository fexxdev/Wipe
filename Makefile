APP_NAME = Wipe
VERSION = 1.0.0
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
DMG_NAME = $(APP_NAME)-$(VERSION).dmg
CONTENTS = $(APP_BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS
RESOURCES = $(CONTENTS)/Resources

.PHONY: build bundle install dmg clean run

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

dmg: bundle
	rm -rf .dmg-stage $(DMG_NAME)
	mkdir -p .dmg-stage
	cp -R $(APP_BUNDLE) .dmg-stage/
	ln -s /Applications .dmg-stage/Applications
	hdiutil create -volname "$(APP_NAME)" -srcfolder .dmg-stage \
		-ov -format UDZO $(DMG_NAME)
	rm -rf .dmg-stage
	@echo "Created $(DMG_NAME)"

clean:
	rm -rf $(APP_BUNDLE) .build .dmg-stage *.dmg

run: bundle
	open $(APP_BUNDLE)
