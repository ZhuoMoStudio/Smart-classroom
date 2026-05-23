[app]

title = 灵动课堂
package.name = smartclassroom
package.domain = org.example
source.dir = .
source.include_exts = py,png,jpg,kv,atlas,json
version = 2.5
requirements = python3,kivy==2.3.0
icon.filename = assets/icon.png
orientation = all
fullscreen = 0
android.permissions = INTERNET
android.api = 34
android.minapi = 24
android.ndk = 28c
android.accept_sdk_license = True
android.archs = arm64-v8a

osx.python_version = 3
osx.kivy_version = 2.3.0

ios.kivy_ios_url = https://github.com/kivy/kivy-ios
ios.kivy_ios_branch = master
ios.ios_deploy_url = https://github.com/phonegap/ios-deploy
ios.ios_deploy_branch = 1.10.0
ios.codesign.allowed = false

[buildozer]
log_level = 2
warn_on_root = 1