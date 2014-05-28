module moegame.vram;

import derelict.opengl3.gl3;

/**
 * A vertex array with an associated buffer.
 */
struct VertexArray(T, size_t vertexCount) {
private:
    static if(is(T == GLfloat)) {
        enum _vertexType = GL_FLOAT;
    } else {
        static assert(false, "The given vertex type is not supported!");
    }

    GLuint _vertexArray;
public:
    @disable this();
    @disable this(this);

    @trusted nothrow
    this(ref T[vertexCount * 3] vertices) {
        // Create a vertex array.
        glGenVertexArrays(1, &_vertexArray);
        // Call bind to set options for the array.
        glBindVertexArray(_vertexArray);

        // The buffer ID is not stored in the object, as deleting
        // The vertex array will cause the buffer to be deleted
        // when the buffer is no longer referenced anywhere.
        GLuint _buffer;

        // Create the vertex array buffer.
        glGenBuffers(1, &_buffer);
        glBindBuffer(GL_ARRAY_BUFFER, _buffer);

        // Copy data into the buffer.
        glBufferData(
            GL_ARRAY_BUFFER, 
            vertices.sizeof, 
            vertices.ptr, 
            // This is a static draw, so we can't redraw it?
            GL_STATIC_DRAW
        );

        // Set the first attribute with just the buffer.
        glEnableVertexAttribArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, _buffer);
        glVertexAttribPointer(
            // The index to be modified.
            0, 
            vertexCount,
            _vertexType,
            // Don't normalise this vertex data.
            GL_FALSE,
            // The stride in the array.
            0,
            // The offset in the array buffer. 
            null
        );

        // Bind array 0 to stop working with this vertex array.
        glBindVertexArray(0);
    }

    @trusted nothrow
    ~this() {
        if (_vertexArray) {
            glDeleteVertexArrays(1, &_vertexArray);
        }
    }

    @trusted nothrow
    void draw() {
        glBindVertexArray(_vertexArray);
        glDrawArrays(
            GL_TRIANGLES, 
            // The start index in the buffer.
            0, 
            // The number of indices to render.
            vertexCount
        );
    }
}

@safe nothrow
VertexArray!(GLfloat, 3) makeTriangle(GLfloat[3 * 3] vertices) {
    return typeof(return)(vertices);
}