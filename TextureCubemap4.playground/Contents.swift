// The famous cube with each of the 6 faces shaded
// with a different graphic.
// This demo uses the GLKTextureLoader method
//      cubeMapWithContentsOfFiles:options:error:
// to load and instantiate a texture object that could be
// passed to an OpenGL fragment shader.
// Requirements: XCode 8.3.2 macOS 10.12.x or later.

import PlaygroundSupport

let vc = SPViewController()
PlaygroundPage.current.liveView = vc
