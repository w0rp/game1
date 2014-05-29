import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

import moegame.app;
import moegame.vram;

string vertexShaderSource = `
    #version 330 core

    layout(location = 0) in vec3 pos;

    void main() {
        gl_Position.xyz = pos;
        gl_Position.w = 1.0;
    }
`;

string fragmentShaderSource = `
    #version 330 core

    out vec3 color;

    void main() {
        color = vec3(1,0,0);
    }
`;

@safe nothrow
int main() {
    GameSettings settings;

    auto app = GameApplication(settings);

    auto triangle = makeTriangle([
        -1,  -1,   0,
         1,  -1,   0,
         0,   1,   0
    ]);

    auto program = GPUProgram(
        Shader!GL_VERTEX_SHADER(vertexShaderSource),
        Shader!GL_FRAGMENT_SHADER(fragmentShaderSource)
    );

    while(!app.shouldClose()) {
        app.clearScreen();

        program.use();

        triangle.draw();

        app.swapBuffers();
        app.handleEvents();
    }

    return 0;
}
