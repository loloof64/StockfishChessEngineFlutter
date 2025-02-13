# Instructions in order to upgrade Stockfish version

## First word of caution

As the Stockfish source code evolves, this guide is not 100% warranted that the changes will have to be made exactly as defined.
So it's better if you have C++/Cmake and little Podspec scripts knowledge before starting to make changes.

## First setup

Create a folder **Stockfish** inside **src** folder, copy the **src** folder from the stockfish sources into the new **Stockfish** folder (and also replace the readme file for Stockfish).

## Adapting streams

- replace all calls to `cout << #SomeContent# << endl` by `fakeout << #SomeContent# << fakeendl` (without the std:: prefix if any) (And ajust also calls to `cout.rdbuf()` by `fakeout.rdbuf()`) **But do not replace calls to sync_cout** add include to **../../fixes/fixes.h** in all related files (and adjust the include path accordingly). Do the same for calls to `cout.#method#`. Don't forget to replace calls to `endl` (with or without std:: prefix) : once more just `endl`not `sync_endl`
- proceed accordingly for `cin` : replace by `fakein`
- and the same for `cerr`: replace by `fakeerr`
- in **misc.h** replace

```cpp
#define sync_cout std::cout << IO_LOCK
#define sync_endl std::endl << IO_UNLOCK
```

with

```cpp
#define sync_cout fakeout << IO_LOCK
#define sync_endl fakeendl << IO_UNLOCK
```

and include **../../fixes/fixes.h** (if not already done)

## Adding main.h source file

Add the file **src/Stockfish/src/main.h** with the following content :
```cpp
#ifndef __MAIN_H__
#define __MAIN_H__

int main(int argc, char* argv[]);

#endif // __MAIN_H__
```

and replace **main.cpp** so that it includes this new file.

## Loading only small NNUE file on mobile devices

By default, there is a big NNUE file (at least above 100Mb), and a small NNUE file (less than 10 Mb).
So it's better to restrict download to small NNUE file on small devices.

### engine.cpp

In file **src/Stockfish/src/engine.cpp** :

- adapt the constructor :

```cpp
Engine::Engine(std::string path) :
    binaryDirectory(CommandLine::get_binary_directory(path)),
    numaContext(NumaConfig::from_system()),
    states(new std::deque<StateInfo>(1)),
    threads(),
    networks(
      numaContext,
      NN::Networks(
        #ifndef IS_MOBILE_TARGET
        NN::NetworkBig({EvalFileDefaultNameBig, "None", ""}, NN::EmbeddedNNUEType::BIG),
        #endif
        NN::NetworkSmall({EvalFileDefaultNameSmall, "None", ""}, NN::EmbeddedNNUEType::SMALL))) {
    pos.set(StartFEN, false, &states->back());
    capSq = SQ_NONE;
```

- adapt the options EvalFile and EvalFileSmall :

```cpp
#ifdef IS_MOBILE_TARGET
    options["EvalFile"] << Option(EvalFileDefaultNameSmall, [this](const Option& o) {
        load_small_network(o);
        return std::nullopt;
    });
    #else
    options["EvalFile"] << Option(EvalFileDefaultNameBig, [this](const Option& o) {
        load_small_network(o);
        return std::nullopt;
    });
    options["EvalFileSmall"] << Option(EvalFileDefaultNameSmall, [this](const Option& o) {
        load_small_network(o);
        return std::nullopt;
    });
    #endif
```

- adapt the function verify_networks :

```cpp
void Engine::verify_networks() const {
    #ifndef IS_MOBILE_TARGET
    networks->big.verify(options["EvalFile"]);
    networks->small.verify(options["EvalFileSmall"]);
    #else
    networks->small.verify(options["EvalFile"]);
    #endif
}
```

- adapt the function load_networks :

```cpp
void Engine::load_networks() {
    networks.modify_and_replicate([this](NN::Networks& networks_) {
        #ifndef IS_MOBILE_TARGET
        networks_.big.load(binaryDirectory, options["EvalFile"]);
        networks_.small.load(binaryDirectory, options["EvalFileSmall"]);
        #else
        networks_.small.load(binaryDirectory, options["EvalFile"]);
        #endif
    });
    threads.clear();
    threads.ensure_network_replicated();
}
```

- inactivate conditionnaly the function load_big_network :

```cpp
#ifndef IS_MOBILE_TARGET
void Engine::load_big_network(const std::string& file) {
    networks.modify_and_replicate(
      [this, &file](NN::Networks& networks_) { networks_.big.load(binaryDirectory, file); });
    threads.clear();
    threads.ensure_network_replicated();
}
#endif
```

- adapt the function save_network :

