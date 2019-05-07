Rationale for this project:

A search on the Internet indicates there are no Swift Playgrounds running OpenGL programs. This set of Swift Playgrounds can be a Starter kit for beginners who would like to learn OpenGL 4.1 on a computer running macOS 10.11 or later.

Description:

The project was developed incrementally in the following order:

 1)  MonoChrome.playground
 2)  HelloWorld.playground
 3)  HelloWorld4.playground
 4)  InterpolatedColors.playground
 5)  Tunnel.playground
 6)  Texture2D.playground
 7)  ColoredCube.playground
 8)  TextureCubemap.playground
 9)  TextureCubemap2.playground
10)  TextureCubemap4.playground
11)  LoadModel.playground

The first playground (MonoChrome.playground) is especially important because it not only forms the basis of developing more complex OpenGL programs running as Swift Playgrounds but explains how an instance of a sub-class of NSViewController and NSOpenGLView are instantiated.

Almost all the Swift Playgrounds one finds on the Internet would create a view (NSView, MTKView, SCNView etc) or one of their sub-classes. Then a statement like:

XCPlaygroundPage.currentPage.liveView = view
(or PlaygroundPage.current.liveView = view   // XCode 8.x or later)

is used to display the contents of the view. But things are not so straightforward when dealing with a specialised view class like NSOpenGLView. Setting the "liveView" property with a Swift language statement like this:

XCPlaygroundPage.currentPage.liveView = openGLView

where "openGLView" is an instance of NSOpenGLView or one of its sub-classes might end up with no display.

That line of code will work only by overriding both the initializer "initWithFrame:pixelFormat:" and "prepareOpenGL" methods of NSOpenGLView. Apple's implementation of OpenGL as part of the initialisation process call the overridden method "prepareOpenGL" call. The programmer must implement this latter method in order to complete the setup of the entire environment for his program. Normally, this includes 

a) loading or creating geometries, converting the data into vertex attributes, 
b) instantiation of OpenGL textures either programmatically or from graphic files,
c) loading shaders and creating shader programs etc.

The documentation of XCPlayground/PlaygroundSupport indicates that a view controller can be also be assigned to the "liveView" property. (To see this documentation look for the line "import XCPlayground" or "import PlaygroundSupport" and click on the second word.)

For this set of playgrounds, a view controller is used to manage the initialization of the sub-class of NSOpenGLView is implemented. Unlike a normal macOS application project where storyboard(s) or Interface Builder files are used, the view controller must be instantiated using an overridden "loadView" method. An instance of NSView or one of its sub-classes must be created programmatically and assigned to the view controller's "view" property. See the source code for the class SPViewController.


Notes on the various playground

HelloWorld.playground: Renders the graphic equivalent of Hello, World using Modern OpenGL.

HelloWorld4.playground: Renders the graphic equivalent of Hello, World using function calls introduced in OpenGL 4.x. 


InterpolatedColors.playground: The color attribute at the 4 vertices of the quad (rectangle) is passed to the fragment shader. An interpolated value is sent by OpenGL's rasterizer, to the fragment shader.


Tunnel.playground: Renders a tunnel using a pair of shaders from Apple's WWDC 2014 project. An instance of NSTimer is required to provide animation effects. A time-elapsed quantity (based on the starting time of execution of the playground) is passed to the fragment shader.


Texture2D.playground: Calls a method of the class GLKTextureLoader to instantiate an OpenGL texture object. This method returns an instance of GLKTextureInfo whose "name" property can be be passed to an OpenGL fragment shader.


ColoredCube.playground: A simple demo to send vertex data to the vertex shader. Functions of the GLKit math class are used to supply matrix data to the shaders. In particular, the contents of the model matrix is changed per frame and needs to be updated.


TextureCubemap.playground: Instead of sending the color attribute of a vertex down the graphics pipeline, a cube map texture is created programmatically. During a frame update, its texture name (textureID) is bind to the fragment shader.


TextureCubemap2.playground: The cube map texture is created from a graphic whose width is 6x its height.


TextureCubemap4.playground: The cube map texture is created from 6 graphic images in the order specified in Apple’s documentation. Function calls introduced in OpenGL 4.x are used in the rendering of the textured cube.


LoadModel.playground: A simple demo to use ModelIO methods to load a wavefront (.obj) file. The vertex data (position, normal and texture coordinates) and index data are extracted and uploaded to the GPU using OpenGL functions. In particular, the macOS 10.12 introduced method 

    addUnwrappedTextureCoordinatesForAttributeNamed:

is utilised to ensure the mesh will have generated texture coordinates if this vertex attribute is missing from the initial MDLMesh object instantiated during loading of the asset.
An MDLAsset method introduced in macOS 10.12

    childObjectsOfClass:

is used to check that the loaded asset has instances of MDLMesh. The 10.11.x playground can not utilised these 2 methods.

Being a simple demo, this playground does not handle multiple instances of MDLMesh and MDLSubmesh. Nor it handle the creation of textures.


Additional Notes:
All the playgrounds of this set should run without problems on macOS 10.12.x, XCode 8.3.2 or later.
Some may work with macOS 10.10.x, XCode 7.2. Porting back to XCode 7.x or 6.x will require some effort because there are major changes to the Swift interfaces especially going from Swift 3.x to Swift 2.x.

A compressed set of playgrounds which runs on XCode 7.3.1, macOS 10.11.x is provided.