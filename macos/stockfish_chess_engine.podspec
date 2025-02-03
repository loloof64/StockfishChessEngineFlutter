#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint stockfish_chess_engine.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'stockfish_chess_engine'
  s.version          = '0.0.1'
  s.summary          = 'Use Stockfish chess engine directly in your Flutter project.'
  s.description      = <<-DESC
Use Stockfish chess engine directly in your Flutter project.
                       DESC
  s.homepage         = 'https://github.com/loloof64'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Laurent Bernabe' => 'laurent.bernabe@gmail.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  
  s.xcconfig = {
    #-- add the path to the downloaded nnue files
    'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/stockfish_chess_engine/"',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'OTHER_CFLAGS' => '-fvisibility=default -fvisibility-inlines-hidden',
  }

  s.source_files = 'Classes/**/*.{h,c,cpp}', '../src/**/*.{h,c,cpp}'
  
  #-- download nnue files
  s.script_phases = [
    {
      :name => 'Download Stockfish NNUE files',
      :execution_position => :before_compile,
      :script => <<-SCRIPT
        # setup variables
        NNUE_NAME="nn-5af11540bbfe.nnue"
        DOWNLOAD_BASE_URL="https://tests.stockfishchess.org/api/nn"
        DEST_DIR="${PODS_ROOT}/stockfish_chess_engine/"

        # download
        mkdir -p $DEST_DIR
        curl -L -o "$DEST_DIR/$NNUE_NAME" "$DOWNLOAD_BASE_URL/$NNUE_NAME"
      SCRIPT
    }
  ]
  
  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'stockfish_chess_engine_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
