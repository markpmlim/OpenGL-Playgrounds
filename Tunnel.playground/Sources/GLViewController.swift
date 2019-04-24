import Cocoa
import OpenGL.GL3
import GLKit

public class SPOpenGLView: NSOpenGLView {
    let shader = GLShader()
    var quadVAO: GLuint = 0
    var stopClock =  Clock()
    var timeLoc: GLint = 0
    var resolutionLoc: GLint = 0
    var factorLoc: GLint = 0
    var fadeFactor: GLfloat = 0
    var fadeFactorDelta: GLfloat = 0

    // This is required
    public override init?(frame frameRect: NSRect,
                          pixelFormat format: NSOpenGLPixelFormat?) {

        super.init(frame: frameRect, pixelFormat: format)
        let glContext = NSOpenGLContext(format: pixelFormat!,
                                        share: nil)
        //Swift.print("OpenGLView init")
        self.openGLContext = glContext
        //Swift.print(self.openGLContext)
        self.openGLContext!.makeCurrentContext()
    }

    // This is required or XCode will not compiled.
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Setup the entire environment for OpenGL.
    override public func prepareOpenGL() {
        //Swift.print("prepareOpenGL")
        super.prepareOpenGL()
        // First load and compile the OpenGL shaders
        var shaderIDs = [GLuint]()
        var shaderID = shader.compileShader(filename: "tunnel.vs",
                                            shaderType: GLenum(GL_VERTEX_SHADER))
        shaderIDs.append(shaderID)
        shaderID = shader.compileShader(filename: "tunnel.fs",
                                        shaderType: GLenum(GL_FRAGMENT_SHADER))
        shaderIDs.append(shaderID)
        shader.createAndLinkProgram(shaders: shaderIDs)

        // These are for the render method.
        timeLoc = glGetUniformLocation(shader.program, "time")
        resolutionLoc = glGetUniformLocation(shader.program, "resolution")
        factorLoc = glGetUniformLocation(shader.program, "factor")
        fadeFactor = 0.0
        fadeFactorDelta = 0.05

        createGeometry()
   }

    override public func reshape() {
        //Swift.print("reshape")
        super.reshape()
        self.render(elapsedTime: stopClock.timeElapsed())
    }

    override public func draw(_ dirtyRect: NSRect) {
        //Swift.print("drawRect")
        render(elapsedTime: stopClock.timeElapsed())
     }

