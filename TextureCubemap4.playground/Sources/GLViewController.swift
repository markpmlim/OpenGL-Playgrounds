
import Cocoa
import OpenGL.GL3
import GLKit

public class SPOpenGLView: NSOpenGLView {
    let shader = GLShader()
    var cubeVAO: GLuint = 0
    var pipelineName: GLuint = 0
    var programs = [String: GLuint]()       // Dictionary where the key is String, value GLuint
    
    var projectionMatrix = GLKMatrix4Identity
    var modelViewMatrix = GLKMatrix4Identity
    var projectionMatrixLoc: GLint = 0
    var modelViewMatrixLoc: GLint = 0
    var textureID: GLuint = 0
    var textureLoc: GLint = 0
    
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

    // This is called after an OpenGL context is made current.
    override public func prepareOpenGL() {
        //Swift.print("prepareOpenGL")
        super.prepareOpenGL()

        programs["texture3D.vs"] = shader.compileProgram("texture3D.vs",
                                                         shaderType: GLenum(GL_VERTEX_SHADER))
        programs["texture3D.fs"] = shader.compileProgram("texture3D.fs",
                                                         shaderType: GLenum(GL_FRAGMENT_SHADER))
        glGenProgramPipelines(1, &pipelineName)
        glBindProgramPipeline(pipelineName)
        glUseProgramStages(pipelineName, GLbitfield(GL_VERTEX_SHADER_BIT), programs["texture3D.vs"]!)
        glUseProgramStages(pipelineName, GLbitfield(GL_FRAGMENT_SHADER_BIT), programs["texture3D.fs"]!)
        
        projectionMatrixLoc = glGetUniformLocation(programs["texture3D.vs"]!, "projectionMatrix")
        modelViewMatrixLoc = glGetUniformLocation(programs["texture3D.vs"]!, "modelViewMatrix")
        textureLoc = glGetUniformLocation(programs["texture3D.fs"]!, "cubeMap")
        textureID = loadTexture()
        
        createGeometry()
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

    // Assumes this method is called whenever there are updates.
     override public func draw(_ dirtyRect: NSRect) {
        render(elapsedTime: stopClock.timeElapsed())
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
        glEnable(GLenum(GL_CULL_FACE))
        glCullFace(GLenum(GL_BACK))
        // Move the camera backwards
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
        let trans1Vec = GLKVector3Make(0.0, 0.0, -3.0)
        let trans1Mat = GLKMatrix4TranslateWithVector3(GLKMatrix4Identity, trans1Vec)
        let trans2Vec = GLKVector3Make(sinx, cosy, sinz * cosz * 2.0)
        let trans2Mat = GLKMatrix4TranslateWithVector3(GLKMatrix4Identity, trans2Vec)

        // Next build the rotation matrices
        var aux1Mat = GLKMatrix4RotateX(GLKMatrix4Identity, GLKMathDegreesToRadians(f*81.0))
        let aux2Mat = GLKMatrix4RotateY(GLKMatrix4Identity, GLKMathDegreesToRadians(f*45.0))
        
        // Finally, build the model matrix using translation & rotation matrices
        let auxMat = GLKMatrix4Multiply(aux1Mat, aux2Mat)       // combined rotation matrix
        aux1Mat = GLKMatrix4Multiply(trans1Mat, trans2Mat)      // combined translation matrix
        let modelMatrix = GLKMatrix4Multiply(aux1Mat, auxMat)   // combined matrix
        modelViewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix)
        // Prepare to pass the matrices to the shaders
        let workMatPtr = UnsafeMutablePointer<GLKMatrix4>.allocate(capacity: 1)
        workMatPtr.pointee = projectionMatrix
        let workMat2Ptr = UnsafeMutablePointer<GLKMatrix4>.allocate(capacity: 1)
        workMat2Ptr.pointee = modelViewMatrix
 
        // Convert unsafeMutablePointer to unsafe(Mutable)RawPointer
        var rawPtr = UnsafeMutableRawPointer(workMatPtr)
        // Convert to the UnsafeMutableRawPointer to UnsafeMutablePointer<GLfloat>
        var unsafeMutablePtr = rawPtr.bindMemory(to: GLfloat.self, capacity: 1)
        glProgramUniformMatrix4fv(programs["texture3D.vs"]!,
                                  projectionMatrixLoc,
                                  1,
                                  GLboolean(GL_FALSE), unsafeMutablePtr)
        rawPtr = UnsafeMutableRawPointer(workMat2Ptr)
        unsafeMutablePtr = rawPtr.assumingMemoryBound(to: GLfloat.self)
        glProgramUniformMatrix4fv(programs["texture3D.vs"]!,
                                  modelViewMatrixLoc,
                                  1,
                                  GLboolean(GL_FALSE), unsafeMutablePtr)
        glProgramUniform1i(programs["texture3D.fs"]!, textureLoc, 0)

        glBindProgramPipeline(pipelineName)
        glBindVertexArray(cubeVAO)
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), textureID)
        glDrawElements(GLenum(GL_TRIANGLES), 36, GLenum(GL_UNSIGNED_BYTE), nil)
        glBindVertexArray(0)
        glBindProgramPipeline(0)
        glDisable(GLenum(GL_CULL_FACE))

        openGLContext!.update()
        // we're double buffered so need to flush to screen
        openGLContext!.flushBuffer()
        CGLUnlockContext(openGLContext!.cglContextObj!)
        workMatPtr.deinitialize()
        workMat2Ptr.deinitialize()
    }

    // The normals are included here in case lighting is added to this demo.
    func createGeometry() {
        // total size = 24 bytes; using GLKVectors may not work!
        struct Vertex {
            let position: (GLfloat, GLfloat, GLfloat)   // 12 bytes
            let normal: (GLfloat, GLfloat, GLfloat)     // 12 bytes
        }

        let vertices: [Vertex] = [
            Vertex(position: (1, 1, -1), normal: (0.0, 1.0, 0.0)),      // Top
            Vertex(position: (-1, 1, -1), normal: (0.0, 1.0, 0.0)),
            Vertex(position: (-1, 1, 1), normal: (0.0, 1.0, 0.0)),
            Vertex(position: (1, 1, 1), normal: (0.0, 1.0, 0.0)),

            Vertex(position: (1, -1, 1), normal: (0.0, -1.0, 0.0)),     // Bottom
            Vertex(position: (-1, -1, 1), normal: (0.0, -1.0, 0.0)),
            Vertex(position: (-1, -1, -1), normal: (0.0, -1.0, 0.0)),
            Vertex(position: (1, -1, -1), normal: (0.0, -1.0, 0.0)),

            Vertex(position: (1, 1, 1), normal: (0.0, 0.0, 1.0)),       // Front
            Vertex(position: (-1, 1, 1), normal: (0.0, 0.0, 1.0)),
            Vertex(position: (-1, -1, 1), normal: (0.0, 0.0, 1.0)),
            Vertex(position: (1, -1,  1), normal: (0.0, 0.0, 1.0)),

            Vertex(position: (1, -1, -1), normal: (0.0, 0.0, -1.0)),    // Back
            Vertex(position: (-1, -1, -1), normal: (0.0, 0.0, -1.0)),
            Vertex(position: (-1, 1, -1), normal: (0.0, 0.0, -1.0)),
            Vertex(position: (1, 1, -1), normal: (0.0, 0.0, -1.0)),

            Vertex(position: (-1, 1, 1), normal: (-1.0, 0.0, 0.0)),     // Left
            Vertex(position: (-1, 1, -1), normal: (-1.0, 0.0, 0.0)),
            Vertex(position: (-1, -1, -1), normal: (-1.0, 0.0, 0.0)),
            Vertex(position: (-1, -1, 1), normal: (-1.0, 0.0, 0.0)),

            Vertex(position: (1, 1, -1), normal: (1.0, 0.0, 0.0)),  	// Right
            Vertex(position: (1, 1, 1), normal: (1.0, 0.0, 0.0)),
            Vertex(position: (1, -1, 1), normal: (1.0, 0.0, 0.0)),
            Vertex(position: (1, -1, -1), normal: (1.0, 0.0, 0.0)),
        ]

        let indices: [UInt8] = [
            0,  1,  2,	// triangle 1 &
            2,  3,  0,	//  triangle 2 of top face
            4,  5,  6,
            6,  7,  4,
            8,  9,  10,
            10, 11, 8,
            12, 13, 14,
            14, 15, 12,
            16, 17, 18,
            18, 19, 16,
            20, 21, 22,	// triangle 1 &
            22, 23, 20	//  triangle 2 of right face
        ]

        // The geometry of the quad is embedded in the vertex shader
        // but OpenGL needs to bind a vertex array object (VAO).
        glGenVertexArrays(1, &cubeVAO)
        glBindVertexArray(cubeVAO)
        var vboId: GLuint = 0
        glGenBuffers(1, &vboId)                         // Create the buffer ID, this is basically the same as generating texture ID's
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vboId)    // Bind the buffer (vertex array data)

        glBufferData(GLenum(GL_ARRAY_BUFFER),
                     MemoryLayout<Vertex>.stride*vertices.count,
                     vertices, GLenum(GL_STATIC_DRAW))
        let positionAttr = UnsafeRawPointer(bitPattern: 0)
        glVertexAttribPointer(0,                        // attribute
                              3,                        // size
                              GLenum(GL_FLOAT),         // type
                              GLboolean(GL_FALSE),      // don't normalize
                              GLsizei(MemoryLayout<Vertex>.stride),  // stride
                              positionAttr)             // array buffer offset
        glEnableVertexAttribArray(0)
        let normalAttr = UnsafeRawPointer(bitPattern: MemoryLayout<Float>.stride*3)
        glVertexAttribPointer(1,
                              3,
                              GLenum(GL_FLOAT),
                              GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<Vertex>.stride),
                              normalAttr)
        glEnableVertexAttribArray(1)

        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)

        var eboID: GLuint = 0

        glGenBuffers(1, &eboID)                         // Generate buffer
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER),   // Bind the element array buffer
                     eboID)

        // Upload the index array, this can be done the same way as above (with NULL as the data, then a
        // glBufferSubData call, but doing it all at once for convenience)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER),
                     36 * MemoryLayout<UInt8>.stride,
                     indices,
                     GLenum(GL_STATIC_DRAW))
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindVertexArray(0)
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

    // Prepend with "@objc" so that Cocoa's NSTimer will see it.
    @objc func onTimer(_ timer: Timer!) {
        //Swift.print("Timer here")
        render(elapsedTime: stopClock.timeElapsed())
    }

    func loadTexture() -> GLuint {
        let names = ["right.jpg", "left.jpg", "top.jpg", "bottom.jpg", "front.jpg", "back.jpg"]
        var paths = [String]()
        let mainBundle = Bundle.main
        for i in 0..<names.count {
            let path = mainBundle.pathForImageResource(names[i])
            paths.append(path!)
        }

        var textureInfo: GLKTextureInfo!
        do {
            let options: [String : NSNumber] = [GLKTextureLoaderOriginBottomLeft: NSNumber(value: true)]
            textureInfo = try GLKTextureLoader.cubeMap(withContentsOfFiles: paths,
                                                       options: options)
        }
        catch let error {
            fatalError("Error loading picture file:\(error)")
        }
        
        //Swift.print(textureInfo)
        return textureInfo.name
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
