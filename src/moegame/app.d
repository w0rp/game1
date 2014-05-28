module moegame.app;

import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

struct GameSettings {
    uint windowWidth = 800;
    uint windowHeight = 600;
    const(char)* windowTitle = "Game";
}

struct GameApplication {
private:
    GLFWwindow* windowPtr;
public:
    @disable this();
    @disable this(this);

    @trusted nothrow
    this(ref const(GameSettings) settings) {
        try {
            DerelictGL3.load();
            DerelictGLFW3.load();
        } catch (Exception err) {
            throw new Error("Could not load Derelict!", err);
        }

        if(!glfwInit()) {
            throw new Error("Could not start glfw!");
        }

        // OpenGL 3.3 without backwards compatibility is used.
        // This is a version likely to work on Mac OSX, 
        // which has the least modern implementation.
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

        // Enable debuging in GL if debugging in D is enabled.
        debug glfwWindowHint(GLFW_OPENGL_DEBUG_CONTEXT, GL_TRUE);

        windowPtr = glfwCreateWindow(
            settings.windowWidth,
            settings.windowHeight,
            settings.windowTitle,
            null, 
            null
        );

        if (windowPtr is null) {
            throw new Error("Could not create window!");
        }

        glfwMakeContextCurrent(windowPtr);

        try {
            DerelictGL3.reload();
        } catch (Exception err) {
            throw new Error("Could not reload Derelict!", err);
        }
    }

    @trusted nothrow
    bool shouldClose() {
        return glfwWindowShouldClose(windowPtr) == GL_TRUE;
    }

    @trusted nothrow
    void swapBuffers() {
        glfwSwapBuffers(windowPtr);
    }

    @trusted nothrow
    void handleEvents() {
        glfwPollEvents();
    }

    @trusted nothrow
    ~this() {
        glfwDestroyWindow(windowPtr);
    }
}