    // This method must be called repeatedly. An instance of NSTimer
    // will send the "render" message to the instance of SPOpenGLView
    // at 60 frames/second.
    func render(elapsedTime: Double) {
        //Swift.print("render")
        openGLContext!.makeCurrentContext()
        CGLLockContext(openGLContext!.cglContextObj!)

        glClear(GLenum(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glViewport(0, 0, GLsizei(frame.width), GLsizei(frame.height))
        // Set the background to gray to indicate the render method had been
        // called in case the shaders are not working properly.
        glClearColor(0.5, 0.5, 0.5, 1.0)

        shader.use()
        glUniform1f(timeLoc, GLfloat(elapsedTime))
        glUniform1f(factorLoc, fadeFactor)
        var viewPort = [GLint](repeating: 0, count: 4)
        glGetIntegerv(GLenum(GL_VIEWPORT), &viewPort)
        glUniform2f(resolutionLoc,
                    GLfloat(viewPort[2]), GLfloat(viewPort[3]))

        glBindVertexArray(quadVAO)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        glBindVertexArray(0)
        glUseProgram(0)
        fadeFactor = max(0, min(1, fadeFactor + fadeFactorDelta))

        openGLContext!.update()
        // we're double buffered so need to flush to screen
        openGLContext!.flushBuffer()
        CGLUnlockContext(openGLContext!.cglContextObj!)
    }

    // The rendered object appears to be open box
    func createGeometry() {
        // size = 24 bytes; GLKVectors may not be compatible.
        struct Vertex {
            let position: (GLfloat, GLfloat, GLfloat, GLfloat)  // 16 bytes
            let uv: (GLfloat, GLfloat)                          //  8 bytes
        }

        let vertices: [Vertex] = [
            Vertex(position: (-1.0, 1.0, 0.0, 1.0),   uv: (0.0, 1.0)),
            Vertex(position: (1.0, 1.0, 0.0, 1.0),    uv: (1.0, 1.0)),
            Vertex(position: (-1.0, -1.0, 0.0, 1.0),  uv: (0.0, 0.0)),
            Vertex(position: (-1.0, -1.0, 0.0, 1.0),  uv: (0.0, 0.0)),
            Vertex(position: (1.0, 1.0, 0.0, 1.0),    uv: (1.0, 1.0)),
            Vertex(position: (1.0, -1.0, 0.0, 1.0),   uv: (1.0, 0.0))
        ]

        // The geometry of the quad is embedded in the vertex shader
        // but OpenGL needs to bind a vertex array object (VAO).
        glGenVertexArrays(1, &quadVAO)
        glBindVertexArray(quadVAO)
        var vboId: GLuint = 0
        glGenBuffers(1, &vboId)                         // Create the buffer ID, this is basically the same as generating texture ID's
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vboId)    // Bind the buffer (vertex array data)

        glBufferData(GLenum(GL_ARRAY_BUFFER),
                     MemoryLayout<Vertex>.size*vertices.count,
                     vertices, GLenum(GL_STATIC_DRAW))
        let positionAttr = UnsafeRawPointer(bitPattern: 0)
        glVertexAttribPointer(0,                        // attribute
                              4,                        // size
                              GLenum(GL_FLOAT),         // type
                              GLboolean(GL_FALSE),      // don't normalize
                              GLsizei(MemoryLayout<Vertex>.size),  // stride
                              positionAttr)             // array buffer offset
        let uvAttr = UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.stride*4)
        glEnableVertexAttribArray(0)
        glVertexAttribPointer(1,
                              2,
                              GLenum(GL_FLOAT),
                              GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<Vertex>.size),
                              uvAttr)
        glEnableVertexAttribArray(1)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindVertexArray(0)
   }

    // This is required to provide animation
    func startTimer() {
        let framesPerSecond = 60
        let timeInterval = 1.0/Double(framesPerSecond)
        Timer.scheduledTimer(timeInterval: timeInterval,
                                               target: self,
                                               selector: #selector(SPOpenGLView.onTimer(_:)),   //selector: "onTimer:",
                                               userInfo: nil,
                                               repeats: true)
    }

    // Prepend with "@objc" so that Cocoa's NSTimer will see it.
    @objc func onTimer(_ timer: Timer!) {
        //Swift.print("Timer here")
        render(elapsedTime: stopClock.timeElapsed())
    }
}

public final class SPViewController: NSViewController {

    // This must be implemented
    override public func loadView() {
        //Swift.print("loadView")
        let frameRect = NSRect(x: 0, y: 0,
                               width: 480, height: 270)
        self.view = NSView(frame: frameRect)

        let pixelFormatAttrsBestCase: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFADoubleBuffer),
            UInt32(NSOpenGLPFAAccelerated),
            UInt32(NSOpenGLPFABackingStore),
            UInt32(NSOpenGLPFADepthSize), UInt32(24),
            UInt32(NSOpenGLPFAOpenGLProfile), UInt32(NSOpenGLProfileVersion4_1Core),
            UInt32(0)
        ]

        let pf = NSOpenGLPixelFormat(attributes: pixelFormatAttrsBestCase)
        if (pf == nil) {
            fatalError("Couldn't init OpenGL at all, sorry :(")
        }
        let openGLView = SPOpenGLView(frame: frameRect,
                                      pixelFormat: pf)
        self.view.addSubview(openGLView!)
        openGLView!.startTimer()
        //Swift.print(self.openGLView)
    }

    override public func viewDidLoad() {
        //Swift.print("viewDidLoad")
        super.viewDidLoad()
    }
 }

class Clock {
    private static var kNanoSecondConvScale: Double = 1.0e-9
    private var machTimebaseInfoRatio: Double = 0
    private var startTime = 0.0

    init() {
        var timebaseInfo = mach_timebase_info_data_t()
        timebaseInfo.numer = 0
        timebaseInfo.denom = 0
        let err = mach_timebase_info(&timebaseInfo)
        if err != KERN_SUCCESS {
            Swift.print(">> ERROR: \(err) getting mach timebase info!")
        }
        else {
            let numer = Double(timebaseInfo.numer)
            let denom = Double(timebaseInfo.denom)
            
            // This gives the resolution
            machTimebaseInfoRatio = Clock.kNanoSecondConvScale * (numer/denom)
            startTime = Double(mach_absolute_time())        // in nano seconds
        }
    }

    // Return the elapsed time in seconds
    func timeElapsed() -> Double {
        let currentTime = Double(mach_absolute_time())      // in nano seconds
        let elapsedTime = currentTime - startTime           // in nano seconds
        return elapsedTime * machTimebaseInfoRatio
    }
}
