
import Cocoa
import OpenGL.GL3

public class SPOpenGLView: NSOpenGLView {
    let shader = GLShader()
    var quadVAO: GLuint = 0
    var stopClock =  Clock()

    // This is required
    public override init?(frame frameRect: NSRect,
                          pixelFormat format: NSOpenGLPixelFormat?) {

        super.init(frame: frameRect, pixelFormat: format)
        let glContext = NSOpenGLContext(format: pixelFormat!,
                                        share: nil)
        //Swift.print("OpenGLView init")
        self.pixelFormat = pixelFormat!
        self.openGLContext = glContext
        //Swift.print(self.openGLContext)
        self.openGLContext!.makeCurrentContext()
    }

    // This is also required
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // This method will be called when the instantiated
    // OpenGL context is made current.
    override public func prepareOpenGL() {
        //Swift.print("prepareOpenGL")
        super.prepareOpenGL()
        // Test to ensure the OpenGL vertex and fragment shaders
        // are compiled into a program.
        var shaderIDs = [GLuint]()
        var shaderID = shader.compileShader(filename: "passthru.vs",
                                            shaderType: GLenum(GL_VERTEX_SHADER))
        shaderIDs.append(shaderID)
        shaderID = shader.compileShader(filename: "passthru.fs",
                                        shaderType: GLenum(GL_FRAGMENT_SHADER))
        shaderIDs.append(shaderID)
        shader.createAndLinkProgram(shaders: shaderIDs)
        // The geometry of the quad is embedded in the vertex shader but
        // OpenGL needs to bind a vertex array object (VAO) before rendering
        glGenVertexArrays(1, &quadVAO)
   }

    // This method is only called once.
    override public func reshape() {
        //Swift.print("reshape")
        super.reshape()
        self.render(elapsedTime: stopClock.timeElapsed())
    }

    // This method is also called once.
    override public func draw(_ _dirtyRect: NSRect) {
        self.render(elapsedTime: stopClock.timeElapsed())
    }

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
        glBindVertexArray(quadVAO)
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        glBindVertexArray(0)
        glUseProgram(0)

        openGLContext!.update()
        // We're double buffered so need to flush to screen
        openGLContext!.flushBuffer()
        CGLUnlockContext(openGLContext!.cglContextObj!)
    }
}

// This sub-class is use to help setup the sub-class of NSOpenGLView properly.
// This implementation creates an instance of NSView as the parent view and
// adds an instance of a sub-class of NSOpenGLView as a child view.
public final class SPViewController: NSViewController {
 
    // This must be implemented
    override public func loadView() {
        //Swift.print("loadView")
        let frameRect = NSRect(x: 0, y: 0,
                               width: 200, height: 200)
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
        // Alternatively, instantiating the NSView object could be skipped.
        // In this case, create the NSOpenGLView object and assigned it
        // to the view controller's view property:
        //self.view = openGLView!
    }

    // This will be called when the view (an instance of NSView or its sub-class)
    // is created by the loadView method above.
    override public func viewDidLoad() {
        //Swift.print("viewDidLoad")
        super.viewDidLoad()
        // We can configure the view controller further.
    }
 }

// This can be used as a Stop clock.
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
        return elapsedTime * machTimebaseInfoRatio          // in seconds
    }
}
