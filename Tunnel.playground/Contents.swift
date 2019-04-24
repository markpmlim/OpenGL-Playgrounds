// Swift playground project to demonstrate how to setup
// an OpenGL environment.
// An instance of NSTimer is added to support animation. The
// "render:" method of SPOpenGLView will be called repeatedly.
// Requirements: XCode 8.3.2 macOS 10.12.x or later.
// The vertex-fragment shaders are from Apple's SceneKit WWDC 2014 Demo.

import PlaygroundSupport

// Create instance of ViewController and ...
let vc = SPViewController()
// ... tell playground to show it in live view
PlaygroundPage.current.liveView = vc
