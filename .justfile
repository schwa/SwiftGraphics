prepare:
    git submodule update --init --recursive

build-package:
    swift package clean
    swift build --configuration debug
    swift build --configuration release
    swift test

build-ProjectionDemo:
    xcodebuild -scheme ProjectionDemo -project Examples/ProjectionDemo/ProjectionDemo.xcodeproj -destination 'platform=OS X,arch=x86_64' clean build
    xcodebuild -scheme ProjectionDemo -project Examples/ProjectionDemo/ProjectionDemo.xcodeproj -destination 'generic/platform=iOS' clean build


build-examples:

    xcodebuild -scheme VectorLaboratory -project Examples/VectorLaboratory/VectorLaboratory.xcodeproj build
