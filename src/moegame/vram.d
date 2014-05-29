module moegame.vram;

import core.exception;
import core.stdc.stdlib;

import std.stdio;
import std.typetuple;

import derelict.opengl3.gl3;

/**
 * A dumb unsafe character buffer.
 */
private struct CharBuffer {
private:
    char[] _data;
public:
    @disable this();
    @disable this(this);

    @system nothrow
    this(size_t length) {
        void* ptr = malloc(length * char.sizeof);

        if (ptr is null) {
            onOutOfMemoryError();
        }

        _data = (cast(char*) ptr)[0 .. length];
    }

    @system nothrow
    ~this() {
        free(_data.ptr);
    }

    @system pure nothrow
    @property
    char[] data() {
        return _data;
    }
}

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

        if (_vertexArray == 0) {
            throw new Error("Unable to create vertex array!");
        }

        // Clean up if something goes wrong.
        scope(failure) glDeleteVertexArrays(1, &_vertexArray);

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
        glDeleteVertexArrays(1, &_vertexArray);
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

/**
 * A shader compiled from a GLSL source.
 */
struct Shader(GLenum shaderType) {
    static assert(
        shaderType == GL_VERTEX_SHADER
        || shaderType == GL_FRAGMENT_SHADER,
        "Unsupported shader type!"
    );
private:
    GLuint _id;
public:
    @disable this();
    @disable this(this);

    @trusted nothrow
    this(string shaderSource) {
        _id = glCreateShader(shaderType);

        if (_id == 0) {
            throw new Error("Unable to create shader program!");
        }

        // Clean up if something goes wrong.
        scope(failure) glDeleteShader(_id);

        {
            const(char)* strPtr = shaderSource.ptr;
            GLint len = cast(GLint) shaderSource.length;

            // Compile the shader now.
            glShaderSource(_id, 1, &strPtr, &len);
            glCompileShader(_id);
        }

        GLint success = GL_FALSE;
        glGetShaderiv(_id, GL_COMPILE_STATUS, &success);

        if (success == GL_FALSE) {
            // Compliation failed, get the error message.

            // Get the length of the message, including the null character.
            int logLength;
            glGetShaderiv(_id, GL_INFO_LOG_LENGTH, &logLength);

            auto buffer = CharBuffer(logLength);

            glGetShaderInfoLog(
                _id,
                // The buffer size.
                logLength,
                // A pointer to an integer to set with the returned length.
                // We know this already.
                null,
                // Pointer to the error message.
                buffer.data.ptr
            );

            // Print the error, minus the null terminating character.
            stderr.writeln(buffer.data[0 .. $ - 1]);

            throw new Error(
                "Compiling a shader failed! "
                ~ "Check the console for more information."
            );
        }
    }

    @trusted nothrow
    ~this() {
        // Calling delete will not break programs containing the shader.
        glDeleteShader(_id);
    }
}

/// true if the type is some Shader type.
enum isSomeShader(T) = 
       is(T == Shader!GL_VERTEX_SHADER)
    || is(T == Shader!GL_FRAGMENT_SHADER);

/**
 * An OpenGL program consisting of some shaders.
 */
struct GPUProgram {
private:
    GLuint _id;
public:
    @trusted nothrow
    this(A...)(A shaderList) if(allSatisfy!(isSomeShader, A)) {
        _id = glCreateProgram();

        if (_id == 0) {
            throw new Error("Unable to create GL GPU program!");
        }

        scope(failure) glDeleteProgram(_id);

        // Link the program.
        foreach(ref shader; shaderList) {
            glAttachShader(_id, shader._id);
        }

        glLinkProgram(_id);

        GLint success = GL_FALSE;
        glGetProgramiv(_id, GL_LINK_STATUS, &success);

        if (success == GL_FALSE) {
            // Linking the program failed.

            // Get the length of the message, including the null character.
            int logLength;
            glGetProgramiv(_id, GL_INFO_LOG_LENGTH, &logLength);

            auto buffer = CharBuffer(logLength);

            glGetProgramInfoLog(
                _id,
                logLength,
                null,
                buffer.data.ptr
            );

            stderr.writeln(buffer.data[0 .. $ - 1]);

            throw new Error(
                "Linking a program failed! "
                ~ "Check the console for more information."
            );
        }
    }

    @trusted nothrow
    void use() {
        glUseProgram(_id);
    }

    @trusted nothrow
    ~this() {
        glDeleteProgram(_id);
    }
}