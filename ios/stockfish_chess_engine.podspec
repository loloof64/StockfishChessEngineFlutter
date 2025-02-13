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
    'GCC_PREPROCESSOR_DEFINITIONS' => "IS_MOBILE_TARGET=1",
    #-- add the path to the downloaded nnue files
    'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/stockfish_chess_engine/"',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'OTHER_CFLAGS' => '-fvisibility=default -fvisibility-inlines-hidden',
  }

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-lstdc++'
  }

  s.source_files = 'Classes/**/*.{h,c,cpp}'
  s.public_header_files = 'Classes/**/*.h'
  
  #-- download nnue files
  s.script_phases = [
    {
      :name => 'Download Stockfish NNUE files',
      :execution_position => :before_compile,
      :script => <<-SCRIPT
        # setup variables
        NNUE_NAME_SMALL="nn-37f18f62d772.nnue"
        DOWNLOAD_BASE_URL="https://tests.stockfishchess.org/api/nn"
        DEST_DIR="${PODS_ROOT}/stockfish_chess_engine/"

        # download
        mkdir -p $DEST_DIR
        curl -L -o "$DEST_DIR/$NNUE_NAME_SMALL" "$DOWNLOAD_BASE_URL/$NNUE_NAME_SMALL"
      SCRIPT
    }
  ]

  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'
end
