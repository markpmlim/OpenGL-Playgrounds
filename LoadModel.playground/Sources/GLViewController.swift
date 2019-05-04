
import Cocoa
import OpenGL.GL3
import GLKit

public class SPOpenGLView: NSOpenGLView {
    let shader = GLShader()
    var stopClock =  Clock()
    var projectionMatrix = GLKMatrix4Identity
    var modelViewMatrix = GLKMatrix4Identity
    var projectionMatrixLoc: GLint = 0
    var modelViewMatrixLoc: GLint = 0
    var mesh: SPMesh?

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
    
    // This is also required
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        projectionMatrixLoc = glGetUniformLocation(shader.program, "projectionMatrix");
        modelViewMatrixLoc = glGetUniformLocation(shader.program, "modelViewMatrix");
        mesh = SPMesh("cube.obj")
        if mesh == nil {
            fatalError("The mesh cannot be instantiated")
        }
   }

    override public func reshape() {
        //Swift.print("reshape")
        super.reshape()
        self.render(elapsedTime: stopClock.timeElapsed())
        let width = self.frame.width
        let height = self.frame.height
        let aspectRatio = GLfloat(width)/GLfloat(height)
        projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(50.0),
                                                     aspectRatio,
                                                     1.0, 100.0)

    }

     override public func draw(_ dirtyRect: NSRect) {
        render(elapsedTime: stopClock.timeElapsed())
     }

    // This is called 1/60-th of a second
    func render(elapsedTime: Double) {
        //Swift.print("render")
        openGLContext!.makeCurrentContext()
        CGLLockContext(openGLContext!.cglContextObj!)
        glClear(GLenum(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glViewport(0, 0, GLsizei(frame.width), GLsizei(frame.height))
        
        // Set the background to gray to indicate the render method had been
        // called in case the shaders are not working properly.
        glClearColor(0.5, 0.5, 0.5, 1.0)
        glEnable(GLenum(GL_CULL_FACE))
        glCullFace(GLenum(GL_BACK))
        // Move the camera backwards towards the observer.
        let viewMatrix = GLKMatrix4MakeLookAt(0.0, 0.0, 3.0,
                                              0.0, 0.0, 0.0,
                                              0.0, 1.0, 0.0)

        // Swift cannot handle complex arithmetic expressions
        let f  = GLfloat(elapsedTime)
        let sinx = sin(2.1 * f) * 0.5
        let cosy = cos(1.7 * f) * 0.5
        let sinz = sin(1.3 * f)
        let cosz = cos(1.5 * f)
        // First build the 2 translation matrices
        let trans1Vec = GLKVector3Make(0.0, 0.0, -5.0)
        let trans1Mat = GLKMatrix4TranslateWithVector3(GLKMatrix4Identity, trans1Vec)
        let trans2Vec = GLKVector3Make(sinx, cosy, sinz * cosz * 2.0)
        let trans2Mat = GLKMatrix4TranslateWithVector3(GLKMatrix4Identity, trans2Vec)

        // Next build the rotation matrices
        var aux1Mat = GLKMatrix4RotateX(GLKMatrix4Identity, GLKMathDegreesToRadians(f*81.0))
        let aux2Mat = GLKMatrix4RotateY(GLKMatrix4Identity, GLKMathDegreesToRadians(f*45.0))
        
        // Finally, build the model matrix using translation & rotation matrices
        let auxMat = GLKMatrix4Multiply(aux1Mat, aux2Mat)       // combined rotation matrix
        aux1Mat = GLKMatrix4Multiply(trans1Mat, trans2Mat)      // combined translation matrix
        let modelMatrix = GLKMatrix4Multiply(aux1Mat, auxMat)   // combined to give the model matrix
        modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix)
        // Prepare to pass the matrices to the shaders
        let workMatPtr = UnsafeMutablePointer<GLKMatrix4>.allocate(capacity: 1)
        workMatPtr.pointee = projectionMatrix
        let workMat2Ptr = UnsafeMutablePointer<GLKMatrix4>.allocate(capacity: 1)
        workMat2Ptr.pointee = modelViewMatrix
 
        shader.use()
        //glBindVertexArray(cubeVAO)
        // Convert unsafeMutablePointer<GLKMatrix4> to unsafe(Mutable)RawPointer
        var rawPtr = UnsafeMutableRawPointer(workMatPtr)
        // Convert to the UnsafeMutableRawPointer to UnsafeMutablePointer<GLfloat>
        var unsafeMutablePtr = rawPtr.bindMemory(to: GLfloat.self, capacity: 1)
        glUniformMatrix4fv(projectionMatrixLoc, 1, GLboolean(GL_FALSE),
                           unsafeMutablePtr)
        rawPtr = UnsafeMutableRawPointer(workMat2Ptr)
        unsafeMutablePtr = rawPtr.assumingMemoryBound(to: GLfloat.self)
        glUniformMatrix4fv(modelViewMatrixLoc, 1, GLboolean(GL_FALSE),
                           unsafeMutablePtr)
        mesh!.render()
        //glDrawElements(GLenum(GL_TRIANGLES), 36, GLenum(GL_UNSIGNED_BYTE), nil)
        //glBindVertexArray(0)
        glUseProgram(0)
        glDisable(GLenum(GL_CULL_FACE))

        openGLContext!.update()
        // we're double buffered so need to flush to screenœ
        openGLContext!.flushBuffer()
        CGLUnlockContext(openGLContext!.cglContextObj!)
        workMatPtr.deinitialize()
        workMat2Ptr.deinitialize()
    }


    // This is required to provide animation
    func startTimer() {
        let framesPerSecond = 60
        let timeInterval = 1.0/Double(framesPerSecond)
        Timer.scheduledTimer(timeInterval: timeInterval,
                             target: self,
                             selector: #selector(SPOpenGLView.onTimer(_:)),
                             userInfo: nil, repeats: true)
    }

    // Prepend with "@objc" so that Cocoa will see it.
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
        return elapsedTime * machTimebaseInfoRatio
    }
}
