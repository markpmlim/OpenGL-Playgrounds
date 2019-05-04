// Load model
// The method MDLAsset can load the sub-classes of MDLObject like
// MDLMesh, MDLLight and MDLCamera.
//
// A model can have more than 1 instance of MDLObject.
// A model can have more than 1 instance of MDLMesh.
// Each instance of MDLMesh has an array of MDLSubmesh.
// In other words, more than one VAO might be needed.
// More than VBO might be associated with for each VAO.
// However, we assume the model has a single instance of MDLMesh
// which in turn has a single instance of MDLSubmesh.

import Cocoa
import SceneKit.ModelIO
import OpenGL.GL3

public class SPMesh {
    var VAO: GLuint = 0
    var VBO: GLuint = 0
    var IBO: GLuint = 0
    var indexCount: GLsizei = 0
    var indexType: GLenum = 0
    
    init?(_ fileName: String) {
        let components = fileName.components(separatedBy: ".")
        let myBundle = Bundle.main
        // The model has 3 vertex attributes: positions, normal & texcoords.
        let assetURL = myBundle.url(forResource: components[0],
                                    withExtension: components[1])
        let asset = MDLAsset(url: assetURL!)
        // The method below is only available in macOS 10.12 or later.
        let mdlObjects = asset.childObjects(of: MDLMesh.self)
        if mdlObjects.isEmpty {
            Swift.print("The asset has no instances of MDLMesh")
            return nil
        }
        if mdlObjects.count != 1 {
            Swift.print("The asset has multiple instances of MDLMesh")
            return nil
        }
        
        // We can only handle a single instance of MDLMesh ...
        let mdlMesh = mdlObjects[0] as! MDLMesh
        
        let submeshes = mdlMesh.submeshes
        // ... and single instance of MDLSubmesh
        if submeshes?.count != 1 {
            Swift.print("The asset has multiple instances of MDLSubmesh")
            return nil
        }
        
        let smoothingLevel: Float = 0.01
        if (asset.count == 1) {
            if mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal) == nil {
                mdlMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal,
                                   creaseThreshold:(1.0 - smoothingLevel))
            }
            if mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeTextureCoordinate) == nil {
                mdlMesh.addUnwrappedTextureCoordinates(forAttributeNamed: MDLVertexAttributeTextureCoordinate)
            }
        }
        
        let positionsAttr = mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition)
        let normalsAttr = mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal)
        let uvAttr = mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeTextureCoordinate)
        var positions = positionsAttr!.dataStart
        var normals = normalsAttr!.dataStart
        var texCoords = uvAttr!.dataStart
        
        // The struct below is 8-byte aligned
        struct Vertex {
            let position: GLKVector3        // 12 bytes
            let normal: GLKVector3          // 12 bytes
            let texCoords: GLKVector2       //  8 bytes
        }
        
        // The extracted data will be uploaded to the GPU using OpenGL functions.
        let vertices = UnsafeMutablePointer<Vertex>.allocate(capacity: mdlMesh.vertexCount)
        for i in 0..<mdlMesh.vertexCount {
            let position = positions.bindMemory(to: GLKVector3.self, capacity: 1).pointee
            let normal = normals.bindMemory(to: GLKVector3.self, capacity: 1).pointee
            let uv = texCoords.bindMemory(to: GLKVector2.self, capacity: 1).pointee
            vertices[i] = Vertex(position: position,
                                 normal: normal,
                                 texCoords: uv)
            positions = positions.advanced(by: positionsAttr!.stride)
            normals = normals.advanced(by: normalsAttr!.stride)
            texCoords = texCoords.advanced(by: uvAttr!.stride)
        }
        
        glGenVertexArrays(1, &VAO)
        glBindVertexArray(VAO)
        
        let submesh = submeshes?[0] as! MDLSubmesh
        // Only triangles are handled.
        if (submesh.geometryType != MDLGeometryType.triangles) {
            Swift.print("Mesh data should be composed of triangles")
            return nil
        }
        
        let indexBuffer = submesh.indexBuffer
        var indexDataSize: GLsizei = 0
        if submesh.indexType == MDLIndexBitDepth.uInt8 {
            indexType = GLenum(GL_UNSIGNED_BYTE)
            indexCount = GLsizei(indexBuffer.length)
            indexDataSize = GLsizei(MemoryLayout<GLubyte>.stride)
        }
        else if submesh.indexType == MDLIndexBitDepth.uInt16 {
            indexType = GLenum(GL_UNSIGNED_SHORT)
            indexCount = GLsizei(indexBuffer.length)/2
            indexDataSize = GLsizei(MemoryLayout<GLushort>.stride)
        }
        else if submesh.indexType == MDLIndexBitDepth.uInt32 {
            indexType = GLenum(GL_UNSIGNED_INT)
            indexCount = GLsizei(indexBuffer.length)/4
            indexDataSize = GLsizei(MemoryLayout<GLuint>.stride)
        }
        else {
            Swift.print("Mesh index type is invalid")
            return nil
        }
        
        glGenBuffers(1, &VBO)                         // Create the buffer ID, this is basically the same as generating texture ID's
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), VBO)    // Bind the buffer (vertex array data)
        
        // Upload the vertex data to the GPU
        glBufferData(GLenum(GL_ARRAY_BUFFER),
                     MemoryLayout<Vertex>.stride * mdlMesh.vertexCount,
                     vertices,
                     GLenum(GL_STATIC_DRAW))
        let positionOffset = UnsafeRawPointer(bitPattern: 0)
        glVertexAttribPointer(0, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<Vertex>.stride),
                              positionOffset)        // offset
        glEnableVertexAttribArray(0)
        let normalOffset = UnsafeRawPointer(bitPattern: MemoryLayout<Float>.stride*3)
        glVertexAttribPointer(1, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<Vertex>.stride),
                              normalOffset)
        glEnableVertexAttribArray(1)
        let uvOffset = UnsafeRawPointer(bitPattern: MemoryLayout<Float>.stride*6)
        glVertexAttribPointer(2, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE),
                              GLsizei(MemoryLayout<Vertex>.stride),
                              uvOffset)
        glEnableVertexAttribArray(2)
        
        glGenBuffers(1, &IBO);
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), IBO)
        // Upload the indices data to the GPU
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER),
                     GLsizeiptr(indexDataSize * indexCount),
                     indexBuffer.map().bytes,
                     GLenum(GL_STATIC_DRAW))
        glBindVertexArray(0)
    }
    
    func render() {
        glBindVertexArray(VAO)
        glEnableVertexAttribArray(0)
        glEnableVertexAttribArray(1)
        glEnableVertexAttribArray(2)
        
        glDrawElements(GLenum(GL_TRIANGLES), indexCount, indexType, nil)
        glBindVertexArray(0)
    }
}
