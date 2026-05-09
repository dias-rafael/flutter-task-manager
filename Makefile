pods:
	cd ios && \
	rm -rf Pods Podfile.lock && \
	pod repo update && \
	pod install

pub get:
	rm -rf pubspec.lock && \
	flutter clean && \
	flutter pub get && \
	$(MAKE) pods

generate:
	dart run build_runner build --delete-conflicting-outputs