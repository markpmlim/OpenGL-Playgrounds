
import Cocoa
import OpenGL.GL3

public class SPOpenGLView: NSOpenGLView {
    var quadVAO: GLuint = 0
    var stopClock =  Clock()
    var resolutionLoc: GLint = 0
    let shader = GLShader()
    var programs = [String: GLuint]()       // Dictionary where the key is String, value GLuint
    var pipelineName: GLuint = 0

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

    override public func prepareOpenGL() {
        //Swift.print("prepareOpenGL")
        super.prepareOpenGL()
        // Instead of an array, using a dictionary is clearer.
        programs["hello_world.vs"] = shader.compileProgram("hello_world.vs",
                                                           shaderType: GLenum(GL_VERTEX_SHADER))
        programs["hello_world.fs"] = shader.compileProgram("hello_world.fs",
                                                           shaderType: GLenum(GL_FRAGMENT_SHADER))
        resolutionLoc = glGetUniformLocation(programs["hello_world.fs"]!, "resolution")
        
        glGenProgramPipelines(1, &pipelineName)
        glBindProgramPipeline(pipelineName)
        glUseProgramStages(pipelineName, GLbitfield(GL_VERTEX_SHADER_BIT), programs["hello_world.vs"]!)
        glUseProgramStages(pipelineName, GLbitfield(GL_FRAGMENT_SHADER_BIT), programs["hello_world.fs"]!)
        
        glGenVertexArrays(1, &quadVAO)
        glBindVertexArray(0)
   }

    override public func reshape() {
        //Swift.print("reshape")
        super.reshape()
        self.render(elapsedTime: stopClock.timeElapsed())
    }

     override public func draw(_ dirtyRect: NSRect) {
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

        // We are using a program pipeline so we can use the preferred method
        // to pass parameters to our separate program objects.
        glProgramUniform2f(programs["hello_world.fs"]!,
                           resolutionLoc,
                           GLfloat(frame.width), GLfloat(frame.height))
        glBindProgramPipeline(pipelineName)
        glBindVertexArray(quadVAO)
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        glBindVertexArray(0)
        glBindProgramPipeline(0)

        openGLContext!.update()
        // we're double buffered so need to flush to screen
        openGLContext!.flushBuffer()
        CGLUnlockContext(openGLContext!.cglContextObj!)
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
        } // if
        else
        {
            let numer = Double(timebaseInfo.numer)
            let denom = Double(timebaseInfo.denom)
            
            // This gives the resolution
            machTimebaseInfoRatio = Clock.kNanoSecondConvScale * (numer/denom)
            startTime = Double(mach_absolute_time())        // in nano seconds
        } // else
    }

    // Return the elapsed time in seconds
    func timeElapsed() -> Double {
        let currentTime = Double(mach_absolute_time())      // in nano seconds
        let elapsedTime = currentTime - startTime           // in nano seconds
        return elapsedTime * machTimebaseInfoRatio          // in seconds
    }
}