```cpp
void Engine::save_network(const std::pair<std::optional<std::string>, std::string> files[2]) {
    networks.modify_and_replicate([&files](NN::Networks& networks_) {
        #ifndef IS_MOBILE_TARGET
        networks_.big.save(files[0].first);
        #endif
        networks_.small.save(files[1].first);
    });
}
```

### evaluate.cpp

In file **src/Stockfish/src/evaluate.cpp** :

#### Function Eval.evaluate

- adapt the computation of array [psqt, positional] :

```cpp
#ifndef IS_MOBILE_TARGET
auto [psqt, positional] = smallNet ? networks.small.evaluate(pos, &caches.small)
                                    : networks.big.evaluate(pos, &caches.big);
#else
auto [psqt, positional] = networks.small.evaluate(pos, &caches.small);
#endif
```

- remove condtionnaly the position reevaluation done with the big NNUE :

```cpp
#ifndef IS_MOBILE_TARGET
// Re-evaluate the position when higher eval accuracy is worth the time spent
if (smallNet && (nnue * psqt < 0 || std::abs(nnue) < 227))
{
    std::tie(psqt, positional) = networks.big.evaluate(pos, &caches.big);
    nnue                       = (125 * psqt + 131 * positional) / 128;
    smallNet                   = false;
}
#endif
```

#### Function Eval.trace

Adapt the computation of the array [psqt, positional] :

```cpp
#ifdef IS_MOBILE_TARGET
auto [psqt, positional] = networks.small.evaluate(pos, &caches->small);
#else
auto [psqt, positional] = networks.big.evaluate(pos, &caches->big);
#endif
```

### File evaluate.h

In file **src/Stockfish/src/evaluate.h**, remove conditionnaly the name of the big nnue, for example :

```cpp
#ifndef IS_MOBILE_TARGET
#define EvalFileDefaultNameBig "nn-1111cefa1111.nnue"
#endif
```

### File network.cpp

In file **src/Stockfish/src/network.cpp** :

- remove the incbin of the big nnue :

```cpp
#if !defined(_MSC_VER) && !defined(NNUE_EMBEDDING_OFF)
#ifndef IS_MOBILE_TARGET
INCBIN(EmbeddedNNUEBig, EvalFileDefaultNameBig);
#endif
INCBIN(EmbeddedNNUESmall, EvalFileDefaultNameSmall);
#else
#ifndef IS_MOBILE_TARGET
const unsigned char        gEmbeddedNNUEBigData[1]   = {0x0};
const unsigned char* const gEmbeddedNNUEBigEnd       = &gEmbeddedNNUEBigData[1];
const unsigned int         gEmbeddedNNUEBigSize      = 1;
#endif
const unsigned char        gEmbeddedNNUESmallData[1] = {0x0};
const unsigned char* const gEmbeddedNNUESmallEnd     = &gEmbeddedNNUESmallData[1];
const unsigned int         gEmbeddedNNUESmallSize    = 1;
#endif
```

- adapt the function get_embedded :

```cpp
EmbeddedNNUE get_embedded(EmbeddedNNUEType type) {
    #ifndef IS_MOBILE_TARGET
    if (type == EmbeddedNNUEType::BIG)
        return EmbeddedNNUE(gEmbeddedNNUEBigData, gEmbeddedNNUEBigEnd, gEmbeddedNNUEBigSize);
    else
    #endif
        return EmbeddedNNUE(gEmbeddedNNUESmallData, gEmbeddedNNUESmallEnd, gEmbeddedNNUESmallSize);
}
```

- remove the explicit big NNUE template instantiation :

```cpp
#ifndef IS_MOBILE_TARGET
template class Network<
  NetworkArchitecture<TransformedFeatureDimensionsBig, L2Big, L3Big>,
  FeatureTransformer<TransformedFeatureDimensionsBig, &StateInfo::accumulatorBig>>;
#endif
```

### File network.h

In file **src/Stockfish/src/network.h** :

- adapt the enum

```cpp
enum class EmbeddedNNUEType {
  #ifndef IS_MOBILE_TARGET
    BIG,
  #endif
    SMALL,
};
```

- remove big nnue variables conditionnaly :

```cpp
#ifndef IS_MOBILE_TARGET
using BigFeatureTransformer =
  FeatureTransformer<TransformedFeatureDimensionsBig, &StateInfo::accumulatorBig>;
using BigNetworkArchitecture = NetworkArchitecture<TransformedFeatureDimensionsBig, L2Big, L3Big>;
#endif

#ifndef IS_MOBILE_TARGET
using NetworkBig   = Network<BigNetworkArchitecture, BigFeatureTransformer>;
#endif
using NetworkSmall = Network<SmallNetworkArchitecture, SmallFeatureTransformer>;
```

- adapt the network struct :

