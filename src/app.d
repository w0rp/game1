import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

import moegame.app;
import moegame.vram;

@safe nothrow
int main() {
    GameSettings settings;

    auto app = GameApplication(settings);

    auto triangle = makeTriangle([
        -1,  -1,   0,
         1,  -1,   0,
         0,   1,   0
    ]);

    while(!app.shouldClose()) {
        triangle.draw();

        app.swapBuffers();
        app.handleEvents();
    }

    return 0;
}