```cpp
struct Networks {
    Networks(
      #ifndef IS_MOBILE_TARGET
      NetworkBig&& nB,
      #endif
       NetworkSmall&& nS
      ) :
      #ifndef IS_MOBILE_TARGET
        big(std::move(nB)),
      #endif
        small(std::move(nS)) {}

    #ifndef IS_MOBILE_TARGET
    NetworkBig   big;
    #endif
    NetworkSmall small;
};
```

### File nnue_accumulator.h

In file **src/Stockfish/src/nnue_accumulator.h** :

- adapt the clear template :

```cpp
template<typename Networks>
    void clear(const Networks& networks) {
        #ifndef IS_MOBILE_TARGET
        big.clear(networks.big);
        #endif
        small.clear(networks.small);
    }
```
- remove the big cache conditionnaly :

```cpp
#ifndef IS_MOBILE_TARGET
Cache<TransformedFeatureDimensionsBig>   big;
#endif
Cache<TransformedFeatureDimensionsSmall> small;
```

### File nnue_misc.cpp

In file **src/Stockfish/src/nnue_misc.cpp** :

- adapt function hint_common_parent_position :

```cpp
void hint_common_parent_position(const Position&    pos,
                                 const Networks&    networks,
                                 AccumulatorCaches& caches) {
    #ifndef IS_MOBILE_TARGET
    if (Eval::use_smallnet(pos))
    #endif
        networks.small.hint_common_access(pos, &caches.small);
    #ifndef IS_MOBILE_TARGET
    else
        networks.big.hint_common_access(pos, &caches.big);
    #endif
```

#### function trace

- adapt the computation of the array [psqt, positional] :

```cpp
#ifdef IS_MOBILE_TARGET
auto [psqt, positional] = networks.small.evaluate(pos, &caches.small);
#else
auto [psqt, positional] = networks.big.evaluate(pos, &caches.big);
#endif
```

- adapt the computation of the std::tie(psqt, positional) :

```cpp
#ifdef IS_MOBILE_TARGET
std::tie(psqt, positional) = networks.small.evaluate(pos, &caches.small);
#else
std::tie(psqt, positional) = networks.big.evaluate(pos, &caches.big);
#endif
```

- adapt the computation of the t variable :

```cpp
#ifdef IS_MOBILE_TARGET
auto t = networks.small.trace_evaluate(pos, &caches.small);
#else
auto t = networks.big.trace_evaluate(pos, &caches.big);
#endif
```

## Copying code for ios and mac

Then, copy **src/Stockfish** folder to
- folder ios/Classes
- folder macos/Classes

## Adapting code for Windows

* In file **src/Stockfish/misc.cpp** we have to remove call to `_get_pgmptr` as this time Stockfish is not a standalone program.
So, in function `std::string CommandLine::get_binary_directory` remove the matching section :

```cpp
#ifdef _WIN32
    pathSeparator = "\\";
    #ifdef _MSC_VER
    // Under windows argv[0] may not have the extension. Also _get_pgmptr() had
    // issues in some Windows 10 versions, so check returned values carefully.
    char* pgmptr = nullptr;
    if (!_get_pgmptr(&pgmptr) && pgmptr != nullptr && *pgmptr)
        argv0 = pgmptr;
    #endif
#else
    pathSeparator = "/";
#endif
```

and replace with the following :

```cpp
#ifdef _WIN32
    pathSeparator = "\\";
    std::string basePath = "build\\windows\\x64\\runner\\";
    #ifdef NDEBUG
        argv0 = basePath + "Release";
    #else
        argv0 = basePath + "Debug";
    #endif
#else
    pathSeparator = "/";
#endif
```

* In file ***src/Stockfish/uci.cpp***, a lambda function can make the compilation failing, as the MSVC compiler is strictier than GCC. So in function `std::string UCIEngine::format_score`, in the lambda using `TB_CP`, we just need to declare it inside the lambda :

```cpp
const auto    format =
      overload{[](Score::Mate mate) -> std::string {
                   auto m = (mate.plies > 0 ? (mate.plies + 1) : mate.plies) / 2;
                   return std::string("mate ") + std::to_string(m);
               },
               [](Score::Tablebase tb) -> std::string {
                    constexpr int TB_CP = 20000;
                   return std::string("cp ")
                        + std::to_string((tb.win ? TB_CP - tb.plies : -TB_CP - tb.plies));
               },
               [](Score::InternalUnits units) -> std::string {
                   return std::string("cp ") + std::to_string(units.value);
               }};
```

## Adapting the NNUE names

1. Copy the big and small nnue names from **src/Stockfish/src/evaluate.h**
2. Replace their names in file **src/CMakeLists.txt**
3. Also replace their names in file **ios/stockfish_chess_engine.podspec** and **macos/stockfish_chess_engine.podspec**